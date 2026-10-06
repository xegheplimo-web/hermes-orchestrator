#!/usr/bin/env bash
# block-dangerous.sh — Hermes pre_tool_call guard (matcher: "terminal").
# Narrow, incident-backed denylist. FAIL-OPEN by design: any internal error,
# malformed payload, or unrecognized command => no output (allow).
# Blocks only via JSON action; exit code stays 0 (never exit 2).
#
# Covered incidents (see skills: lead-orchestrator §5b, hermes-self-upgrade):
#   1. force-push (never needed; use --force-with-lease if ever truly required)
#   2. name-based kills of user-facing apps (Devin desktop / Hermes / cline-app)
#   3. rm -rf on protected roots (main repos / hermes home) — subpaths still allowed
set -u

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0

cmd=""
if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
else
  cmd=$(printf '%s' "$payload" | python -c 'import json,sys
try:
    d = json.load(sys.stdin)
    ti = d.get("tool_input") or {}
    print(ti.get("command") or "")
except Exception:
    pass' 2>/dev/null || true)
fi
[ -n "$cmd" ] || exit 0

_log() { printf '%s\t%s\t%s\n' "$(date -u +%FT%TZ 2>/dev/null || echo '-')" "$1" "$(printf '%s' "$2" | head -c 200 | tr '\n\r' '  ')" >> "C:/Users/atton/AppData/Local/hermes/logs/guard.log" 2>/dev/null || true; }
deny() { _log BLOCK "$cmd :: $1"; printf '{"action":"block","message":"%s"}\n' "$1"; exit 0; }

# 1) Force-push (segment-scoped so `git push && rm -f x` is not a false hit)
seg=$(printf '%s' "$cmd" | grep -oE 'git[[:space:]]+push[^;&|]*' | head -1 || true)
if [ -n "$seg" ]; then
  case "$seg" in
    *--force-with-lease*) : ;;
    *)
      if printf '%s' "$seg" | grep -Eq -- '(--force([[:space:]]|$)|[[:space:]]-f([[:space:]]|$))'; then
        deny "blocked by guard: force-push is forbidden on this machine (use --force-with-lease, or ask Sep)"
      fi ;;
  esac
fi

# 2) Name-based kills of user-facing apps (live incidents: cline-app.exe, Get-Process Devin)
if printf '%s' "$cmd" | grep -Eq '(Stop-Process[^|;&]*-Name[^|;&]*(Devin|Hermes|cline-app)|taskkill[^|;&]*/IM[^|;&]*(Devin|Hermes|cline-app)|Get-Process[[:space:]]+.?Devin[^|;&]*\|)'; then
  deny "blocked by guard: name-based kill of a user-facing app (Devin/Hermes/cline-app). Kill the CLI by its exact install path instead"
fi

# 3) rm -rf on protected roots (boundary match: `aoe-native-agent-worktrees` is NOT matched)
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:];&|])rm[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*-[a-zA-Z]*r[a-zA-Z]*f|(^|[[:space:];&|])rm[[:space:]]+-[a-zA-Z]*f[a-zA-Z]*r'; then
  for root in aoe-native-agent Aoe-Agent hermes-orchestrator; do
    if printf '%s' "$cmd" | grep -Eq "${root}/?[\"']?[[:space:]]*(\\\\\$|$|&&|;|\|)"; then
      deny "blocked by guard: rm -rf on protected root '${root}'. Delete specific subpaths (worktrees/build dirs) instead"
    fi
  done
  if printf '%s' "$cmd" | grep -Eq 'AppData[\\/]Local[\\/]hermes/?[\"'"'"']?[[:space:]]*(\\\\\$|$|&&|;|\|)'; then
    deny "blocked by guard: rm -rf on the Hermes home root. Delete specific subpaths instead"
  fi
fi

_log ALLOW "$cmd"
exit 0
