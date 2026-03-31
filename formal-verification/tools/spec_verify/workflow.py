"""Workflow orchestration — file flow, issue flow, interactive menus.

All external operations (LLM, git, gh) are STUBBED for UI prototyping.
Stubs print what *would* happen but make no real calls or changes.
"""

from __future__ import annotations

import hashlib
import time
import click
from pathlib import Path

from spec_verify.extractor import extract_all_functions
from spec_verify.formatter import (
    FunctionResult,
    FixResult,
    LiveTable,
    print_header,
    print_step,
    print_analysis_table,
    print_issue_summary,
    print_fix_summary,
    print_issue_detail,
)

REPO = "alf-logic/app-ethereum"


# ── Helpers ─────────────────────────────────────────────────────


def _short_hash(text: str) -> str:
    return hashlib.sha1(text.encode()).hexdigest()[:6]


# Real analysis data for uint128.c — from manual code review + confirmed test results
_GH = "https://github.com/alf-logic/app-ethereum/issues"
_ANALYSIS: dict[str, dict] = {
    "readu128BE":            dict(s="pass", t=3, bug="",          finding="",                                  ds=1, dl=1, dp=1),
    "zero128":               dict(s="pass", t=3, bug="",          finding="",                                  ds=1, dl=1, dp=1),
    "copy128":               dict(s="pass", t=3, bug="",          finding="",                                  ds=1, dl=1, dp=1),
    "clear128":              dict(s="pass", t=2, bug="",          finding="",                                  ds=1, dl=1, dp=1),
    "shiftl128":             dict(s="pass", t=9, bug="",          finding="proven correct in Lean",            ds=3, dl=3, dp=5),
    "shiftr128":             dict(s="fail", t=9, bug="bug",       finding="aliasing clobber at value=64",      ds=3, dl=3, dp=5, f=1, rec="swap assignment order in value==64 branch",
                                  inum=10, iurl=f"{_GH}/10", risk="Medium", tsum="1 FAIL, 3 PASS"),
    "bits128":               dict(s="pass", t=5, bug="",          finding="",                                  ds=2, dl=2, dp=3),
    "equal128":              dict(s="pass", t=4, bug="",          finding="",                                  ds=1, dl=1, dp=1),
    "gt128":                 dict(s="pass", t=5, bug="",          finding="",                                  ds=1, dl=2, dp=2),
    "gte128":                dict(s="pass", t=3, bug="",          finding="",                                  ds=1, dl=1, dp=1),
    "add128":                dict(s="pass", t=5, bug="",          finding="",                                  ds=2, dl=2, dp=3),
    "sub128":                dict(s="pass", t=5, bug="",          finding="",                                  ds=2, dl=2, dp=3),
    "or128":                 dict(s="pass", t=3, bug="",          finding="",                                  ds=1, dl=1, dp=1),
    "mul128":                dict(s="pass", t=6, bug="",          finding="",                                  ds=4, dl=5, dp=8),
    "divmod128":             dict(s="fail", t=7, bug="bug",       finding="infinite loop on div-by-zero",      ds=5, dl=6, dp=9, f=1, rec="add zero-divisor guard before loop",
                                  inum=11, iurl=f"{_GH}/11", risk="High", tsum="hang detected"),
    "tostring128":           dict(s="pass", t=6, bug="",          finding="",                                  ds=3, dl=4, dp=6),
    "tostring128_signed":    dict(s="fail", t=5, bug="edge case", finding="buffer underflow if len=0+negative",ds=3, dl=4, dp=6, f=1, rec="guard out_length before writing '-'",
                                  inum=12, iurl=f"{_GH}/12", risk="Low", tsum="2 FAIL, 1 PASS"),
    "convertUint64BEto128":  dict(s="fail", t=5, bug="bug",       finding="target unchanged on len>16",        ds=3, dl=3, dp=4, f=1, rec="clear target before early return",
                                  inum=13, iurl=f"{_GH}/13", risk="Medium", tsum="1 FAIL, 1 PASS"),
    "convertUint128BE":      dict(s="fail", t=5, bug="edge case", finding="silent return, target unchanged",   ds=2, dl=2, dp=3, f=1, rec="clear target on error paths",
                                  inum=14, iurl=f"{_GH}/14", risk="Low-Medium", tsum="3 FAIL, 1 PASS"),
}


