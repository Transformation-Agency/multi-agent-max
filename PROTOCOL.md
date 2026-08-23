# PROTOCOL — roles, tickets, state, verification, failure handling

## 1. Roles

| Role | Count | Sees | Does | May NOT |
|---|---|---|---|---|
| **Planner** | 1 | WHITEBOARD, DECISIONS, LESSONS (full), DEBT, ticket summaries, verifier reports, SPEC, ARCHITECTURE | Decomposes stages into tickets; orders by dependency; spawns workers/verifiers/red team; writes a lesson after every rejection; runs checkpoints; advances stage; escalates to human | Write implementation code; mark a ticket `done`; edit contracts without an ADR |
| **Worker** | many, parallel | Its ticket, SPEC (relevant ACs), ARCHITECTURE, CLAUDE.md, the contracts it implements | Implements in its own worktree; runs `verify.sh`; writes evidence; declares debt; opens PR | See other workers' output, planner reasoning, or WHITEBOARD history; edit contracts; weaken tests; touch audit files except appending to DEBT.md |
| **Verifier** | 1 per finished ticket, fresh context | Ticket, diff, worker's evidence bundle, SPEC ACs, ARCHITECTURE | Re-runs `verify.sh --fresh` itself; reads the diff at atom level; checks scope and AC mapping; sets `done` or `rejected` with written reason; appends LEDGER line | See the worker's reasoning trace; fix code |
| **Red team** | 1+ at Stage 3 | Whole repo, SPEC (esp. §6 risks), ARCHITECTURE | Tries to break ACs and risk items; writes findings as tickets with severity + repro; writes regression tests | Fix things; mark anything done |
| **Human** | 1 | WHITEBOARD + escalations | Stage 0 contract review; Stage 2 demo; Stage 3 P0/P1 triage; Stage 4 sign-off; taste decisions | — |

**Blindness is deliberate.** Workers don't see each other (no shared wrong assumptions).
Verifiers don't see worker reasoning (no bias toward the same line of thought). A
verifier *always* re-runs the gate; it never trusts the worker's `verify.json`.

## 2. Tickets

The atomic unit of agent work. One file per ticket in `tickets/`, from `tickets/TEMPLATE.md`.

**Sizing rule:** a worker must finish a ticket within one context window (~1–2 h of
agent work). Larger = planner failure → split. Oversized tickets are the main source
of wasted tokens and half-done PRs.

**Lifecycle:** `todo → building → verifying → done | rejected(n) | blocked`

| Transition | Actor | Requires |
|---|---|---|
| todo → building | planner (spawns worker) | deps done; worktree created |
| building → verifying | worker | `verify.sh` green; evidence written; PR open |
| verifying → done | **verifier only** | own `verify.sh --fresh` green; diff reviewed; ACs mapped; LEDGER line |
| verifying → rejected(n) | verifier | written reason in evidence dir; planner writes lesson; back to planner, not same worker |
| building → blocked | worker | budget exceeded or genuine blocker; diagnosis in ticket |
| any → todo | planner | re-scoped; ADR if contract changed |

Every transition appends one line to `state/LEDGER.md` (`scripts/new-ticket.sh`
and the role prompts do this).

**Budgets:** each ticket has a token/time budget (default: 1 context window / 2 h).
Exceeding it → worker stops, writes diagnosis, status `blocked`. Never loop on a
flaky test.

**Merge discipline:** one git worktree per ticket; rebase on main before running
`verify.sh`; squash-merge; never force-push main.

## 3. State & persistence

