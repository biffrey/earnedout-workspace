# Off-Market Airtable Write & Dashboard Badge

Built by build-loop **stage s7**. This reference defines how each `ScoredLead`
produced by s6 is persisted to the **existing** Master Deal Pipeline tracker and
made visible on the daily dashboard. There is **no parallel tracker**: off-market
records are written to the same base / table as on-market leads and are
**interchangeable** rows.

Implements PRD **§8** (field-by-field mapping) and the §13 resolution decisions:
a dedicated `Gov Entity ID` field (do not reuse `Listing ID`); the two new
`Source` values; an **"Off-Market" badge** on dashboard rows (no `Source`
column added).

**Airtable target:** base `appOsvuyy5eK43QTx`, table `tblSmNrHROMLm7vOS`
("Master Deal Pipeline").

Companion files:
- `references/scoring_integration.md` — produces the `ScoredLead` input (its §1).
- `references/entity_resolution.md` — produced `dedup_verdict` / `tracker_record_id`.
- `references/airtable_schema_preflight.md` — the Step-1 fail-loud check that
  must pass before any write here runs.
- `config/search_config.md` — field IDs for the existing + 16 reused fields.
- `Off-Market Search/_ralph_build/evidence/s2-airtable-schema.md` — field IDs for
  the five new §8.4 fields.

> Markdown-driven, like the adapters / resolver / enrichment / scoring: the
> procedure below is executed at runtime by the skill (it calls the Airtable
> MCP tools and renders a Jinja template) — not compiled code.

---

## 1. Stage inputs and outputs

**Input:** the s6 output — a list of `ScoredLead` objects (`new` entities), plus
the s4 `existing`-tagged `CanonicalEntity` objects (each carrying a
`tracker_record_id`). `new` → **create**; `existing` → **update** the matched
row, never a duplicate.

**Output:**
1. One Airtable row per `ScoredLead` in `tblSmNrHROMLm7vOS`, created or updated.
2. Each new/updated row's record URL captured back into `Notes` and into the
   `ScoredLead` (for the run log).
3. The daily dashboard regenerated with the **"Off-Market" badge** on
   off-market rows (the badge markup is added by this stage; the dashboard
   *wiring* — assembling the lead dicts — is s9, Step 8 of the skill).

---

## 2. Preconditions — never write blind

Before the first write of a run:

1. **Schema preflight must have passed** (skill Step 1,
   `references/airtable_schema_preflight.md`). It confirms the `Source` field
   carries `Off-Market — ASL Bolt-on` and `Off-Market — SBIC` and that the five
   §8.4 fields exist. If the preflight failed, the skill has **already halted** —
   s7 never runs. s7 does **not** re-check or auto-create anything; a missing
   `Source` value is a fail-loud operator stop, not a silent skip.
2. **The s4 tracker read succeeded.** Per `entity_resolution.md` §"Failure
   handling", a failed tracker read halts the write step rather than writing
   blind — duplicates would result. If s4 reported a tracker-read failure, do
   not write; surface the error and stop.

---

## 3. Field-by-field mapping (PRD §8) — create a new record

For every `ScoredLead` whose entity is `new`, create one record. Field IDs:
existing + 16 reused fields from `config/search_config.md`; the five new fields
from `evidence/s2-airtable-schema.md`. Map from the `ScoredLead`
(`lead_packet` = the s5 `LeadPacket`; scoring fields from s6):

### 3.1 Existing fields (PRD §8.1)

