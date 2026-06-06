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
op read "op://Personal/dealstream.com/username"
op read "op://Personal/dealstream.com/password"
```

## Search Platforms

### DealStream (Authenticated)
- **Login URL:** `https://www.dealstream.com/login`
- **Search URL:** `https://www.dealstream.com/businesses-for-sale`
- **Auth method:** 1Password CLI → form login via Playwright
- **Listing URL pattern:** `dealstream.com/d/biz-sale/{category}/{listing-id}`
- **Listing ID extraction:** Last segment of the URL path

### BizBuySell (Public)
- **Search method:** Navigate **category pages** with the browser — do **NOT** use the
  `?q=` keyword search or generic `site:bizbuysell.com` web search. BizBuySell
  bot-protects the `?q=` search endpoint (returns HTTP 403 / a "Powered and protected"
  challenge); `site:` web search returns category pages, not detail URLs.
- **⚠ Headless automation is also blocked.** Category pages load in a **real browser**
  (full Chrome fingerprint — verified in the connected Claude-in-Chrome browser
  2026-06-04), but a **headless** `chrome-headless-shell` request to the same category
  page is **403-challenged** (also verified). Detail pages are more lenient (headless
  Playwright reached listing 2455028's detail page fine). **Resolution (in place
  2026-06-04):** the Playwright MCP is now configured (`config/playwright-mcp.json`) to
  launch **real Google Chrome** — `channel: "chrome"`, **headed**,
  `--disable-blink-features=AutomationControlled`, `ignoreDefaultArgs:
  ["--enable-automation"]`, persistent `userDataDir` — which is **not** challenged on
  category pages (verified: HTTP 200, surfaced listing 2455028). So the normal Playwright
  browser session can sweep BizBuySell category pages directly. Because it is **headed**,
  the run must execute in the logged-in GUI session (the 10:00 ET slot, operator present).
  If a category page is ever still challenged, mark BizBuySell **"blocked — coverage
  incomplete"** and use manual submission (`submit-url`) for forwarded listings — never
  report a block as "0 available." (A paid anti-bot scraper is planned as the durable
  long-term path.)
- **Category page pattern:** `https://www.bizbuysell.com/{state}/{category-slug}/`
  (omit `{state}/` for all states). Paginate via the trailing `/2/`, `/3/`, … path.
- **Listing URL pattern:** `bizbuysell.com/business-opportunity/{slug}/{listing-id}/`
- **Listing ID extraction:** Numeric ID at end of URL.
- **⚠ Taxonomy trap — ASL / sign language:** BizBuySell files sign-**language** /
  interpreting businesses under **Manufacturing › Signs** — category
  "Sign Manufacturers and Businesses", slug `sign-manufacturers-and-businesses-for-sale`
  — mixed in with sign-**making** companies. The ASL vertical MUST scan that category
  (plus `other-communication-and-media-businesses-for-sale` and generic service
  categories) and disambiguate by title/description, never by category alone. Verified:
  listing 2455028 ("ASL Interpretation Service", Oregon) sits in *Manufacturing › Signs*.
- **Keyword disambiguation (ASL vertical):** KEEP listings whose title/description contain
  ASL, sign language, interpreting, interpreter, deaf, hard of hearing, VRI, CART,
  captioning, translation, or language access. DROP pure signage/sign-making (custom
  signs, signage, banners, vinyl, awnings, vehicle wraps, recognition awards).
- **Never silently report 0:** if a category page returns a bot challenge/interstitial or
  fails to load, log it as "blocked — coverage incomplete", **not** "0 listings available".
- **Pacing + backoff (anti-bot), tunable:** throttle **3–8 s between category pages** and
  **2–5 s between detail fetches**; on a 403 / "Powered and protected" challenge, back off
  and retry the page — **~30 s then ~90 s, max 3 attempts** — before marking it blocked.
  (The block tripped after ~50 listings on 2026-06-06; pacing avoids it, backoff recovers
  from transient throttles. Full anti-bot durability is the planned paid-scraper path.)

### BizQuest (Public)
- **Search URL:** `https://www.bizquest.com/businesses-for-sale/`
- **Listing URL pattern:** `bizquest.com/listing/{listing-id}/`
- **Listing ID extraction:** Numeric ID after `/listing/`

## Search Industries and Keywords

Per `.claude/skills/prospect-evaluation/references/industries-and-geography.md`:

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
| Sign Language / Translation & Interpretation | ASL interpretation, sign language interpreting, VRI, CART, realtime captioning, deaf services, translation agency, foreign-language interpreting (NAICS 541930) — roll-up add-on for Applied Development |
| Commercial Waste | roll-off dumpster rental, C&D waste hauling, construction debris recycling, demolition cleanup, commercial dumpster service — roll-up add-on for Fambro Waste |
| SBIC | SBIC, Small Business Investment Company, SBA-licensed fund, SBIC management company, SBIC general partner |

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
