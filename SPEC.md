# SPEC — <<PROJECT NAME>>

> Fill every `<<...>>`. Delete guidance blockquotes when done. This file is the
> source of truth for *what* gets built. After Stage 0 it changes only via an ADR.

## 1. Vision (one paragraph)

<<Who is this for, what problem does it solve, what does "working" look like in
one sentence a user would say.>>

## 2. Non-goals (explicit)

> Agents expand scope when unconstrained. Anything not listed in §4 is out of
> scope by default, but list the tempting ones explicitly.

- <<e.g. No mobile app. No admin dashboard. No i18n.>>
- <<...>>

## 3. Users & core flows

| User type | Primary goal | Key flow |
|---|---|---|
| <<e.g. Owner>> | <<...>> | <<signup → create workspace → invite>> |

## 4. Features and acceptance criteria

> IDs are permanent. Tests reference them by name/tag (`[AC-01.02]`), and
> `scripts/ac-coverage.sh` checks every AC has at least one passing test.
> Each AC must be observable and testable: input → expected output/state.
> Tag each feature with the stage it must be done by. MVP = Stage 1.

### F-01 <<Feature name>>  (stage: 1)
<<One-line description.>>

| ID | Acceptance criterion | Notes |
|---|---|---|
| AC-01.01 | <<Given X, when Y, then Z>> | |
| AC-01.02 | <<...>> | |

### F-02 <<Feature name>>  (stage: 1)

| ID | Acceptance criterion | Notes |
|---|---|---|
| AC-02.01 | <<...>> | |

### F-03 <<Feature name>>  (stage: 2)

| ID | Acceptance criterion | Notes |
|---|---|---|
| AC-03.01 | <<...>> | |

## 5. Golden demo script

> Written in Stage 0. This IS the MVP definition: Stage 1 is done when every line
> works. It is also the spec for the single smoke test that runs from Stage 1 on.

1. <<Open the app → see landing page>>
2. <<Sign up as a new user>>
3. <<Create a <<thing>>>>
4. <<See it in the list>>
5. <<Log out, log in, it's still there>>

## 6. Risk list (what the red team attacks)

> Name the 3–5 things that would actually hurt. Red team goes deep on these, not
> shallow on everything.

| # | Risk | Why it matters | ACs involved |
|---|---|---|---|
| R1 | <<e.g. Cross-tenant data access>> | <<...>> | AC-02.03, AC-05.01 |
| R2 | <<e.g. Payment double-charge>> | | |

## 7. Non-functional requirements

> Only list what you actually need. Each one here becomes a check in verify.sh at Stage 3.

- Performance: <<none | p95 < 300ms on /api/x | bundle < 250kB>>
- Security: <<auth model, data at rest, secrets handling>>
- Availability / failure modes: <<what happens when DB/3rd-party is down>>
- Accessibility: <<none | WCAG AA on core flows>>

## 8. Open questions

> Anything unresolved. Planner must escalate to human rather than guess.

- <<...>>
