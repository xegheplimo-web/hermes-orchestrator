# PROJECT STATE — hermes-orchestrator

**Project**: Lead Orchestrator kit — canonical orchestrator prompt + templates + control-plane scaffold + agent launch scripts.
**Philosophy**: Hermes = reviewer + QA gate + integration owner; Devin / Cline / OpenCode = workers.
**Repo**: `E:\hermes-orchestrator` · **Worktrees**: `E:\hermes-orchestrator-worktrees\<TASK-ID>`

## Current milestone
**M0 — kit bootstrap** (created 2026-10-06): repo + canonical prompt + templates + scripts + control plane; self-test green.

## Completed
- 2026-10-06 — **T-001** kit bootstrap: `PROMPT.md`, `docs/`, `templates/`, `scripts/`; smoke test PASS (see `VERIFICATION.md`); initial commit on `main`.

## In progress
- none

## Next up (backlog — see TASKS.json)
- T-101 status renderer (`TASKS.json` → compact board, python stdlib).
- T-102 secret-scan pre-commit hook. T-103 CI (shellcheck + smoke).
- Use case #1: run the first real multi-agent project on top of this kit.

## Blocked
- none

## Key decisions (see DECISIONS.md)
- **D-001** kit created · **D-002** `PROMPT.md` is the canonical prompt · **D-003** agents write files, Hermes owns git.
