---
name: submit-url
description: Submit a single business-for-sale listing URL to the EarnedOut acquisition pipeline. Validates the link via Playwright and captures a screenshot, extracts structured listing data, deduplicates against Airtable with price-drop detection, runs the full prospect-evaluation scoring, creates or updates the Airtable record with Source = "Manual Submission", drafts broker outreach, regenerates the daily dashboard, and reports the lead score. Use when the user says "submit this URL", "add this listing", "evaluate this link", or otherwise provides a business-for-sale URL to process on demand.
---

# Submit URL Skill

You are adding a manually-submitted business listing to the EarnedOut acquisition pipeline. A user has found a listing outside the overnight search — forwarded by a broker, seen on LinkedIn, spotted at a conference — and wants it run through the same pipeline on demand. This skill runs the identical pipeline as the `overnight-search` skill, but for a single user-provided URL, and tags the result with `Source = "Manual Submission"`. It maps directly to `REVAMP_PLAN.md` Step 6 and reuses plan Steps 2c, 2d, 2e, 3, 4, 5, and 7.

## Before you start

1. **Read configuration:** Load `config/search_config.md` for Airtable field IDs, the canonical live field names, output paths, and platform URL patterns.
2. **Read outreach templates:** Load `config/outreach_templates.md` for the broker email templates and the template-selection logic.
3. **Read credential setup:** Load `config/credentials-setup.md`. If the submitted URL is a DealStream listing behind a login wall, retrieve the DealStream credentials via the 1Password CLI exactly as the overnight-search skill does (`op read "op://Personal/dealstream.com/username"` and `op read "op://Personal/dealstream.com/password"`) and **fail loudly** if `op` is not installed or not signed in. Public-platform URLs (BizBuySell, BizQuest, etc.) do not require authentication.
4. **Read the prospect-evaluation skill:** Load `.claude/skills/prospect-evaluation/skill.md` — you invoke it in Step 5 to score the lead.

**Airtable target:** base `appOsvuyy5eK43QTx`, table `tblSmNrHROMLm7vOS` ("Master Deal Pipeline"). Existing Links field: `fldwo7ui7aIGoMxAG`.

## Step 1: Accept the URL

Accept exactly one URL from the user. Confirm it looks like a business-for-sale listing URL — a single business detail page, not a search-results page.

- Extract the **listing ID** from the URL pattern where possible (e.g., DealStream `dealstream.com/d/biz-sale/trade-contractor/6a89ka` → `6a89ka`; BizBuySell numeric ID at the end of the URL; BizQuest `bizquest.com/listing/{listing-id}/`).
- **Reject search-results pages.** If the URL resolves to a search-results grid rather than one business detail page, stop and tell the user this skill needs a direct listing URL — never store a search-results page (the same critical rule the overnight search enforces in plan Step 2b / overnight-search skill Step 2).

## Step 2: Validate the URL — Playwright (plan Step 2c; overnight-search skill Step 3)

1. Launch a Playwright browser session and navigate to the URL.
2. **Validate content:** confirm the page has listing-specific content — a specific business name, asking price, location, and description. Negative signals: "listing removed", "no longer available", "page not found", a generic search-results grid, or a login wall.
3. **If valid:** capture a full-page screenshot → `output/screenshots/{listing-id}.png`. Record `Link Health Status = Live` and `Link Last Checked = today`.
4. **If invalid (dead / removed / generic):** report to the user exactly what was found (removed listing, redirect to a generic page, login wall, etc.), record `Link Health Status = Dead`, and **stop processing** — do not create an Airtable record.
5. **If redirect:** record `Link Health Status = Redirect`, follow the redirect, and validate the destination; proceed only if the destination is a valid single business listing.

## Step 3: Extract Structured Data (plan Step 2d; overnight-search skill Step 4)

From the validated listing page, extract every available field:

- Business Name, Industry, Location (City, State)
- Asking Price, Revenue (latest year), EBITDA or SDE
- Years in Business, Employee Count
- Broker Name, Broker Contact
- 2024 Revenue / 2024 Cash Flow, 2025 Revenue / 2025 Cash Flow (if disclosed)

For any field not present on the listing page, mark it "needs broker follow-up" — **do not fabricate values**.

## Step 4: Deduplicate Against Airtable — with Price-Drop Detection (plan Step 2e; overnight-search skill Step 5)

Query existing records from table `tblSmNrHROMLm7vOS` (base `appOsvuyy5eK43QTx`).

**Match criteria (check both):**
- Business Name + Business Address (existing dedup logic).
- `Listing ID` field match (new dedup logic).

**Not in Airtable → new lead:** proceed to Step 5.

**In Airtable, same or higher price → duplicate:** inform the user — "This listing already exists in the pipeline (Record: [name]). No action taken." — update `Link Last Checked` to today, and stop.

**In Airtable, LOWER price on the website → price drop:**
1. Store the old Airtable price in `Previous Asking Price`.
2. Update `Asking Price` with the new lower price.
3. Set `Date Updated` to today.
4. Inform the user: "Price drop detected: was $X, now $Y."
5. Proceed to Step 5 to re-evaluate — a lower price may change the score.

## Step 5: Run the Prospect-Evaluation Skill (plan Step 3; overnight-search skill Step 6)

For the new lead (or the price-drop update):

