#!/usr/bin/env bash
# Usage: STAGE=1 TICKET=T-012 plan/scripts/verify.sh --profile ticket -- pnpm run test:unit -- path/to/test
#        STAGE=2 TICKET=M-001 plan/scripts/verify.sh --profile milestone
#        STAGE=4 TICKET=release plan/scripts/verify.sh --profile release --fresh
# Ticket checks are scoped evidence, never integration certification. See STAGES.md.
set -euo pipefail
PLAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$PLAN_DIR/.." && pwd)"; cd "$REPO_ROOT"
STAGE="${STAGE:-$(awk '/^stage:/{print $2;exit}' "$PLAN_DIR/state/WHITEBOARD.md")}"
STAGE="${STAGE:-0}"; TICKET="${TICKET:-adhoc}"; PROFILE=""; FRESH=0
while (( $# )); do
  case "$1" in
    --profile) [[ $# -ge 2 ]] || { echo 'missing profile'; exit 2; }; PROFILE=$2; shift 2;;
    --fresh) FRESH=1; shift;;
    --) shift; break;;
    *) echo "unknown argument: $1"; exit 2;;
  esac
done
[[ "$STAGE" =~ ^[0-4]$ ]] || { echo 'STAGE must be 0..4'; exit 2; }
[[ "$TICKET" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]] || { echo 'invalid TICKET'; exit 2; }
if [[ -z "$PROFILE" ]]; then
  if (( STAGE == 4 )); then PROFILE=release
  elif (( STAGE >= 2 )); then PROFILE=milestone
  else PROFILE=ticket; fi
