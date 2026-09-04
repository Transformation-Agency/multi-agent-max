# PROTOCOL — roles, tickets, evidence, and integration

## Roles

| Role | Responsibility | Boundary |
|---|---|---|
| Planner | Scope tickets, dispatch Workers/Verifiers, name integration milestones, maintain state, escalate | Does not implement or mark feature tickets done |
| Worker | Implement its ticket, test affected behavior, record local evidence and deferrals | Does not change shared contracts without a decision or claim integration certification |
| Verifier | Independently read diffs/test quality, assess evidence, accept tickets against integrated milestone evidence | Does not fix code or blindly trust a Worker summary |
| Red team | Attack SPEC risks, file reproducible findings and regression tests at Stage 3 | Does not fix findings or certify work |
| Human | Stage 0 review, Stage 2 demo, consequential decisions, Stage 4 approval | Final authority on intended behavior |

Keep independent context: Workers receive their assignment and relevant code/spec;
Verifiers receive ticket, diff, evidence, SPEC, and ARCHITECTURE, not Worker reasoning.
The repo supplies prompts/scripts, not an automatic agent scheduler.

## Ticket lifecycle

`todo → building → implemented → done`, with `rejected(n)` / `blocked` alternatives.

| Transition | Actor | Evidence |
|---|---|---|
| todo → building | Planner | Dependencies available, owned files/worktree assigned, milestone named |
| building → implemented | Worker | Focused ticket checks pass, diff/notes supplied, PR ready; deferred checks named |
| implemented → done | Verifier | Required diff review and passing milestone report covering integrated code |
| implemented → rejected(n) | Verifier | Concrete review defect and evidence path; return to Planner |
| building → blocked | Worker | Genuine blocker or budget exhausted, diagnosis |
| rejected/blocked → todo | Planner | Re-scoped assignment; decision if shared contract changes |

T-000 is an infrastructure exception: human Stage 0 acceptance permits done with
startup evidence. T-001 may be implemented before the first milestone and marked
done by its Verifier when that milestone passes. No ordinary ticket can be called
done on a local-only pass.

Default budget is one context window / 2 hours; split oversized assignments. One
worktree per Worker; parallelize disjoint ownership. Rebase before integration;
squash-merge, never force-push main. `implemented` tickets can be integrated into
an integration branch before certification. Main may serve as the integration
branch if it is not automatically deployed; otherwise use a separate branch.

A dependent Worker may consume an implemented, reviewed interface with explicit
Planner approval, but do not build a large chain on unverified changes. Changed
shared interfaces trigger a milestone before substantial downstream work.

## Local verification and evidence

Each ticket specifies an exact focused command and why it checks the affected
behavior. Prefer a test runner's file/test selection, focused type/lint checks, or
a reproducible startup/behavior check where automated infrastructure is not ready.
Security/access/data/money behavior needs meaningful tests as it is introduced;
do not use deferred infrastructure to defer basic safety validation.

`STAGE=1 TICKET=T-012 plan/scripts/verify.sh --profile ticket -- pnpm run test:unit -- src/projects.test.ts`

The script records logs, profile, commit, dirty flag, command, results, and deferred
broader checks. It preserves dependencies/caches. Exit 0 with profile=ticket means
LOCAL CHECKS PASS, not whole-app certification. Do not repeatedly run the wrapper
while editing; use fast commands directly, then record evidence at submission.

Commit implementation before evidence capture when practical. Append evidence and
notes afterward; identify the tested implementation commit separately from the
later evidence-only commit. If testing uncommitted changes, include the exact diff
and identify untracked implementation files. Dirty evidence is not reusable based
on its commit SHA alone. Rebase/merge or any code/config/dependency changes invalidate
reuse until the relevant checks are rerun on the resulting state.

Each attempt directory contains verify.json/log (and checks.tsv), plus diff.patch
and notes.md. Notes list ACs checked, exact commands, tested implementation revision,
what was not checked, and owning integration milestone. UI/API notes link screenshots
or API logs when needed to substantiate behavior. Preserve old attempts.

## Verifier policy

