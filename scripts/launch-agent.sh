#!/usr/bin/env bash
# launch-agent.sh — launch Devin CLI (the sole coding agent) on a task prompt.
#
# Usage:
#   bash scripts/launch-agent.sh devin <workdir> <prompt-file> [options]
#
#   The only accepted agent token is `devin`.  `cline`/`opencode` are rejected
#   with an error (D-015 — Devin CLI is the sole coding lane; Cline/OpenCode are
#   retained on disk but removed from the coding roster).
#
# Options:
#   --title NAME     run title (default: prompt-file basename without extension)
#   --log FILE       log path (default: <worktrees-root>/_logs/<title>-<timestamp>.log)
#   --model M        Devin model override (default: swe-2-max)
#   --timeout SECS   wall-clock timeout (default: 2400)
#   --dry-run        print the composed command without running it
#
# Log:  <worktrees-root>/_logs/<title>-<timestamp>.log  (outside the task worktree;
#       unique per attempt; survives worktree cleanup).  `--log FILE` overrides.
#       Fallback to <workdir>/agent_logs/ when no sibling _logs/ exists.
# Exit code = the agent's own exit code.  `EXIT=<code>` is appended to the log.
# devin runs non-interactive print mode:  `-p --prompt-file <FILE>`
# (path converted for the native binary via cygpath -m).
set -u

usage() {
  cat <<'EOF'
Usage: bash scripts/launch-agent.sh devin <workdir> <prompt-file> [options]

The only accepted agent token is `devin` (D-015 — Devin CLI is the sole coding
lane).  `cline`/`opencode` are rejected with an error.

Options:
  --title NAME     run title (default: prompt-file basename without extension)
  --log FILE       log path (default: <worktrees-root>/_logs/<title>-<timestamp>.log)
  --model M        Devin model override (default: swe-2-max)
  --timeout SECS   wall-clock timeout (default: 2400)
  --dry-run        print the composed command without running it
EOF
  exit 2
}

[ $# -ge 3 ] || usage
AGENT="$1"; WORKDIR="$2"; PFILE="$3"; shift 3

# --- agent validation --------------------------------------------------------
# D-015: Devin CLI is the sole coding agent.  cline/opencode are rejected.
case "$AGENT" in
  devin) ;;
  cline|opencode)
        echo "ERROR: '$AGENT' is no longer a coding lane (D-015 Devin-only)." >&2
    echo "       Devin CLI is the sole coding agent.  Cline/OpenCode remain" >&2
    echo "       installed on disk for non-coding CLI tasks but are removed" >&2
    echo "       from the coding roster, routing, retry, and fallback." >&2
    exit 2
    ;;
  *)
    echo "ERROR: unknown agent '$AGENT' (expected: devin)" >&2
    usage
    ;;
esac

TITLE=""; LOG=""; MODEL=""; TMO=""; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --title)   TITLE="${2:-}"; shift 2 ;;
    --log)     LOG="${2:-}"; shift 2 ;;
    --model)   MODEL="${2:-}"; shift 2 ;;
    --timeout) TMO="${2:-}"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    *) echo "ERROR: unknown option: $1"; usage ;;
  esac
done

[ -d "$WORKDIR" ] || { echo "ERROR: workdir not found: $WORKDIR"; exit 2; }
[ -f "$PFILE" ]   || { echo "ERROR: prompt file not found: $PFILE"; exit 2; }

# devin.exe is a native Windows binary — give --prompt-file a Windows-style path (cygpath -m)
DPFILE="$PFILE"
if command -v cygpath >/dev/null 2>&1; then
  DPFILE="$(cygpath -m "$PFILE" 2>/dev/null || printf '%s' "$PFILE")"
fi

[ -n "$TITLE" ] || { TITLE="$(basename "$PFILE")"; TITLE="${TITLE%.*}"; }
if [ -z "$LOG" ]; then
  WT_ROOT="$(dirname "$WORKDIR")"
  if [ -d "$WT_ROOT/_logs" ]; then
    LOG="$WT_ROOT/_logs/$TITLE-$(date +%Y%m%d-%H%M%S-%N).log"
  else
    LOG="$WORKDIR/agent_logs/$TITLE.log"
  fi
fi

# --- defaults ---------------------------------------------------------------
# Model policy (D-015): default swe-2-max for hard/core work; caller may down-grade
# via --model for light/medium tasks (adaptive, swe-2-high, swe-2-medium, etc.).
[ -n "$MODEL" ] || MODEL="swe-2-max"
[ -n "$TMO" ]   || TMO=2400
BIN=devin

# --- dry-run ----------------------------------------------------------------
if [ "$DRY" -eq 1 ]; then
  echo "DRY-RUN (devin)"
  echo "  cd $WORKDIR"
  echo "  timeout $TMO devin --respect-workspace-trust=false --permission-mode dangerous --model $MODEL -p --prompt-file $DPFILE > $LOG 2>&1"
  echo "  # then: echo \"EXIT=\$?\" >> $LOG"
  exit 0
fi

command -v "$BIN" >/dev/null 2>&1 || { echo "ERROR: '$BIN' not found on PATH"; exit 127; }

mkdir -p "$(dirname "$LOG")"
cd "$WORKDIR" || { echo "ERROR: cannot cd to $WORKDIR"; exit 2; }

# Delegated agents must never start a training run inside the workspace:
# trainer.py refuses to start when this is set (see the orchestration guard).
export SLBOT_TRAIN_LOCK=agent-sandbox

timeout "$TMO" devin --respect-workspace-trust=false --permission-mode dangerous --model "$MODEL" -p --prompt-file "$DPFILE" > "$LOG" 2>&1
RC=$?

echo "EXIT=$RC" | tee -a "$LOG"
exit "$RC"
