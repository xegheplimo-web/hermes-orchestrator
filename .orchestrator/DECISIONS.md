# DECISIONS

One entry per binding decision. Newest at the bottom. Frozen interfaces/names change only via a new entry.

## D-001 (2026-10-06) — Kit created

- New repo `E:\hermes-orchestrator` materializes Sếp's canonical Lead Orchestrator brief into a
  reusable kit: canonical prompt + templates + control-plane scaffold + launch scripts.

## D-002 (2026-10-06) — PROMPT.md is canonical

- `PROMPT.md` reproduces the brief verbatim (formatting cleaned only). It is the system/project
  orchestrator prompt for any project run with this kit; changes go through this file.

## D-003 (2026-10-06) — Git ownership

- Agents write files; **Hermes owns git** (commit / merge / push). One task = one worktree =
  one branch (`task/<id>-<slug>`) created by `scripts/new-task-worktree.sh`.

## D-004 (2026-10-06) — Repo published (public GitHub)

- Kit repo published as <https://github.com/xegheplimo-web/hermes-orchestrator> (public), paired
  with the Hermes skill `lead-orchestrator`. Push discipline stays D-003: agents never push; Hermes
  owns remote operations. Repo-local `core.autocrlf false` pinned (CRLF ghost-diff prevention).
- `docs/installation.md` is the canonical onboarding path (verified commands + expected outputs);
  keep it in sync when CLI versions or launch conventions change.
