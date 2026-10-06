#!/usr/bin/env bash
# Synthetic tests for block-dangerous.sh — asserts BLOCK/ALLOW per case.
# Run: bash test-guard.sh   (exit 0 = all green)
GUARD="$(cd "$(dirname "$0")" && pwd)/block-dangerous.sh"
pass=0; fail=0

check() { # check <expect: block|allow> <desc> <command-string>
  local expect="$1" desc="$2" cmd="$3" out got
  out=$(python -c 'import json,sys; print(json.dumps({"hook_event_name":"pre_tool_call","tool_name":"terminal","tool_input":{"command":sys.argv[1]}}))' "$cmd" | bash "$GUARD")
  got="allow"
  case "$out" in *'"block"'*) got="block" ;; esac
  if [ "$got" = "$expect" ]; then
    pass=$((pass+1)); echo "PASS [$expect] $desc"
  else
    fail=$((fail+1)); echo "FAIL (got=$got want=$expect) $desc  <<< out: $out"
  fi
}

# -- force-push family
check block "force-push --force"          "git push --force origin main"
check block "force-push -f"               "git push -f origin main"
check allow "normal push"                 "git push origin main"
check allow "force-with-lease"            "git push --force-with-lease origin main"
check allow "push && rm -f unrelated"     "git push origin main && rm -f tmp.txt"

# -- rm -rf protected roots
check block "rm -rf main repo root"       "rm -rf E:/aoe-native-agent"
check block "rm -rf hermes home root"     "rm -rf C:/Users/atton/AppData/Local/hermes"
check allow "rm -rf worktrees subpath"    "rm -rf E:/aoe-native-agent-worktrees/task-x"
check allow "rm -rf scratch subpath"      "rm -rf C:/Users/atton/AppData/Local/hermes/cache/scratch/tmp1"
check allow "rm -f single file"           "rm -f /tmp/x.txt"

# -- name-based kills of user apps
check block "Stop-Process -Name Devin"    "powershell -NoProfile -Command \"Stop-Process -Name Devin -Force\""
check block "taskkill cline-app"          "taskkill //IM cline-app.exe //F"
check allow "Stop-Process by PID"         "powershell -NoProfile -Command \"Stop-Process -Id 1234 -Force\""
check allow "kill by exact path"          "powershell -NoProfile -Command \"Stop-Process -Id 4321 -Force\""

# -- benign
check allow "benign echo"                 "echo hello"
check allow "git status"                  "git status --short"

echo "== $pass pass, $fail fail =="
[ "$fail" -eq 0 ]
