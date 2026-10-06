# Agent matrix — this machine (verified 2026-10-06)

## Roster

| Difficulty | Agent | Command (this machine) | Work it gets |
|---|---|---|---|
| Hardest: architecture, complex bugs, large refactors, core logic, integration | **Devin CLI** (SWE-2) | `devin --respect-workspace-trust false --permission-mode dangerous -p -- "<prompt>"` | architecture proposals, TDD builds, unknown-root-cause bugs |
| Medium: implementation, API/UI, tests, scoped independent tasks | **Cline** | `cline -P opencode-go -m longcat-2.5-preview-free -t 1200 "<prompt>"` | features, file edits, integration tests |
| Light: boilerplate, tests, docs, lint/typecheck, review, small fixes | **OpenCode** | `opencode run --model opencode/muse-spark-1.3-contributor-free --title <name> "<prompt>"` | docs, unit tests, reviews, cleanups |
| Orchestration, verification, integration, git | **Hermes (self)** | — | split, prompts, verify ALL artifacts/claims, fix, integrate, final gate |

Never assign a strong agent to a light task; free models first.

## Routing rules (quick)

- Low complexity + low risk → OpenCode · Medium → Cline · High/Critical, unknown root cause,
  architecture/core/integration → Devin (may go straight to Devin to avoid loops).
- **2 failures by the same agent → escalate one tier up** (OpenCode → Cline → Devin). No third attempt.
- A "failure" is also: did nothing / partial artifact / auto-rejected calls — not just a crash.
- Cost-aware: cheapest agent that can safely finish; don't save in the wrong place.

## Pitfalls (observed live)

- **Devin**: print mode cannot answer permission prompts — needs `--permission-mode dangerous` +
  `--respect-workspace-trust false` for out-of-workspace reads. Exit 0 ≠ success (verify the
  artifact). Leaves `.serena/` in the workspace (gitignored here).
- **Cline**: infra crashes possible mid-run (hook/socket, especially at large file writes) → exit 1
  with partial artifacts. Smoke-test recovery (say SMOKE_OK), retry once with a NARROWER scope,
  then escalate. Use `-t 1200` task timeout AND a shell `timeout` wrapper.
- **OpenCode**: auto-rejects reads outside the project (`permission.external_directory` in
  `opencode.json`) — add allow globs, then relaunch. Old runs can linger after a relaunch — check
  session ids / artifact mtimes. `--title <name>` labels runs.
- **All**: exit codes and self-reports are claims, not evidence. Free tiers throttle (429) —
  stagger heavy runs and design cooldowns. Keep prompts in files (`_prompts/<TASK>.md`) and pass
  via `"$(cat file)"` so runs are reproducible.

## Launch

Use `scripts/launch-agent.sh` — it applies the exact commands above plus wall-clock `timeout`,
log redirect, and an `EXIT=<code>` marker. `--dry-run` prints the command without running.
