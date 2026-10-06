#!/usr/bin/env python3
"""doc-stats.py — documentation & roadmap statistics for orchestrated projects.

Scans a project for documentation artifacts (root markdown, ``docs/**``,
``analysis/**``, ``.orchestrator/**``) and reports, per document: size,
last-commit date, and flags (stale vs HEAD, untracked, checklist); plus
roadmap checklist progress (done/open) and control-plane presence.

Why: orchestrated projects accumulate docs (control plane, specs, round
interfaces, roadmaps) that silently stop tracking reality. This tool gives the
orchestrator a five-second read on that drift. Stdlib-only; git optional
(falls back to file mtimes outside a repo).

Usage
-----
  python3 doc-stats.py [ROOT] [--stale-days N] [--include GLOB]... [--exclude NAME]...
                       [--json] [--out FILE] [--quiet] [--strict]

Exit codes: 0 ok (warnings allowed) · 1 warnings present AND --strict · 2 usage/IO error.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

SCHEMA = "doc-stats.v1"

DEFAULT_INCLUDES = (
    "README.md",
    "*.md",
    "docs/**/*.md",
    "analysis/**/*.md",
    ".orchestrator/**/*.md",
    ".orchestrator/*.json",
)

# Path components that are always skipped (build junk, caches, logs).
DEFAULT_EXCLUDE = {
    ".git", ".venv", "venv", "node_modules", "__pycache__",
    ".ruff_cache", ".pytest_cache", "agent_logs", "dist", "build",
}

CONTROL_PLANE_FILES = (
    "TASKS.json", "PROJECT_STATE.md", "VERIFICATION.md", "DECISIONS.md", "INTERFACES.md",
)

CHECKLIST_RE = re.compile(r"^\s*[-*]\s+\[([ xX])\]\s+")

KIND_ORDER = {"control-plane": 0, "root": 1, "docs": 2, "analysis": 3, "other": 4}


def _git(root: Path, *args: str) -> str | None:
    """Run a git query; return stripped stdout on success, None otherwise."""
    try:
        out = subprocess.run(
            ["git", "-C", str(root), *args],
            capture_output=True, text=True, timeout=30,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    return out.stdout.strip() if out.returncode == 0 else None


def _parse_iso(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(value)
    except ValueError:
        return None


def _kind(rel: str) -> str:
    if rel.startswith(".orchestrator/"):
        return "control-plane"
    if rel.startswith("docs/"):
        return "docs"
    if rel.startswith("analysis/"):
        return "analysis"
    if "/" not in rel:
        return "root"
    return "other"


def _collect(root: Path, includes: list[str], exclude: set[str]) -> list[tuple[str, Path]]:
    seen: dict[Path, Path] = {}
    for pat in includes:
        for p in sorted(root.glob(pat)):
            if p.is_file():
                seen[p.resolve()] = p
    docs: list[tuple[str, Path]] = []
    for path in seen.values():
        rel = path.relative_to(root).as_posix()
        if any(part in exclude for part in rel.split("/")[:-1]):
            continue
        docs.append((rel, path))
    return sorted(docs, key=lambda t: (KIND_ORDER[_kind(t[0])], t[0]))


def _analyze(args: argparse.Namespace) -> dict:
    root = Path(args.root)
    if not root.is_dir():
        raise SystemExit(f"error: root is not a directory: {args.root}")
    root = root.resolve()

    includes: list[str] = list(DEFAULT_INCLUDES) + [str(x) for x in args.include]
    exclude = set(DEFAULT_EXCLUDE) | set(args.exclude)
    docs = _collect(root, includes, exclude)

    is_repo = _git(root, "rev-parse", "--is-inside-work-tree") == "true"
    head_iso = _git(root, "log", "-1", "--format=%cI") if is_repo else None
    head_dt = _parse_iso(head_iso)

    entries: list[dict] = []
    roadmaps: list[dict] = []
    warnings: list[str] = []

    for rel, path in docs:
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
            nbytes = path.stat().st_size
        except OSError as exc:  # pragma: no cover - defensive
            warnings.append(f"unreadable: {rel} ({exc})")
            continue
        lines = len(text.splitlines())
        done = open_n = 0
        for ln in text.splitlines():
            m = CHECKLIST_RE.match(ln)
            if not m:
                continue
            if m.group(1).lower() == "x":
                done += 1
            else:
                open_n += 1

        flags: list[str] = []
        source = "mtime"
        last_dt: datetime | None = None
        if is_repo:
            iso = _git(root, "log", "-1", "--format=%cI", "--", rel)
            if iso:
                last_dt = _parse_iso(iso)
                source = "git"
            else:
                flags.append("untracked")
        if last_dt is None:
            last_dt = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc)

        if "untracked" not in flags and head_dt and last_dt:
            age_days = (head_dt - last_dt).total_seconds() / 86400.0
            if age_days > args.stale_days:
                flags.append("stale")
                warnings.append(
                    f"doc-stale: {rel} (last {last_dt.date()} vs head {head_dt.date()})"
                )
        else:
            age_days = None

        if done + open_n:
            roadmaps.append({"path": rel, "done": done, "open": open_n, "total": done + open_n})
            flags.append("checklist")

        entries.append({
            "path": rel,
            "kind": _kind(rel),
            "lines": lines,
            "bytes": nbytes,
            "last_commit_date": last_dt.isoformat(timespec="seconds"),
            "date_source": source,
            "age_days_vs_head": round(age_days, 1) if age_days is not None else None,
            "flags": flags,
        })

    cp_dir = root / ".orchestrator"
    dir_present = cp_dir.is_dir()
    if dir_present:
        present = [f for f in CONTROL_PLANE_FILES if (cp_dir / f).is_file()]
        missing = [f for f in CONTROL_PLANE_FILES if not (cp_dir / f).is_file()]
        if missing:
            warnings.append("control-plane missing: " + ", ".join(missing))
    else:
        present, missing = [], []

    if not entries:
        warnings.append(
            "no documentation files found (looked for: " + ", ".join(sorted(set(includes))) + ")"
        )

    totals = {
        "docs": len(entries),
        "lines": sum(e["lines"] for e in entries),
        "bytes": sum(e["bytes"] for e in entries),
        "roadmaps": len(roadmaps),
        "warnings": len(warnings),
    }
    return {
        "schema": SCHEMA,
        "root": str(root),
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "git": {"is_repo": is_repo, "head_commit_date": head_iso},
        "totals": totals,
        "docs": entries,
        "roadmaps": roadmaps,
        "control_plane": {"dir_present": dir_present, "present": present, "missing": missing},
        "warnings": warnings,
    }


def _render_md(data: dict) -> str:
    lines: list[str] = []
    g = data["git"]
    lines.append(f"# Doc stats — {data['root']}")
    lines.append("")
    git_note = f"head {g['head_commit_date']}" if g["is_repo"] and g["head_commit_date"] else (
        "no git" if not g["is_repo"] else "git (empty)"
    )
    t = data["totals"]
    lines.append(
        f"generated: {data['generated_at']} · {git_note} · "
        f"**{t['docs']} docs** · {t['lines']} lines · {t['bytes']} bytes · "
        f"{len(data['warnings'])} warning(s)"
    )
    lines.append("")
    lines.append("## Inventory")
    lines.append("")
    lines.append("| path | kind | lines | bytes | last | flags |")
    lines.append("|---|---|--:|--:|---|---|")
    for e in data["docs"]:
        last = e["last_commit_date"][:10] if e["last_commit_date"] else "-"
        flags = ", ".join(e["flags"]) or "-"
        lines.append(f"| `{e['path']}` | {e['kind']} | {e['lines']} | {e['bytes']} | {last} | {flags} |")
    lines.append("")
    lines.append("## Roadmaps / checklists")
    lines.append("")
    if data["roadmaps"]:
        lines.append("| doc | done | open | total | % |")
        lines.append("|---|--:|--:|--:|--:|")
        for r in data["roadmaps"]:
            pct = round(100 * r["done"] / r["total"]) if r["total"] else 0
            lines.append(f"| `{r['path']}` | {r['done']} | {r['open']} | {r['total']} | {pct}% |")
    else:
        lines.append("none found")
    lines.append("")
    lines.append("## Control plane")
    lines.append("")
    cp = data["control_plane"]
    if cp.get("dir_present"):
        lines.append("- present: " + (", ".join(cp["present"]) or "—"))
        lines.append("- missing: " + (", ".join(cp["missing"]) or "—"))
    else:
        lines.append("no `.orchestrator/` directory")
    lines.append("")
    lines.append("## Warnings")
    lines.append("")
    if data["warnings"]:
        lines.extend(f"- {w}" for w in data["warnings"])
    else:
        lines.append("none")
    lines.append("")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    reconfigure = getattr(sys.stdout, "reconfigure", None)
    if reconfigure:
        reconfigure(encoding="utf-8", errors="replace")
    parser = argparse.ArgumentParser(
        prog="doc-stats.py",
        description="Documentation & roadmap statistics (inventory, staleness vs HEAD, checklists).",
    )
    parser.add_argument("root", nargs="?", default=".", help="project root (default: .)")
    parser.add_argument("--stale-days", type=float, default=7.0,
                        help="flag a doc stale when it lags HEAD by more than N days (default 7)")
    parser.add_argument("--include", action="append", default=[],
                        help="extra glob(s) to include (repeatable; defaults stay)")
    parser.add_argument("--exclude", action="append", default=[],
                        help="extra path component(s) to skip (repeatable)")
    parser.add_argument("--json", action="store_true", help="emit JSON instead of markdown")
    parser.add_argument("--out", help="write the report to this file instead of stdout")
    parser.add_argument("--quiet", action="store_true",
                        help="with --out: print only the one-line summary")
    parser.add_argument("--strict", action="store_true",
                        help="exit 1 when warnings are present")
    args = parser.parse_args(argv)

    try:
        data = _analyze(args)
    except SystemExit as exc:
        print(str(exc))
        return 2

    content = json.dumps(data, indent=2, ensure_ascii=False) + "\n" if args.json else _render_md(data)

    if args.out:
        Path(args.out).write_text(content, encoding="utf-8")
        if not args.quiet:
            t = data["totals"]
            print(f"doc-stats: {t['docs']} docs · {t['lines']} lines · "
                  f"{t['warnings']} warning(s) → {args.out}")
    else:
        sys.stdout.write(content)

    if args.strict and data["warnings"]:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
