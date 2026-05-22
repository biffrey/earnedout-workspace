# s10 — End-to-End Assembly Dry Run (IMPLEMENT artifact)

iter 28 — 2026-05-22. **s10 IMPLEMENT.** This is the assembled end-to-end
dry run the `OFFMARKET_BUILD_PLAN.md` s10 stage calls for: *"an end-to-end dry
run on a small live (or fixture) sample for both classes."*

s10 adds **no new pipeline logic** — like s9 it only assembles. Where s9's
SELF-TEST verified the *wiring* (the 1→9 type chain, halt-vs-degrade, the
schedule artifacts), this artifact runs the **whole pipeline through to scored
records and a written-out run log** for both target classes, so the s10
SELF-TEST and the FINAL AUDIT have one consolidated end-to-end trace to check.

> **Dry-run, not a live run.** Per `references/orchestration.md` §5: adapters
> read recorded `s3-fixtures/` payloads (and live key-free sources where
> available); the Airtable write is directed at a **test context**, never
> `tblSmNrHROMLm7vOS`. A live weekly run additionally halts at Step 1 (B4 — the
> two off-market `Source` values do not yet exist). No row was written to the
> tracker; nothing was sent.

---

## Sample — small, both classes

| id | class | entity | source of the record | nature |
|---|---|---|---|---|
| R1 | 1 | EXAMPLE INTERPRETING FIXTURE LLC (`UEI:ZZTEST00FIX1`) | `s3-fixtures/S2.json` (SAM.gov Entity Mgmt, B3 fixture) | synthetic build-loop **fixture** — see limitation note below |
| R2 | 2 | 1st Source Capital Corporation, South Bend IN (`NAME:1st source capital\|south bend in`) | live SBA SBIC directory CSV (S4 adapter) | **real** SBA-licensed SBIC |
| SYN-NF1 | 1 | synthetic non-fit | constructed in-memory | exclusion-only keywords — exercises the s5 pre-filter drop |
| SYN-NC1 | 1 | synthetic no-contact | constructed in-memory | exercises the s8 no-contact → no-draft path |

Plus the 3 live S1 USAspending records and the S3 fixture record, carried
through Steps 2–3 to exercise resolution/dedup volume (see Step 3).

---

## Step-by-step end-to-end trace

### Step 1 — schema preflight (`airtable_schema_preflight.md`)
- Live read of base `appOsvuyy5eK43QTx` / `tblSmNrHROMLm7vOS`:
  the five §8.4 fields exist (`Gov Entity ID` `fld7Ook8ZoLAjwFTe`,
  `SBIC License #` `fldogicjVNMCBuyJI`, `SBIC License Status` `fldscFvXPUFYbSg3F`,
  `Gov Data Source` `fldM7KoR2gtfvBVWN`, `Federal Award History $`
  `fldZXrqqoBkIdDWJN`). The `Source` field (`fldiGyXTk6Ybb6J1L`) has only
  `Overnight Search` / `Manual Submission` — the two off-market values are
  **absent**.
- **A live run would HALT here** (fail-loud, B4) with the operator message.
- **This dry run** records the halt condition, then proceeds in dry-run mode
  (writes to a test context) so the rest of the pipeline can be assembled and
  exercised. The honest outcome for a live run is `halted-preflight`.

### Step 2 — source adapters (`source_adapters.md`)
8 raw records, per the s3 SELF-TEST evidence:
- S1 USAspending.gov — **live**, key-free — 3 `RawRecord`s.
- S2 SAM.gov Entity Mgmt — **blocked B3**, fixture `s3-fixtures/S2.json` — 1.
- S3 SAM.gov Contract Awards — **blocked B3**, fixture `s3-fixtures/S3.json` — 1.
- S4 SBA SBIC directory — **live CSV** — 3 `RawRecord`s.
- S8 priority-state portals — **blocked B1**, shell only — 0.
Degrade, not halt: blocked adapters return `AdapterMeta.status: blocked`; the
run continues. **Raw records in: 8.**

### Step 3 — entity resolution & dedup (`entity_resolution.md`)
- 8 raw → **4 canonical `new`** + **3 `needs_operator_review`** + 1 merged.
- The 3 S1 USAspending records carry no UEI/address (IMPROVE-s3-1) → routed to
  `needs_operator_review`, **not fabricated into rows**.
- Dedup against `tblSmNrHROMLm7vOS`: 0 `existing` matches (no off-market row
  has ever been written — B4). On a re-run after B4 clears, R2 would resolve
  `existing` and update in place.
- `new` set passed to Step 4: R1 (Class 1), R2/R3/R4 (Class 2).

