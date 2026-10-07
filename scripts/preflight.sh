#!/usr/bin/env bash
# preflight.sh — one-command §9 convention check for the orchestrator kit.
# Checks: agent CLIs on PATH + versions · launch-agent.sh dry-runs still match the
# §9 launch conventions · key flags still present in the live CLIs · Devin cloud lane
# (MCP endpoint reachable · server registered · API key present).
# Read-only (writes only to a temp dir). Exit 0 = all green.
# Any FAIL = drift → resync §9 (docs/installation.md + skill lead-orchestrator §9),
# then re-run this script. Run after ANY CLI upgrade and before a round.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
PASS=0; FAIL=0
ok()  { echo "  PASS  $*"; PASS=$((PASS+1)); }
bad() { echo "  FAIL  $*"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d 2>/dev/null)" || { TMP="${TMPDIR:-/tmp}/preflight.$$"; mkdir -p "$TMP"; }
trap 'rm -rf "$TMP"' EXIT
printf 'preflight — reply with exactly PREFLIGHT_OK\n' > "$TMP/pf.md"

echo "== 1. agent CLIs on PATH (versions informational) =="
for c in cline opencode devin; do
  if command -v "$c" >/dev/null 2>&1; then
    echo "  $c: $("$c" --version 2>/dev/null | head -1)"
  else
    bad "$c not found on PATH"
  fi
done

echo "== 2. launch-agent.sh dry-runs match §9 =="
want() { # want <agent> <needle> <out>
  case "$3" in *"$2"*) ;; *) bad "$1 dry-run missing: $2"; return 1 ;; esac
}
dr() { # dr <agent> <needle>...
  local agent="$1"; shift
  local out rc miss=0 n
  out="$(bash "$HERE/launch-agent.sh" "$agent" "$TMP" "$TMP/pf.md" --title PF-101 --dry-run 2>&1)"; rc=$?
  if [ "$rc" -ne 0 ]; then bad "$agent dry-run exited $rc"; return; fi
  for n in "$@"; do want "$agent" "$n" "$out" || miss=1; done
  [ "$miss" -eq 0 ] && ok "$agent dry-run matches §9"
}
dr cline    "-P opencode-go" "-m longcat-2.5-preview-free" "-t 1380" "timeout 1500"
dr opencode "opencode run --model opencode/muse-spark-1.3-contributor-free" "--title" "timeout 1500"
dr devin    "devin --respect-workspace-trust false --permission-mode dangerous -p --" "timeout 2400"

echo "== 3. key flags still exist in live CLIs =="
flag() { # flag <desc> <needle> <cmd...>
  local desc="$1" needle="$2"; shift 2
  if "$@" >"$TMP/help.out" 2>&1 && grep -qF -- "$needle" "$TMP/help.out"; then
    ok "$desc"
  else
    bad "$desc (no \"$needle\" in help output)"
  fi
}
flag "cline help: --provider" "--provider" cline --help
flag "cline help: --model" "--model" cline --help
flag "cline help: --timeout" "--timeout" cline --help
flag "opencode run help: --model" "--model" opencode run --help
flag "opencode run help: --title" "--title" opencode run --help
flag "opencode run help: --variant" "--variant" opencode run --help
flag "devin help: --permission-mode" "--permission-mode" devin --help
flag "devin help: --respect-workspace-trust" "--respect-workspace-trust" devin --help

echo "== 3b. Devin cloud lane (MCP/API) =="
code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 https://mcp.devin.ai/ 2>/dev/null)"
[ "$code" = "200" ] && ok "mcp.devin.ai reachable (200)" || bad "mcp.devin.ai returned '$code' (network?)"
if hermes mcp list 2>/dev/null | grep -q 'devin'; then
  ok "devin MCP server registered"
else
  bad "devin MCP server not registered (run: hermes mcp add devin --url https://mcp.devin.ai/mcp --auth header)"
fi
ENVF="${LOCALAPPDATA:-$HOME/AppData/Local}/hermes/.env"; ENVF="${ENVF//\\//}"
if grep -q '^MCP_DEVIN_API_KEY=' "$ENVF" 2>/dev/null; then
  ok "MCP_DEVIN_API_KEY present in hermes .env"
else
  bad "MCP_DEVIN_API_KEY missing in $ENVF (add via: hermes mcp add devin --url https://mcp.devin.ai/mcp --auth header)"
fi

echo "== 4. reminders =="
echo "  - after any CLI upgrade: sync version rows in docs/installation.md (§2 · §7 · §9)"
echo "  - live smokes: say <AGENT>_SMOKE_OK (Devin cloud quota-billed → hermes mcp test devin; CLI → devin doctor + dry-run)"
echo
echo "PREFLIGHT: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
