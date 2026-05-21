# PRD — Off-Market Target Search

| | |
|---|---|
| **Document** | Product Requirements Document — Off-Market Target Search |
| **Version** | 1.0 (draft for operator review) |
| **Date** | 2026-05-21 |
| **Owner** | Biffrey Braxton (bb@braxton.ai) |
| **Status** | Planning pass — produced by the `OFFMARKET_LOOP_PROMPT.md` Ralph loop. Not yet operator-approved. |
| **Canonical spec** | `Off-Market Search/OFFMARKET_PRD_SPEC.md` |
| **Final deliverable path** | `~/published-listing-search/Off-Market Search/PRD_OFF_MARKET_SEARCH.md` |

> **⚠ Reading note.** This is a *planning* document. Every item prefixed
> **`⚠ VERIFY:`** is an assumption, code, API detail, or statistic that the
> author is **not certain of** and that the operator must confirm from the
> primary source before any build. They are *not* stated as fact. A
> consolidated list of all `⚠ VERIFY:` items is in §13.

---

## Table of Contents

1. Executive Summary
2. Objective, Success Metrics, Scope & Non-Goals
3. The Two Target Classes
4. Per-Source Methodology
5. Search Keys & Keyword Strategy
6. Entity Resolution & De-Duplication
7. Qualification — Raw Record → Scored Prospect
8. Data Schema — Field-by-Field Mapping to the Tracker
9. Workflow & Cadence
10. Integration Plan
11. Compliance & Legal Notes
12. Risks
13. Open Questions & Consolidated Verification Checklist

---

## 1. Executive Summary

The EarnedOut acquisition pipeline today sources **on-market** businesses —
companies actively listed for sale on DealStream, BizBuySell, BizQuest, etc. —
via the `overnight-search` and `submit-url` skills, scores them with the
`prospect-evaluation` skill, and tracks them in one Airtable table.

This PRD specifies an **Off-Market Target Search** system: a new *intake
front-end* that surfaces acquisition targets which are **not listed for sale**,
sourced from U.S. government / open-data systems, and routes them into the
**exact same** tracker, scorer, dashboard, and review cadence. It is explicitly
**not** a parallel system — an off-market record and an on-market record are
interchangeable rows in the same Airtable table.

Two target classes are in scope:

1. **ASL platform bolt-ons** — operating companies in sign-language
   interpretation, CART / realtime captioning, VRI, and related deaf / hard-of-
   hearing communication-access services, acquirable as roll-up add-ons to the
   platform company **Applied Development**.
2. **SBIC firms acquired outright** — the GP / management entity that holds an
   SBA SBIC license, where the strategic prize is the license itself.

The system mines federal / state open data (FPDS-NG, SAM.gov, USAspending.gov,
the SBA SBIC directory, SBA DSBS, GSA eLibrary, and state registries) to
identify these companies, resolves them to single entities, de-duplicates
against the pipeline, and hands each qualified target to the existing
`prospect-evaluation` skill for scoring.

---

## 2. Objective, Success Metrics, Scope & Non-Goals

### 2.1 Objective

Build a repeatable, mostly-automated intake pipeline that discovers off-market
acquisition targets in the two target classes from government open data, and
delivers them as fully-scored prospects into the existing Master Deal Pipeline
tracker — interchangeable with on-market leads.

### 2.2 Success Metrics

| Metric | Target (operator to confirm) |
|---|---|
| Off-market targets surfaced per monthly run | ⚠ VERIFY: operator to set a target (e.g., ≥ 25 class-1 + ≥ all-licensed class-2) |
| Qualified (scored) prospects added to Airtable per run | ⚠ VERIFY: operator to set |
| Precision — surfaced targets that are genuinely in-scope operating companies | ≥ 80% (proposed) |
| Duplicate rate — targets already in the tracker re-surfaced as "new" | < 5% (proposed) |
| Entity-resolution accuracy — distinct gov records correctly merged to one company | ≥ 95% (proposed) |
| Coverage of licensed SBICs reviewed against the SBA directory | 100% of the current directory each run |
| Mean time from gov-record discovery to scored Airtable record | ⚠ VERIFY: operator to set |

All proposed numbers above are **starting points** — operator to confirm or
replace (see §13).

### 2.3 Scope

- Two target classes only (§3).
- U.S. government / open-data sources only (§4).
- Output is **scored prospects in the existing Airtable tracker** plus the
  existing daily dashboard and `search_reports/` artifacts.
- A new intake skill (proposed name `off-market-search`) and a new manual-add
  path mirroring `submit-url`.

### 2.4 Non-Goals (explicit)

- **No parallel tracker.** Off-market records live in the same Airtable base
  `appOsvuyy5eK43QTx`, table `tblSmNrHROMLm7vOS`.
- **No new scoring system.** Qualification reuses the `prospect-evaluation`
  skill and `references/buy-box-and-scoring.md` verbatim. No new scorecard.
- **No live searches in this planning pass.** This PRD does not query FPDS/SAM/
  USAspending/SBA; it specifies how to.
- **No outreach automation beyond the existing drafting behavior.** Email is
  never sent automatically (consistent with the on-market skills).
- **Not acquiring SBIC portfolio companies** — class 2 targets the management
  company / license only.
- **No paid data brokers, no scraping behind authentication or paywalls** for
  off-market sourcing — government open data only.

### 2.5 How This Integrates With the Existing On-Market System

The off-market pipeline is a **front-end swap**: it replaces "search broker
listing sites" with "mine government open data," then re-uses every downstream
stage the on-market skills already use — Playwright/website enrichment,
de-duplication against Airtable, the `prospect-evaluation` skill, Airtable
record creation, outreach drafting, and the daily dashboard. See the on-market
summary in `_ralph/evidence/onmarket-system-summary.md`.

