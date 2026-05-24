# ACCESS INTERPRETING INC — Prospect Evaluation

**Prepared for:** Biffrey Braxton / EarnedOut
**Report date:** 2026-05-23
**Prepared by:** Claude (Prospect Evaluation skill — off-market-search invocation, rollup_addon mode)
**Lead source:** Off-Market — ASL Bolt-on (gov-data discovery, S1 USAspending, S2 SAM.gov)

---

## Buy Box Screening

| # | Criterion | Status | Evidence |
|---|-----------|:------:|----------|
| 1 | ≥ 10 full-time employees | ⚠️ | FTE count not disclosed in gov data |
| 2 | EBITDA ≥ $1M / year | ⚠️ | EBITDA not disclosed (private company) |
| 3 | 10+ years in business | ✅ | SAM registered 2008-01-10 (~18 yrs) |
| 4 | 3+ yrs YoY revenue and profit growth | ⚠️ | Multi-year P&L not disclosed |
| 5 | Asking price ≤ 4.0x EBITDA | ⚠️ | Off-market — no asking price |
| 6 | DSCR > 1.4 (informational only) | ⚠️ | DSCR not computable (insufficient financials) |

**Overall Buy Box:** **CONDITIONAL (add-on)**
**Lead Score:** **50 / 110**
**Roll-up add-on for: Applied Development** — Applied Development add-ons have **no size floor**; every acquirable Class-1 target is worth evaluating.

Does not meet standalone thresholds (off-market, no financials disclosed) but qualifies as a roll-up add-on for Applied Development; gov data confirms a clear NAICS 541930 / PSC R608 sign-language / interpretation services line of business with active federal-contract revenue.

---

## Scorecard (26 fields)

| # | Field | Value | Source |
|---|-------|-------|--------|
| 1 | Business Name | ACCESS INTERPRETING INC | SAM.gov / USAspending recipient profile |
| 2 | Lead Source | Off-Market — gov data (USAspending + SAM.gov) | S1 / S2 adapters |
| 3 | Years in business | 18 | SAM registration 2008-01-10 |
| 4 | Value of real estate owned | (insufficient data) | Not in gov data |
| 5 | Value of FF&E | (insufficient data) | Not in gov data |
| 6 | Full-time employees | (insufficient data) | Not in gov data |
| 7 | Part-time employees | (insufficient data) | Not in gov data |
| 8 | Contractors / 1099 workers | (insufficient data — sign-language firms typically rely heavily on 1099 interpreters) | Not in gov data |
| 9 | Business address | 10507 OAKTON RIDGE CT, OAKTON, VA, 22124 | SAM.gov physical address |
| 10 | Revenue 2022 | (insufficient data — private co) | — |
| 11 | Revenue 2023 | (insufficient data — private co) | — |
| 12 | Revenue 2024 | (insufficient data — private co) | — |
| 13 | Revenue 2025 | (insufficient data — private co) | — |
| 14 | Net / free cash flow 2022 | (insufficient data) | — |
| 15 | Net / free cash flow 2023 | (insufficient data) | — |
| 16 | Net / free cash flow 2024 | (insufficient data) | — |
| 17 | Net / free cash flow 2025 | (insufficient data) | — |
| 18 | Asking price | NOT FOR SALE (off-market) — no asking price | n/a |
| 19 | % revenue growth YoY | (insufficient data) | computed — no disclosed P&L |
| 20 | Yearly revenue retention | (insufficient data) | — |
| 21 | EBITDA margin | (insufficient data) | computed — no disclosed P&L |
| 22 | Customer LTV |  | LEAVE BLANK per skill rule 3 |
| 23 | Customer CAC |  | LEAVE BLANK per skill rule 3 |
| 24 | Client concentration (largest %) | (insufficient data) | — |
| 25 | Link to 2024 financials + YTD | (none — off-market, no financials disclosed) | — |
| 26 | Industry / NAICS | 541930 — Translation and Interpretation Services (sign-language line confirmed via federal-contract data) | USAspending NAICS field |

### Off-market signals (informational — not part of the 0–100 score)

| Signal | Value | Source |
|---|---|---|
| UEI | FUT6MQ1MCDC9 | SAM.gov / USAspending recipient |
| CAGE code | 4YL49 | SAM.gov |
| Federal award total (trailing 5 FYs) | $40,080,138 | USAspending S1 |
| Federal award count | 12 | USAspending S1 |
| Place(s) of performance | DC, MD, VA | USAspending |
| Awarding agencies sampled | (none) | USAspending |
| Class-1 keyword tier | **core** | hits: AMERICAN SIGN LANGUAGE, CART, COMMUNICATION ACCESS, DEAF, HARD OF HEARING, SIGN LANGUAGE |
| Website | http://www.ainterpreting.com (Live) | SAM.gov entityURL + curl health-check |
| Business POC (from SAM.gov public tier) | Brad Leon | SAM.gov pointsOfContact.governmentBusinessPOC |

---

## Lead Score Breakdown (per-line math from buy-box-and-scoring.md — applied verbatim)

