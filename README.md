# multi-agent-max

A reusable planning package for building production software with a
**Planner / Worker / Verifier** agent loop, a single machine-checkable gate
(`scripts/verify.sh`), and a rigor dial that ramps from "build the MVP fast,
unattended" to "fresh-clone, red-teamed, signed-off release."

Design lineage: Miller's *formalization game* (machine-checkable win condition,
contracts locked first, lessons earned from failures, append-only audit record) and
OpenProver (Planner/Worker/Verifier, blind verification, whiteboard + repository).

---

## The one idea

**An agent's claim of "done" is worth nothing. Only `scripts/verify.sh` exiting 0 is
a certificate.** Every other file here exists either to tell agents exactly what to
build, or to produce evidence that script can check.

You intervene at three points only: review contracts (Stage 0), watch a demo
(Stage 2), sign off (Stage 4). Everything between runs on the automated gate.

---

## Quick start — new project

```bash
# 1. Create your project repo (or cd into an existing one) and pull in the plan
mkdir my-app && cd my-app && git init
git clone --depth 1 git@github.com:Transformation-Agency/multi-agent-max.git plan
rm -rf plan/.git                        # it's your copy now; the plan lives with the project

# 2. Fill in the two human-authored files (this is the highest-leverage hour of the project)
$EDITOR plan/SPEC.md                     # vision, NON-goals, features → AC-xx.yy, golden demo, risk list
$EDITOR plan/ARCHITECTURE.md             # stack adapter, boundaries, contracts, external services

# 3. Wire the stack adapter (the ONLY stack-specific part)
#    - add the package scripts verify.sh calls (see "Stack adapter contract" below)
#    - edit the `# STACK ADAPTER` lines in plan/scripts/verify.sh if you're not on Node/pnpm
#    - make test runners write JSON to .reports/ (for AC coverage)

# 4. Baseline the gate and commit
plan/scripts/checks/config-hash.sh --init
git add -A && git commit -m "chore: adopt multi-agent-max plan [ADR-000]"

