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

echo "== 4. launch-agent.sh dry-run (devin only, D-015) =="
echo "# smoke prompt" > "$WT/_prompts/T-101.md"

# D-015: only devin is a coding lane
OUT="$(bash "$HERE/launch-agent.sh" devin "$WT/T-101" "$WT/_prompts/T-101.md" --title T-101 --dry-run 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "dry-run devin exits 0" || bad "dry-run devin exits 0 (rc=$RC)"
chk_contains "dry-run devin shows canonical form" "devin --respect-workspace-trust=false --permission-mode dangerous --model swe-2-max -p --prompt-file" "$OUT"

chk "dry-run created no log" test ! -f "$WT/T-101/agent_logs/T-101.log"

# D-015: cline and opencode must be REJECTED (exit 2, no execution)
OUT="$(bash "$HERE/launch-agent.sh" cline "$WT/T-101" "$WT/_prompts/T-101.md" --title T-101 --dry-run 2>&1)"; RC=$?
if [ "$RC" -eq 2 ]; then ok "cline rejected (exit 2)"; else bad "cline rejected (exit 2) (rc=$RC)"; fi
chk_contains "cline rejection mentions D-015" "D-015" "$OUT"

OUT="$(bash "$HERE/launch-agent.sh" opencode "$WT/T-101" "$WT/_prompts/T-101.md" --title T-101 --dry-run 2>&1)"; RC=$?
if [ "$RC" -eq 2 ]; then ok "opencode rejected (exit 2)"; else bad "opencode rejected (exit 2) (rc=$RC)"; fi
chk_contains "opencode rejection mentions D-015" "D-015" "$OUT"

echo "== 5. doc-stats.py self-test =="
DST_OUT="$(bash "$HERE/test-doc-stats.sh" 2>&1)"
case "$DST_OUT" in
  *"ALL GREEN — "*)
    n="${DST_OUT##*ALL GREEN — }"; n="${n%% passed*}"
    case "$n" in ''|*[!0-9]*) n=0 ;; esac
    PASS=$((PASS+n)); echo "  PASS  doc-stats self-test ($n checks)"
    ;;
  *SKIPPED*)
    echo "  SKIP  doc-stats self-test (no python)"
    ;;
  *)
    FAIL=$((FAIL+1)); echo "  FAIL  doc-stats self-test"
    printf '%s\n' "$DST_OUT" | tail -15
    ;;
esac


echo "== 6. bootstrap idempotent (RUNS.jsonl) =="
P2="$SMOKE/proj2"; WT2="$SMOKE/wt2"
chk "bootstrap #1 exits 0" bash "$HERE/bootstrap-project.sh" "$P2" --name p2 --worktrees-dir "$WT2"
RUNS2="$P2/.orchestrator/RUNS.jsonl"
printf '%s
' '{"schema":"hermes.run.v1","run_id":"fake-1"}' >> "$RUNS2"
if [ "$(wc -l < "$RUNS2" | tr -d ' ')" -eq 1 ]; then ok "RUNS has 1 line before 2nd bootstrap"; else bad "RUNS has 1 line before 2nd bootstrap"; fi
chk "bootstrap #2 exits 0" bash "$HERE/bootstrap-project.sh" "$P2" --name p2 --worktrees-dir "$WT2"
if [ "$(wc -l < "$RUNS2" | tr -d ' ')" -eq 1 ]; then ok "RUNS still 1 line after 2nd bootstrap"; else bad "RUNS still 1 line after 2nd bootstrap"; fi
if grep -q 'fake-1' "$RUNS2"; then ok "RUNS fake line retained"; else bad "RUNS fake line retained"; fi
if grep -qxF '.orchestrator/RUNS.jsonl' "$P2/.gitignore"; then ok ".gitignore has RUNS entry"; else bad ".gitignore has RUNS entry"; fi
if ( cd "$P2" && git check-ignore .orchestrator/RUNS.jsonl >/dev/null 2>&1 ); then ok "RUNS ignored by git"; else bad "RUNS ignored by git"; fi

