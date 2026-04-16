---
name: Overnight Search
description: Runs the EarnedOut overnight published-listing search pipeline. Searches DealStream (authenticated), BizBuySell, BizQuest, and other platforms for businesses matching the buy box. Validates links via Playwright, captures screenshots, deduplicates against Airtable (with price-drop detection), runs prospect evaluation on every new lead, creates Airtable records, drafts broker outreach, and generates a daily HTML dashboard. Use when the user says "run the overnight search", "search for listings", "find new deals", or on a nightly schedule.
---

# Overnight Search Skill

You are running the EarnedOut overnight published-listing search pipeline. This skill searches multiple business-for-sale platforms, validates every link, scores every lead, and populates Airtable with fully evaluated prospects.

## Before you start

1. **Read configuration:** Load `config/search_config.md` for Airtable field IDs, platform URLs, industry keywords, and output paths.
2. **Read outreach templates:** Load `config/outreach_templates.md` for broker email templates.
3. **Read prospect-evaluation skill:** Load `.claude/skills/prospect-evaluation/skill.md` — you will invoke this for every new lead.

## Step 1: Authenticate

### 1Password credential retrieval
```bash
op read "op://Private/DealStream/username"
op read "op://Private/DealStream/password"
```
If `op` fails (not installed or not signed in), **stop immediately** with a clear error. Do not proceed without credentials.

### Playwright browser session
Launch a Playwright browser session. Navigate to `https://www.dealstream.com/login`. Enter the retrieved username and password. Verify login succeeds by checking for the authenticated dashboard or profile element. If login fails, log the error and continue with public-only platforms.

## Step 2: Search All Active Platforms

For each active industry in `config/search_config.md`:

### 2a. DealStream (Authenticated)
- Navigate to DealStream search with industry keywords + geography filters
- Paginate through all results pages
- For each listing, extract:
  - **Direct listing URL** (e.g., `dealstream.com/d/biz-sale/trade-contractor/6a89ka`)
  - **Listing ID** (e.g., `6a89ka`) — the last path segment
- **CRITICAL:** Extract the URL that links to the individual business detail page. NEVER store a search-results page URL.

### 2b. BizBuySell (Public)
- Search via web search: `site:bizbuysell.com [INDUSTRY_KEYWORDS] [STATE]`
- Or navigate directly: `bizbuysell.com/businesses-for-sale/` with filters
- Extract direct listing URLs and listing IDs from URL patterns
- Listing ID = numeric ID at end of URL

### 2c. BizQuest (Public)
- Same approach as BizBuySell
- Listing URL pattern: `bizquest.com/listing/{listing-id}/`

### 2d. Other Platforms
- Search for listings on any additional platforms found via web search
- Always extract the direct listing URL — never a search-results page

### Critical Rule
**NEVER store a search-results page URL as a listing link.** Every lead must have a URL that resolves to a single business detail page. If a search result doesn't have a detail-page link, skip it.

## Step 3: Validate Each URL + Screenshot (Playwright)

For each candidate URL:

1. **Navigate** to the URL in Playwright
2. **Validate content:** Check that the page contains listing-specific content (business name, asking price, description). Look for:
   - Positive signals: specific business name, price, location, financial details
   - Negative signals: "listing removed", "no longer available", "page not found", generic search results, login walls
3. **If valid:**
   - Capture a full-page screenshot → save as `output/screenshots/{listing-id}.png`
   - Record: `Link Health Status = Live`, `Link Last Checked = [today's date]`
4. **If dead/removed/generic:**
   - Log the URL and reason
   - Record: `Link Health Status = Dead`
   - Skip to next listing
5. **If redirect:**
   - Record: `Link Health Status = Redirect`
   - Follow the redirect and validate the destination
   - If destination is a valid listing, proceed; otherwise skip

## Step 4: Extract Structured Data

From each validated listing page, extract all available fields:

| Field | Where to find |
|-------|---------------|
| Business Name | Page title, heading, or listing header |
| Industry | Category tags, description |
| Location (City, State) | Address section or location field |
| Asking Price | Price field, financial summary |
| Revenue (latest year) | Financial details section |
| EBITDA or SDE | Financial details section |
| Years in Business | Established date or "years" field |
| Employee Count | Staffing section |
| Broker Name | Contact section, listing agent |
| Broker Contact | Email/phone in contact section |
| 2024 Revenue / Cash Flow | Financial details |
| 2025 Revenue / Cash Flow | Financial details (if disclosed) |

For any field not on the listing page, mark as "needs broker follow-up" — do not fabricate.

## Step 5: Deduplicate Against Airtable (with Price-Drop Detection)

Query existing records from `tblSmNrHROMLm7vOS` (base `appOsvuyy5eK43QTx`).

### Match criteria (check both):
- **Name + Address match:** Business Name + Business Address (existing dedup logic)
- **Listing ID + platform match:** Listing ID field matches (new dedup logic)

### For each candidate:

**Not in Airtable → New lead:**
- Proceed to Step 6 (prospect evaluation)

**In Airtable, same or higher price → Duplicate:**
- Skip, log as duplicate
- Update `Link Last Checked` to today

