# AGENTS.md — hermes-orchestrator

This repo is the **Hermes Lead Orchestrator kit**: the canonical orchestrator prompt, task
templates, a control-plane scaffold, and launch scripts used to run **Devin CLI / Cline / OpenCode** as a verified multi-agent team under **Hermes** as Lead Orchestrator.

## For agent workers

- You work here only when a task card explicitly dispatches you; the card's scope wins.
- Never edit `.orchestrator/**` or this file; propose changes in your final report.
- Never run state-changing git commands (commit / merge / rebase / push); Hermes owns git.
- Artifacts in English; evidence required (exact commands + real output). No fabrication.
- Full rules: `.orchestrator/AGENT_RULES.md`. Gates: `docs/gates.md`.

## For Hermes (orchestrator)

- Canonical prompt: `PROMPT.md`. Roster + routing: `docs/agent-matrix.md`.
- State: `.orchestrator/PROJECT_STATE.md` · tasks: `.orchestrator/TASKS.json`.
- Dispatch: `scripts/launch-agent.sh` (+ `scripts/new-task-worktree.sh` for isolation).
