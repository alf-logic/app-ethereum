"""spec-verify: Analyze C functions — generate specs, find bugs, open issues."""

import click
from pathlib import Path


@click.command()
@click.option("--file", required=True, type=click.Path(exists=True), help="C source file")
@click.option("--issue", type=int, default=None, help="Work on a specific GitHub issue")
@click.option("--model", default="gpt-5.2", show_default=True, help="LLM model")
@click.option("--verbose", "-v", is_flag=True, default=False)
def main(file: str, issue: int | None, model: str, verbose: bool):
    """Analyze all functions in a C file, or work on a specific issue."""
    source_path = Path(file)

    from spec_verify.workflow import run_file_flow, run_issue_flow

    if issue:
        run_issue_flow(source_path, issue, model, verbose)
    else:
        run_file_flow(source_path, model, verbose)
