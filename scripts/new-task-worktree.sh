#!/usr/bin/env bash
# new-task-worktree.sh — create an isolated worktree + branch for one task.
#
# Usage: bash scripts/new-task-worktree.sh <project-dir> <worktrees-root> <task-id> <slug> [base-branch]
#   Creates: git worktree add <worktrees-root>/<task-id> -b task/<task-id>-<slug> <base-branch>
#   Default base branch: main. The base branch must already exist (repo has commits).
set -u

if [ $# -lt 4 ]; then
  cat <<'EOF'
Usage: bash scripts/new-task-worktree.sh <project-dir> <worktrees-root> <task-id> <slug> [base-branch]

  <project-dir>     the main checkout of the project
  <worktrees-root>  where worktrees live (e.g. E:/my-project-worktrees)
  <task-id>         e.g. T-101
  <slug>            short slug, e.g. speed-audit
  [base-branch]     default: main
EOF
  exit 2
fi

PROJ="$1"; WT="$2"; TID="$3"; SLUG="$4"; BASE="${5:-main}"
DEST="$WT/$TID"

[ -d "$PROJ" ] || { echo "ERROR: project dir not found: $PROJ"; exit 2; }
mkdir -p "$WT"
[ -e "$DEST" ] && { echo "ERROR: destination already exists: $DEST"; exit 2; }

WT_WIN="$( ( cd "$WT" && { pwd -W 2>/dev/null || pwd; } ) )"
DEST_WIN="$WT_WIN/$TID"

if ! ( cd "$PROJ" && git worktree add "$DEST_WIN" -b "task/$TID-$SLUG" "$BASE" ); then
  echo "ERROR: git worktree add failed (base branch '$BASE' must exist in $PROJ)"
  exit 1
fi

echo
echo "OK: worktree created"
echo "  path  : $DEST"
echo "  branch: task/$TID-$SLUG (base: $BASE)"
echo "  prompt: write $WT/_prompts/$TID.md, then launch:"
echo "          bash scripts/launch-agent.sh <cline|opencode|devin> \"$DEST\" \"$WT/_prompts/$TID.md\" --title $TID"
