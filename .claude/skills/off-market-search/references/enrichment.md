# Off-Market Enrichment & Qualification Pre-Filters

Built by build-loop **stage s5**. This reference defines how a thin canonical
gov record (from s4) is turned into a **scorable lead packet**: the cheap
pre-filters that drop obvious non-fits before any expensive work, the
enrichment steps that fill in website / formation date / financial signals /
contacts, and the `LeadPacket` object handed to s6 for scoring.

Implements PRD **§7.1** (the enrich → lead-packet pipeline), **§7.4** (the
cost-control pre-filters), and the §7.2 / §7.3 per-class enrichment notes, with
the §13 resolution decisions applied: state SOS / portals are in Phase 1, with
the **B1**-resolved priority jurisdictions (DC, VA, MD, PA, WV) wired into the
§3.2 SOS lookup; the SBIC directory publishes **no** standing flag, so good
standing is cross-referenced (§13).

Companion files:
- `references/entity_resolution.md` — produces the `CanonicalEntity` input.
- `references/source_adapters.md` — the S5 (SBIC good-standing), S8 (state
  portals), S9 (RID), S10 (IAPD) enrichment adapters this stage drives.
- `config/offmarket_sources.md` — the Class-1 keyword / exclusion lists and the
  Class-2 keyword list the pre-filters apply.

> Markdown-driven, like the adapters and resolver: each procedure below is
> executed at runtime by the skill (string tests, web search, Playwright
> navigation, Airtable / API reads) — not compiled code.

---

## 1. Stage inputs and outputs

**Input:** the s4 output filtered to entities tagged `dedup_verdict: new` —
each a `CanonicalEntity`. `existing` entities skip s5 entirely (they go
straight to s7 as an update, with their gov fields refreshed). Entities marked
`needs_operator_review` by s4 also skip s5 and are reported in the run log.

**Output:** for every `new` entity that **passes the §7.4 pre-filter**, one
**`LeadPacket`** — the same structured-data object `overnight-search` Step 6
passes to the scorer, extended with the off-market gov fields. Entities that
**fail** the pre-filter are dropped before enrichment and recorded (with the
reason) in the s9 run log — they are not enriched, not scored, not written.

### `LeadPacket` — the scorable object

| Field | Type | Source |
|---|---|---|
| `entity_id` | string | from `CanonicalEntity` (`Gov Entity ID`) |
| `target_class` | `1` \| `2` | from `CanonicalEntity` |
| `business_name` | string | `legal_name` |
| `industry` | string | derived from NAICS/PSC + keyword hits |
| `location` | object | `{city, state}` from canonical `address` |
| `website` | string \| null | §3.1 discovery |
| `website_status` | `live` \| `dead` \| `none_found` | §3.1 validation |
| `screenshot_path` | string \| null | §3.1 screenshot |
| `formation_date` | string \| null | §3.2 SOS lookup |
| `years_in_business` | number \| null | computed from `formation_date` |
| `sos_status` | string \| null | SOS active / good-standing string |
| `employee_count` | number \| null | §3.3 — number, else `null` with an `"employee count — needs follow-up"` gap |
| `revenue_signal` | string | §3.3 — estimate **labelled as a signal**, or `"needs follow-up"` |
| `federal_award_total` | number \| null | `award_total` from `CanonicalEntity` |
| `asking_price` | string | off-market → `"not for sale — no asking price"` |
| `contact` | object \| null | §3.4 — owner / GP principal POC |
| `sbic_license_no` | string \| null | Class 2 — from `CanonicalEntity` |
| `sbic_license_status` | string | Class 2 — §4 good-standing cross-check result |
| `sbic_gp_economics` | object \| null | Class 2 — §3.5 GP economics |
| `gov_data_source` | string[] | `source_ids` mapped to `Gov Data Source` choices — §5.1 |
| `provenance_urls` | string[] | `source_urls` from `CanonicalEntity` |
| `prefilter_verdict` | `pass` | only `pass` packets are emitted |
| `enrichment_gaps` | string[] | every field left `"needs follow-up"` — audit trail |

