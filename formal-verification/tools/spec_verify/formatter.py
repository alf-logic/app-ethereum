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
    lean_tests: int = 0  # number of Lean native_decide tests


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


# ── Lean live table ────────────────────────────────────────────


class LeanTable:
    """Terminal table for Lean translation progress."""

    COLUMNS = ("Lean Code", "Lean Tests", "Theorems", "Validation")

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
            f" {'Lean Code':<11} {'Lean Tests':<12} {'Theorems':<10} Validation"
        )
        lines.append(hdr)
        lines.append(f"  {'─' * (3 + 2 + self.name_w + 11 + 12 + 10 + 18)}")

        for i, name in enumerate(self.names):
            c = self.cells[i]
            v = c["Validation"]
            if "PASS" in v:
                v_display = click.style(v, fg="green")
            elif "FAIL" in v:
                v_display = click.style(v, fg="red")
            else:
                v_display = v
            lines.append(
                f"  {i + 1:>3}  {name:<{self.name_w}}"
                f" {c['Lean Code']:<11} {c['Lean Tests']:<12} {c['Theorems']:<10} {v_display}"
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


# ── Lean summary table ─────────────────────────────────────────


def _styled_pad(text: str, styled: str, width: int) -> str:
    """Pad a styled string to a fixed visible width."""
    return styled + " " * (width - len(text))


def print_lean_summary(results: list[FunctionResult]) -> None:
    """Summary table for Lean pipeline — code, tests, theorems + difficulty."""
    nw: int = max(len(r.name) for r in results) + 2
    cw, tw, thw, dw = 8, 8, 11, 13

    hdr = (
        f"  {'#':>3}  {'Function':<{nw}} "
        f"{'Code':<{cw}}{'Tests':<{tw}}{'Theorems':<{thw}}"
        f"{'Difficulty':<{dw}}Status"
    )
    bar_w = 3 + 2 + nw + 1 + cw + tw + thw + dw + 6
    bar = f"  {'─' * bar_w}"

    click.echo(f"\n{hdr}")
    click.echo(bar)

    check = click.style("✓", fg="green")

    for i, r in enumerate(results):
        label, color = _diff_label(r.diff_proof)
        dp = _styled_pad(label, click.style(label, fg=color), dw)
        status = click.style("PASS", fg="green")

        click.echo(
            f"  {i + 1:>3}  {r.name:<{nw}} "
            f"{_styled_pad('✓', check, cw)}"
            f"{_styled_pad('✓', check, tw)}"
            f"{_styled_pad('✓', check, thw)}"
            f"{dp}{status}"
        )

    click.echo(bar)

    total_lean: int = sum((r.lean_tests if r.lean_tests else r.total) for r in results)
    click.echo(
        f"\n  {len(results)} functions translated, "
        f"{total_lean} tests verified via native_decide"
    )


# ── Analysis table (function summary) ──────────────────────────


def _diff_label(v: int) -> tuple[str, str]:
    """Convert 1-10 score to easy/medium/hard with color."""
    if v <= 2:
        return "easy", "green"
    elif v <= 5:
        return "medium", "yellow"
    return "hard", "red"


def print_analysis_table(results: list[FunctionResult]) -> None:
    """Full analysis table with bug type, findings, difficulty, risk, issues."""
    n_pass: int = sum(1 for r in results if r.status == "pass")
    n_fail: int = sum(1 for r in results if r.status == "fail")

    line = f"\n  {n_pass} passed"
    if n_fail:
        line += click.style(f", {n_fail} failed", fg="red")
    click.echo(line)

    nw: int = max(len(r.name) for r in results) + 2
    nw = max(nw, 14)
    dw: int = 8  # width for each difficulty column

    hdr = (
        f"  {'#':>3}  {'Function':<{nw}} "
        f"{'Result':<7} {'Type':<11} {'Finding':<32} "
        f"{'Risk':<11} "
        f"{'D(spec)':<{dw}} {'D(lean)':<{dw}} {'D(proof)':<{dw}} "
        f"Issue"
    )
    bar_w: int = 3 + 2 + nw + 1 + 7 + 11 + 32 + 1 + 11 + 1 + dw * 3 + 1 + 6
    bar = f"  {'─' * bar_w}"

    click.echo(f"\n{hdr}")
    click.echo(bar)

    for i, r in enumerate(results):
        # result column (pad manually for ANSI)
        if r.status == "pass":
            res = click.style("PASS", fg="green") + "   "
        else:
            res = click.style("FAIL", fg="red") + "   "

        # bug type
        if r.bug_type == "bug":
            btype = click.style("bug", fg="red") + " " * 8
        elif r.bug_type == "edge case":
            btype = click.style("edge case", fg="yellow") + " " * 2
        else:
            btype = "—" + " " * 10

        # finding
        finding = (r.finding if r.finding else "—")[:31]
        finding_display = f"{finding:<32} "

        # risk
        if r.risk == "High":
            risk_d = click.style("High", fg="red") + " " * 7
        elif r.risk == "Medium":
            risk_d = click.style("Medium", fg="yellow") + " " * 5
        elif r.risk:
            rtext = r.risk[:10]
            risk_d = click.style(rtext, fg="green") + " " * (11 - len(rtext))
        else:
            risk_d = "—" + " " * 10

        # difficulty (easy/medium/hard)
        def _dcol(v: int) -> str:
            label, color = _diff_label(v)
            return click.style(label, fg=color) + " " * (dw - len(label))

        ds = _dcol(r.diff_spec)
        dl = _dcol(r.diff_lean)
        dp = _dcol(r.diff_proof)

        # issue
        if r.issue_url:
            issue = click.style(f"#{r.issue_number}", fg="cyan", underline=True)
        elif r.issue_number:
            issue = click.style(f"#{r.issue_number}", fg="cyan")
        else:
            issue = "—"

        click.echo(
            f"  {i + 1:>3}  {r.name:<{nw}} "
            f"{res}{btype}{finding_display}"
            f"{risk_d}"
            f"{ds}{dl}{dp}"
            f"{issue}"
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


# ── Fix / PR summary table ─────────────────────────────────────


@dataclass
class FixResult:
    issue_number: int
    issue_url: str
    branch: str
    fix_desc: str
    tests: str  # e.g. "4/4 PASS"
    pr_url: str


def print_fix_summary(fixes: list[FixResult]) -> None:
    """Table of completed fixes with issue, branch, fix, tests, PR."""
    click.echo(click.style(f"\n  Fix Summary ({len(fixes)} PRs created)", bold=True))

    iw: int = max(len(f.issue_url) for f in fixes) + 1
    bw: int = max(len(f.branch) for f in fixes) + 1
    fw: int = max(len(f.fix_desc) for f in fixes) + 1
    tw: int = 7
    pw: int = max(len(f.pr_url) for f in fixes) + 1

    hdr = f"  {'#':>3}  {'Issue':<{iw}} {'Branch':<{bw}} {'Fix':<{fw}} {'Tests':<{tw}} PR"
    bar_w = 3 + 2 + iw + bw + fw + tw + pw + 6
    bar = f"  {'─' * bar_w}"

    click.echo(f"\n{hdr}")
    click.echo(bar)

    for i, f in enumerate(fixes, 1):
        issue = click.style(f"{f.issue_url:<{iw}}", fg="cyan")
        branch = click.style(f"{f.branch:<{bw}}", fg="yellow")
        tests = click.style(f"{f.tests:<{tw}}", fg="green")
        pr = click.style(f.pr_url, fg="cyan")
        click.echo(f"  {i:>3}  {issue} {branch} {f.fix_desc:<{fw}} {tests} {pr}")

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
