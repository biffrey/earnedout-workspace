# Off-Market Search PRD — §13 Resolution

| | |
|---|---|
| **Companion to** | `PRD_OFF_MARKET_SEARCH.md` v1.0 |
| **Purpose** | Records operator answers to the §13.1 clarifying questions and the primary-source verification of the §13.2 `⚠ VERIFY:` checklist |
| **Date** | 2026-05-21 |
| **Prepared for** | Biffrey Braxton (bb@braxton.ai) |
| **Status** | Draft for operator review. One question (SBIC scope) still open — see Part 4. |

> **Accuracy note.** Confidence levels below are honest. "Confirmed" means a
> primary or strongly corroborated source was located; "Reported" means a
> credible secondary source states it but the primary was not directly read;
> "Not verified" means no reliable source was confirmed. Items the operator
> should still spot-check are called out explicitly.

---

## Part 1 — §13.1 Clarifying Questions: Operator Answers

| # | Question | Operator decision | PRD impact |
|---|---|---|---|
| Q1 | Run cadence | **Weekly**, both classes, scheduled via `/schedule` cron | **Changes the PRD.** §9.3 proposed *monthly*. Update §9.3 to weekly. See note below. |
| Q2 | Success-metric targets (§2.2) | **Accept all proposed numbers as-is** | §2.2 quality metrics stand (≥80% precision, <5% duplicate rate, ≥95% resolution). Volume / cycle-time blanks to be filled with proposed defaults. |
| Q3 | Spoken-language translation firms | **Surface as "adjacent"** (lower priority; 5-pt line-10 bonus vs 10) | Confirms §3.1 / §5.1 approach. No PRD change. |
| Q4 | New Airtable fields (§8.4) | **Approve all 5 proposed fields + add a dedicated `Gov Entity ID`** | §8.4 fields all approved; the §8.2 "reuse `Listing ID`" fallback is dropped. |
| Q5 | Dashboard enhancement | **Add an "Off-Market" badge** to off-market rows | §10 — implement the badge; no `Source` column needed. |
| Q6 | State sources phasing | **Include priority states in Phase 1** | **Changes the PRD.** §4.7 proposed deferring all state sources to Phase 2. Operator wants priority states now — the PRD must name the priority states. |
| Q7 | Off-market outreach template | **Approve a dedicated proprietary-approach template** | §10 — create the new template; keep broker templates for on-market. |
| Q8 | SBIC license/program scope | **Decide after research** | Open. Research summary provided in **Part 4** for the operator's decision. |
| Q9 | Build sequencing | **Yes — create a separate off-market build loop next** | After PRD approval, stand up a dedicated build loop (plan + loop prompt + STATE), mirroring the on-market REVAMP loop. |

**Note on Q1 (weekly cadence).** Federal award data and the SBIC directory
change slowly, so most weekly runs will diff to "no change." That is harmless —
the run already diffs against the prior run (§9.3) — but the operator should
expect the majority of weekly runs to surface few or zero new targets. Monthly
would capture nearly the same targets at lower cost; weekly is fine if low-yield
runs are acceptable.

**Note on Q6 (priority states).** The PRD currently has no priority-state list.
Because the operator wants state sources in Phase 1, §4.7 needs an explicit
named set of states. Recommend the operator specify them (e.g., by population,
deaf-population concentration, or existing-deal geography) before the build loop
starts.

---

## Part 2 — §13.2 Verification Checklist: Findings From Primary Sources

### 1. NAICS 541930 — Translation and Interpretation Services
**Status: CONFIRMED — and confirms the §5.1 caveat. Confidence: High.**

NAICS **541930 "Translation and Interpretation Services"** is a current, valid
code in the 2022 NAICS (the edition still in force in 2026; the 2027 revision is
not yet effective). The official industry definition covers establishments
"primarily engaged in translating written material and interpreting speech from
one language to another" **and** establishments "primarily engaged in providing
sign language services."

This is good and bad for the PRD: 541930 is unambiguously the right discovery
code, and it explicitly includes sign language — but it equally includes
spoken/foreign-language translation. The §5.1 caveat that 541930 is *broader*
than Class 1 is correct, and the §5.2 keyword filter remains necessary. No
single narrower "sign-language-only" NAICS code exists — 541930 is the most
granular code available. **No adjacent NAICS is needed for discovery;** the
keyword filter, not a second code, isolates ASL providers.

*Primary source:* U.S. Census Bureau NAICS, code 541930 —
`https://www.census.gov/naics/?input=541930&year=2022&details=541930`
(the page is JavaScript-rendered; the definition above was confirmed via the
Census-sourced search index — recommend the operator open the page directly to
read the verbatim definition.)