**Never fabricate.** Any field not found stays `"needs follow-up"` (or `null`)
and is listed in `enrichment_gaps`. No invented financials, employee counts,
formation dates, websites, or contacts — consistent with the on-market skills
and the build-plan constraints.

---

## 2. §7.4 — Cheap pre-filters (run FIRST, before enrichment)

Cost control: scoring and Playwright enrichment are expensive, so each
candidate must clear a cheap, identifier/keyword-only pre-filter **before** any
website discovery or SOS lookup. A candidate that fails is dropped immediately.

### 2.1 Class 1 — ASL platform bolt-on pre-filter

A Class-1 candidate **passes** only when **both** hold:

1. **Keyword filter indicates a sign-language / deaf-services line.** At least
   one `keyword_hits` entry (from s3, carried on the `CanonicalEntity`) is in
   the Class-1 **core or adjacent** list of `config/offmarket_sources.md`
   §5.2 — and **no** exclusion term dominates. A record whose only hits are
   exclusion / down-weight terms (spoken-language-only translation with no ASL
   signal) is **dropped**. A spoken-language-only translation firm that *does*
   carry an ASL/CART signal is kept but tagged `adjacent` (Buy Box line-10
   bonus 5, not 10 — §13).
2. **U.S. operating company.** The canonical `address.country` is US (or null
   with a US state present), and the entity is an operating company — not a
   government office, a sole individual interpreter with no business entity, or
   a pure staffing-agency listing with no deaf-services line.

### 2.2 Class 2 — SBIC pre-filter

A Class-2 candidate **passes** only when:

1. **Current licensee.** The entity appears on the **current** SBA SBIC
   directory export (s3 adapter S4) — not a lapsed/historical-only row.
2. **Good standing not already disproven.** This condition checks only a
   *prior-run or cached* standing result — the §2 pre-filter runs **before** the
   §3/§4 enrichment of this run, so on a first run no §4 cross-check has executed
   yet and there is nothing to disprove. If a cached / prior-run §4 good-standing
   cross-check has already surfaced a `Revoked` / `Surrendered` status for this
   entity, the candidate is dropped here. Otherwise — no cached standing, or an
   *unconfirmed* standing — the candidate **passes** the pre-filter; the §4
   cross-check then runs in this run's enrichment and the scorer's SBIC gate
   handles an unconfirmed standing as CONDITIONAL (§7.3).

Pre-filter outcome is logged per candidate: `pass`, or `drop` + reason. Only
`pass` candidates proceed to §3.

---

## 3. Enrichment steps (for pre-filter-passing candidates)

### 3.1 Website discovery + Playwright validation + screenshot

Reuses `overnight-search` **Step 3** logic verbatim — same validation, same
screenshot path convention:

1. **Discover** the company website: web search on `legal_name` + city/state
   (+ "sign language" / "interpreting" for Class 1). Prefer a first-party
   domain over a directory/aggregator page.
2. **Validate** in Playwright: navigate; confirm the page is the company's own
   site with company-specific content (name, services, location). Negative
   signals — parked domain, "site not found", a generic directory page, a
   login wall — mean **not validated**.
3. **If valid:** capture a full-page screenshot →
   `output/screenshots/{entity-id-slug}.png`; set `website`,
   `website_status: live`, `screenshot_path`.
   - **`{entity-id-slug}` — sanitize `entity_id` for filesystem use.** The
     off-market `entity_id` is not a plain alphanumeric id like the
     `overnight-search` `listing-id`; it embeds characters that are
     illegal or fragile in filenames — `:` (e.g. `UEI:`/`SBIC:` prefix),
     `|` and spaces (e.g. `NAME:abacus finance group|new york ny`), and `/`
     (SBIC license numbers, e.g. `SBIC:09/79-0292`). So the canonical
     `entity_id` is **not** used verbatim as the filename. Build the slug:
     lowercase the `entity_id`, replace every run of any character outside
     `[a-z0-9]` (covering `:`, `|`, `/`, and whitespace) with a single `-`,
     collapse consecutive `-`, and trim leading/trailing `-`. Examples:
     `UEI:ZZTEST00FIX1` → `uei-zztest00fix1`;
     `NAME:abacus finance group|new york ny` →
     `name-abacus-finance-group-new-york-ny`;
     `SBIC:09/79-0292` → `sbic-09-79-0292`. The canonical `entity_id` itself
     is unchanged (it stays verbatim in `Gov Entity ID`, per
     `entity_resolution.md` §5); only the screenshot filename is slugified.
     `screenshot_path` records the actual on-disk path, e.g.
     `output/screenshots/uei-zztest00fix1.png`.
