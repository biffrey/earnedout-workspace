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

### Credential retrieval — environment variables (Keychain-backed)

The runner (`run-overnight-search.sh`) resolves the DealStream credentials **before**
invoking this skill and passes them in via environment variables:

```bash
$DEALSTREAM_USERNAME   # resolved from macOS Keychain (item: earnedout-dealstream-username)
$DEALSTREAM_PASSWORD   # resolved from macOS Keychain (item: earnedout-dealstream-password)
```

This is the **headless** auth path: the macOS login Keychain is unlocked whenever the
user is logged in, so the scheduled run authenticates with **no Touch ID prompt and no
1Password dependency**. (Service-account tokens are a 1Password Business feature; this is
an Individual account, so Keychain is the mechanism — see `config/credentials-setup.md`.)
If `$DEALSTREAM_USERNAME`/`$DEALSTREAM_PASSWORD` are empty, the runner has already tried
the `op read` fallback; on first-time/bootstrap you may also read directly with
`op read "op://Personal/dealstream.com/username"` (desktop integration, daytime only).

**Fail loudly — gate on the credentials, not on `op whoami`.** Authentication is
satisfied when **both** `$DEALSTREAM_USERNAME` and `$DEALSTREAM_PASSWORD` are non-empty —
proceed. **Do NOT call `op whoami`** (under desktop-app integration it always reports
"account is not signed in" even when credentials are valid; gating on it caused the
2026-05-23 → 06-04 dark period). Only **stop immediately** if either credential is empty:
print a clear error naming the blocked step, exit non-zero, and do not continue. NEVER
proceed to DealStream unauthenticated and NEVER fall back to blank or hard-coded
credentials — unauthenticated access silently returns incomplete results.

### Playwright browser session

Launch a Playwright browser session. Navigate to `https://www.dealstream.com/login`. Enter the retrieved username and password. **Verify login succeeded before proceeding** — confirm an authenticated dashboard or profile element is present. If login fails despite valid credentials, log a clear error, record DealStream as a blocked platform in the run summary, and continue with the public-only platforms so the run still produces value.

## Step 2: Search All Active Platforms (plan Step 2b)

For each active industry in `config/search_config.md`:

### 2a. DealStream (Authenticated)
- Navigate to DealStream search with industry keywords + geography filters.
- Paginate through all results pages.
- For each listing extract the **direct listing URL** (e.g., `dealstream.com/d/biz-sale/trade-contractor/6a89ka`) and the **listing ID** (e.g., `6a89ka`, the last path segment).

### 2b. BizBuySell (Public)
- **Method: navigate category pages with the browser — NOT the `?q=` keyword search.**
  BizBuySell bot-protects its `?q=` search endpoint (returns HTTP 403 / a "Powered and
  protected" challenge), so keyword search and generic `site:bizbuysell.com` web search
  are unreliable and silently return nothing usable.
- **Real-Chrome browser session (already configured).** Headless browsers are 403-blocked
  on BizBuySell category pages, so the Playwright MCP is configured (`config/playwright-mcp.json`)
  to launch **real headed Google Chrome** (`channel: chrome`, anti-automation flags,
  persistent profile), which passes (verified 2026-06-04). Just use the normal Playwright
  browser session to navigate the category pages — no special tool needed. (This is why the
  run is scheduled at 10:00 ET with the operator present: a headed browser needs the GUI
  session.) If a category page is still challenged, mark BizBuySell **"blocked — coverage
  incomplete"** and process forwarded listings via the submit-url skill (detail pages still
  validate) — never report a block as "0 candidates available."
- **Pace requests + back off on the anti-bot block (added 2026-06-06).** The block trips
  under sustained paging (it triggered after ~50 listings on 2026-06-06). Two defenses:
  1. **Throttle** to look human and avoid tripping it at all — wait a randomized **3–8 s
     between category pages** and **2–5 s between detail-page fetches**.
  2. **Backoff-retry when a page returns the 403 / "Powered and protected" challenge** —
     do NOT give up immediately and do NOT hammer it: wait **~30 s** and reload once; if
     still blocked, wait **~90 s** and reload once more. **Max 3 attempts per page**
     (~30 s → 90 s backoff). Faster retries make the block worse, so respect the waits.
  After 3 failed attempts, stop retrying that page/category, record how many
  pages/categories were skipped, and move on — then resume normal pacing.
- For each active vertical, open its BizBuySell **category page(s)** per the slug map in
  `config/search_config.md` (`https://www.bizbuysell.com/{state}/{category-slug}/`),
  priority states first then all-states; paginate through `/2/`, `/3/`, ….
