# T-xxx — <<Short title>>

- **Status:** todo
- **Stage:** <<1>>
- **Depends on:** <<T-000, T-004>>
- **Budget:** 1 context window / 2 h
- **Owner (worker id):** —
- **Verifier required:** <<auto (gate only) | blind verifier>>  ← per STAGES.md process dial

## Goal (one sentence)
<<What exists when this is done.>>

## Contracts this implements / consumes
- <<`src/core/types.ts` → `Project`, `createProject()`>>
- <<`openapi.yaml` → `POST /api/projects`>>

## Acceptance criteria (from SPEC.md)
- AC-<<02.01>>
- AC-<<02.02>>

## In scope
- <<files / modules this ticket owns>>

## Out of scope (do not touch)
- <<e.g. UI for listing projects (T-007); auth changes>>

## Verification
```bash
STAGE=<<1>> TICKET=T-xxx scripts/verify.sh
```

## Evidence required
- Stage 1: `verify.json` + `diff.patch`
- Stage 2+: + `notes.md` (built / ACs / not-done / debt / repro) + screenshots or API logs if UI/API

## Applicable lessons
- <<L3, P2>>

## Known risks / notes
- <<...>>

## Log
- <<date>> created by planner
