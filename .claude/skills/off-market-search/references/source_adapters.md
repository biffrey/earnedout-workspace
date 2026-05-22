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
| `blocker_id` | the `BLOCKERS.md` entry id when `status: blocked` (the four bootstrap blockers B1–B4 are all resolved — set only if a future external precondition reopens) |
| `records_returned` | count |
| `query_filters` | the exact NAICS/PSC/keyword/time filters applied (provenance) |
| `rate_limit_note` | requests used vs. cap, any pacing applied |
| `notes` | free text — fixture-mode, partial pull, ToS constraint, etc. |

A `blocked` or `error` adapter **must not** halt the run: the orchestrator
records `meta` in the run log and proceeds with the other adapters. Only the s2
schema preflight is fail-loud.

### Fixture mode

Until the build loop verifies the skill, for SELF-TEST / dry runs, and for any
adapter whose live precondition is unmet (e.g. a missing credential, or a portal
whose ToS is not yet confirmed), an adapter may run in **fixture mode**: it reads
a recorded sample payload from `_ralph_build/evidence/s3-fixtures/<source_id>.json`
instead of calling the network, maps it through the identical normalization
code, and sets `meta.notes: "fixture"`. This lets s3 SELF-TEST and downstream
stages exercise the full pipeline without a network call — and, for a
quota-limited source, without spending live request budget.

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
     from `params`. Page with `page` / `limit` (cap 100/page). The
     `spending_by_award` response does **not** carry a recipient UEI — its
     `fields` list exposes `Recipient Name` and the internal `recipient_id`
     (a hashed `<hash>-<level>` token) but no UEI — so request `recipient_id`
     in `fields` and resolve the UEI in step 2.
  2. **Recipient-detail follow-up (required for `uei`):** for each distinct
     `recipient_id` returned in step 1, `GET /api/v2/recipient/{recipient_id}/`
     and read `uei` (and legacy `duns`, location) from that response. Cache by
     `recipient_id` so each recipient is fetched once per run; pace the
     follow-up calls at ~1 req/sec with the rest of the adapter. If the detail
     call fails or returns no `uei`, set `uei: null` and let s4 fall back to
     the name+address ladder for that record — never fabricate a UEI.
  3. For large pulls prefer `POST /api/v2/bulk_download/awards/`, then poll the
     returned file URL and parse the CSV; the bulk-download CSV **does** include
     a `recipient_uei` column, so a bulk pull can skip the step-2 follow-up.
  4. Validate `541930` / `R608` once per run via the NAICS/PSC autocomplete
     endpoints; abort the adapter (not the run) with `status: error` if either
     code no longer resolves.
- **Map:** recipient name→`legal_name`, recipient UEI→`uei` (from the step-2
  `/api/v2/recipient/{recipient_id}/` follow-up, or the `recipient_uei` column
  of a bulk download — **not** from `spending_by_award` directly), legacy
  DUNS→`duns`, recipient location→`address`, award NAICS/PSC→`naics`/`psc`,
  summed obligations→`award_total`, count→`award_count`, business-type flags→
  `socioeconomic_flags`. Group award rows by `recipient_id` (then by resolved
  UEI) so one recipient = one `RawRecord`.
- **Keyword tier:** scan recipient name + award description for the Class-1 core
  / exclusion terms; set `keyword_hits` / `keyword_tier`.
- **Rate / ToS:** no hard per-IP cap documented — pace ~1 req/sec, prefer bulk
  download for large pulls; data is U.S. Government work. `status: ok`.

### S2 — SAM.gov Entity Management API adapter  *(Class 1 — entity discovery + enrichment; live, public ~10/day tier)*

- **Transport:** REST, `x-api-key` header. Base
  `https://api.sam.gov/entity-information/v3/entities` — the Entity Management
  API is public at `api.sam.gov/entity-information/v1`–`v4`; this adapter
  targets **v3** (the version the recorded fixture's `entityData` shape
  matches).
- **API key (B3 RESOLVED).** The SAM.gov Public API Key is **never** stored in
  any file or committed. The adapter retrieves it at runtime from the macOS
  login keychain:
  ```
  security find-generic-password -s samgov-api-key -a off-market-search -w
  ```
  (service `samgov-api-key`, account `off-market-search`). The returned string
  is sent as the `x-api-key` request header. The keychain item was created via
  Keychain Access without `-A`, so the **first** read in a session may raise a
  one-time "Always Allow" prompt — that is expected, not an error. The weekly
  run executes in the operator's logged-in session (the launchd agent runs in
  `gui/<uid>`), so the login keychain is unlocked and reachable. If retrieval
  fails (no item, locked keychain, or the prompt is denied), the adapter sets
  `status: error, notes: "SAM.gov key unavailable"` and falls back to **fixture
  mode** — it never fabricates entity data and never halts the run.
