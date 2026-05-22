# Off-Market Source Configuration

Source config for the `off-market-search` skill. Companion to
`config/search_config.md` (Airtable IDs, output paths, on-market platforms).
Every code, endpoint, and access fact here is **verified** — see
`Off-Market Search/PRD_OFF_MARKET_SEARCH_Section13_Resolution.md` Part 2. No
verify-this-value placeholder markers remain; items still pending an operator
decision are carried as blockers in
`Off-Market Search/_ralph_build/BLOCKERS.md`.

<!-- Built by build-loop stage s1. Source adapters that consume this config are
built by s3. -->

---

## Target classes

| Class | Definition | Acquisition target |
|---|---|---|
| **1 — ASL bolt-on** | Operating companies in sign-language interpretation, CART / realtime captioning, VRI, and deaf / hard-of-hearing communication-access services | The operating company — a roll-up add-on for **Applied Development** |
| **2 — SBIC** | Licensed Small Business Investment Companies | The **GP / management entity that holds the SBA SBIC license** — never the portfolio companies |

**Class-2 government fact carried on every record:** acquiring a licensed SBIC
requires **SBA prior approval** of the change of control (a closing condition).

---

## Search keys — VERIFIED

| Key | Value | Status | Use |
|---|---|---|---|
| **NAICS** | `541930` — Translation and Interpretation Services | CONFIRMED (2022 NAICS, in force 2026). Definition explicitly includes "providing sign language services." | Class-1 discovery net. Broader than Class 1 (also covers spoken-language translation) — the keyword filter below isolates ASL providers. No narrower code exists. |
| **PSC** | `R608` — Support — Administrative: Translation and Interpreting Services (Including Sign Language) | CONFIRMED (current PSC Manual = April 2025 edition). PRD "low confidence" flag CLEARED. | Class-1 contract-award discovery. Operator spot-check: row R608 in `PSC April 2025.xlsx` from acquisition.gov. |
| **GSA MAS SIN** | `541930` — Translation and Interpretation Services (SIN = NAICS post-MAS-consolidation). Adjacent: SIN `611630` Linguistic Training and Education. | CONFIRMED | Class-1 discovery via GSA eLibrary. |
| **SBIC NAICS** | none used | The SBA SBIC directory supersedes NAICS for Class 2. Do not guess a NAICS. | — |

### Class-1 keyword strategy

**Core terms** (a hit on any → candidate is a core Class-1 ASL/deaf-services
provider, line-10 roll-up bonus = 10):

`ASL` · `American Sign Language` · `sign language` · `sign-language interpreting`
· `interpreting` · `interpreter` · `CART` · `realtime captioning` ·
`real-time captioning` · `communication access` · `CART captioning` · `VRI` ·
`video remote interpreting` · `VRS` · `deaf` · `hard of hearing` ·
`hard-of-hearing` · `HoH` · `deaf services` · `deaf and hard of hearing` ·
`captioning services`

**Exclusion / down-weight terms** (only these, no core term → mark **"adjacent"**,
line-10 bonus = 5, lower priority — per §13 Q3, adjacents are surfaced not
hard-excluded):

`document translation` · `localization` · `foreign language` (alone) ·
`language learning` · `subtitling software`

### Class-2 keyword strategy

`SBIC` · `Small Business Investment Company` · `SBA license` · `debenture` ·
`accrual debenture` · `fund management` · plus the management-company name. The
SBA SBIC directory (below) is the authoritative key; keywords enrich only.

**SBIC scope (B2):** default = **all licensed SBIC types** (Standard Debenture,
Accrual, Reinvestor, non-leveraged). The good-standing gate and
`prospect-evaluation` SBIC mode do the filtering. Operator may narrow — see B2.

---

## Sources

Ordered by build priority. Each adapter (built in s3) filters by NAICS/PSC + the
keyword strategy and returns a normalized raw-record object. The source layer is
**swappable** — the FPDS decommission is the cautionary tale.

### S1 — USAspending.gov  *(PRIMARY award source — Class 1)*
- **What:** federal prime + sub-award data and recipient profiles.
- **Access:** public REST API, **no authorization / no key required**.
- **Base:** `https://api.usaspending.gov`
- **Key endpoints:**
  - `POST /api/v2/search/spending_by_award/` — award search; filter by NAICS
    `541930`, PSC `R608`, recipient name, time period, award type, place of
    performance.
  - `POST /api/v2/bulk_download/awards/` and `/api/v2/download/awards/` — bulk
    download (prefer for large pulls).
  - NAICS/PSC autocomplete endpoints — validate codes.