**In Airtable, LOWER price on website → Price drop:**
1. Store the old Airtable price in `Previous Asking Price`
2. Update `Asking Price` with the new lower price
3. Set `Date Updated` to today
4. Re-run prospect evaluation (Step 6) — lower price may change the score
5. Update the Airtable record with new Lead Score, new report
6. Add to Notes: `"PRICE DROP: was $[OLD], now $[NEW] ([DATE])"`
7. Draft fresh broker outreach using Template D (price-drop template)
8. Flag for dashboard Section A with "PRICE DROP" badge

## Step 6: Prospect Evaluation

For EVERY new lead and every price-drop update:

1. **Create output directory:** `output/reports/{listing-id}/`
2. **Invoke the prospect-evaluation skill** (`.claude/skills/prospect-evaluation/skill.md`) with the extracted data
   - Pass: business name, industry, location, financials, employee count, asking price, broker info, listing URL, screenshot path
   - The skill runs: Buy Box screening → 26-field scorecard → 0–100 lead score → full deal memo
3. **Capture outputs:**
   - `output/reports/{listing-id}/{slug}-report.md`
   - `output/reports/{listing-id}/{slug}-report.html`
4. **Extract the lead score** from the generated report header

## Step 7: Create/Update Airtable Record

### For new leads — create record with ALL fields:

**Existing field mappings** (use field IDs from `config/search_config.md`):
- Business Name, Industry Match, Business Address, Website, Lead Source, Broker Name, Asking Price, EBITDA, EBITDA Margin, Years in Business, Qty FT Employees, NAICS Code, Status, Priority Geography, Track, Tier

**New field mappings:**
- `Listing ID` → platform-specific listing ID
- `Direct Listing URL` → validated business detail page URL (NEVER a search-results page)
- `Listing Screenshot` → attach the PNG from `output/screenshots/{listing-id}.png`
- `Date Added` → today's date
- `Date Updated` → today's date
- `Link Health Status` → "Live"
- `Link Last Checked` → today's date
- `Disposition` → "Active"
- `Lead Score` → score from prospect evaluation
- `Prospect Eval Report` → path to HTML report
- `Revenue 2025` → if disclosed
- `Cash Flow 2025` → if disclosed
- `Source` → "Overnight Search"

**Notes field:** Always include:
```
[BUSINESS_NAME] | Listing ID: [LISTING_ID]
Direct URL: [DIRECT_LISTING_URL]
Lead Score: [SCORE]/100
[One-line summary from prospect evaluation]
```
NEVER reference a search-results page in Notes.

### For price-drop updates — update existing record:
- Update: Asking Price, Previous Asking Price, Date Updated, Lead Score, Prospect Eval Report, Notes (append price drop note)

## Step 8: Draft Broker Outreach

For each new lead (and price-drop re-outreach):

1. **Select template** from `config/outreach_templates.md`:
   - Aviation → Template C
   - Price drop → Template D
   - All others → Template A
2. **Personalize:** Fill in all placeholders (broker name, business name, listing ID, industry, location, years, specific details from the listing)
3. **A/B subject line:** Odd listing IDs → Variant 1, Even → Variant 2
4. **Store outreach:**
   - Append to Airtable Notes field
   - Append to `search_reports/outreach_drafts_YYYY-MM-DD.md`
5. **Revisit for Roll-up leads:** Defer outreach (do not draft until disposition changes)

## Step 9: Generate Daily HTML Dashboard

Generate `output/dashboards/dashboard_YYYY-MM-DD.html` using the template at `templates/daily-dashboard.html`.

### Section A: Last Night's New Finds (+ Price Drops)
- All new leads found in this run + all price-drop updates
- Sorted by lead score descending
- Each row: Rank, Score, Business Name, Industry, State, Asking Price, EBITDA, Source, Report Link
- Price drops show badge: "PRICE DROP: was $X → now $Y"
- Manual submissions from today also appear here

### Section B: Running Queue (All Active Leads)
- Query Airtable for ALL records where Disposition = "Active"
- Sorted by Lead Score descending
- Shows Date Added column for age tracking
- Same table format as Section A

### Section C: Revisit Bucket
- Query Airtable for records where Disposition = "Revisit for Roll-up"
- Sorted by Lead Score descending
- These are too small for foundation acquisition but potential roll-up targets

### Section D: Run Summary
- Total leads searched this run
- New leads found
- Duplicates skipped
- Dead links caught
- Price drops detected and re-evaluated
- Manual submissions added (if any)
- Leads per industry breakdown
- Leads per platform breakdown
- Any errors or platform blocks encountered

## Step 10: Final Logging

1. Write a run summary to `search_reports/run_log_YYYY-MM-DD.md`
2. Update the Ralph loop iteration counter in `.claude/ralph-loop.local.md`
3. Report completion with: total new leads, price drops, dashboard path

## Error Handling

- **1Password failure:** Stop with clear error. Do not search DealStream without auth.
- **Playwright failure:** Log error, skip the specific URL, continue with remaining URLs.
- **Airtable API failure:** Retry once. If still failing, log the lead data locally and flag for manual entry.
- **Platform blocks/CAPTCHAs:** Log the platform and error, skip that platform, continue with others.
- **No new leads found:** Still generate the dashboard (Sections B, C, D will have content from existing records).
