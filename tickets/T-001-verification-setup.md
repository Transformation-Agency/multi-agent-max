# T-001 — First integration milestone: verification setup

- **Status:** todo
- **Stage:** 1
- **Depends on:** T-000; coordinate with first real-flow Worker
- **Budget:** 1 context window / 2 h; split CI follow-up if deferred
- **Owner (worker id):** —
- **Verifier required:** milestone review
- **Integration milestone:** M-001

## Goal
The first real feature group can be integration-verified without imposing this
setup on Stage 0 or repeating it per ticket.

## In scope
- Wire typecheck, bug lint, unit tests, build, and ONE real golden-demo smoke test.
- Add only fixtures needed by that flow; tests assert meaningful behavior with AC IDs.
- Configure report output into runner-owned .reports/; commit config-hash baseline.
- Document stack commands and record focused setup evidence.
- Arrange first stage 1 milestone on combined setup + feature code.
- CI at Stage 2, or explicit release-owned deferral: <<owner, follow-up ticket, due>>.
  Before release CI must invoke the same verification command and preserve evidence.

## Out of scope
Full e2e/security/performance infrastructure before its stage needs it. Do not remove
or disable already useful checks. Do not impose a fresh install on ticket workflows.

## Focused verification
```bash
STAGE=1 TICKET=T-001 plan/scripts/verify.sh --profile ticket -- <<focused-setup-check>>
```

## Integration acceptance
```bash
STAGE=1 TICKET=M-001 plan/scripts/verify.sh --profile milestone
```

Can become implemented alongside the first feature; becomes done only after M-001
passes and Verifier accepts. Missing required setup fails the milestone.

## Log
- created by template
