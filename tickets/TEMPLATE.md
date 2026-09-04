# T-xxx — <<Short title>>

- **Status:** todo
- **Stage:** <<1>>
- **Depends on:** <<T-000, T-004>>
- **Budget:** 1 context window / 2 h
- **Owner (worker id):** —
- **Verifier required:** <<risk-ticket review | milestone review | all-ticket review>> — per STAGES.md
- **Integration milestone:** <<M-001>> (owns broader deferred checks)

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

## Focused verification (local evidence only)
```bash
STAGE=<<1>> TICKET=T-xxx plan/scripts/verify.sh --profile ticket -- <<command>> <<args>>
```

## Evidence required
- `verify.json` + `diff.patch` + `notes.md` (tested revision, command, ACs, not-done, debt, deferred checks + milestone)
- Stage 2+: screenshots or API logs when needed to substantiate UI/API behavior

## Integration acceptance

- Worker sets `implemented` after focused evidence.
- Required review: <<...>>.
- Milestone command: `STAGE=<<1>> TICKET=<<M-001>> plan/scripts/verify.sh --profile milestone`.
- Verifier sets `done` only after required review and passing combined milestone evidence.

## Applicable lessons
- <<L3, P2>>

## Known risks / notes
- <<...>>

## Log
- <<date>> created by planner
