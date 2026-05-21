---
name: overnight-search
description: Runs the EarnedOut overnight published-listing search pipeline. Searches DealStream (authenticated), BizBuySell, BizQuest, and other platforms for businesses matching the buy box. Validates every link via Playwright, captures screenshots, deduplicates against Airtable with price-drop detection, runs the prospect-evaluation skill on every new lead and every price-drop, creates/updates Airtable records, drafts broker outreach, and generates a daily HTML dashboard. Use when the user says "run the overnight search", "search for listings", "find new deals", or on a nightly schedule.
---

# Overnight Search Skill

You are running the EarnedOut overnight published-listing search pipeline. This skill searches multiple business-for-sale platforms, validates every link, scores every lead through the prospect-evaluation skill, and populates Airtable with fully evaluated prospects. It maps directly to `REVAMP_PLAN.md` Steps 2–8.

## Before you start (plan Step 2a — Read Config)

1. **Read configuration:** Load `config/search_config.md` for Airtable field IDs, platform URLs, industry keywords, geography filters, and output paths.
2. **Read outreach templates:** Load `config/outreach_templates.md` for the broker email templates and template-selection logic.
3. **Read credential setup:** Load `config/credentials-setup.md` for the 1Password item path and the fail-loud requirement.
4. **Read the prospect-evaluation skill:** Load `.claude/skills/prospect-evaluation/skill.md` — you invoke this for every new lead and every price-drop update.

**Airtable target:** base `appOsvuyy5eK43QTx`, table `tblSmNrHROMLm7vOS` ("Master Deal Pipeline"). Existing Links field: `fldwo7ui7aIGoMxAG`.

## Step 1: Authenticate (plan Step 2a — Authenticate)

### 1Password credential retrieval

Retrieve the DealStream login at runtime via the 1Password CLI. The **canonical item path** (per `REVAMP_PLAN.md` Step 0 and `config/credentials-setup.md`) is:

```bash
op read "op://Private/DealStream/username"
op read "op://Private/DealStream/password"
```

**Fail loudly.** Before searching, check authentication (`op whoami`, or a trial `op read`). If `op` is not installed, not signed in, or the item cannot be read, **stop immediately**: print a clear error naming the missing/blocked step, exit non-zero, and do not continue. NEVER proceed to DealStream unauthenticated and NEVER fall back to cached, blank, or hard-coded credentials — unauthenticated access silently returns incomplete results.

### Playwright browser session

Launch a Playwright browser session. Navigate to `https://www.dealstream.com/login`. Enter the retrieved username and password. **Verify login succeeded before proceeding** — confirm an authenticated dashboard or profile element is present. If login fails despite valid credentials, log a clear error, record DealStream as a blocked platform in the run summary, and continue with the public-only platforms so the run still produces value.

## Step 2: Search All Active Platforms (plan Step 2b)

For each active industry in `config/search_config.md`:

### 2a. DealStream (Authenticated)
- Navigate to DealStream search with industry keywords + geography filters.
- Paginate through all results pages.
- For each listing extract the **direct listing URL** (e.g., `dealstream.com/d/biz-sale/trade-contractor/6a89ka`) and the **listing ID** (e.g., `6a89ka`, the last path segment).

### 2b. BizBuySell (Public)
- Web search: `site:bizbuysell.com [INDUSTRY_KEYWORDS] [STATE]`, or navigate `bizbuysell.com/businesses-for-sale/` with filters.
- Extract the direct listing URL and the listing ID (numeric ID at the end of the URL).

### 2c. BizQuest (Public)
- Same approach as BizBuySell. Listing URL pattern: `bizquest.com/listing/{listing-id}/`.

### 2d. Other Platforms
- Search any additional platforms found via web search. Always extract the direct listing URL.

### Critical rule — never store a search-results page URL
**NEVER store a search-results page URL as a listing link.** Every lead must have a URL that resolves to a single business detail page. If a search result does not link to a detail page, **skip it**.

## Step 3: Validate Each URL + Screenshot — Playwright (plan Step 2c)

For each candidate URL:

1. **Navigate** to the URL in Playwright.
2. **Validate content:** confirm the page has listing-specific content — specific business name, asking price, location, description. Negative signals: "listing removed", "no longer available", "page not found", a generic search-results grid, or a login wall.
3. **If valid:** capture a full-page screenshot → `output/screenshots/{listing-id}.png`. Record `Link Health Status = Live` and `Link Last Checked = [today]`.
4. **If dead/removed/generic:** log the URL and reason, record `Link Health Status = Dead`, and skip to the next listing.
5. **If redirect:** record `Link Health Status = Redirect`, follow the redirect, and validate the destination — proceed only if the destination is a valid listing.

