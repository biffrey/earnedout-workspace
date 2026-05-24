#!/usr/bin/env bash
#
# run-overnight-search.sh — nightly trigger for the EarnedOut overnight-search skill.
#
# Invoked by the launchd agent `ai.earnedout.overnight-search` (see config/schedule.md).
# Each run is ONE headless Claude Code invocation that loads the overnight-search
# skill and executes the full nightly pipeline, then exits.
#
# This must run on Biffrey's Mac (not a remote/cloud agent): the pipeline retrieves
# DealStream credentials via the `op` 1Password desktop CLI, which only resolves in
# the local GUI login session. launchd agents run in that session, so `op` works.
#
# Manual run:  ./run-overnight-search.sh
#
set -u

# launchd starts agents with a minimal environment — set PATH explicitly so the
# `claude` CLI and the `op` 1Password CLI are found.
export PATH="/Users/biffreybraxton/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

cd "$(dirname "$0")" || { echo "cannot cd to script dir" >&2; exit 1; }

LOG_DIR="output/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/overnight-search_$(date +%Y-%m-%d).log"

PROMPT='Run the EarnedOut overnight published-listing search now. Use the overnight-search skill (.claude/skills/overnight-search/skill.md): retrieve DealStream credentials via the `op` 1Password CLI and FAIL LOUD and stop if `op` is not signed in; log into DealStream with Playwright and search every active platform (DealStream, BizBuySell, BizQuest, and the others in config/search_config.md) for businesses matching the buy box; for each listing extract the direct listing URL, listing ID, and structured data including 2024 and 2025 revenue and cash flow; validate every link with Playwright and capture a screenshot; deduplicate against the Airtable Master Deal Pipeline (base appOsvuyy5eK43QTx, table tblSmNrHROMLm7vOS) with price-drop detection; run the prospect-evaluation skill on every new lead and every price-drop; create or update Airtable records with Source = "Overnight Search"; draft broker outreach to files and the Notes field only (NEVER send email); and generate the daily HTML dashboard. Run at normal nightly scope.'

{
  echo "=== overnight-search run started $(date -u +%FT%TZ) ==="
  claude -p "$PROMPT" --dangerously-skip-permissions
  rc=$?
  echo "=== overnight-search run finished $(date -u +%FT%TZ) (exit $rc) ==="
} >> "$LOG" 2>&1
