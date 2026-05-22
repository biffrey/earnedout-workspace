# Off-Market Source Adapters — Common Interface & Per-Source Modules

Built by build-loop **stage s3**. This reference defines one query module
("adapter") per government / open-data source, all behind a **single common
interface** so a source can be swapped, added, or removed without touching the
downstream stages (resolution s4, enrichment s5, scoring s6, write s7). The
FPDS-NG decommission is the cautionary tale that motivates the abstraction.

Companion files:
- `config/offmarket_sources.md` — the verified codes, endpoints, keywords, and
  per-source access facts every adapter reads.
- `references/airtable_schema_preflight.md` — the s2 preflight.

> The `off-market-search` skill is markdown-driven: each adapter below is a
> **procedure** the skill executes at runtime using `WebFetch`, `Bash` (curl),
> the Playwright MCP, or a CSV download — not compiled code. "Module" = one
> self-contained adapter section here.

---

## 1. The common adapter interface

Every adapter is invoked the same way and returns the same shape. Downstream
stages only ever see `RawRecord` objects — they never know which source
produced one.

### Invocation

```
adapter.query(target_class, params) -> { records: [RawRecord], meta: AdapterMeta }
```

- **`target_class`** — `1` (ASL bolt-on) or `2` (SBIC). An adapter that does not
  serve a class returns `records: []` and `meta.status: "n/a"`.
- **`params`** — optional run scoping: `time_period` (award lookback, default
  trailing 5 federal FYs), `place_of_performance` / `state` filter, `name` (for
  the manual single-entity path and point-of-need lookups), `limit`.
- Each adapter **applies its own source-appropriate filter** — NAICS `541930` /
  PSC `R608` / GSA SIN `541930` / SBIC-directory membership / the Class-1
  keyword strategy from `config/offmarket_sources.md` — and is responsible for
  its own pagination, rate-limit pacing, and ToS compliance.

### `RawRecord` — the normalized output object

Every adapter maps its native payload onto these fields. **Unknown → `null`**
(never invented — the s5 enricher converts `null` to "needs follow-up"; nothing
downstream fabricates a value).

| Field | Type | Notes |
|---|---|---|
| `source_id` | string | `S1`–`S11` — which adapter produced this record |
| `target_class` | `1` \| `2` | |
| `legal_name` | string | entity legal name as the source spells it |
| `dba_name` | string \| null | trade / "doing business as" name |
| `uei` | string \| null | 12-char SAM Unique Entity ID — primary resolution key |
| `cage_code` | string \| null | secondary resolution key |
| `duns` | string \| null | legacy; bridge key on pre-2022 award rows only |
| `sbic_license_no` | string \| null | Class-2 resolution key (S4/S5 only) |
| `address` | object \| null | `{street, city, state, zip, country}` |
| `naics` | string[] | NAICS codes on the record |
| `psc` | string[] | PSC codes on the record (award sources) |
| `award_total` | number \| null | $ summed for this entity in scope — size proxy |
| `award_count` | number \| null | number of awards in scope |
| `socioeconomic_flags` | string[] | small-business / set-aside flags |
| `poc` | object \| null | `{name, title, email, phone}` — public POC only |
| `website` | string \| null | if the source publishes one |
| `keyword_hits` | string[] | Class-1 core/exclusion terms matched in source text |
| `keyword_tier` | `core` \| `adjacent` \| null | per the §13 Q3 keyword strategy |
| `source_url` | string | the human-viewable page for this record (provenance) |
| `raw_pulled_at` | ISO-8601 | when the adapter fetched it |
| `source_payload` | object | the trimmed native record, kept for audit |

### `AdapterMeta` — per-call status

| Field | Notes |
|---|---|
| `status` | `ok` \| `blocked` \| `degraded` \| `n/a` \| `error` |
| `blocker_id` | `B1` / `B3` … when `status: blocked` — names the BLOCKERS.md entry |
| `records_returned` | count |
| `query_filters` | the exact NAICS/PSC/keyword/time filters applied (provenance) |
| `rate_limit_note` | requests used vs. cap, any pacing applied |
| `notes` | free text — fixture-mode, partial pull, ToS constraint, etc. |

