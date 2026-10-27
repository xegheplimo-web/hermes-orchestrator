# Installation — full setup guide

Reconstructs the whole orchestration stack on a Windows machine: **Hermes as Lead Orchestrator**
driving **Devin CLI as the sole coding agent (D-015)** with a live guard hook and a self-tested script kit.

Verified end-to-end on the machine this kit was born on (2026-10-06; re-verified 2026-10-07 after CLI upgrades; Devin = CLI-only lane 2026-10-08): every command below was
executed, and the "expected" values are real observed output — a fresh install can be validated
line by line against this document.

## 0. Component map

| # | Component | Role in the loop | Location (this machine) |
|---|---|---|---|
| 1 | **Hermes Agent** (desktop, profile `default`) | Orchestrator: split · assign · verify · integrate · owns git | `%LOCALAPPDATA%\hermes` (`config.yaml` · `skills\` · `agent-hooks\`) |
| 2 | **This kit repo** | Canonical prompt + docs + templates + scripts + control plane | `E:\hermes-orchestrator` |
| 3 | **Devin CLI** | Expert worker — architecture, core logic, hard bugs, RE/bring-up | `%LOCALAPPDATA%\devin\cli\bin\devin.exe` |
| 4 | **Cline CLI** *(retained: non-coding only)* | One-off non-coding CLI tasks (auth, probes); removed from coding roster (D-015) | npm global shim `%APPDATA%\npm\cline` |
| 5 | **OpenCode CLI** *(retained: non-coding only)* | One-off non-coding CLI tasks (auth, probes); removed from coding roster (D-015) | npm global shim `%APPDATA%\npm\opencode` |
| 6 | **Skill `lead-orchestrator`** | The process playbook Hermes loads per round | `%LOCALAPPDATA%\hermes\skills\autonomous-ai-agents\lead-orchestrator\SKILL.md` |
| 7 | **Guard hook `block-dangerous.sh`** | Live `pre_tool_call` safety net (fail-open) | `%LOCALAPPDATA%\hermes\agent-hooks\block-dangerous.sh` |

Path conventions across this stack: projects live at `E:\<project>`; per-task worktrees at
`E:\<project>-worktrees\<TASK-ID>`; task prompts in `_prompts\`, run logs in `<worktrees-root>/_logs/` (outside worktrees, survives cleanup).

## 1. Prerequisites

- Windows 10/11 x64 with **git-bash** in PATH (Hermes terminal runs bash/MSYS).
- **Node.js ≥ 20 + npm** — this machine uses the Node bundled with Hermes:
  `%LOCALAPPDATA%\hermes\tools\node-26.7.0-win32-x64` (v26.7.0, npm 11.19.0).
  Check: `node --version && npm --version`.
- **Python 3.11+** — used by `scripts/doc-stats.py`. Check: `python --version`.
- **Hermes Agent** installed and working (desktop app). Check: `hermes hooks doctor` runs.
- Accounts / keys: a **Devin** account (CLI login: `devin auth login`). Cline and OpenCode CLIs
  remain installed for non-coding CLI tasks (D-015) but no longer need provider auth for coding.
- Optional: GitHub CLI for push discipline — check `gh auth status`.

## 2. Install the agent CLIs

### 2.1 Devin CLI (sole coding lane, D-015)

Install (official Cognition routes — macOS/Linux/WSL, Windows, Homebrew):

```bash
# macOS / Linux / WSL
curl -fsSL https://cli.devin.ai/install.sh | bash

# Windows — download and run the installer (x86_64 shown; ARM64 build also published)
#   https://static.devin.ai/cli/devin-updater-x86_64-pc-windows.exe
# or from PowerShell:
irm https://static.devin.ai/cli/setup.ps1 | iex
```

This lands the CLI under `%LOCALAPPDATA%\devin\cli\` (self-updates with `devin update`;
`devin update --force` re-installs). Restart the terminal after install.

Verify + authenticate:

```bash
devin --version          # expected: devin 3000.11.3 (9c803229faa4)  (verified 2026-10-07)
devin auth login         # or the interactive wizard: devin setup
devin auth status
devin doctor             # expected: 2 check(s): 2 passed, 0 warning(s), 0 failure(s)
```

Non-interactive launch — canonical form (flags verified on v3000.11.3):

```bash
devin --respect-workspace-trust=false --permission-mode dangerous --model swe-2-max -p --prompt-file <prompt-file>
```

- `-p` runs print mode (non-interactive); `--prompt-file` reads the task card from disk — no
  Windows argv limit, no quoting pitfalls (the kit launcher passes it for you).
- `--respect-workspace-trust=false` is **mandatory in fresh dirs**: print mode cannot show the
  trust prompt and fails in an untrusted directory. Note the `=` form: as an optional-value flag
  (devin ≥3000), `--respect-workspace-trust false` (space) swallows the value, `--permission-mode`
  stops taking effect, and every write is rejected in print mode (verified 2026-10-18).
- `--permission-mode dangerous` auto-approves all tools — required for reads/writes outside the
  agent's workspace.
- Default model: SWE-2 family (`DEVIN_MODEL` default `swe-2-max`); pin per task with `--model`.

### 2.2 Cline CLI *(retained: non-coding only)*

Cline CLI remains installed on disk for one-off non-coding CLI tasks (auth, probes). It is
**not** dispatched for coding (D-015 — Devin is the sole coding lane). The Cline provider auth
from the multi-agent era may be retained for interactive probes but is not needed for coding:

```bash
# one-off non-coding use only
cline --version
```

### 2.3 OpenCode CLI *(retained: non-coding only)*

OpenCode CLI remains installed on disk for one-off non-coding CLI tasks. It is **not** dispatched
for coding (D-015). The opencode config and auth from the multi-agent era are retained for probes:

```bash
# one-off non-coding use only
opencode --version
```

## 3. Hermes side — skill + guard hook

### 3.1 Skill `lead-orchestrator`

Place the skill (and its companion agent skills `devin-cli`,
`multi-agent-orchestration`) under:

```
%LOCALAPPDATA%\hermes\skills\autonomous-ai-agents\<skill-name>\SKILL.md
```

Reload the session (`/new`) and confirm the skill is listed. Division of labour: **the skill is
the in-session playbook** (routing, verification discipline, pitfalls); **this repo is the
machine-side kit** (scripts + docs + templates + control plane).

### 3.2 Guard hook (live, fail-open)

The guard is a `pre_tool_call` shell hook that blocks catastrophic terminal calls (force-push,
name-based kills of the user's own apps, `rm -rf` of protected roots). A hook failure never blocks
work — it fails open.

1. Install the script (kit copy → live location):

   ```bash
   mkdir -p "$LOCALAPPDATA/hermes/agent-hooks"
   cp scripts/agent-hooks/block-dangerous.sh "$LOCALAPPDATA/hermes/agent-hooks/"
   chmod +x "$LOCALAPPDATA/hermes/agent-hooks/block-dangerous.sh"
   ```

2. Register it in `%LOCALAPPDATA%\hermes\config.yaml`:

   ```yaml
   hooks:
     pre_tool_call:
       - matcher: terminal
         command: C:/Users/<you>/AppData/Local/hermes/agent-hooks/block-dangerous.sh
         timeout: 10
   hooks_auto_accept: true
   ```

3. Consent: the first use prompts once on a TTY and records the approval (command + script mtime)
   in the allowlist beside the config (`%LOCALAPPDATA%\hermes\shell-hooks-allowlist.json`).
   Non-interactive runs need `hooks_auto_accept: true` (as above) or `--accept-hooks`.
   **After editing the script, re-approve** — mtime drift invalidates consent.

4. Verify:

   ```bash
   hermes hooks doctor                      # expect: exists+executable ✓ · allowlisted ✓ · unchanged ✓ · runs clean ✓
   bash scripts/agent-hooks/test-guard.sh   # expect: 19 pass, 0 fail   (re-verified 2026-10-07)
   ```

### 3.3 Superpowers plugin (optional — quality methodology)

Methodology skill pack for Hermes sessions (github.com/obra/superpowers; installed 2026-10-07):

```bash
hermes plugins install obra/superpowers --enable --yes-deps    # community source -> scan CAUTION; add --force after reviewing the findings
hermes plugins doctor superpowers                              # expect: import + registration passed · 1 hook
```

- Skills load namespaced (`superpowers:*`); the bootstrap injects on the FIRST turn of each new session (no post-compaction hook — start a fresh session if skills stop triggering).
- Restart the gateway / desktop app for already-running processes to pick it up.
- Optional telemetry opt-out: `SUPERPOWERS_DISABLE_TELEMETRY=1`.

## 4. Kit — install & self-test

```bash
git clone https://github.com/xegheplimo-web/hermes-orchestrator E:/hermes-orchestrator
cd E:/hermes-orchestrator && bash scripts/smoke-test.sh
# expected: SMOKE: ALL GREEN — 84 passed, 0 failed
```

The smoke test boots a throwaway project in a temp dir and asserts every script contract
(bootstrap, worktree, launch dry-runs, doc-stats self-test).

For a one-command §9 convention re-check — CLI versions + the three launch dry-runs + the key
flags in the live CLIs + `devin doctor` + a banned-token drift scan (§3b–§3c) —
run `bash scripts/preflight.sh` (exit ≠ 0 = drift; run it after ANY CLI upgrade and before a round).

## 5. First orchestrated project (quickstart)

```bash
bash scripts/bootstrap-project.sh E:/my-project
bash scripts/new-task-worktree.sh E:/my-project E:/my-project-worktrees T-101 short-slug
$EDITOR E:/my-project-worktrees/_prompts/T-101.md        # task card — templates/task-card.md
bash scripts/launch-agent.sh devin E:/my-project-worktrees/T-101 E:/my-project-worktrees/_prompts/T-101.md --dry-run
bash scripts/launch-agent.sh devin E:/my-project-worktrees/T-101 E:/my-project-worktrees/_prompts/T-101.md --title T-101
```

Then follow `docs/git-orchestration.md` for verify → merge → bookkeeping. Hermes owns git, always.

## 6. Launch conventions (verified commands)

| Agent | Command (run from the task worktree; prompt from file) |
|---|---|
| devin | `timeout 2400 devin --respect-workspace-trust=false --permission-mode dangerous --model swe-2-max -p --prompt-file <prompt-file>` |

`scripts/launch-agent.sh` wraps exactly these (timeout + log + `EXIT=` marker); `--dry-run` prints
the composed command. Operational rules learned live (details: `docs/agent-matrix.md`):

### Runtime evidence (RUNS.jsonl)

- `.orchestrator/RUNS.jsonl` (gitignored raw telemetry) is scaffolded by `scripts/bootstrap-project.sh` (empty file, never overwritten).
- `scripts/record-run.py` appends one `hermes.run.v1` JSON object per line; required fields: `run_id`, `task_id`, `agent`, `model`, `task_type`, `duration_s`, `exit_code`, `provider_failure`, `verify_status`, `retry_index`, `verified_by` (plus `salvaged`, `timestamp`).
- Agent ∈ {devin, hermes} (D-015: Devin is sole coding lane); verify_status ∈ {PASS, FAIL, PENDING, UNVERIFIED}. Duplicate `run_id` is rejected (retry = new run_id). Failed runs are recorded as-is; the tool never rewrites a verdict.
- Hermes (not the agent lane) writes the final verdict; the tool is append-only mechanism.

- **Long runs must survive the parent session**: spawn with `persist_on_release=true`
  (Hermes `terminal(background=true, notify=true, persist_on_release=true)`); otherwise lifecycle
  events (compression, new session) SIGTERM mid-run agents.
- **Watchdog**: an agent that hasn't written its artifact in ~15 min is a failure — kill by PID and
  go to fail #1 (same agent, exact evidence). Completion = log stability, not process exit.
- **Kill by PATH, never by name** (a name-based kill matches the user's Devin desktop app).
- **Free tiers throttle (429)** — stagger heavy runs; prompts for live APIs get a politeness rule
  (≥1.5 s between calls) and capped batch sizes.

## 7. Verification checklist (prove the install)

| # | Check | Command | Expected |
|---|---|---|---|
| 1 | Devin CLI present | `devin --version` | devin 3000.11.3 |
| 2 | Devin health | `devin doctor` | 2 passed, 0 failures |
| 3 | Hook registered | `hermes hooks doctor` | all checks green |
| 4 | Hook behavior | `bash scripts/agent-hooks/test-guard.sh` | 19 pass / 0 fail |
| 5 | Kit scripts | `bash scripts/smoke-test.sh` | 84 passed / 0 failed |
| 6 | Launch dry-run (devin) | `bash scripts/launch-agent.sh devin <workdir> <prompt> --dry-run` | prints canonical devin command, no side effects |
| 7 | Launch rejects cline | `bash scripts/launch-agent.sh cline <workdir> <prompt> --dry-run` | exit 2, mentions D-015 |
| 8 | Launch rejects opencode | `bash scripts/launch-agent.sh opencode <workdir> <prompt> --dry-run` | exit 2, mentions D-015 |
| 9 | One-command §9 re-check | `bash scripts/preflight.sh` | `PREFLIGHT: NN passed, 0 failed` — run it; the live count is printed by the script |

## 8. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Native tool errors "cannot change to" / "not found" on paths | Native programs (git, .exe) do not understand MSYS `/e/...` or `/tmp` paths | Pass `E:/...` / `C:/...` (or `cygpath -m`), and use `$TMPDIR` (already a Windows dir) for native tools |
| Agent killed mid-run (`exit_code -15`, empty output) | Session lifecycle cleanup reaped the background process | Relaunch with `persist_on_release=true`; after any kill, check what actually landed on disk before deciding to re-run |
| Devin "planning" without writing, ~15+ min | Over-deliberation stall | Kill by PID (never by name); fail #1 = narrower scope; fail #2 = escalate to Hermes self-help with a rescue brief |
| Run exits 0 but the artifact is missing/partial | Agent claim ≠ evidence | Always verify the artifact + re-run gates yourself; provider-death runs may still have complete work on disk |
| Devin exit 0 but no artifact | Trust/permission issue in print mode | Use `=` form: `--respect-workspace-trust=false`; pass Windows-style prompt file path |
| Ghost diffs / "Committer identity unknown" in worktrees | Missing repo-local identity / CRLF | Pin repo-local `user.name`, `user.email`, `core.autocrlf false` |
| Scope diff shows phantom noise once main moved | Two-dot diff | Use three-dot: `git diff main...HEAD` |
| Devin 429 / "Model is unavailable" | Free-tier throttle | Stagger runs, respect cooldowns; re-check the live catalog |
| `npm i -g <pkg>` fails with EPERM under `...\hermes\tools\node-*` | Bundled npm's default global prefix points into the Hermes tools dir | Install with an explicit prefix: `npm i -g <pkg> --prefix "$APPDATA/npm"` (same dir as the existing CLI shims), then re-check `<cli> --version` |
| Devin update fails: `devin.exe` "being used by another process" | A running devin CLI session holds the exe | Wait for devin sessions to exit, re-run `irm https://cli.devin.ai/install.ps1 \| iex`, verify `devin --version` |
| `devin --prompt-file` → `Failed to read prompt file` | Path not readable by the native binary (MSYS `/e/...` style, or wrong cwd) | Pass a Windows-style path (`E:/...`; the kit launcher converts via `cygpath -m`) |

## 9. Machine inventory (verified 2026-10-06; re-verified 2026-10-07; Devin = CLI-only lane 2026-10-08)

| Item | Value |
|---|---|
| devin (CLI) | 3000.11.3 `9c803229faa4` (`%LOCALAPPDATA%\devin\cli\bin\devin.exe`) |
| cline / opencode | retained on disk for non-coding CLI tasks (D-015) |
| node / npm | v26.7.0 / 11.19.0 (Node bundled with Hermes) |
| kit smoke test | 84 passed / 0 failed |
| guard hook | kit mirror **identical** to live; 19/19 synthetic tests; re-approved 2026-10-07 after the read-only-query refinement |
| `hermes hooks doctor` | healthy — exists · allowlisted · unchanged · runs clean |
| superpowers plugin | 6.4.2 (`hermes plugins`; skills namespaced `superpowers:*`; up to date) |