## Step 4: Extract Structured Data (plan Step 2d)

From each validated listing page, extract every available field:

| Field | Where to find |
|-------|---------------|
| Business Name | Page title, heading, listing header |
| Industry | Category tags, description |
| Location (City, State) | Address or location field |
| Asking Price | Price field, financial summary |
| Revenue (latest year) | Financial details section |
| EBITDA or SDE | Financial details section |
| Years in Business | Established date or "years" field |
| Employee Count | Staffing section |
| Broker Name / Contact | Contact section, listing agent |
| 2024 Revenue / 2024 Cash Flow | Financial details |
| 2025 Revenue / 2025 Cash Flow | Financial details (if disclosed) |

For any field not present on the listing page, mark it "needs broker follow-up" — **do not fabricate values**.

## Step 5: Deduplicate Against Airtable — with Price-Drop Detection (plan Step 2e)

Query existing records from table `tblSmNrHROMLm7vOS` (base `appOsvuyy5eK43QTx`).

### Match criteria (check both)
- **Name + Address match:** Business Name + Business Address (existing dedup logic).
- **Listing ID + platform match:** the `Listing ID` field matches (new dedup logic).

### For each candidate

**Not in Airtable → new lead:** proceed to Step 6.

**In Airtable, same or higher price → duplicate:** skip, log as duplicate, update `Link Last Checked` to today.

**In Airtable, LOWER price on the website → price drop:**
1. Store the old Airtable price in `Previous Asking Price`.
2. Update `Asking Price` with the new lower price.
3. Set `Date Updated` to today.
4. Re-run prospect evaluation (Step 6) — a lower price may change the score.
5. Update the record with the new Lead Score and new report path.
6. Append to Notes: `PRICE DROP: was $[OLD], now $[NEW] ([DATE])`.
7. Draft fresh broker outreach using the price-drop template (Step 8).
8. Flag the lead for dashboard Section A with a "PRICE DROP" badge.

## Step 6: Prospect Evaluation (plan Step 3)

For EVERY new lead and EVERY price-drop update:

1. **Create the output directory:** `output/reports/{listing-id}/`. Save the extracted structured data as JSON and copy in the screenshot.
2. **Invoke the prospect-evaluation skill** (`.claude/skills/prospect-evaluation/skill.md`) with the lead data — business name, industry, location, financials, employee count, asking price, broker info, direct listing URL, screenshot path. It runs: Buy Box screening (6 hard criteria) → 26-field scorecard → 0–100 lead score with per-line math → full deal memo.
3. **Capture outputs:** `output/reports/{listing-id}/{slug}-report.md` and `output/reports/{listing-id}/{slug}-report.html`.
4. **Extract the lead score** from the generated report header.

Every lead now enters the pipeline already evaluated — no raw, unscored leads.

## Step 7: Create / Update the Airtable Record (plan Step 4)

### For new leads — create a record with ALL fields

**Existing field mappings** (use the field IDs in `config/search_config.md`): Business Name, Industry Match, Business Address, Website, Lead Source, Broker Name, Asking Price, EBITDA, EBITDA Margin, Years in Business, Qty FT Employees, NAICS Code, Status, Priority Geography, Track, Tier.

**New field mappings** (canonical live field names — see `REVAMP_PLAN.md` Step 1 "Live field-name reconciliation"):
- `Listing ID` → platform-specific listing ID
- `Direct Listing URL` → validated business detail page URL (NEVER a search-results page)
- `Listing Screenshot` → attach the PNG from `output/screenshots/{listing-id}.png`
- `Date Added` → today
- `Date Updated` → today (same as Date Added for new leads)
- `Link Health Status` → "Live"
- `Link Last Checked` → today
- `Disposition` → "Active" (default for every new lead)
- `Lead Score` → score from prospect evaluation
- `Prospect Eval Report` → path to the HTML report
- `Revenue 2024` → if disclosed
- `Cash Flow 2024` → if disclosed
- `Revenue 2025` → if disclosed
- `Cash Flow 2025` → if disclosed
- `Source` → "Overnight Search"

