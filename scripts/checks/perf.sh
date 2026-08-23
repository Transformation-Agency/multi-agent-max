#!/usr/bin/env bash
# perf.sh — optional perf budgets (only if SPEC §7 defines any). Exit 3 = not configured.
# ── STACK ADAPTER ── e.g. bundle-size check, lighthouse-ci, k6 against a local server.
set -euo pipefail
PLAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; REPO_ROOT="$(cd "$PLAN_DIR/.." && pwd)"; cd "$REPO_ROOT"
[[ -f "$PLAN_DIR/perf-budgets.json" ]] || { echo "perf: no perf-budgets.json — not configured"; exit 3; }
echo "perf: implement against perf-budgets.json"; exit 1