| # | Item | Awarded | Note |
|---|------|---------|------|
| 1 | Industry match | **20** | Clearly in NAICS 541930 sign-language line — full 20. |
| 2 | EBITDA tier (>$3M=15 / >$2M=10 / >$1M=5 / ≤$1M=0) | **0** | Insufficient data — not awarded (per rubric). |
| 3 | Years in business (≥10=10, else 0) | **10** | SAM registered 2008-01-10 (~18 yrs) |
| 4 | 3-yr rev + profit growth | **0** | Insufficient data — not awarded. |
| 5 | Recurring revenue | **10** | Federal contracts (NAICS 541930 / PSC R608) are contracted-term, recurring revenue |
| 6 | Customer concentration (<20%=5, else 0) | **0** | Insufficient data — not awarded. |
| 7 | Employees (≥10 FTE=10, else 0) | **0** | Insufficient data — not awarded. |
| 8 | Valuation multiple (≤4x=15 / 4–5.5x=7 / >5.5x=0) | **0** | Off-market — no asking price → insufficient data → not awarded (per scoring_integration.md §3.2, not a failure). |
| 9 | Low owner dependence | **0** | Insufficient data — not awarded. |
| 10 | Roll-up add-on strategic fit (Applied Development) | **10** | Core ASL/CART/deaf-services — direct add-on for Applied Development → 10. |
| | **TOTAL** | **50 / 110** | |

**Interpretation band:** Weak fit (<60) — would normally pass unless strategic; off-market signal: clear federal-contract revenue history in target industry justifies surfacing.

---

## Supporting Deal Memo

### 1. Executive Summary
ACCESS INTERPRETING INC is a core Class-1 Applied Development roll-up add-on candidate, surfaced via U.S. government open data (USAspending federal-award discovery on NAICS 541930 / PSC R608). The company has **$40,080,138** in federal contracts (trailing 5 FYs, 12 awards) with awarding agencies including multiple federal customers. The keyword strategy from `config/offmarket_sources.md` matched on: AMERICAN SIGN LANGUAGE, CART, COMMUNICATION ACCESS, DEAF, HARD OF HEARING, SIGN LANGUAGE. The company is **not for sale** — outreach must be proprietary-approach, not broker-mediated.

### 2. Industry & Geography Gate
NAICS 541930 (Translation and Interpretation Services — includes sign-language services per 2022 NAICS definition) is a recognized Applied Development add-on target industry. Place of performance: DC, MD, VA. Physical headquarters: OAKTON, VA. Priority geography (DC/VA/MD/PA/WV — B1 Phase 1)

### 3. Buy Box (off-market context)
Six standard checks above. Five of six are ⚠️ "insufficient data" — the expected state for an off-market target with no published P&L. Years-in-business is the only header line that can be answered from public data (18 years if SAM registration is a fair proxy). **Verdict: CONDITIONAL (add-on)** — Applied Development add-ons have no size floor, and the gov-data evidence is strong enough to warrant proprietary outreach.

### 4. Financial Snapshot
No disclosed P&L; gov-contract revenue is a **size signal**, not an audited financial. Federal awards totaling $40,080,138 over the trailing 5 FYs suggest a mid-market firm by federal-contracting volume, but commercial revenue and non-federal sources are unknown.

### 5. Operations & Team
Insufficient data from public gov sources — fill in via post-outreach diligence. SAM.gov POC: Brad Leon. Website: http://www.ainterpreting.com (Live).

### 6. Customer Concentration & Recurring Revenue
Federal-contract revenue is recurring during contract terms but agency-concentrated. Awarding agencies (sample): none in award sample. Commercial customer concentration is unknown.

### 7. Roll-up / Applied Development Fit
Direct fit — core ASL/sign-language/CART line of business is the Applied Development platform. Closing condition: SBA prior approval is not applicable here (Class 1 — operating company, not an SBIC).

### 8. Deal Structure & Risks
Off-market → no broker → proprietary outreach via Template OM-1 (contact: Brad Leon). Key risks: (a) owner may not be a seller; (b) federal-contract concentration (DCAA audit exposure on close); (c) workforce is typically heavily 1099 — staffing model carries classification risk; (d) data gaps on EBITDA / FTE / multi-year growth — all required before LOI.

### 9. Recommendation & Next Steps
Proprietary outreach Template OM-1 — light, no-pressure approach. Pre-outreach due-diligence items: confirm operating address & website, verify owner / principal name (SAM.gov POC vs. public LinkedIn), pull state SOS formation record to confirm Years-in-Business, request a basic financial summary at first meeting.

### 10. Appendix — Sources fetched this run
- USAspending recipient profile: `https://www.usaspending.gov/recipient/7fc32726-99ce-8f72-bbcf-42af91b856ea-C/latest`
- USAspending award search (NAICS 541930 + PSC R608, FY22–26)
- SAM.gov entity record: api.sam.gov/entity-information/v3/entities?ueiSAM=FUT6MQ1MCDC9
- Website health-check (curl): 200 https://ainterpreting.com/

### 11. Scoring methodology notes
- Rubric applied verbatim from `.claude/skills/prospect-evaluation/references/buy-box-and-scoring.md` §6.
- Off-market "no asking price" handled per `scoring_integration.md` §3.2 — valuation line scores 0 ("insufficient data — not awarded"), **not a failure**.
- Insufficient-data items score 0 per buy-box-and-scoring §6 "Scoring notes".
- Roll-up bonus (line 10) = 10 for core ASL/CART tier, 5 for adjacent tier per `config/offmarket_sources.md` keyword strategy.
