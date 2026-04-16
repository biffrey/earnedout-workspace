# Research Playbook — How to fill the 26 scorecard fields

For each field: **source priority order → extraction approach → estimation method if all sources fail → how to label the value**.

Rules of thumb:
- Cite the specific URL or document you pulled each value from in the Appendix.
- Tag estimates inline with `(est.)`.
- Never invent a number. If nothing credible exists, leave the field blank.
- Prefer primary sources (SOS filings, tax returns, FAA/NRC/state bar registries, county assessor) over aggregators (ZoomInfo, Growjo).

---

## The 26 output fields

| # | Field | Primary sources | Estimation fallback | Label |
|---|-------|-----------------|---------------------|-------|
| 1 | **Business Name** | Provided docs, SOS filing (legal name), website | — | Legal name with d/b/a if different |
| 2 | **Lead Source** | How the user found this (listing site, broker, referral, cold outbound, prior contact) | — | Plain-text |
| 3 | **Years in business** | State Secretary of State registration date; Wayback Machine earliest capture; LinkedIn "Founded"; D&B; About page | Use earliest among above; label `(est.)` if no single source confirms | YYYY (years) |
| 4 | **Value of real estate owned** | County assessor records; CIM; SBA 504 filings; provided balance sheet | If not disclosed: leave blank, or note "None disclosed" | USD |
| 5 | **Value of furniture, fixtures & equipment (FF&E)** | Balance sheet, CIM, equipment schedule, asset list | Industry benchmark × revenue if CIM silent (rare) | USD `(est.)` if derived |
| 6 | **Full-time employees** | LinkedIn headcount (decent proxy); ZoomInfo; provided CIM; state UI filings | Revenue-per-employee benchmarks by NAICS | Integer `(est.)` if derived |
| 7 | **Part-time employees** | CIM; provided docs; direct listing | Leave blank if unknown | Integer |
| 8 | **Contractors / 1099** | CIM; provided docs | Leave blank if unknown | Integer |
| 9 | **Business address** | SOS registered address; Google Business Profile; website footer | — | Street, city, state, ZIP |
| 10 | **Revenue 2022** | Provided P&L / tax return | ZoomInfo/Growjo/Dun&Bradstreet estimate; industry × headcount benchmark | USD, `(est.)` if not from P&L |
| 11 | **Revenue 2023** | same as above | same | same |
| 12 | **Revenue 2024** | same | same | same |
| 13 | **Revenue 2025** | Provided YTD + run-rate annualization; listing disclosure | If YTD only: annualize and label `(est., YTD × 12/n)` | same |
| 14 | **Net / free cash flow 2022** | Tax return (Line 21 on 1120 or similar); CIM add-backs | Industry EBITDA margin × revenue, then subtract taxes/CapEx `(est.)` | USD |
| 15 | **Net / free cash flow 2023** | same | same | same |
| 16 | **Net / free cash flow 2024** | same | same | same |
| 17 | **Net / free cash flow 2025** | Provided YTD | Annualized from YTD `(est.)` | same |
| 18 | **Asking price** | BizBuySell, BizQuest, Axial, broker listing, direct from seller/broker | If unlisted: derive from EBITDA × stated multiple | USD |
| 19 | **% revenue growth YoY** | Computed from fields 10–13 | — | % per year; show each YoY % separately |
| 20 | **Yearly revenue retention** | CIM; churn disclosures; contract renewal rates | Leave blank if not disclosed | % |
| 21 | **EBITDA margin** | Computed from EBITDA / revenue | If EBITDA estimated, label as `(est.)` | % |
| 22 | **Customer LTV** | Only if provided by seller | **LEAVE BLANK** — do not estimate | USD |
| 23 | **Customer CAC** | Only if provided by seller | **LEAVE BLANK** — do not estimate | USD |
| 24 | **Client concentration (largest customer %)** | CIM; direct disclosure | Leave blank if not disclosed — never guess | % |
| 25 | **Link to 2024 financials + YTD (P&L + BS)** | Data room URL; provided attachment path | — | URL or file path |
| 26 | **Lead Score** | Computed from `buy-box-and-scoring.md` rubric | — | XX / 100 |

