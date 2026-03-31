"""Display formatting — live table, steps, issue detail."""

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
    risk: str = ""  # "high" | "low"
    lean_ready: bool = False  # can be translated to Lean
    suggestion: str = ""  # "bug fix" | "refactor" | "translate to lean"


# ── Primitives ──────────────────────────────────────────────────


def print_header(title: str) -> None:
    click.echo(click.style(f"\n  {title}", bold=True))
    click.echo("  " + "=" * 62)


def print_step(step: int, total: int, msg: str, detail: str = "") -> None:
    click.echo(f"\n  [{step}/{total}] {msg}")
    if detail:
        click.echo(click.style(f"        → {detail}", dim=True))


# ── Live table ──────────────────────────────────────────────────


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
        """Set all cells in a column to the same value, single redraw."""
        for c in self.cells:
            c[column] = value
        self.redraw()


# ── Summary footer ──────────────────────────────────────────────


def print_summary_footer(results: list[FunctionResult]) -> None:
    n_pass: int = sum(1 for r in results if r.status == "pass")
    n_fail: int = sum(1 for r in results if r.status == "fail")

    line = f"\n  {n_pass} passed"
    if n_fail:
        line += click.style(f", {n_fail} failed", fg="red")
    click.echo(line)

    failed = [r for r in results if r.status == "fail"]
    if failed:
        click.echo()
        name_w: int = max(len(r.name) for r in failed) + 2
        for r in failed:
            tag = f"#{r.issue_number}" if r.issue_number else "—"
            risk_color = "red" if r.risk == "high" else "yellow"
            risk_display = click.style(f"risk: {r.risk:<4}", fg=risk_color)
            lean_display = click.style("lean: yes", fg="green") if r.lean_ready else click.style("lean: no ", fg="red")
            sug = click.style(f"suggest: {r.suggestion}", fg="yellow")
            click.echo(f"    {r.name:<{name_w}} → {tag:<8} {risk_display}  {lean_display}  {sug}")


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