### 2. PSC R608 — Translation/Interpreting
**Status: CONFIRMED — the §5.1 "low confidence" flag can be cleared. Confidence: High.**

The PRD flagged **PSC R608** as a low-confidence guess. It is in fact correct.
**R608 = "Support — Administrative: Translation and Interpreting Services
(Including Sign Language)."** The structure is internally consistent (PSC letter
`R` = professional/administrative/management support services) and three
independent federal-data aggregators (GovTribe, HigherGov, FSCPSC) return the
identical description.

One correction to the PRD's working assumption: the current Product and Service
Code Manual is the **FY2025 / April 2025 edition** (not April 2024). The
acquisition.gov manual page links the current files dated April 8, 2025.

*Caveat:* I could not extract the `R`-code section directly from the PSC Manual
PDF (the PDF text extraction returned only the front matter and early service
codes). The R608 description is therefore confirmed by strong corroboration, not
by reading the primary PDF. **Recommended final spot-check:** open
`PSC April 2025.xlsx` from the acquisition.gov PSC Manual page and confirm row
R608.

*Primary source:* PSC Manual page (current edition = April 2025) —
`https://www.acquisition.gov/psc-manual`

### 3. SBIC-relevant NAICS
**Status: NOT VERIFIED — and not material. Confidence: N/A.**

I did not confirm a NAICS code for SBIC management entities from a primary
source, and I will not guess one. This is not a problem: the PRD's own §5.1
states the SBA SBIC directory supersedes NAICS for Class 2. **Recommendation:**
drop the speculative "523910/523999" line from §5.1 or mark it explicitly
non-essential. The directory (item 7 below) is the authoritative key.

### 4. FPDS-NG access method
**Status: MATERIALLY CHANGED — the PRD must be rewritten here. Confidence: High.**

FPDS-NG is being decommissioned. Confirmed facts: the FPDS.gov public website,
login, and search tools — including **ezSearch** — have been retired; users are
directed to conduct contract-data searches in **SAM.gov**; and the **FPDS ATOM
feed is scheduled to be decommissioned later in FY2026.** A secondary source
(Gormley Group) reports the FPDS.gov public site was decommissioned on
**February 24, 2026** — treat that specific date as *Reported*, pending the
operator confirming it on `sam.gov/fpds`.

The replacement programmatic source is the **SAM.gov Contract Awards API** at
`open.gsa.gov/api/contract-awards/` (it requires an API key). This *strengthens*
the PRD's existing recommendation: do not build on FPDS-NG. §4.1 should be
rewritten to name the SAM.gov Contract Awards API as the FPDS successor and keep
USAspending.gov as the primary award source.

*Primary sources:* `https://sam.gov/fpds` · `https://open.gsa.gov/api/contract-awards/`

### 5. SAM.gov APIs
**Status: CONFIRMED. Confidence: High.**

The SAM.gov **Entity Management API** is real and public-facing at
`api.sam.gov/entity-information/v1` through `v4`. Key facts from the GSA primary
documentation:

- **An API key is required.** It is the "Public API Key" generated from the
  user's SAM.gov profile (`sam.gov/profile/details`), retrieved via a one-time
  password. The key is sent as the `x-api-key` header.
- **Three data tiers.** *Public* data (entity name, UEI, registration details,
  physical/mailing address, business types, PSC, NAICS, POC name and address) is
  available to a standard account. *FOUO* and *Sensitive* tiers require a
  **Federal** System Account — not available to a private acquirer, and not
  needed for off-market sourcing.
- **Rate limits (daily):** non-federal user with **no role** in SAM.gov = **10
  requests/day**; non-federal user **with a role** = **1,000/day**; non-federal
  **system account** = 1,000/day; federal system account = 10,000/day.

**Operator action:** to get a usable 1,000/day quota, the SAM.gov account behind
this pipeline needs a *role* assigned (a no-role account is capped at 10/day,
which is unusable). The §4.2 / §11 assumptions in the PRD are correct.

*Primary source:* `https://open.gsa.gov/api/entity-api/`

### 6. USAspending.gov API
**Status: CONFIRMED. Confidence: High.**

USAspending.gov's REST API is real, public, and **requires no authorization** —
the official endpoint reference states plainly: "Endpoints do not currently
require any authorization." The award-search endpoint the PRD names,
**`/api/v2/search/spending_by_award/` (POST)**, exists. Bulk download endpoints
(`/api/v2/bulk_download/awards/`, `/api/v2/download/awards/`) and NAICS/PSC
autocomplete endpoints also exist, supporting the PRD's filter-by-NAICS/PSC plan.

