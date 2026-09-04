#!/usr/bin/env bash
# debt.sh — every TODO/FIXME/@debt in source has an entry in state/DEBT.md; --must-be-empty: Open table must be empty (stage 4).
set -euo pipefail
PLAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; REPO_ROOT="$(cd "$PLAN_DIR/.." && pwd)"; cd "$REPO_ROOT"
DEBT="$PLAN_DIR/state/DEBT.md"
SRC_DIRS=(); for d in src app lib; do [[ -d $d ]] && SRC_DIRS+=("$d"); done   # ── STACK ADAPTER ──
fail=0
# Open records persist; matching appended closure/acceptance records resolve them.
open_rows=$(awk '
  /^## Open/{section="open";next}
  /^## Closed/{section="closed";next}
  /^\|/{
    split($0, fields, "|"); id=fields[2]; gsub(/^[ \t]+|[ \t]+$/, "", id)
    if (id !~ /^D-?[0-9A-Za-z]+$/) next
    if(section=="open") {rows[id]=$0; order[++n]=id}
    if(section=="closed") {
      outcome=fields[5]; gsub(/^[ \t]+|[ \t]+$/, "", outcome)
      if(outcome ~ /^(closed|deferred-accepted)([ \t:]|$)/) resolved[id]=1
    }
  }
  END {for(i=1;i<=n;i++) if(!resolved[order[i]]) print rows[order[i]]}
' "$DEBT")
if [[ "${1:-}" == "--must-be-empty" ]]; then
  if [[ -n "$open_rows" ]]; then echo "debt: open items remain at stage 4:"; echo "$open_rows" | sed 's/^/  /'; exit 1; fi
  echo "debt: ledger closed"; exit 0
fi
hits=""; (( ${#SRC_DIRS[@]} )) && hits=$({ grep -rnE 'TODO|FIXME|@debt' "${SRC_DIRS[@]}" 2>/dev/null || true; } | grep -v node_modules || true)
[[ -z "$hits" && -z "$open_rows" ]] && { echo "debt: ok (none)"; exit 0; }
while IFS= read -r line; do [[ -z "$line" ]] && continue
  file=${line%%:*}
  # any @debt(T-xxx) must name a ticket that appears in DEBT.md; plain TODO/FIXME must have the file path in DEBT.md
  if [[ "$line" =~ @debt\(([A-Za-z]+-[0-9]+)\) ]]; then t=${BASH_REMATCH[1]}; grep -q "$t" "$DEBT" || { echo "debt: $line → ticket $t not in DEBT.md"; fail=1; }
  else grep -qF "$file" "$DEBT" || { echo "debt: undeclared: $line"; fail=1; }; fi
done <<< "$hits"
(( fail )) && { echo "debt: add entries to state/DEBT.md (Open table) with owning ticket"; exit 1; }
echo "debt: ok ($(echo "$hits" | grep -c . || echo 0) markers, all declared)"
