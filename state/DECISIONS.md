# DECISIONS — append-only ADR log
<!-- Never edit or delete prior entries. Supersede by adding a new ADR that references the old one. -->

## ADR-000 — Adopt this plan template
- Date: <<date>>
- Status: accepted
- Context: Multi-agent build needs a single certificate of done, locked contracts, staged rigor, and an append-only audit record.
- Decision: Use plan-template (verify.sh gate, STAGES dial, PROTOCOL roles).
- Consequences: Contracts change only via ADR; only verifier sets done; audit files append-only.

## ADR-001 — Progressive verification and smaller Stage 0
- Date: 2026-09-04
- Status: accepted for template implementation by user request
- Context: Repeated clean installs/full gates and upfront CI/testing setup delay first useful behavior.
- Decision: Keep roles, tickets, records, risk review, and stages. Introduce ticket/milestone/release profiles, implemented status, integration ownership, and T-001 setup alongside the first flow. CI can wait until Stage 2 or release. Reserve --fresh for release/diagnosis.
- Consequences: Supersedes ADR-000's single undifferentiated certificate. Only integrated Verifier acceptance marks feature tickets done; missing required milestone checks fail. Stage 0 human acceptance is the infrastructure exception. No existing project history or tests should be discarded during adoption.