---

## Cross-cutting research sources by goal

### Founding date / history
1. State Secretary of State business search (authoritative)
2. Wayback Machine (first capture of website)
3. LinkedIn company page "Founded"
4. OpenCorporates
5. News archive for founding-era articles

### Employee count
1. LinkedIn company page (current headcount — good proxy for FTE)
2. ZoomInfo / Growjo / Apollo
3. Glassdoor "company size" band
4. State Department of Labor / unemployment insurance data
5. CIM (if provided)

### Revenue & EBITDA estimation (when docs are missing)
1. ZoomInfo / Growjo / Owler estimates (label `(est.)`)
2. Industry revenue-per-employee benchmarks (IBISWorld, RMA Annual Statement Studies)
3. Public comps' margin × this target's estimated revenue
4. Cross-check with asking price ÷ typical multiple for the industry

Always show the math in the Appendix when estimating.

### Real estate
1. County tax assessor (authoritative for ownership + value)
2. Zillow / LoopNet (market-rate cross-check)
3. CIM real estate exhibit
4. SBA 504 loan public records

### Principals and leadership
1. LinkedIn profiles
2. Company "About" / "Team" page
3. State Bar profile (for law firms)
4. FAA airman registry (for aviation principals)
5. Podcast appearances, speaker bios, conference talks
6. Press releases and news mentions
7. Industry awards and association memberships
8. University alumni magazines (education + history)

### Contact information
1. Website contact page and email footer
2. LinkedIn "Contact info"
3. SOS registered agent (for legal address)
4. ZoomInfo / Apollo (for direct dials, if available)

### Customer / revenue mix
1. CIM
2. Case studies and testimonials on website (infer anchor customers)
3. SEC EDGAR (if any customer is public and discloses this vendor)
4. Federal contract data — USASpending.gov — if the target is a gov contractor

---

## Industry-specific sources

### Aerospace
- **FAA Repair Station Directory** — confirm Part 145 / Part 135 / Part 121 certifications.
- **FAA Airman Registry** — for A&P mechanic counts and principals' certifications.
- **NTSB database** — incidents involving the shop.
- **USASpending.gov / SAM.gov** — for DOD / government contract history.

### Law firms (PI)
- **State bar membership search** — confirm principals' admissions and good standing.
- **PACER / state court dockets** — approximate case volume and settlement history.
- **State AG consumer complaints** — red flags.

### Nuclear pharmacy / cardiac / medical
- **NRC licensing search** — for radioactive material licenses.
- **USP 797/800 compliance records** — state board of pharmacy.
- **CMS NPI registry** — for principal providers.
- **State board of pharmacy** — licensing status.

### Precious metals
- **EPA RCRA permits** — recyclers need these.
- **LBMA Good Delivery list** — for credible refiners.
- **State DEQ / environmental records.**

### Home services (garage door / locksmith / HVAC / plumbing)
- **State contractor license lookup** — confirm active license.
- **BBB accreditation and complaints.**
- **Google Reviews / Yelp** — rough size and tenure indicator.

### Emergency management
- **SAM.gov** — contract awards.
- **FEMA contractor registry.**
- **State emergency management agency contract lists.**

### Printing
- **PRINTING United Alliance member list.**
- **EPA permits for ink/solvent emissions.**

### Organ transport
- **UNOS / OPO partnership disclosures.**
- **DOT / FMCSA registration** for the vehicles/drivers.

---

## Estimation method disclosures (required in Appendix)

Every estimated field must appear in the Appendix as:

> **Field #X — {{Field Name}}** — Estimated at **{{value}}**.
> **Method:** {{formula or reasoning, e.g., "ZoomInfo lists 28 employees; industry avg revenue/FTE for NAICS 561730 = $185K → $5.18M (est.) rev"}}.
> **Sources:** {{URLs actually fetched}}.

Never write "estimated from industry average" without naming the industry average and the source for it.