- **Extract:** recipient name, UEI, legacy DUNS, parent recipient, recipient
  location, award NAICS/PSC, amounts/dates, awarding agency, business-type flags.
  Recipient total-awards = a size proxy.
- **Rate limit / ToS:** no documented hard per-IP rate limit — use courteously,
  prefer bulk download for large pulls. Data is U.S. Government work.
- **Serves:** Class 1 (primary). Status: **not blocked.**

### S2 — SAM.gov Entity Management API  *(Class 1 — entity discovery + enrichment)*
- **What:** authoritative registry of entities; NAICS, socioeconomic flags,
  addresses, POC.
- **Access:** **API key required** — the SAM.gov "Public API Key" from
  `sam.gov/profile/details`, sent as the `x-api-key` header.
- **Base:** `https://api.sam.gov/entity-information/v1` … `v4` (use the current
  version at build time).
- **Extract:** legal name + DBA, UEI, CAGE, legacy DUNS, physical/mailing
  address, NAICS list, socioeconomic flags, registration status/dates, public POC.
  Public tier only — never request FOUO / Sensitive tiers.
- **Rate limit:** non-federal **no-role account = 10 requests/day** (unusable);
  **role-assigned account = 1,000/day**. Operator must get a role assigned.
- **Serves:** Class 1. Status: **blocked above 10/day by B3** (SAM.gov account +
  keyed role). Adapter is built in s3; live use beyond 10/day waits on B3.

### S3 — SAM.gov Contract Awards API  *(FPDS-NG successor — Class 1)*
- **What:** federal contract-award data — the replacement for the decommissioned
  FPDS-NG. **Do NOT build on fpds.gov or the FPDS ATOM feed** (FPDS.gov public
  site + ezSearch retired; ATOM feed scheduled for FY2026 decommission).
- **Access:** API key required (same SAM.gov key family).
- **Base / docs:** `https://open.gsa.gov/api/contract-awards/`
- **Extract:** contractor name, UEI, NAICS/PSC of award, award $ and dates,
  contracting agency, place of performance, small-business flags.
- **Use:** cross-check / supplement USAspending (which stays primary).
- **Serves:** Class 1. Status: **blocked by B3** (same key).

### S4 — SBA SBIC Directory  *(PRIMARY source — Class 2)*
- **What:** the official directory of currently-licensed SBICs.
- **Access:** **live filterable web directory** with a **"Download CSV"** export.
  Approach = download-and-diff the CSV each run.
- **URLs:** directory `https://www.sba.gov/funding-programs/investment-capital/sbic-directory`
  · CSV export `https://www.sba.gov/export/contacts/sbic`
- **Publishes per licensee:** fund name, city/state, "Managed by" (management
  company / GP), vintage year, fund size, average investment, investment
  strategy, fund style, "making new investments?" flag, investor-relations
  contact (name, email, phone).
- **Does NOT publish:** SBA license number, a license-status / "good standing"
  flag, or outstanding SBA leverage. Appearing on the directory establishes the
  entity is **currently licensed**; **good standing must be cross-checked**
  (S5 below) — see the SBIC good-standing check.
- **Count note:** ~318 licensed SBICs reported as of 2024-09-30 — re-pull the
  live count each run.
- **Serves:** Class 2 (primary). Status: **not blocked** (CSV is public).

### S5 — SBIC good-standing cross-check  *(Class 2 — gate input)*
- **What:** the §7.3 SBIC gate ("active and in good standing") cannot be
  confirmed from the directory alone. Cross-check each licensee against:
  - SBA enforcement actions / SBIC license actions,
  - SBA Office of Inspector General (OIG) reports,
  - SBIC license actions published in the **Federal Register**.
- **Result feeds:** the `SBIC License Status` Airtable field
  (Good Standing / Under Review / Surrendered / Revoked / Unknown).
- **Serves:** Class 2. Status: **not blocked.**

### S6 — SBA Small Business Search (SBS)  *(Class 1 — formerly DSBS)*
- **What:** the SBA's searchable database of small businesses with an **active
  SAM registration**. **Renamed from DSBS to "Small Business Search (SBS)" in
  July 2025.** `dsbs.sba.gov` redirects to SBS.
