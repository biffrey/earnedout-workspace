---
active: true
iteration: 60
max_iterations: 120
last_iteration_at: 2026-05-22T00:00:00Z
promise_token: OFFMARKET_BUILD_VERIFIED
final_audit_passed: true
unresolved_findings: 22
open_blockers: 0
stages:
  s1_foundations:       { status: verified }
  s2_airtable_schema:   { status: verified }
  s3_source_adapters:   { status: verified }
  s4_entity_resolution: { status: verified }
  s5_enrichment:        { status: verified }
  s6_scoring:           { status: verified }
  s7_airtable_write:    { status: verified }
  s8_outreach:          { status: verified }
  s9_orchestration:     { status: verified }
  s10_assembly_audit:   { status: verified }
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

## Operator intervention — 2026-05-22 (between iter 31 and the next run)

The loop stopped at iter 31 on a session limit, not a build error. While the
loop was paused the operator resolved B1, B2 and B4 and is actioning B3:

- **B1 RESOLVED** — Phase-1 priority jurisdictions are DC, VA, MD, PA, WV. The
  state pieces of s3 and s5 were verified earlier as fixture-shells, so the
  real build is now tracked as `IMPROVE-s3-2` and `IMPROVE-s5-5` in
  `FINDINGS.md` (these must close before COMPLETE).
- **B2 RESOLVED** — all licensed SBIC types in scope (the documented default;
  no build change).
- **B4 RESOLVED** — the two `Source` single-select values were added by hand
  and verified live (byte-for-byte match to spec). `s2` and `s7` are
  un-blocked — reset to `not_started` so the loop re-runs them with the schema
  now complete.
- **B3 RESOLVED** — the SAM.gov Public API Key is stored in the macOS login
  keychain (service `samgov-api-key`, account `off-market-search`); see
  `BLOCKERS.md` B3 for the retrieval command. The S2/S3 SAM adapters were built
  as fixture-shells while B3 was open — building them for real is tracked as
  `IMPROVE-s3-3` in `FINDINGS.md`.

`open_blockers` is now 0 — all four blockers are resolved. `unresolved_findings`
is 27: `IMPROVE-s3-2`, `IMPROVE-s5-5` and `IMPROVE-s3-3` were added for the
state-source and SAM-adapter rebuilds the resolved blockers now require. The
loop can be restarted — it will re-run s2 and s7 (schema now complete), finish
s10, run the final audit, then clear findings in the RESOLVE phase before
COMPLETE. `max_iterations` was raised 80 → 120 (and the runner's `MAX_RUNS`
backstop to match) to give the three adapter-rebuild findings room to finish
within budget. These edits were made by hand and are not a loop iteration —
`iteration` and `last_iteration_at` are unchanged from iter 31.