# 5. Start the planner (Claude Code: open the repo and paste prompts/planner.md as the first message)
#    Its first job is tickets/T-000-stage0-scaffold.md. When it finishes, review the contracts
#    it produced — that's human touchpoint #1 — then let it run Stage 1 unattended.
```

Sanity check before starting the planner: `STAGE=0 TICKET=setup plan/scripts/verify.sh`
should end with `✓ PASS` (unconfigured checks show as `skipped: not configured`).

### Stack adapter contract

`verify.sh` calls these package scripts via `pnpm run <name>` and treats a missing
script as "not configured" (skipped, not failed). Add them as you go:

| Script | Needed from | Suggested command (Next.js/TS) |
|---|---|---|
| `typecheck` | Stage 0 | `tsc --noEmit` |
| `lint:bugs` | Stage 0 | `eslint . --max-warnings 0` with style rules off |
| `lint` | Stage 3 | full eslint incl. style |
| `test:unit` | Stage 0 | `vitest run --reporter=json --outputFile=.reports/unit.json` |
| `build` | Stage 0 | `next build` |
| `test:smoke` | Stage 0 | ONE golden-demo flow, ~30s (`playwright test --grep @golden`) |
| `test:integration` | Stage 2 | `vitest run -c vitest.integration.ts --reporter=json --outputFile=.reports/int.json` |
| `test:e2e:smoke` | Stage 2 | `playwright test --grep @smoke` (3–6 flows) |
| `test:e2e` | Stage 3 | `playwright test` (json reporter → `.reports/e2e.json`) |
| `audit` | Stage 3 | `pnpm audit --audit-level high && gitleaks detect` |
| `check:env` | Stage 3 | boot env-schema validation |
| `test:rt` | Stage 3 | tests named `[RT-xx]` (red-team regressions) |

Non-Node stacks: replace the `pkg()` helper in `verify.sh` with your runner (make, cargo,
poetry…) — the rule is "exit 3 = not configured", anything else non-zero = fail.

---

## How it runs

```
Stage 0  Lock       contracts/stubs/CI/seed/golden-demo smoke   ← human: review contracts
Stage 1  MVP        unattended sprint, automated gate only       ← no human
Stage 2  Integrate  verifiers on, integration + smoke e2e        ← human: one demo walkthrough
Stage 3  Harden     red team, AC coverage 100%, debt burn-down   ← human: triage P0/P1 only
Stage 4  Release    fresh-clone verify, acceptance report        ← human: sign-off
```

The planner advances `stage:` in `state/WHITEBOARD.md` only when the stage's exit gate
in `STAGES.md` passes, then tags git `stage-N-complete`. Full check matrix: `STAGES.md`.

Mapping to Claude Code: planner = your main session (or a Workflow script); workers =
subagents, one git worktree each; verifiers = *fresh* subagents given only ticket + diff
+ evidence; red team = fresh subagent at Stage 3. Strongest model for planner / verifier /
red team; a faster model is fine for workers on well-specified tickets.

---

## Layout

| Path | What it is | Who edits it |
|---|---|---|
| `SPEC.md` | What we're building: vision, non-goals, features → `AC-xx.yy`, golden demo, risk list | **You** (Stage 0), then ADR only |
| `ARCHITECTURE.md` | Stack adapter, boundaries, reusable layer, contracts, external services | **You** (Stage 0), then ADR only |
| `STAGES.md` | The rigor dial — checks per stage, exit gates, invariants | Template |
| `PROTOCOL.md` | Roles, visibility, ticket lifecycle, state, evidence, failure handling, red team, final acceptance | Template |
| `CLAUDE.md` | Loaded by every agent: invariants + **active** lessons (generated) | `scripts/gen-claude-md.sh` |
| `prompts/*.md` | Role prompts: planner, worker, verifier, red-team | Template |
| `tickets/` | One file per unit of work (`TEMPLATE.md`, `T-000` scaffold ticket) | Planner creates |
| `state/WHITEBOARD.md` | Planner's compact live state — first thing any agent reads | Planner |
| `state/DECISIONS.md` | Append-only ADR log | Planner / human |
| `state/LESSONS.md` | Append-only lesson record (L/P/M/B series) | Planner |
| `state/DEBT.md` | Declared shortcuts with owning ticket | Workers append, planner burns down |
| `state/LEDGER.md` | One line per ticket state transition — the audit trail | Scripts + verifier |
| `state/evidence/<T>/attempt-N/` | `verify.json`, `verify.log`, diff, notes, verdict — every attempt, incl. failures | `verify.sh` + verifier |
| `scripts/verify.sh` | THE gate | Template + stack adapter lines |
| `scripts/checks/*` | Anti-gaming + audit checks | Template |

## Invariants (never relax, any stage)

1. Contracts change only via an ADR in `state/DECISIONS.md`.
2. Tests are never weakened to pass. Flaky → quarantine + ticket, never retried into green.
3. Debt is declared in `state/DEBT.md`, never hidden.
4. `state/WHITEBOARD.md` is maintained.
5. Audit files (`LESSONS`, `DECISIONS`, `DEBT`, `LEDGER`, `evidence/`) are append-only — enforced by `scripts/checks/audit-append-only.sh`.
6. Only a Verifier moves a ticket to `done`.

## What the gate catches (tested)

`verify.sh` fails on: a skipped/focused test · a test file with no assertions · a drop in
test count without an ADR · growth in `eslint-disable` / `@ts-ignore` / `as any` without an
ADR · an undeclared `TODO`/`FIXME` · any edit to a prior line of an audit file · a deleted
evidence file · a loosened `verify.sh` or lint/ts/test config · a dirty tree under `--fresh`
· uncovered ACs at Stage 3+ · open debt at Stage 4.

## Daily commands

```bash
STAGE=1 TICKET=T-012 plan/scripts/verify.sh            # worker, before submitting
STAGE=2 TICKET=T-012 plan/scripts/verify.sh --fresh    # verifier, always --fresh, on a committed branch
plan/scripts/ac-coverage.sh [--strict]                 # AC → test traceability
plan/scripts/new-ticket.sh T-013 "Short title" [stage] # planner
plan/scripts/gen-claude-md.sh                          # after appending to LESSONS.md
plan/scripts/checks/config-hash.sh --init              # after an ADR-approved change to the gate
```

## Requirements

bash ≥ 3.2 (macOS default is fine), git, node (JSON report parsing), your stack's toolchain.

## Updating the template itself

Improvements earned on a project (new checks, better prompts, lessons that generalize)
belong back here. Open a PR against this repo; project-specific lessons stay in the project.