| Field (ID) | Off-market value |
|---|---|
| Business Name (`fldquYtYnHJ1YzUR7`) | `lead_packet.business_name` — resolved canonical company / SBIC GP name |
| Industry Match (`fldyJH0ZsOJD29wEg`) | Class 1 → `"Sign Language / CART (Applied Development add-on)"`; Class 2 → `"SBIC"` |
| Business Address (`fldkVBunWYKdXkgpB`) | `lead_packet.location` / resolved address (SAM.gov / SOS) |
| Website (`fldTRaz0PzBYS9ICl`) | `lead_packet.website` — blank if `website_status: none_found` |
| Links (`fldwo7ui7aIGoMxAG`) | `lead_packet.provenance_urls` — the source government-record URL(s) |
| Lead Source (`fldI1h3qmNI6vc5rr`) | **Blank** off-market. `Lead Source` is a **singleSelect** restricted to 14 broker-platform options (`Direct Outreach`, `Broker`, `Referral`, `Conference`, `BizBuySell`, `BizQuest`, `Axial`, `Grata`, `DealStream`, `Trade-A-Plane`, `LinkedIn`, `Other Platform`, `General Web`, `BusinessBroker.net`) — it cannot hold a gov-source string and a gov source is not a broker platform. Gov provenance is carried by the dedicated `Gov Data Source` multi-select (§3.3) and the source URL(s) in `Links` (§3.1). **Never auto-create a select option** to hold a gov-source value |
| Broker Name (`fldXdZC8Tbrbk8ysk`) | **Blank** off-market — no broker |
| Owner Name (`fldfa10GqZ1FfinQW`) | `lead_packet.contact.name` if a direct contact (owner / SBIC GP principal) was found |
| Contact Email / Phone (`fldlOcCvi9SSCoIu2` / `fldlsBbVahZqAiMHd`) | From `lead_packet.contact` if found; else blank |
| Asking Price (`fldhqAXiAWh2ktXln`) | **Blank** — the company is not for sale (never write `"not for sale"` text into a currency field) |
| EBITDA / EBITDA Margin (`fldFK17soNXcUsxbg` / `fldufGAWn6iv9axWa`) | Only if a real disclosed figure exists; otherwise **blank** (never a signal/estimate) |
| Years in Business (`fldhdqJ0Ow0Z608Pl`) | `lead_packet.years_in_business` if known; else blank |
| Qty FT Employees (`fldgvFTCdDauWZDr3`) | `lead_packet.employee_count` if a real count; else blank |
| NAICS Code (`fldNoi4yt9l4oHwcu`) | NAICS from the gov record (e.g. `541930`) |
| Status / Track / Tier (`fldB0LCiJMUuKVd6y` / `fldAZYJlGy2R95TSn` / `fldCGASC27dR0fJz8`) | Per existing tracker conventions (Tier from the lead score band) |
| Priority Geography? (`fld1x82ld7D0UYjHw`) | Set if the resolved state is a B1 priority state |
| Notes (`fldbEqYoyoPNthNoV`) | The §3.4 Notes block |

### 3.2 The 16 reused fields (PRD §8.2)

| Field (ID) | Off-market value |
|---|---|
| Listing ID (`fld81k0uFwqkHaEEI`) | **Blank** — off-market uses the dedicated `Gov Entity ID` field, not `Listing ID` (§13 operator decision) |
| Direct Listing URL (`fldMCmSVQjYv3odok`) | The canonical gov-record URL (USAspending recipient page / SAM entity page / SBA directory entry) — never a search-results page |
| Listing Screenshot (`fldrPuxZHGsYZuxTO`) | Attach the PNG from `lead_packet.screenshot_path` if a first-party site was validated; else leave empty |
| Date Added (`fldoZVwrhWaGGMlFR`) | Run date |
| Date Updated (`fld3TRpVYopXL7LLm`) | Run date (same as Date Added for a new record) |
| Previous Asking Price (`fldySRjfm1P8Nodes`) | **Unused** off-market — leave blank |
| Link Health Status (`fldlsuLeSFhFKQuFc`) | `"Live"` once the website / gov record validated; `"Dead"` if not reachable |
| Link Last Checked (`fldMXwyQbEWPXbqE2`) | Validation date (run date) |
| Disposition (`fldw0xk1YBkmP7sBD`) | **`"Active"`** — default for every new off-market lead |
| Lead Score (`fld2ipICYNLjaDm39`) | `ScoredLead.lead_score` (Class 1: /110; Class 2: informational). If `null` (scorer failed for this candidate), leave blank and note it in `Notes` |
| Prospect Eval Report (`fld9InVXs4RqgtNDo`) | `ScoredLead.report_html_path` |
| Revenue 2024 / 2025 (`fldfUOMF98BAk8Qeo` / `fld8Pmhi9M7m5qaUf`) | Only a real disclosed figure; off-market revenue **signals** are never written here (they stay in the report) |
| Cash Flow 2024 / 2025 (`fldwX2NkTE2E66pln` / `flde6Fr88nm4BAoE1`) | Same — disclosed figures only, else blank |
| Source (`fldiGyXTk6Ybb6J1L`) | Class 1 → **`"Off-Market — ASL Bolt-on"`**; Class 2 → **`"Off-Market — SBIC"`** (em dash U+2014, exact spacing) |