A `blocked` or `error` adapter **must not** halt the run: the orchestrator
records `meta` in the run log and proceeds with the other adapters. Only the s2
schema preflight is fail-loud.

### Fixture mode

Until the build loop verifies the skill, and for any adapter whose live
precondition is unmet (B1, B3), an adapter may run in **fixture mode**: it reads
a recorded sample payload from `_ralph_build/evidence/s3-fixtures/<source_id>.json`
instead of calling the network, maps it through the identical normalization
code, and sets `meta.notes: "fixture"`. This lets s3 SELF-TEST and downstream
stages exercise the full pipeline without depending on a blocked credential.

---

## 2. Per-source adapters

Ordered by build priority. Each cites the `config/offmarket_sources.md` source
it implements.

### S1 — USAspending.gov adapter  *(Class 1 — PRIMARY award source; not blocked)*

- **Transport:** public REST, no key. `Bash` curl or `WebFetch` to
  `https://api.usaspending.gov`.
- **Query:**
  1. `POST /api/v2/search/spending_by_award/` with a filter object:
     `naics_codes: ["541930"]`, `psc_codes: ["R608"]` (run both; union the
     results), `time_period` from `params` (default trailing 5 FYs),
     `award_type_codes` for contracts + grants, optional `place_of_performance`
     from `params`. Page with `page` / `limit` (cap 100/page).
  2. For large pulls prefer `POST /api/v2/bulk_download/awards/`, then poll the
     returned file URL and parse the CSV.
  3. Validate `541930` / `R608` once per run via the NAICS/PSC autocomplete
     endpoints; abort the adapter (not the run) with `status: error` if either
     code no longer resolves.
- **Map:** recipient name→`legal_name`, recipient UEI→`uei`, legacy DUNS→`duns`,
  recipient location→`address`, award NAICS/PSC→`naics`/`psc`, summed
  obligations→`award_total`, count→`award_count`, business-type flags→
  `socioeconomic_flags`. Group award rows by UEI so one recipient = one
  `RawRecord`.
- **Keyword tier:** scan recipient name + award description for the Class-1 core
  / exclusion terms; set `keyword_hits` / `keyword_tier`.
- **Rate / ToS:** no hard per-IP cap documented — pace ~1 req/sec, prefer bulk
  download for large pulls; data is U.S. Government work. `status: ok`.

### S2 — SAM.gov Entity Management API adapter  *(Class 1 — entity discovery + enrichment; BLOCKED above 10/day by B3)*

- **Transport:** REST, `x-api-key` header = the SAM.gov Public API Key from the
  project secret store (never in any file). Base
  `https://api.sam.gov/entity-information/v<N>` (use the current version).
- **Query:** filter entities by NAICS `541930`, optional state; request the
  **public tier only** — never FOUO / Sensitive.
- **Map:** legal name + DBA→`legal_name`/`dba_name`, `uei`, `cage_code`,
  legacy DUNS→`duns`, physical address→`address`, NAICS list→`naics`,
  socioeconomic flags, registration status/dates→`source_payload`, public
  POC→`poc`, public URL→`website`.
- **Rate / ToS — B3:** a no-role account is capped at **10 requests/day**
  (unusable for a full run); a role-assigned account gets **1,000/day**.
  - If no key is present, or the key is no-role: return
    `status: blocked, blocker_id: "B3"` and (when verifying the pipeline) fall
    back to **fixture mode**. The adapter is fully built; only live use beyond
    10/day waits on B3.
  - With a valid keyed role: `status: ok`, pace under 1,000/day.

### S3 — SAM.gov Contract Awards API adapter  *(Class 1 — FPDS-NG successor; BLOCKED by B3)*

- **Transport:** REST, same SAM.gov key family (`x-api-key`). Docs/base per
  `https://open.gsa.gov/api/contract-awards/`. **Do NOT build on fpds.gov or the
  FPDS ATOM feed** — both are retired/decommissioning.
- **Query:** contract awards filtered by NAICS `541930` / PSC `R608`, time
  period from `params`. Used to **cross-check / supplement** S1 — USAspending
  stays primary.
- **Map:** contractor name→`legal_name`, `uei`, award NAICS/PSC→`naics`/`psc`,
  award $→`award_total`, dates + contracting agency→`source_payload`,
  small-business flags→`socioeconomic_flags`.