1. Create the output directory `output/reports/{listing-id}/`. Save the extracted structured data as JSON and copy in the screenshot.
2. Invoke the prospect-evaluation skill (`.claude/skills/prospect-evaluation/skill.md`) with the lead data — business name, industry, location, financials, employee count, asking price, broker info, direct listing URL, screenshot path. It runs: Buy Box screening (6 hard criteria) → 26-field scorecard → 0–100 lead score with per-line math → full deal memo.
3. Capture outputs: `output/reports/{listing-id}/{slug}-report.md` and `output/reports/{listing-id}/{slug}-report.html`.
4. Extract the 0–100 lead score from the generated report header.

## Step 6: Create / Update the Airtable Record — Source = "Manual Submission" (plan Step 4; overnight-search skill Step 7)

Create the record (or, for a price drop, update the existing one) with ALL fields mapped.

**Existing field mappings** (use the field IDs in `config/search_config.md`): Business Name, Industry Match, Business Address, Website, Lead Source, Broker Name, Asking Price, EBITDA, EBITDA Margin, Years in Business, Qty FT Employees, NAICS Code, Status, Priority Geography, Track, Tier.

**New field mappings** (canonical live field names — see `REVAMP_PLAN.md` Step 1 "Live field-name reconciliation"):
- `Listing ID` → extracted listing ID
- `Direct Listing URL` → the submitted, validated URL (NEVER a search-results page)
- `Listing Screenshot` → attach the PNG from `output/screenshots/{listing-id}.png`
- `Date Added` → today
- `Date Updated` → today (same as Date Added for new leads)
- `Link Health Status` → "Live"
- `Link Last Checked` → today
- `Disposition` → "Active" (default for every new lead)
- `Lead Score` → score from the prospect evaluation
- `Prospect Eval Report` → path to the HTML report
- `Revenue 2024` → if disclosed
- `Cash Flow 2024` → if disclosed
- `Revenue 2025` → if disclosed
- `Cash Flow 2025` → if disclosed
- **`Source` → "Manual Submission"** — this is the one field that distinguishes a manual submission from an overnight-search find. The overnight-search skill sets this to "Overnight Search"; this skill always sets it to "Manual Submission".

**Notes field — always include all four identifiers, never a search-results page:**
```
[BUSINESS_NAME] | Listing ID: [LISTING_ID]
Direct URL: [DIRECT_LISTING_URL]
Airtable record: [AIRTABLE_RECORD_URL]
Source: Manual Submission
Lead Score: [SCORE]/100
[One-line summary from the prospect evaluation]
```
Capture the Airtable record URL after the record is created (or, for a price-drop update, from the existing record) and write it back into Notes. NEVER reference a search-results page in Notes.

For a price-drop update, also append to Notes: `PRICE DROP: was $[OLD], now $[NEW] ([DATE])`.

## Step 7: Draft Broker Outreach (plan Step 5; overnight-search skill Step 8)

If broker information is available on the listing:

1. **Select the template** from `config/outreach_templates.md` using the selection logic:
   - Aviation listing (Part 135, Part 145) → Aviation Template C
   - Price-drop re-submission → price-drop follow-up template
   - All others → updated default template
2. **Personalize** every placeholder: broker name, business name, listing ID, industry, location, years in business, and specific details drawn from the listing.
3. **A/B test the subject line only** — rotate subject-line variants, never the body text.
4. **Store the draft** in two places: append it to the Airtable `Notes` field, and append it to `search_reports/outreach_drafts_YYYY-MM-DD.md`.
5. **Never send email.** This skill only drafts outreach; sending is always a manual human action.

If no broker info is available, note in the record that outreach is pending broker identification — do not fabricate broker details.

## Step 8: Regenerate the Daily Dashboard (plan Step 7; overnight-search skill Step 10)

**Never emit dashboard HTML from the model.** Update today's dashboard **context JSON** at `output/run_state/dashboard_data_YYYY-MM-DD.json` (create it if missing — the context contract is documented in the header comment of `templates/daily-dashboard.html`), then run `python3 scripts/build_dashboard_html.py output/run_state/dashboard_data_YYYY-MM-DD.json` to re-render `output/dashboards/dashboard_YYYY-MM-DD.html` so this lead appears:

- **Section A — Last Night's New Finds (+ Price Drops):** this manual submission appears here with `source = "Manual Submission"` (and `price_drop: true` if it was a price-drop update).
- **Section B — Running Queue:** the lead joins all `Disposition = "Active"` records.
- **Section C — Revisit Bucket** and **Section D — Run Summary** refresh from current Airtable data in the JSON.

## Step 9: Report to the User

Display a concise summary:
- Business Name
- Lead Score: XX/100
- Buy Box result: PASS / CONDITIONAL / FAIL
- Key highlights: industry, location, EBITDA, asking price, implied multiple
- Airtable record created or updated (with the record URL)
- Report location: `output/reports/{listing-id}/`
- Outreach status: drafted / pending broker info
- Dashboard: path to the regenerated `output/dashboards/dashboard_YYYY-MM-DD.html`

## Error Handling

- **1Password / `op` failure (DealStream URL only):** stop with a clear error — do not load a DealStream listing unauthenticated.
- **Invalid or dead URL:** stop after Step 2; report what was found; create no Airtable record.
- **Search-results page submitted:** stop at Step 1; ask the user for a direct single-listing URL.
- **Playwright failure:** report the failure to the user; do not create a partial record.
- **Airtable API failure:** retry once; if it still fails, save the lead data locally and flag it for manual entry.
