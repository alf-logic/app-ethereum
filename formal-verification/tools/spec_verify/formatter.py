"""Display formatting — live table, analysis table, issue summary, steps."""

from __future__ import annotations

import sys
import click
from dataclasses import dataclass, field


@dataclass
class FunctionResult:
    name: str
    status: str  # "pass" | "fail" | "error"
    total: int
    passed: int
    failed: int
    failures: list[str] = field(default_factory=list)
    recommendation: str = ""
    issue_number: int | None = None
    risk: str = ""  # "High" | "Medium" | "Low" | "Low-Medium"
    lean_ready: bool = False
    suggestion: str = ""
    bug_type: str = ""  # "bug" | "edge case" | ""
    finding: str = ""
    diff_spec: int = 1
    diff_lean: int = 1
    diff_proof: int = 1
    issue_url: str = ""
    test_summary: str = ""  # e.g. "1 FAIL, 3 PASS"


# ── Primitives ──────────────────────────────────────────────────


def print_header(title: str) -> None:
    click.echo(click.style(f"\n  {title}", bold=True))
    click.echo("  " + "=" * 62)


def print_step(step: int, total: int, msg: str, detail: str = "") -> None:
    click.echo(f"\n  [{step}/{total}] {msg}")
    if detail:
        click.echo(click.style(f"        → {detail}", dim=True))


# ── Live table (progress) ──────────────────────────────────────


class LiveTable:
    """Terminal table that redraws in-place as cells update."""

    COLUMNS = ("Spec", "Scenarios", "Tests", "Result")

    def __init__(self, names: list[str]) -> None:
        self.names: list[str] = names
        self.name_w: int = max(max(len(n) for n in names) + 2, 24)
        self.cells: list[dict[str, str]] = [
            {c: "—" for c in self.COLUMNS} for _ in names
        ]
        self._line_count: int = 0

    def _build_lines(self) -> list[str]:
        lines: list[str] = []
        hdr = (
            f"  {'#':>3}  {'Function':<{self.name_w}}"
            f" {'Spec':<8} {'Scenarios':<12} {'Tests':<8} Result"
        )
        lines.append(hdr)
        lines.append(f"  {'─' * (3 + 2 + self.name_w + 8 + 12 + 8 + 20)}")

        for i, name in enumerate(self.names):
            c = self.cells[i]
            r = c["Result"]
            if "PASS" in r:
                r_display = click.style(r, fg="green")
            elif "FAIL" in r:
                r_display = click.style(r, fg="red")
            else:
                r_display = r
            lines.append(
                f"  {i + 1:>3}  {name:<{self.name_w}}"
                f" {c['Spec']:<8} {c['Scenarios']:<12} {c['Tests']:<8} {r_display}"
            )
        return lines

    def draw(self) -> None:
        lines = self._build_lines()
        for line in lines:
            sys.stdout.write(line + "\n")
        sys.stdout.flush()
        self._line_count = len(lines)

    def redraw(self) -> None:
        if self._line_count:
            sys.stdout.write(f"\033[{self._line_count}A")
        lines = self._build_lines()
        for line in lines:
            sys.stdout.write(f"\033[2K{line}\n")
        sys.stdout.flush()
        self._line_count = len(lines)

    def update(self, idx: int, column: str, value: str) -> None:
        self.cells[idx][column] = value
        self.redraw()

    def batch_update(self, column: str, value: str) -> None:
        for c in self.cells:
            c[column] = value
        self.redraw()


# ── Analysis table (function summary) ──────────────────────────


def _diff_color(v: int) -> str:
    if v <= 2:
        return click.style(f"{v:>3}", fg="green")
    elif v <= 5:
        return click.style(f"{v:>3}", fg="yellow")
    return click.style(f"{v:>3}", fg="red")


