# doc-stats — documentation & roadmap statistics

`scripts/doc-stats.py` reads a project's documentation state in one shot:
inventory, drift vs the repo's HEAD, roadmap checklist progress, and
control-plane health. Born from a real gap: orchestrated projects accumulate
docs (control plane, specs, round-interface freezes, roadmaps) that silently
stop tracking reality — e.g. a `SPEC.md` frozen at round 2 while the repo is at
round 7. This tool catches that drift mechanically instead of by memory.

## What it reports

- **Inventory** — every doc under the default globs (root `*.md`, `docs/**`,
  `analysis/**`, `.orchestrator/**`) with kind, lines, bytes, last-commit date,
  and flags (`stale`, `untracked`, `checklist`).
- **Drift warnings** — a doc whose last commit lags the repo's HEAD by more
  than `--stale-days` (default 7) is flagged `stale` and listed under
  Warnings.
- **Roadmap progress** — checklist lines (`- [x]` / `- [ ]`) counted per doc:
  done / open / total / %.
- **Control-plane audit** — presence of
  `.orchestrator/{TASKS.json,PROJECT_STATE.md,VERIFICATION.md,DECISIONS.md,INTERFACES.md}`
  (a missing-file warning fires only when a `.orchestrator/` dir exists).

Stdlib-only, git optional (mtime fallback outside a repo).

## Usage

```bash
python3 scripts/doc-stats.py E:/my-project                 # markdown to stdout
python3 scripts/doc-stats.py . --stale-days 14             # looser drift window
python3 scripts/doc-stats.py . --json --out doc-stats.json # machine-readable
python3 scripts/doc-stats.py . --strict                    # exit 1 when warnings
python3 scripts/doc-stats.py . --include "research/**/*.md" --exclude evidence
```

Exit codes: `0` ok (warnings allowed) · `1` warnings present AND `--strict` ·
`2` usage/IO error.

## When to run (orchestration flow)

- **Round 0 SCAN** — snapshot the project's doc state into the round's evidence
  pack (cheap, offline).
- **Audit / final verify** — re-run and require: no NEW `stale` warnings on
  docs the round touched; control plane updated in the same session as the
  merge (governance v3 bookkeeping rule).
- **Before a pause/resume note** — confirm the resume note points at docs that
  are actually current.

## Self-test

```bash
bash scripts/test-doc-stats.sh    # 10 checks; also wired into smoke-test.sh
```

Fixtures cover: stale detection with fixed git dates, roadmap counts,
control-plane present/missing, `--json` contract, `--out`, `--strict` exit
codes, exit-2 on a missing root, fresh-project `--strict` (exit 0), and the
no-git mtime fallback.