---

## 3. The Two Target Classes

### 3.1 Target Class 1 — ASL Platform Bolt-Ons

**Definition.** Operating companies whose business is sign-language
interpretation, CART / realtime captioning, video remote interpreting (VRI), or
related deaf / hard-of-hearing communication-access services.

**Why.** Biffrey already owns the platform company **Applied Development**, a
translation & interpretation business (per `references/buy-box-and-scoring.md`,
valued at ~6.5x). Class-1 targets are **roll-up add-ons** to Applied
Development. The Buy Box reference grants Applied Development add-ons **no size
floor** — every acquirable target in this space is worth evaluating regardless
of EBITDA / employee count / age.

**"Off-market"** = the company is a going concern **not currently listed for
sale** on any business-for-sale marketplace. We infer acquirability from
indirect signals (owner age / tenure, small single-location operators, long
operating history) rather than a "for sale" listing.

**The acquisition target** is the **operating company** itself.

**In scope:** ASL interpreting agencies; CART/captioning providers; VRI
providers; deaf-services / communication-access agencies; court / educational /
medical interpreting firms with a sign-language line of business.

**Out of scope (or low priority):** pure spoken/foreign-language translation
firms with no sign-language line — flag as "adjacent" only (the Buy Box line-10
bonus gives adjacents 5 vs 10); language-learning software; captioning *software*
vendors with no services business. ⚠ VERIFY: operator to confirm whether
spoken-language-only translation firms should be surfaced at all, given NAICS
541930 covers both (see §5).

### 3.2 Target Class 2 — SBIC Firms Acquired Outright

**Definition.** A licensed **Small Business Investment Company** where the
acquisition target is the **general partner / management entity that holds the
SBA SBIC license** (and, with SBA approval, the associated fund) — **not** the
SBIC's portfolio companies.

**Why.** Per `references/buy-box-and-scoring.md` §"SBIC targets": acquiring a GP
that holds a license already in good standing "short-circuits the lengthy de
novo SBA SBIC licensing process." The license is the prize.

**The acquisition target** is the **GP / management company / licensee entity** —
explicitly **not** the fund's portfolio companies.

**Acquirability signals (off-market):** aging fund managers; wind-down or
end-of-life fund vintages; single-GP shops with succession risk; dormant or
inactive licensees; SBICs that have stopped making new investments.

**Hard gate (from the Buy Box reference):** the SBIC license must be **active
and in good standing** (no revocation, surrender, capital impairment, or
outstanding SBA enforcement action). Any change of control of a licensed SBIC
**requires SBA approval** — a closing condition, not a screening gate.

**In scope:** all entity types on the SBA's licensed-SBIC directory —
Debenture, and ⚠ VERIFY: whether Leverage/Equity, "Early Stage," Reinvestor, and
any current SBIC program variants are all in scope or only some.

**Out of scope:** SBIC *applicants* not yet licensed; surrendered / revoked
licensees (fail the gate); the portfolio companies themselves.

---

## 4. Per-Source Methodology

> Every source below is U.S. government / open data. For each: what it is, why
> it matters, which target class it serves, how to query it, what to extract,
> the access method, and rate-limit / ToS notes. **All NAICS/PSC codes, API
> endpoints, parameter names, and rate limits are `⚠ VERIFY:` items** — the
> figures here are best-effort starting points, not confirmed fact.

### 4.1 FPDS-NG — Federal Procurement Data System

- **What / why.** Federal contract *award* history. Companies that have **won
  federal interpretation / captioning / CART contracts** are, by definition,
  real operating providers — an excellent class-1 discovery source.
- **Serves:** Class 1 (primary). Class 2: minimal (SBICs are not contractors).
- **Query approach.** Search awards by **NAICS** and **PSC** (see §5) and by
  contractor name keywords; filter by award date window (e.g., last 5 years) to
  bias toward active firms.
- **Extract:** Vendor/contractor legal name + DBA; **UEI** and (legacy) **DUNS**;
  vendor address; NAICS/PSC of the award; award $ and dates; contracting
  agency; place of performance; small-business / socioeconomic flags.
- **Access method.** ⚠ VERIFY: FPDS-NG historically exposes (a) a web search UI
  at fpds.gov and (b) an **ATOM feed / web-services interface** for programmatic
  pulls. ⚠ VERIFY: significant FPDS contract-data functions have been migrating
  into **SAM.gov** and are also mirrored in **USAspending.gov** — confirm the
  current canonical programmatic endpoint before building. **Recommendation:**
  treat **USAspending.gov (§4.3) as the primary programmatic award source** and
  FPDS-NG as a cross-check, because USAspending has a stable documented public
  API.
- **Rate-limit / ToS.** ⚠ VERIFY: FPDS-NG ATOM feed pagination limits and any
  throttling; ⚠ VERIFY: terms of use for automated access.

### 4.2 SAM.gov — System for Award Management

- **What / why.** The authoritative registry of entities doing business with
  the federal government — entity registrations, NAICS codes, socioeconomic /
  small-business status, and an opportunities (solicitations) feed.
- **Serves:** Class 1 (entity discovery + enrichment). Class 2: low.
- **Query approach.**
  - **Entity Management** — search registered entities by NAICS (§5) and by
    name keywords; filter by registration status (active) and entity location.
  - **Contract Opportunities** — search current/closed solicitations by NAICS/
    PSC + keywords to find agencies *buying* interpretation/captioning, then
    follow to the incumbents/awardees.
- **Extract:** Legal business name + DBA; **UEI**, **CAGE code**, legacy DUNS;
  physical address; NAICS list (primary + all); socioeconomic flags
  (small business, 8(a), WOSB, SDVOSB, HUBZone); registration status & dates;
  POC where public.
