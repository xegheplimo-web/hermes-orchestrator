# PROJECT STATE — hermes-orchestrator

**Project**: Lead Orchestrator kit — canonical orchestrator prompt + templates + control-plane scaffold + agent launch scripts.
**Philosophy**: Hermes = reviewer + QA gate + integration owner; Devin / Cline / OpenCode = workers.
**Repo**: `E:\hermes-orchestrator` → <https://github.com/xegheplimo-web/hermes-orchestrator> (public) · **Worktrees**: `E:\hermes-orchestrator-worktrees\<TASK-ID>`

## Current milestone
**M1 — published** (2026-10-06): public GitHub remote live + full installation guide (`docs/installation.md`) + README install section; self-test re-verified green (42/42 — re-verified again 2026-10-07 after CLI upgrades).

## Completed
- 2026-10-06 — **T-001** kit bootstrap: `PROMPT.md`, `docs/`, `templates/`, `scripts/`; smoke test PASS (see `VERIFICATION.md`); initial commit on `main`.
- 2026-10-06 — **T-104** GitHub publish: public repo `xegheplimo-web/hermes-orchestrator`; `origin` + `main` tracking set; push verified via `git ls-remote`; secrets scan clean.
- 2026-10-06 — **T-105** installation guide: `docs/installation.md` (verified commands + expected outputs, 9 sections) + README install section; CLI syntax re-verified against installed `--help` for all three agents.
- 2026-10-07 — **T-106** upgrade lane: opencode **1.18.35** · devin **3000.11.3** (`9c803229faa4`) · Superpowers plugin live (`superpowers:*`); §9 re-verify green; `docs/installation.md` synced (evidence in `VERIFICATION.md`).
- 2026-10-07 — **T-107** preflight: `scripts/preflight.sh` — 1-command §9 check (versions · 3× dry-run · flag greps; canary 11/11, smoke 43/43); lesson sync vào 5 skills (npm --prefix → opencode/cline-cli; update-check topology quirk → hermes-self-upgrade; cross-pointer → multi-agent-orchestration).

## In progress
- none

## Next up (backlog — see TASKS.json)
- T-101 status renderer (`TASKS.json` → compact board, python stdlib).
- T-102 secret-scan pre-commit hook. T-103 CI (shellcheck + smoke). T-108 round ledger from `agent_logs/*_result.json` (new).
- Use case #1: run the first real multi-agent project on top of this kit.

## Blocked
- none

## Key decisions (see DECISIONS.md)
- **D-001** kit created · **D-002** `PROMPT.md` is the canonical prompt · **D-003** agents write files, Hermes owns git · **D-004** repo published public on GitHub (Hermes owns push).
