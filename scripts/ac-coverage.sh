#!/usr/bin/env bash
# ac-coverage.sh — every AC-xx.yy in SPEC.md must be referenced by ≥1 PASSING test.
#
# Usage: scripts/ac-coverage.sh [--strict] [--results <file>]
#   --strict   exit 1 if any AC uncovered (Stage 3+). Otherwise report only.
#   --results  test-results file to scan (default: auto-detect). Exit 3 if none found.
#
# How it works (stack-agnostic): collect AC ids from SPEC.md; collect AC ids that
# appear in the names of PASSING tests from a JSON/JUnit results file; diff.
# ── STACK ADAPTER ── make your test runner emit a results file, e.g.
#   vitest: `vitest run --reporter=json --outputFile=.reports/unit.json`
#   playwright: `reporter: [['json', { outputFile: '.reports/e2e.json' }]]`
#   pytest: `--junitxml=.reports/pytest.xml`
set -euo pipefail
PLAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$PLAN_DIR/.." && pwd)"; cd "$REPO_ROOT"
STRICT=0; RESULTS=()
while (( $# )); do case $1 in
  --strict) STRICT=1;; --results) shift; RESULTS+=("$1");; *) echo "unknown arg $1"; exit 2;; esac; shift; done

(( ${#RESULTS[@]} )) || RESULTS=( $(ls .reports/*.json .reports/*.xml 2>/dev/null || true) )
if (( ${#RESULTS[@]} == 0 )); then echo "ac-coverage: no test results in .reports/ — not configured"; exit 3; fi

spec_acs=$(grep -oE 'AC-[0-9]+\.[0-9]+' "$PLAN_DIR/SPEC.md" | sort -u)
[[ -n "$spec_acs" ]] || { echo "ac-coverage: no AC ids in SPEC.md"; exit 3; }

# Extract AC ids from passing tests. Handles vitest/jest/playwright JSON and JUnit XML heuristically.
extract() {
  local f; for f in "${RESULTS[@]}"; do
    case "$f" in
      (*.json) node "$PLAN_DIR/scripts/checks/ac-extract.js" "$f";;
      (*.xml)  # JUnit: testcase without <failure>/<skipped> child
        perl -0ne 'while(/<testcase\b([^>]*)\/>|<testcase\b([^>]*)>(.*?)<\/testcase>/sg){my $a=$1//$2;my $b=$3//"";next if $b=~/<(failure|error|skipped)/;while($a=~/AC-\d+\.\d+/g){print "$&\n"}}' "$f";;
    esac
  done
}
covered=$(extract | sort -u)

total=$(echo "$spec_acs" | wc -l | tr -d ' ')
missing=$(comm -23 <(echo "$spec_acs") <(echo "$covered"))
nmiss=$( [[ -n "$missing" ]] && echo "$missing" | wc -l | tr -d ' ' || echo 0 )
ncov=$((total-nmiss))
echo "ac-coverage: $ncov/$total ACs have a passing test"
if [[ -n "$missing" ]]; then echo "uncovered:"; echo "$missing" | sed 's/^/  /'; fi
if (( STRICT && nmiss > 0 )); then echo "FAIL (strict): $nmiss uncovered"; exit 1; fi
exit 0
