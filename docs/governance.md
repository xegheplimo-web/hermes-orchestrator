# Governance v3 — permissions, maintenance lane, audit (2026-10-06)

Adopted from an external proposal review, trimmed to stay consistent with the proven kit
(see `PROMPT.md` + skill `lead-orchestrator`, `docs/gates.md`, `docs/git-orchestration.md`). Scope: orchestrated project runs.

## 1. Permission tiers

Enforced by (a) the verify gates — Hermes re-runs everything itself — and (b) a live guard hook,
never by prompt hope.

| Tier | Actions |
|---|---|
| **AUTO** | Read source · search web/docs · create branch/worktree · edit files inside the project · run tests/build/lint · install project-local deps · call Devin/Cline/OpenCode · write/run tests · use trusted skills/MCP |
| **GATED** (explicit approval / round decision) | Global package installs · system package managers (apt/choco/brew/winget) · adding MCP servers or Hermes plugins · API keys/secrets changes · production DB migrations · production deploys · push/merge to protected branches · CI/CD changes · important Hermes config changes |
| **BLOCKED during a run** | Live Hermes core self-modification · disabling tests or security checks to pass · deleting the main repo/worktree · force-push · database drops · running untrusted installs |

### Live guard hook (installed)

- Script: `~/.hermes/agent-hooks/block-dangerous.sh` — `pre_tool_call` hook, matcher `terminal`, fail-open, timeout 10s.
- Registered in `~/.hermes/config.yaml` (`hooks.pre_tool_call`, `hooks_auto_accept: true`); manage via
  `hermes config set …` and verify with `hermes hooks doctor`.
- Blocks, from real incidents only: **force-push** · **name-based kills of user-facing apps**
  (Devin desktop / Hermes / cline-app — kill CLIs by exact path instead) · **`rm -rf` of protected
  roots** (main repos / Hermes home — subpaths like worktrees stay allowed).
- Audit trail: `~/.hermes/logs/guard.log` (one line per fire: BLOCK/ALLOW + command).
- Tests: `scripts/agent-hooks/test-guard.sh` (19 synthetic cases incl. false-positive checks; 2026-10-07 refinement: read-only `Get-Process` queries allowed, pipeline kills blocked).
  Extend patterns ONLY with an incident behind them.

## 2. Maintenance lane (infra failure ≠ project failure)

When something keeps failing, classify before touching code:

```
PROJECT / AGENT / MODEL / TOOL / ENVIRONMENT / ORCHESTRATOR failure?
        │
PAUSE affected task  →  snapshot (config/state backup)  →  diagnose
        →  fix  →  doctor / smoke test  →  canary (small real run)
        →  PASS ? RESUME PROJECT  :  ROLLBACK maintenance
```

Never keep "fixing" project code when the fault is infrastructure. Hermes self-changes run
between rounds only — never while agent CLIs are working.

## 3. Audit cadence

- **Light audit** — every task: one ledger row (agent · model · outcome · wall time · retries ·
  where verify failed · who finally fixed it) in the round's verification doc.
- **Deep audit** — every ~10 tasks or when the failure rate spikes: routing accuracy, per-agent
  success rate, average retries, tool/dependency failures, commonly missed tests, over-escalations,
  over-expensive assignments, repeated bugs, slow commands, broken skills/plugins.
- Deep audit may adjust **routing rules / skills / prompts only** — never core. Routing changes come
  from data, not vibes (e.g. "UI task: OpenCode 48% → Cline 91%" ⇒ reroute).

## 4. Result contract

Every agent task writes `agent_logs/<task>_result.json` (schema: `templates/result.json`):
`status · files_changed[] · tests_run[] · tests_passed · issues[] · summary`.
Hermes re-runs the task's VERIFY commands regardless — the contract feeds the ledger, it is not trust.

## 5. Capability rule

Install a new tool only when it solves a **current missing capability**:
built-in → official skill → MCP catalog → plugin catalog → project dependency → minimal proposal.
Never because "it might be useful". This is what keeps the system from bloating.

## 6. Trimmed from the proposal (with reasons)

- **`agent-router` plugin** — the kit scripts + skills already fill this role; revisit only on real friction.
- **GPT critic** — existing escalation chain + RESCUE BRIEF covers it; use ad hoc for high-risk diffs.
- **Logs outside the repo** — kept in-repo (`agent_logs/`) as the evidence trail.
- **Single project.yaml as sole state** — `.orchestrator/` stays canonical (richer);
  `templates/project.yaml` seeds its machine-readable profile.