- **Access method.** ⚠ VERIFY: SAM.gov provides public **APIs at `api.sam.gov`**
  (Entity Management API, Opportunities API). ⚠ VERIFY: the Entity Management
  API requires a **SAM.gov account + system account / API key**, and some
  entity fields (e.g., FOUO data) are restricted to roled accounts; public/
  non-sensitive entity data is available at a lower tier. Confirm exactly which
  fields are available at the public tier and whether a key is required.
- **Rate-limit / ToS.** ⚠ VERIFY: per-key daily request quotas; ⚠ VERIFY:
  SAM.gov data-use terms — public extracts are generally permitted; restricted
  data must not be redistributed.

### 4.3 USAspending.gov

- **What / why.** Federal award & recipient data — prime awards and sub-awards —
  with the **best-documented, key-free public REST API** of the federal award
  systems. Recommended **primary programmatic award source** for class 1.
- **Serves:** Class 1 (primary). Class 2: low.
- **Query approach.** ⚠ VERIFY: the award-search API (`api.usaspending.gov`,
  e.g. the `/api/v2/search/spending_by_award/` endpoint and recipient endpoints)
  accepts filters by **NAICS**, **PSC**, recipient name, time period, award
  type, and place of performance. Also offers **bulk award downloads**.
- **Extract:** Recipient name + UEI + (legacy) DUNS + parent recipient; recipient
  location; award NAICS/PSC; award amounts & dates; awarding agency; business-
  type flags. Recipient profile pages aggregate total awards per recipient —
  useful as a size proxy.
- **Access method.** ⚠ VERIFY: public REST API, **no API key required**;
  documented at the USAspending API docs site; bulk "Custom Award Data" download
  and the full database download also available.
- **Rate-limit / ToS.** ⚠ VERIFY: confirm any per-IP rate limits; data is public
  domain (U.S. Government work) but confirm attribution / bulk-use terms.

### 4.4 SBA.gov — SBIC Program Directory  *(primary source for Class 2)*

- **What / why.** The SBA publishes the official list of **licensed SBICs**.
  This is the **primary discovery source for target class 2** — it enumerates
  every entity that holds the license we want to acquire.
- **Serves:** Class 2 (primary).
- **Query approach.** ⚠ VERIFY: the SBA SBIC Program publishes a **directory /
  list of licensed SBICs** (the author believes this is released periodically
  as a downloadable Excel/PDF on the SBA's SBIC / Office of Investment &
  Innovation pages, and possibly via SBA open-data datasets). Confirm the exact
  current URL, file format, and refresh cadence. Pull the **entire list** each
  run — class 2 is small enough to review exhaustively.
- **Extract per licensee:** SBIC legal name; **SBA license number**; licensee
  type / program (Debenture, etc.); license status (active / good standing);
  license / commitment date (vintage); management company / GP name; city/state;
  ⚠ VERIFY: whether the directory also publishes leverage outstanding, fund size,
  or principals — if not, enrich from §4.5 / state registries / the firm's site.
- **Access method.** ⚠ VERIFY: most likely a periodic file download (not a live
  API). Plan for a download-and-diff approach.
- **Rate-limit / ToS.** Static file download — negligible rate concern. ⚠ VERIFY:
  SBA data-use terms.
- **Good-standing check.** ⚠ VERIFY: how to confirm "active and in good
  standing" — the directory's status column, plus checking for SBA enforcement
  actions / OIG reports. This feeds the §7 SBIC gate.

### 4.5 SBA Dynamic Small Business Search (DSBS)  *(Class 1)*

- **What / why.** DSBS is the SBA's searchable database of small businesses
  registered in SAM, with capability-narrative profiles. Good for class-1
  discovery of small interpretation/captioning firms that may never have won a
  federal contract but are registered.
- **Serves:** Class 1.
- **Query approach.** ⚠ VERIFY: search DSBS (historically `dsbs.sba.gov`) by
  **NAICS** (§5) and keyword; filter by state. ⚠ VERIFY: DSBS / SBA small-
  business profile systems have been undergoing consolidation (certifications
  moved to `certify.SBA.gov`); confirm the current live DSBS URL and whether a
  programmatic interface exists or it is UI-only.
- **Extract:** Firm name; address; NAICS codes; capability narrative; ownership /
  socioeconomic certifications; contact; UEI where shown.
- **Access method.** ⚠ VERIFY: likely UI search; confirm export / API options.
- **Rate-limit / ToS.** ⚠ VERIFY.

### 4.6 GSA eLibrary / GSA Advantage  *(Class 1)*

- **What / why.** Firms holding a **GSA Multiple Award Schedule** contract for
  language / interpretation services are vetted, established providers. ⚠ VERIFY:
  the relevant schedule / SIN for interpretation & translation (historically
  language services fell under a Language Services SIN on the Professional
  Services / MAS schedule — confirm the current SIN).
- **Serves:** Class 1.
- **Query approach.** Search GSA eLibrary (`gsaelibrary.gsa.gov`) by the
  language-services SIN and by keyword; cross-reference contractors on GSA
  Advantage.
- **Extract:** Contractor name; contract number; SIN(s); location; contact.
- **Access method.** ⚠ VERIFY: UI search; confirm any data export.
- **Rate-limit / ToS.** ⚠ VERIFY.

### 4.7 Additional .gov Sources (each with rationale)

