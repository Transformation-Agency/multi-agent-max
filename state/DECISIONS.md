# DECISIONS — append-only ADR log
<!-- Never edit or delete prior entries. Supersede by adding a new ADR that references the old one. -->

## ADR-000 — Adopt this plan template
- Date: <<date>>
- Status: accepted
- Context: Multi-agent build needs a single certificate of done, locked contracts, staged rigor, and an append-only audit record.
- Decision: Use plan-template (verify.sh gate, STAGES dial, PROTOCOL roles).
- Consequences: Contracts change only via ADR; only verifier sets done; audit files append-only.
