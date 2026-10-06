#!/usr/bin/env bash
# smoke-test.sh — self-test for the hermes-orchestrator scripts.
# Boots a throwaway project in a temp dir and asserts every script contract. Exit 0 = all green.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
PASS=0; FAIL=0
ok()  { echo "  PASS  $*"; PASS=$((PASS+1)); }
bad() { echo "  FAIL  $*"; FAIL=$((FAIL+1)); }
chk() { # chk <desc> <cmd...>
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$desc"; else bad "$desc"; fi
}
chkc() { # chkc <desc> <shell-string>   (compound checks: cd/grep/negation)
  local desc="$1" s="$2"
  if bash -c "$s" >/dev/null 2>&1; then ok "$desc"; else bad "$desc"; fi
}
chk_contains() { # chk_contains <desc> <needle> <haystack>
  local desc="$1" needle="$2" hay="$3"
  case "$hay" in *"$needle"*) ok "$desc" ;; *) bad "$desc" ;; esac
}

echo "== 1. bash -n (syntax) =="
for s in "$HERE"/*.sh; do
  chk "syntax OK: $(basename "$s")" bash -n "$s"
done

echo "== 2. bootstrap-project.sh in a throwaway dir =="
SMOKE="$(mktemp -d)"
P="$SMOKE/proj"; WT="$SMOKE/wt"
chk "bootstrap exits 0" bash "$HERE/bootstrap-project.sh" "$P" --name smoke-proj --worktrees-dir "$WT"
for f in PROJECT_STATE.md TASKS.json AGENT_RULES.md VERIFICATION.md DECISIONS.md INTERFACES.md; do
  chk "control plane: $f" test -f "$P/.orchestrator/$f"
done
chkc "placeholders rendered (no {{ left)" "! grep -rq '{{' '$P/.orchestrator'"
chk "worktrees _prompts dir" test -d "$WT/_prompts"
chk "worktrees _logs dir" test -d "$WT/_logs"
chk "agent_logs dir" test -d "$P/agent_logs"
chkc ".gitignore has agent_logs/" "grep -qxF 'agent_logs/' '$P/.gitignore'"
chkc "git repo initialized" "cd '$P' && git rev-parse --is-inside-work-tree"
chkc "rendered name in PROJECT_STATE" "grep -q 'smoke-proj' '$P/.orchestrator/PROJECT_STATE.md'"

PYBIN=""
command -v python  >/dev/null 2>&1 && PYBIN=python
[ -z "$PYBIN" ] && command -v python3 >/dev/null 2>&1 && PYBIN=python3
if [ -n "$PYBIN" ]; then
  TASKS_JSON="$P/.orchestrator/TASKS.json"
  # native tools (python) cannot read MSYS-style /tmp paths — convert when cygpath is available
  command -v cygpath >/dev/null 2>&1 && TASKS_JSON="$(cygpath -m "$TASKS_JSON")"
  chk "TASKS.json is valid JSON" "$PYBIN" -c 'import json,sys; json.load(open(sys.argv[1], encoding="utf-8"))' "$TASKS_JSON"
else
  echo "  SKIP  TASKS.json JSON check (no python on PATH)"
fi

echo "== 3. new-task-worktree.sh =="
chk "seed commit for worktree test" bash -c "cd '$P' && git config user.email smoke@test.local && git config user.name Smoke && echo hi > seed.txt && git add -A && git commit -qm seed"
chk "worktree creation exits 0" bash "$HERE/new-task-worktree.sh" "$P" "$WT" T-101 smoke-task
chk "worktree dir exists" test -d "$WT/T-101"
chk "worktree has seed file" test -f "$WT/T-101/seed.txt"
chkc "branch task/T-101-smoke-task exists" "cd '$P' && git branch --list 'task/T-101-smoke-task' | grep -q 'T-101'"

echo "== 4. launch-agent.sh (dry-run for all three agents) =="
echo "# smoke prompt" > "$WT/_prompts/T-101.md"

OUT="$(bash "$HERE/launch-agent.sh" cline "$WT/T-101" "$WT/_prompts/T-101.md" --title T-101 --dry-run 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "dry-run cline exits 0" || bad "dry-run cline exits 0 (rc=$RC)"
chk_contains "dry-run cline shows verified command" "cline -P opencode-go -m longcat-2.5-preview-free" "$OUT"

OUT="$(bash "$HERE/launch-agent.sh" opencode "$WT/T-101" "$WT/_prompts/T-101.md" --title T-101 --dry-run 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "dry-run opencode exits 0" || bad "dry-run opencode exits 0 (rc=$RC)"
chk_contains "dry-run opencode shows verified command" "opencode run --model opencode/muse-spark-1.3-contributor-free" "$OUT"

OUT="$(bash "$HERE/launch-agent.sh" devin "$WT/T-101" "$WT/_prompts/T-101.md" --title T-101 --dry-run 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "dry-run devin exits 0" || bad "dry-run devin exits 0 (rc=$RC)"
chk_contains "dry-run devin shows dangerous mode" "devin --respect-workspace-trust false --permission-mode dangerous" "$OUT"

chk "dry-run created no log" test ! -f "$WT/T-101/agent_logs/T-101.log"

echo
if [ "$FAIL" -eq 0 ]; then
  echo "SMOKE: ALL GREEN — $PASS passed, 0 failed"
  rm -rf "$SMOKE"
  exit 0
else
  echo "SMOKE: FAILED — $PASS passed, $FAIL failed"
  echo "  kept for debugging: $SMOKE"
  exit 1
fi
