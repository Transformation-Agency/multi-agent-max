#!/usr/bin/env bash
# no-skip.sh — tests can't be skipped/focused; suppressions can't grow silently.
# Scans test files for .skip/.only/xit/xdescribe/@skip/@pytest.mark.skip (except @quarantine-tagged files listed in DEBT.md),
# and fails on any test file with zero assertions. Counts eslint-disable/@ts-ignore/`as any` vs baseline.
set -euo pipefail
PLAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; REPO_ROOT="$(cd "$PLAN_DIR/.." && pwd)"; cd "$REPO_ROOT"
# ── STACK ADAPTER ── test file globs + assertion keywords + source dirs
TEST_GLOB='-name *.test.* -o -name *.spec.* -o -name test_*.py'
ASSERT_RE='expect\(|assert|should\.|toBe|toEqual|\.ok\('
SRC_DIRS=(); for d in src app lib; do [[ -d $d ]] && SRC_DIRS+=("$d"); done
tests=(); while IFS= read -r t; do [[ -n "$t" ]] && tests+=("$t"); done < <(find . -type d \( -name node_modules -o -name .git -o -name dist -o -name .next \) -prune -o -type f \( $TEST_GLOB \) -print 2>/dev/null)
(( ${#tests[@]} )) || { echo "no-skip: no test files found — not configured"; exit 3; }
fail=0
for f in "${tests[@]}"; do
  if grep -nE '\.(skip|only)\(|^\s*(xit|xdescribe|xtest)\(|@pytest\.mark\.skip|@skip\b' "$f" >/dev/null; then
    if grep -q '@quarantine' "$f" && grep -q "${f#./}" "$PLAN_DIR/state/DEBT.md"; then :; else
      echo "no-skip: skipped/focused test in $f"; grep -nE '\.(skip|only)\(|^\s*(xit|xdescribe|xtest)\(|@pytest\.mark\.skip|@skip\b' "$f" | sed 's/^/   /'; fail=1; fi
  fi
  grep -qE "$ASSERT_RE" "$f" || { echo "no-skip: no assertions in $f"; fail=1; }
done
# suppression ratchet
BASE="$PLAN_DIR/state/suppressions-baseline.txt"
count() { (( ${#SRC_DIRS[@]} )) || { echo 0; return; }; { grep -rEo 'eslint-disable|@ts-ignore|@ts-expect-error|as any|# type: ignore|# noqa' "${SRC_DIRS[@]}" 2>/dev/null || true; } | wc -l | tr -d ' '; }
now=$(count); [[ -f "$BASE" ]] || echo "$now" > "$BASE"
base=$(cat "$BASE")
if (( now > base )); then
  if git log -1 --pretty=%B 2>/dev/null | grep -qE 'ADR-[0-9]+'; then echo "$now" > "$BASE"; echo "no-skip: suppressions $base→$now (ADR cited; baseline updated)";
  else echo "no-skip: suppressions grew $base→$now without ADR reference in commit"; fail=1; fi
elif (( now < base )); then echo "$now" > "$BASE"; fi
(( fail )) && exit 1; echo "no-skip: ok (${#tests[@]} test files, $now suppressions)"; exit 0
