# PROJECT STATE — hermes-orchestrator

**Project**: Lead Orchestrator kit — canonical orchestrator prompt + templates + control-plane scaffold + agent launch scripts.
**Philosophy**: Hermes = reviewer + QA gate + integration owner; Devin / Cline / OpenCode = workers.
**Repo**: `E:\hermes-orchestrator` → <https://github.com/xegheplimo-web/hermes-orchestrator> (public) · **Worktrees**: `E:\hermes-orchestrator-worktrees\<TASK-ID>`

## Current milestone
**M1 — published** (2026-10-06): public GitHub remote live + full installation guide (`docs/installation.md`) + README install section; self-test re-verified green (42/42 — re-verified again 2026-10-07 after CLI upgrades).
**M2 — Devin cloud lane** (2026-10-08 AM): D-007 adopted (MCP/API primary) — **reverted the same day via D-008**; the MCP add step was never run (lane chưa từng được đăng ký).
**M3 — Devin = CLI-only convention** (2026-10-08): D-008 đảo D-007 — bỏ hẳn lane MCP/API khỏi skill + kit; `lead-orchestrator` v1.4.5 · `devin-cli` v1.4.0 (rename về) · preflight §3c banned-token drift scan; gates re-run green (see `VERIFICATION.md`).

## Completed
- 2026-10-06 — **T-001** kit bootstrap: `PROMPT.md`, `docs/`, `templates/`, `scripts/`; smoke test PASS (see `VERIFICATION.md`); initial commit on `main`.
- 2026-10-06 — **T-104** GitHub publish: public repo `xegheplimo-web/hermes-orchestrator`; `origin` + `main` tracking set; push verified via `git ls-remote`; secrets scan clean.
- 2026-10-06 — **T-105** installation guide: `docs/installation.md` (verified commands + expected outputs, 9 sections) + README install section; CLI syntax re-verified against installed `--help` for all three agents.
- 2026-10-07 — **T-106** upgrade lane: opencode **1.18.35** · devin **3000.11.3** (`9c803229faa4`) · Superpowers plugin live (`superpowers:*`); §9 re-verify green; `docs/installation.md` synced (evidence in `VERIFICATION.md`).
- 2026-10-07 — **T-107** preflight: `scripts/preflight.sh` — 1-command §9 check (versions · 3× dry-run · flag greps; canary 11/11, smoke 43/43); lesson sync vào 5 skills (npm --prefix → opencode/cline-cli; update-check topology quirk → hermes-self-upgrade; cross-pointer → multi-agent-orchestration).
- 2026-10-07 — **T-109** PR review loop adopted (D-005): `resolve-reviews` / `resolve-agent-reviews` / `resolve-human-reviews` skills installed via Hub (pbakaus/agent-reviews, MIT) + `docs/git-orchestration.md` §PR review loop + `gates.md` DONE line + `PROMPT.md` §16 extension; smoke re-run green (see `VERIFICATION.md`).
- 2026-10-07 — **T-110** cline `-t` drift sync (after 23c476f): preflight expectation → `-t 1380` + 9 stale literals across docs/README/skill + smoke-count rows (42→43); gates re-verified (PREFLIGHT 11/11 · SMOKE 43/43).
- 2026-10-07 — **T-111** §0 core vận hành adopted (D-006): `PROMPT.md` §0 (bản ngắn của Sếp — Lead Orchestrator + Technical Owner) + `docs/agent-matrix.md` Routing memory + skill `lead-orchestrator` §0/§13 + `multi-agent-orchestration` standing rules; gates re-run green (see `VERIFICATION.md`).
- 2026-10-08 — **T-112** Devin lane → cloud MCP/API (D-007): skill `lead-orchestrator` v1.3.0 (§1/§6/§9) + `devin-cli` v1.1.0; kit sync (PROMPT §2/§3 · agent-matrix · installation §0–§9 · README · AGENTS · preflight §3b); drift fix guard-test 16→19; gates re-run (see `VERIFICATION.md`).
- 2026-10-08 — **T-113** Devin lane → CLI-only (D-008, đảo D-007): skill `lead-orchestrator` v1.4.5 + rename `devin-cli` v1.4.0 (từ `devin-mcp`); kit sweep (PROMPT · agent-matrix · installation · README · AGENTS · preflight §3c `devin doctor` + banned-token scan · launcher `--prompt-file`/cygpath · smoke); retire 1-click `Them-Devin-MCP.cmd`; gates re-run green (see `VERIFICATION.md`).

## In progress
- none

## Next up (backlog — see TASKS.json)
- T-101 status renderer (`TASKS.json` → compact board, python stdlib).
- T-102 secret-scan pre-commit hook. T-103 CI (shellcheck + smoke). T-108 round ledger from `agent_logs/*_result.json` (new).
- Use case #1: run the first real multi-agent project on top of this kit.

## Blocked
- none

## Key decisions (see DECISIONS.md)
- **D-001** kit created · **D-002** `PROMPT.md` is the canonical prompt · **D-003** agents write files, Hermes owns git · **D-004** repo published public on GitHub (Hermes owns push) · **D-005** PR review loop adopted (zero unanswered review comments before DONE) · **D-006** §0 core vận hành + routing memory (2026-10-07) · **D-007** Devin lane → cloud MCP/API (2026-10-08 · reversed same day) · **D-008** Devin = CLI-only — single lane, no MCP/API (đảo D-007) (2026-10-08).