*One honest gap:* the endpoint reference page does **not** publish a specific
per-IP rate limit. The PRD's "⚠ VERIFY rate limits" line should be answered as
"no documented hard rate limit; use courteously and prefer bulk download for
large pulls." The PRD's recommendation to treat USAspending as the **primary**
programmatic award source is sound and is reinforced by the FPDS decommission.

*Primary source:* `https://api.usaspending.gov/docs/endpoints`

### 7. SBA SBIC directory
**Status: CONFIRMED — with a correction to the PRD's format assumption. Confidence: High.**

The SBA SBIC directory is live at
`sba.gov/funding-programs/investment-capital/sbic-directory`. The PRD's §4.4
assumed it is "most likely a periodic file download (Excel/PDF)." That is
**incorrect** — it is a **live, filterable web directory** (filter by investment
strategy, fund style, making-new-investments, state) with a **"Download CSV"**
button (`sba.gov/export/contacts/sbic`). A download-and-diff approach still works
fine; just diff the CSV export.

**Fields the directory publishes per licensee:** fund name, city/state, "Managed
by" (the management company / GP), vintage year, fund size, average investment,
investment strategy, fund style, "making new investments?" flag, and an investor-
relations contact (name, email, phone).

**Fields it does NOT publish:** SBA license number, an explicit license-status /
"good standing" flag, or outstanding SBA leverage. This matters for the §7.3
SBIC gate — **"active and in good standing" cannot be confirmed from the
directory alone.** Appearing on the directory establishes the entity is
currently licensed; good standing must be cross-checked against SBA enforcement
actions, SBA OIG reports, and SBIC license actions published in the Federal
Register. §4.4 and §7.3 should be updated to say so.

*Count note:* SBA has reported approximately **318 licensed SBICs as of
September 30, 2024** — treat as approximate and re-pull the current count from
the directory each run.

*Primary source:* `https://www.sba.gov/funding-programs/investment-capital/sbic-directory`

### 8. SBA DSBS
**Status: MATERIALLY CHANGED — name and platform are out of date in the PRD. Confidence: High.**

DSBS no longer exists under that name. In **July 2025 the SBA replaced the
Dynamic Small Business Search (DSBS) with "Small Business Search" (SBS).**
Existing profiles were migrated. The old `dsbs.sba.gov` domain still resolves and
redirects to the new SBS platform. Only businesses with an **active SAM
registration** appear in SBS. §4.5 should be renamed "SBA Small Business Search
(SBS)."

*Honest gap:* I did not confirm whether SBS exposes a programmatic interface or
export. §4.5's "⚠ VERIFY programmatic interface / export" remains open —
recommend treating SBS as UI-search until proven otherwise, and noting that
USAspending + the SAM.gov Entity API already cover most of the same firms.

*Primary source:* `https://dsbs.sba.gov/` (redirects to the SBS platform)

### 9. GSA eLibrary — language-services SIN
**Status: CONFIRMED. Confidence: High.**

Under the consolidated **Multiple Award Schedule (MAS)**, language services are
**SIN 541930 — "Translation and Interpretation Services"** (post-consolidation,
SIN numbers were aligned to NAICS codes, so the SIN equals the NAICS code). A
related adjacent SIN is **611630 — "Linguistic Training and Education."** GSA
eLibrary can be browsed at `gsaelibrary.gsa.gov` filtering on
`scheduleNumber=MAS` and `specialItemNumber=541930`; GSA also publishes a
contractor list spreadsheet for these SINs.

*Caveat:* GSA's SIN 541930 ordering guide describes interpretation primarily in
terms of spoken/foreign-language modalities — useful context, but the SIN itself
is the correct net; the §5.2 keyword filter still isolates ASL providers.

*Primary source:* GSA eLibrary —
`https://www.gsaelibrary.gsa.gov/ElibMain/sinDetails.do?scheduleNumber=MAS&specialItemNumber=541930&executeQuery=YES`

### 10. U.S. Courts interpreter procurement
**Status: CONFIRMED — resolves to LOW value as a discovery source. Confidence: Medium-High.**

Federal courts contract with **individual** contract interpreters, not with
third-party interpreting firms. The Administrative Office of the U.S. Courts
maintains the **National Court Interpreter Database (NCID)** for interpreter
contact information and publishes a standard "Contract for Court Interpreter
Services"; individual district courts publish their own interpreter information.