**Notes field — always include all four identifiers, never a search-results page:**
```
[BUSINESS_NAME] | Listing ID: [LISTING_ID]
Direct URL: [DIRECT_LISTING_URL]
Airtable record: [AIRTABLE_RECORD_URL]
Lead Score: [SCORE]/100
[One-line summary from the prospect evaluation]
```
Capture the Airtable record URL after the record is created (or, for updates, from the existing record) and write it back into Notes. NEVER reference a search-results page in Notes.

### For price-drop updates — update the existing record
Update: `Asking Price`, `Previous Asking Price`, `Date Updated`, `Lead Score`, `Prospect Eval Report`, and append the price-drop line to `Notes`.

## Step 8: Draft Broker Outreach (plan Step 5)

For each new lead (and each price-drop re-outreach):

1. **Select the template** from `config/outreach_templates.md` using the selection logic:
   - Aviation leads (Part 135, Part 145) → Aviation Template C
   - Price-drop re-outreach → price-drop follow-up template
   - All others → updated default template
2. **Personalize** every placeholder: broker name, business name, listing ID, industry, location, years in business, and specific details drawn from the listing.
3. **A/B test the subject line only** — rotate subject-line variants, never the body text.
4. **Store the draft** in two places: append it to the Airtable `Notes` field, and append it to `search_reports/outreach_drafts_YYYY-MM-DD.md`.
5. **Revisit for Roll-up leads:** defer outreach — do not draft until the disposition changes.
6. **Never send email.** This skill only drafts outreach; sending is always a manual human action.

## Step 9: Disposition Workflow (plan Step 8)

Every record carries a single `Disposition` single-select field. New leads default to **Active**. The full value set:

| Value | Meaning | When to use |
|-------|---------|-------------|
| Active | New lead, not yet reviewed | Default for all new leads |
| Contacted | Broker outreach sent | After sending email |
| Maybe Later | Interesting but not right now | Timing/market conditions |
| Revisit for Roll-up | Too small for foundation, valuable as a future add-on | Sub-$2M EBITDA companies in target industries |
| Passed | Reviewed and rejected | Does not fit the buy box or strategic criteria |
| Dead Link | Listing no longer available | Link validation finds the page is gone |

The daily dashboard filters on `Disposition`: Section B shows `Active` leads; Section C shows `Revisit for Roll-up`. "Maybe Later" and "Revisit for Roll-up" leads stay visible but grouped separately so they do not clutter the active pipeline. When link validation (Step 3) finds a previously-live listing is gone, set that record's `Disposition` to `Dead Link` and `Link Health Status` to `Dead`.

## Step 10: Generate the Daily HTML Dashboard (plan Step 7)

Generate `output/dashboards/dashboard_YYYY-MM-DD.html` from the template at `templates/daily-dashboard.html`.

- **Section A — Last Night's New Finds (+ Price Drops):** all new leads from this run plus all price-drop updates, sorted by lead score descending. Columns: Rank, Score, Business Name, Industry, State, Asking Price, EBITDA, Source, Report Link. Price drops show a "PRICE DROP" badge with "was $X → now $Y". Manual submissions from the same day also appear here.
- **Section B — Running Queue:** all Airtable records where `Disposition = "Active"`, regardless of when added, sorted by score descending, with a `Date Added` column for age.
- **Section C — Revisit Bucket:** all records where `Disposition = "Revisit for Roll-up"`, sorted by score.
- **Section D — Run Summary:** totals (leads searched, new leads, duplicates skipped, dead links caught), price drops detected/re-evaluated, manual submissions added, leads per industry, leads per platform, and any errors or platform blocks.

## Step 11: Final Logging

1. Write a run summary to `search_reports/run_log_YYYY-MM-DD.md` (counts, per-platform/per-industry breakdowns, errors).
2. Report completion: total new leads, price drops detected, and the dashboard path.

## Error Handling

- **1Password / `op` failure:** stop with a clear error (fail loud). Do not search DealStream without authentication.
- **DealStream login failure (valid creds):** log the error, mark DealStream blocked in the run summary, continue with public platforms.
- **Playwright failure on one URL:** log it, skip that URL, continue with the rest.
- **Airtable API failure:** retry once; if it still fails, log the lead data locally and flag it for manual entry.
- **Platform blocks / CAPTCHAs:** log the platform and error, skip that platform, continue with the others.
- **No new leads found:** still generate the dashboard — Sections B, C, and D render from existing records.
