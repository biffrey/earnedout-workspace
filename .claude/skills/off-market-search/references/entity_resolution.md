# Off-Market Entity Resolution & De-Duplication

Built by build-loop **stage s4**. This reference defines how the raw records
emitted by the s3 source adapters are collapsed into one canonical entity per
real-world company, and how each canonical entity is checked against the
existing Master Deal Pipeline tracker so a target already on file is **never
re-surfaced as a new lead**.

Implements PRD **§6.1** (resolving the same company across sources) and **§6.2**
(de-duplication against the tracker), with the §13 resolution decisions applied:
DUNS is a legacy bridge key only (§13 item 12 — DUNS retired 2022-04-01); the
dedicated `Gov Entity ID` field is the off-market analogue of `Listing ID`
(§8 ⚠ VERIFY resolved — operator approved a dedicated field).

Companion files:
- `references/source_adapters.md` — produces the `RawRecord` input to this stage.
- `references/airtable_schema_preflight.md` — guarantees `Gov Entity ID` and the
  other §8.4 fields exist before any dedup read/write.

> Markdown-driven, like the adapters: each procedure below is executed at
> runtime by the skill (string normalization, set membership, Airtable MCP
> `search_records` / `list_records_for_table` reads) — not compiled code.

---

## 1. Stage inputs and outputs

**Input:** the combined record set from s3 — every `RawRecord` from every
discovery adapter, plus the enrichment amendments from the enrichment adapters,
with their `AdapterMeta`.

**Output:** a list of **`CanonicalEntity`** objects, each tagged with a
**`dedup_verdict`**. Only entities whose verdict is `new` flow on to s5
enrichment as fresh candidates; `existing` entities carry the matched Airtable
`record_id` so s7 performs an **update**, not a create.

### `CanonicalEntity` — the resolved object

| Field | Type | Notes |
|---|---|---|
| `entity_id` | string | stable off-market ID — see §5; written to `Gov Entity ID` |
| `target_class` | `1` \| `2` | inherited from the constituent records |
| `legal_name` | string | the canonical legal name (longest / most-complete spelling) |
| `all_names` | string[] | every distinct `legal_name` / `dba_name` seen across sources |
| `uei` | string \| null | resolved UEI |
| `cage_code` | string \| null | resolved CAGE |
| `duns` | string \| null | legacy DUNS, bridge only |
| `sbic_license_no` | string \| null | Class-2 key, where any source supplied it |
| `address` | object \| null | canonical `{street, city, state, zip, country}` |
| `naics` / `psc` | string[] | union across sources |
| `award_total` / `award_count` | number \| null | summed across constituent records |
| `socioeconomic_flags` | string[] | union |
| `poc` | object \| null | best public POC found |
| `website` | string \| null | first non-null |
| `keyword_hits` | string[] | union; `keyword_tier` = strongest tier seen (`core` > `adjacent`) |
| `source_ids` | string[] | which adapters (`S1`–`S11`) contributed — provenance |
| `source_urls` | string[] | every provenance URL |
| `constituent_records` | RawRecord[] | the raw records this entity was built from (audit) |
| `resolution_key` | string | which §6.1 key matched — `uei` / `cage` / `duns` / `name_address` |
| `resolution_confidence` | `exact` \| `probable` | `exact` for id keys; `probable` for name+address |
| `dedup_verdict` | `new` \| `existing` | see §3 |
| `tracker_record_id` | string \| null | the matched `tblSmNrHROMLm7vOS` record id when `existing` |
| `dedup_key` | string \| null | which §6.2 key matched — `A_gov_id` / `B_name_address` / `C_sbic_license` |

Unknown fields stay `null` — never invented; s5 converts `null` to "needs
follow-up".

---

## 2. §6.1 — Resolving one company across sources (cross-run dedup)

Goal: the same company found via USAspending **and** the SAM Entity API **and**
GSA eLibrary in one run produces **one** `CanonicalEntity`, not three. Run this
before the tracker dedup in §3.

### 2.0 Normalization helpers (used here and in §3)

- **`norm_name(s)`** — lowercase; strip diacritics; remove punctuation; drop the
  trailing entity suffixes `LLC, L.L.C., Inc, Incorporated, Corp, Corporation,
  Co, Company, LP, LLP, PLLC, Ltd`; collapse `&` → `and`; collapse whitespace.
