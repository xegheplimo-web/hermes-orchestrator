# Agent matrix — this machine (verified 2026-10-06 · Devin = SOLE coding lane 2026-10-08)

> **D-015 status:** Devin CLI is the sole coding agent. Cline and OpenCode CLIs
> remain installed on disk for non-coding CLI tasks (auth, probes, one-off
> commands) but are **removed from the coding roster, routing, retry, and
> fallback**. This document is the single source of truth for dispatch.

## The loop (canonical)

```
HERMES — Lead Orchestrator (split · assign · verify · integrate · git)
   ├── DEVIN    Expert  — architecture · core logic · hard bugs · refactor · complex debug · RE / exploratory bring-up
   │                            │
   │                     HERMES VERIFY (independent re-run — never trust self-reports)
   │                            ├── PASS → INTEGRATE (merge --no-ff + control-plane bookkeeping)
   │                            └── FAIL → FIX (same agent, exact failing evidence; fail #2 → ESCALATE to hermes self-help)
   │                                        └── FINAL VERIFY (full gates) → DONE
```

## Roster

| Difficulty | Agent | Command (this machine) | Work it gets |
|---|---|---|---|
| Hardest: architecture, complex bugs, large refactors, core logic, integration, RE / exploratory bring-up | **Devin CLI** (SWE-2) — only coding lane | `devin --respect-workspace-trust=false --permission-mode dangerous --model swe-2-max -p --prompt-file <prompt-file>` | architecture proposals, TDD builds, unknown-root-cause bugs, live-system bring-up (self-adapts around blockers) |
| Orchestration, verification, integration, git | **Hermes (self)** | — | split, prompts, verify ALL artifacts/claims, fix, integrate, final gate |

**Cline / OpenCode (retained, non-coding):** still installed on disk
(`cline`, `opencode` on PATH) for one-off non-coding CLI tasks — auth probes,
health checks, config dumps. They are **not** dispatched for coding. If a
coding task somehow lands on them, the launcher rejects it (D-015).

Never assign a strong agent to a light task; free models first.

## Routing rules (quick)

- **All coding work goes to Devin** (D-015). No Cline / OpenCode coding lane.
- **2 failures by Devin on the same task → escalate to Hermes self-help**
  (inspect the worktree, complete the commit, merge). No third automated attempt.
- A "failure" is also: did nothing / partial artifact / auto-rejected calls — not just a crash.
- Cost-aware: Devin SWE-2 is the default; caller may down-grade per task via
  `--model` (e.g. `swe-2-high`, `swe-2-medium`) for lighter work. Don't waste
  the strongest lane on trivial tasks.

### Routing memory (agent × task-type — living; update at DONE)

| Agent | First-try strengths (observed) | Weak spots → route elsewhere |
|---|---|---|
| Devin | architecture · core logic · RE / live bring-up · refactor · hard bugs with unknown cause · bounded protocol/net internals | reserve for real difficulty; inspect worktree after wall-cap — deliverables often on disk at the final self-verify |

Per round: record agent × task-type × outcome (+ failure mode, wall time) in the round ledger.

## Pitfalls (observed live)

- **Devin — CLI**: print mode cannot answer permission prompts — needs `--permission-mode dangerous` +
  `--respect-workspace-trust=false` for out-of-workspace reads. Exit 0 ≠ success (verify the
  artifact). Leaves `.serena/` in the workspace (gitignored here). **Cards must forbid `.devin/**`**
  writes — ForceAsk even under `dangerous`: print mode rejects → run dies mid-flight (pending
  parallel writes cancelled, exit 0). Resume: `devin ... -c -p --prompt-file <follow-up>`.
  **Kill by path, never by name** —
  `Get-Process Devin` also matches the user's Devin DESKTOP app (`%LOCALAPPDATA%\Programs\Devin`,
  ~15 Electron processes, launched from explorer); CLI processes live under `%LOCALAPPDATA%\devin\cli\`
  — match the path when stopping.
- **All**: exit codes and self-reports are claims, not evidence. Free tiers throttle (429) —
  stagger heavy runs and design cooldowns. Keep prompts in files (`_prompts/<TASK>.md`) and pass
  via `\"$(cat file)\"` so runs are reproducible.

## Field lessons (aoe-native-agent program, Oct 2026)

- **Provider death ≠ task failure**: runs can die mid-flight on provider stream errors ("hook
  dispatch failed" / "Response stream ended without a finish reason", exit 1) — even at the final
  commit step. Inspect the worktree first: if deliverables + evidence are complete and the
  acceptance re-run is green, Hermes completes the commit on the task branch (prompt's message)
  and logs the provenance — no re-run needed.
- **Kill by PATH, never by name** (Devin CLI vs Devin desktop app — see Pitfalls); after stopping
  an agent + its child processes, verify machine state (processes gone, display restored).
- **Pause = first-class op**: on user pause, kill agent + children, verify quiet, write
  `_prompts/T-xxx-resume.md` (state · tool paths · continuation steps); resume = re-dispatch with a
  continuation prompt pointing at that note.
- **Scope check is THREE-dot** (`git diff main...HEAD`) — two-dot shows phantom noise once main
  moves ahead (and it confuses agents doing their own diff checks).
- **Control plane = source of truth**: `.orchestrator/` (TASKS.json · VERIFICATION.md · DECISIONS.md
  · PROJECT_STATE.md) updated in the SAME session as the merge, as a separate bookkeeping commit.
- **Write-first for over-explorers**: "STOP exploring — WRITE the deliverable now, refine after".

## Round D — Vietnam_Atlas (16/10)

- **Devin T-102 (wall-cap salvage pattern)**: wall-timeout during final self-verify, all
  deliverables on disk — salvage (review + independent re-verify + merge) beats relaunch.
  A relaunch would have burned the entire work again. (Original was a Cline run; the
  wall-cap salvage pattern is confirmed for Devin too.)
- **Env**: MSYS `timeout` does NOT kill the native CLI child after the wrapper exits — reap by PID
  before worktree cleanup; an emptied husk dir can stay locked all session (lead-orchestrator §10).

## Launch

Use `scripts/launch-agent.sh` — it applies the exact command above (timeout + log + `EXIT=`
marker + `--model swe-2-max` default). `--dry-run` prints the command without running.
Cline and OpenCode invocations are rejected with exit code 2 (D-015).
