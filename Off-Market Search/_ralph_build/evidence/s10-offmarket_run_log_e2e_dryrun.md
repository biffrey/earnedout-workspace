# Off-Market Search — Run Log 2026-05-22 (s10 end-to-end dry run)

> **s10 IMPLEMENT artifact — dry-run.** The consolidated run log for the s10
> end-to-end assembly (`evidence/s10-e2e-dryrun.md`), produced by Step 9 of the
> assembled pipeline using the `references/orchestration.md` §3 template. This
> is **not** a live run: no rows were written to `tblSmNrHROMLm7vOS`, nothing
> was sent.

- **Run type:** end-to-end dry-run (fixture mode — `orchestration.md` §5)
- **Started / finished (UTC):** 2026-05-22T10:45:00Z / 2026-05-22T10:46:30Z
- **Outcome:** completed-degraded (dry-run; blocked adapters used fixtures; a
  live run would be `halted-preflight` at Step 1 — B4)
- **Open blockers affecting this run:** B1 (state portals), B3 (SAM.gov tier),
  B4 (off-market `Source` values)

## Sources queried
| Source | Class | Status | Records | Note |
|--------|-------|--------|---------|------|
| S1 USAspending.gov | 1+2 | ok | 3 | live, key-free |
| S2 SAM.gov Entity Management | 1 | blocked (B3) | 1 | fixture `s3-fixtures/S2.json` |
| S3 SAM.gov Contract Awards | 1 | blocked (B3) | 1 | fixture `s3-fixtures/S3.json` |
| S4 SBA SBIC directory | 2 | ok | 3 | live CSV export |
| S8 priority-state portals | 1+2 | blocked (B1) | 0 | shell only — no priority states named |

_Enrichment-only sources (S5 good-standing cross-check, S6 SBS, S7 GSA
eLibrary, S9 RID, S10 IAPD, S11 U.S. Courts) are point-of-need; a live run
lists each in this table when invoked (NIT-s9-2)._

## Resolution & dedup
- Raw records in: 8  →  canonical entities: 7 (4 resolved `new` + 3 thin)
- New: 4   Existing (updated in place): 0   Needs operator review: 3
- Needs-review: the 3 S1 USAspending records carry no UEI/address
  (IMPROVE-s3-1) → routed to operator review, not fabricated into rows.

## Enrichment & scoring
- Pre-filter: passed 4 (R1 Class 1 — core keyword `interpreting`; R2/R3/R4
  Class 2 — current SBIC licensees), dropped 1 (synthetic SYN-NF1,
  exclusion-only keywords, dropped before enrichment).
- Scored — Class 1 (`rollup_addon`, /110): R1 = 30/110.
- Scored — Class 2 (`sbic`, informational, /100): R2 = 20/100, SBIC license
  gate ✅ PASS. R3/R4 were carried as Class-2 candidates but not scored in this
  dry run (only R2 was scored as the representative Class-2 lead — IMPROVE-s10-2).
  R2 scored strictly from `lead-packet.json`: formation date is a `null`
  enrichment gap, so years-in-business is "insufficient data — not awarded"
  (BLOCKING-s10-1 fix, iter 31).
- Scorer failures: 0.

## Airtable writes
- Created: 0 rows   Updated: 0 rows   Write failures: 0
- **Dry-run — writes directed at a test context, not `tblSmNrHROMLm7vOS`.** A
  live run is additionally B4-blocked (Step 1 preflight halt).
- Record URLs: n/a (dry-run)

## Outreach drafts
- Drafts generated: 2 (R1 Class 1 OM-1 / R2 Class 2 OM-2)
- No-contact (no draft, follow-up logged): 1 (SYN-NC1)
- File (dry-run / evidence path): `_ralph_build/evidence/s8-offmarket_outreach_drafts_2026-05-22.md` — NOT SENT.
  A live run writes to `search_reports/offmarket_outreach_drafts_<date>.md`;
  this dry run stored the drafts under the s8 evidence path (IMPROVE-s10-1).

## Dashboard
- Dry-run preview — off-market `.chip.offmarket` badge on 2 rows; on-market
  rows unchanged. Not regenerated against the live tracker (dry-run).

## Follow-ups for the operator
- B4 — add the two off-market `Source` values so a live run passes preflight.
- B3 — assign a SAM.gov role + Public API Key to lift S2/S3 off fixture mode.
- B1 — name the Phase-1 priority states to activate the S8 state adapter.
- 3 needs-operator-review entities (S1 records missing UEI/address —
  IMPROVE-s3-1).
- A real-company Class-1 ASL/CART end-to-end score is pending IMPROVE-s3-1
  (USAspending `uei` population) — see `s10-e2e-dryrun.md` limitation 4.