- **Rate / ToS — B3:** same key dependency as S2. No key → `status: blocked,
  blocker_id: "B3"`, fixture fallback. Adapter built; live use waits on B3.

### S4 — SBA SBIC Directory adapter  *(Class 2 — PRIMARY source; not blocked)*

- **Transport:** CSV download + diff — **no scraping**. Download
  `https://www.sba.gov/export/contacts/sbic` each run.
- **Query:** parse every row; the directory **is** the Class-2 universe (no
  NAICS filter — per config, do not guess an SBIC NAICS). Apply the B2 scope =
  **all licensed SBIC types** (operator may narrow — see B2). Diff against the
  previous run's CSV snapshot stored in
  `search_reports/sbic_directory/<YYYY-MM-DD>.csv` to flag new / changed / removed
  licensees.
- **Map:** `Manager` (management company / GP) → `legal_name` — **the GP /
  management entity is the target, never the fund or portfolio companies**;
  fund name + vintage + fund size + strategy + style + "making new investments?"
  → `source_payload`; city/state→`address`; investor-relations contact→`poc`.
  `sbic_license_no` → `null` (the directory does not publish it — S5 supplies it
  where found). Set `target_class: 2`.
- **Carry the government fact:** every S4 record carries — acquiring a licensed
  SBIC requires **SBA prior approval** of the change of control.
- **Rate / ToS:** public CSV, single download/run. `status: ok`.

### S5 — SBIC good-standing cross-check adapter  *(Class 2 — gate input; not blocked)*

- **Transport:** `WebFetch` of public SBA enforcement / OIG pages + a Federal
  Register search (`federalregister.gov` API, key-free).
- **Query:** for each S4 management entity, search SBA enforcement actions /
  SBIC license actions, SBA OIG reports, and Federal Register SBIC license
  actions for the entity / fund name.
- **Map:** result → an `sbic_license_status` value
  (`Good Standing` / `Under Review` / `Surrendered` / `Revoked` / `Unknown`)
  attached to the matching S4 record; capture any SBA license number found into
  `sbic_license_no`. **Default `Unknown`** when nothing is found — never assume
  good standing.
- **Note:** this is an **enrichment adapter** — it amends S4 records rather than
  emitting new entities. The directory establishes *currently licensed*;
  good standing must be cross-checked here. `status: ok`.

### S6 — SBA Small Business Search (SBS) adapter  *(Class 1 — supplementary; not blocked)*

- **Transport:** UI search via Playwright MCP at `https://dsbs.sba.gov/`
  (redirects to SBS). Treat as **UI-only** until a programmatic interface is
  proven. Formerly DSBS — renamed July 2025.
- **Query:** search by NAICS `541930` + the Class-1 keywords; supplementary —
  USAspending (S1) and the SAM Entity API (S2) already cover most of these firms.
- **Map:** firm name→`legal_name`, address, NAICS, any contact→`poc`.
- **Rate / ToS:** courteous UI pacing; no bulk extraction. `status: ok` (or
  `degraded` if the UI blocks automation).

### S7 — GSA eLibrary adapter  *(Class 1; not blocked)*

- **Transport:** the SIN contractor-list spreadsheet where published, else
  Playwright over the browse UI:
  `https://www.gsaelibrary.gsa.gov/ElibMain/sinDetails.do?scheduleNumber=MAS&specialItemNumber=541930&executeQuery=YES`
- **Query:** MAS SIN `541930` (Translation & Interpretation); adjacent SIN
  `611630` optional. These are vetted, established providers.
- **Map:** contractor name→`legal_name`, `uei` / contract number→`source_payload`,
  address, `website`. Run the Class-1 keyword tiering.
- **Rate / ToS:** prefer the spreadsheet over scraping; courteous pacing.
  `status: ok`.

### S8 — Priority-state portals + Secretary-of-State registries adapter  *(Class 1 — Phase 1; BLOCKED by B1)*

- **Transport:** per-state — non-uniform. State eProcurement portals + SOS
  business registries each have their own access method and ToS.
- **Query:** for each operator-named priority state (B1): state contracts for
  ASL/CART interpreting (courts, education, vocational rehab) and SOS lookups
  for formation date / status / officers.