| Source | Rationale | Class |
|---|---|---|
| **U.S. Courts interpreter procurement** | Federal courts contract court interpreters, including sign-language; the Administrative Office of the U.S. Courts and individual district courts publish interpreter contract/vendor info. Surfaces specialized court-interpreting firms. ⚠ VERIFY: where this data is published and whether it is machine-readable. | 1 |
| **State procurement portals** | States contract heavily for ASL/CART interpreting (courts, education, vocational-rehab agencies). Each state's eProcurement portal lists awarded vendors. ⚠ VERIFY: no single national source — would require per-state targeting; prioritize high-population / priority-geography states. | 1 |
| **State Secretary of State business registries** | Confirm a candidate company legally exists, its formation date (feeds the Buy Box "years in business" check), registered agent, officers, and status (active / good standing). Used for **enrichment & entity resolution**, not primary discovery. ⚠ VERIFY: each state SOS has its own search; some offer bulk data / APIs, many are UI-only. | 1 & 2 |
| **State / federal vocational rehabilitation & education agency vendor lists** | VR agencies and school districts are major buyers of communication-access services; their approved-vendor lists name local providers. ⚠ VERIFY: availability varies by state. | 1 |
| **SEC EDGAR (Form ADV / investment-adviser filings)** | Some SBIC GPs are also registered investment advisers; EDGAR / IAPD filings enrich class-2 targets (AUM, principals, fund vintage). ⚠ VERIFY: coverage — not all SBIC GPs file. | 2 |
| **Registered Interpreter directories — RID** | The Registry of Interpreters for the Deaf publishes member/agency information. ⚠ VERIFY: RID is a **non-profit, not a .gov source** — include only if its terms permit; treat as supplementary, not a core gov source. | 1 |

> ⚠ VERIFY: state-by-state portals and SOS registries are high-effort and
> non-uniform. Recommendation: **Phase 1 uses only the federal sources (§4.1–4.6);
> state sources are a Phase 2 expansion** — operator to confirm prioritization.

---

## 5. Search Keys & Keyword Strategy

### 5.1 NAICS / PSC codes — candidates, MUST be verified

> **These codes are starting points, NOT confirmed.** The operator must verify
> the exact current codes from the primary source (Census NAICS manual; the
> federal PSC manual) before any build.

- **⚠ VERIFY: NAICS 541930 — "Translation and Interpretation Services."** The
  internal `references/buy-box-and-scoring.md` already associates Applied
  Development with NAICS 541930. **Caveat:** 541930 covers **both** sign-language
  *and* spoken/foreign-language translation & interpreting — it is **broader**
  than target class 1. Use 541930 as the discovery net, then keyword-filter
  (§5.2) to isolate sign-language / CART providers. ⚠ VERIFY: that 541930 is
  current and correct, and whether any adjacent NAICS (e.g., other 5419
  professional-services codes, or disability-services codes) should be added.
- **⚠ VERIFY: PSC R608 — translation/interpreting support services.** This is a
  *candidate only* and the author has **low confidence** it is the correct
  current code. Confirm the exact current PSC for translation/interpreting
  services from the federal PSC manual before use.
- **⚠ VERIFY: SBIC NAICS** — for class 2, the SBA SBIC directory (§4.4) is the
  primary key, not NAICS; an SBIC GP might appear under NAICS 523910/523999
  (investment activities) ⚠ VERIFY — but the directory supersedes NAICS here.

### 5.2 Keyword Strategy (Class 1)

Apply these as full-text filters against names, capability narratives, contract
descriptions, and websites — to isolate sign-language/deaf-services providers
from the broader 541930 population:

`ASL` · `American Sign Language` · `sign language` · `sign-language interpreting`
· `interpreting` / `interpreter` · `CART` · `realtime captioning` /
`real-time captioning` · `communication access` · `CART captioning` · `VRI` /
`video remote interpreting` · `VRS` · `deaf` · `hard of hearing` / `hard-of-
hearing` · `HoH` · `deaf services` · `deaf and hard of hearing` · `captioning
services`.

**Exclusion / down-weight terms** (mark as "adjacent" not "core"): `document
translation`, `localization`, `foreign language` *only*, `language learning`,
`subtitling software`.

### 5.3 Keyword Strategy (Class 2)

For SBIC enrichment: `SBIC`, `Small Business Investment Company`, `SBA license`,
`debenture`, `fund management`, plus the management-company name. The directory
(§4.4) is the authoritative key; keywords are for enrichment only.

---

## 6. Entity Resolution & De-Duplication

### 6.1 Resolving the Same Company Across Government Sources

A single company appears in FPDS-NG, SAM.gov, USAspending, and DSBS under
slightly different names and addresses. Resolve to one canonical entity using,
in priority order:

1. **UEI (Unique Entity Identifier)** — the current government-wide entity key
   (12-character SAM.gov UEI). **Primary match key** — exact UEI match = same
   entity. Present in SAM.gov, USAspending, and post-2022 FPDS records.
2. **CAGE code** — secondary key; present in SAM.gov and many award records.
3. **Legacy DUNS** — for pre-2022 records that predate UEI. ⚠ VERIFY: DUNS was
   retired as the government key in 2022; older award rows may still carry it —
   use only as a fallback bridge to UEI.
4. **Normalized name + address** — when no shared identifier exists (e.g., a
   DSBS-only firm vs. a USAspending recipient): normalize legal name (strip
   `LLC/Inc/Corp/&/punctuation`, lowercase), normalize address (USPS-style), and
   match on name + ZIP/city-state. Treat as a **probable** match requiring
   confirmation, not an exact match.

**Output of resolution:** one canonical record per company carrying its UEI,
CAGE, DUNS (if any), all known names/DBAs, address, and the list of source
systems it was found in.

### 6.2 De-Duplication Against the Existing Tracker

Before creating any Airtable record, check the candidate against table
`tblSmNrHROMLm7vOS` — consistent with the on-market dedup logic in
`REVAMP_PLAN.md` Step 2e and `overnight-search` skill Step 5:

- **Match key A — government identifier.** Match the candidate UEI/CAGE against
  a stored government identifier on existing records (requires the new
  `Gov Entity ID` field — §8). Exact match → existing record.