There is **no single machine-readable national list of interpreting
firms/agencies** from the courts — the data is individual-interpreter oriented.
Because Class 1 targets are *operating companies*, not sole practitioners, the
U.S. Courts channel is a weak discovery source. **Recommendation:** deprioritize
it in §4.7, or keep it only as an enrichment cross-reference.

*Primary source:* `https://www.uscourts.gov/court-programs/federal-court-interpreters`

### 11. State procurement / Secretary-of-State registries
**Status: CONFIRMED as non-uniform — no single source exists. Confidence: High (on the non-uniformity).**

There is no national source; each state runs its own eProcurement portal and its
own SOS business registry, with varying terms (some prohibit bulk extraction,
some charge for bulk data). This cannot be "verified" as one item. Given the
operator's Q6 decision to include priority states in Phase 1, the actionable
output is: **the PRD needs a named priority-state list**, and each chosen state's
portal terms must be checked individually before automating (per §11). This is a
build-loop input, not a single fact to confirm.

### 12. DUNS retirement / handling of legacy records
**Status: CONFIRMED. Confidence: High.**

The federal government stopped using the D&B **DUNS number** as the entity
identifier on **April 4, 2022**, when SAM.gov completed the transition to the
government-issued **12-character Unique Entity Identifier (UEI)**. The last
moment a DUNS could be used in SAM.gov was 8:00 p.m. ET on April 1, 2022. The
PRD's §6.1 logic — UEI as the primary key, DUNS only as a legacy bridge on
pre-2022 award rows — is correct.

*Primary source:* SAM.gov / GSA transition notices (e.g., the NIH eRA notice
`https://www.era.nih.gov/news/era-information-samgov-unavailable-april-1-4-2022-transition-duns-uei.htm`).

### 13. SEC EDGAR / RID
**Status: CONFIRMED with one correction (Form ADV) and one operator decision (RID). Confidence: High.**

**Form ADV — correction to the PRD.** SBIC GP investment-adviser data is **not
in EDGAR.** Form ADV is filed through the Investment Adviser Registration
Depository (IARD) and disclosed publicly through the **Investment Adviser Public
Disclosure (IAPD)** system at `adviserinfo.sec.gov`. The SEC also publishes bulk
**"Form ADV Data"** in CSV (January 2001 to present) covering SEC-registered
investment advisers and Exempt Reporting Advisers. §4.7 should say "IAPD /
adviserinfo.sec.gov (Form ADV)," not "SEC EDGAR." The PRD's coverage caveat is
correct and worth keeping: only SBIC GPs that are registered RIAs or ERAs file
Form ADV — many SBIC managers are not, so this enriches *some* Class 2 targets,
not all.

**RID — retained as a supplementary source (operator decision).** The Registry
of Interpreters for the Deaf is a non-profit (`rid.org`), as the PRD assumed. Its
member-search directory (`myaccount.rid.org`) carries terms instructing users not
to copy names into an external database and stating the directory is for
contacting interpreters for assignments. The operator has elected to **keep RID
in scope** as a supplementary Class-1 source. To stay consistent with RID's
stated terms, the build should use RID for **point-of-need enrichment and contact
lookup** — querying it while a specific candidate is being worked — rather than
bulk-copying the member directory into Airtable; the operator may also confirm
acceptable use directly with RID. RID stays supplementary, never a core discovery
source, consistent with PRD §4.7.

*Primary sources:* `https://adviserinfo.sec.gov/` ·
`https://www.sec.gov/data-research/sec-markets-data/information-about-registered-investment-advisers-exempt-reporting-advisers` ·
RID member search `https://myaccount.rid.org/Public/Search/Member.aspx`

### 14–18. Operator-decision items (§13.2 lines that were really §13.1 questions)
**Status: RESOLVED via Part 1.**

- `Listing ID` reuse vs. new `Gov Entity ID` → **new `Gov Entity ID` field** (Q4).
- Dashboard `Source` column / badge → **off-market badge** (Q5).
- Off-market outreach template → **dedicated template approved** (Q7).
- §2.2 success-metric targets → **accepted as-is** (Q2).
- §9.3 cadence → **weekly via cron** (Q1).

---

## Part 3 — Material Corrections the PRD Needs

These are the items where verification found the PRD's planning assumption is
now wrong or out of date — they should be fixed before the build loop starts:

1. **§4.1 FPDS-NG** — FPDS.gov public site and ezSearch are decommissioned; the
   ATOM feed is scheduled to be retired in FY2026. Replace with the SAM.gov
   Contract Awards API (`open.gsa.gov/api/contract-awards/`) and keep USAspending
   as primary.