| File | Nature | Loaded by |
|---|---|---|
| `state/WHITEBOARD.md` | compact, rewritten each planner step: stage, active tickets, blocked, failed approaches (don't retry), next 3 moves | planner; any agent starting cold |
| `state/DECISIONS.md` | append-only ADRs (context → decision → consequences); superseded ones marked, never removed | planner, verifier |
| `state/LESSONS.md` | append-only record: every lesson ever, with status `active`/`retired`; retire = new line | planner (full); `gen-claude-md.sh` generates the view |
| `CLAUDE.md` | invariants + **active** lessons only — the view | every agent |
| `state/DEBT.md` | open shortcuts (id, ticket, what, why, plan) + closed section | workers append; planner burns down |
| `state/LEDGER.md` | one line per ticket transition: `ts · ticket · from→to · actor · commit · evidence path` | auditor |
| `state/evidence/<T>/attempt-N/` | `verify.json`, `verify.log`, `diff.patch`, `notes.md` (what I did / didn't do); verifier's `verdict.md` | verifier, auditor |
| git | squash-merge per ticket; tag each stage gate | — |

**Record vs view.** The record (LESSONS, DECISIONS, DEBT, LEDGER, evidence/) is
never trimmed; `scripts/checks/audit-append-only.sh` fails the gate if a prior line
changes or an evidence file disappears. The view (CLAUDE.md) is curated: the
planner retires lessons that never recur, and regenerates.

**Lessons** use four series (from Miller):
- **L** — tool/stack idioms ("this ORM's transactions don't nest")
- **P** — process ("never mark done on a green build alone")
- **M** — domain/model structure ("tenancy is a WHERE on every query, not middleware")
- **B** — bridging/architecture ("adapter vs. patching the seam")

Each lesson: failure mode → fix → operational rule. Earned from a specific ticket,
never designed in advance.

## 4. Evidence bundle

Stage 1 (minimal): `verify.json` + `diff.patch`.
Stage 2+ (full): add `notes.md` — what was built, ACs claimed (by id), what was
*not* done, debt declared, commands to reproduce; plus screenshots/API logs for
UI/API tickets.

A bundle without a passing `verify.json` is not accepted for verification.

## 5. Verifier checklist

1. `git fetch && git rebase main` on the ticket branch; `STAGE=$S TICKET=$T scripts/verify.sh --fresh`. Red → reject.
2. Diff `verify.json` against the worker's copy (same commit? same checks?).
3. Read the diff at atom level: do the tests actually exercise the claimed ACs, or just pass? Any `as any`, disabled rules, weakened assertions?
4. Scope: anything outside the ticket's "in scope"? Contracts touched without ADR → reject.
5. Debt: TODOs in code ↔ DEBT.md entries.
6. Write `verdict.md` (accept/reject + reasons) into the evidence dir; append LEDGER; set status.

## 6. Failure handling

| Situation | Rule |
|---|---|
| `verify.sh` red in worker | fix; max 3 attempts; then `blocked` with diagnosis. Never weaken a test. |
| Verifier rejects | back to planner; planner writes a lesson; re-scope or re-spawn a *fresh* worker |
| Contract found wrong mid-stage | stop; ADR; re-lock; re-verify dependents one unit at a time |
| Flaky test | quarantine on first flake: tag `@quarantine`, exclude, open ticket. Never retry into green. |
| Failed build | downstream checks are invalid; do not trust cached results (`--fresh`) |
| Red-team finding | becomes a ticket with severity + regression test; originating ticket gets a lesson |
| 2 consecutive rejections on the same ticket | escalate to human |
| Scope/taste decision, build-vs-defer a gap, ambiguity in SPEC | escalate to human; never guess |

## 7. Red-team playbook (Stage 3)

Scope: SPEC §6 risks first and deepest; then generic categories.

For each risk / AC: adversarial inputs (empty, huge, unicode, injection), auth &
tenancy (other user's ids, expired tokens, role escalation), concurrency (double
submit, races), failure injection (DB down, 3rd-party timeout, partial writes),
state (refresh mid-flow, back button, stale cache), money/idempotency if applicable.

Output per finding: `tickets/RT-xx.md` with severity (P0 data loss/security/money,
P1 core flow broken, P2 degraded, P3 cosmetic), repro steps, AC violated, and a
failing regression test. Planner prioritizes; P0/P1 block the Stage 3 gate.

## 8. Planner checkpoint (every 5 tickets, Stages 1–3)

`scripts/verify.sh --fresh` on main → rewrite WHITEBOARD → review DEBT → retire
stale lessons (in the record, via status line) → regenerate CLAUDE.md → commit.

## 9. Final acceptance (Stage 4)

1. Fresh clone into a clean dir; `STAGE=4 scripts/verify.sh --fresh` → green.
2. `scripts/ac-coverage.sh --strict` → 100%; zero skipped/quarantined tests on certified paths.
3. Boundaries check green (reusable layer isolated).
4. Red-team report: no open P0/P1; deferred items listed with rationale.
5. DEBT.md open section empty or every item `deferred-accepted` by human.
6. Write `ACCEPTANCE-REPORT.md`: what was built (by feature/AC), what was deferred, what was left out and why, evidence index, stage tags.
7. Human reads the AC list + report once end-to-end and signs off (statement-faithfulness: do the ACs as written mean what was intended?). Sign-off line appended to LEDGER.