- **Match key B — name + address.** Normalized Business Name + Business Address
  match (the existing on-market dedup logic). Match → existing record.
- **Match key C — SBIC license number** (class 2 only) — match the candidate
  SBA license number against the stored license number.

**On a match:** do **not** create a duplicate. Update `Link Last Checked` /
`Date Updated`, refresh any newly-available gov data, and — if the record was
sourced on-market and the off-market run found materially new info — append a
note rather than overwriting. **Never re-surface a target already in the tracker
as a "new" lead** (this protects the §2.2 duplicate-rate metric).

**Cross-run dedup within off-market itself:** maintain the resolved-entity set
(§6.1) so the same company found via FPDS *and* USAspending in one run produces
one candidate, not two.

⚠ VERIFY: the on-market dedup currently keys on Business Name + Business Address
and `Listing ID`; off-market records have no `Listing ID`. Confirm with the
operator that adding `Gov Entity ID` as the off-market analogue of `Listing ID`
is acceptable (see §8).

---

## 7. Qualification — Raw Record → Scored Prospect

A raw government record is **not** a prospect until it has been enriched and
scored. Qualification reuses the **existing** `prospect-evaluation` skill — **no
new scoring is defined here.**

### 7.1 Pipeline (both classes)

1. **Resolve & de-dup** (§6). Drop anything already in the tracker.
2. **Enrich.** Government records are thin (name, address, NAICS, award
   history). Enrich each candidate with: the company website (find via search;
   Playwright-validate, screenshot — reusing `overnight-search` Step 3 logic);
   formation date from the state SOS (§4.7) for the Buy Box "years in business"
   check; employee-count and revenue signals from the website / award totals;
   ownership and broker/contact info. Fields not found are marked **"needs
   follow-up"** — **never fabricated** (consistent with the on-market skills).
3. **Build the lead packet** — the same structured-data object the
   `overnight-search` skill passes to the scorer (business name, industry,
   location, financials, employees, asking price [usually blank off-market],
   contact, URL, screenshot path).
4. **Invoke `prospect-evaluation`** — see §7.2 / §7.3 for the per-class mode.
5. **Capture** the 0–100 (or /110) lead score and the `.md` + `.html` report to
   `output/reports/{entity-id}/`.
6. **Create the Airtable record** (§8) and draft outreach where a contact
   exists (§9/§10).

### 7.2 Class 1 — Roll-Up Add-On Mode

Class-1 targets are scored as **roll-up add-ons for Applied Development**. Per
`references/buy-box-and-scoring.md`:

- The scorer applies the **"Applied Development add-on" path: no size floor** —
  the target is never rejected for being too small.
- Buy Box verdict can be **CONDITIONAL (add-on)** rather than FAIL.
- Lead score is on the **/110** scale (line-10 roll-up bonus: **10** for a
  direct ASL/CART add-on, **5** for an adjacent niche).
- Interpretation bands: the add-on bands apply (95–110 top-tier; 80–94 strong;
  60–79 partner review; <60 weak).

**Off-market specifics:** there is usually **no asking price** (the company is
not for sale), so Buy Box check 5 and rubric line 8 (valuation multiple) will be
**"insufficient data — not awarded"** — this is expected and correct, not a
failure. The score reflects the business's quality; pricing is established later
in a proprietary approach.

### 7.3 Class 2 — SBIC Mode

Class-2 targets are scored in the scorer's **SBIC mode**. Per
`references/buy-box-and-scoring.md` §"SBIC targets":

- **Gate (the only thing that drives the verdict):** the SBIC license is
  **active and in good standing**. PASS if confirmed; FAIL if not; **CONDITIONAL
  if good standing cannot yet be confirmed.**
- Standard financial Buy Box checks are **reported but non-gating**.
- The 0–100 score is **informational only**.
- Pull and show GP economics as informational context: management-fee revenue,
  EBITDA, FTE, AUM / committed capital, outstanding SBA leverage, fund vintage
  and remaining life.
- Note that **change of control requires SBA approval** — a closing condition.

The off-market intake's job for class 2 is to (a) confirm the licensee is on the
current directory and flagged in good standing, and (b) gather the GP economics
above before invoking the scorer.

### 7.4 Qualification Filters Before Scoring (cost control)

To avoid scoring obvious non-fits, apply cheap pre-filters first: class 1 —
keyword filter (§5.2) must indicate a sign-language/deaf-services line, and the
entity must be a U.S. operating company; class 2 — must be a current licensee in
good standing. Only candidates passing the pre-filter are enriched and scored.

---

## 8. Data Schema — Field-by-Field Mapping to the Tracker

Off-market records are written to the **same** Airtable base `appOsvuyy5eK43QTx`,
table `tblSmNrHROMLm7vOS` ("Master Deal Pipeline"). They must be
**interchangeable** with on-market records.

### 8.1 Existing fields — reused as-is

| On-market field | Off-market intake value |
|---|---|
| Business Name | Resolved canonical company / SBIC GP name |
| Industry Match | "Sign Language / CART (Applied Development add-on)" (class 1) or "SBIC" (class 2) |
| Business Address | Resolved address (SAM.gov / SOS) |
| Website | Company website (found + Playwright-validated) |
| Links (`fldwo7ui7aIGoMxAG`) | Source government record URL(s) — FPDS/USAspending/SAM/SBA pages |
| Lead Source | Government source system(s) the target came from |
| Broker Name | Usually blank off-market — replaced by a direct contact (owner / GP principal) |
| Asking Price | Blank off-market (company not listed for sale) |
| EBITDA / EBITDA Margin / Years in Business / Qty FT Employees | From enrichment; blank → "needs follow-up" |
| NAICS Code | NAICS from the gov record (e.g., 541930 — ⚠ VERIFY) |
| Status / Priority Geography / Track / Tier | Per existing conventions |
| Notes | Same 4-identifier rule, adapted: business name, gov entity ID, direct gov-record URL, Airtable record URL, lead score, one-line eval summary |

