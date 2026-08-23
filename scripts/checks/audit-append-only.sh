#!/usr/bin/env bash
# audit-append-only.sh — audit files only grow; prior content never changes; evidence/ never loses files.
# Compares against the last committed version (HEAD) — so a commit that rewrote history is caught at the next gate,
# and a working-tree edit is caught before commit.
set -euo pipefail
PLAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; REPO_ROOT="$(cd "$PLAN_DIR/.." && pwd)"; cd "$REPO_ROOT"
git rev-parse HEAD >/dev/null 2>&1 || { echo "audit: not a git repo — not configured"; exit 3; }
REL="${PLAN_DIR#$REPO_ROOT/}"
FILES=( state/LESSONS.md state/DECISIONS.md state/DEBT.md state/LEDGER.md )
fail=0
for f in "${FILES[@]}"; do
  p="$REL/$f"; git cat-file -e "HEAD:$p" 2>/dev/null || continue
  old=$(git show "HEAD:$p"); cur=$(cat "$p")
  oldn=$(printf '%s\n' "$old" | wc -l); curn=$(printf '%s\n' "$cur" | wc -l)
  # DEBT.md: rows may move from Open to Closed, so only require every old *non-table* line to persist; others: strict prefix.
  if [[ "$f" == state/DEBT.md ]]; then
    while IFS= read -r l; do [[ "$l" =~ ^\| ]] && continue; [[ -z "$l" ]] && continue
      grep -qFx -- "$l" "$p" || { echo "audit: $f lost/changed line: $l"; fail=1; }; done <<< "$old"
    # every old Open/Closed ID must still exist somewhere
    for id in $(printf '%s\n' "$old" | grep -oE '^\| *D-?[0-9A-Za-z]+' | tr -d '| '); do grep -q "$id" "$p" || { echo "audit: DEBT id $id vanished"; fail=1; }; done
  else
    if (( curn < oldn )) || [[ "$(printf '%s\n' "$cur" | head -n "$oldn")" != "$old" ]]; then echo "audit: $f — prior content modified or removed (append-only)"; fail=1; fi
  fi
done
# evidence: no tracked file under evidence/ may be deleted or modified
if git diff --name-status HEAD -- "$REL/state/evidence" 2>/dev/null | grep -E '^(D|M)' >/dev/null; then
  echo "audit: evidence/ files deleted or modified:"; git diff --name-status HEAD -- "$REL/state/evidence" | grep -E '^(D|M)' | sed 's/^/  /'; fail=1; fi
(( fail )) && exit 1; echo "audit: ok (append-only preserved)"
