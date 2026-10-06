#!/usr/bin/env bash
# test-doc-stats.sh — self-test for doc-stats.py.
# Builds a throwaway project with FIXED git dates and asserts the contract:
# inventory, stale flag (doc lags HEAD), roadmap checklist counts, control-plane
# audit, --json/--out/--strict/exit-2 behavior, and the no-git fallback.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
PASS=0; FAIL=0
ok()  { echo "  PASS  $*"; PASS=$((PASS+1)); }
bad() { echo "  FAIL  $*"; FAIL=$((FAIL+1)); }

PYBIN=""
command -v python  >/dev/null 2>&1 && PYBIN=python
[ -z "$PYBIN" ] && command -v python3 >/dev/null 2>&1 && PYBIN=python3
if [ -z "$PYBIN" ] || ! "$PYBIN" -c 'import sys' >/dev/null 2>&1; then
  echo "  SKIP  doc-stats self-test (no usable python on PATH)"
  echo "DOC-STATS: SKIPPED"
  exit 0
fi

conv() { command -v cygpath >/dev/null 2>&1 && cygpath -m "$1" || printf '%s' "$1"; }
SCRIPT="$(conv "$HERE/doc-stats.py")"

SMOKE="$(mktemp -d)"
OUTDIR="$(conv "$SMOKE")"
P="$SMOKE/proj"; mkdir -p "$P/.orchestrator" "$P/docs" "$P/analysis"

cat > "$P/README.md" <<'EOF'
# demo
## Roadmap
- [x] done one
- [x] done two
- [ ] open three
EOF
printf '# Arch\nan architectural doc\n' > "$P/docs/arch.md"
printf '# state\nfresh\n' > "$P/.orchestrator/PROJECT_STATE.md"
printf '{"tasks": []}\n' > "$P/.orchestrator/TASKS.json"
printf '# r1\n- [ ] todo\n' > "$P/analysis/r1-interfaces.md"

# Commit 1 @ 2026-09-01 (everything); commit 2 @ 2026-10-01 (README + state only)
cd "$P"
git init -q
git config user.email smoke@test.local && git config user.name Smoke
git add -A
GIT_AUTHOR_DATE="2026-09-01T10:00:00+07:00" GIT_COMMITTER_DATE="2026-09-01T10:00:00+07:00" \
  git commit -qm c1
printf '\nmore\n' >> README.md
printf '\nmore\n' >> .orchestrator/PROJECT_STATE.md
git add -A
GIT_AUTHOR_DATE="2026-10-01T10:00:00+07:00" GIT_COMMITTER_DATE="2026-10-01T10:00:00+07:00" \
  git commit -qm c2
cd - >/dev/null

ROOT="$(conv "$P")"

OUT="$("$PYBIN" "$SCRIPT" "$ROOT" --stale-days 14 2>&1)"; RC=$?
[ "$RC" -eq 0 ] && ok "runs exit 0" || bad "runs exit 0 (rc=$RC)"
case "$OUT" in *"docs/arch.md"*) ok "inventory lists docs/arch.md" ;; *) bad "inventory lists docs/arch.md" ;; esac
case "$OUT" in *"stale"*) ok "stale flag present in output" ;; *) bad "stale flag present in output" ;; esac
case "$OUT" in *"Roadmaps / checklists"*) ok "roadmap section rendered" ;; *) bad "roadmap section rendered" ;; esac

J="$("$PYBIN" "$SCRIPT" "$ROOT" --stale-days 14 --json 2>/dev/null)"
if printf '%s' "$J" | "$PYBIN" -c '
import json, sys
d = json.load(sys.stdin)
assert d["schema"] == "doc-stats.v1", d.get("schema")
docs = {e["path"]: e for e in d["docs"]}
assert "docs/arch.md" in docs, list(docs)
assert "stale" in docs["docs/arch.md"]["flags"], docs["docs/arch.md"]
assert "untracked" not in docs["docs/arch.md"]["flags"]
assert "stale" not in docs["README.md"]["flags"], docs["README.md"]
rm = {r["path"]: r for r in d["roadmaps"]}
assert (rm["README.md"]["done"], rm["README.md"]["open"]) == (2, 1), rm["README.md"]
cp = d["control_plane"]
assert "TASKS.json" in cp["present"] and "VERIFICATION.md" in cp["missing"], cp
assert d["totals"]["docs"] >= 5 and d["totals"]["warnings"] >= 1, d["totals"]
' >/dev/null 2>&1; then ok "json contract asserts"; else bad "json contract asserts"; fi

"$PYBIN" "$SCRIPT" "$ROOT" --stale-days 14 --strict >/dev/null 2>&1
[ $? -eq 1 ] && ok "--strict exits 1 with warnings" || bad "--strict exits 1 with warnings"

"$PYBIN" "$SCRIPT" "$ROOT" --stale-days 14 --json --out "$OUTDIR/out.json" --quiet >/dev/null 2>&1
if "$PYBIN" -c 'import json,sys; json.load(open(sys.argv[1], encoding="utf-8"))' "$OUTDIR/out.json" >/dev/null 2>&1; then
  ok "--out writes valid JSON"
else
  bad "--out writes valid JSON"
fi

"$PYBIN" "$SCRIPT" "$SMOKE/missing-dir" >/dev/null 2>&1
[ $? -eq 2 ] && ok "missing root exits 2" || bad "missing root exits 2"

# Fresh fixture: single commit, nothing lags HEAD -> --strict must exit 0
P2="$SMOKE/fresh"; mkdir -p "$P2/docs"
printf '# a\n' > "$P2/README.md"; printf '# b\n' > "$P2/docs/x.md"
cd "$P2"
git init -q
git config user.email smoke@test.local && git config user.name Smoke
git add -A
GIT_AUTHOR_DATE="2026-10-01T10:00:00+07:00" GIT_COMMITTER_DATE="2026-10-01T10:00:00+07:00" \
  git commit -qm c1
cd - >/dev/null
"$PYBIN" "$SCRIPT" "$(conv "$P2")" --strict >/dev/null 2>&1
[ $? -eq 0 ] && ok "fresh project --strict exits 0" || bad "fresh project --strict exits 0"

# No-git fixture: mtime fallback, still exit 0
P3="$SMOKE/nogit"; mkdir -p "$P3"
printf '# c\n' > "$P3/README.md"
"$PYBIN" "$SCRIPT" "$(conv "$P3")" >/dev/null 2>&1
[ $? -eq 0 ] && ok "non-git project exit 0 (mtime fallback)" || bad "non-git project exit 0 (mtime fallback)"

echo
if [ "$FAIL" -eq 0 ]; then
  echo "DOC-STATS: ALL GREEN — $PASS passed, 0 failed"
  rm -rf "$SMOKE"
  exit 0
else
  echo "DOC-STATS: FAILED — $PASS passed, $FAIL failed"
  echo "  kept for debugging: $SMOKE"
  exit 1
fi
