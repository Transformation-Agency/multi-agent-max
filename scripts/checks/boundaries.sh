#!/usr/bin/env bash
# boundaries.sh — reusable layer has no reverse edges into app code; module rules from ARCHITECTURE §3.
# ── STACK ADAPTER ── default: dependency-cruiser if configured; else a grep fallback on a REUSABLE list.
set -euo pipefail
PLAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; REPO_ROOT="$(cd "$PLAN_DIR/.." && pwd)"; cd "$REPO_ROOT"
if [[ -f .dependency-cruiser.js || -f .dependency-cruiser.cjs || -f .dependency-cruiser.json ]]; then exec pnpm exec depcruise src; fi
REUSABLE=( src/core src/integrations )          # must not import from:
FORBIDDEN=( src/app src/db src/ui src/services )
any=0; fail=0
for r in "${REUSABLE[@]}"; do [[ -d "$r" ]] || continue; any=1
  for f in "${FORBIDDEN[@]}"; do
    if grep -rnE "from ['\"](\.\./)*(@/|src/)?${f#src/}(/|['\"])" "$r" 2>/dev/null; then echo "boundaries: $r imports from $f"; fail=1; fi
  done; done
(( any )) || { echo "boundaries: no reusable dirs present — not configured"; exit 3; }
(( fail )) && exit 1; echo "boundaries: ok"