def print_analysis_table(results: list[FunctionResult]) -> None:
    """Full analysis table with bug type, findings, difficulty, risk, issues."""
    n_pass: int = sum(1 for r in results if r.status == "pass")
    n_fail: int = sum(1 for r in results if r.status == "fail")

    line = f"\n  {n_pass} passed"
    if n_fail:
        line += click.style(f", {n_fail} failed", fg="red")
    click.echo(line)

    name_w: int = max(len(r.name) for r in results) + 2
    name_w = max(name_w, 14)

    # Header
    hdr = (
        f"  {'#':>3}  {'Function':<{name_w}}"
        f" {'Result':<7} {'Type':<11} {'Finding':<34}"
        f" {'Risk':<8}"
        f" {'D(spec)':>7} {'D(lean)':>7} {'D(proof)':>8}  Issue"
    )
    bar_w: int = 3 + 2 + name_w + 7 + 11 + 34 + 8 + 8 + 8 + 9 + 10
    bar = f"  {'─' * bar_w}"

    click.echo(f"\n{hdr}")
    click.echo(bar)

    for i, r in enumerate(results):
        # result
        if r.status == "pass":
            res = click.style("PASS", fg="green")
            res_pad = "PASS"
        else:
            res = click.style("FAIL", fg="red")
            res_pad = "FAIL"

        # bug type
        if r.bug_type == "bug":
            btype = click.style(f"{'bug':<11}", fg="red")
        elif r.bug_type == "edge case":
            btype = click.style(f"{'edge case':<11}", fg="yellow")
        else:
            btype = f"{'—':<11}"

        # finding
        finding = r.finding if r.finding else "—"
        finding_display = f"{finding[:33]:<34}"

        # risk
        if r.risk == "High":
            risk_display = click.style(f"{'High':<8}", fg="red")
        elif r.risk == "Medium":
            risk_display = click.style(f"{'Medium':<8}", fg="yellow")
        elif r.risk:
            risk_display = click.style(f"{r.risk:<8}", fg="green")
        else:
            risk_display = f"{'—':<8}"

        # difficulty
        spc = _diff_color(r.diff_spec)
        ln = _diff_color(r.diff_lean)
        prf = _diff_color(r.diff_proof)

        # issue link
        if r.issue_url:
            issue = click.style(f"#{r.issue_number}", fg="cyan", underline=True)
        elif r.issue_number:
            issue = click.style(f"#{r.issue_number}", fg="cyan")
        else:
            issue = "—"

        res_extra = " " * (7 - len(res_pad))
        click.echo(
            f"  {i + 1:>3}  {r.name:<{name_w}}"
            f" {res}{res_extra}{btype}{finding_display}"
            f" {risk_display}"
            f"    {spc}    {ln}     {prf}  {issue}"
        )

    click.echo(bar)


# ── Issue summary table ────────────────────────────────────────


def print_issue_summary(results: list[FunctionResult]) -> None:
    """Table of opened issues with URL, function, type, test result, risk."""
    failed = [r for r in results if r.status == "fail" and r.issue_number]
    if not failed:
        return

    click.echo(click.style(f"\n  Issue Summary ({len(failed)} issues)", bold=True))

    name_w: int = max(len(r.name) for r in failed) + 2
    url_w: int = max(len(r.issue_url) for r in failed if r.issue_url) if any(r.issue_url for r in failed) else 20

    hdr = (
        f"  {'#':>3}  {'Issue':<{url_w}}  "
        f"{'Function':<{name_w}} {'Bug Type':<11} {'Test Result':<16} Risk"
    )
    bar_w = 3 + 2 + url_w + 2 + name_w + 11 + 16 + 12
    bar = f"  {'─' * bar_w}"

    click.echo(f"\n{hdr}")
    click.echo(bar)

    for i, r in enumerate(failed, 1):
        url = r.issue_url if r.issue_url else f"#{r.issue_number}"
        url_display = click.style(f"{url:<{url_w}}", fg="cyan")

        if r.bug_type == "bug":
            btype = click.style(f"{'bug':<11}", fg="red")
        else:
            btype = click.style(f"{'edge case':<11}", fg="yellow")

        test_res = r.test_summary if r.test_summary else f"{r.failed} FAIL, {r.passed} PASS"

        if r.risk == "High":
            risk = click.style(r.risk, fg="red")
        elif r.risk == "Medium":
            risk = click.style(r.risk, fg="yellow")
        else:
            risk = click.style(r.risk, fg="green")

        click.echo(
            f"  {i:>3}  {url_display}  "
            f"{r.name:<{name_w}} {btype}{test_res:<16} {risk}"
        )

    click.echo(bar)


# ── Issue detail ────────────────────────────────────────────────


def print_issue_detail(result: FunctionResult, file_path: str) -> None:
    click.echo(f"\n  Issue:    spec-verify: {result.name}() — {result.failed} failing scenario(s)")
    click.echo(f"  Function: {result.name}()")
    click.echo(f"  File:     {file_path}")
    click.echo(f"  Status:   {result.failed} of {result.total} scenarios failing")

    click.echo(click.style("\n  Failing scenarios:", bold=True))
    for f in result.failures:
        click.echo(click.style(f"    ✗ {f}", fg="red"))

    passing: int = result.total - result.failed
    if passing > 0:
        click.echo(click.style(f"    ✓ {passing} other scenario(s) passing", fg="green", dim=True))

    if result.recommendation:
        click.echo(click.style(f"\n  Recommendation: {result.recommendation}", fg="yellow", bold=True))
