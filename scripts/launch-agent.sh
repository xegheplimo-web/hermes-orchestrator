#!/usr/bin/env bash
# launch-agent.sh — launch a coding-agent CLI on a task prompt (timeout + log + exit marker).
#
# Usage:
#   bash scripts/launch-agent.sh <cline|opencode|devin> <workdir> <prompt-file>
#        [--title T] [--log L] [--model M] [--timeout S] [--dry-run]
#
# Defaults:
#   models   : cline    -> opencode/deepseek-v4.1-flash-free (provider -P opencode)
#              opencode -> opencode/deepseek-v4.1-flash-free
#   timeout  : cline/opencode 1500s, devin 2400s (cline's internal -t = TMO-120; override via CLINE_T env)
#   log      : <workdir>/agent_logs/<title>.log  (title defaults to prompt file basename)
# Exit code = the agent's own exit code. `EXIT=<code>` is appended to the log and printed.
# devin runs non-interactive print mode: `-p --prompt-file <FILE>` (path converted for the native binary).
set -u

usage() {
  cat <<'EOF'
Usage: bash scripts/launch-agent.sh <cline|opencode|devin> <workdir> <prompt-file> [options]

Options:
  --title NAME     run title (default: prompt-file basename without extension)
  --log FILE       log path (default: <workdir>/agent_logs/<title>.log)
  --model M        model override (cline / opencode)
  --timeout SECS   wall-clock timeout (default: cline/opencode 1500, devin 2400)
  --dry-run        print the composed command without running it
EOF
  exit 2
}

[ $# -ge 3 ] || usage
AGENT="$1"; WORKDIR="$2"; PFILE="$3"; shift 3

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

case "$AGENT" in
  cline|opencode|devin) ;;
  *) echo "ERROR: unknown agent '$AGENT' (expected: cline|opencode|devin)"; usage ;;
esac
[ -d "$WORKDIR" ] || { echo "ERROR: workdir not found: $WORKDIR"; exit 2; }
[ -f "$PFILE" ] || { echo "ERROR: prompt file not found: $PFILE"; exit 2; }

# devin.exe is a native Windows binary — give --prompt-file a Windows-style path (cygpath -m)
DPFILE="$PFILE"
if command -v cygpath >/dev/null 2>&1; then
  DPFILE="$(cygpath -m "$PFILE" 2>/dev/null || printf '%s' "$PFILE")"
fi

[ -n "$TITLE" ] || { TITLE="$(basename "$PFILE")"; TITLE="${TITLE%.*}"; }
[ -n "$LOG" ] || LOG="$WORKDIR/agent_logs/$TITLE.log"
if [ -z "$TMO" ]; then
  case "$AGENT" in devin) TMO=2400 ;; *) TMO=1500 ;; esac
fi
CLINE_T="${CLINE_T:-$((TMO - 120))}"
[ "$CLINE_T" -gt 0 ] 2>/dev/null || CLINE_T=1200

case "$AGENT" in
  cline)
    [ -n "$MODEL" ] || MODEL="opencode/deepseek-v4.1-flash-free"
    BIN=cline
    PROC="cline -P opencode -m $MODEL -t $CLINE_T"
    ;;
  opencode)
    [ -n "$MODEL" ] || MODEL="opencode/deepseek-v4.1-flash-free"
    BIN=opencode
    PROC="opencode run --model $MODEL --title \"$TITLE\""
    ;;
  devin)
    BIN=devin
    # NOTE: --respect-workspace-trust is an OPTIONAL-VALUE flag in devin >=3000.
    # With a space ("--respect-workspace-trust false") the value is swallowed but
    # --permission-mode stops taking effect and every write is rejected in -p mode.
    # Use the = form.
    PROC="devin --respect-workspace-trust=false --permission-mode dangerous -p --prompt-file"
    ;;
esac

if [ "$DRY" -eq 1 ]; then
  echo "DRY-RUN ($AGENT)"
  echo "  cd $WORKDIR"
  if [ "$AGENT" = devin ]; then
    echo "  timeout $TMO $PROC $DPFILE > $LOG 2>&1"
  else
    echo "  timeout $TMO $PROC \"\$(cat $PFILE)\" > $LOG 2>&1"
  fi
  echo "  # then: echo \"EXIT=\$?\" >> $LOG"
  exit 0
fi

command -v "$BIN" >/dev/null 2>&1 || { echo "ERROR: '$BIN' not found on PATH"; exit 127; }

mkdir -p "$(dirname "$LOG")"
cd "$WORKDIR" || { echo "ERROR: cannot cd to $WORKDIR"; exit 2; }

PROMPT="$(cat "$PFILE")"

# Delegated agents must never start a training run inside the workspace:
# trainer.py refuses to start when this is set (see the orchestration guard).
export SLBOT_TRAIN_LOCK=agent-sandbox

case "$AGENT" in
  cline)    timeout "$TMO" cline -P opencode -m "$MODEL" -t "$CLINE_T" "$PROMPT" > "$LOG" 2>&1; RC=$? ;;
  opencode) timeout "$TMO" opencode run --model "$MODEL" --title "$TITLE" "$PROMPT" > "$LOG" 2>&1; RC=$? ;;
  devin)    timeout "$TMO" devin --respect-workspace-trust=false --permission-mode dangerous -p --prompt-file "$DPFILE" > "$LOG" 2>&1; RC=$? ;;
esac

echo "EXIT=$RC" | tee -a "$LOG"
exit "$RC"
