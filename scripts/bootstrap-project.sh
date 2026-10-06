#!/usr/bin/env bash
# bootstrap-project.sh — scaffold an orchestrated project (control plane + agent work areas).
#
# Usage:
#   bash scripts/bootstrap-project.sh <project-dir> [--name NAME] [--worktrees-dir DIR] [--no-git]
#
# Creates:
#   <project-dir>/.orchestrator/       control plane (rendered from templates/control-plane/)
#   <project-dir>/agent_logs/          agent run logs (gitignored)
#   <worktrees-dir>/{_prompts,_logs}   task worktrees + prompts + logs
#                                      (default: sibling dir "<basename>-worktrees")
#   <project-dir>/.gitignore           with agent-artifact entries (appended)
#   git init (branch main) unless --no-git or already a repository
#
# Non-destructive: existing files are never overwritten (skipped with a notice).
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
KIT="$(cd "$HERE/.." && pwd)"
TPL="$KIT/templates/control-plane"

usage() {
  cat <<'EOF'
Usage: bash scripts/bootstrap-project.sh <project-dir> [--name NAME] [--worktrees-dir DIR] [--no-git]

  <project-dir>          target project folder (created if missing)
  --name NAME            project name for the control plane (default: basename of project dir)
  --worktrees-dir DIR    where task worktrees live (default: <parent>/<basename>-worktrees)
  --no-git               do not run git init
EOF
  exit 2
}

PROJ=""; NAME=""; WT=""; NOGIT=0
while [ $# -gt 0 ]; do
  case "$1" in
    --name)          NAME="${2:-}"; shift 2 ;;
    --worktrees-dir) WT="${2:-}"; shift 2 ;;
    --no-git)        NOGIT=1; shift ;;
    -h|--help)       usage ;;
    *)               PROJ="$1"; shift ;;
  esac
done

[ -n "$PROJ" ] || usage
[ -d "$TPL" ] || { echo "ERROR: templates not found at $TPL (run from the kit repo)"; exit 2; }

BASE="$(basename "$PROJ")"
[ -n "$NAME" ] || NAME="$BASE"
[ -n "$WT" ] || WT="$(dirname "$PROJ")/${BASE}-worktrees"
DATE="$(date +%F)"

mkdir -p "$PROJ/.orchestrator" "$PROJ/agent_logs" "$WT/_prompts" "$WT/_logs"

WINP() { ( cd "$1" 2>/dev/null && { pwd -W 2>/dev/null || pwd; } ); }
WT_WIN="$(WINP "$WT")"

# --- render control plane (placeholders -> values; never overwrite) ---
rendered=0; skipped=0
for t in "$TPL"/*; do
  f="$(basename "$t")"
  out="$PROJ/.orchestrator/$f"
  if [ -e "$out" ]; then
    echo "  skip (exists): .orchestrator/$f"
    skipped=$((skipped+1))
    continue
  fi
  sed -e "s|{{PROJECT_NAME}}|$NAME|g" \
      -e "s|{{DATE}}|$DATE|g" \
      -e "s|{{WORKTREES_ROOT}}|$WT_WIN|g" \
      -e "s|{{PROMPTS_ROOT}}|$WT_WIN/_prompts|g" \
      "$t" > "$out"
  echo "  created: .orchestrator/$f"
  rendered=$((rendered+1))
done

# --- .gitignore entries ---
GI="$PROJ/.gitignore"
touch "$GI"
for entry in "agent_logs/" ".serena/" "_sandbox/" "*.log"; do
  if ! grep -qxF "$entry" "$GI" 2>/dev/null; then
    printf '%s\n' "$entry" >> "$GI"
  fi
done
echo "  updated: .gitignore (agent artifacts)"

# --- git init ---
if [ "$NOGIT" -eq 0 ]; then
  if ( cd "$PROJ" && git rev-parse --is-inside-work-tree >/dev/null 2>&1 ); then
    echo "  git: already a repository (left as-is)"
  else
    if ( cd "$PROJ" && { git init -q -b main 2>/dev/null || git init -q; } ); then
      echo "  git: initialized (branch main)"
    else
      echo "  WARN: git init failed"
    fi
  fi
else
  echo "  git: skipped (--no-git)"
fi

echo
echo "Bootstrapped: $NAME"
echo "  project  : $PROJ"
echo "  control  : $PROJ/.orchestrator ($rendered new, $skipped skipped)"
echo "  worktrees: $WT (prompts: $WT/_prompts, logs: $WT/_logs)"
echo
echo "Next steps:"
echo "  1. Fill .orchestrator/TASKS.json (split per PROMPT.md §5; one task = one worktree)."
echo "  2. Create a task worktree: bash scripts/new-task-worktree.sh \"$PROJ\" \"$WT\" T-101 short-slug"
echo "  3. Write the task card to: $WT/_prompts/T-101.md"
echo "  4. Dispatch: bash scripts/launch-agent.sh <cline|opencode|devin> \"$WT/T-101\" \"$WT/_prompts/T-101.md\" --title T-101"
