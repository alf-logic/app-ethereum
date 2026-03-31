"""Extract a C function and its preceding comments from a source file."""

import re
from pathlib import Path


def extract_function(file_path: Path, function_name: str) -> str | None:
    """Extract a C function and its preceding comment block from a file.

    Returns the full text including docstrings, ACSL annotations, and the
    function body with matched braces. Returns None if not found.
    """
    source = file_path.read_text()

    # Find the function signature line
    sig_pattern = re.compile(
        rf"^[^\S\n]*\w[\w\s\*]*\b{re.escape(function_name)}\s*\([^)]*\)\s*\{{",
        re.MULTILINE,
    )

    match = sig_pattern.search(source)
    if not match:
        return None

    sig_start = match.start()

    # Walk backwards to capture preceding comment blocks (docstrings, ACSL)
    block_start = sig_start
    prefix = source[:sig_start].rstrip()
    if prefix.endswith("*/"):
        # Find the start of this comment block
        comment_start = prefix.rfind("/*")
        if comment_start != -1:
            # Check for a second comment block before this one (ACSL + Gherkin)
            before_comment = source[:comment_start].rstrip()
            if before_comment.endswith("*/"):
                second_start = before_comment.rfind("/*")
                if second_start != -1:
                    block_start = second_start
                else:
                    block_start = comment_start
            else:
                block_start = comment_start
    # Also capture #ifndef guards right before the function
    elif prefix.endswith("#endif") or prefix.endswith("#ifndef"):
        pass  # don't include preprocessor guards

    # Find matching closing brace
    brace_count = 0
    pos = match.end() - 1
    for i in range(pos, len(source)):
        if source[i] == "{":
            brace_count += 1
        elif source[i] == "}":
            brace_count -= 1
            if brace_count == 0:
                return source[block_start : i + 1]

    return None


def extract_all_functions(file_path: Path) -> list[tuple[str, str]]:
    """Extract all C function definitions from a file.

    Returns list of (function_name, full_source) tuples, in order of appearance.
    """
    source = file_path.read_text()

    control_flow = {"if", "else", "while", "for", "switch", "return", "sizeof", "typeof", "main"}

    sig_pattern = re.compile(
        r"^[^\S\n]*(?:static\s+)?(?:inline\s+)?[\w][\w\s\*]*?\b(\w+)\s*\([^)]*\)\s*\{",
        re.MULTILINE,
    )

    functions: list[tuple[str, str]] = []
    seen: set[str] = set()
    for match in sig_pattern.finditer(source):
        name = match.group(1)
        if name in control_flow or name in seen:
            continue
        func_source = extract_function(file_path, name)
        if func_source:
            functions.append((name, func_source))
            seen.add(name)

    return functions