- **`norm_addr(a)`** — USPS-style: uppercase; standard street abbreviations
  (`STREET→ST`, `AVENUE→AVE`, …); drop suite/unit lines; keep 5-digit ZIP and
  `city + state`. The match grain is **ZIP** (or `city+state` when ZIP is
  absent), never the full street string.
- **`norm_uei(s)`** — uppercase, trim; must be 12 alphanumeric chars or it is
  treated as absent. **`norm_cage(s)`** — uppercase 5-char. **`norm_duns(s)`** —
  9 digits.

### 2.1 Resolution key ladder (priority order — PRD §6.1)

Process records and merge them into resolution clusters using the **first**
key that produces a match, in this order:

1. **UEI** — exact `norm_uei` match ⇒ **same entity** (`resolution_confidence:
   exact`). The government-wide key; present in S1/S2/S3 and post-2022 awards.
2. **CAGE code** — exact `norm_cage` match ⇒ same entity (`exact`). Secondary;
   present in SAM.gov and many award records.
3. **Legacy DUNS** — exact `norm_duns` match ⇒ same entity (`exact`), used
   **only as a fallback bridge** for pre-2022 award rows that predate UEI
   (§13 item 12). Never resolve solely on DUNS when a UEI is available on either
   record — prefer the UEI cluster and attach the DUNS to it.
4. **Normalized name + address** — when no shared identifier exists (e.g. an
   SBS-only firm vs. a USAspending recipient): match when `norm_name` is equal
   **and** `norm_addr` agrees at ZIP (or city+state) grain. This is a
   **`probable`** match, not exact — flag `resolution_confidence: probable` so
   s5/operator review can confirm it. Do **not** merge on name alone.

**Class-2 (SBIC) note:** SBIC directory rows (S4) rarely carry a UEI. Within a
run, also cluster Class-2 records on **`sbic_license_no`** when present
(treated as an exact id key); otherwise fall through to name+address. The
license number is primarily a §3 tracker key (key C).

### 2.2 Merging a cluster into one `CanonicalEntity`

For each resolution cluster:
- `legal_name` = the longest non-empty spelling; `all_names` = the distinct set.
- Identifiers (`uei`/`cage`/`duns`/`sbic_license_no`) = the non-null value;
  if two records disagree on a supposedly-exact id, do **not** merge them —
  keep them separate and add an `IMPROVE` finding for operator review.
- `address` = the most complete record's address (prefer one with a street + ZIP).
- `naics`/`psc`/`socioeconomic_flags`/`keyword_hits` = unions; `keyword_tier` =
  `core` if any constituent is `core`, else `adjacent`, else `null`.
- `award_total`/`award_count` = summed across constituents **after** UEI
  grouping (S1 already groups by UEI; guard against double-counting the same
  award id).
- `poc`/`website` = first non-null, preferring discovery-source values.
- `source_ids`/`source_urls`/`constituent_records` = accumulate all — provenance
  must show every source that contributed.
- `resolution_key` = the highest-priority key that matched.

---

## 3. §6.2 — De-duplication against the existing tracker

After §2 produces the resolved set, check **each** `CanonicalEntity` against
table `tblSmNrHROMLm7vOS` **before** s5/s7 — consistent with the on-market dedup
in `REVAMP_PLAN.md` Step 2e and the `overnight-search` skill Step 5. This
protects the §2.2 **<5% duplicate-rate** metric.

Read the tracker once per run (Airtable MCP `list_records_for_table`, fields:
`Gov Entity ID`, `Business Name`, `Business Address`, `SBIC License #`,
`Source`, `Disposition`, `Link Last Checked`, `Date Updated`, `Notes`) and build
three in-memory lookup indexes — gov-id, normalized name+address, SBIC license.

### Match keys (any one match ⇒ `existing`)

- **Key A — government identifier.** Candidate `uei` **or** `cage_code` equals a
  stored `Gov Entity ID` ⇒ existing record. (`Gov Entity ID` stores the
  resolved id — see §5.) Exact match.
