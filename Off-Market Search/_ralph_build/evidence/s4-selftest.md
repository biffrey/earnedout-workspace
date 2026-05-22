# s4 Entity Resolution & De-Duplication — SELF-TEST evidence (iter 9, 2026-05-22)

Hand-executing the §6.1 resolver and §6.2 tracker dedup procedures from
`references/entity_resolution.md` over the s3 fixture record set
(`evidence/s3-fixtures/`) and a live read of the Master Deal Pipeline tracker.
Markdown-driven logic, exercised the same way the s3 SELF-TEST exercised the
adapter mappings.

## Input — combined s3 record set (8 RawRecords)

| # | source | legal_name | uei | cage | sbic_lic | address | class |
|---|---|---|---|---|---|---|---|
| 1 | S1 | THE MISSION ESSENTIAL GROUP, LLC | null | null | null | null | 1 |
| 2 | S1 | WORLDWIDE LANGUAGE RESOURCES, LLC | null | null | null | null | 1 |
| 3 | S1 | SOS INTERNATIONAL LLC | null | null | null | null | 1 |
| 4 | S2 | EXAMPLE INTERPRETING FIXTURE LLC | ZZTEST00FIX1 | 0ZZ11 | null | Anytown VA 20001 | 1 |
| 5 | S3 | EXAMPLE INTERPRETING FIXTURE LLC | ZZTEST00FIX1 | null | null | null | 1 |
| 6 | S4 | 1st Source Capital Corporation | null | null | null | South Bend IN | 2 |
| 7 | S4 | AAVIN Private Equity | null | null | null | Cedar Rapids IA | 2 |
| 8 | S4 | Abacus Finance Group, LLC | null | null | null | New York NY | 2 |

## §6.1 — resolution clusters produced

- **Cluster R1 (UEI key).** Records 4 + 5 share `norm_uei = ZZTEST00FIX1` →
  **merge into ONE `CanonicalEntity`**. `resolution_key = uei`,
  `resolution_confidence = exact`. Merged: `legal_name` "EXAMPLE INTERPRETING
  FIXTURE LLC", `uei ZZTEST00FIX1`, `cage_code 0ZZ11` (from rec 4 only),
  `naics [541930]`, `psc [R608]` (from rec 3-shape), `award_total 480000`,
  `source_ids [S2,S3]`, `source_urls` both. **2 records → 1 entity.** ✓
- **Clusters R2 / R3 / R4 (name+address key).** Records 6, 7, 8 carry no
  shared identifier and no `sbic_license_no`; each has a distinct `norm_name`
  and distinct `norm_addr` (city+state grain) → **3 separate**
  `CanonicalEntity` objects, `resolution_key = name_address`,
  `resolution_confidence = probable`. No false merge across the three. ✓
- **Records 1, 2, 3 (S1).** No UEI / CAGE / DUNS / SBIC license **and** no
  address → §6.1 key ladder produces no match and §5 cannot build an
  `entity_id`. Per §4 "missing all identifiers and address" they are routed to
  **`needs_operator_review`** — not fabricated into a row, not silently
  dropped. Logged for the s9 run log. Correct §4 behavior. ✓
  (Live-run note: this is the on-disk consequence of **IMPROVE-s3-1** — the
  USAspending `spending_by_award` adapter does not yet populate `uei`/address.
  Until that s3 finding is resolved, every S1 record routes here. s4 handles
  the thin input correctly; the fix belongs to s3.)

§6.1 output: **4 `CanonicalEntity`** (R1 + R2 + R3 + R4) + 3
`needs_operator_review`.

### R1 per-field merge trace (merge trace added iter 60, RESOLVE — IMPROVE-s4-3)

Per-field union for the **rec 4 (S2) + rec 5 (S3) → R1** merge asserted in the
cluster bullet above. Each row shows `rec 4 value` ⊕ `rec 5 value` → `merged`,
so every merged R1 value is reproducible from the two contributing records:

| field | rec 4 (S2) | rec 5 (S3) | merged | union step |
|---|---|---|---|---|
| `legal_name` | EXAMPLE INTERPRETING FIXTURE LLC | EXAMPLE INTERPRETING FIXTURE LLC | EXAMPLE INTERPRETING FIXTURE LLC | identical — value kept |
| `uei` | ZZTEST00FIX1 | ZZTEST00FIX1 | ZZTEST00FIX1 | identical — the merge key itself |
| `cage_code` | 0ZZ11 | _(none)_ | 0ZZ11 | scalar — single non-null contributor (rec 4) |
| `naics` | [541930] | [541930] | [541930] | set union, deduped |
| `psc` | _(none)_ | [R608] | [R608] | set union — sole contributor is rec 5 (S3) |
| `award_total` | _(none)_ | 480000 | 480000 | sole contributor rec 5 (S3 `obligatedAmount`) |
| `source_ids` | [S2] | [S3] | [S2, S3] | set union |
| `source_urls` | rec-4 source URL | rec-5 source URL | both | set union |

