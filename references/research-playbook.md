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

### Sign language, CART & translation/interpretation services (roll-up add-on for Applied Development)
- **RID (Registry of Interpreters for the Deaf)** — search for certified interpreters affiliated with the company; indicates bench depth and quality.
- **State interpreter licensure databases** — many states require ASL interpreter licensing; verify active status.
- **USASpending.gov / SAM.gov** — federal contracts for interpreting services (courts, VA, Social Security, etc.).
- **State/county school district vendor lists** — education is a major buyer of ASL interpreting; check if the target is an approved vendor.
- **FCC TRS (Telecommunications Relay Service) provider list** — for VRI / video relay providers.
- **State Vocational Rehabilitation (VR) agency vendor rosters** — another recurring government channel.
- **Court interpreter registries** — federal and state court-certified interpreter rosters.
- **LinkedIn** — interpreter headcount, company size, key personnel.
- **Google Business Profile / Yelp** — coverage area and reviews from deaf community members.
- **National Association of the Deaf (NAD)** and **Conference of Interpreter Trainers (CIT)** — membership and community standing.
- **ATA (American Translators Association)** — for spoken/foreign-language translation & interpreting agencies (all of NAICS 541930 is in scope); membership and certified-translator counts. (Verify against the association's current directory.)

### Commercial waste management (roll-up add-on for Fambro Waste Management)
- **State solid-waste hauler permits / transporter licenses** — required to operate; confirms legitimacy and geographic coverage.
- **EPA RCRA / state DEQ records** — for recycling/transfer-station permits.
- **DOT / FMCSA** — motor carrier authority, fleet size, safety rating (SAFER system).
- **Municipal franchise agreements** — some jurisdictions grant exclusive or semi-exclusive hauling rights; strong recurring revenue indicator.
- **State contractor license boards** — for construction-related waste haulers needing contractor licenses.
- **USASpending.gov / SAM.gov** — federal construction site waste contracts.
- **NWRA (National Waste & Recycling Association)** membership.
- **Construction & Demolition Recycling Association (CDRA)** member directory.
- **Google Business Profile** — service area, reviews, fleet photos (estimate truck count).
- **BizBuySell / BizQuest** — asking price and listing details for waste haulers for sale.

### SBIC GP / management-company targets
- **SBA SBIC Program Office** — the SBA licenses and regulates SBICs; use SBA records to confirm the SBIC license exists, is active, and is **in good standing**. This good-standing confirmation is the central screening step. (Verify the current SBA SBIC directory / licensee-lookup URL — the SBA reorganizes its site periodically.)
- **SBIC license number** — confirm against SBA records; note license type and issue date.
- **SBA enforcement / capital-impairment status** — check for any SBA enforcement action, transfer-of-control restriction, or capital impairment that would break "good standing".
- **SBA annual financial reporting (SBA Form 468)** — SBICs file annual financials with the SBA. Verify the current form number/format against SBA guidance; use it (if obtainable) for fund-level financials. (Informational.)
- **Form ADV / SEC IAPD** — if the management entity is also a registered investment adviser, its Form ADV (SEC Investment Adviser Public Disclosure database) discloses AUM, ownership, and disciplinary history. (Informational.)
- **Outstanding SBA leverage** — amount and tier of SBA-guaranteed debentures; relevant to the change-of-control analysis. (Informational.)
- **Change-of-control review** — confirm with SBA counsel that a buyer can obtain SBA approval to transfer control of the license; this is a closing condition.
- **SBIC industry associations** — e.g., the Small Business Investor Alliance (SBIA) — for membership and standing.
- **State business registries** — for the GP / management legal entity, officers, and registered agent.

---

## Estimation method disclosures (required in Appendix)

Every estimated field must appear in the Appendix as:

> **Field #X — {{Field Name}}** — Estimated at **{{value}}**.
> **Method:** {{formula or reasoning, e.g., "ZoomInfo lists 28 employees; industry avg revenue/FTE for NAICS 561730 = $185K → $5.18M (est.) rev"}}.
> **Sources:** {{URLs actually fetched}}.

Never write "estimated from industry average" without naming the industry average and the source for it.
