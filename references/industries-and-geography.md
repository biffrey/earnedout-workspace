# Target Industries, Exclusions, and Geography

Use this file during Step 3 (industry + geography gate) of the workflow. An industry match is worth 20 points on the rubric — but more importantly, it determines whether a prospect should exist in the funnel at all.

---

## 1. Target industries

Broaden searches with the keywords listed for each. A target industry match is **required** for a full rubric score on line 1.

### Aerospace — TOP PRIORITY
**Keywords:** Part 145, Part 135, Part 121, FAA repair station, avionics, aircraft maintenance, helicopter maintenance, aircraft charter, MRO, engine overhaul, component repair.
**Notes:** Verify certifications via the FAA repair station directory. DOD / government aerospace support is fine. **Weapons components are excluded.**

### Marketing
**Keywords:** digital marketing agency, creative agency, social media agency, performance marketing, PPC, SEO agency, branding agency, content studio.

### Personal Injury Law Firms
**Keywords:** auto accident, injury attorney, PI practice, litigation firm, tort, mass tort, plaintiff's firm.
**Notes:** Law firms are restricted to specific states — see §3 below. If the firm is domiciled outside the allowed jurisdictions, **reject**.

### Emergency Management Firms
**Keywords:** disaster recovery, emergency response planning, incident management, EOC consulting, FEMA contractor, continuity of operations (COOP).

### Cardiac / Medical
**Keywords:** locum tenens, cardiology, cardiac, vein clinic, vascular clinic, interventional cardiology, peripheral vascular.

### Nuclear Pharmacy — TARGET SUBSET ONLY
**Allowed:**
- Radiopharmaceutical compounding pharmacies
- Chemotherapy / oncology drug compounding or dispensing facilities

**Not allowed:** Retail nuclear-medicine resellers, nuclear imaging clinics, general compounding pharmacies. Verify NRC licensing and USP 797/800 compliance.

### Printing Businesses
**Keywords:** commercial print shop, label printing, industrial printing, flexographic, digital press, packaging printing.

### Architectural Design
**Keywords:** interior design firm, furniture design studio, boutique architecture firm, workplace strategy, hospitality design.

### Precious Metals — TARGET SUBSET ONLY
**Allowed:**
- Refiners
- Recyclers

**Keywords:** platinum, palladium, tin recycling, metal reclaim, PGM refining, catalytic converter recycling, precious metals assay.
**Not allowed:** Jewelry retailers, coin dealers, pawn shops, bullion resellers.

### Organ Transport Companies
**Keywords:** medical courier, transplant organ logistics, time-critical medical transport, specimen transport, OPO logistics.

### Home Services — LIMITED SUBSET
**Allowed (and only these):**
- Garage door companies
- Locksmiths
- HVAC
- Plumbing

**Not allowed:** Landscaping, pest control, roofing, painting, cleaning, general handyman, etc. Reject any home-services target not in the four allowed verticals.

---

## 2. Exclusions (automatic reject — reason in report)

- **Restaurants** — all types.
- **Retail stores** — brick-and-mortar retail, e-commerce consumer retail. (Precious metals recyclers/refiners are NOT retail.)
- **Distressed businesses** — insolvent, negative cash flow, EBITDA declining, under forbearance, in Ch. 11.
- **Weapons manufacturers or sellers** — firearms, ammunition, explosives, missile components, targeting systems intended for weapons.

**Explicitly allowed (NOT excluded):**
- Government contractors
- DOD contractors
- Cybersecurity firms
- Aerospace support and MRO
- Emergency management firms

If an aerospace target makes dual-use parts and you're uncertain whether they're a "weapons manufacturer", flag it in the Risk Factors section and pass the decision to the user.

---

## 3. Geography

**Required:** United States only. Reject non-US businesses.

**Priority regions (bonus narrative, same scoring):**
- Mid-Atlantic — Maryland, DC, Virginia
- Louisiana
- Florida
- Texas

**Remote / location-agnostic:** Allowed if the business is operationally US-based.

### Law-firm jurisdiction rule (REQUIRED — apply strictly)

Personal injury law firms may only be pursued if domiciled in one of these jurisdictions:

| Jurisdiction | Rationale |
|---|---|
| **Arizona (AZ)** | Arizona's rules permit non-attorney ownership of law firms (ABS — Alternative Business Structure). |
| **Puerto Rico (PR)** | Non-attorney ownership is currently permitted under PR rules. |
| **Utah (UT)** | Utah's legal-services sandbox program allows non-attorney ownership of participating firms. |
| **Maryland (MD)** | Allowed because partner **Brandon Thornton** is admitted to the bar in Maryland — ownership is covered through him. |
| **District of Columbia (DC)** | Allowed because partner **Brandon Thornton** is admitted to the DC bar. |
| **Virginia (VA)** | Allowed because partner **Brandon Thornton** is admitted to the Virginia bar. |

**All other states: reject law-firm targets.** State the reason in the report: "Law firm domiciled in <state>, which does not permit non-attorney ownership and is outside Brandon Thornton's bar admissions."

If the firm is multi-state, the rule applies to the state of registration / primary operations. Confirm the state from the state bar listing or the firm's Secretary of State filing — not just the website.

---

## 4. Quick decision table

| Industry / situation | Accept? |
|---|---|
| FAA Part 145 repair station (non-weapons), TX | ✅ |
| Missile guidance subassembly manufacturer | ❌ (weapons exclusion) |
| Digital marketing agency, FL | ✅ |
| PI law firm, AZ | ✅ |
| PI law firm, CA | ❌ (state not allowed) |
| PI law firm, MD | ✅ (Brandon Thornton jurisdiction) |
| Nuclear pharmacy doing oncology compounding, TX | ✅ |
| Retail nuclear-medicine reseller | ❌ (not target subset) |
| Platinum refiner, LA | ✅ |
| Coin / bullion retailer | ❌ (retail + not target subset) |
| HVAC company, VA | ✅ |
| Landscaping company, TX | ❌ (not allowed home-services subset) |
| Organ transport courier, FL | ✅ |
| Printing — commercial print shop, DC | ✅ |
| Restaurant chain, anywhere | ❌ |
| Distressed cardiac clinic, FL | ❌ (distressed) |
| UK-based marketing agency serving US clients | ❌ (not US-based) |