- Stage 1: independent review of contract/auth/data/money changes before integration;
  ordinary tickets can be reviewed together at their feature milestone.
- Stage 2: independent per-ticket review for contract/auth/data/money; others batched.
- Stage 3+: every ticket gets independent diff review, still with batched broad checks.
- Ask: does each test actually exercise its AC, and would it fail if behavior broke?
  Inspect scope, ownership, suppressions, weakened assertions, and debt.
- A fresh context does NOT require a fresh installation. Rerun focused checks if
  evidence is absent, stale, suspicious, environment-sensitive, or risk warrants it.
- Reuse traceable evidence only for the same tested code, dependencies, configuration,
  and relevant environment. CI evidence can satisfy a milestone; inspect the report.
  Do not automatically repeat a valid full suite locally.
- Accept implemented tickets as done only after matching them to a successful
  integrated milestone and completing required review. Write verdicts and ledger
  entries referencing the milestone's tested revision and evidence.

## Integration milestones

Planner records a milestone ID, scope/member tickets, stage, integration branch,
checks deferred to it, and status in WHITEBOARD. This is the owner of routine broader
verification deferrals; exceptional shortcuts also go in DEBT with an owning ticket.

At the first feature group, T-001 wires core checks and the real-flow smoke test and
commits a config baseline. Run `--profile milestone` on combined code. No routine
clean install. The runner clears only .reports JSON/XML output before broad runs;
this directory is test-runner scratch, not a fixture or permanent evidence directory.

The runner gathers independent failures together. A failed build blocks browser/
performance checks that need it; a failed fresh install blocks all later checks.
If your integration tests require a build, adapt that dependency in verify.sh.
Failed checks cannot be certified even if other checks pass. Missing required
configuration fails the milestone. AC coverage runs after report-producing suites.

Planner groups failures by cause and assigns repairs. Use targeted checks while
repairing; rerun the milestone after the fixes. Verifier reviews the combined diff,
report, and AC mapping, then records acceptance and closes covered tickets. Do not
rerun the full milestone solely because status/evidence-only files were appended;
verify no implementation, config, or dependency change occurred.

## State and history

- WHITEBOARD: compact current view, active tickets, milestones/deferrals, blockers,
  failed approaches, next three actions. Update at meaningful transitions.
- DECISIONS: append-only important architecture/shared-contract decisions.
- LESSONS: append-only failures and operational rules; generate active view in CLAUDE.md.
- DEBT: declared shortcuts; close by appending a matching ID in Closed / accepted.
  Do not delete an Open row; the closure supersedes it. Human accepted deferrals
  require explicit approval recorded with their rationale.
- LEDGER: timestamp, ticket/milestone, transition, actor, implementation revision,
  evidence path. Every status transition is recorded.
- evidence/: all attempts, including failures. No editing prior evidence.

Audit scripts are guardrails, not tamper-proof history or substitutes for review.

## Failure handling

Workers fix clear local failures without weakening tests. After three failed repair
attempts, stop with a diagnosis. Verifier rejection returns to Planner, who records
a lesson and re-scopes/re-spawns a fresh Worker. Two consecutive rejections escalate
to human. Flaky tests get quarantine + owning ticket, not retries until green.
Shared-contract changes require a decision and affected checks; clarify consequential
scope/taste ambiguities with human. Preserve failed evidence; never relabel it a pass.

## Red team and release

At Stage 3 attack SPEC risks first: authorization/tenancy, concurrency, partial
writes, dependency outages, malicious inputs, money/idempotency where relevant.
Each finding gets RT-xx ticket, severity, repro, AC mapping, and failing regression.
P0/P1 block release; other findings need fixes or accepted debt.

At Stage 4 run release profile with --fresh on a clean committed release checkout,
preferably a new clone. CI must be configured by release; the same CI run may supply
the clean release evidence. Reviewer confirms no open high-severity findings,
missing required checks, or skipped/quarantined tests on certified paths. Verify
optional check applicability against SPEC. Write ACCEPTANCE-REPORT.md with features,
ACs, deferrals, evidence index, and stage tags. Human reviews intent and signs off
in LEDGER. A green script alone does not grant release approval.
