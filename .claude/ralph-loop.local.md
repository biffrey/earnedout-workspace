---
active: false
iteration: 1
max_iterations: 10
completion_promise: ALL_TASKS_COMPLETE
---

# EarnedOut Overnight Published Listing Search — Complete Revamp

## Objective

Rebuild the EarnedOut overnight search pipeline from the ground up. Migrate both skills (overnight-search + prospect-evaluation) into a shared `earnedout-workspace` repo, wire up Playwright MCP for link validation/screenshots, integrate 1Password CLI for credential retrieval, add new Airtable fields, implement prospect-evaluation scoring on every lead, build a daily HTML dashboard, create a manual URL submission skill, and revise broker outreach templates. Each phase is implemented and verified independently before moving to the next.

## Completion Criteria

Complete when TODO.md shows [x] ALL_TASKS_COMPLETE

## Verification Commands

Run these to check progress after each phase:

- `op read "op://Private/DealStream/username"` — 1Password CLI retrieves credentials
- `npx @anthropic/mcp-playwright --help` — Playwright MCP is installed
- Airtable: `list_table_fields` on `tblSmNrHROMLm7vOS` — all 16 new fields exist
- Playwright navigates to a known-good listing URL and captures a screenshot to `output/screenshots/`
- Playwright navigates to a known-dead listing URL and correctly flags it as dead
- Prospect-evaluation skill produces `.md` and `.html` reports in `output/reports/`
- Airtable record created with all new fields populated (Date Added, Listing ID, Direct URL, Screenshot, Lead Score, Disposition = Active)
- Price-drop detection: modify a test record's Asking Price higher than website price, re-run, verify Previous Asking Price is set and score recalculated
- Submit-URL skill processes a manually provided URL through the full pipeline
- Daily dashboard HTML (`output/dashboards/dashboard_YYYY-MM-DD.html`) renders with Sections A-D
- Running queue (Section B) pulls all undispositioned leads
- Notes field contains business name, listing ID, and direct URL (never a search-results page)
- Broker outreach uses the updated template with personalized details

## Context

- Read `REVAMP_PLAN.md` for full specifications and decision log
- Read `config/search_config.md` for platform search parameters (after migration)
- Read `config/outreach_templates.md` for email templates (after migration)
- Read `.claude/skills/prospect-evaluation/skill.md` for scoring workflow (after migration)
- Airtable base: `appOsvuyy5eK43QTx`, table: `tblSmNrHROMLm7vOS`
- Credential storage: 1Password CLI (`op read`)
- Browser automation: Playwright MCP (`@anthropic/mcp-playwright`)
- Testing: Live systems (real Airtable base and DealStream account)
- Implementation approach: Phased, step-by-step with independent verification per phase
