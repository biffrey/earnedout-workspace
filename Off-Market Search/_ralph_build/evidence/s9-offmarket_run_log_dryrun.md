# Off-Market Search — Run Log 2026-05-22

> **SELF-TEST ARTIFACT — dry-run.** Assembled by the s9 SELF-TEST (iter 26) from
> the real counts in the s3–s8 SELF-TEST evidence, to exercise the
> `references/orchestration.md` §3 run-log template. This is **not** a live run:
> no rows were written to `tblSmNrHROMLm7vOS`.

- **Run type:** dry-run (fixture mode — `orchestration.md` §5)
- **Started / finished (UTC):** 2026-05-22T10:31:40Z / 2026-05-22T10:33:00Z
- **Outcome:** completed-degraded (dry-run; blocked adapters used fixtures)
- **Open blockers affecting this run:** B1 (state portals), B3 (SAM.gov tier),
  B4 (off-market `Source` values — a live run would halt at Step 1 preflight)

## Sources queried
| Source | Class | Status | Records | Note |
|--------|-------|--------|---------|------|
| S1 USAspending.gov | 1+2 | ok | 3 | live (s3 SELF-TEST C1) |
| S2 SAM.gov Entity Management | 1 | blocked (B3) | 1 | fixture `s3-fixtures/S2.json` |
| S3 SAM.gov Contract Awards | 1 | blocked (B3) | 1 | fixture `s3-fixtures/S3.json` |
| S4 SBA SBIC directory | 2 | ok | 3 | live CSV (s3 SELF-TEST C3) |
| S8 priority-state portals | 1+2 | blocked (B1) | 0 | shell only — no priority states named |

## Resolution & dedup
- Raw records in: 8  →  canonical entities: 7 (4 resolved + 3 thin)
- New: 4   Existing (updated in place): 0   Needs operator review: 3
- Needs-review: the 3 S1 records carry no UEI/address (IMPROVE-s3-1) → routed
  to operator review, not fabricated into rows.

## Enrichment & scoring
- Pre-filter: passed 4 (R1 Class 1 — core keyword `interpreting`; R2/R3/R4
  Class 2 — current SBIC licensees), dropped 1 (synthetic SYN-NF1,
  exclusion-only keywords, dropped before enrichment).
- Scored: Class 1 (rollup_addon /110): R1 = 30/110. Class 2 (sbic,
  informational): R2 = 30/100, SBIC license gate ✅ PASS.
- Scorer failures: 0.

## Airtable writes
- Created: 0 rows   Updated: 0 rows   Write failures: 0
- **Dry-run — writes directed at a test context, not `tblSmNrHROMLm7vOS`.** A
  live run is additionally B4-blocked (Step 1 preflight halt).
- Record URLs: n/a (dry-run)

## Outreach drafts
- Drafts generated: 2 (R1 Class 1 OM-1 / R2 Class 2 OM-2)
- No-contact (no draft, follow-up logged): 1 (SYN-NC1)
- File: search_reports/offmarket_outreach_drafts_2026-05-22.md — NOT SENT

## Dashboard
- output/dashboards/dashboard_2026-05-22.html — off-market badge on 2 rows
  (dry-run preview; not regenerated against the live tracker)

## Follow-ups for the operator
- B4 — add the two off-market `Source` values so a live run can pass preflight.
- B3 — assign a SAM.gov role + Public API Key to lift S2/S3 off fixture mode.
- B1 — name the Phase-1 priority states to activate the S8 state adapter.
- 3 needs-operator-review entities (S1 records missing UEI/address —
  IMPROVE-s3-1).
