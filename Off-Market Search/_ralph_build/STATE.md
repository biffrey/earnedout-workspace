---
active: true
iteration: 20
max_iterations: 80
last_iteration_at: 2026-05-22T19:05:00Z
promise_token: OFFMARKET_BUILD_VERIFIED
final_audit_passed: false
unresolved_findings: 19
open_blockers: 4
stages:
  s1_foundations:       { status: verified }
  s2_airtable_schema:   { status: blocked }
  s3_source_adapters:   { status: verified }
  s4_entity_resolution: { status: verified }
  s5_enrichment:        { status: verified }
  s6_scoring:           { status: verified }
  s7_airtable_write:    { status: drafted }
  s8_outreach:          { status: not_started }
  s9_orchestration:     { status: not_started }
  s10_assembly_audit:   { status: not_started }
---

# Off-Market Search — Build Loop State

This state machine drives `OFFMARKET_BUILD_LOOP_PROMPT.md`. The loop advances
exactly one (stage, phase) per iteration and commits. Canonical "what":
`OFFMARKET_BUILD_PLAN.md`.

**Deliverable:** a working `off-market-search` skill (plus manual path, config,
Airtable schema changes, dashboard badge, outreach template) — see the build
plan's "Deliverables" section.

Stage status: `not_started` → `drafted` → `self_checked` → `verified`
(`blocked` if waiting on an external precondition in `BLOCKERS.md`).

Phase ladder per stage: IMPLEMENT → SELF-TEST → VERIFY. After all 10 stages are
`verified`: FINAL AUDIT → RESOLVE → COMPLETE (emit
`<promise>OFFMARKET_BUILD_VERIFIED</promise>`).

**Open blockers at bootstrap (4):** B1 priority-state list, B2 SBIC scope,
B3 SAM.gov account + API key, B4 Airtable schema-write access — see
`BLOCKERS.md`. The loop runs all non-blocked stages and reaches COMPLETE only
when `open_blockers: 0`.

Bootstrapped 2026-05-21 — iteration 0, awaiting first run. Set `active: true`
to start the loop.
