# Hermes — Lead Orchestrator kit

A reusable control tower for running **Devin CLI + Cline + OpenCode** as one verified software
team under **Hermes as Lead Orchestrator**: Analyze → Split → Assign → Execute → Verify →
Fix/Reassign → Integrate → Final Verify. Core law: *an agent saying "done" is not DONE* — only
orchestrator verification makes DONE.

Born on this machine (`E:\hermes-orchestrator`, 2026-10-06) from Sếp's canonical brief. Pairs with
the Hermes skill `lead-orchestrator`.

**Repo:** <https://github.com/xegheplimo-web/hermes-orchestrator> ·
**Setup:** [`docs/installation.md`](docs/installation.md) — the full verified installation guide.

## Layout

| Path | Purpose |
|---|---|
| `PROMPT.md` | Canonical system/project orchestrator prompt (Vietnamese). **§0 = core vận hành (bản ngắn — Lead Orchestrator + Technical Owner, Recon → … → Final Verify; Sếp chốt 2026-10-07)**; §1–§31 = bản chi tiết tham chiếu. |
| `docs/agent-matrix.md` | Machine roster: exact CLIs/models, routing rules, escalation, per-agent pitfalls. |
| `docs/gates.md` | Build gates + DONE definition + per-stack command sets + diff hygiene. |
| `docs/git-orchestration.md` | Worktree-per-task flow; who may touch git; merge discipline. |
| `docs/governance.md` | Governance v3: permission tiers (AUTO/GATED/BLOCKED), maintenance lane, audit cadence, result contract, live guard hook. |
| `docs/installation.md` | Full installation & setup guide — prerequisites, agent CLIs, provider auth, skill + guard hook, kit self-test, verification checklist (verified commands + expected outputs). |
| `templates/task-card.md` | Mandatory task format (prompt §7). |
| `templates/decision-plan.md` | Pre-execution plan format (§28). |
| `templates/final-report.md` | Final report format (§30). |
| `templates/project.yaml` | Machine-readable project profile — Round-0 SCAN artifact (governance v3). |
| `templates/result.json` | Agent result contract, written per task (governance v3). |
| `templates/control-plane/` | Starter `.orchestrator/` files for a new project (`{{PROJECT_NAME}}`, `{{DATE}}`). |
| `scripts/bootstrap-project.sh` | Scaffold a new orchestrated project (control plane + agent work dirs + .gitignore). |
| `scripts/new-task-worktree.sh` | Create `task/<id>-<slug>` worktree for a task. |
| `scripts/launch-agent.sh` | Launch cline/opencode/devin (CLI lanes) on a prompt file: timeout + log + exit marker (`--dry-run`). |
| `scripts/smoke-test.sh` | Self-test for all scripts (throwaway project in a temp dir), incl. the doc-stats self-test. |
| `scripts/doc-stats.py` | Documentation & roadmap statistics for a project: inventory, staleness vs HEAD, checklist progress, control-plane audit (`--json`, `--strict`). |
| `scripts/agent-hooks/` | Guard hook `block-dangerous.sh` + 19 synthetic tests — mirror of the live hook at `%LOCALAPPDATA%\hermes\agent-hooks\`. |

## Install

Full step-by-step setup (prerequisites → agent CLIs → provider auth → Hermes skill + guard hook →
kit self-test → verification checklist): [`docs/installation.md`](docs/installation.md).
Short path:

```bash
npm install -g cline opencode-ai          # Devin CLI: official installer from cli.devin.ai (see the guide)
cline auth -p opencode-go -k <KEY> -m longcat-2.5-preview-free
git clone https://github.com/xegheplimo-web/hermes-orchestrator E:/hermes-orchestrator
bash E:/hermes-orchestrator/scripts/smoke-test.sh     # expect: 43 passed / 0 failed
```

## Quickstart — orchestrate a project

1. **Bootstrap** the target project:

   ```bash
   bash scripts/bootstrap-project.sh E:/my-project
   ```

   Creates `E:/my-project/.orchestrator/` (rendered from templates), `agent_logs/`,
   `E:/my-project-worktrees/{_prompts,_logs}`, and git-inits if needed.

2. **Split & assign** per `PROMPT.md` §5–§7: fill `.orchestrator/TASKS.json`, one task = one
   worktree = one branch.

3. **Dispatch** a task:

   ```bash
   bash scripts/new-task-worktree.sh E:/my-project E:/my-project-worktrees T-101 short-slug
   # write the task card to E:/my-project-worktrees/_prompts/T-101.md
   bash scripts/launch-agent.sh devin E:/my-project-worktrees/T-101 E:/my-project-worktrees/_prompts/T-101.md --title T-101
   ```

4. **Verify** (never trust exit code / self-report): diff review + gates yourself
   (`docs/gates.md`), then integrate. Hermes owns all git operations.

## Conventions

- One task = one worktree = one branch (`task/<id>-<slug>`); never two agents in one scope.
- Agents write files; **Hermes owns git** (commit / merge / push).
- Escalation ladder: OpenCode → Cline → Devin (2 failures → escalate; no third attempt).
- Repo artifacts in English; reports to the user in Vietnamese.

## Self-test

```bash
bash scripts/smoke-test.sh
```

Boots a throwaway project in a temp dir and asserts every script contract. Exit 0 = all green.
