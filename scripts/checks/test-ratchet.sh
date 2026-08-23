#!/usr/bin/env bash
# test-ratchet.sh — total test count may not decrease without an ADR reference in the commit message.
set -euo pipefail
PLAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; REPO_ROOT="$(cd "$PLAN_DIR/.." && pwd)"; cd "$REPO_ROOT"
BASE="$PLAN_DIR/state/test-count-baseline.txt"
# ── STACK ADAPTER ── how to count tests (static count is fine; result-file count is better)
count() {
  if ls .reports/*.json >/dev/null 2>&1; then
    node -e 'let n=0;for(const f of process.argv.slice(1)){const r=JSON.parse(require("fs").readFileSync(f,"utf8"));n+=r.numTotalTests??r.stats?.expected??0;}console.log(n)' .reports/*.json
  else
    find . -type d \( -name node_modules -o -name .git \) -prune -o -type f \( -name '*.test.*' -o -name '*.spec.*' -o -name 'test_*.py' \) -print 2>/dev/null \
      | { xargs grep -hE '^\s*(it|test|def test_)\b' 2>/dev/null || true; } | wc -l | tr -d ' '
  fi
}
now=$(count); [[ "$now" =~ ^[0-9]+$ ]] || now=0
(( now == 0 )) && { echo "test-ratchet: no tests found — not configured"; exit 3; }
[[ -f "$BASE" ]] || echo 0 > "$BASE"; base=$(cat "$BASE")
if (( now < base )); then
  if git log -1 --pretty=%B 2>/dev/null | grep -qE 'ADR-[0-9]+'; then echo "$now" > "$BASE"; echo "test-ratchet: $base→$now (ADR cited)"; exit 0; fi
  echo "test-ratchet: test count dropped $base→$now without ADR reference"; exit 1
fi
echo "$now" > "$BASE"; echo "test-ratchet: ok ($now tests, baseline $base)"