- **Access:** UI search (treat as UI-only until a programmatic interface is
  proven). USAspending + the SAM Entity API already cover most of the same firms.
- **URL:** `https://dsbs.sba.gov/` (redirects to SBS)
- **Serves:** Class 1 (supplementary). Status: **not blocked.**

### S7 — GSA eLibrary  *(Class 1)*
- **What:** GSA Multiple Award Schedule contract holders for language services —
  vetted, established providers.
- **Access:** browse UI; GSA also publishes a contractor-list spreadsheet for
  the SIN.
- **URL:** `https://www.gsaelibrary.gsa.gov/ElibMain/sinDetails.do?scheduleNumber=MAS&specialItemNumber=541930&executeQuery=YES`
- **Serves:** Class 1. Status: **not blocked.**

### S8 — Priority-state procurement portals + Secretary-of-State registries  *(Class 1)*
- **What:** state contracts for ASL/CART interpreting (courts, education,
  vocational rehab) and SOS business registries (formation date, status, officers
  — used for enrichment & entity resolution).
- **Access:** non-uniform — each state has its own portal and ToS; some prohibit
  bulk extraction. Each chosen state's terms must be confirmed before automating.
- **Serves:** Class 1 (Phase 1, per §13 Q6). Status: **blocked by B1** — the
  operator must name the priority states. Priority-state list: _(pending B1)_.

### S9 — RID (Registry of Interpreters for the Deaf)  *(Class 1 — supplementary)*
- **What:** non-profit registry of sign-language interpreters/agencies (`rid.org`).
- **Access:** member search at `https://myaccount.rid.org/Public/Search/Member.aspx`.
  **Point-of-need enrichment / contact lookup ONLY** — query while working a
  specific candidate. **Do NOT bulk-copy** the member directory into Airtable
  (RID's terms instruct against external-database copying).
- **Serves:** Class 1 (supplementary, never a core discovery source). Status:
  **not blocked** (constrained use only).

### S10 — IAPD / adviserinfo.sec.gov (Form ADV)  *(Class 2 — enrichment)*
- **What:** investment-adviser disclosures for SBIC GPs that are registered RIAs
  or Exempt Reporting Advisers — AUM, principals, fund vintage. **Form ADV is in
  IAPD, NOT SEC EDGAR.**
- **Access:** IAPD `https://adviserinfo.sec.gov/`; SEC bulk "Form ADV Data" CSV
  at `https://www.sec.gov/data-research/sec-markets-data/information-about-registered-investment-advisers-exempt-reporting-advisers`.
- **Coverage caveat:** only SBIC GPs that are RIAs/ERAs file — enriches *some*
  Class-2 targets, not all.
- **Serves:** Class 2 (enrichment). Status: **not blocked.**

### S11 — U.S. Courts interpreter procurement  *(Class 1 — low value, deprioritized)*
- **What:** the National Court Interpreter Database (NCID) and district-court
  interpreter info.
- **Why low value:** federal courts contract **individual** interpreters, not
  firms; there is no machine-readable national list of interpreting *companies*.
- **Use:** enrichment cross-reference only — not a discovery source.
- **URL:** `https://www.uscourts.gov/court-programs/federal-court-interpreters`
- **Serves:** Class 1 (deprioritized). Status: **not blocked.**

---

## Entity identifiers (for resolution — s4)

Priority order: **UEI** (12-char SAM.gov Unique Entity Identifier — primary key)
→ **CAGE code** → **legacy DUNS** (only as a bridge on pre-2022 award rows; the
government retired DUNS on 2022-04-04) → normalized name + address (probable
match, requires confirmation). For Class 2 also: **SBA SBIC license number**.

---

## Airtable target

Base `appOsvuyy5eK43QTx`, table `tblSmNrHROMLm7vOS` ("Master Deal Pipeline") —
the **same** table as on-market leads. New `Source` values and new fields are
created by build-loop stage s2 (see `OFFMARKET_BUILD_PLAN.md` s2 and PRD §8).

---

## Compliance posture

- API or bulk download **over scraping**, always. Respect `robots.txt`, rate
  limits, and each source's ToS.
- No scraping behind logins or paywalls.
- SAM.gov: public tier only — never request FOUO / Sensitive data.
- RID: point-of-need lookup only, no bulk copy.
- State portals: confirm each state's terms before automating (S8 / B1).
- See PRD §11 for the full compliance & legal notes.