4. **If no first-party site is found / none validates:** `website: null`,
   `website_status: none_found` (or `dead`), `screenshot_path: null` — record
   `"website — needs follow-up"` in `enrichment_gaps`. **Do not** invent a URL
   and **do not** substitute a directory page as the website.

### 3.2 SOS formation-date lookup (feeds Buy Box "years in business")

Look up the entity in its state Secretary-of-State business registry via the s3
adapter **S8** SOS-registry path to get `formation_date`, `sos_status` (active /
good standing), registered agent, and officers.

- **Phase-1 scope (B1 RESOLVED 2026-05-22 — DC, VA, MD, PA, WV).** The SOS
  lookup is **wired and run** for any entity whose canonical `address.state` is
  one of the five Phase-1 jurisdictions, driving the matching S8 SOS / business
  registry surface (`source_adapters.md` S8 — DC DLCP CorpOnline
  `corponline.dc.gov`; VA SCC Clerk's Information System `cis.scc.virginia.gov`;
  MD SDAT / Maryland Business Express `egov.maryland.gov/businessexpress`; PA
  Dept. of State business search `file.dos.pa.gov`; WV SOS business-organization
  search `apps.sos.wv.gov/business/corporations`). The lookup runs under the S8
  per-jurisdiction **ToS gate** — `robots.txt` honored, an official export / API
  preferred over the public search UI, ≤1 request / 2s, no login/paywall
  bypass. A name lookup on `legal_name` + city resolves the registry record;
  read `formation_date` (date of incorporation / organization), entity status →
  `sos_status`, and officers (carried to §3.4 contact discovery).
- **Entity not in a Phase-1 jurisdiction.** If `address.state` is not one of
  DC / VA / MD / PA / WV, the SOS lookup is **skipped by design** — that
  registry is not yet in scope. Set `formation_date: null`,
  `years_in_business: null`, and record the gap `"formation date — needs
  follow-up (state SOS not in Phase-1 scope)"`. Skipping an out-of-scope state
  is **not** a fabrication and **not** a failure.
- **In-scope but not found / registry unreachable.** If the entity *is* in a
  Phase-1 jurisdiction but no registry record matches, or the jurisdiction was
  skipped this run by the S8 ToS gate (`status: degraded`), leave
  `formation_date` / `years_in_business` `null` and record `"formation date —
  needs follow-up (SOS lookup returned no match)"` (or `"… (state registry
  skipped this run — ToS unconfirmed)"`). Never invent a formation date.
- When a formation date is found, `years_in_business = current_year −
  formation_year`.

### 3.3 Financial-signal enrichment

Government records carry no revenue/EBITDA. Gather **signals only**, each
explicitly labelled as an estimate, never written as a hard financial:

- `federal_award_total` — already on the `CanonicalEntity` (`award_total`);
  carried through to `Federal Award History $`. This is contract revenue
  *with the government only*, not total revenue — label it as such.
- `employee_count` — from the website ("our team", staff page) or SAM.gov
  entity data if present; else `null`, with `"employee count — needs
  follow-up"` recorded in `enrichment_gaps` (the same `… | null` + gap pattern
  used by `website`, `formation_date` and the other unknown-able fields).
- `revenue_signal` — a qualitative band derived from award history + employee
  count + website scale, written as e.g. `"signal: small (<$5M est.) — based
  on $X federal awards + ~N staff"`. Never written into a numeric revenue
  field as if disclosed. If nothing supports an estimate → `"needs follow-up"`.

