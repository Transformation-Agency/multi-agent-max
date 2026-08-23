#!/usr/bin/env bash
# config-hash.sh — the gate and its configs must not be loosened silently.
# Hashes verify.sh, the checks, and lint/ts/test configs; compares to committed baseline.
# Usage: config-hash.sh [--init]   (--init writes/overwrites the baseline — cite an ADR in the commit)
set -euo pipefail
PLAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; REPO_ROOT="$(cd "$PLAN_DIR/.." && pwd)"; cd "$REPO_ROOT"
BASE="$PLAN_DIR/state/config-baseline.sha256"
# ── STACK ADAPTER ── add your config files
FILES=( "$PLAN_DIR/scripts/verify.sh" "$PLAN_DIR/scripts/ac-coverage.sh" "$PLAN_DIR"/scripts/checks/*.sh
        tsconfig.json eslint.config.* .eslintrc* vitest.config.* jest.config.* playwright.config.* pyproject.toml setup.cfg .flake8 )
existing=(); for f in "${FILES[@]}"; do [[ -f "$f" ]] && existing+=("$f"); done
hash() { for f in "${existing[@]}"; do printf '%s  %s\n' "$(shasum -a 256 "$f" | cut -d' ' -f1)" "${f#$REPO_ROOT/}"; done | sort -k2; }
if [[ "${1:-}" == "--init" ]]; then hash > "$BASE"; echo "baseline written: $BASE (${#existing[@]} files). Commit it, citing an ADR."; exit 0; fi
[[ -f "$BASE" ]] || { echo "config-hash: no baseline at $BASE — run with --init (stage 0)"; exit 3; }
if diff <(hash) "$BASE" >/dev/null; then echo "config-hash: ok (${#existing[@]} files)"; exit 0; fi
echo "config-hash: MISMATCH — gate/config files changed without re-baselining:"; diff <(hash) "$BASE" | grep '^[<>]' | sed 's/^/  /' || true
echo "If intentional: write an ADR, then run config-hash.sh --init and commit."; exit 1