fi
case "$PROFILE" in ticket|milestone|release) ;; *) echo 'profile must be ticket, milestone, or release'; exit 2;; esac
if [[ "$PROFILE" == ticket ]]; then
  (( $# )) || { echo 'ticket profile requires a focused check command after --'; exit 2; }
  (( FRESH == 0 )) || { echo 'use milestone --fresh for environment diagnosis'; exit 2; }
else
  (( $# == 0 )) || { echo 'focused command is only valid with ticket profile'; exit 2; }
  (( STAGE >= 1 )) || { echo 'Stage 0 uses the ticket profile'; exit 2; }
fi
if (( STAGE == 4 )) || [[ "$PROFILE" == release ]]; then
  [[ "$PROFILE" == release && "$STAGE" == 4 && "$FRESH" == 1 ]] || {
    echo 'release requires STAGE=4 --profile release --fresh'; exit 2;
  }
fi
command -v node >/dev/null || { echo 'node is required for evidence reports'; exit 2; }
COMMIT=$(git rev-parse HEAD 2>/dev/null || echo nogit)
# Capture input state BEFORE creating evidence. Staged and untracked changes count.
DIRTY=$(git status --porcelain --untracked-files=all 2>/dev/null || echo nogit)
if (( FRESH )) && { [[ "$COMMIT" == nogit ]] || [[ -n "$DIRTY" ]]; }; then
  echo '--fresh requires a committed, clean checkout (including staged/untracked files)'; exit 1
fi
EV_BASE="$PLAN_DIR/state/evidence/$TICKET"; mkdir -p "$EV_BASE"
N=1
while ! mkdir "$EV_BASE/attempt-$N" 2>/dev/null; do
  [[ -d "$EV_BASE/attempt-$N" ]] || { echo "cannot create evidence in $EV_BASE"; exit 1; }
  N=$((N+1))
done
OUT="$EV_BASE/attempt-$N"; LOG="$OUT/verify.log"; ROWS="$OUT/checks.tsv"
: > "$LOG"; : > "$ROWS"; FAIL=0; START=$SECONDS; LAST_RC=0
log() { printf '%s\n' "$*" | tee -a "$LOG"; }
record() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "${4:-0}" >> "$ROWS"; }
finish() {
  node "$PLAN_DIR/scripts/checks/verify-report.js" "$OUT" "$STAGE" "$TICKET" "$PROFILE" "$COMMIT" "$FRESH" "$FAIL" "$((SECONDS-START))" "$DIRTY" "$@"
  if (( FAIL )); then log "✗ FAIL ($PROFILE) — $OUT/verify.json"; exit 1; fi
  if [[ "$PROFILE" == ticket ]]; then log "✓ LOCAL CHECKS PASS — broader verification deferred ($OUT/verify.json)"
  else log "✓ PASS ($PROFILE) — $OUT/verify.json"; fi
  exit 0
}
# Run independent checks even after failures. Missing REQUIRED checks fail closed.
run() {
  local name=$1 required=$2 t0=$SECONDS rc=0; shift 2
  log "── $name"; "$@" >> "$LOG" 2>&1 || rc=$?; LAST_RC=$rc
  if (( rc == 0 )); then record "$name" pass '' "$((SECONDS-t0))"
  elif (( rc == 3 )) && [[ "$required" == optional ]]; then record "$name" not-applicable 'not configured' "$((SECONDS-t0))"
  else
    FAIL=1
    if (( rc == 3 )); then record "$name" fail 'required check not configured' "$((SECONDS-t0))"
    else record "$name" fail "exit $rc" "$((SECONDS-t0))"; fi
    log "   FAILED: $name (exit $rc)"
  fi
}
blocked() { record "$1" blocked "$2"; FAIL=1; }
# STACK ADAPTER: replace pkg/fresh_install and profile checks for another stack.
pkg() {
  local s=$1; shift
  [[ -f package.json ]] || return 3
  node -e 'const p=require("./package.json");process.exit(p.scripts?.[process.argv[1]] ? 0 : 3)' "$s" || return $?
  pnpm run "$s" "$@"
}
fresh_install() {
  [[ -f package.json ]] || return 3
  rm -rf node_modules .next dist build coverage
  pnpm install --frozen-lockfile
}
CHK="$PLAN_DIR/scripts/checks"
log "verify.sh stage=$STAGE profile=$PROFILE ticket=$TICKET commit=$COMMIT → $OUT"
if (( FRESH )); then
  run clean-fresh-install required fresh_install
  if (( LAST_RC != 0 )); then blocked remaining-checks 'fresh install failed'; finish; fi
fi
if [[ "$PROFILE" == ticket ]]; then
  # Cheap record checks only; no global test scans, installs, builds, or ratchets.
  if [[ -f "$PLAN_DIR/state/config-baseline.sha256" ]]; then run config-integrity required "$CHK/config-hash.sh"
  else record config-integrity deferred 'baseline due at first integration milestone'; fi
  run audit-append-only optional "$CHK/audit-append-only.sh"
  run debt-ledger required "$CHK/debt.sh"
  run focused-check required "$@"
  for check in typecheck lint unit-tests build test-count-ratchet golden-demo-smoke no-skipped-tests integration-tests smoke-e2e module-boundaries ac-coverage full-e2e security-audit env-schema perf-budget red-team-regressions; do
    record "$check" deferred 'broader check owned by integration milestone; see ticket'
  done
  record clean-fresh-install deferred 'release or environment diagnosis'
  record debt-closed deferred 'release'
  finish "$@"
fi
run config-integrity required "$CHK/config-hash.sh"
run audit-append-only required "$CHK/audit-append-only.sh"
run no-skipped-tests required "$CHK/no-skip.sh"
run debt-ledger required "$CHK/debt.sh"
# .reports is runner-owned scratch output. Never credit reports from an older run.
mkdir -p .reports
rm -f .reports/*.json .reports/*.xml
run typecheck required pkg typecheck
if (( STAGE >= 3 )); then run lint-full required pkg lint
else run lint-bugs-only required pkg lint:bugs; fi
run unit-tests required pkg test:unit; UNIT_RC=$LAST_RC
run build required pkg build; BUILD_RC=$LAST_RC
if (( BUILD_RC == 0 )); then run golden-demo-smoke required pkg test:smoke
else blocked golden-demo-smoke 'build failed'; fi
if (( STAGE >= 2 )); then
  # Integration tests are independent of the application build by default.
  run integration-tests required pkg test:integration
  if (( BUILD_RC == 0 )); then run smoke-e2e required pkg test:e2e:smoke
  else blocked smoke-e2e 'build failed'; fi
  run module-boundaries required "$CHK/boundaries.sh"
fi
if (( STAGE >= 3 )); then
  if (( BUILD_RC == 0 )); then run full-e2e required pkg test:e2e
  else blocked full-e2e 'build failed'; fi
  run security-audit required pkg audit
  run env-schema required pkg check:env
  if [[ -f "$PLAN_DIR/perf-budgets.json" ]]; then
    if (( BUILD_RC == 0 )); then run perf-budget required "$CHK/perf.sh"
    else blocked perf-budget 'build failed'; fi
  else record perf-budget not-applicable 'no configured budget; reviewer must check SPEC'; fi
  if compgen -G "$PLAN_DIR/tickets/RT-*.md" >/dev/null; then run red-team-regressions required pkg test:rt
  else record red-team-regressions not-applicable 'no red-team finding tickets'; fi
fi
# Consume current-run reports only, after all report-producing suites.
if (( UNIT_RC == 0 )); then run test-count-ratchet required "$CHK/test-ratchet.sh"
else blocked test-count-ratchet 'unit tests failed'; fi
if (( STAGE >= 3 )); then run ac-coverage-strict required "$PLAN_DIR/scripts/ac-coverage.sh" --strict
elif (( STAGE >= 2 )); then run ac-coverage-report required "$PLAN_DIR/scripts/ac-coverage.sh"; fi
if [[ "$PROFILE" == release ]]; then run debt-closed required "$CHK/debt.sh" --must-be-empty; fi
finish