### 3.4 Ownership & contact discovery

Find a **direct** contact for the proprietary-approach outreach s8 drafts:

- **Class 1:** business owner / principal — from the website (About / team
  page), SOS officer records, or the SAM.gov entity POC.
- **Class 2:** the SBIC **GP principal / managing partner** — from the SBIC
  directory POC, the firm website, or IAPD (adapter S10) Form ADV principals.
- Store `{name, title, email, phone}` — any subfield not found stays null;
  if no direct contact is found at all, `contact: null` and s8 will skip the
  draft (no outreach without a contact). RID (adapter S9) is used here only as
  a **point-of-need** lookup for a specific firm — never bulk-copied.

### 3.5 Class-2 GP economics (SBIC mode context)

For Class-2 candidates, gather the §7.3 informational GP economics for the
scorer: management-fee revenue, EBITDA, FTE, AUM / committed capital,
outstanding SBA leverage, fund vintage and remaining life — from IAPD / Form
ADV (S10), the SBIC directory, and the firm website. All are **informational**
(the SBIC gate is the license, not the financials); anything not found is
`"needs follow-up"`. Every Class-2 `LeadPacket` also carries the standing fact:
**acquiring a licensed SBIC requires SBA prior approval of the change of
control** — a closing condition, surfaced to s6/s7.

---

## 4. SBIC good-standing cross-check (Class 2 — beyond the directory)

The SBA SBIC directory lists current licensees but **does not publish a
good-standing flag** (§13). Good standing is therefore cross-referenced, not
read off one page. Drive adapter **S5** to check, in order:

This cross-check is a **per-entity enrichment step**: it runs once for **every**
pre-filter-passing Class-2 entity (§2.2) in this run, never once per run for a
single representative. A run with N Class-2 candidates performs N independent §4
cross-checks and records N `sbic_license_status` values.

1. **Current directory presence** — the entity is on the latest SBIC directory
   export (already confirmed by the §2.2 pre-filter).
2. **Adverse-action / enforcement signals** — SBA OIG reports, SBA press
   releases, and the federal court records adapter (S11) for any
   license-revocation or receivership action naming the firm.
3. **IAPD / Form ADV** (S10) — for a GP that is also a registered investment
   adviser, a disclosed regulatory event is a negative signal.

Resolve to one `sbic_license_status` value matching the Airtable
`SBIC License Status` single-select:

- `Good Standing` — current on the directory **and** no adverse signal found.
- `Under Review` — current but an open/unresolved adverse signal exists.
- `Surrendered` / `Revoked` — confirmed terminated (also fails the §2.2
  pre-filter on a re-run).
- `Unknown` — standing **cannot be confirmed**. This is an honest value, not a
  failure: it flows to the scorer, whose SBIC gate returns **CONDITIONAL**
  (§7.3). Never write `Good Standing` to mean "couldn't find anything bad."

**Class-2 coverage gate (IMPROVE-s5-3).** The s5 SELF-TEST demonstrated the §4
cross-check end-to-end for only one Class-2 entity (R2 — `evidence/s5-selftest.md`
C6); R3/R4 passed the §2.2 pre-filter but their beyond-the-directory cross-check
was not separately shown. Because §4 is a per-entity step (above), s10's
larger-sample live run **must run and record the §4 cross-check for every
Class-2 entity it enriches** — one `sbic_license_status` value per entity, with
the adverse-action search query and verdict logged in `TEST_LOG.md` — so the
cross-check coverage is measured against real multi-entity data and not inferred
from the single R2 demonstration.

---

## 5. Building the `LeadPacket`

After the pre-filter and enrichment, assemble the `LeadPacket` (§1 schema):

- Map `CanonicalEntity` fields through unchanged (`entity_id`, identifiers,
  `address`, `award_total`, `source_*`).
- `industry` — a short human label from the NAICS/PSC + keyword tier (e.g.
  `"Sign-language interpreting (NAICS 541930, core)"`).
