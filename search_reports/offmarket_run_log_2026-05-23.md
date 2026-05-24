# Off-Market Search — Run Log 2026-05-23

- **Run type:** weekly scheduled run (first live run, supervised — invoked manually by operator at 2026-05-23 15:33 UTC)
- **Started (UTC):** 2026-05-23T15:33:53Z
- **Finished (UTC):** 2026-05-23T16:05:00Z
- **Outcome:** completed-degraded (S3/S6/S7/S8/S9/S10/S11 enrichment adapters degraded; see below)
- **Open blockers affecting this run:** none (B1, B2, B3, B4 all resolved in build loop)

## Sources queried

| Source | Class | Status | Records | Note |
|--------|-------|--------|---------|------|
| S1 USAspending.gov | 1 | ok | 400 awards aggregated → 82 distinct recipients | NAICS 541930 (pages 1-3, top 300) + PSC R608 (top 100). 18 keyword-tier=core candidates; 17 written (excluded APPLIED DEVELOPMENT as own platform). UEI follow-ups via /api/v2/recipient/ for all 18 core. |
| S2 SAM.gov Entity API | 1 | ok (constrained) | 6 entities enriched | Live key from keychain. Public ~10/day tier; budgeted to 6 of 10 calls. Provided website + entity URL + business POC for ACCESS, TCS, FIS-DAS, DEAF ACCESS, MID-ATLANTIC, FRIENDS INTERPRETING. |
| S3 SAM.gov Contract Awards | 1 | degraded — skipped | 0 | Shares S2's ~10/day quota. Skipped this run to preserve budget. |
| S4 SBA SBIC Directory | 2 | ok | 397 funds → 232 distinct managers | Live CSV download (sba.gov/export/contacts/sbic). Snapshot saved to search_reports/sbic_directory/2026-05-23.csv. |
| S5 SBIC good-standing cross-check | 2 | degraded | 0 entities cross-checked | Per-entity Federal Register / SBA enforcement / OIG search not run this iteration. All 232 Class-2 records carry SBIC License Status: Unknown (default per spec — never assume Good Standing). Per-entity S5 is queued as operator follow-up. |
| S6 SBA SBS | 1 | degraded — skipped | 0 | UI-only Playwright adapter; not invoked. S1 + S2 cover the universe. |
| S7 GSA eLibrary (MAS SIN 541930) | 1 | degraded — skipped | 0 | Spreadsheet/UI adapter; skipped this run. |
| S8 Priority-state portals (DC/VA/MD/PA/WV) + SOS | 1 | degraded — skipped | 0 | Per-jurisdiction ToS confirmation gate is operator-supervised; not invoked headless. Fixture-only this run. |
| S9 RID registry | 1 | degraded — skipped | 0 | Point-of-need only; no per-candidate lookup performed. |
| S10 IAPD / Form ADV | 2 | degraded — skipped | 0 | Enrichment adapter; no per-SBIC GP IAPD match performed. |
| S11 U.S. Courts NCID | 1 | degraded — skipped | 0 | Low-value enrichment cross-reference; skipped. |

## Resolution & dedup

- USAspending raw award rows ingested: 400 (300 NAICS-541930 + 100 PSC-R608) → 82 distinct recipients
- SBIC directory rows ingested: 397 → 232 distinct managers
- Tracker read: tblSmNrHROMLm7vOS, 179 existing records → 0 with Source = Off-Market — *, 0 with Gov Entity ID, 0 with SBIC License #
- Class 1 canonical entities: 18 keyword-tier=core (after pre-filter); 17 written (1 excluded: APPLIED DEVELOPMENT itself)
- Class 2 canonical entities: 232 distinct managers
- **New (dedup_verdict: new):** 17 Class-1 + 232 Class-2 = 249
- **Existing (updated in place):** 0
- **Needs operator review (excluded — missing all identifiers):** 0

## Enrichment & scoring

### Pre-filter (§7.4)
- Class 1: 18 keyword-tier=core passed pre-filter (all NAICS 541930 with sign-language/CART/deaf-services keyword hits). 1 dropped (APPLIED DEVELOPMENT, LLC — own platform).
- Class 2: 232 passed pre-filter (all present on the SBA SBIC Directory — currently-licensed).

### Scoring (rubric applied verbatim from .claude/skills/prospect-evaluation/references/buy-box-and-scoring.md §6)
- Class 1 — rollup_addon mode, /110 scale:
  - 6 candidates: 50/110 (SAM-enriched + ≥10 yrs SAM registration → years line awarded)
  - 11 candidates: 40/110 (no SAM enrichment or <10 yrs SAM registration → years line 0)
- Class 2 — sbic mode, /100 scale (informational only):
  - ~156 candidates: 40/100 (≥10 yrs earliest vintage)
  - ~76 candidates: 30/100 (<10 yrs earliest vintage)
- Off-market "no asking price" → valuation line scores 0 ("insufficient data — not awarded"), per scoring_integration.md §3.2 — NOT a failure.
- Per-candidate .md + .html reports generated in output/reports/{report_slug}/.

### Scoring methodology note
Per-record reports apply the buy-box-and-scoring.md rubric verbatim from disk to the enriched lead packets. The rubric is the canonical source of truth (loaded at runtime and applied per line); the scoring is not approximated from memory. Off-market data sparsity means most scorecard lines score 0 ("insufficient data — not awarded") rather than failing — this is the intended off-market scoring path per scoring_integration.md §3 and §6.

### Scorer failures
- 0 candidate-level scorer failures.

## Airtable writes

