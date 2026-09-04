# ARCHITECTURE — <<PROJECT NAME>>

> Fill essentials for the first flow at Stage 0; mark future sections planned.
> Subsequent shared-contract/design changes use an ADR in
> `state/DECISIONS.md`. Contracts live as *code* in the repo; this file points to them.

## 1. Stack adapter

Commands below are targets to wire alongside features, not Stage 0 prerequisites.
Core checks are due at the first Stage 1 milestone; see STAGES.md for later checks.

> The ONLY stack-specific part of the whole package. `scripts/verify.sh` mirrors
> these commands in its `# STACK ADAPTER` block — keep them in sync.

| Concern | Choice | Command |
|---|---|---|
| Language / runtime | <<TypeScript / Node 24>> | |
| Framework | <<Next.js App Router>> | |
| Package manager | <<pnpm>> | `pnpm i --frozen-lockfile` |
| Typecheck | <<tsc>> | `pnpm tsc --noEmit` |
| Lint (bug rules only until Stage 3) | <<eslint>> | `pnpm lint --max-warnings 0` |
| Format (auto, never a gate) | <<prettier>> | `pnpm format` |
| Unit tests | <<vitest>> | `pnpm test:unit` |
| Integration tests | <<vitest + testcontainers>> | `pnpm test:integration` |
| E2E / smoke | <<playwright>> | `pnpm test:e2e --grep @smoke` / `pnpm test:e2e` |
| Build | | `pnpm build` |
| DB + migrations | <<Postgres / drizzle>> | `pnpm db:migrate` |
| Seed fixtures | | `pnpm db:seed` |
| Dependency boundaries | <<dependency-cruiser>> | `pnpm depcruise src` |
| Security | <<pnpm audit, gitleaks>> | |
| Hosting / deploy | <<Vercel>> | |

Test naming convention for AC traceability: include the AC id in the test title,
e.g. `it("[AC-02.03] rejects access to another tenant's project", ...)`.
`scripts/ac-coverage.sh` greps test reports for `AC-\d+\.\d+`.

## 2. System overview

<<One paragraph + a simple diagram (ascii or mermaid) of the major pieces and how
data flows between them.>>

```
<<client>> → <<api/server actions>> → <<service layer>> → <<db>>
                                   ↘ <<external services>>
```

## 3. Module boundaries

> Workers must not cross these. `scripts/checks/boundaries.sh` enforces the
> reusable-layer rule from Stage 2.

| Module / dir | Responsibility | May import from | Must NOT import from |
|---|---|---|---|
| `src/core/` | <<pure domain logic, no I/O>> | nothing app-specific | `src/app`, `src/db`, `src/ui` |
| `src/db/` | <<schema, migrations, repositories>> | `src/core` | `src/app`, `src/ui` |
| `src/services/` | <<use-cases, orchestrates db + external>> | `src/core`, `src/db`, `src/integrations` | `src/ui` |
| `src/app/` | <<routes / pages / server actions>> | `src/services`, `src/ui` | `src/db` directly |
| `src/ui/` | <<components>> | `src/core` types | `src/db`, `src/services` |
| `src/integrations/` | <<3rd-party adapters>> | `src/core` | everything else |

### Reusable layer
> The subset that must stay independent of this app — the "self-contained layer."
> Zero reverse edges into app code; could be lifted into another project as-is.

- `<<src/core/>>`
- `<<src/integrations/<x>/>>`

## 4. Shared contracts (define when needed)

> Define interfaces needed by the first assignments at Stage 0. Other interfaces
> remain planned until their features need them; no full stub scaffold is required.
> Changes to agreements already consumed by Workers require an ADR and affected checks.

| Contract | Location | Format |
|---|---|---|
| Domain types | `<<src/core/types.ts>>` | TS types / zod |
| DB schema | `<<src/db/schema.ts>> + migrations/` | drizzle |
| API surface | `<<src/app/api/**>> or openapi.yaml` | OpenAPI / route handlers |
| Auth model | `<<src/core/auth.ts>>` | roles, permissions, tenancy rule |
| Env schema | `<<src/env.ts>>` | zod, validated at boot |
| Event / job names | `<<src/core/events.ts>>` | |

## 5. Data model

<<Entities, key fields, relationships. Keep it to what's needed; link to schema file.>>

## 6. External services

> Decide mock vs sandbox vs real *per service* now. Workers stall at Stage 2 if
> credentials aren't available.

| Service | Used for | Stage 1 | Stage 2–3 | Stage 4 | Credentials owner |
|---|---|---|---|---|---|
| <<Stripe>> | <<billing>> | mock adapter | test-mode keys | test-mode keys | <<you>> |
| <<Resend>> | <<email>> | mock | sandbox | sandbox | |

## 7. Environments & config

- Local: <<docker compose for db>>
- CI: <<introduce at Stage 2, or name a release-owned deferral; required by release>>
- Verification: ticket = explicit focused command; milestone = combined feature checks;
  release = clean checkout + --fresh. Preserve caches during normal development.
- First milestone: <<M-001 scope + T-001 verification setup owner>>
- Preview / prod: <<...>>
- Secrets: never in repo; env schema validated at boot (`AC` for this if relevant).

## 8. Non-functional design

- Error handling convention: <<typed errors from services; app layer maps to HTTP>>
- Logging / observability: <<...>>
- Performance budgets (only if SPEC §7 requires): <<...>>

## 9. ADR index

> Append-only log lives in `state/DECISIONS.md`; this is just the pointer list.

| ADR | Title | Status |
|---|---|---|
| ADR-000 | Adopt this plan template | accepted |
