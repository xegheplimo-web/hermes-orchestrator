# Installation — full setup guide

Reconstructs the whole orchestration stack on a Windows machine: **Hermes as Lead Orchestrator**
driving three CLI coding agents (**Devin = hard · Cline = medium · OpenCode = light**) with a live
guard hook and a self-tested script kit.

Verified end-to-end on the machine this kit was born on (2026-10-06; re-verified 2026-10-07 after CLI upgrades): every command below was
executed, and the "expected" values are real observed output — a fresh install can be validated
line by line against this document.

## 0. Component map

| # | Component | Role in the loop | Location (this machine) |
|---|---|---|---|
| 1 | **Hermes Agent** (desktop, profile `default`) | Orchestrator: split · assign · verify · integrate · owns git | `%LOCALAPPDATA%\hermes` (`config.yaml` · `skills\` · `agent-hooks\`) |
| 2 | **This kit repo** | Canonical prompt + docs + templates + scripts + control plane | `E:\hermes-orchestrator` |
| 3 | **Devin CLI** | Expert worker — architecture, core logic, hard bugs, RE/bring-up | `%LOCALAPPDATA%\devin\cli\bin\devin.exe` |
| 4 | **Cline CLI** | Builder worker — features, API/UI, tests, build/run infra | npm global shim `%APPDATA%\npm\cline` |
| 5 | **OpenCode CLI** | Worker — boilerplate, docs, unit tests, lint/typecheck | npm global shim `%APPDATA%\npm\opencode` |
| 6 | **Skill `lead-orchestrator`** | The process playbook Hermes loads per round | `%LOCALAPPDATA%\hermes\skills\autonomous-ai-agents\lead-orchestrator\SKILL.md` |
| 7 | **Guard hook `block-dangerous.sh`** | Live `pre_tool_call` safety net (fail-open) | `%LOCALAPPDATA%\hermes\agent-hooks\block-dangerous.sh` |

Path conventions across this stack: projects live at `E:\<project>`; per-task worktrees at
`E:\<project>-worktrees\<TASK-ID>`; task prompts in `_prompts\`, run logs in `agent_logs\`.

## 1. Prerequisites

- Windows 10/11 x64 with **git-bash** in PATH (Hermes terminal runs bash/MSYS).
- **Node.js ≥ 20 + npm** — this machine uses the Node bundled with Hermes:
  `%LOCALAPPDATA%\hermes\tools\node-26.7.0-win32-x64` (v26.7.0, npm 11.19.0).
  Check: `node --version && npm --version`.
- **Python 3.11+** — used by `scripts/doc-stats.py`. Check: `python --version`.
- **Hermes Agent** installed and working (desktop app). Check: `hermes hooks doctor` runs.
- Accounts / keys: a Cline account, an **opencode-go** API key, an **OpenCode Zen** credential,
  a **Devin** account.
- Optional: GitHub CLI for push discipline — check `gh auth status`.

## 2. Install the agent CLIs

### 2.1 Cline (medium worker)

```bash
npm install -g cline
cline --version          # expected: 3.0.68  (verified 2026-10-06)
```

Configure the provider (one-time; stores state in `%USERPROFILE%\.cline\data\settings\providers.json`,
which keeps the key local — never commit it):

```bash
cline auth -p opencode-go -k <OPENCODE_GO_API_KEY> -m longcat-2.5-preview-free
```

Model fact (verified against live catalogs 2026-10-06): on opencode-go the **only working free
model is `longcat-2.5-preview-free`** (`space-bunny-free` is unavailable upstream; no `-free-extra`
variants exist). Confirm the model actually used per run from
`%USERPROFILE%\.cline\data\sessions\<id>\<id>.json` (field `model`), not from the request.

Smoke test:

```bash
cline -P opencode-go -m longcat-2.5-preview-free "say CLINE_SMOKE_OK"    # expect: CLINE_SMOKE_OK
```

### 2.2 OpenCode (light worker)

```bash
npm install -g opencode-ai
opencode --version       # expected: 1.18.35  (verified 2026-10-07)
```

Auth (OpenCode Zen credential → `%USERPROFILE%\.local\share\opencode\auth.json`):

```bash
opencode auth login
```

Global model config `%USERPROFILE%\.config\opencode\opencode.jsonc`:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "model": "opencode/muse-spark-1.3-contributor-free",
  "small_model": "opencode/deepseek-v4-flash"
}
```

Notes:

- Reads outside the project are auto-rejected by default (`external_directory` guard) — add allow
  globs under `permission.external_directory` in the opencode config (`opencode.jsonc`) when a task
  must read other repos, then relaunch.
- `--title <name>` labels a run; keep logs in `agent_logs\`.

Smoke test:

```bash
opencode run --model opencode/muse-spark-1.3-contributor-free --title smoke "say OPENCODE_SMOKE_OK"
```

### 2.3 Devin CLI (hard worker)

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

Non-interactive launch (flags verified on v3000.11.3):

```bash
devin --respect-workspace-trust false --permission-mode dangerous -p -- "<prompt>"
```

- `--respect-workspace-trust false` is **mandatory in fresh dirs**: print mode cannot show the
  trust prompt and fails in an untrusted directory.
- `--permission-mode dangerous` auto-approves all tools — required for reads/writes outside the
  agent's workspace.
- Default model: SWE-2 family (`DEVIN_MODEL` default `swe-2-max`); pin per task with `--model`.

## 3. Hermes side — skill + guard hook

### 3.1 Skill `lead-orchestrator`

Place the skill (and its companion agent skills `devin-cli`, `cline-cli`, `opencode`,
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
   bash scripts/agent-hooks/test-guard.sh   # expect: 16 pass, 0 fail   (verified 2026-10-06)
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
# expected: SMOKE: ALL GREEN — 43 passed, 0 failed
```

The smoke test boots a throwaway project in a temp dir and asserts every script contract
(bootstrap, worktree, launch dry-runs, doc-stats self-test).

For a one-command §9 convention re-check — CLI versions + the three launch dry-runs + the key
flags in the live CLIs — run `bash scripts/preflight.sh` (exit ≠ 0 = drift; run it after ANY
CLI upgrade and before a round).

## 5. First orchestrated project (quickstart)

```bash
bash scripts/bootstrap-project.sh E:/my-project
bash scripts/new-task-worktree.sh E:/my-project E:/my-project-worktrees T-101 short-slug
$EDITOR E:/my-project-worktrees/_prompts/T-101.md        # task card — templates/task-card.md
bash scripts/launch-agent.sh cline E:/my-project-worktrees/T-101 E:/my-project-worktrees/_prompts/T-101.md --dry-run
bash scripts/launch-agent.sh cline E:/my-project-worktrees/T-101 E:/my-project-worktrees/_prompts/T-101.md --title T-101
```

Then follow `docs/git-orchestration.md` for verify → merge → bookkeeping. Hermes owns git, always.

## 6. Launch conventions (verified commands)

| Agent | Command (run from the task worktree; prompt from file) |
|---|---|
| cline | `timeout 1500 cline -P opencode-go -m longcat-2.5-preview-free -t 1380 "$(cat <prompt>)"` |
| opencode | `timeout 1500 opencode run --model opencode/muse-spark-1.3-contributor-free --title <task> "$(cat <prompt>)"` |
| devin | `timeout 2400 devin --respect-workspace-trust false --permission-mode dangerous -p -- "$(cat <prompt>)"` |

`scripts/launch-agent.sh` wraps exactly these (timeout + log + `EXIT=` marker); `--dry-run` prints
the composed command. Operational rules learned live (details: `docs/agent-matrix.md`):

- **Long runs must survive the parent session**: spawn with `persist_on_release=true`
  (Hermes `terminal(background=true, notify=true, persist_on_release=true)`); otherwise lifecycle
  events (compression, new session) SIGTERM mid-run agents.
- **Watchdog**: an agent that hasn't written its artifact in ~15 min is a failure — kill by PID and
  go to fail #1 (same agent, exact evidence). Completion = log stability, not process exit.
- **Kill by PATH, never by name** (a name-based kill matches the user's Devin desktop app).
- **Free tiers throttle (429)** — stagger heavy runs; prompts for live APIs get a politeness rule
  (≥1.5 s between calls) and capped batch sizes.

## 7. Verification checklist (prove the install)

| # | Check | Command | Expected (verified 2026-10-06) |
|---|---|---|---|
| 1 | CLIs present | `cline --version && opencode --version && devin --version` | 3.0.68 · 1.18.35 · devin 3000.11.3 |
| 2 | Cline smoke | `cline -P opencode-go -m longcat-2.5-preview-free "say CLINE_SMOKE_OK"` | `CLINE_SMOKE_OK` |
| 3 | OpenCode smoke | `opencode run --model opencode/muse-spark-1.3-contributor-free --title smoke "say OPENCODE_SMOKE_OK"` | `OPENCODE_SMOKE_OK` |
| 4 | Devin health | `devin doctor` | 2 passed, 0 failures (v3000.11.3) |
| 5 | Hook registered | `hermes hooks doctor` | all checks green |
| 6 | Hook behavior | `bash scripts/agent-hooks/test-guard.sh` | 16 pass / 0 fail |
| 7 | Kit scripts | `bash scripts/smoke-test.sh` | 43 passed / 0 failed |
| 8 | Launch dry-runs | `bash scripts/launch-agent.sh <agent> <workdir> <prompt> --dry-run` | prints the verified command, no side effects |
| 9 | One-command §9 re-check | `bash scripts/preflight.sh` | `PREFLIGHT: 11 passed, 0 failed` (verified 2026-10-07) |

## 8. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Native tool errors "cannot change to" / "not found" on paths | Native programs (git, .exe) do not understand MSYS `/e/...` or `/tmp` paths | Pass `E:/...` / `C:/...` (or `cygpath -m`), and use `$TMPDIR` (already a Windows dir) for native tools |
| Agent killed mid-run (`exit_code -15`, empty output) | Session lifecycle cleanup reaped the background process | Relaunch with `persist_on_release=true`; after any kill, check what actually landed on disk before deciding to re-run |
| Cline "planning" without writing, ~15+ min | Over-deliberation stall | Kill by PID (never by name); fail #1 = same agent, narrower scope; fail #2 = escalate to Devin with a rescue brief |
| Run exits 0 but the artifact is missing/partial | Agent claim ≠ evidence | Always verify the artifact + re-run gates yourself; provider-death runs may still have complete work on disk |
| OpenCode refuses reads outside the project | `external_directory` guard | Add allow globs to the opencode config, relaunch |
| Ghost diffs / "Committer identity unknown" in worktrees | Missing repo-local identity / CRLF | Pin repo-local `user.name`, `user.email`, `core.autocrlf false` |
| Scope diff shows phantom noise once main moved | Two-dot diff | Use three-dot: `git diff main...HEAD` |
| Cline 429 / "Model is unavailable" | Free-tier throttle / catalog drift | Stagger runs, respect cooldowns; re-check the live catalog; `longcat-2.5-preview-free` is the stable free pick |
| `npm i -g <pkg>` fails with EPERM under `...\hermes\tools\node-*` | Bundled npm's default global prefix points into the Hermes tools dir | Install with an explicit prefix: `npm i -g <pkg> --prefix "$APPDATA/npm"` (same dir as the existing CLI shims), then re-check `<cli> --version` |
| Devin update fails: `devin.exe` "being used by another process" | A running devin CLI session holds the exe | Wait for devin sessions to exit, re-run `irm https://cli.devin.ai/install.ps1 \| iex`, verify `devin --version` |

## 9. Machine inventory (verified 2026-10-06; re-verified 2026-10-07)

| Item | Value |
|---|---|
| cline | 3.0.68 (npm global, `%APPDATA%\npm\cline`) |
| opencode | 1.18.35 (npm global, `opencode-ai`; upgrade with `--prefix "$APPDATA/npm"`) |
| devin | 3000.11.3 `9c803229faa4` (`%LOCALAPPDATA%\devin\cli\bin\devin.exe`) |
| node / npm | v26.7.0 / 11.19.0 (Node bundled with Hermes) |
| kit smoke test | 43 passed / 0 failed |
| guard hook | kit mirror **identical** to live; 19/19 synthetic tests; re-approved 2026-10-07 after the read-only-query refinement |
| `hermes hooks doctor` | healthy — exists · allowlisted · unchanged · runs clean |
| superpowers plugin | 6.4.2 (`hermes plugins`; skills namespaced `superpowers:*`; up to date) |
