---
active: false
iteration: 6
max_iterations: 40
last_iteration_at: 2026-05-21T19:25:00Z
promise_token: OFFMARKET_PRD_VERIFIED
final_audit_passed: true
unresolved_findings: 0
open_blockers: 0
stages:
  s1_foundations:       { status: verified }
  s2_target_classes:    { status: verified }
  s3_sources:           { status: verified }
  s4_entity_resolution: { status: verified }
  s5_qualification:     { status: verified }
  s6_schema:            { status: verified }
  s7_workflow:          { status: verified }
  s8_compliance:        { status: verified }
  s9_assembly:          { status: verified }
---

# Off-Market Target Search PRD — Ralph Loop State

This state machine drives `OFFMARKET_LOOP_PROMPT.md`. The loop advances exactly
one (stage, phase) per iteration and commits. Deliverable:
`Off-Market Search/PRD_OFF_MARKET_SEARCH.md`.

Stage status: `not_started` → `drafted` → `self_checked` → `verified`
(`blocked` if waiting on an external dependency in `BLOCKERS.md`).

Bootstrapped 2026-05-21 — iteration 0, awaiting first run.