### 3.3 The five new §8.4 fields (IDs from `evidence/s2-airtable-schema.md`)

| Field (ID) | Off-market value |
|---|---|
| Gov Entity ID (`fld7Ook8ZoLAjwFTe`) | `lead_packet.entity_id` — the prefixed cross-source key from s4 (`UEI:…` / `CAGE:…` / `SBIC:…` / `NAME:…`). The off-market unique key |
| SBIC License # (`fldogicjVNMCBuyJI`) | Class 2 → `lead_packet.sbic_license_no`. Class 1 → blank |
| SBIC License Status (`fldscFvXPUFYbSg3F`) | Class 2 → `lead_packet.sbic_license_status` (one of `Good Standing` / `Under Review` / `Surrendered` / `Revoked` / `Unknown` — never defaulted to `Good Standing`). Class 1 → blank |
| Gov Data Source (`fldM7KoR2gtfvBVWN`) | `lead_packet.gov_data_source` — multi-select values from the `enrichment.md` §5.1 mapping table only (live choices: `USAspending` / `SAM.gov` / `SAM.gov Contract Awards` / `SBA SBIC` / `SBS` / `GSA eLibrary` / `State` / `RID`). An unmapped value halts the skill (never auto-grow the select) |
| Federal Award History $ (`fldZXrqqoBkIdDWJN`) | `lead_packet.federal_award_total` — total federal awards from USAspending (a size proxy for Class 1). Blank if no award history |

### 3.4 The `Notes` block (PRD §8.1, adapted 4-identifier rule)

```
[BUSINESS_NAME] | Gov Entity ID: [GOV_ENTITY_ID]
Direct gov-record URL: [DIRECT_LISTING_URL]
Airtable record: [AIRTABLE_RECORD_URL]
Lead Score: [SCORE]/[110 or 100]   ([informational] for Class 2)
[One-line summary from the prospect-evaluation report]
[Class 2 only:] Change of control of a licensed SBIC requires SBA prior approval.
[ScoredLead.scoring_notes — e.g. "no asking price (off-market) — valuation line not awarded"]
```

Capture the Airtable record URL **after** the record is created and write it
back into `Notes` (a second update). Never reference a search-results page.
Outreach drafts are appended to `Notes` later by s8 — not here.

---

## 4. Update an existing record (PRD §8, s4 `dedup_verdict: existing`)

When s4 tagged the entity `existing`, it carries a `tracker_record_id`. **Update
that row — never create a second one.** Per `entity_resolution.md`:

- Refresh `Link Last Checked` and `Date Updated` to the run date.
- Fill **blank** gov fields (`Gov Entity ID`, `Gov Data Source`,
  `Federal Award History $`, `SBIC License #` / `SBIC License Status`) — do
  **not** overwrite a value already present.
