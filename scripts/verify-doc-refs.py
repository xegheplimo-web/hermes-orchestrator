#!/usr/bin/env python3
"""verify-doc-refs.py - mechanical citation/token verifier for doc waves.

Built for orchestrated analysis rounds ("doc waves", see skill lead-orchestrator):
each agent writes ONE markdown doc citing real files/tokens; the orchestrator
re-checks mechanically instead of trusting prose.

Checks (combine with --mode):
  refs    - every path-like reference in the doc must exist under one of the
            --root trees. References are collected from backticked spans,
            bare tokens containing '/' + a file extension, and bracket-tag
            refs like ``[src: path]``. ':line' / ':a-b' suffixes and trailing
            punctuation are normalized away before checking.
  tokens  - every backticked token matching --token-regex (default:
            '^(--[a-z]|VLLM_)' = CLI flags + env vars) must appear somewhere
            under --root (grep -F, run with '-e' so '--flag' tokens are
            patterns, not grep options).

Usage:
  python verify-doc-refs.py DOC.md --root ROOT [--root ROOT2 ...]
      [--mode refs|tokens|both]      (default: both)
      [--token-regex RE]             (default '^(--[a-z]|VLLM_)')
      [--limit N]                    (missing entries printed, default 30)

Exit: 0 = all referenced, 1 = missing refs/tokens found, 2 = usage error.
Windows note: token mode needs `grep` on PATH (git-bash/MSYS). ref mode is
pure stdlib and cross-platform.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

LINE_SUFFIX = re.compile(r":\d+(?:-\d+)?$")
TRAIL = ".,;:)]}>`'\""
EXT_RE = re.compile(r"\.[A-Za-z0-9]*[A-Za-z][A-Za-z0-9]{0,7}$")
BRACKET_REF = re.compile(r"\[\w+:\s*([^\]\n]+)\]")
BARE_PATH = re.compile(r"(?<![\w`:/\\-])([A-Za-z0-9_][\w.\-]*(?:[/\\][\w.\-]+)+)")
BACKTICK = re.compile(r"`([^`\n]+)`")


def normalize(tok: str) -> str:
    t = tok.strip().strip(TRAIL).strip()
    t = LINE_SUFFIX.sub("", t)
    t = t.strip(TRAIL).strip()
    return t.replace("\\", "/")


def skip_token(t: str, skips: list[re.Pattern]) -> bool:
    if any(ch in t for ch in "<>{}%*") or " " in t:
        return True
    return any(s.search(t) for s in skips)


def collect_refs(text: str) -> set[str]:
    cands: set[str] = set()
    for span in BACKTICK.findall(text):
        cands.add(span.strip())
    for m in BRACKET_REF.finditer(text):
        cands.add(m.group(1).strip())
    for m in BARE_PATH.finditer(text):
        cands.add(m.group(1))
    return cands


def is_pathish(t: str) -> bool:
    if "://" in t or t.lower().startswith(("http", "www.", "mailto")):
        return False
    if " " in t:
        return False
    if not EXT_RE.search(t):
        return False
    return "/" in t


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="verify-doc-refs.py")
    ap.add_argument("doc")
    ap.add_argument("--root", action="append", required=True,
                    help="base tree (repeatable); refs are resolved under each")
    ap.add_argument("--mode", choices=("refs", "tokens", "both"), default="both")
    ap.add_argument("--token-regex", default=r"^(--[a-z]|VLLM_)")
    ap.add_argument("--limit", type=int, default=30)
    ap.add_argument("--skip", action="append", default=[],
                    help="regex of refs/tokens to ignore (repeatable)")
    args = ap.parse_args(argv)

    doc = Path(args.doc)
    if not doc.exists():
        print(f"usage error: doc not found: {doc}", file=sys.stderr)
        return 2
    roots = [Path(r) for r in args.root]
    for r in roots:
        if not r.exists():
            print(f"usage error: root not found: {r}", file=sys.stderr)
            return 2
    skips = [re.compile(s) for s in args.skip]
    text = doc.read_text(encoding="utf-8", errors="replace")
    rc = 0

    if args.mode in ("refs", "both"):
        refs = sorted({normalize(c) for c in collect_refs(text)})
        refs = [r for r in refs if is_pathish(r) and not skip_token(r, skips)]
        missing = [r for r in refs if not any((root / r).exists() for root in roots)]
        print(f"== refs: checked={len(refs)} missing={len(missing)}")
        for m in missing[: args.limit]:
            print(f"   MISSING: {m}")
        if missing:
            rc = 1

    if args.mode in ("tokens", "both"):
        tok_re = re.compile(args.token_regex)
        toks = sorted({normalize(c) for c in BACKTICK.findall(text)})
        toks = [t for t in toks if tok_re.match(t) and not skip_token(t, skips)]
        missing = []
        for t in toks:
            found = False
            for root in roots:
                out = subprocess.run(
                    ["grep", "-rl", "-F", "-e", t, str(root)],
                    capture_output=True, text=True,
                )
                if out.stdout.strip():
                    found = True
                    break
            if not found:
                missing.append(t)
        print(f"== tokens: checked={len(toks)} missing={len(missing)}")
        for m in missing[: args.limit]:
            print(f"   MISSING: {m}")
        if missing:
            rc = 1

    return rc


if __name__ == "__main__":
    sys.exit(main())
