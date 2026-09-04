# T-000 — Stage 0: first flow, essential design, local scaffold

- **Status:** todo
- **Stage:** 0
- **Depends on:** SPEC and essential ARCHITECTURE decisions available
- **Budget:** One context window; target a short setup pass, split if genuinely blocked
- **Owner (worker id):** —
- **Verifier required:** human scope/design review
- **Integration milestone:** M-001 (broader checks owned by T-001)

## Goal
The first feature is clearly defined, the scaffold starts locally, essential data/
access decisions are recorded, and no unresolved blocker prevents implementation.

## In scope
- First-flow ACs, non-goals, major risks, and necessary stack/shared-interface decisions.
- Minimal scaffold and actual startup check; reuse useful existing checks.
- Document first assignments and T-001 ownership of deferred verification setup.
- Human review before Stage 1.

## Out of scope
- CI, full build/test certification, config baseline, complete contract stubs.
- Browser-test infrastructure or seed fixtures for features not being built yet.
- Future API/schema design beyond the first assignments' dependencies.

## Local verification
Planner fills in an exact finite command that starts/checks/stops the scaffold,
or uses an existing startup test. Do not substitute a no-op.

```bash
STAGE=0 TICKET=T-000 plan/scripts/verify.sh --profile ticket -- <<startup-check-command>>
```

## Evidence and acceptance
Startup command/result, implementation revision/diff, notes listing essential
decisions and deferred checks owned by M-001/T-001. Human acceptance permits done
as the infrastructure exception; it does not claim integrated verification.

## Log
- created by template
