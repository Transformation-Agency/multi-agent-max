# STAGES — the rigor dial

The same package, roles, and `verify.sh` run in every stage. What changes is *which
checks run* and *who has to look*. The current stage is the `stage:` line in
`state/WHITEBOARD.md`; `verify.sh` reads it (or `STAGE=` env). Planner advances the
stage only when the exit gate passes, then tags git `stage-N-complete`.

Speed comes from **deferring** verification, not skipping it. Anything deferred is
written down in `state/DEBT.md`.

## Overview

| Stage | SDLC analog | Goal | Human |
|---|---|---|---|
| 0 Lock | Design / scaffold | Contracts, stubs, CI, seed, golden-demo smoke all green | Review contracts (touchpoint 1) |
| 1 MVP | Build | Golden demo works end-to-end, ugly OK | **None** |
| 2 Integrate | Alpha / integration | Features work together; demoable | Demo walkthrough (touchpoint 2) |
| 3 Harden | QA / security | Break it before users do; debt burn-down | Triage P0/P1 only |
| 4 Release | UAT / acceptance | Fresh-clone win condition | Sign-off (touchpoint 3) |

## verify.sh checks by stage

| Check | 0 | 1 | 2 | 3 | 4 | Notes |
|---|---|---|---|---|---|---|
| clean state / frozen lockfile (`--fresh`) | ✓ | ✓ | ✓ | ✓ | ✓ | `--fresh` mandatory for verifier and Stage 4 |
| config-hash (verify.sh, lint/ts/test configs unchanged) | ✓ | ✓ | ✓ | ✓ | ✓ | anti-gaming |
| audit-append-only | ✓ | ✓ | ✓ | ✓ | ✓ | audit files only grow |
| no-skip / no-only / assertion presence | ✓ | ✓ | ✓ | ✓ | ✓ | anti-gaming |
| typecheck | ✓ | ✓ | ✓ | ✓ | ✓ | |
| lint — bug rules only | ✓ | ✓ | ✓ | | | |
| lint — full incl. style | | | | ✓ | ✓ | |
| unit tests | ✓ | ✓ | ✓ | ✓ | ✓ | |
| build | ✓ | ✓ | ✓ | ✓ | ✓ | |
| test-count ratchet | ✓ | ✓ | ✓ | ✓ | ✓ | can't drop without ADR |
| golden-demo smoke (1 flow, ~30s) | ✓ | ✓ | ✓ | ✓ | ✓ | written once in S0 |
| debt ledger consistency | | ✓ | ✓ | ✓ | ✓ | TODO ↔ DEBT.md |
| integration tests | | | ✓ | ✓ | ✓ | |
| smoke e2e (3–6 flows) | | | ✓ | ✓ | ✓ | |
| module boundaries / reusable layer | | | ✓ | ✓ | ✓ | |
| AC coverage — report only | | | ✓ | | | |
| AC coverage — strict 100% | | | | ✓ | ✓ | |
| full e2e | | | | ✓ | ✓ | |
| security (audit, secret scan, env schema) | | | | ✓ | ✓ | |
| perf budgets | | | | (✓) | (✓) | only if SPEC §7 requires |
| red-team regression suite | | | | ✓ | ✓ | tests written from findings |
| debt ledger must be closed | | | | | ✓ | or each item explicitly accepted |

## Process dial by stage

| Process element | 0 | 1 | 2 | 3 | 4 |
|---|---|---|---|---|---|
| Blind verifier per ticket | human | off (gate only) | on for contract/auth/data/money tickets | on for all | on for all |
| Evidence bundle | full | `verify.json` + diff | full | full | full |
| Red team | | | | on, scoped to SPEC §6 risks | re-run on fixes |
| Planner checkpoint (`verify.sh --fresh` on main + whiteboard rewrite) | | every 5 tickets | every 5 tickets | every 5 tickets | |
| Lesson written after each rejection | ✓ | ✓ | ✓ | ✓ | ✓ |

## Stage exit gates

**Stage 0 → 1**
- All contracts in ARCHITECTURE §4 exist as code and compile with stubs.
- `verify.sh` green (stage 0 set) on CI.
- Seed fixtures + golden-demo smoke test exist and pass against stubs/minimal impl.
- `scripts/checks/config-hash.sh --init` baseline committed.
- Human has reviewed SPEC ACs and contracts and confirmed they match intent.

**Stage 1 → 2**
- Every SPEC feature tagged `stage: 1` has all its tickets `done` (gate-verified).
- Golden demo script (SPEC §5) runs end-to-end.
- `verify.sh --fresh` green on main.
- DEBT.md reviewed by planner: every item has an owning ticket.

**Stage 2 → 3**
- All `stage: ≤2` features done, verifier-certified (retro-verify Stage 1 tickets touching contract/auth/data/money).
- Integration + smoke e2e green.
- AC coverage report: planner has a ticket for every uncovered AC.
- Human demo done; feedback converted to tickets.

**Stage 3 → 4**
- AC coverage 100%, full e2e green, security checks green.
- Red-team report filed; zero open P0/P1; P2+ either fixed or accepted in DEBT.md with rationale.
- Every red-team finding has a regression test.
- DEBT.md: open items are each explicitly `deferred-accepted` by human or closed.

**Stage 4 → finished**  (see PROTOCOL.md §9)
- Fresh clone, `STAGE=4 verify.sh --fresh` green.
- `ACCEPTANCE-REPORT.md` written.
- Human sign-off recorded in LEDGER.md.

## Invariants — never relax

1. Contracts change only via ADR.
2. Tests are never weakened to pass. Flaky → quarantine (tag + exclude + ticket) on first occurrence; never retried into green.
3. Debt declared, not hidden.
4. Whiteboard maintained.
5. Audit record append-only (LESSONS, DECISIONS, DEBT, LEDGER, evidence/, git history — no force-push to main).
6. Only a Verifier sets `done`.