Each multi-valued field (`naics`, `psc`, `source_ids`, `source_urls`) is a
deduped **set union** of the two records; each scalar (`legal_name`, `uei`,
`cage_code`, `award_total`) takes the single non-null / identical value. No
field is invented. (The cluster bullet's inline `psc … (from rec 3-shape)`
provenance label is a separate cosmetic mis-citation tracked as **NIT-s5-1** —
the correct contributor is rec 5 (S3), as this trace shows.)

## §6.2 — dedup against the live tracker

Live read: Airtable MCP `list_records_for_table` on
`appOsvuyy5eK43QTx` / `tblSmNrHROMLm7vOS` — **167 records**. Indexes built:
gov-id (`Gov Entity ID`), name+address, SBIC license (`SBIC License #`).

- **Key A — gov identifier.** 0 of 167 rows have a non-empty `Gov Entity ID`
  (no off-market records exist yet) → no key-A match for R1–R4.
- **Key B — name+address.** None of the 4 candidate `norm_name`s appears in the
  tracker. Checked specifically against the on-market ASL row
  `recFbcG0NPtQ3toQY` "Leading American Sign Language Training Center"
  (`norm_name` "leading american sign language training center") — no
  collision with "example interpreting fixture" or the three SBIC names.
- **Key C — SBIC license.** 0 of 167 rows have a non-empty `SBIC License #` →
  no key-C match.

Result: **all 4 `CanonicalEntity` → `dedup_verdict: new`** — correct, since the
fixture entities have never been written. No false `existing`.

## §6.2 — `existing` detection (seeded synthetic rows)

To prove keys A/B/C actually fire, three synthetic tracker rows were built
**in-memory only** (NOT written to Airtable — fixtures must not be written to
the production tracker outside a test context) and the dedup indexes rebuilt
to include them:

- **SR-A** `Gov Entity ID = "UEI:ZZTEST00FIX1"` → re-run candidate R1 →
  candidate `uei` equals stored gov id → `dedup_verdict: existing`,
  `dedup_key: A_gov_id`, `tracker_record_id: SR-A`. Routed to s7 as an
  **update**, not a create. ✓
- **SR-B** `Business Name = "Abacus Finance Group LLC"`,
  `Business Address = "New York, NY"` → re-run candidate R4 → `norm_name` equal
  **and** `norm_addr` agrees at city+state grain → `existing`,
  `dedup_key: B_name_address`. ✓
- **SR-C** `SBIC License # = "09/79-0292"` → re-run a synthetic Class-2
  candidate carrying `sbic_license_no = "09/79-0292"` (the S4 directory CSV
  does not publish license numbers, so this candidate is synthetic and so
  labeled) → key C match → `existing`, `dedup_key: C_sbic_license`. ✓

Each `existing` hit takes the update path (refresh `Link Last Checked` /
`Date Updated`, fill blank gov fields, no duplicate row, no `Source` flip).

## §5 — `entity_id` construction check

- R1 has a UEI → `UEI:ZZTEST00FIX1`. ✓
- R2–R4 have no UEI/CAGE/SBIC license → `NAME:<norm_name>|<citystate>` —
  deterministic, hash-free, stable across runs (e.g.
  `NAME:abacus finance group|new york ny`). ✓
- Synthetic SR-C candidate → `SBIC:09/79-0292`. ✓
  All prefixes match §5; the same firm yields the same id on a later run, so
  cross-run dedup key A works for identifier-less firms.

## Accuracy spot-check (§2.2 targets: ≥95% resolution, <5% duplicate)

Sample = the 4 cluster decisions + 4 dedup verdicts produced above.

- **Resolution accuracy.** 1 `exact` UEI merge (R1) — genuinely one entity per
  the fixture design; 3 `probable` name+address singletons (R2–R4) — genuinely
  three distinct firms, no false merge; 3 S1 records correctly **not**
  force-merged. 0 false merges, 0 missed merges → **4/4 cluster decisions
  correct = 100%** on this sample. Meets ≥95%.
- **Duplicate rate.** 4 entities resolved `new`, 0 written as a duplicate of an
  existing tracker row; 3 seeded-row scenarios all caught as `existing`; 0
  false `existing`. → **0% sampled duplicate rate.** Meets <5%.
- **Caveat.** The sample is small and S2/S3 are structural fixtures; s10 must
  repeat the spot-check on a larger live sample once B3 (SAM.gov key) clears.

## Result

All seven SELF-TEST checks PASS (see `TEST_LOG.md` iter 9). Stage s4 →
`self_checked`. Next phase: VERIFY (fresh-context critic).