### 8.2 The 16 "new" fields — reused as-is (IDs from `REVAMP_PLAN.md` Step 1)

| Field | Off-market value |
|---|---|
| Listing ID (`fld81k0uFwqkHaEEI`) | **Gov entity key** — the UEI (or SBA license number for class 2). Reuse this field as the off-market unique key, OR add `Gov Entity ID` (§8.4) — ⚠ VERIFY operator choice. |
| Direct Listing URL (`fldMCmSVQjYv3odok`) | Canonical gov-record URL (USAspending recipient page / SAM entity page / SBA directory entry) |
| Listing Screenshot (`fldrPuxZHGsYZuxTO`) | Screenshot of the company website (or gov-record page) |
| Date Added (`fldoZVwrhWaGGMlFR`) | Run date |
| Date Updated (`fld3TRpVYopXL7LLm`) | Run date |
| Previous Asking Price (`fldySRjfm1P8Nodes`) | Unused off-market (no price) |
| Link Health Status (`fldlsuLeSFhFKQuFc`) | "Live" once the website/record is validated |
| Link Last Checked (`fldMXwyQbEWPXbqE2`) | Validation date |
| Disposition (`fldw0xk1YBkmP7sBD`) | "Active" (default for all new off-market leads) |
| Lead Score (`fld2ipICYNLjaDm39`) | Score from `prospect-evaluation` (/110 class 1; informational class 2) |
| Prospect Eval Report (`fld9InVXs4RqgtNDo`) | Path to the generated HTML report |
| Revenue 2024 / 2025 (`fldfUOMF98BAk8Qeo` / `fld8Pmhi9M7m5qaUf`) | From enrichment if available |
| Cash Flow 2024 / 2025 (`fldwX2NkTE2E66pln` / `flde6Fr88nm4BAoE1`) | From enrichment if available |
| Source (`fldiGyXTk6Ybb6J1L`) | **New value** — see §8.3 |

### 8.3 `Source` single-select — new values required

The `Source` field currently has `Overnight Search` and `Manual Submission`. Add:

- **`Off-Market — ASL Bolt-on`** (class 1)
- **`Off-Market — SBIC`** (class 2)

⚠ VERIFY: **operator action required** — these single-select options must be
created in Airtable before the off-market skill runs. The skill must fail loudly
(not silently create) if the option is missing, mirroring the on-market
fail-loud convention.

### 8.4 Proposed NEW fields (operator approval required)

These are genuinely off-market-only and have no on-market equivalent. **Each is
PROPOSED — the operator must approve and create them**, or decide to fold the
data into `Notes`:

| PROPOSED field | Type | Purpose |
|---|---|---|
| `Gov Entity ID` | Single line text | UEI / CAGE — the cross-source entity key (§6). ⚠ VERIFY: or reuse `Listing ID`. |
| `SBIC License #` | Single line text | SBA SBIC license number (class 2). |
| `SBIC License Status` | Single select (Good Standing / Under Review / Surrendered / Revoked / Unknown) | The §7.3 gate result. |
| `Gov Data Source` | Multi-select (FPDS-NG / SAM.gov / USAspending / SBA SBIC / DSBS / GSA eLibrary / State) | Which systems surfaced the target (also drives §6 resolution provenance). |
| `Federal Award History $` | Currency | Total federal awards from USAspending — size proxy for class 1. |

> The off-market system must work **even if the operator approves zero new
> fields** — in that fallback, `Gov Entity ID`, license #, and source detail all
> go into `Notes`, and `Source` still distinguishes off-market records. The new
> fields are an *enhancement*, not a hard dependency — except the §8.3 `Source`
> values, which **are** required.

---

## 9. Workflow & Cadence

### 9.1 The Off-Market Intake Skill (proposed `off-market-search`)

A new skill, structured to **mirror `overnight-search`** but with a government-
data front-end. Proposed steps:

1. **Read config** — a new `config/offmarket_sources.md` (source URLs, codes,
   keys, keyword lists) + the existing `config/search_config.md`,
   `config/outreach_templates.md`; read the `prospect-evaluation` skill.
2. **Query government sources** (§4) for each target class.
3. **Resolve & de-duplicate** (§6) — across sources and against the tracker.
4. **Enrich** (§7.1) — website, SOS formation date, financial signals;
   Playwright-validate + screenshot.
5. **Qualify & score** (§7) — invoke `prospect-evaluation` in the right mode.
6. **Create/update Airtable records** (§8).
7. **Draft outreach** where a direct contact exists (§10).
8. **Generate the daily dashboard** (§10) — off-market leads appear alongside
   on-market leads.
9. **Write run logs** to `search_reports/`.

A manual single-entity path (mirroring `submit-url`) lets the operator push one
known company/SBIC through the same pipeline on demand.

### 9.2 Build Cadence — Ralph Loop (mirrors `REVAMP_LOOP_PROMPT.md`)

Building this system follows the **same Ralph-loop discipline** the on-market
revamp used. Parallels:

| On-market (`REVAMP_LOOP_PROMPT.md`) | Off-market build loop |
|---|---|
| Canonical plan `REVAMP_PLAN.md` | This PRD + `OFFMARKET_PRD_SPEC.md` |
| `_ralph/STATE.md`, one (stage, phase)/iteration | `Off-Market Search/_ralph/STATE.md`, same |
| IMPLEMENT → SELF-TEST → VERIFY → FINAL AUDIT → COMPLETE | Same phase ladder |
| Critic subagent per stage; final-audit subagent | Same |
| Promise `REVAMP_VERIFIED` | Promise `OFFMARKET_PRD_VERIFIED` (PRD) → a build loop would define its own |
| Anti-deception: never fake a PASS | Same — never state a guess as a confirmed code |

