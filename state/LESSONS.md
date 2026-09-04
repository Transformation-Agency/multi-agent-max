# LESSONS — append-only record
<!--
One entry per lesson. NEVER edit or delete a prior entry. To retire or revise, append a new
entry with `status: retired` or a new id that says `supersedes: Lxx`.
CLAUDE.md shows only `status: active` entries — regenerate with scripts/gen-claude-md.sh.

Series: L = tool/stack idiom · P = process · M = domain/model structure · B = bridging/architecture
Format (keep exactly — the generator parses it):

### <ID> · <series> · <status> · <date> · <ticket>
**Failure mode:** ...
**Fix:** ...
**Rule:** ...
-->

### P1 · P · active · <<date>> · T-000
**Failure mode:** Treating a green build as proof a change is complete.
**Fix:** Run `scripts/verify.sh`; read the diff; map tests to AC ids.
**Rule:** Green build is a precondition, not a certificate. Only verify.sh exit 0 + verifier diff read counts.

### P1 · P · retired · 2026-09-04 · template-update
**Reason:** Superseded by P2: distinguish local evidence from integrated certification.

### P2 · P · active · 2026-09-04 · template-update
**Failure mode:** Stage 0 setup and full verification at each handoff delay working features.
**Fix:** Small startup stage, focused ticket checks, batched integration milestones, clean release verification.
**Rule:** Local pass means implemented; only reviewed integrated evidence means done. Record deferred checks and their milestone owner. Preserve the principle that a build alone does not prove completion.
