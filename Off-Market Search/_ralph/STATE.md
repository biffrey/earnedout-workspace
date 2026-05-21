---
active: true
iteration: 3
max_iterations: 40
last_iteration_at: 2026-05-21T19:10:00Z
promise_token: OFFMARKET_PRD_VERIFIED
final_audit_passed: false
unresolved_findings: 0
open_blockers: 0
stages:
  s1_foundations:       { status: self_checked }
  s2_target_classes:    { status: self_checked }
  s3_sources:           { status: self_checked }
  s4_entity_resolution: { status: self_checked }
  s5_qualification:     { status: self_checked }
  s6_schema:            { status: self_checked }
  s7_workflow:          { status: self_checked }
  s8_compliance:        { status: self_checked }
  s9_assembly:          { status: self_checked }
---

# Off-Market Target Search PRD — Ralph Loop State

This state machine drives `OFFMARKET_LOOP_PROMPT.md`. The loop advances exactly
one (stage, phase) per iteration and commits. Deliverable:
`Off-Market Search/PRD_OFF_MARKET_SEARCH.md`.

Stage status: `not_started` → `drafted` → `self_checked` → `verified`
(`blocked` if waiting on an external dependency in `BLOCKERS.md`).

Bootstrapped 2026-05-21 — iteration 0, awaiting first run.