This PRD is itself the deliverable of the **PRD loop**. A subsequent **build
loop** (its own plan + loop prompt + STATE) would implement the
`off-market-search` skill against this PRD.

### 9.3 Run Cadence — Operational

- The on-market `overnight-search` runs **nightly**. Off-market sources change
  far more slowly (federal award data updates on a lag; the SBIC directory
  refreshes periodically).
- **Proposed:** run `off-market-search` **monthly** (class 1) and **monthly or
  on directory refresh** (class 2) — not nightly. ⚠ VERIFY: operator to set the
  cadence and whether it is a `/schedule` cron like the on-market job.
- Each run **diffs against the previous run** so only genuinely new or changed
  targets are surfaced.

### 9.4 Review Cadence

Off-market leads land as `Disposition = Active` and appear in the **same daily
dashboard** the operator already reviews. That dashboard has four sections
(`overnight-search` skill Step 10): **A** — Last Night's New Finds, **B** —
Running Queue (`Disposition = Active`), **C** — Revisit Bucket
(`Disposition = Revisit for Roll-up`), **D** — Run Summary. Off-market finds
behave exactly like on-market manual submissions: although Section A is titled
"Last Night's New Finds," every lead created on the dashboard's run day appears
there — so a **monthly** off-market run's new targets surface in Section A on
that run's day, and thereafter in Section B until dispositioned. The operator
triages with the same `Disposition` values (Active / Contacted / Maybe Later /
Revisit for Roll-up / Passed / Dead Link). No new review surface.

---

## 10. Integration Plan

Which existing files / trackers the off-market system reads and writes:

| Artifact | How off-market uses it |
|---|---|
| Airtable base `appOsvuyy5eK43QTx` / table `tblSmNrHROMLm7vOS` | **Writes** off-market records here — same table as on-market. Requires the §8.3 `Source` values; optionally the §8.4 new fields. |
| `prospect-evaluation` skill | **Invoked unchanged** for every qualified target (roll-up add-on mode / SBIC mode). |
| `references/buy-box-and-scoring.md` | Read by the scorer; **no changes** — it already covers both classes. |
| `templates/daily-dashboard.html` | Off-market leads render in the **same dashboard**. ⚠ VERIFY: minor enhancement may be wanted — a `Source` column or an "Off-Market" badge so the operator can tell off-market from on-market at a glance. Proposed, operator to confirm. |
| `output/dashboards/` | Daily dashboard output — shared. |
| `output/reports/{entity-id}/` | Off-market eval reports — same structure as on-market `output/reports/{listing-id}/`. |
| `output/screenshots/` | Website/record screenshots — shared. |
| `search_reports/` | Off-market run logs (`offmarket_run_log_YYYY-MM-DD.md`) and outreach drafts — same folder, distinct filenames. |
| `config/` | New `config/offmarket_sources.md`; reuse `search_config.md` + `outreach_templates.md`. ⚠ VERIFY: an off-market outreach template is likely needed — proprietary-approach outreach to an owner who has **not** listed the business reads very differently from broker outreach. Proposed new template, operator to confirm. |
| `.claude/skills/off-market-search/` | New skill (proposed). |

**Outreach note.** Off-market outreach goes to a **business owner / SBIC GP
principal directly**, not a broker, and the company is not for sale — the
message is a proprietary approach. This needs its own template; the existing
broker templates do not fit. Drafts are stored in `Notes` + `search_reports/`,
and **never auto-sent** (on-market convention preserved).

---

## 11. Compliance & Legal Notes

> Not legal advice. The operator should confirm each item with counsel and with
> each source's current Terms of Service.

- **Government data is generally public.** Federal data from FPDS-NG,
  USAspending.gov, and SAM.gov public extracts is U.S. Government work and
  generally in the public domain or openly licensed. ⚠ VERIFY each source's
  current terms.
- **SAM.gov restricted data.** ⚠ VERIFY: some SAM.gov entity fields (e.g.,
  FOUO / sensitive POC data) are restricted to roled accounts and **must not be
  scraped or redistributed**. Use only the public tier for off-market sourcing.
- **API terms & keys.** ⚠ VERIFY: SAM.gov and (if used) other APIs require
  registered accounts / API keys; comply with per-key quotas and acceptable-use
  terms. USAspending's API is key-free but still has acceptable-use terms.
- **Automated-access / scraping limits.** ⚠ VERIFY: where a source offers an API
  or bulk download, use it instead of scraping the UI. Respect `robots.txt`,
  rate limits, and any anti-automation terms. Do not scrape behind logins.
- **FOIA.** Most needed data is already published; FOIA is a **fallback** only
  (e.g., a specific contract file). FOIA requests are public-record requests —
  not a routine pipeline input. ⚠ VERIFY: no FOIA request should be filed as
  part of an automated run without operator sign-off.
- **State sources.** ⚠ VERIFY: state SOS and procurement portals have varying
  terms; some explicitly prohibit bulk extraction or charge for bulk data.
  Confirm per state before automating.
- **SBIC change-of-control.** Acquiring an SBIC GP requires **SBA prior
  approval** of the change of control — a transaction/closing condition, flagged
  on every class-2 record (§7.3). Not a data-compliance issue, but a legal
  gating fact the PRD must carry forward.
- **PII handling.** Owner/principal contact data gathered for outreach is
  business-contact information; store it only in the existing Airtable/`Notes`/
  `search_reports/` locations and do not redistribute. ⚠ VERIFY: confirm
  acceptable use with counsel, especially for any individual (vs. company) data.
- **Outreach law.** Cold outreach emails are subject to **CAN-SPAM** (and any
  applicable state law); since outreach is human-sent and individually
  personalized, this is low-risk, but the operator should confirm.

