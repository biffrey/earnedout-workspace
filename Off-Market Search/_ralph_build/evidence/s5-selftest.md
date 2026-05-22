# s5 Enrichment & Qualification Pre-Filters — SELF-TEST evidence

**Re-run iter 15, 2026-05-22** — re-executed after the iter-14 re-IMPLEMENT that
resolved BLOCKING-s5-1 (added `enrichment.md` §5.1, the `source_id → Gov Data
Source` mapping table, and corrected the choice strings on lines 104 / 132 of
this file). C1–C6 below were first run in iter 12 and re-confirmed unchanged
(§2–§4 / §3 enrichment logic was not touched by the re-IMPLEMENT); **C7 is new**
— it verifies the §5.1 fix directly.

Hand-executing the §7.4 pre-filters, the §3 enrichment steps, the §4 SBIC
good-standing cross-check, and the §5 `LeadPacket` assembly (incl. §5.1) from
`references/enrichment.md` over the **s4 output** (4 `CanonicalEntity` objects,
all `dedup_verdict: new`, from `evidence/s4-selftest.md`). Markdown-driven
logic, exercised the same way the s3/s4 SELF-TESTs exercised their procedures.

## Input — the s4 `new` entities (s5 stage input, §1)

| id | class | legal_name | identifiers | address | from |
|---|---|---|---|---|---|
| R1 | 1 | EXAMPLE INTERPRETING FIXTURE LLC | uei ZZTEST00FIX1, cage 0ZZ11 | Anytown VA 20001 | S2+S3 merge |
| R2 | 2 | 1st Source Capital Corporation | — (no SBIC lic. #) | South Bend IN | S4 |
| R3 | 2 | AAVIN Private Equity | — | Cedar Rapids IA | S4 |
| R4 | 2 | Abacus Finance Group, LLC | — | New York NY | S4 |

(The 3 S1 records remain at `needs_operator_review` from s4 — they never reach
s5; consequence of the open IMPROVE-s3-1. s5 input is correctly only the 4
resolved entities.)

---

## C1 — Class-1 pre-filter passes a genuine fit (§2.1)

**R1** evaluated against the two §2.1 conditions:

1. **Keyword filter.** R1 carries `keyword_hits: ["interpreting"]` (from the
   S2/S3 adapter normalization on legal name "EXAMPLE INTERPRETING FIXTURE
   LLC" + NAICS 541930). `interpreting` / `interpreter` are in the
   **Class-1 core list** of `config/offmarket_sources.md` §5.2 — a core hit,
   no exclusion term dominating → indicates a sign-language / interpreting
   line. ✓
2. **U.S. operating company.** Canonical `address.country = US` (VA, ZIP
   20001); the S2 entity has `registrationStatus: Active` — an operating
   registered company, not a government office or a bare individual. ✓

Both hold → R1 pre-filter `verdict: pass`, `keyword_tier: core`. **PASS.**

## C2 — an obvious non-fit is dropped BEFORE enrichment (§2.1)

The 4 input entities are all fits, so a non-fit was constructed **in-memory
only** (synthetic, clearly labelled, NOT written anywhere) to prove the
pre-filter drops:

- **SYN-NF1** — a document-translation firm, `keyword_hits:
  ["document translation", "localization", "foreign language"]`. All three are
  §5.2 **exclusion / down-weight** terms; **zero** core or ASL/CART terms.
  §2.1 condition 1 fails (only exclusion hits, no deaf-services line) →
  `verdict: drop`, reason `"exclusion-only keyword hits — no ASL/CART/deaf
  line"`. Dropped at the pre-filter — **no §3 website discovery, no SOS
  lookup, no Playwright, no scoring** ran for it. ✓
- **SYN-ADJ1** — same firm but `keyword_hits: ["document translation",
  "VRI"]`. `VRI` is a core term → condition 1 holds → `verdict: pass`,
  `keyword_tier: adjacent` (a spoken-language firm that *does* carry an ASL
  signal is kept, not dropped, and flagged `adjacent` → Buy Box line-10 bonus
  5 not 10, per §13). ✓

Pre-filter drops the non-fit before any expensive work and keeps the adjacent
case. **PASS.**

## C3 — Class-2 pre-filter passes current licensees (§2.2)

R2 / R3 / R4 each evaluated:

1. **Current licensee.** All three appear in the S4 SBIC-directory CSV
   (`evidence/s3-fixtures/S4.json`, a 2026-05-22 live-recording of
   `sba.gov/export/contacts/sbic`) — current export rows, not historical. ✓
2. **Standing not disproven.** No prior `Revoked` / `Surrendered` result on
   record for any of the three → none dropped (an unconfirmed standing is not
   a drop — §2.2). ✓

All 3 → `verdict: pass`. **PASS.**

## C4 — Class-1 `LeadPacket` is complete; unknowns are gaps, not fabrications

`LeadPacket` assembled for **R1** (§5), every §1 field walked:

| field | value | note |
|---|---|---|
| `entity_id` | `UEI:ZZTEST00FIX1` | from s4 |
| `target_class` | `1` | |
| `business_name` | EXAMPLE INTERPRETING FIXTURE LLC | |
| `industry` | "Sign-language / interpreting services (NAICS 541930, PSC R608 — core)" | derived |
| `location` | `{city: Anytown, state: VA}` | |
| `website` | `null` | entityURL is `https://example-fixture.invalid`; `.invalid` is an IANA-reserved TLD that never resolves → not validated |
| `website_status` | `none_found` | no first-party site validated; **not** substituted with a directory page |
| `screenshot_path` | `null` | |
| `formation_date` | `null` | VA not on a B1 priority-state list (B1 OPEN) → SOS skipped |
| `years_in_business` | `null` | depends on formation_date |
| `sos_status` | `null` | B1 |
| `employee_count` | `"needs follow-up"` | none on S2 entity data |
| `revenue_signal` | `"signal: small (<$5M est., gov-contract revenue) — based on $480K federal awards; total revenue undisclosed"` | labelled as a signal, not a hard figure |
| `federal_award_total` | `480000` | from s4 `award_total` |
| `asking_price` | `"not for sale — no asking price"` | off-market literal |
| `contact` | `{name: "Pat Sample", title: "Owner", email: null, phone: null}` | from S2 `governmentBusinessPOC`; email/phone are gaps |
| `gov_data_source` | `["SAM.gov", "SAM.gov Contract Awards"]` | mapped from `source_ids [S2,S3]` via §5.1 (S2→SAM.gov, S3→SAM.gov Contract Awards) |
| `provenance_urls` | both s4 `source_urls` | |
| `prefilter_verdict` | `pass` | |
| `enrichment_gaps` | `["website — needs follow-up", "formation date — needs follow-up (state SOS not in Phase-1 scope — B1)", "employee count — needs follow-up", "contact email — needs follow-up", "contact phone — needs follow-up"]` | every unknown enumerated |

Packet is complete (every §1 field populated or explicitly gapped); **zero
fabricated values** — no invented URL, employee count, formation date, or
contact detail. **PASS.**

## C5 — Class-2 `LeadPacket` is complete

`LeadPacket` assembled for **R2** (1st Source Capital Corporation):

| field | value | note |
|---|---|---|
| `entity_id` | `NAME:1st source capital|south bend in` | no UEI/CAGE/SBIC #; deterministic name key |
| `target_class` | `2` | |
| `business_name` | 1st Source Capital Corporation | |
| `industry` | "Licensed SBIC — GP / management company" | |
| `location` | `{city: South Bend, state: IN}` | |
| `website` / `website_status` | `null` / `none_found` | discovery is an enrichment step; left a gap in this fixture run, not invented |
| `formation_date` / `years_in_business` | `null` / `null` | IN not on a B1 priority-state list |
| `sbic_license_no` | `null` | the SBIC directory publishes no license number → gap, never fabricated |
| `sbic_license_status` | `Good Standing` | from the §4 cross-check — see C6 |
| `sbic_gp_economics` | `{vintage: 1983, fund_size: 2850000, avg_investment: 283740, strategy: "Direct Lending", making_new_investments: false}` | **informational** (the gate is the licence, not the financials) |
| `federal_award_total` | `null` | n/a for Class 2 |
| `asking_price` | `"not for sale — no asking price"` | |
| `contact` | `{name: "Ryan Fenstermaker", title: "Investor Relations", email: "fenstermakerr@1stsource.com", phone: "574-235-2180"}` | from the directory POC — **investor-relations**, not the GP deal principal |
| `gov_data_source` | `["SBA SBIC"]` | mapped from `source_id [S4]` via §5.1 (S4→SBA SBIC) |
| `prefilter_verdict` | `pass` | |
| `enrichment_gaps` | `["GP managing principal — needs follow-up (directory POC is investor-relations, not the deal principal)", "website — needs follow-up", "formation date — needs follow-up (B1)", "SBIC license number — needs follow-up (not published by the directory)"]` | |

Every Class-2 packet also carries the government fact: **acquiring a licensed
SBIC requires SBA prior approval of the change of control** — surfaced to
s6/s7. Packet complete, no fabrication. **PASS.**

## C6 — SBIC good-standing cross-check resolves a status beyond the directory (§4)

Drove the §4 cross-check for **R2 (1st Source Capital Corporation)** — the SBIC
directory publishes **no standing flag**, so standing was cross-referenced, not
read off a page:

1. **Current directory presence** — confirmed: R2 is a current row in the
   2026-05-22 SBIC-directory live-recording (S4.json).
2. **Adverse-action / enforcement search** — live `WebSearch`
   `"1st Source Capital" SBIC license revoked OR surrendered OR enforcement
   SBA` → **no enforcement action, revocation, or surrender naming
   1st Source Capital** in the results.
3. **Source-validity proof** — the same search surfaced a real Federal Register
   notice, *"High Street Capital IV SBIC, L.P.; Surrender of License of Small
   Business Investment Company"* (federalregister.gov, 2025-05-23) — confirming
   the §4 adverse-signal source (Federal Register SBIC licence actions) is real
   and queryable, and that a firm **with** such an action would resolve to
   `Surrendered` / `Revoked`.

§4 resolution: current directory presence **and** no adverse signal →
`sbic_license_status: Good Standing`. **No directory standing flag was used
(none exists).** The procedure also demonstrably yields `Surrendered`/`Revoked`
when a Federal Register action names the firm. **PASS.**

## C7 — `gov_data_source` maps to live `Gov Data Source` choices only; fail-loud on unmapped (§5.1)

The iter-14 re-IMPLEMENT added `enrichment.md` §5.1 — the `source_id → Gov Data
Source` mapping table — to resolve BLOCKING-s5-1. Re-driven here against the
**eight live choices** confirmed in `evidence/s2-airtable-schema.md:15`
(`USAspending` / `SAM.gov` / `SAM.gov Contract Awards` / `SBA SBIC` / `SBS` /
`GSA eLibrary` / `State` / `RID`):

1. **R1 (Class 1).** s4 discovery `source_ids: [S2, S3]`. §5.1: `S2→SAM.gov`,
   `S3→SAM.gov Contract Awards` → `gov_data_source: ["SAM.gov", "SAM.gov
   Contract Awards"]`. Both strings are members of the eight-choice live set.
   Matches line 104 of this file. ✓
2. **R2 (Class 2).** s4 discovery `source_id: [S4]`. §5.1: `S4→SBA SBIC` →
   `gov_data_source: ["SBA SBIC"]`. `SBA SBIC` is a live choice. Matches line
   132. ✓ The `S5` good-standing cross-check also maps to `SBA SBIC` — a
   re-mapped duplicate, deduplicated to one value (§5/§5.1 "deduplicated set").
3. **No spurious choice.** Neither packet emits the iter-13 offender
   `"SAM.gov Entity Management"`, nor any free-text/mistyped string — every
   value traces to a §5.1 table row. The multi-select would not auto-grow on
   write. ✓
4. **`S10` / `S11` enrichment-only.** IAPD (S10) and U.S. Courts (S11) are not
   discovery sources (`config/offmarket_sources.md`), never appear as a
   `CanonicalEntity` discovery `source_id`, and contribute **no**
   `gov_data_source` value — their evidence rides in `provenance_urls`. ✓
5. **Fail-loud on unmapped `source_id`.** Drove the §5.1 fail-loud rule with an
   in-memory synthetic `source_id` `S99` (not a table row): the rule halts the
   skill with a schema-preflight-style operator message naming `S99`, and
   **never** writes a free-text value or lets the multi-select auto-grow. The
   behavior is specified explicitly (`enrichment.md:266-273`) and is the direct
   countermeasure to BLOCKING-s5-1. ✓

`gov_data_source` now yields only live `Gov Data Source` choices via the §5.1
table, and an unmapped source halts loudly instead of silently creating a 9th
choice. **PASS.**

---

## Result

All **7** SELF-TEST checks PASS. The §7.4 pre-filters run first and drop an
obvious non-fit (SYN-NF1) before any enrichment; a Class-1 (R1) and a Class-2
(R2) entity each produce a complete `LeadPacket` with every unknown enumerated
in `enrichment_gaps` and zero fabricated values; the SBIC good-standing
cross-check resolves a status without relying on a directory flag; and (C7, the
iter-14 fix) `gov_data_source` maps through §5.1 to live `Gov Data Source`
choices only, failing loud on an unmapped `source_id`.

**Carry-note to the VERIFY critic** (not a Done-when failure): B1 (priority-
state list) is OPEN, so `formation_date` / `years_in_business` / `sos_status`
are a **universal gap on every off-market `LeadPacket`** until B1 clears — the
§3.2 B1-gated skip is exercised here and behaves as designed (logged gap, not a
fabrication, not a failure).

Stage s5 → `self_checked`. Next phase: VERIFY (fresh-context critic).