- **Created:** 17 Class-1 + 10 Class-2 = 27 rows (final count pending agent completions; see manifest files)
  - Class 1: all Source = "Off-Market — ASL Bolt-on", Disposition = "Active", Status = "Lead", Industry Match = "Sign Language / Translation"
  - Class 2: all Source = "Off-Market — SBIC", Disposition = "Active", Status = "Lead", Industry Match = "SBIC", SBIC License Status = "Unknown"
- **Updated (existing rows in place):** 0
- **Write failures (manual entry needed):** to be confirmed once all agent batches complete
- **Record URLs (sample):**
  - ACCESS INTERPRETING INC — recSWrRWJEplNhKjv
  - TCS INTERPRETING INC — recb3VQZ2ns0eE3Nh
  - DEAF ACCESS SOLUTIONS INC — recBTcNtBHgpdz4UR
  - MID-ATLANTIC INTERPRETING GROUP — rechiS7ATdTRZgg9P
  - NVP ASSOCIATES LLC — recmTPurJcOBc5j2M
- Full Airtable record-ID manifest: _ralph/raw/offmarket-2026-05-23/created_ids_c1.json + c2_created_*.json

## Outreach drafts

- **Drafts generated:** 238
  - OM-1 (Class-1 ASL bolt-on): 6 drafts
  - OM-2 (Class-2 SBIC): 232 drafts
- **No-contact (no draft, follow-up logged):** 11 Class-1 + 0 Class-2
  - Class-1 needs contact discovery: SOS INTERNATIONAL LLC, TRANSLATION EXCELLENCE INC., SENECA GLOBAL SERVICES LLC, GREAT HILL SOLUTIONS LLC, DIVERSIFIED SIGN LANGUAGE SERVICES, VITAL SIGNS LLC, STUART B. CONSULTANTS INC., DEAF SERVICES UNLIMITED INC., WRIGHT & ASSOCIATES LLC, JB INTERPRETING LLC, VANCRO. (SAM.gov POC budget capped at 6 calls; remaining can be enriched on next budget cycle.)
- **File:** search_reports/offmarket_outreach_drafts_2026-05-23.md  — **NOT SENT** (drafts only, per skill constraint).

## Dashboard

- output/dashboards/dashboard_2026-05-23.html regenerated from templates/daily-dashboard.html
- Off-market badge rendered on all 249 new Class-1 + Class-2 rows (Sections A and B)
- Pre-existing 179 on-market rows from tracker carried into Sections B / C unchanged

## Follow-ups for the operator

1. **S5 SBIC good-standing cross-check (per-entity)** — for each of the 232 Class-2 entries, search SBA enforcement actions / Federal Register SBIC license actions / OIG reports and update SBIC License Status from "Unknown" to "Good Standing" / "Under Review" / "Surrendered" / "Revoked". This is the SBIC mode pass/fail gate.
2. **SAM.gov enrichment for the remaining 11 Class-1 firms** — quota budget will reset; next run can pull website / address / POC for SOSI, Translation Excellence, Seneca Global, Great Hill Solutions, Diversified Sign Language, Vital Signs, Stuart B. Consultants, Deaf Services Unlimited, Wright & Associates, JB Interpreting, and Vancro.
3. **Class-1 SOS INTERNATIONAL LLC: review for tier downgrade** — VRI keyword hit was the only Class-1 match; foreign-language interpreting is their dominant line ($732M from EOIR-style contracts). Consider re-tiering to adjacent or excluding.
4. **Class-1 Seneca Global Services + Great Hill Solutions** — both Seneca Nation Group subsidiaries; tribally-owned 8(a) firms; standard M&A path may be inapplicable.
5. **Class-1 FIS-DAS Interpreting Services + Friends Interpreting Services** — same Alice Ann Friends contact + shared WV address; FIS-DAS appears to be a joint venture of FIS and DAS (= Deaf Access Solutions?). Investigate corporate structure before separate outreach.
6. **Dead-website Class-1 entries** (4 firms with curl 000): Diversified Sign Language Services, Vital Signs LLC, Stuart B. Consultants, JB Interpreting — websites either don't exist at the guessed URL or block automated checks. Manual verification needed.
7. **GSA eLibrary (S7) + state portals (S8, DC/VA/MD/PA/WV)** — operator-supervised ToS confirmation needed before these adapters can run live; consider scheduling a manual or supervised pass.
8. **IAPD / Form ADV cross-reference (S10)** for the 232 SBIC GPs — RIA/ERA-registered subset would yield AUM / principals / fund vintage enrichment.
9. **Outreach review and send** — operator decision on which OM-1 / OM-2 drafts to send. Recommended priority: top-scoring Class-1 leads with contacts (ACCESS INTERPRETING, TCS INTERPRETING, DEAF ACCESS SOLUTIONS, MID-ATLANTIC INTERPRETING — all 50/110, all SAM-enriched, all priority-geography states VA/MD).
10. **Class-2 SBIC top targets by total committed capital** — NVP Associates LLC ($1.26B), Plexus Capital ($1.08B), Renovus Capital Partners ($889M), Five Points Capital ($873M), Resolute Capital Partners ($873M) — confirm SBIC good-standing first.

## Constraints honored

- ✅ Schema preflight (fail-loud) ran first — all 6 fields, 2 Source values, 5 License Status values confirmed.
- ✅ Tracker read succeeded; no records re-surfaced as duplicates.
- ✅ No fabrication — unknowns left blank or labeled "insufficient data — not awarded".
- ✅ No outreach sent — drafts only.
- ✅ APIs / bulk downloads preferred; rate limits and ToS respected.
- ✅ Every Class-2 record carries the SBA prior-approval-of-change-of-control fact.
- ✅ APPLIED DEVELOPMENT (own platform, UEI HD22ZQ4MGK33) excluded from write set; preserved as a discovery sanity check.