def _stub_analyze(name: str, idx: int) -> FunctionResult:
    """Return analysis result — uses real data for known functions, generic for unknown."""
    if name in _ANALYSIS:
        a = _ANALYSIS[name]
        is_fail: bool = a["s"] == "fail"
        n_failed: int = a.get("f", 0)
        total: int = a["t"]
        return FunctionResult(
            name=name,
            status=a["s"],
            total=total,
            passed=total - n_failed,
            failed=n_failed,
            failures=[f"test_{name}_bug_scenario"] if is_fail else [],
            recommendation=a.get("rec", ""),
            risk=a.get("risk", ""),
            lean_ready=not is_fail,
            suggestion="bug fix" if a["bug"] == "bug" else ("review edge case" if a["bug"] else "translate to lean"),
            bug_type=a["bug"],
            finding=a["finding"],
            diff_spec=a["ds"],
            diff_lean=a["dl"],
            diff_proof=a["dp"],
            issue_number=a.get("inum"),
            issue_url=a.get("iurl", ""),
            test_summary=a.get("tsum", ""),
        )

    # Fallback for unknown functions
    return FunctionResult(
        name=name, status="pass", total=3, passed=3, failed=0,
        lean_ready=True, suggestion="translate to lean",
        diff_spec=2, diff_lean=2, diff_proof=2,
    )


# ── File flow ───────────────────────────────────────────────────


def run_file_flow(file_path: Path, model: str, verbose: bool) -> None:
    print_header(f"spec-verify: {file_path.name}")

    # 1 — branch
    branch: str = f"spec-verify/{file_path.stem}-{_short_hash(file_path.name)}"
    print_step(1, 4, "Creating branch...", f"Would run: git checkout -b {branch}")

    # 2 — extract (real)
    functions = extract_all_functions(file_path)
    if not functions:
        click.echo(click.style("  No functions found.", fg="red"))
        return
    names: str = ", ".join(n for n, _ in functions)
    print_step(2, 4, "Extracting functions...", f"Found {len(functions)}: {names}")

    # 3 — analyze with live table
    print_step(3, 4, "Analyzing functions...", "")
    click.echo()

    names_list: list[str] = [n for n, _ in functions]
    results: list[FunctionResult] = [_stub_analyze(n, i) for i, (n, _) in enumerate(functions, 1)]

    table = LiveTable(names_list)
    table.draw()

    delay: float = 0.03

    # Phase 1: Specs
    for i in range(len(functions)):
        time.sleep(delay)
        table.update(i, "Spec", "✓")

    # Phase 2: Scenarios
    for i, r in enumerate(results):
        time.sleep(delay)
        table.update(i, "Scenarios", str(r.total))

    # Phase 3: Tests
    for i in range(len(functions)):
        time.sleep(delay)
        table.update(i, "Tests", "✓")

    # Phase 4: Validation
    for i, r in enumerate(results):
        time.sleep(delay)
        if r.status == "pass":
            table.update(i, "Result", f"PASS ({r.passed}/{r.total})")
        else:
            table.update(i, "Result", f"FAIL ({r.failed}/{r.total} failed)")

    failed = [r for r in results if r.status == "fail"]
    passed = [r for r in results if r.status == "pass"]

    # 4 — open issues (real issue numbers from GH)
    if failed:
        print_step(4, 4, f"Opening issues for {len(failed)} failed function(s)...", "")
        for r in failed:
            tag = f"#{r.issue_number}" if r.issue_number else "new"
            click.echo(click.style(
                f"        → {tag}  {r.name}()  [{r.bug_type}: {r.finding}]",
                dim=True,
            ))
    else:
        print_step(4, 4, "No issues — all functions passed!", "")

    # function summary (analysis table)
    print_analysis_table(results)

    # issue summary table
    print_issue_summary(results)

    # menu
    _main_menu(passed, failed, file_path, model)


# ── Main menu ───────────────────────────────────────────────────


def _main_menu(
    passed: list[FunctionResult],
    failed: list[FunctionResult],
    file_path: Path,
    model: str,
) -> None:
    all_results: list[FunctionResult] = passed + failed
    options: list[str] = []
    if passed:
        options.append(f"Prepare PR for {len(passed)} successful function(s)")
    if failed:
        options.append("Fix a specific issue")
        options.append("Fix all issues and make PR")
    options.append("Prepare analysis summary")

    click.echo("\n  Select an action:")
    for i, opt in enumerate(options, 1):
        click.echo(f"    {i}. {opt}")

    choice: int = click.prompt("\n  Your choice", type=click.IntRange(1, len(options)))
    text: str = options[choice - 1]

    if "Prepare PR" in text:
        _handle_pr_for_passed(passed, file_path)
    elif "specific" in text:
        _handle_fix_specific(failed, file_path, model)
    elif "Fix all" in text:
        _handle_fix_all(failed, file_path, model)
    elif "summary" in text:
        _handle_analysis_summary(all_results, file_path)


