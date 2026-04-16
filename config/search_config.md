# Search Configuration

## Airtable

| Setting | Value |
|---------|-------|
| Base ID | `appOsvuyy5eK43QTx` |
| Table ID | `tblSmNrHROMLm7vOS` |
| Table Name | Master Deal Pipeline |

## Airtable Field IDs

### Existing Fields
| Field | ID |
|-------|-----|
| Business Name | `fldquYtYnHJ1YzUR7` |
| Industry Match | `fldyJH0ZsOJD29wEg` |
| Subsector | `fldtwmCfS4QrDo0GL` |
| Business Address | `fldkVBunWYKdXkgpB` |
| Priority Geography? | `fld1x82ld7D0UYjHw` |
| Website | `fldTRaz0PzBYS9ICl` |
| Links | `fldwo7ui7aIGoMxAG` |
| Lead Source | `fldI1h3qmNI6vc5rr` |
| Broker Name | `fldXdZC8Tbrbk8ysk` |
| Owner Name | `fldfa10GqZ1FfinQW` |
| Owner Age (Est.) | `fld3p7XUTIOtUmLvA` |
| Contact Email | `fldlOcCvi9SSCoIu2` |
| Contact Phone | `fldlsBbVahZqAiMHd` |
| Contact Information | `fldFRlWmriYvpLCC3` |
| NDA Status | `fldhmc4rPJmgwXoWR` |
| CIM Received? | `fldqcUc5Rl6ZTplUe` |
| Last Contacted | `fldPfxpwLUTCYRbas` |
| Follow-up Date | `fldLxdM1uMXoxZmhA` |
| Years in Business | `fldhdqJ0Ow0Z608Pl` |
| Qty FT Employees | `fldgvFTCdDauWZDr3` |
| Asking Price | `fldhqAXiAWh2ktXln` |
| EBITDA | `fldFK17soNXcUsxbg` |
| EBITDA Margin | `fldufGAWn6iv9axWa` |
| NAICS Code | `fldNoi4yt9l4oHwcu` |
| Status | `fldB0LCiJMUuKVd6y` |
| Track | `fldAZYJlGy2R95TSn` |
| Tier | `fldCGASC27dR0fJz8` |
| Notes | `fldbEqYoyoPNthNoV` |
| Revenue 2022 | `fldKEgHGYPyE5bLGt` |
| Revenue 2023 | `fldwmM2jq4LKliud8` |
| Revenue 2024 | `fldfUOMF98BAk8Qeo` |
| Cash Flow 2022 | `fldQ8gw6xRXGB9AD9` |
| Cash Flow 2023 | `fldeQR4uLjTtOeqk7` |
| Cash Flow 2024 | `fldwX2NkTE2E66pln` |
| DSCR | `fldBUi4NSUCn4emsd` |
| Document Files | `fldP3dzbLo41Ds19q` |

### New Fields (created by revamp)
| Field | ID | Type |
|-------|-----|------|
| Listing ID | `fld81k0uFwqkHaEEI` | singleLineText |
| Direct Listing URL | `fldMCmSVQjYv3odok` | url |
| Listing Screenshot | `fldrPuxZHGsYZuxTO` | multipleAttachments |
| Date Added | `fldoZVwrhWaGGMlFR` | date |
| Date Updated | `fld3TRpVYopXL7LLm` | date |
| Previous Asking Price | `fldySRjfm1P8Nodes` | currency |
| Link Health Status | `fldlsuLeSFhFKQuFc` | singleSelect |
| Link Last Checked | `fldMXwyQbEWPXbqE2` | date |
| Disposition | `fldw0xk1YBkmP7sBD` | singleSelect |
| Lead Score | `fld2ipICYNLjaDm39` | number |
| Prospect Eval Report | `fld9InVXs4RqgtNDo` | url |
| Revenue 2025 | `fld8Pmhi9M7m5qaUf` | currency |
| Cash Flow 2025 | `flde6Fr88nm4BAoE1` | currency |
| Source | `fldiGyXTk6Ybb6J1L` | singleSelect |

## Credential Retrieval

```bash
op read "op://Private/DealStream/username"
op read "op://Private/DealStream/password"
```

## Search Platforms

### DealStream (Authenticated)
- **Login URL:** `https://www.dealstream.com/login`
- **Search URL:** `https://www.dealstream.com/businesses-for-sale`
- **Auth method:** 1Password CLI → form login via Playwright
- **Listing URL pattern:** `dealstream.com/d/biz-sale/{category}/{listing-id}`
- **Listing ID extraction:** Last segment of the URL path

### BizBuySell (Public)
- **Search URL:** `https://www.bizbuysell.com/businesses-for-sale/`
- **Listing URL pattern:** `bizbuysell.com/Business-Opportunity/{slug}/{listing-id}/`
- **Listing ID extraction:** Numeric ID at end of URL

### BizQuest (Public)
- **Search URL:** `https://www.bizquest.com/businesses-for-sale/`
- **Listing URL pattern:** `bizquest.com/listing/{listing-id}/`
- **Listing ID extraction:** Numeric ID after `/listing/`

## Search Industries and Keywords

Per `references/industries-and-geography.md`:

| Industry | Keywords |
|----------|----------|
| Aerospace | Part 145, Part 135, FAA repair station, avionics, aircraft maintenance, MRO, engine overhaul |
| Marketing | digital marketing agency, creative agency, performance marketing, SEO agency |
| PI Law Firms | auto accident, injury attorney, PI practice, litigation firm (AZ, PR, UT, MD, DC, VA only) |
| Emergency Management | disaster recovery, emergency response planning, FEMA contractor |
| Cardiac / Medical | locum tenens, cardiology, vein clinic, vascular clinic |
| Nuclear Pharmacy | radiopharmaceutical compounding, oncology drug compounding |
| Printing | commercial print shop, label printing, industrial printing |
| Architectural Design | interior design firm, boutique architecture firm, workplace strategy |
| Precious Metals | platinum refining, palladium recycling, PGM refining, catalytic converter recycling |
| Organ Transport | medical courier, transplant organ logistics, specimen transport |
| Home Services | garage door, locksmith, HVAC, plumbing |

## Geography

- **Required:** United States only
- **Priority:** MD, DC, VA, LA, FL, TX
- **State filters for search:** All US states, priority states searched first

## Output Paths

| Output | Path |
|--------|------|
| Screenshots | `output/screenshots/{listing-id}.png` |
| Prospect eval reports | `output/reports/{listing-id}/` |
| Daily dashboards | `output/dashboards/dashboard_YYYY-MM-DD.html` |
| Outreach drafts | `search_reports/outreach_drafts_YYYY-MM-DD.md` |
| Run logs | `search_reports/` |