- **Query:** `GET /entity-information/v3/entities` with `primaryNaics=541930`
  (Translation & Interpretation), optional
  `physicalAddressProvinceOrStateCode=<state>` from `params`,
  `registrationStatus=A` (active registrations only), and
  `includeSections=entityRegistration,coreData,assertions,pointsOfContact,socioEconomic`.
  Page with `page` (0-indexed) and `size`. Request the **public tier only** —
  never the FOUO / Sensitive sections (those need a Federal System Account, not
  available to a private acquirer and not needed here).
- **Map:** from each `entityData[]` element —
  `entityRegistration.legalBusinessName`→`legal_name`,
  `entityRegistration.dbaName`→`dba_name`, `entityRegistration.ueiSAM`→`uei`,
  `entityRegistration.cageCode`→`cage_code`, legacy DUNS (if present)→`duns`,
  `coreData.physicalAddress`→`address`,
  `assertions.goodsAndServices.naicsList[].naicsCode` / `primaryNaics`→`naics`,
  `socioEconomic.businessTypeList`→`socioeconomic_flags`,
  `pointsOfContact.governmentBusinessPOC`→`poc`,
  `coreData.entityInformation.entityURL`→`website`, registration status /
  expiration dates→`source_payload`.
- **Rate / ToS — B3 RESOLVED.** The Public API Key is live. The SAM.gov account
  behind it is on the **public ~10 requests/day tier** until SAM.gov entity
  registration completes (~2–3 weeks) for the role-assigned **1,000/day** tier
  — no code change is needed when the cap rises. While on the 10/day tier the
  adapter budgets strictly: run S2 **after** the key-free discovery sources
  (S1, S6, S7), cap S2 at ≤10 requests per run (shared with S3 — see below),
  and pull the broadest useful page first. On an HTTP 429 / quota-exceeded
  response the adapter stops paging and returns `status: degraded` with a
  `rate_limit_note` — it does **not** halt the run; the other adapters' records
  still flow downstream. `status: ok` on a clean keyed pull within quota.
- **Recorded-fixture query:** `_ralph_build/evidence/s3-fixtures/S2.json` — a
  structural sample of the v3 `entityData` response (illustrative placeholder
  identifiers, never written as a real prospect). It exercises the S2
  normalization mapping end-to-end without spending the live 10/day quota; the
  adapter runs it in fixture mode for SELF-TEST and any dry run.

### S3 — SAM.gov Contract Awards API adapter  *(Class 1 — FPDS-NG successor; live, public ~10/day tier)*

- **Transport:** REST, hosted under `api.sam.gov`; the **same SAM.gov Public
  API Key** as S2 (`x-api-key` header), retrieved at runtime by the
  **identical** keychain command:
  ```
  security find-generic-password -s samgov-api-key -a off-market-search -w
  ```
  The endpoint path / version is per the live GSA documentation at
  `https://open.gsa.gov/api/contract-awards/`. **Do NOT build on fpds.gov or
  the FPDS ATOM feed** — the FPDS.gov public site is decommissioned and the
  ATOM feed retires in FY2026 (§13 item 4).
- **Query:** contract awards filtered by NAICS `541930` / PSC `R608`, time
  period from `params` (default trailing 5 FYs). Used to **cross-check /
  supplement** S1 — USAspending stays primary.
- **Map:** contractor name→`legal_name`, vendor UEI→`uei`, award NAICS/PSC→
  `naics`/`psc`, obligated $→`award_total`, dates + contracting agency→
  `source_payload`, small-business flags→`socioeconomic_flags`.
- **Rate / ToS — B3 RESOLVED.** Shares the S2 Public API Key and therefore the
  **same daily quota** — S2 and S3 draw from one shared budget (~10 requests/day
  on the public tier until SAM.gov entity registration completes, then
  1,000/day). The orchestrator counts both adapters' calls against that single
  cap. Same key-retrieval failure handling as S2 (retrieval failure →
  `status: error` → fixture fallback, never fabricate). On an HTTP 429 /
  quota-exceeded response the adapter stops paging and returns
  `status: degraded` with a `rate_limit_note`; the run continues. `status: ok`
  on a clean keyed pull within quota.
- **Recorded-fixture query:** `_ralph_build/evidence/s3-fixtures/S3.json` — a
  structural sample of a Contract Awards record (placeholder values, never
  written as a real award); exercises the S3 mapping without spending live
  quota.

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

### S8 — Priority-state portals + Secretary-of-State registries adapter  *(Class 1 — Phase 1; B1 RESOLVED — DC, VA, MD, PA, WV)*

- **Transport:** per-jurisdiction — non-uniform. Each Phase-1 jurisdiction
  exposes two surfaces: a **state eProcurement portal** (solicitations / awards
  for ASL & CART interpreting bought by courts, public education, and
  vocational-rehabilitation agencies) and a **Secretary-of-State / business
  registry** (formation date, entity status, registered agent, officers — feeds
  s4 resolution and the s5 SOS lookup). Accessed by an official open-data export
  / API where one exists, else `WebFetch` or the Playwright MCP over the public
  search UI with courteous pacing.