- Update `Lead Score` and `Prospect Eval Report` to the latest run's values.
- Append a dated line to `Notes` recording the off-market re-surface; **never
  flip an existing on-market row's `Source`** to an off-market value, and never
  change its `Disposition`.
- If the matched row is itself a prior off-market record, the same rules apply —
  update in place, append a dated `Notes` line.

---

## 5. The dashboard "Off-Market" badge

Per the §13 resolution: off-market rows get an **"Off-Market" badge**, **not** a
new `Source` column. The badge is added to `templates/daily-dashboard.html` by
this stage (s7); s9 wires the lead dicts that drive it.

**Whole-tracker rendering (not per-run).** The dashboard's Section B
(`running_queue`) and Section C (`revisit_bucket`) must be populated from a
fresh read of the **entire** `tblSmNrHROMLm7vOS` tracker — every
`Disposition = "Active"` row into B, every `"Revisit for Roll-up"` row into C —
exactly as `overnight-search` Step 10 does. Section A (`new_finds`) carries only
this run's leads. Populating B/C from the off-market run's own leads alone drops
every on-market lead and every prior-run row from the dashboard; the badge logic
below is additive and does not change this.

- **Badge style.** A `.chip.offmarket` class, sibling to the existing
  `.chip.price-drop` / `.chip.manual` chips, in the dashboard `<style>` block.
- **Render condition.** In Section A (New Finds) and Section B (Running Queue),
  render `<span class="chip offmarket">OFF-MARKET</span>` next to the business
  name when `lead.source` is an off-market value — i.e.
  `lead.source.startswith('Off-Market')`. This covers both
  `Off-Market — ASL Bolt-on` and `Off-Market — SBIC`.
- **On-market rows unchanged.** The condition is additive: an `Overnight Search`
  or `Manual Submission` row renders exactly as before. The existing `Source`
  column in Section A still shows the literal `Source` value.

The lead dict already carries `source` (see the template's data contract). No
new dict field is needed for the badge.

---

## 6. Failure and edge handling

- **Airtable write failure** — retry once; if it still fails, log the lead data
  locally (to the run log) and flag it for manual entry. One failed write does
  not abort the run (mirrors `overnight-search` error handling).
- **`lead_score: null`** (scorer failed for that candidate, s6 §6) — still write
  the record (the operator should see the target); leave `Lead Score` blank and
  note the scoring failure in `Notes`.
- **Class-2 `fail`/`conditional` gate** — still written as a normal `Active`
  row; `SBIC License Status` carries the real status; the gate state is in the
  report and the `Notes` summary line. Never dropped, never hidden.
- **Never fabricate to fill a field.** Every unknown field is left blank (its
  honest state); the gap is already enumerated in `lead_packet.enrichment_gaps`
  and visible in the report. No invented financials, NAICS, URLs, or contacts.
- **Never auto-create a `Source` value or field.** That is a Step-1
  preflight/operator concern (§2); s7 only writes against a schema already
  confirmed present.
- **Never auto-create a select option on any field.** `Lead Source` is a
  singleSelect with a fixed broker-platform option set (§3.1) — off-market rows
  leave it blank rather than writing an unmatched value. Writing a value not in
  a singleSelect/multipleSelects field's option set causes Airtable to reject
  the whole `create_records_for_table` call atomically (`HTTP 422: Insufficient
  permissions to create new select option`). Map only to existing options, or
  leave the field blank.

---

*Built by build-loop stage s7 (IMPLEMENT). Next phase: SELF-TEST — drive this
procedure over the s6 SELF-TEST `ScoredLead`s: confirm a Class-1 and a Class-2
record map field-by-field per §3 with the correct `Source` value and no
fabricated field; confirm an `existing`-tagged entity updates in place per §4
rather than creating a duplicate; confirm the `.chip.offmarket` badge renders on
an off-market row and an on-market row is unchanged. Record pass/fail per check
in `_ralph_build/TEST_LOG.md`.*
