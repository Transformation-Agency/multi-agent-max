# multi-agent-max

A reusable Planner / Worker / Verifier package for building software with clear
requirements, independent review, visible debt, and evidence of working behavior.
Start with a small Stage 0; build with focused checks; verify combined features at
integration milestones; certify the release from a clean checkout.

**Local checks prove local progress. Milestone checks certify integrated work.
Release checks support human sign-off.** A green ticket run is not a full-app pass.

Design lineage: Miller's formalization game (checkable outcomes, explicit agreements,
lessons from failures, audit records) and OpenProver (Planner/Worker/Verifier,
independent verification, whiteboard + repository).

## Quick start

```bash
mkdir my-app && cd my-app && git init
git clone --depth 1 git@github.com:Transformation-Agency/multi-agent-max.git plan
rm -rf plan/.git
```

Fill SPEC.md with the first user flow, acceptance criteria, non-goals, and risks.
Fill ARCHITECTURE.md with stack, essential data/access decisions, and interfaces
needed for the first assignments. Future interfaces can remain planned. Start the
Planner using `plan/prompts/planner.md` in an agent environment that can dispatch
subagents/worktrees; this repo does not launch agents itself.

T-000 gets the scaffold starting locally, records the startup check, and requests
human review. It does NOT require CI, full contract stubs, seed data for future
features, a complete test framework, or a fresh build. Then begin feature work.
T-001 owns core verification setup alongside the first real flow, due at the first
stage 1 milestone. Do not replace implementation with repeated infrastructure work.

## Daily commands

Run commands from the application root; the template lives in `plan/`.

```bash
# Worker: explicit focused command, dependencies/caches preserved.
STAGE=1 TICKET=T-012 plan/scripts/verify.sh --profile ticket -- pnpm run test:unit -- src/projects.test.ts

# Verifier/Planner: combined feature group, broader stage checks, no reinstall.
STAGE=1 TICKET=M-001 plan/scripts/verify.sh --profile milestone
STAGE=2 TICKET=M-002 plan/scripts/verify.sh --profile milestone

# Release candidate: clean committed checkout, full checks, fresh install.
STAGE=4 TICKET=release plan/scripts/verify.sh --profile release --fresh

plan/scripts/new-ticket.sh T-013 "Short title" 1
plan/scripts/gen-claude-md.sh
# Configure and commit at first milestone; later baseline changes cite a decision.
plan/scripts/checks/config-hash.sh --init
```

Ticket mode requires a command after `--`; at Stage 0 use an actual finite startup
check (start server, verify response, shut it down), or an existing scaffold check.
An automated test is preferred as soon as the real behavior exists. A placeholder
command such as `true` is not acceptable evidence. The Verifier judges relevance.

## Verification profiles

| Profile | Scope | Result |
|---|---|---|
| ticket | Explicit focused command + cheap audit/debt/config checks | Local-only pass; broader checks listed as deferred |
| milestone | Stage-specific build, tests, integration and security checks | Integrated evidence; missing required setup fails |
| release | Stage 4 checks + clean install and debt closure | Release evidence; human approval still required |

Default profile: ticket at stages 0–1, milestone at 2–3, release at 4. Explicit
profiles in tickets avoid accidental broad runs. Stage 4 requires release --fresh.

Milestones run after coherent feature groups and before substantial downstream
work relies on changed shared interfaces. Independent failures are collected in
one report; dependent browser checks are blocked after a failed build. Repair with
focused checks, then rerun the milestone on the repaired combined state. Do not
reinstall dependencies at each handoff. A failed fresh install stops further checks.

Full runs own `.reports/*.json` and `.reports/*.xml`: stale reports are cleared,
then AC coverage runs after all producing suites. Keep fixtures/evidence elsewhere.
Review may reuse valid evidence for unchanged code/config/dependencies/environment,
including CI evidence. Rebase/merge changes require verification of the combined result.

## Stack adapter

The default runner uses Node/pnpm. Add scripts alongside the first feature; the
following become REQUIRED at their first applicable milestone, not at Stage 0:

| Script | First milestone stage | Example |
|---|---|---|
| typecheck | 1 | tsc --noEmit |
| lint:bugs | 1 | eslint with bug rules |
| test:unit | 1 | vitest run --reporter=json --outputFile=.reports/unit.json |
| build | 1 | next build |
| test:smoke | 1 | one real golden-demo flow |
| test:integration | 2 | runner writing .reports/int.json |
| test:e2e:smoke | 2 | a few critical integrated browser flows |
| lint | 3 | full lint rules |
| test:e2e | 3 | full browser suite writing .reports/e2e.json |
| audit | 3 | dependency audit + secret scan |
| check:env | 3 | environment-schema validation |
| test:rt | 3, if RT tickets exist | regression tests for red-team findings |

Also configure module boundaries at Stage 2, performance checks only when SPEC
requires them, and config-hash baseline before the first milestone. Non-Node stacks:
adapt pkg/fresh_install and relevant checks, document genuine inapplicability in
ARCHITECTURE, and review changes. Exit 3 means unconfigured; required milestone/
release checks fail on it. Optional inapplicable checks are never represented as passes.

CI can be introduced at Stage 2; if deferred, T-001 records a concrete owner and it
must exist before release. CI runs the same milestone/release command, rather than
an independent duplicate checking system. Keep fast local checks while developing.

## Process and records

Stages remain Prepare → MVP → Integrate → Harden → Release. Human touchpoints remain
initial scope/design review, integrated demo, severe-risk decisions, and final approval.
See STAGES.md for exact exit criteria and PROTOCOL.md for roles and evidence rules.

Tickets progress `todo → building → implemented → done`. Workers may set implemented
after focused evidence. Verifier sets done only after required review and passing
integrated milestone evidence. T-000 human acceptance is the infrastructure exception.

| Path | Purpose |
|---|---|
| SPEC.md / ARCHITECTURE.md | Intent, ACs, design, shared interfaces |
| STAGES.md / PROTOCOL.md | Verification schedule and operating rules |
| prompts/ | Planner, Worker, Verifier, Red Team roles |
| CLAUDE.md | Standing rules and generated active lessons |
| tickets/ | Scope, focused commands, integration milestone ownership |
| state/WHITEBOARD.md | Current state, milestones, deferrals, blockers |
| state/DECISIONS.md / LESSONS.md | Decisions and earned lessons |
| state/DEBT.md | Shortcuts, append-only closure/accepted-deferral records |
| state/LEDGER.md | Ticket and milestone transition history |
| state/evidence/ | Every verification attempt, diffs, notes, verdicts |

Keep tests meaningful, contracts shared by Workers explicit, debt visible, audit
records append-only. The scripts are guardrails: text scans and AC IDs do not prove
behavior or guarantee security. Independent review and human acceptance remain essential.

## Migrating an existing project

Preserve its tests, CI, contracts, and existing audit history. Adopt the three profiles,
replace per-ticket --fresh commands with explicit focused commands, and add milestone
ownership to active tickets. Map old verifying tickets to implemented only when local
evidence exists; preserve historical verdicts/status lines. Do not invalidate previously
certified done work solely due to terminology. Re-baseline the changed gate under a
recorded decision after review. Update prompts/STAGES/PROTOCOL/CLAUDE together.

## Requirements and template validation

bash ≥3.2, git, node, and the application's stack toolchain. To test this template's
profile orchestration without installing application dependencies:

```bash
node scripts/tests/verify-profiles.test.js
```

Changes earned on projects can return here as PRs; project-specific lessons stay there.