echo "== 7. record-run.py =="
RR="$SMOKE/rr"; mkdir -p "$RR/.orchestrator"
RRD="$RR/.orchestrator"
command -v cygpath >/dev/null 2>&1 && RRD="$(cygpath -m "$RRD")"
REC_SCRIPT="$HERE/record-run.py"
command -v cygpath >/dev/null 2>&1 && REC_SCRIPT="$(cygpath -m "$REC_SCRIPT")"

"$PYBIN" "$REC_SCRIPT" --orchestrator-dir "$RRD" --run-id r1 --task-id T --agent devin --model m --task-type small-fix --duration-s 10 --exit-code 0 --provider-failure false --verify-status PASS --retry-index 0 --verified-by hermes >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 0 ]; then ok "record-run valid exits 0"; else bad "record-run valid exits 0 (rc=$RC)"; fi
"$PYBIN" - "$RRD/RUNS.jsonl" <<'PYCHK'
import json,sys
lines=open(sys.argv[1],encoding='utf-8').read().splitlines()
assert len(lines)==1, len(lines)
o=json.loads(lines[0])
assert o["schema"]=="hermes.run.v1"
assert o["run_id"]=="r1"
PYCHK
if [ $? -eq 0 ]; then ok "valid record parseable + schema"; else bad "valid record parseable + schema"; fi

"$PYBIN" "$REC_SCRIPT" --orchestrator-dir "$RRD" --run-id r2 --agent devin --model m --task-type small-fix --duration-s 10 --exit-code 0 --provider-failure false --verify-status PASS --retry-index 0 --verified-by hermes >/dev/null 2>&1
RC=$?
if [ "$RC" -ne 0 ]; then ok "record-run missing field exits non-zero"; else bad "record-run missing field exits non-zero"; fi
if [ "$(wc -l < "$RRD/RUNS.jsonl" | tr -d ' ')" -eq 1 ]; then ok "missing field leaves file unchanged"; else bad "missing field leaves file unchanged"; fi

"$PYBIN" "$REC_SCRIPT" --orchestrator-dir "$RRD" --run-id r1 --task-id T --agent devin --model m --task-type small-fix --duration-s 10 --exit-code 0 --provider-failure false --verify-status PASS --retry-index 0 --verified-by hermes >/dev/null 2>&1
RC=$?
if [ "$RC" -ne 0 ]; then ok "record-run duplicate exits non-zero"; else bad "record-run duplicate exits non-zero"; fi
if [ "$(wc -l < "$RRD/RUNS.jsonl" | tr -d ' ')" -eq 1 ]; then ok "duplicate leaves line count unchanged"; else bad "duplicate leaves line count unchanged"; fi

"$PYBIN" "$REC_SCRIPT" --orchestrator-dir "$RRD" --run-id r2 --task-id T --agent devin --model m --task-type small-fix --duration-s 10 --exit-code 0 --provider-failure false --verify-status PASS --retry-index 1 --verified-by hermes >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 0 ]; then ok "record-run retry exits 0"; else bad "record-run retry exits 0 (rc=$RC)"; fi
if [ "$(wc -l < "$RRD/RUNS.jsonl" | tr -d ' ')" -eq 2 ]; then ok "retry yields 2 lines"; else bad "retry yields 2 lines"; fi
"$PYBIN" - "$RRD/RUNS.jsonl" <<'PYCHK'
import json,sys
ids=[json.loads(x)["run_id"] for x in open(sys.argv[1],encoding='utf-8').read().splitlines()]
assert len(set(ids))==2
PYCHK
if [ $? -eq 0 ]; then ok "retry yields 2 distinct run_ids"; else bad "retry yields 2 distinct run_ids"; fi

"$PYBIN" "$REC_SCRIPT" --orchestrator-dir "$RRD" --run-id r3 --task-id T --agent devin --model m --task-type small-fix --duration-s 10 --exit-code 7 --provider-failure false --verify-status FAIL --retry-index 0 --verified-by hermes >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 0 ]; then ok "record-run failed run exits 0"; else bad "record-run failed run exits 0 (rc=$RC)"; fi
"$PYBIN" - "$RRD/RUNS.jsonl" <<'PYCHK'
import json,sys
o=json.loads(open(sys.argv[1],encoding='utf-8').read().splitlines()[-1])
assert o["exit_code"]==7 and o["verify_status"]=="FAIL"
PYCHK
if [ $? -eq 0 ]; then ok "failed run record keeps exit_code"; else bad "failed run record keeps exit_code"; fi