- **Map:** firm name→`legal_name`, address, SOS formation date / officers→
  `source_payload` (also feeds s4 resolution + s5 enrichment).
- **Rate / ToS — B1:** the priority-state list is unset and **each state's terms
  must be confirmed before automating** (some portals prohibit bulk extraction).
  Until B1 clears the adapter returns `status: blocked, blocker_id: "B1"`,
  `records: []`. The common-interface shell is built; per-state query logic and
  ToS confirmation are added when B1 names the states.

### S9 — RID adapter  *(Class 1 — point-of-need enrichment ONLY; not blocked, constrained)*

- **Transport:** member search at
  `https://myaccount.rid.org/Public/Search/Member.aspx` via Playwright,
  **one lookup at a time**.
- **Query:** invoked **only** with a specific `params.name` while working an
  individual candidate (manual path, or s5 enrichment). **Never** a bulk
  discovery sweep — RID's terms instruct against copying the member directory
  into an external database.
- **Map:** confirmed agency/interpreter detail → enrichment on an existing
  record (`poc`, credential confirmation). Emits **no new discovery records**.
- **Guard:** if called without `params.name`, return `status: n/a` and do
  nothing — this enforces the no-bulk-copy rule in code, not just in prose.

### S10 — IAPD / adviserinfo.sec.gov adapter  *(Class 2 — enrichment; not blocked)*

- **Transport:** the SEC bulk **Form ADV Data** CSV
  (`sec.gov/.../information-about-registered-investment-advisers...`) preferred;
  IAPD `https://adviserinfo.sec.gov/` for point lookups. **Form ADV is in IAPD,
  not SEC EDGAR.**
- **Query:** match S4 SBIC GPs that are RIAs / Exempt Reporting Advisers.
- **Map:** AUM, principals, fund vintage → enrichment on the matching S4 record.
- **Coverage caveat:** only SBIC GPs that are RIAs/ERAs file — enriches *some*
  Class-2 targets, not all. Enrichment adapter; emits no new entities.
  `status: ok`.

### S11 — U.S. Courts interpreter procurement adapter  *(Class 1 — deprioritized; not blocked)*

- **Transport:** `WebFetch` of `https://www.uscourts.gov/court-programs/federal-court-interpreters`
  and NCID references.
- **Use:** **enrichment cross-reference only** — federal courts contract
  *individual* interpreters, not firms, so there is no machine-readable national
  list of interpreting *companies*. Emits no discovery records; cross-references
  names onto existing records. `status: ok` (low value).

---

## 3. Adapter registry & swappability

The orchestrator (s9) iterates a **registry** — adding/removing a source is a
one-line registry change, never a downstream edit. Discovery adapters emit new
`RawRecord`s; enrichment adapters amend existing ones.

| ID | Source | Class | Role | Live status |
|---|---|---|---|---|
| S1 | USAspending.gov | 1 | discovery (primary) | ok |
| S2 | SAM.gov Entity API | 1 | discovery + enrichment | blocked (B3) — built, fixture fallback |
| S3 | SAM.gov Contract Awards API | 1 | discovery (cross-check) | blocked (B3) — built, fixture fallback |
| S4 | SBA SBIC Directory | 2 | discovery (primary) | ok |
| S5 | SBIC good-standing cross-check | 2 | enrichment (gate input) | ok |
| S6 | SBA Small Business Search | 1 | discovery (supplementary) | ok |
| S7 | GSA eLibrary | 1 | discovery | ok |
| S8 | Priority-state portals + SOS | 1 | discovery + enrichment | blocked (B1) — shell only |
| S9 | RID | 1 | enrichment (point-of-need) | ok (constrained) |
| S10 | IAPD / Form ADV | 2 | enrichment | ok |
| S11 | U.S. Courts | 1 | enrichment (cross-ref) | ok |

The orchestrator collects every adapter's `RawRecord`s and `AdapterMeta`, then
hands the combined record set to s4 (entity resolution & de-duplication). A
`blocked` / `error` adapter degrades the run gracefully — its `meta` is logged,
the run continues.

---

*Built by build-loop stage s3 (IMPLEMENT). Next phase: SELF-TEST — exercise at
least one adapter against a live or recorded-fixture query and record pass/fail
per adapter in `_ralph_build/TEST_LOG.md`.*