# ── Action handlers (all stubbed) ──────────────────────────────


def _handle_analysis_summary(results: list[FunctionResult], file_path: Path) -> None:
    n_pass: int = sum(1 for r in results if r.status == "pass")
    n_fail: int = sum(1 for r in results if r.status == "fail")
    n_lean: int = sum(1 for r in results if r.lean_ready)

    click.echo(click.style(f"\n  Analysis Summary: {file_path.name}", bold=True))
    click.echo(f"  {'─' * 50}")
    click.echo(f"  Total functions:   {len(results)}")
    click.echo(f"  Passed:            {click.style(str(n_pass), fg='green')}")
    click.echo(f"  Failed:            {click.style(str(n_fail), fg='red')}")
    click.echo(f"  Lean-ready:        {click.style(str(n_lean), fg='green')}")
    click.echo(f"  Need refactor/fix: {click.style(str(len(results) - n_lean), fg='yellow')}")

    high_risk = [r for r in results if r.risk == "high"]
    if high_risk:
        click.echo(click.style(f"\n  High-risk issues ({len(high_risk)}):", fg="red", bold=True))
        for r in high_risk:
            click.echo(f"    #{r.issue_number}  {r.name}() — {r.suggestion}")

    click.echo(click.style(
        f"\n  → Would write summary to formal-verification/reports/{file_path.stem}_summary.md",
        dim=True,
    ))
    click.echo(click.style("\n  [STUB] Summary generation not implemented yet.", fg="yellow"))


def _handle_pr_for_passed(passed: list[FunctionResult], file_path: Path) -> None:
    names: str = ", ".join(r.name for r in passed)
    click.echo(click.style(f"\n  → Would create branch with spec + test files for: {names}", dim=True))
    click.echo(click.style(
        f'  → Would run: gh pr create -R {REPO} '
        f'--title "feat: add specs + tests for {len(passed)} functions in {file_path.name}"',
        dim=True,
    ))
    click.echo(click.style("\n  [STUB] PR creation not implemented yet.", fg="yellow"))


def _handle_fix_specific(
    failed: list[FunctionResult], file_path: Path, model: str
) -> None:
    click.echo("\n  Failed functions:")
    for i, r in enumerate(failed, 1):
        click.echo(f"    {i}. {r.name} — Issue #{r.issue_number}: {r.failed} scenario(s) failed")

    idx: int = click.prompt("\n  Select issue to fix", type=click.IntRange(1, len(failed)))
    _fix_menu(failed[idx - 1], file_path, model)


# Real fix data for the 5 issues we created PRs for
_FIXES: list[dict] = [
    dict(inum=10, iurl=f"{_GH}/10", branch="fix/shiftr128-issue-10",
         fix="Swap assignment order in value==64 branch", tests="4/4 PASS",
         pr="https://github.com/alf-logic/app-ethereum/pull/15"),
    dict(inum=11, iurl=f"{_GH}/11", branch="fix/divmod128-issue-11",
         fix="Add zero128(r) guard before loop", tests="3/3 PASS",
         pr="https://github.com/alf-logic/app-ethereum/pull/16"),
    dict(inum=12, iurl=f"{_GH}/12", branch="fix/tostring128_signed-issue-12",
         fix="Add out_length < 2 guard before '-'", tests="3/3 PASS",
         pr="https://github.com/alf-logic/app-ethereum/pull/17"),
    dict(inum=13, iurl=f"{_GH}/13", branch="fix/convertUint64BEto128-issue-13",
         fix="clear128(target) instead of memset(tmp)", tests="2/2 PASS",
         pr="https://github.com/alf-logic/app-ethereum/pull/18"),
    dict(inum=14, iurl=f"{_GH}/14", branch="fix/convertUint128BE-issue-14",
         fix="Add clear128(target) on all error paths", tests="4/4 PASS",
         pr="https://github.com/alf-logic/app-ethereum/pull/19"),
]


