# Agent matrix — this machine (verified 2026-10-06 · extended by the aoe-native-agent program)

## The loop (canonical)

```
HERMES — Lead Orchestrator (split · assign · verify · integrate · git)
   ├── DEVIN    Expert  — architecture · core logic · hard bugs · refactor · complex debug · RE / exploratory bring-up
   ├── CLINE    Builder — features · API/UI · modules · integration · medium bugs · build/run infra
   └── OPENCODE Worker  — boilerplate · unit tests · docs · lint · typecheck
                            │
                     HERMES VERIFY (independent re-run — never trust self-reports)
                            ├── PASS → INTEGRATE (merge --no-ff + control-plane bookkeeping)
                            └── FAIL → FIX (same agent, exact failing evidence; fail #2 → ESCALATE to Devin)
                                        └── FINAL VERIFY (full gates) → DONE
```

## Roster

| Difficulty | Agent | Command (this machine) | Work it gets |
|---|---|---|---|
| Hardest: architecture, complex bugs, large refactors, core logic, integration, RE / exploratory bring-up | **Devin CLI** (SWE-2) | `devin --respect-workspace-trust false --permission-mode dangerous -p -- "<prompt>"` | architecture proposals, TDD builds, unknown-root-cause bugs, live-system bring-up (self-adapts around blockers) |
| Medium: implementation, API/UI, tests, scoped independent tasks, build/run infra | **Cline** | `cline -P opencode-go -m longcat-2.5-preview-free -t 1380 "<prompt>"` | features, file edits, integration tests, build+run harnesses |
| Light: boilerplate, tests, docs, lint/typecheck, review, small fixes | **OpenCode** | `opencode run --model opencode/muse-spark-1.3-contributor-free --title <name> "<prompt>"` | docs, unit tests, reviews, cleanups |
| Orchestration, verification, integration, git | **Hermes (self)** | — | split, prompts, verify ALL artifacts/claims, fix, integrate, final gate |

Never assign a strong agent to a light task; free models first.
Extended evidence (aoe-native-agent program, Oct 2026): Devin 8/8 first-try (incl. dynamic game bring-up T-702 — DirectDraw fail → windowed pivot, CD-check → MP-solo pivot); Cline 4/4 (incl. T-801: provider died pre-commit → Hermes completed the commit after re-verification); OpenCode 2/2 (write-first when it over-explores). 0 escalations needed.

## Routing rules (quick)

- Low complexity + low risk → OpenCode · Medium → Cline · High/Critical, unknown root cause,
  architecture/core/integration → Devin (may go straight to Devin to avoid loops).
- Exploratory/unknown work (RE, live bring-up, plan will change) → Devin — it self-adapts when its
  first approach fails; pair with strict prompt rules (read-only paths, bounded experiments, cleanup).
- **2 failures by the same agent → escalate one tier up** (OpenCode → Cline → Devin). No third attempt.
- A "failure" is also: did nothing / partial artifact / auto-rejected calls — not just a crash.
- Cost-aware: cheapest agent that can safely finish; don't save in the wrong place.

## Pitfalls (observed live)

- **Devin**: print mode cannot answer permission prompts — needs `--permission-mode dangerous` +
  `--respect-workspace-trust false` for out-of-workspace reads. Exit 0 ≠ success (verify the
  artifact). Leaves `.serena/` in the workspace (gitignored here). **Kill by path, never by name** —
  `Get-Process Devin` also matches the user's Devin DESKTOP app (`%LOCALAPPDATA%\Programs\Devin`,
  ~15 Electron processes, launched from explorer); CLI processes live under `%LOCALAPPDATA%\devin\cli\`
  — match the path when stopping.
- **Cline**: infra crashes possible mid-run (hook/socket, especially at large file writes) → exit 1
  with partial artifacts. Smoke-test recovery (say SMOKE_OK), retry once with a NARROWER scope,
  then escalate. Use `-t` (task timeout; default `TMO-120` = 1380) AND a shell `timeout` wrapper. **Provider stream errors
  can kill a run even at the final commit** — inspect the worktree; if the work is complete, the
  orchestrator completes the commit (see Field lessons).
- **OpenCode**: auto-rejects reads outside the project (`permission.external_directory` in
  `opencode.json`) — add allow globs, then relaunch. Old runs can linger after a relaunch — check
  session ids / artifact mtimes. `--title <name>` labels runs.
- **All**: exit codes and self-reports are claims, not evidence. Free tiers throttle (429) —
  stagger heavy runs and design cooldowns. Keep prompts in files (`_prompts/<TASK>.md`) and pass
  via `"$(cat file)"` so runs are reproducible.

## Field lessons (aoe-native-agent program, Oct 2026)

- **Provider death ≠ task failure**: runs can die mid-flight on provider stream errors ("hook
  dispatch failed" / "Response stream ended without a finish reason", exit 1) — even at the final
  commit step. Inspect the worktree first: if deliverables + evidence are complete and the
  acceptance re-run is green, Hermes completes the commit on the task branch (prompt's message)
  and logs the provenance — no re-run needed.
- **Kill by path, never by name** (Devin CLI vs Devin desktop app — see Pitfalls); after stopping
  an agent + its child processes, verify machine state (processes gone, display restored).
- **Pause = first-class op**: on user pause, kill agent + children, verify quiet, write
  `_prompts/T-xxx-resume.md` (state · tool paths · continuation steps); resume = re-dispatch with a
  continuation prompt pointing at that note.
- **Scope check is THREE-dot** (`git diff main...HEAD`) — two-dot shows phantom noise once main
  moves ahead (and it confuses agents doing their own diff checks).
- **Control plane = source of truth**: `.orchestrator/` (TASKS.json · VERIFICATION.md · DECISIONS.md
  · PROJECT_STATE.md) updated in the SAME session as the merge, as a separate bookkeeping commit.
- **Write-first for over-explorers**: "STOP exploring — WRITE the deliverable now, refine after".

## Launch

Use `scripts/launch-agent.sh` — it applies the exact commands above plus wall-clock `timeout`,
log redirect, and an `EXIT=<code>` marker. `--dry-run` prints the command without running.
