#!/usr/bin/env bash
#
# run-offmarket-search.sh — weekly trigger for the EarnedOut off-market-search skill.
#
# Invoked by the weekly `/schedule` cron (or the local launchd agent
# `ai.earnedout.offmarket-search` fallback) — see config/offmarket_schedule.md.
# Each run is ONE headless Claude Code invocation that loads the off-market-search
# skill and executes the full Steps 1-9 pipeline, then exits.
#
# Unlike run-overnight-search.sh, this does NOT need the `op` 1Password CLI: the
# off-market skill queries public U.S. government / open-data sources, no login.
# It does need the Airtable and Playwright MCP servers.
#
# Manual run:  ./run-offmarket-search.sh
#
set -u

# A scheduler starts agents with a minimal environment — set PATH explicitly so
# the `claude` CLI is found.
export PATH="/Users/biffreybraxton/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

cd "$(dirname "$0")" || { echo "cannot cd to script dir" >&2; exit 1; }

LOG_DIR="output/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/offmarket-search_$(date +%Y-%m-%d).log"

PROMPT='Run the EarnedOut off-market target search now. Use the off-market-search skill (.claude/skills/off-market-search/skill.md): run the fail-loud Airtable schema preflight first and STOP if a Source value or a section-8.4 field is missing; query the U.S. government / open-data sources in config/offmarket_sources.md for both target classes (Class 1 ASL/CART/deaf-services roll-up add-ons, Class 2 licensed SBIC management firms) via the s3 source adapters; resolve and de-duplicate the records against the Airtable Master Deal Pipeline (base appOsvuyy5eK43QTx, table tblSmNrHROMLm7vOS) — never re-surface an existing tracker row as a new lead; enrich and apply the cheap pre-filters; score every qualified target with the prospect-evaluation skill (rollup_addon mode for Class 1, sbic mode for Class 2); create or update Airtable records with Source = "Off-Market — ASL Bolt-on" or "Off-Market — SBIC" and Disposition = "Active"; draft proprietary-approach off-market outreach to files and the Notes field only (NEVER send email); regenerate the daily HTML dashboard with the off-market badge; and write the run log to search_reports/offmarket_run_log_YYYY-MM-DD.md. Never fabricate a field — unknowns are "needs follow-up".'

{
  echo "=== off-market-search run started $(date -u +%FT%TZ) ==="
  claude -p "$PROMPT" --dangerously-skip-permissions
  rc=$?
  echo "=== off-market-search run finished $(date -u +%FT%TZ) (exit $rc) ==="
} >> "$LOG" 2>&1
