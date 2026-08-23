#!/usr/bin/env bash
# gen-claude-md.sh — regenerate the "Active lessons" view in CLAUDE.md from the append-only state/LESSONS.md record.
# A lesson is active if its most recent entry for that ID has status `active`.
set -euo pipefail
PLAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LESSONS="$PLAN_DIR/state/LESSONS.md"; CLAUDE="$PLAN_DIR/CLAUDE.md"

# Parse entries: header "### <ID> · <series> · <status> · <date> · <ticket>" followed by body lines until next ### or EOF.
active=$(awk '
  /^### /{ if(id!=""){ entries[id]=body; status[id]=st; order[++n]=id }
           line=$0; sub(/^### /,"",line); split(line,p," · "); id=p[1]; st=p[3]; body=$0"\n"; next }
  /^<!--/ {skip=1} skip&&/-->/ {skip=0; next} skip{next}
  { if(id!="") body=body $0 "\n" }
  END{ if(id!=""){ entries[id]=body; status[id]=st; order[++n]=id }
       # latest entry per id wins (file is append-only, so later overrides earlier)
       for(i=1;i<=n;i++){ id=order[i]; seen[id]=i }
       for(i=1;i<=n;i++){ id=order[i]; if(seen[id]==i && status[id]=="active") printf "%s\n", entries[id] } }
' "$LESSONS")
[[ -n "$active" ]] || active="_(none yet)_"

tmp=$(mktemp)
ACTIVE_LESSONS="$active" awk '
  /<!-- LESSONS:BEGIN/ { print; print "## Active lessons"; print ""; print ENVIRON["ACTIVE_LESSONS"]; inblock=1; next }
  /<!-- LESSONS:END/   { inblock=0 }
  !inblock { print }
' "$CLAUDE" > "$tmp" && mv "$tmp" "$CLAUDE"
n=$(grep -c '^### ' <<< "$active" || true)
echo "CLAUDE.md regenerated: $n active lesson(s)"