- **Key B — name + address.** `norm_name(candidate.legal_name)` ∈
  `{norm_name(all_names)}` equals `norm_name(Business Name)` **and**
  `norm_addr` agrees at ZIP / city+state grain ⇒ existing record. This is the
  existing on-market dedup logic — it also catches an off-market target that
  was previously entered on-market.
- **Key C — SBIC license number (Class 2 only).** Candidate `sbic_license_no`
  equals a stored `SBIC License #` ⇒ existing record.

Evaluate A → C in order; the first hit sets `dedup_verdict: existing`,
`dedup_key`, and `tracker_record_id`. No hit ⇒ `dedup_verdict: new`.

### On an `existing` match — update, never duplicate

Do **not** create a second row. Hand the entity to s7 as an **update**:
- refresh `Link Last Checked` / `Date Updated`;
- fill any now-available gov field that was previously blank (`Gov Entity ID`,
  `SBIC License #`, `SBIC License Status`, `Gov Data Source`,
  `Federal Award History $`) — fill blanks, do not overwrite operator-entered
  values;
- if the existing row was sourced **on-market** and the off-market run found
  materially new info, **append a dated note** to `Notes` rather than
  overwriting — and do **not** change its `Source`;
- never flip an existing row to look like a new lead.

### Cross-run dedup within off-market itself

§2 already collapses one run's multi-source records. Additionally, before s7
writes a `new` entity, re-check key A/B/C against the tracker — a prior weekly
off-market run will have written the entity, so a target seen last week resolves
to `existing` this week. (No separate state file is needed: the tracker itself
is the cross-run memory, since every off-market entity is written there.)

---

## 4. Failure & edge handling

- **Missing all identifiers and address** — cannot be safely resolved or
  deduped. Do not drop silently and do not guess: mark the entity
  `needs_operator_review` in the run log and exclude it from the write; it is
  reported in the s9 run log, not fabricated into a row.
- **Conflicting exact ids** (two records, same UEI, irreconcilable names; or one
  name+ZIP, two UEIs) — keep separate, emit an `IMPROVE` finding, let operator
  review decide. Never auto-merge across an id conflict.
- **Tracker read fails / MCP unavailable** — dedup cannot be guaranteed, so the
  run must **not** write (writing blind risks duplicates). Halt the write step
  with a clear operator message and log it — consistent with "fail loud".
- **`probable` (name+address) resolution or dedup** — flagged, not blocked; it
  proceeds but is surfaced for the accuracy spot-check (§6) and operator review.

---

## 5. `entity_id` / `Gov Entity ID` construction

Every `CanonicalEntity` gets a stable `entity_id`, also written to the Airtable
`Gov Entity ID` field (the off-market analogue of `Listing ID`):

- **Has a UEI** → `UEI:<uei>` (e.g. `UEI:ABC123DEF456`).
- **No UEI, has CAGE** → `CAGE:<cage>`.
- **Class 2, no UEI/CAGE, has SBIC license** → `SBIC:<license_no>`.
- **None of the above** → `NAME:<norm_name>|<zip-or-citystate>` — a deterministic
  hash-free key so the same firm yields the same id across runs (enabling
  cross-run dedup key A even for identifier-less firms).

The prefix records which key type identified the entity; `Gov Entity ID` is what
dedup key A matches on next run.

---

## 6. Resolution-accuracy spot-check (toward the §2.2 ≥95% target)

s4 SELF-TEST and s10 must spot-check resolution accuracy, not assume it:
- take a sample of resolution clusters and dedup verdicts;
- manually confirm each `exact`-key merge is genuinely one company and each
  `probable` merge is correct;
- confirm no `new` verdict is actually a tracker row under a different spelling
  and no `existing` verdict is a false collision;
- record the sampled accuracy in `_ralph_build/TEST_LOG.md` against the **≥95%**
  resolution-accuracy and **<5%** duplicate-rate targets. A miss sends s4 back
  to IMPLEMENT.

---

*Built by build-loop stage s4 (IMPLEMENT). Next phase: SELF-TEST — run the
resolver + tracker dedup over the s3 fixture records, confirm multi-source
records collapse to one entity and a seeded tracker row is detected as
`existing`, and record the accuracy spot-check in `_ralph_build/TEST_LOG.md`.*
