"""Execute OpenAI API calls for spec/test generation, then compile and run tests."""

import subprocess
import os
import tempfile
from dataclasses import dataclass, field
from pathlib import Path

from dotenv import load_dotenv
from openai import OpenAI

from spec_verify.prompts import SPEC_GENERATION, TEST_GENERATION

# Load .env from project root
load_dotenv(Path(__file__).resolve().parents[3] / ".env")

# Budget tracking
_BUDGET_LIMIT = 2.00  # USD
_total_cost = 0.0

# GPT-4o pricing (per 1M tokens)
_INPUT_COST = 2.50 / 1_000_000
_OUTPUT_COST = 10.00 / 1_000_000

MODEL = "gpt-4o"


@dataclass
class AnalysisResult:
    spec: str = ""
    tests: str = ""
    test_compile_ok: bool = False
    test_run_output: str = ""
    test_passed: int = 0
    test_failed: int = 0
    failures: list[str] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)
    cost: float = 0.0

    @property
    def all_pass(self) -> bool:
        return self.test_compile_ok and self.test_failed == 0 and self.test_passed > 0

    @property
    def has_failures(self) -> bool:
        return self.test_failed > 0


def _call_llm(prompt: str, step_name: str) -> str:
    """Call OpenAI API and return the response. Tracks cost."""
    global _total_cost

    if _total_cost >= _BUDGET_LIMIT:
        return f"ERROR: Budget limit ${_BUDGET_LIMIT:.2f} reached (spent ${_total_cost:.4f})"

    client = OpenAI()
    response = client.chat.completions.create(
        model=MODEL,
        messages=[{"role": "user", "content": prompt}],
        temperature=0,
    )

    # Track cost
    usage = response.usage
    if usage:
        cost = usage.prompt_tokens * _INPUT_COST + usage.completion_tokens * _OUTPUT_COST
        _total_cost += cost

    return response.choices[0].message.content.strip()


def _extract_code_block(text: str) -> str:
    """Extract content from a ```c or ```gherkin fenced block."""
    lines = text.split("\n")
    in_block = False
    result = []
    for line in lines:
        if line.strip().startswith("```c") or line.strip().startswith("```gherkin"):
            in_block = True
            continue
        if line.strip() == "```" and in_block:
            in_block = False
            continue
        if in_block:
            result.append(line)
    return "\n".join(result) if result else text


def _compile_and_run_tests(
    test_source: str,
    func_source_path: Path,
    function_name: str,
) -> tuple[bool, str, int, int, list[str]]:
    """Compile the test file with the source and run it."""
    with tempfile.TemporaryDirectory() as tmpdir:
        test_file = Path(tmpdir) / f"test_{function_name}.c"
        test_file.write_text(test_source)
        binary = Path(tmpdir) / "test_runner"

        # Find project paths
        project_root = func_source_path.resolve()
        while project_root.name != "src" and project_root != project_root.parent:
            project_root = project_root.parent
        project_root = project_root.parent

        src_dir = project_root / "src"
        stubs_dir = project_root / "tests" / "unit" / "stubs"
        plugin_dir = project_root / "ethereum-plugin-sdk" / "src"

        include_dirs = []
        for d in [stubs_dir, src_dir, plugin_dir]:
            if d.exists():
                include_dirs.extend(["-I", str(d)])

        extra_sources = []
        if (src_dir / "uint128.c").exists():
            extra_sources.append(str(src_dir / "uint128.c"))
        if (stubs_dir / "utils_stubs.c").exists():
            extra_sources.append(str(stubs_dir / "utils_stubs.c"))

        # Find cmocka
        cmocka_include = ""
        cmocka_lib = ""
        for prefix in ["/opt/homebrew/opt/cmocka", "/usr/local/opt/cmocka", "/usr"]:
            if os.path.exists(f"{prefix}/include/cmocka.h"):
                cmocka_include = f"-I{prefix}/include"
                cmocka_lib = f"-L{prefix}/lib"
                break

        compile_cmd = [
            "cc", "-o", str(binary),
            str(test_file),
            *extra_sources,
            *include_dirs,
            cmocka_include, cmocka_lib,
            "-lcmocka", "-Wall", "-g",
        ]
        compile_cmd = [c for c in compile_cmd if c]

        compile_result = subprocess.run(compile_cmd, capture_output=True, text=True)
        if compile_result.returncode != 0:
            return False, f"COMPILE ERROR:\n{compile_result.stderr}", 0, 0, []

        try:
            run_result = subprocess.run(
                [str(binary)], capture_output=True, text=True, timeout=30
            )
            output = run_result.stdout + run_result.stderr
        except subprocess.TimeoutExpired:
            # Run timed out — run each test individually to find which one hangs
            output, passed, failed, failures = _isolate_hanging_test(
                str(binary), test_source
            )
            return True, output, passed, failed, failures

        passed = output.count("[       OK ]")
        failed = output.count("[  FAILED  ]")
        failures = [line.strip() for line in output.split("\n")
                    if "[  FAILED  ]" in line or "FAILED" in line]

        return True, output, passed, failed, failures


