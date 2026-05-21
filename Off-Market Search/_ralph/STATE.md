---
active: true
iteration: 0
max_iterations: 40
last_iteration_at: null
promise_token: OFFMARKET_PRD_VERIFIED
final_audit_passed: false
unresolved_findings: 0
open_blockers: 0
stages:
  s1_foundations:       { status: not_started }
  s2_target_classes:    { status: not_started }
  s3_sources:           { status: not_started }
  s4_entity_resolution: { status: not_started }
  s5_qualification:     { status: not_started }
  s6_schema:            { status: not_started }
  s7_workflow:          { status: not_started }
  s8_compliance:        { status: not_started }
  s9_assembly:          { status: not_started }
---

# Off-Market Target Search PRD — Ralph Loop State

This state machine drives `OFFMARKET_LOOP_PROMPT.md`. The loop advances exactly
one (stage, phase) per iteration and commits. Deliverable:
`Off-Market Search/PRD_OFF_MARKET_SEARCH.md`.

Stage status: `not_started` → `drafted` → `self_checked` → `verified`
(`blocked` if waiting on an external dependency in `BLOCKERS.md`).

Bootstrapped 2026-05-21 — iteration 0, awaiting first run.
