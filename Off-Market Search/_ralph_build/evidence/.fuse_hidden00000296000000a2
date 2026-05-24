# Off-Market Search — Run Log 2026-05-22

> **SELF-TEST ARTIFACT — dry-run.** Assembled by the s9 SELF-TEST (iter 26) from
> the real counts in the s3–s8 SELF-TEST evidence, to exercise the
> `references/orchestration.md` §3 run-log template. This is **not** a live run:
> no rows were written to `tblSmNrHROMLm7vOS`.
>
> **Iter-77 refresh note (NIT-s9-4).** This run log is frozen at the iter-26
> state it documents. When it was produced, blockers B1/B3/B4 were open; all
> four blockers (B1–B4) were resolved by the operator on 2026-05-22 and
> `open_blockers` is now 0 (`BLOCKERS.md`; `STATE.md`). The "Outcome", "Open
> blockers", "Sources queried" status column, "Airtable writes" and "Follow-ups"
> lines below were refreshed at iter 77 to drop the stale open-blocker
> attribution: the fixture/dry-run usage they describe is correct, but it is
> now governed by the recorded-fixture practice documented in the (since
> RESOLVED) adapter-rebuild findings `IMPROVE-s3-2` / `IMPROVE-s3-3` /
> `IMPROVE-s5-5`, not by any open blocker. The Step 1 preflight now passes —
> the `Source` single-select holds all four choices (confirmed by the iter-38
> s7 live write `recklDY7vHFmKauQD`). Same stale-blocker refresh class as
> `IMPROVE-s10-3` / `NIT-s9-3`. The s9 `Done-when` criteria are all met and
> s9 stays `verified`.
>
> **Iter-80 note (NIT-s9-2).** The "Sources queried" table below lists only the
> discovery adapters exercised by the s3–s8 SELF-TEST fixtures (S1–S4, S8); the
> enrichment-only sources (S5 SBIC good-standing, S9 RID, S10 IAPD, S11 U.S.
> Courts) are not listed because this fixture exercise did not run them. That
> omission is acceptable for a frozen SELF-TEST artifact, but a **live** run
> must list every source attempted — `orchestration.md` §3 was amended at
> iter 80 (NIT-s9-2 resolution) to require this explicitly in the run-log
> template.

- **Run type:** dry-run (fixture mode — `orchestration.md` §5)
- **Started / finished (UTC):** 2026-05-22T10:31:40Z / 2026-05-22T10:33:00Z
- **Outcome:** completed-degraded (dry-run; quota-limited and ToS-gated adapters
  used recorded fixtures — see the iter-77 refresh note)
- **Open blockers affecting this run:** none — B1–B4 are all RESOLVED
  (`open_blockers: 0`). At the iter-26 time of this run B1/B3/B4 were open;
  see the iter-77 refresh note above.

## Sources queried
| Source | Class | Status | Records | Note |
|--------|-------|--------|---------|------|
| S1 USAspending.gov | 1+2 | ok | 3 | live (s3 SELF-TEST C1) |
| S2 SAM.gov Entity Management | 1 | fixture | 1 | fixture `s3-fixtures/S2.json` — recorded fixture; conserves the SAM.gov public ~10/day quota |
| S3 SAM.gov Contract Awards | 1 | fixture | 1 | fixture `s3-fixtures/S3.json` — recorded fixture; shares S2's ~10/day quota |
| S4 SBA SBIC directory | 2 | ok | 3 | live CSV (s3 SELF-TEST C3) |
| S8 priority-state portals | 1+2 | fixture | 0 | recorded fixture `s3-fixtures/S8.json` — per-jurisdiction ToS gate not exercised in this dry run |

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
- **Dry-run — writes directed at a test context, not `tblSmNrHROMLm7vOS`.** The
  Step 1 schema preflight now passes — the `Source` single-select holds all
  four choices including the two off-market values (confirmed by the iter-38
  s7 live write `recklDY7vHFmKauQD`); the iter-26 "B4 preflight halt" no longer
  applies.
- Record URLs: n/a (dry-run)

## Outreach drafts
- Drafts generated: 2 (R1 Class 1 OM-1 / R2 Class 2 OM-2)
- No-contact (no draft, follow-up logged): 1 (SYN-NC1)
- File: search_reports/offmarket_outreach_drafts_2026-05-22.md — NOT SENT

## Dashboard
- output/dashboards/dashboard_2026-05-22.html — off-market badge on 2 rows
  (dry-run preview; not regenerated against the live tracker)

## Follow-ups for the operator
- _B1/B3/B4 follow-ups removed at iter 77 — all four blockers are RESOLVED
  (`BLOCKERS.md`; `open_blockers: 0`). The S2/S3/S8 adapters were rebuilt for
  real (`IMPROVE-s3-2`/`-s3-3`, RESOLVED iters 68–69); the fixture usage above
  is now the recorded-fixture practice, not a blocker._
- 3 needs-operator-review entities (S1 records missing UEI/address) — resolved
  at source: `IMPROVE-s3-1` (RESOLVED iter 55) rewired the S1 adapter to
  populate a real `uei`, so a fresh live run would not reproduce this count.