- **Disambiguate by title/description, not by category.** BizBuySell mis-files some
  verticals: e.g. ASL / sign-language / interpreting businesses live under **"Sign
  Manufacturers and Businesses"** (Manufacturing › Signs), mixed with sign-**making**
  firms. Keep only listings matching the vertical's keep-keywords and drop the
  false-category noise (see the ASL keep/drop lists in `config/search_config.md`).
- For each kept listing, extract the **direct detail URL** and **listing ID** (numeric ID
  at end of URL); validate the detail page in Step 3 (detail pages load fine).
- **After the backoff-retry above is exhausted**, a still-challenged or unreachable category
  page must be logged as **"blocked — coverage incomplete"** (with the count of skipped
  pages/categories), never as "0 candidates available." Never let an anti-bot block
  masquerade as "no matching businesses exist" — that is the failure that hid listing 2455028.

### 2c. BizQuest (Public)
- Same approach as BizBuySell. Listing URL pattern: `bizquest.com/listing/{listing-id}/`.

### 2d. Other Platforms
- Search any additional platforms found via web search. Always extract the direct listing URL.

### Critical rule — never store a search-results page URL
**NEVER store a search-results page URL as a listing link.** Every lead must have a URL that resolves to a single business detail page. If a search result does not link to a detail page, **skip it**.

## Steps 3 + 4: Validate, Screenshot, and Extract — via the `listing-processor` subagent (plan Steps 2c–2d)

**Do NOT open candidate detail pages in this (main) context.** For each candidate URL, invoke the **`listing-processor`** subagent (`.claude/agents/listing-processor.md`, Haiku) via the Agent tool with: `platform`, `url`, `listing_id` (and `known_price` for price-rechecks). The subagent navigates, validates per the Step-3 rules, captures the screenshot to `output/screenshots/{listing-id}.png`, extracts the full Step-4 field set, and returns ONE compact JSON record — that record is all that enters this context.

- **Sequential only — never invoke listing-processor in parallel.** The Playwright browser session (headed Chrome, persistent profile, DealStream auth) is shared; concurrent subagents would fight over it.
- The returned JSON may arrive wrapped in a markdown code fence — strip the fence before parsing.
- Map the record's `status` to `Link Health Status` (`Live` / `Dead` / `Redirect`); set `Link Last Checked = [today]`. `Blocked` is NOT a link-health value — a Blocked listing goes to the carry-forward queue (`output/run_state/next_run_queue.json`) and is logged as "blocked — coverage incomplete", never as dead.
- `null` fields in the record mean "needs broker follow-up" — **never fabricate values** for them.
- Dead listings: log URL + `status_reason`, record `Link Health Status = Dead`, continue to the next listing.

The detailed validation rules (negative signals, redirect handling, BizBuySell 30 s → 90 s backoff, max 3 attempts) and the extraction field table now live in the subagent definition — keep them in sync there, not here.

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
2. **Invoke the `prospect-scorer` subagent** (`.claude/agents/prospect-scorer.md`, Opus — it preloads the prospect-evaluation skill) via the Agent tool with the lead record JSON, the screenshot path, and `output_dir`. It runs the full evaluation — Buy Box screening (6 hard criteria) → 26-field scorecard → 0–100 lead score with per-line math → full deal memo — and writes the **Markdown report only**. **Do not load the prospect-evaluation skill or write deal memos in this (main) context.** Scoring is the one deliberately-expensive step; everything else in this pipeline stays on the cheaper orchestrator/extractor models.
3. **Parse the subagent's JSON return** (strip any code fence or one-line preamble — take the JSON object): `lead_score`, `score_denominator`, `buy_box`, `suggested_disposition`, `report_md`, `one_line_summary`. Verify `report_md` exists on disk; if missing, re-invoke once before flagging the lead for manual review.
3b. **Render the HTML report deterministically** — never write report HTML from a model: run `python3 scripts/build_report_html.py --any output/reports/{listing-id}/` and verify `{slug}-report.html` now exists next to the `.md`. That HTML path is what goes into the Airtable `Prospect Eval Report` field.
4. **Use the returned `lead_score` and `one_line_summary`** for the Airtable record and Notes — never re-derive them from the report body in this context.

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

**Never emit dashboard HTML from the model.** Instead:

1. Write the dashboard **context JSON** to `output/run_state/dashboard_data_YYYY-MM-DD.json`. The exact context contract (keys, per-lead fields, pre-formatted price strings) is documented in the header comment of `templates/daily-dashboard.html` — follow it precisely. Lead lists may be written in any order; the renderer sorts by score descending.
2. Run `python3 scripts/build_dashboard_html.py output/run_state/dashboard_data_YYYY-MM-DD.json` — it renders the Jinja2 template to `output/dashboards/dashboard_YYYY-MM-DD.html`.
3. Verify the script printed its success line and the HTML file exists.

The four sections below describe what belongs in the context JSON:

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
