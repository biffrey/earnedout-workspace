# Task Checklist

## Phase 0: Prerequisites

- [x] Install 1Password CLI (`op`) and document setup in `config/credentials-setup.md`
- [x] Install Playwright MCP (`@anthropic/mcp-playwright`) and add to `.claude/settings.json`
- [x] Verify Playwright can launch a browser and navigate to a test URL

## Phase 1: Repo Setup & File Migration

- [x] Create `earnedout-workspace` GitHub repo
- [x] Migrate published-listing-search files into new repo structure
- [x] Copy prospect-evaluation skill files (skill.md, references, templates) from Google Drive
- [x] Create directory structure: `.claude/skills/`, `config/`, `references/`, `templates/`, `output/`, `search_reports/`
- [x] Commit and push initial repo state

## Phase 2: Airtable Field Creation

- [x] Query existing fields on `tblSmNrHROMLm7vOS` via `list_table_fields`
- [x] Auto-create missing fields: Listing ID, Direct Listing URL, Listing Screenshot, Date Added, Date Updated
- [x] Auto-create missing fields: Previous Asking Price, Link Health Status, Link Last Checked, Disposition
- [x] Auto-create missing fields: Lead Score, Prospect Eval Report, 2025 Revenue, 2025 Cash Flow, 2024 Revenue, 2024 Cash Flow, Source
- [x] Verify all 16 new fields exist and have correct types

## Phase 3: Search Workflow Rewrite

- [x] Rewrite overnight-search `skill.md` with config reading + 1Password auth (Step 2a)
- [x] Implement DealStream authenticated search with direct listing URL extraction (Step 2b)
- [x] Implement BizBuySell, BizQuest, and other public platform searches (Step 2b)
- [x] Enforce critical rule: never store search-results page URLs as listing links
- [x] Implement Playwright URL validation + screenshot capture (Step 2c)
- [x] Implement structured data extraction from validated listing pages (Step 2d)
- [x] Implement dedup against Airtable with price-drop detection (Step 2e)

## Phase 4: Prospect Evaluation Integration

- [x] Wire overnight-search to invoke prospect-evaluation skill on every new lead
- [x] Capture lead score + HTML/MD reports in `output/reports/{listing-id}/`
- [x] Store Lead Score and Prospect Eval Report path in Airtable record
- [x] Verify prospect-evaluation runs on a test lead and produces both report formats

## Phase 5: Airtable Record Creation

- [x] Map all existing fields (Business Name, Industry Match, etc.) — unchanged IDs
- [x] Map all new fields (Listing ID, Direct URL, Screenshot, Date Added, Disposition, Lead Score, etc.)
- [x] Implement Notes field change: always include business name, listing ID, direct URL — never search-results pages
- [x] Verify a complete Airtable record is created with all fields populated

## Phase 6: Broker Outreach

- [x] Update `config/outreach_templates.md` with revised default template
- [x] Implement template selection logic (Aviation / price-drop / default)
- [x] Implement A/B testing on subject lines (not body text)
- [x] Store outreach in Airtable Notes + `search_reports/outreach_drafts_YYYY-MM-DD.md`
- [x] Verify outreach draft uses updated template with personalized details

## Phase 7: Submit-URL Skill

- [x] Create `.claude/skills/submit-url/skill.md`
- [x] Implement full pipeline: Playwright validation → data extraction → dedup → prospect eval → Airtable → outreach
- [x] Set Source = "Manual Submission" for submitted URLs
- [x] Verify submit-url processes a test URL end-to-end

## Phase 8: Daily HTML Dashboard

- [x] Create `templates/daily-dashboard.html` Jinja-style template
- [x] Implement Section A: Last Night's New Finds (+ price drops), sorted by lead score
- [x] Implement Section B: Running Queue (all Disposition = "Active" leads), sorted by score
- [x] Implement Section C: Revisit Bucket (Disposition = "Revisit for Roll-up")
- [x] Implement Section D: Run Summary (totals, errors, per-industry/platform breakdowns)
- [x] Generate dashboard to `output/dashboards/dashboard_YYYY-MM-DD.html`
- [x] Verify dashboard renders correctly in browser with all sections populated

## Phase 9: Disposition Workflow

- [x] Implement Disposition field logic (Active, Contacted, Maybe Later, Revisit for Roll-up, Passed, Dead Link)
- [x] Dashboard filters correctly by Disposition for Sections B and C
- [x] "Maybe Later" and "Revisit for Roll-up" leads grouped separately from active pipeline

## Phase 10: End-to-End Verification

- [x] `op read` retrieves DealStream credentials
- [x] Playwright logs into DealStream, navigates search, paginates results
- [x] Known-good listing URL validated + screenshot captured
- [x] Known-dead listing URL flagged and skipped
- [x] Prospect-evaluation produces `.md` and `.html` reports for a test lead
- [x] Airtable record created with all new fields (Date Added, Listing ID, Direct URL, Screenshot, Lead Score, Disposition = Active)
- [x] Price-drop detection: old price stored in Previous Asking Price, record updated, re-scored
- [x] Manual URL submission via submit-url skill goes through full pipeline
- [x] Daily dashboard HTML shows test leads in Section A, links to HTML reports
- [x] Running queue (Section B) pulls all undispositioned leads from Airtable
- [x] "Revisit for Roll-up" lead appears in Section C, not Section B
- [x] Notes field contains business name, listing ID, and direct URL (not search-results page)
- [x] Broker outreach email uses updated template with personalized details

## Completion

- [x] ALL_TASKS_COMPLETE