### Step 4 — enrichment & pre-filters (`enrichment.md`)
- Pre-filter: **passed 4** (R1 — Class-1 core keyword `interpreting`; R2/R3/R4 —
  current SBIC licensees), **dropped 1** (SYN-NF1, exclusion-only keywords,
  dropped before any expensive enrichment).
- `LeadPacket` built for each pass; every unknown field is a logged
  `enrichment_gaps` entry, never invented.
- Class-2 §4 good-standing cross-check run for R2 (→ `Good Standing`).
  *Per IMPROVE-s5-3, a live run must repeat the cross-check for R3/R4 too — a
  fixture dry run scores R2 as the representative Class-2 lead.*

### Step 5 — scoring (`scoring_integration.md`)
Both candidates scored by the **unmodified `prospect-evaluation` skill**:
- **R1 — Class 1, `rollup_addon`, /110 → 30/110.** Reports on disk:
  `output/reports/uei-zztest00fix1/example-interpreting-fixture-llc-report.md`
  + `.html` + `lead-packet.json`.
- **R2 — Class 2, `sbic`, informational, 30/100; SBIC license gate ✅ PASS.**
  Reports on disk:
  `output/reports/name-1st-source-capital-south-bend-in/1st-source-capital-corporation-report.md`
  + `.html` + `lead-packet.json`.
- "No asking price" handled as "insufficient data — not awarded" in both — no
  crash, no drop. Scorer failures: 0.

### Step 6 — Airtable write (`airtable_write.md`)
- **Dry-run: 0 created / 0 updated.** Writes directed at a test context, not
  `tblSmNrHROMLm7vOS`. The field-by-field §3 mapping was assembled for R1
  (`Source = Off-Market — ASL Bolt-on`) and R2 (`Source = Off-Market — SBIC`),
  `Disposition = Active`, `Listing ID` blank, gov fields populated, no
  fabricated disclosed-figure field — but **not executed** (B4 preflight halt +
  dry-run). A live run after B4 clears performs the create.

### Step 7 — outreach drafting (`outreach_drafting.md`)
- **2 drafts** generated: R1 → OM-1 (Owner Approach), R2 → OM-2 (SBIC GP
  Principal — carries the fixed SBA-prior-approval sentence).
- **1 no-contact skip:** SYN-NC1 → no draft, contact-discovery follow-up logged.
- Both drafts marked `--- OFF-MARKET OUTREACH DRAFT (NOT SENT) ---`. Stored to
  `search_reports/offmarket_outreach_drafts_2026-05-22.md`. The `Notes`-append
  half of §4 storage is B4-degraded (no live row) — designed degradation.

### Step 8 — dashboard badge (`airtable_write.md` §5)
- Dry-run dashboard preview shows the `.chip.offmarket` badge on the 2
  off-market rows; on-market rows unchanged. Not regenerated against the live
  tracker (dry-run).

### Step 9 — run log (`orchestration.md` §3)
- Consolidated run log written to
  `evidence/s10-offmarket_run_log_e2e_dryrun.md` (this assembly's run log).
  Counts are the real Step 2–8 counts above, not estimates.

---

## Result of the assembly

The pipeline runs end-to-end and produces **≥1 scored record per class**:
- **Class 1:** R1 — 30/110 (`rollup_addon`) — report on disk.
- **Class 2:** R2 — 30/100 informational, license gate PASS — report on disk.

No field in either lead packet or report is fabricated — every unknown is a
logged `enrichment_gaps` / "needs follow-up" entry. Nothing was sent. No row
was written to `tblSmNrHROMLm7vOS`.

## Known limitations carried into the s10 SELF-TEST and FINAL AUDIT

1. **B4 (open)** — a live weekly run halts at Step 1; the live Airtable create,
   the live dashboard regenerate, and the `Notes`-append half of outreach
   storage are exercised only as dry-run mappings. They become live once the
   two `Source` values exist. The build cannot reach COMPLETE while B4 is open.
2. **B3 (open)** — S2/S3 SAM.gov adapters ran on recorded fixtures, not the
   live API (no role-assigned key).
3. **B1 (open)** — S8 priority-state portals are shell-only (no priority states
   named); 0 records.
4. **R1 is a synthetic Class-1 fixture, not a real S1-discovered company**
   (IMPROVE-s3-1 / IMPROVE-s4-4 / IMPROVE-s6-2). The USAspending adapter does
   not yet return `uei`, so every real S1 record routes to
   `needs_operator_review` and the genuine real-company Class-1 end-to-end
   score is not yet demonstrated. A real Class-1 ASL/CART score depends on
   IMPROVE-s3-1 closing.

These are honest open items, not faked passes. s10 SELF-TEST exercises this
assembly against the s10 `Done-when`; the FINAL AUDIT weighs items 1–4.

*Built by s10 IMPLEMENT, iter 28. Next phase for s10: SELF-TEST.*