---

## 12. Risks

| # | Risk | Mitigation |
|---|---|---|
| R1 | **Wrong NAICS/PSC codes** silently miss most targets or flood with false positives. | All codes are `⚠ VERIFY:` — confirm before build (§5, §13). Validate by spot-checking known ASL firms appear under the chosen code. |
| R2 | **NAICS 541930 is too broad** — surfaces mostly spoken-language translation firms, not ASL. | Keyword filter (§5.2) isolates sign-language providers; adjacents marked as such for the line-10 bonus. |
| R3 | **Government APIs change / migrate** (FPDS→SAM/USAspending consolidation). | Treat USAspending as primary (stable, key-free); abstract the source layer so one source can be swapped. |
| R4 | **Entity resolution errors** — same company double-counted, or two firms merged. | UEI-first matching; name+address only as "probable"; §2.2 accuracy metric tracked. |
| R5 | **Off-market leads have no price** → Buy Box check 5 / rubric line 8 unscorable. | Expected behavior — scored "insufficient data," not a failure (§7.2). Operator briefed. |
| R6 | **Thin gov records** require heavy enrichment; enrichment may fail or be slow. | "Needs follow-up" markers, never fabricate; enrichment is best-effort; partial records still scored. |
| R7 | **SBIC directory format/URL unknown** — primary class-2 source not yet pinned down. | `⚠ VERIFY:` in §4.4; build a download-and-diff adapter once confirmed. |
| R8 | **State sources are non-uniform and high-effort.** | Phase 1 = federal only; state sources deferred to Phase 2 (§4.7). |
| R9 | **Duplicate creation** in the shared tracker pollutes the on-market pipeline. | Three-key dedup (§6.2); `Gov Entity ID`; off-market skill fails loud on schema mismatch. |
| R10 | **ToS / scraping violations.** | API/bulk-download first; respect rate limits; §11; legal sign-off. |
| R11 | **Off-market outreach mis-tone** — broker templates used for a proprietary owner approach. | Dedicated off-market outreach template (§10), operator-approved. |
| R12 | **Scope creep** into SBIC portfolio companies or paid data brokers. | Explicit non-goals (§2.4). |

---

## 13. Open Questions & Consolidated Verification Checklist

### 13.1 Clarifying questions for the operator

1. **Cadence** — monthly for both classes? Or different per class? Scheduled via
   `/schedule` cron like the on-market job?
2. **Success-metric targets** — confirm or replace the proposed numbers in §2.2.
3. **Spoken-language translation firms** — surface them at all (as adjacents),
   or hard-exclude and keep class 1 strictly sign-language/CART/deaf-services?
4. **New Airtable fields** — approve the §8.4 proposed fields, or fold that data
   into `Notes`? In particular: add `Gov Entity ID`, or reuse `Listing ID`?
5. **Dashboard** — add a `Source` column / off-market badge (§10), or leave the
   dashboard exactly as-is?
6. **State sources** — confirm Phase 1 = federal only, state sources deferred?
7. **Off-market outreach template** — approve creating a dedicated proprietary-
   approach template (§10)?
8. **SBIC scope** — all SBIC license/program types, or only certain ones (§3.2)?
9. **Build sequencing** — should a separate **off-market build loop** (its own
   plan + loop prompt) be created next, after this PRD is approved?

### 13.2 Consolidated `⚠ VERIFY:` checklist (confirm from primary sources)

- [ ] **NAICS 541930** is the current, correct code for Translation &
  Interpretation Services, and whether adjacent NAICS should be added (§5.1).
- [ ] **PSC R608** — confirm the correct current PSC for translation/interpreting
  (low confidence; §5.1).
- [ ] SBIC-relevant NAICS, if any (§5.1).
- [ ] **FPDS-NG** current programmatic access method (ATOM feed vs. SAM.gov
  migration) and rate limits / ToS (§4.1).
- [ ] **SAM.gov** APIs at `api.sam.gov`, which fields are public-tier vs.
  restricted, whether an API key is required, quotas, ToS (§4.2, §11).
- [ ] **USAspending.gov** API endpoints, parameters, key-free status, rate
  limits, bulk-download options, ToS (§4.3).
- [ ] **SBA SBIC directory** — exact URL, file format, refresh cadence, and
  whether it publishes leverage/fund/principal data; how to confirm "good
  standing" (§4.4, §7.3).
- [ ] **SBA DSBS** — current live URL, whether a programmatic interface exists,
  export options (§4.5).
- [ ] **GSA eLibrary** — current language-services SIN, export options (§4.6).
- [ ] **U.S. Courts interpreter procurement** — where published, machine-
  readable? (§4.7)
- [ ] **State procurement / SOS** — per-state terms, bulk-data availability
  (§4.7, §11).
- [ ] **DUNS** retirement date / handling for legacy records (§6.1).
- [ ] **SEC EDGAR / RID** — coverage and (for RID) non-gov ToS (§4.7).
- [ ] **SBIC program variants in scope** — confirm whether all SBIC license/
  program types or only certain ones are targeted (§3.2).
- [ ] **`Listing ID` reuse vs. new `Gov Entity ID` field** — operator decision
  on the off-market unique key (§6.2, §8.2, §8.4).
- [ ] **Dashboard enhancement** — whether to add a `Source` column / off-market
  badge to `templates/daily-dashboard.html` (§10).
- [ ] **Off-market outreach template** — whether to create a dedicated
  proprietary-approach template (§10).
- [ ] All §2.2 **success-metric targets** (operator-set).
- [ ] All §9.3 **cadence** decisions (operator-set).

---

*End of PRD v1.0. Produced by the `OFFMARKET_LOOP_PROMPT.md` planning loop.
Awaiting operator review of §13.*