- **Phase-1 jurisdictions (B1 RESOLVED 2026-05-22): DC, VA, MD, PA, WV.** The
  two surfaces per jurisdiction:

  | Jurisdiction | eProcurement portal | SOS / business registry |
  |---|---|---|
  | **DC** | OCP contracts — `contracts.ocp.dc.gov`; open data `opendata.dc.gov` | DLCP CorpOnline — `corponline.dc.gov` |
  | **VA** | eVA — `eva.virginia.gov` (public solicitation/award search) | SCC Clerk's Information System — `cis.scc.virginia.gov` |
  | **MD** | eMaryland Marketplace Advantage (eMMA) — `emma.maryland.gov` | SDAT Business Entity Search / Maryland Business Express — `egov.maryland.gov/businessexpress` |
  | **PA** | PA eMarketplace — `emarketplace.state.pa.us` | PA Dept. of State business search — `file.dos.pa.gov` |
  | **WV** | WV Purchasing Division / wvOASIS VSS — `wvpurchasing.gov` | WV SOS business-organization search — `apps.sos.wv.gov/business/corporations` |

- **ToS confirmation (B1 mandate — required before any automated call).** Each
  portal's terms differ; per jurisdiction, before its first automated request
  the adapter (1) fetches and honors the portal's `robots.txt`; (2) reads the
  portal's published Terms of Use / acceptable-use statement; (3) **prefers** an
  official bulk export, open-data dataset, or documented API over UI scraping
  (DC `opendata.dc.gov` and several eProcurement portals publish CSV / RSS feeds
  — use those first); (4) paces ≤1 request / 2s, no concurrency, never extracts
  behind a login or paywall. If a jurisdiction's ToS prohibits automated access,
  or its terms cannot be confirmed this run, the adapter **skips that
  jurisdiction**, records `status: degraded` with a per-jurisdiction `notes`
  entry, and continues — it never halts the run and never scrapes a portal whose
  terms forbid it.
- **Query:** for each ToS-cleared jurisdiction —
  - *eProcurement:* search solicitations / awards for the Class-1 keyword set
    (`config/offmarket_sources.md` → "Class-1 keyword strategy" — `ASL`,
    `sign language`, `interpreting`, `CART`, `realtime captioning`,
    `communication access`, `VRI`, …), scoped to interpreting / captioning
    services bought by courts, public-education, and vocational-rehabilitation
    agencies. State portals carry no uniform NAICS field — the keyword strategy
    is the filter.
  - *SOS registry:* a name lookup per candidate (discovery candidates from the
    eProcurement scan, plus s5 enrichment lookups) for formation date, entity
    status, and officers.
- **Map:** vendor / awardee name→`legal_name`, trade name→`dba_name`,
  portal-published address→`address`, contract/solicitation title + agency +
  award $→`source_payload` (award $→`award_total` only when the portal publishes
  a contract value attributable to the entity), SOS formation date + status +
  officers→`source_payload` (consumed by s4 resolution and the s5 SOS
  formation-date lookup — see IMPROVE-s5-5), the portal record page→`source_url`.
  Run the Class-1 keyword tiering→`keyword_hits` / `keyword_tier`. State portals
  publish **no UEI / CAGE** — `uei`, `cage_code`, `duns` stay `null`; s4 resolves
  S8 records on name+address (UEI back-fills if S1/S2 also carry the firm). Set
  `target_class: 1`.
- **Rate / ToS:** see "ToS confirmation" above. Per-run `status`: `ok` when ≥1
  jurisdiction was queried live within ToS; `degraded` when one or more
  jurisdictions were skipped (ToS unconfirmed / automation prohibited / portal
  unreachable); `error` only on a total adapter failure. **Never `blocked`** —
  B1 is resolved.
- **Recorded-fixture query:** `_ralph_build/evidence/s3-fixtures/S8.json` — a
  structural fixture carrying one sample record per Phase-1 jurisdiction (DC, VA,
  MD, PA, WV), each with the eProcurement + SOS shape this adapter maps.
  Identifiers are illustrative placeholders, never written as a real prospect.
  The adapter runs it in fixture mode for SELF-TEST and any dry run, and for any
  jurisdiction whose live ToS is not yet confirmed. No live state-portal call was
  made this iteration: each of the five portals' Terms of Use must be confirmed
  first (the B1 mandate), which a headless run cannot complete — the adapter is
  spec-complete and the per-jurisdiction ToS gate + fixture fallback are
  documented above for the live run.

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
| S2 | SAM.gov Entity API | 1 | discovery + enrichment | ok (live key; public ~10/day tier) |
| S3 | SAM.gov Contract Awards API | 1 | discovery (cross-check) | ok (live key; shares S2's ~10/day quota) |
| S4 | SBA SBIC Directory | 2 | discovery (primary) | ok |
| S5 | SBIC good-standing cross-check | 2 | enrichment (gate input) | ok |
| S6 | SBA Small Business Search | 1 | discovery (supplementary) | ok |
| S7 | GSA eLibrary | 1 | discovery | ok |
| S8 | Priority-state portals + SOS | 1 | discovery + enrichment | ok (B1 resolved — DC/VA/MD/PA/WV; per-jurisdiction ToS gate) |
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