"$PYBIN" "$REC_SCRIPT" --orchestrator-dir "$RRD" --run-id r4 --task-id T --agent nope --model m --task-type small-fix --duration-s 10 --exit-code 0 --provider-failure false --verify-status PASS --retry-index 0 --verified-by hermes >/dev/null 2>&1
RC=$?
if [ "$RC" -ne 0 ]; then ok "record-run bad agent exits non-zero"; else bad "record-run bad agent exits non-zero"; fi
if [ "$(wc -l < "$RRD/RUNS.jsonl" | tr -d ' ')" -eq 3 ]; then ok "bad agent leaves line count unchanged"; else bad "bad agent leaves line count unchanged"; fi

# hardening: negative numbers rejected
"$PYBIN" "$REC_SCRIPT" --orchestrator-dir "$RRD" --run-id r5 --task-id T --agent devin --model m --task-type small-fix --duration-s -5 --exit-code 0 --provider-failure false --verify-status PASS --retry-index 0 --verified-by hermes >/dev/null 2>&1
RC=$?
if [ "$RC" -ne 0 ]; then ok "negative duration rejected"; else bad "negative duration rejected"; fi
"$PYBIN" "$REC_SCRIPT" --orchestrator-dir "$RRD" --run-id r6 --task-id T --agent devin --model m --task-type small-fix --duration-s 1 --exit-code 0 --provider-failure false --verify-status PASS --retry-index -2 --verified-by hermes >/dev/null 2>&1
RC=$?
if [ "$RC" -ne 0 ]; then ok "negative retry_index rejected"; else bad "negative retry_index rejected"; fi
if [ "$(wc -l < "$RRD/RUNS.jsonl" | tr -d ' ')" -eq 3 ]; then ok "negative values leave file unchanged"; else bad "negative values leave file unchanged"; fi

# hardening: corrupt existing JSONL line must block appends (no silent skip)
RRD2="$RR/" ; mkdir -p "$RR/x"; RR2="$RR/x/.orchestrator"; mkdir -p "$RR2"
printf '%s\n' 'not-json-at-all{{{' > "$RR2/RUNS.jsonl"
RRD2="$(command -v cygpath >/dev/null 2>&1 && cygpath -m "$RR2" || printf '%s' "$RR2")"
"$PYBIN" "$REC_SCRIPT" --orchestrator-dir "$RRD2" --run-id r7 --task-id T --agent devin --model m --task-type small-fix --duration-s 1 --exit-code 0 --provider-failure false --verify-status PASS --retry-index 0 --verified-by hermes >/dev/null 2>&1
RC=$?
if [ "$RC" -ne 0 ]; then ok "corrupt JSONL line blocks append"; else bad "corrupt JSONL line blocks append"; fi
if [ "$(wc -l < "$RR2/RUNS.jsonl" | tr -d ' ')" -eq 1 ]; then ok "corrupt file left untouched"; else bad "corrupt file left untouched"; fi

echo "== 8. log retention =="
WT3="$SMOKE/wt3"; mkdir -p "$WT3/T-101" "$WT3/_logs"
PROMPT3="$SMOKE/prompt3.md"; printf '# p
' > "$PROMPT3"
OUT1="$(bash "$HERE/launch-agent.sh" devin "$WT3/T-101" "$PROMPT3" --title T-101 --dry-run 2>&1)"
OUT2="$(bash "$HERE/launch-agent.sh" devin "$WT3/T-101" "$PROMPT3" --title T-101 --dry-run 2>&1)"
case "$OUT1" in *"$WT3/_logs/"*) ok "dry-run log path in _logs" ;; *) bad "dry-run log path in _logs" ;; esac
case "$OUT1" in *"$WT3/T-101/agent_logs"*) bad "dry-run log must not be in worktree agent_logs" ;; *) ok "dry-run log not in worktree" ;; esac
if [ "$OUT1" != "$OUT2" ]; then ok "two dry-runs produce distinct output"; else bad "two dry-runs produce distinct output"; fi

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