- `asking_price` — always the literal `"not for sale — no asking price"` for
  off-market; this drives the scorer's "insufficient data — not awarded" on
  Buy Box check 5 / rubric line 8 (§7.2), which is expected, not a failure.
- `gov_data_source` — the deduplicated set of `Gov Data Source` Airtable
  choices for the entity's discovery `source_ids`, per the §5.1 mapping table.
- `enrichment_gaps` — list **every** field left `"needs follow-up"`; this list
  is carried to s7 (written into `Notes`) and to s8 (the outreach draft asks
  for exactly these unknowns).

Hand the `pass` packets to s6 (scoring); hand the `drop` list and the
`needs_operator_review` carryover to s9 (run log).

### 5.1 `source_id` → `Gov Data Source` mapping (fail-loud, never auto-grow)

`gov_data_source` is the deduplicated set of `Gov Data Source` Airtable choices
covering the entity's discovery `source_ids`. The `Gov Data Source` multi-select
has **eight** live choices (`evidence/s2-airtable-schema.md`): `USAspending`,
`SAM.gov`, `SAM.gov Contract Awards`, `SBA SBIC`, `SBS`, `GSA eLibrary`,
`State`, `RID`. Each discovery `source_id` maps to exactly one of them:

| `source_id` | adapter | `Gov Data Source` choice |
|---|---|---|
| `S1` | USAspending.gov | `USAspending` |
| `S2` | SAM.gov Entity Management API | `SAM.gov` |
| `S3` | SAM.gov Contract Awards API | `SAM.gov Contract Awards` |
| `S4` | SBA SBIC Directory | `SBA SBIC` |
| `S5` | SBIC good-standing cross-check | `SBA SBIC` |
| `S6` | SBA Small Business Search (SBS) | `SBS` |
| `S7` | GSA eLibrary | `GSA eLibrary` |
| `S8` | Priority-state portals / SOS registries | `State` |
| `S9` | RID | `RID` |

`S10` (IAPD / Form ADV) and `S11` (U.S. Courts) are **enrichment-only** — per
`config/offmarket_sources.md` neither is a discovery source, so neither ever
appears as a discovery `source_id` on a `CanonicalEntity` and neither
contributes a `Gov Data Source` value (their evidence lives in
`provenance_urls`).

**Fail-loud rule.** Multi-select choices auto-grow silently on write, so a
free-text or mistyped value would create a spurious 9th choice and break
field-value consistency with the s7 Airtable write. To prevent that, **every**
value placed in `gov_data_source` must be one of the eight live choices,
produced **only** via the table above. A discovery `source_id` not in this
table is an **error** — the skill halts with the schema-preflight-style
operator message naming the unmapped `source_id`; it **never** writes an
unmapped or free-text value and **never** lets the multi-select auto-grow.

---

## 6. Failure & edge handling

- **Pre-filter drops everything for a class** — not an error; the run logs
  "0 Class-N candidates passed pre-filter" and continues with the other class.
- **Playwright failure on one candidate** — log it, set `website_status: dead`
  / `screenshot_path: null`, continue enriching the rest (mirrors
  `overnight-search` error handling).
- **A pre-filter-passing candidate that enriches to zero usable signal** — it
  is still scored; the scorer handles thin data via "insufficient data — not
  awarded". Do not drop a pre-filter pass just because enrichment was sparse.
- **State SOS unreachable, out of Phase-1 scope, or skipped by the ToS gate** —
  formation date is left a gap, not fabricated; see §3.2.
- **Conflicting signals** (e.g. two different formation dates) — keep the
  most authoritative (SOS over website), note the conflict in
  `enrichment_gaps`.

---

*Built by build-loop stage s5 (IMPLEMENT). Next phase: SELF-TEST — run the
pre-filters + enrichment over the s4 fixture entities, confirm an obvious
non-fit is dropped before enrichment, a Class-1 and a Class-2 entity each
produce a complete `LeadPacket` with unknowns marked "needs follow-up" (not
fabricated), and the SBIC good-standing cross-check resolves a status without
relying on a directory flag — record pass/fail per check in
`_ralph_build/TEST_LOG.md`.*
