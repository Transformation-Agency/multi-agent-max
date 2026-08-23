# T-000 — Stage 0: scaffold, lock contracts, CI, seed, golden-demo smoke

- **Status:** todo
- **Stage:** 0
- **Depends on:** — (SPEC.md and ARCHITECTURE.md filled in by human)
- **Budget:** 1 context window / 2 h (split into T-000a/b/c if larger)
- **Owner (worker id):** —
- **Verifier required:** human (contract review = touchpoint 1)

## Goal
The repo compiles, CI runs `verify.sh` at stage 0 green, every contract in
ARCHITECTURE §4 exists as code with stub implementations, seed fixtures load, and
a single golden-demo smoke test passes against the stubs.

## Contracts this implements
- All of ARCHITECTURE.md §4 (types, DB schema + migration 0, API surface stubs, auth model, env schema, events)

## Acceptance criteria
- (none from SPEC — this is infrastructure; exit gate is STAGES.md "Stage 0 → 1")

## In scope
- Project scaffold per ARCHITECTURE §1 stack adapter
- Contract files with `throw new Error("not implemented")` / TODO stubs, compiling
- `scripts/verify.sh` stack-adapter lines wired and green at STAGE=0
- CI workflow running `STAGE=0 scripts/verify.sh --fresh`
- `db:seed` fixtures (the data every worker + smoke test starts from)
- One smoke test implementing SPEC §5 golden demo as far as stubs allow (at minimum: app boots, home route 200)
- `scripts/checks/config-hash.sh --init` baseline committed
- Lint config: bug rules only (style rules present but off until Stage 3)

## Out of scope
- Any feature logic. Any UI beyond a placeholder page.

## Verification
```bash
STAGE=0 TICKET=T-000 scripts/verify.sh --fresh
```

## Evidence required
- Full bundle: verify.json, diff.patch, notes.md listing every contract file created and the command to run the smoke test

## Applicable lessons
- (none yet)

## Log
- created by template