def _handle_fix_all(
    failed: list[FunctionResult], file_path: Path, model: str
) -> None:
    import time as _t

    click.echo(click.style(f"\n  Fixing all {len(failed)} issue(s):\n", bold=True))

    for fd in _FIXES:
        click.echo(click.style(f"  Working on issue #{fd['inum']}", bold=True))
        click.echo(click.style(f"  Reading issue...", dim=True))
        _t.sleep(0.1)
        click.echo(click.style(f"  Create branch: {fd['branch']}", dim=True))
        _t.sleep(0.1)
        click.echo(click.style(f"  Implementation: {fd['fix']}", dim=True))
        _t.sleep(0.1)
        click.echo(click.style(f"  Validation: {fd['tests']}", dim=True))
        _t.sleep(0.1)
        click.echo(click.style(f"  Prepare PR...", dim=True))
        click.echo(click.style(f"  PR: {fd['pr']}", fg="cyan"))
        click.echo()

    fixes = [
        FixResult(
            issue_number=fd["inum"], issue_url=fd["iurl"],
            branch=fd["branch"], fix_desc=fd["fix"],
            tests=fd["tests"], pr_url=fd["pr"],
        )
        for fd in _FIXES
    ]
    print_fix_summary(fixes)

    click.echo(click.style(
        f"\n  All {len(fixes)} issues fixed. Merge PRs to proceed.",
        fg="green", bold=True,
    ))


# ── Fix menu (shared by file-flow and issue-flow) ──────────────


def _fix_menu(result: FunctionResult, file_path: Path, model: str) -> None:
    click.echo(click.style(
        f"\n  Issue #{result.issue_number}: {result.name}() — "
        f"{result.failed} failing scenario(s)",
        bold=True,
    ))
    if result.recommendation:
        click.echo(click.style(f"  Recommendation: {result.recommendation}", fg="yellow"))

    click.echo(f"\n  Fix approach:")
    click.echo(f"    1. Show context for human fix")
    click.echo(f"    2. AI-assisted fix ({model})")
    click.echo(f"    3. Back")

    choice: int = click.prompt("\n  Your choice", type=click.IntRange(1, 3))

    if choice == 1:
        _show_human_context(result, file_path)
    elif choice == 2:
        _handle_ai_fix(result, file_path, model)


def _show_human_context(result: FunctionResult, file_path: Path) -> None:
    click.echo(click.style(f"\n  Context for fixing {result.name}():", bold=True))
    click.echo(f"  File: {file_path}")
    click.echo(click.style(f"\n  Failing scenarios:", bold=True))
    for f in result.failures:
        click.echo(click.style(f"    ✗ {f}", fg="red"))
    if result.recommendation:
        click.echo(click.style(f"\n  Suggestion: {result.recommendation}", fg="yellow"))
    click.echo(f"\n  After fixing, re-run:")
    click.echo(click.style(
        f"    spec-verify --file {file_path} --issue {result.issue_number}", dim=True
    ))


def _handle_ai_fix(result: FunctionResult, file_path: Path, model: str) -> None:
    click.echo(click.style(f"\n  AI-assisted fix for {result.name}():", bold=True))
    click.echo(click.style(f"  → Would call {model} with function source + failing scenarios", dim=True))
    click.echo(click.style(f"  → Would generate patched function", dim=True))
    click.echo(click.style(f"  → Would re-run tests to verify fix", dim=True))
    branch: str = f"fix/{result.name}-issue-{result.issue_number}"
    click.echo(click.style(f"  → Would run: git checkout -b {branch}", dim=True))
    click.echo(click.style(
        f'  → Would run: gh pr create -R {REPO} '
        f'--title "fix: {result.name}() — closes #{result.issue_number}"',
        dim=True,
    ))
    click.echo(click.style("\n  [STUB] AI fix not implemented yet.", fg="yellow"))


# ── Issue flow ──────────────────────────────────────────────────


def run_issue_flow(file_path: Path, issue_number: int, model: str, verbose: bool) -> None:
    print_header(f"spec-verify: Issue #{issue_number}")

    click.echo(click.style(
        f"\n  → Would run: gh issue view {issue_number} -R {REPO} --json title,body", dim=True
    ))

    # Extract functions to pick one for the stub demo
    functions = extract_all_functions(file_path)
    if not functions:
        click.echo(click.style("  No functions found in file.", fg="red"))
        return

    # Deterministic pick based on issue number
    idx: int = issue_number % len(functions)
    name, _src = functions[idx]

    result = _stub_analyze(name, idx)
    result.issue_number = issue_number
    # Force failure for issue-flow demo
    if result.status == "pass":
        result.status = "fail"
        result.failed = 1
        result.passed = result.total - 1
        result.failures = [f"test_{name}_edge_case"]
        result.recommendation = f"check boundary conditions in {name}()"

    print_issue_detail(result, str(file_path))

    _fix_menu(result, file_path, model)
