# Agent matrix — this machine (verified 2026-10-06 · extended by the aoe-native-agent program · Devin = CLI-only lane 2026-10-08)

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
| Hardest: architecture, complex bugs, large refactors, core logic, integration, RE / exploratory bring-up | **Devin CLI** (SWE-2) — only Devin lane | `devin --respect-workspace-trust=false --permission-mode dangerous -p --prompt-file <prompt-file>` | architecture proposals, TDD builds, unknown-root-cause bugs, live-system bring-up (self-adapts around blockers) |
| Medium: implementation, API/UI, tests, scoped independent tasks, build/run infra | **Cline** | `cline -P opencode -m opencode/deepseek-v4.1-flash-free -t 1380 "<prompt>"` | features, file edits, integration tests, build+run harnesses |
| Light: boilerplate, tests, docs, lint/typecheck, review, small fixes | **OpenCode** | `opencode run --model opencode/deepseek-v4.1-flash-free --title <name> "<prompt>"` | docs, unit tests, reviews, cleanups |
| Orchestration, verification, integration, git | **Hermes (self)** | — | split, prompts, verify ALL artifacts/claims, fix, integrate, final gate |

Never assign a strong agent to a light task; free models first.
Extended evidence (aoe-native-agent + freqtrade-kit + hermes-browser-kit programs, Oct 2026): Devin 10/10 first-try (incl. dynamic game bring-up T-702 — DirectDraw fail → windowed pivot, CD-check → MP-solo pivot; browser-kit T-201 bhkit core, selftest 13/13 first-pass; browser-kit M2 T-210 bounded net interception, E2E n=26 first-pass); Cline 7/7 (incl. T-801 + browser-kit T-202: provider died twice pre-verify → Hermes salvage after re-verification; browser-kit T-204: integrated regression 7/7, idempotent); OpenCode 5/5 (browser-kit T-203: bootstrap + installer + docs, run2 after external-read card fix; freqtrade-kit D1 — API-adaptation fix + regression test, card-in-file, default model, first-pass ~156s, tree-diff verified; browser-kit M2 T-211 session-pin module + own race found & fixed mid-run). 0 escalations needed. M2 wave (12/10): Cline T-209 salvaged — run 1 provider stream death (nothing written), run 2 with write-first preface wrote all 4 deliverables then hit the 1380s wall DURING its own final self-verify; Hermes reviewed + re-verified (selftest incl. o1-o3, VERIFY_OBSERVE n=5) + merged.

## Routing rules (quick)

- Low complexity + low risk → OpenCode · Medium → Cline · High/Critical, unknown root cause,
  architecture/core/integration → Devin (may go straight to Devin to avoid loops).
- Exploratory/unknown work (RE, live bring-up, plan will change) → Devin — it self-adapts when its
  first approach fails; pair with strict prompt rules (read-only paths, bounded experiments, cleanup).
- **2 failures by the same agent → escalate one tier up** (OpenCode → Cline → Devin). No third attempt.
- A "failure" is also: did nothing / partial artifact / auto-rejected calls — not just a crash.
- Cost-aware: cheapest agent that can safely finish; don't save in the wrong place.

### Routing memory (agent × task-type — living; update at DONE)

| Agent | First-try strengths (observed) | Weak spots → route elsewhere |
|---|---|---|
| Devin | architecture · core logic · RE / live bring-up · refactor · hard bugs with unknown cause · bounded protocol/net internals (10/10 first-try — aoe + browser-kit) | reserve for real difficulty |
| Cline | medium features · API/UI · docs · build+run infra (7/7 — aoe + browser-kit; 3 salvages: 2 provider-death + 1 wall-timeout) | long rewrite-from-corruption stalls without writing (28' live) → send to Devin; on wall-capped runs the final self-verify can eat the remaining `-t` wall with deliverables already on disk — inspect-first + salvage, do not relaunch (4th occurrence 16/10: T-102 Vietnam_Atlas wall-cap at self-verify, 6/6 deliverables on disk) |
| OpenCode | boilerplate · unit tests · docs · review/cleanup · small isolated defect fixes (5/5 — aoe + kit D1 + browser-kit) | over-explores on fuzzy tasks → give a write-first instruction |

Per round: record agent × task-type × outcome (+ failure mode, wall time) in the round ledger; consult this table before every assignment; update it at DONE. The table is the assignment ground truth — new evidence lands here.

## Pitfalls (observed live)

- **Devin — CLI**: print mode cannot answer permission prompts — needs `--permission-mode dangerous` +
  `--respect-workspace-trust=false` for out-of-workspace reads. Exit 0 ≠ success (verify the
  artifact). Leaves `.serena/` in the workspace (gitignored here). **Cards must forbid `.devin/**`
  writes** — ForceAsk even under `dangerous`: print mode rejects → run dies mid-flight (pending
  parallel writes cancelled, exit 0). Resume: `devin ... -c -p --prompt-file <follow-up>`.
  **Kill by path, never by name** —
  `Get-Process Devin` also matches the user's Devin DESKTOP app (`%LOCALAPPDATA%\Programs\Devin`,
  ~15 Electron processes, launched from explorer); CLI processes live under `%LOCALAPPDATA%\devin\cli\`
  — match the path when stopping.
- **Cline**: infra crashes possible mid-run (hook/socket, especially at large file writes) → exit 1
  with partial artifacts. Smoke-test recovery (say SMOKE_OK), retry once with a NARROWER scope,
  then escalate. Use `-t` (task timeout; default `TMO-120` = 1380) AND a shell `timeout` wrapper. **Provider stream errors
  can kill a run even at the final commit** — inspect the worktree; if the work is complete, the
  orchestrator completes the commit (see Field lessons). **Wall-timeout is the same lane:** T-209 run 2 (12/10)
  died at `-t` 1380s mid self-verify with every deliverable on disk — salvage (review + independent
  re-verify + merge) beats relaunch; a relaunch would have burned the whole work again.
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

## Round D — Vietnam_Atlas (16/10)

- **OpenCode T-101 (P0 fix lane)**: complete first-pass on 4 files + tests (89/89 worktree gates). Bot review later surfaced 3 real edge-case defects (loader guard for non-list `features`, partial-collection honesty, full-width CSV prefixes) → lead fix round. Budget a review-fix pass for edge-case hardening lanes.
- **Cline T-102 (new tooling + docs)**: wall-cap during final self-verify, all deliverables on disk (2nd consecutive wall-timeout salvage — pattern solid). It was mid-verifying the schtasks roundtrip; lead completed it and found a real bug: register script's `$RepoRoot` off by one directory → task registers fine, fails at fire time. Caught by a bot review, not by the agent's own tests → registration artifacts need the query-the-command probe (lead-orchestrator §6.3, 16/10).
- **Env**: MSYS `timeout` does NOT kill the native CLI child after the wrapper exits — reap by PID before worktree cleanup; an emptied husk dir can stay locked all session (lead-orchestrator §10).

## Launch

Use `scripts/launch-agent.sh` — it applies the exact commands above plus wall-clock `timeout`,
log redirect, and an `EXIT=<code>` marker. `--dry-run` prints the command without running.
