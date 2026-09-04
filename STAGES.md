# STAGES — progressive verification

Stage controls product maturity; verification profile controls the work performed
on this run. Read `stage:` in `state/WHITEBOARD.md` (or set `STAGE`). A ticket pass
is local evidence, not certification of the combined app.

## Three verification profiles

| Profile | When | What it does |
|---|---|---|
| `ticket` | Worker development/submission, any stage 0–3 | Runs an explicit focused command plus cheap audit/debt checks; checks the config baseline if it exists. Preserves dependencies, build caches, and reports. Lists broader checks as deferred. |
| `milestone` | A coherent feature group is integrated, shared interfaces change, or a stage ends | Runs the stage's broader checks on combined code, reusing dependencies/caches. Collects independent failures in one report; blocks checks whose prerequisites failed. |
| `release` | Stage 4 release candidate | Requires `--fresh` and a clean committed checkout, reinstalls from the lockfile, clears build caches, runs all release checks. |

Default profile: ticket at stages 0–1, milestone at stages 2–3, release at stage 4.
Always specify the profile in ticket commands. Ticket requires a command after `--`.
`--fresh` is never routine ticket work; milestone may use it for an environment
problem. Stage 4 cannot use a cheaper profile.

## Stage overview

| Stage | Goal | Human |
|---|---|---|
| 0 Prepare | Clear first flow, essential design choices, scaffold starts locally | Review scope, essential interfaces/access rules |
| 1 MVP | Golden demo works end-to-end; feature groups integration-verified | Escalations only |
| 2 Integrate | Broader integration/browser coverage and configured verification | Demo walkthrough |
| 3 Harden | Risk-focused red team, strict AC coverage, security checks | P0/P1 triage and accepted deferrals |
| 4 Release | Clean-copy verification and acceptance report | Final sign-off |

## Stage 0 → 1: small and bounded

- SPEC defines first flow, observable success conditions, non-goals, and key risks.
- ARCHITECTURE records stack, essential data/access decisions, and interfaces needed
  by the first assignments. Unneeded future contracts can remain planned.
- Scaffold starts locally; ticket evidence records the startup command/result.
- Existing useful checks are used; do not build a full testing framework just to exit.
- T-001 owns verification setup for the first feature milestone: core checks, smoke
  test for a real flow, and config baseline. CI can wait until Stage 2 or release.
- Human reviews the scope and essential agreements. Human acceptance of T-000 is
  the infrastructure-only exception to integration certification; log it explicitly.

No CI, complete contract stubs, database fixtures for future features, clean install,
full build/test gate, or full browser suite is required to exit Stage 0.

## Milestone check matrix (not per ticket)

| Check | Stage 1 | Stage 2 | Stages 3–4 |
|---|---|---|---|
| Config baseline, audit, no-skip, debt consistency | Required | Required | Required |
| Typecheck, unit tests, build, golden-demo smoke, test-count ratchet | Required | Required | Required |
| Lint | Bug rules | Bug rules | Full |
| Integration tests, smoke e2e, module boundaries | Deferred | Required | Required |
| AC coverage | Deferred | Report uncovered ACs | Strict 100% |
| Full e2e, security audit, env validation | Deferred | Deferred | Required |
| Performance budgets | Deferred | Deferred | Required if SPEC defines them; configure perf-budgets.json |
| Red-team regressions | Deferred | Deferred | Required when RT finding tickets exist |
| Debt closed or explicitly human-accepted | — | — | Stage 4 only |
| Clean install | Only environment diagnosis | Only environment diagnosis | Mandatory at release |

Missing required commands/reports/baselines FAIL a milestone or release. Exit 3
means unconfigured, never a required-check pass. Adapt genuinely inapplicable stack
checks explicitly in ARCHITECTURE and the script; do not silently substitute a no-op.
The reviewer verifies optional performance/red-team applicability against the SPEC
and red-team report. These human judgments are not automated by the script.

## Integration cadence

Planner names a milestone and its member tickets BEFORE dispatch. Run it after a
coherent feature group lands and before building substantially on changed shared
interfaces. Review the whiteboard every five tickets as a backstop; it does not
itself require reinstalling or repeating a previously valid milestone run. If work
has accumulated without integrated evidence, schedule the milestone now.

T-001 is completed alongside the first real flow and before its milestone. First
milestone uses stage 1 even if other MVP features remain. After failures, group root
causes, repair, run affected checks during repair, then run the milestone once on
the repaired combined state. Never reuse evidence across changed code, dependencies,
configuration, or a relevant environment change. Do not postpone all build feedback
to the end of the app.

## Stage 1 → 2

- Stage 1 features and golden demo work; their tickets are `done` after milestone
  evidence on the integrated revision and Verifier milestone acceptance.
- First-flow smoke/core checks and committed config baseline exist.
- A stage 1 milestone covers the current integrated state; debt has owners.

## Stage 2 → 3

- Stage ≤2 feature tickets are done; stage 2 milestone passes.
- Contract/auth/data/money tickets have independent diff review (including Stage 1).
- Every uncovered AC has an owning ticket.
- Human demo feedback becomes tickets.
- CI runs the same milestone command, or T-001 records a concrete release-owned CI
  deferral. Do not duplicate an identical successful CI run locally without cause.

## Stage 3 → 4

- Current stage 3 milestone passes; AC coverage is 100%.
- Red-team report addresses SPEC risks; no open P0/P1; each finding has a regression.
- Remaining debt is closed or explicitly deferred-accepted by human.
- CI is configured before release, even if deferred at Stage 2.

## Stage 4 → finished

- Fresh clone/clean release checkout; `STAGE=4 TICKET=release plan/scripts/verify.sh
  --profile release --fresh` passes. CI may supply this evidence for the same revision.
- No quarantined/skipped tests on certified paths (Verifier checks this explicitly).
- ACCEPTANCE-REPORT.md and human sign-off in LEDGER.

## Invariants

Contracts shared by Workers change via recorded decisions; tests are never weakened
to pass; shortcuts and deferred checks stay visible; audit records remain append-only.
Only a Verifier sets feature tickets `done` after integrated evidence. A ticket's
`implemented` status never claims milestone or release certification.