2. **§4.4 SBIC directory** — it is a live filterable web directory with a CSV
   export, not a periodic Excel/PDF. It does not publish license number or a
   good-standing flag — §7.3's gate needs an external good-standing check.
3. **§4.5 DSBS** — renamed to **Small Business Search (SBS)** as of July 2025.
4. **§4.7 SEC EDGAR** — Form ADV is in **IAPD (adviserinfo.sec.gov)**, not EDGAR.
5. **§4.7 RID** — retained as a supplementary Class-1 source per operator
   decision. Use it for point-of-need enrichment / contact lookup rather than
   bulk-copying the member directory, consistent with RID's stated terms.
6. **§5.1 PSC** — R608 is correct; clear the "low confidence" flag. Current PSC
   manual is the April 2025 edition.
7. **§9.3 cadence** — change "monthly" to "weekly" per the operator.
8. **§4.7 state sources** — promoted into Phase 1; the PRD needs a named
   priority-state list.

---

## Part 4 — Still Open: Q8, SBIC Scope (operator decision needed)

The operator deferred Q8 pending research. Here is what to decide against.

As of 2026, following the SBA's 2023 "Investment Diversification and Growth"
final rule, the SBIC program issues these **license types**:

- **Standard Debenture SBIC** — aligned with mezzanine / private-credit /
  current-pay strategies; up to ~2x leverage.
- **Accrual SBIC** — aligned with longer-duration equity funds; uses Accrual
  Debentures (interest accrues, repaid at distribution/maturity); up to ~1.25x
  leverage.
- **Reinvestor SBIC** — a fund-of-funds model investing in underlying funds;
  uses the accrual debenture.
- **Non-leveraged SBICs** — licensed SBICs that do not draw SBA leverage.

Note the public SBIC directory does **not** categorize entries by license type —
it categorizes by *Investment Strategy* (Buyout, Mezzanine, Direct Lending,
Early Stage, Growth Equity, Venture, etc.) and *Fund Style* (Private Equity,
Private Credit, Venture, Hybrid, Fund of Funds). License type would have to be
confirmed per entity with the SBA.

**The decision for the operator:** since the strategic prize is the *license
itself* and any of these types short-circuits de novo licensing, the simplest
and most defensible scope is **all licensed SBIC types** — then let the
`prospect-evaluation` SBIC mode and the good-standing gate do the filtering.
Narrowing to one type (e.g., Standard Debenture only) would exclude otherwise
valid license acquisitions for no strategic reason. But this is the operator's
call, and the question is now ready to answer.

---

## Sources

- U.S. Census Bureau — NAICS 541930: https://www.census.gov/naics/?input=541930&year=2022&details=541930
- Acquisition.gov — Product and Service Code (PSC) Manual (current = April 2025): https://www.acquisition.gov/psc-manual
- SAM.gov — Contract Award Data / FPDS migration: https://sam.gov/fpds
- GSA Open Technology — SAM.gov Contract Awards API: https://open.gsa.gov/api/contract-awards/
- GSA Open Technology — SAM.gov Entity Management API: https://open.gsa.gov/api/entity-api/
- USAspending.gov — API endpoint reference: https://api.usaspending.gov/docs/endpoints
- SBA — SBIC directory: https://www.sba.gov/funding-programs/investment-capital/sbic-directory
- SBA — Small Business Search (formerly DSBS): https://dsbs.sba.gov/
- GSA eLibrary — MAS SIN 541930: https://www.gsaelibrary.gsa.gov/ElibMain/sinDetails.do?scheduleNumber=MAS&specialItemNumber=541930&executeQuery=YES
- U.S. Courts — Federal Court Interpreters: https://www.uscourts.gov/court-programs/federal-court-interpreters
- NIH eRA — SAM.gov DUNS→UEI transition notice: https://www.era.nih.gov/news/era-information-samgov-unavailable-april-1-4-2022-transition-duns-uei.htm
- SEC — Investment Adviser Public Disclosure (IAPD): https://adviserinfo.sec.gov/
- SEC — Information about Registered Investment Advisers and Exempt Reporting Advisers: https://www.sec.gov/data-research/sec-markets-data/information-about-registered-investment-advisers-exempt-reporting-advisers
- SBA — Apply to be an SBIC (license types): https://www.sba.gov/partners/sbics/apply-be-sbic

*Prepared 2026-05-21 as a companion to PRD_OFF_MARKET_SEARCH.md v1.0.*
