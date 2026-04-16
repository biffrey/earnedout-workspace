---
name: Submit URL
description: Submit a business-for-sale listing URL to the EarnedOut pipeline. Validates the link via Playwright, extracts structured data, checks for duplicates in Airtable (with price-drop detection), runs the full prospect evaluation, creates/updates the Airtable record, and drafts broker outreach. Use when the user says "submit this URL", "add this listing", "evaluate this link", or provides a business-for-sale URL to process.
---

# Submit URL Skill

You are adding a manually-submitted business listing to the EarnedOut acquisition pipeline. This runs the same pipeline as the overnight search but for a single user-provided URL.

## Before you start

1. **Read configuration:** Load `config/search_config.md` for Airtable field IDs and output paths.
2. **Read outreach templates:** Load `config/outreach_templates.md` for broker email templates.
3. **Read prospect-evaluation skill:** Load `.claude/skills/prospect-evaluation/skill.md`.

## Step 1: Accept URL

Accept one URL from the user. Confirm it looks like a business-for-sale listing URL. Extract the listing ID from the URL pattern if possible.

## Step 2: Validate URL (Playwright)

1. Launch Playwright and navigate to the URL
2. Check that the page contains listing-specific content:
   - Business name, asking price, description present → valid
   - "Listing removed", "no longer available", login wall, generic page → invalid
3. If valid:
   - Capture full-page screenshot → `output/screenshots/{listing-id}.png`
   - Set `Link Health Status = Live`
4. If invalid:
   - Report to user: "This URL does not appear to be a valid business listing"
   - Explain what was found (removed listing, redirect, etc.)
   - Stop processing

## Step 3: Extract Structured Data

From the validated listing page, extract all available fields:
- Business Name, Industry, Location (City, State)
- Asking Price, Revenue, EBITDA/SDE
- Years in Business, Employee Count
- Broker Name, Broker Contact
- 2024 and 2025 Revenue/Cash Flow (if disclosed)

Mark any unavailable fields as "needs broker follow-up".

## Step 4: Deduplicate Against Airtable

Query `tblSmNrHROMLm7vOS` for matching records:
- Match on Business Name + Business Address
- Match on Listing ID (if extractable)

**Not found → new lead.** Proceed to Step 5.

**Found, same/higher price → duplicate.** Inform user: "This listing already exists in the pipeline (Record: [name]). No action taken." Update `Link Last Checked`.

**Found, LOWER price → price drop:**
1. Store old price in `Previous Asking Price`
2. Update `Asking Price`
3. Set `Date Updated` to today
4. Inform user: "Price drop detected: was $X, now $Y"
5. Proceed to Step 5 for re-evaluation

## Step 5: Run Prospect Evaluation

Invoke `.claude/skills/prospect-evaluation/skill.md` with the extracted data.
- Create directory: `output/reports/{listing-id}/`
- Generate both `.md` and `.html` reports
- Extract the 0–100 lead score

## Step 6: Create/Update Airtable Record

Create (or update for price drops) the Airtable record with ALL fields:

- All standard fields (Business Name, Industry Match, Address, etc.)
- `Listing ID` → extracted from URL
- `Direct Listing URL` → the submitted URL
- `Listing Screenshot` → attach PNG
- `Date Added` → today
- `Date Updated` → today
- `Link Health Status` → "Live"
- `Link Last Checked` → today
- `Disposition` → "Active"
- `Lead Score` → from prospect evaluation
- `Prospect Eval Report` → path to HTML report
- **`Source` → "Manual Submission"** (this distinguishes from overnight search finds)

**Notes field:**
```
[BUSINESS_NAME] | Listing ID: [LISTING_ID]
Direct URL: [DIRECT_LISTING_URL]
Source: Manual Submission
Lead Score: [SCORE]/100
[One-line summary from prospect evaluation]
```

## Step 7: Draft Broker Outreach

If broker info is available:
1. Select template from `config/outreach_templates.md` (aviation → Template C, price drop → Template D, default → Template A)
2. Personalize all placeholders
3. Store in Airtable Notes + `search_reports/outreach_drafts_YYYY-MM-DD.md`

If no broker info: note in the record that outreach is pending broker identification.

## Step 8: Update Dashboard

If a dashboard exists for today (`output/dashboards/dashboard_YYYY-MM-DD.html`), regenerate it to include this new lead in Section A. If no dashboard exists for today, generate a new one.

## Step 9: Report to User

Display a summary:
- Business Name
- Lead Score: XX/100
- Buy Box: PASS / CONDITIONAL / FAIL
- Key highlights (industry, location, EBITDA, asking price, multiple)
- Airtable record created/updated
- Report location: `output/reports/{listing-id}/`
- Outreach status: drafted / pending broker info
