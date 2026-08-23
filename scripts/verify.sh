#!/usr/bin/env bash
# verify.sh — THE gate. The only certificate of "done".
#
# Usage:  STAGE=<0-4> TICKET=<T-xxx> scripts/verify.sh [--fresh]
#   STAGE   defaults to the `stage:` line in state/WHITEBOARD.md
#   TICKET  defaults to "adhoc"
#   --fresh clean install + cleared build caches (verifier and Stage 4 MUST use this).
#           Requires a clean working tree — run it on a committed branch, not mid-edit.
#   Stack commands exit 3 when not configured → recorded as "skipped", so the gate runs on day 0.
#   Requires bash ≥3.2 (macOS default OK), git, node (for JSON report parsing).
#
# Writes: state/evidence/<TICKET>/attempt-N/verify.{log,json}
# Exit 0 only if every enabled check passed. Cheapest checks first, fail-fast.
set -euo pipefail

PLAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$PLAN_DIR/.." && pwd)"
cd "$REPO_ROOT"

STAGE="${STAGE:-$(grep -m1 -E '^stage:' "$PLAN_DIR/state/WHITEBOARD.md" 2>/dev/null | awk '{print $2}')}"
STAGE="${STAGE:-0}"
TICKET="${TICKET:-adhoc}"
FRESH=0; [[ "${1:-}" == "--fresh" ]] && FRESH=1

# ---- evidence dir: attempt-N, never overwrite prior attempts -----------------
EV_BASE="$PLAN_DIR/state/evidence/$TICKET"
mkdir -p "$EV_BASE"
N=1; while [[ -d "$EV_BASE/attempt-$N" ]]; do N=$((N+1)); done
OUT="$EV_BASE/attempt-$N"; mkdir -p "$OUT"
LOG="$OUT/verify.log"; : > "$LOG"
COMMIT="$(git rev-parse HEAD 2>/dev/null || echo nogit)"
RESULTS=()
START=$SECONDS

log() { printf '%s\n' "$*" | tee -a "$LOG"; }

write_report() {  # $1 = true|false
  local joined; joined=$(IFS=,; echo "${RESULTS[*]}")
  printf '{"stage":%s,"ticket":"%s","commit":"%s","fresh":%s,"passed":%s,"secs":%s,"checks":[%s]}\n' \
    "$STAGE" "$TICKET" "$COMMIT" "$FRESH" "$1" "$((SECONDS-START))" "$joined" > "$OUT/verify.json"
}

# run <name> <min_stage> <cmd...>
#   Runs cmd if STAGE >= min_stage. A cmd exiting 3 means "not configured" → recorded
#   as skipped (lets the template run before the stack adapter is wired).
run() {
  local name=$1 min=$2; shift 2
  if (( STAGE < min )); then
    RESULTS+=("{\"name\":\"$name\",\"status\":\"skipped\",\"reason\":\"stage<$min\"}"); return 0
  fi
  local t0=$SECONDS rc=0
  log "── $name"
  "$@" >>"$LOG" 2>&1 || rc=$?
  if (( rc == 0 )); then
    RESULTS+=("{\"name\":\"$name\",\"status\":\"pass\",\"secs\":$((SECONDS-t0))}")
  elif (( rc == 3 )); then
    RESULTS+=("{\"name\":\"$name\",\"status\":\"skipped\",\"reason\":\"not configured\"}")
    log "   skipped: not configured"
  else
    RESULTS+=("{\"name\":\"$name\",\"status\":\"fail\",\"secs\":$((SECONDS-t0))}")
    write_report false
    log "✗ FAIL: $name (stage=$STAGE) — see $LOG"
    exit 1
  fi
}

# Stack-adapter helper: run a package script only if it exists; else exit 3 (not configured).
# ── STACK ADAPTER ── edit `has_script`/`pkg` for non-Node stacks.
pkg() {  # pkg <script-name> [extra args...]
  local s=$1; shift
  [[ -f package.json ]] || return 3
  node -e "process.exit(require('./package.json').scripts?.['$s'] ? 0 : 3)" 2>/dev/null || return 3
  pnpm run "$s" "$@"
}
fresh_install() {
  [[ -f package.json ]] || return 3
  git diff --quiet || { echo "working tree dirty — commit or stash before --fresh"; return 1; }
  rm -rf node_modules .next dist build coverage
  pnpm install --frozen-lockfile
}
CHK="$PLAN_DIR/scripts/checks"

log "verify.sh  stage=$STAGE ticket=$TICKET fresh=$FRESH commit=$COMMIT  → $OUT"

# ---- always-on: hygiene + anti-gaming (cheap) ---------------------------------
(( FRESH )) && run clean-fresh-install   0 fresh_install
run config-integrity                     0 "$CHK/config-hash.sh"
run audit-append-only                    0 "$CHK/audit-append-only.sh"
run no-skipped-tests                     0 "$CHK/no-skip.sh"

# ---- core build checks ---------------------------------------------------------
# ── STACK ADAPTER ── map to your commands (see ARCHITECTURE.md §1)
run typecheck                            0 pkg typecheck            # e.g. "typecheck": "tsc --noEmit"
if (( STAGE >= 3 )); then
  run lint-full                          3 pkg lint                 # full ruleset incl. style
else
  run lint-bugs-only                     0 pkg lint:bugs            # e.g. eslint with style rules off
fi
run unit-tests                           0 pkg test:unit
run build                                0 pkg build
run test-count-ratchet                   0 "$CHK/test-ratchet.sh"
run golden-demo-smoke                    0 pkg test:smoke           # ONE flow, ~30s, written in Stage 0

# ---- stage 1+ --------------------------------------------------------------------
run debt-ledger                          1 "$CHK/debt.sh"

# ---- stage 2+ --------------------------------------------------------------------
run integration-tests                    2 pkg test:integration
run smoke-e2e                            2 pkg test:e2e:smoke      # 3–6 golden flows
run module-boundaries                    2 "$CHK/boundaries.sh"
if (( STAGE >= 3 )); then
  run ac-coverage-strict                 3 "$PLAN_DIR/scripts/ac-coverage.sh" --strict
else
  run ac-coverage-report                 2 "$PLAN_DIR/scripts/ac-coverage.sh"
fi

# ---- stage 3+ --------------------------------------------------------------------
run full-e2e                             3 pkg test:e2e
run security-audit                       3 pkg audit                # e.g. "audit": "pnpm audit --audit-level high && gitleaks detect"
run env-schema                           3 pkg check:env            # boot-time env validation in CI mode
run perf-budget                          3 "$CHK/perf.sh"          # exits 3 unless configured (SPEC §7)
run red-team-regressions                 3 pkg test:rt              # tests named [RT-xx]

# ---- stage 4 ---------------------------------------------------------------------
run debt-closed                          4 "$CHK/debt.sh" --must-be-empty

write_report true
log "✓ PASS  stage=$STAGE ticket=$TICKET ($((SECONDS-START))s) → $OUT/verify.json"