def _isolate_hanging_test(
    binary: str, test_source: str
) -> tuple[str, int, int, list[str]]:
    """When the full test suite hangs, run each test with a short timeout to find which one."""
    import re

    # Extract test function names from the source
    test_names = re.findall(r'cmocka_unit_test\((\w+)\)', test_source)

    # Extract scenario descriptions from Gherkin-style comments above each test
    scenarios = {}
    lines = test_source.split("\n")
    for i, line in enumerate(lines):
        for name in test_names:
            if f"static void {name}" in line:
                # Look backwards for Given/When/Then or Scenario comment
                desc_parts = []
                for j in range(max(0, i - 10), i):
                    stripped = lines[j].strip().lstrip("/ *")
                    if any(kw in stripped for kw in ["Scenario:", "Given ", "When ", "Then "]):
                        desc_parts.append(stripped)
                if desc_parts:
                    scenarios[name] = " | ".join(desc_parts)
                break

    # cmocka runs all tests sequentially in one binary.
    # When it hangs, one test caused it — the rest never ran.
    # Identify the likely culprit: edge-case tests (zero, max, boundary).
    suspect_keywords = ["zero", "null", "max", "boundary", "overflow", "empty", "negative"]
    suspects = []
    others = []
    for name in test_names:
        is_suspect = any(kw in name.lower() for kw in suspect_keywords)
        desc = scenarios.get(name, "")
        if is_suspect:
            suspects.append((name, desc))
        else:
            others.append((name, desc))

    failures = []
    output_lines = ["TEST SUITE TIMED OUT after 30s — one test caused an infinite loop.\n"]

    if suspects:
        output_lines.append("Likely culprit(s):")
        for name, desc in suspects:
            detail = f"HUNG (likely): {name}"
            if desc:
                detail += f"\n         {desc}"
            detail += f"\n         This edge-case test likely triggers the hang."
            output_lines.append(f"  [  HUNG    ] {name}")
            failures.append(detail)

    if others:
        output_lines.append(f"\n{len(others)} other test(s) never ran (blocked by the hang):")
        for name, _ in others:
            output_lines.append(f"  [ BLOCKED  ] {name}")

    output = "\n".join(output_lines)
    return output, 0, len(suspects), failures


def run_analysis(
    source: str,
    function_name: str,
    source_path: Path,
) -> AnalysisResult:
    """Generate spec → generate tests → compile → run."""
    global _total_cost
    result = AnalysisResult()

    # Step 1: Generate Gherkin spec
    print("  [1/3] Generating spec...")
    raw_spec = _call_llm(
        SPEC_GENERATION.format(source=source, function_name=function_name),
        "spec",
    )
    result.spec = _extract_code_block(raw_spec) if "```" in raw_spec else raw_spec

    if result.spec.startswith("ERROR:"):
        result.errors.append(result.spec)
        result.cost = _total_cost
        return result

    # Extract #include lines from the source file for the test prompt
    import re
    includes = "\n".join(
        line for line in Path(source_path).read_text().split("\n")
        if re.match(r'\s*#include\s+"', line)
    )

    # Step 2: Generate tests
    print("  [2/3] Generating tests...")
    raw_tests = _call_llm(
        TEST_GENERATION.format(
            source=source, function_name=function_name, spec=result.spec,
            includes=includes,
        ),
        "tests",
    )
    result.tests = _extract_code_block(raw_tests) if "```" in raw_tests else raw_tests

    if result.tests.startswith("ERROR:"):
        result.errors.append(result.tests)
        result.cost = _total_cost
        return result

    # Step 3: Compile and run
    print("  [3/3] Compiling and running tests...")
    (
        result.test_compile_ok,
        result.test_run_output,
        result.test_passed,
        result.test_failed,
        result.failures,
    ) = _compile_and_run_tests(result.tests, source_path, function_name)

    result.cost = _total_cost
    print(f"  Cost: ${_total_cost:.4f} / ${_BUDGET_LIMIT:.2f}")
    return result
