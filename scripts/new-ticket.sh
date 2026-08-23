#!/usr/bin/env bash
# new-ticket.sh — create a ticket from TEMPLATE.md and append the LEDGER line.
# Usage: scripts/new-ticket.sh T-013 "Short title" [stage]
set -euo pipefail
PLAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ID="${1:?ticket id e.g. T-013}"; TITLE="${2:?title}"; STAGE="${3:-$(grep -m1 -E '^stage:' "$PLAN_DIR/state/WHITEBOARD.md" | awk '{print $2}')}"
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-|-$//g' | cut -c1-40)
F="$PLAN_DIR/tickets/$ID-$SLUG.md"
[[ -e "$F" ]] && { echo "exists: $F"; exit 1; }
TS=$(date -u +%Y-%m-%dT%H:%MZ)
sed -e "s/^# T-xxx — <<Short title>>/# $ID — $TITLE/" -e "s/T-xxx/$ID/g" -e "s/\*\*Stage:\*\* <<1>>/**Stage:** $STAGE/" \
    -e "s/STAGE=<<1>>/STAGE=$STAGE/" -e "s/- <<date>> created by planner/- $TS created by planner/" "$PLAN_DIR/tickets/TEMPLATE.md" > "$F"
echo "$TS | $ID | — -> todo | planner | $(git rev-parse --short HEAD 2>/dev/null || echo -) | — | created: $TITLE" >> "$PLAN_DIR/state/LEDGER.md"
echo "$F"
