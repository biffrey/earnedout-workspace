#!/usr/bin/env bash
#
# run-overnight-search.sh — nightly trigger for the EarnedOut overnight-search skill.
#
# Invoked by the launchd agent `ai.earnedout.overnight-search` (see config/schedule.md).
# Each run is ONE headless Claude Code invocation that loads the overnight-search
# skill and executes the full nightly pipeline, then exits.
#
# This must run on Biffrey's Mac (not a remote/cloud agent).
#
# AUTH (headless — works while logged in, no biometric prompt):
#   PRIMARY: macOS login Keychain. The DealStream username/password are stored as
#      generic-password items `earnedout-dealstream-username` / `-password`
#      (created with `-A` so the launchd job reads them non-interactively). The
#      login keychain is unlocked whenever the user is logged in, so the 10:00
#      run authenticates with NO Touch ID prompt and NO 1Password dependency.
#      (Service-account tokens are a 1Password Business feature; this account is
#      Individual, so Keychain is the headless mechanism — see credentials-setup.md.)
#   FALLBACK: 1Password `op` desktop integration (interactive, daytime only) if
#      the Keychain items are missing. Used only for first-time/bootstrap.
#
# Manual run:  ./run-overnight-search.sh
#
set -u

# launchd starts agents with a minimal environment — set PATH explicitly so the
# `claude` CLI and the `op` 1Password CLI are found.
export PATH="/Users/biffreybraxton/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Resolve DealStream credentials for a HEADLESS run (no biometric prompt).
# Primary source: macOS login Keychain. Fallback: 1Password `op` (daytime only).
# The skill consumes these env vars and fails loud if either is empty — it never
# falls back to blank/hard-coded creds.
DEALSTREAM_USERNAME="$(security find-generic-password -s earnedout-dealstream-username -w 2>/dev/null || true)"
DEALSTREAM_PASSWORD="$(security find-generic-password -s earnedout-dealstream-password -w 2>/dev/null || true)"
if [ -z "${DEALSTREAM_USERNAME:-}" ] || [ -z "${DEALSTREAM_PASSWORD:-}" ]; then
  echo "[auth] Keychain creds missing/empty; falling back to 1Password op read" >&2
  DEALSTREAM_USERNAME="$(op read 'op://Personal/dealstream.com/username' 2>/dev/null || true)"
  DEALSTREAM_PASSWORD="$(op read 'op://Personal/dealstream.com/password' 2>/dev/null || true)"
else
  echo "[auth] loaded DealStream credentials from macOS Keychain" >&2
fi
export DEALSTREAM_USERNAME DEALSTREAM_PASSWORD

cd "$(dirname "$0")" || { echo "cannot cd to script dir" >&2; exit 1; }

LOG_DIR="output/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/overnight-search_$(date +%Y-%m-%d).log"

PROMPT='Run the EarnedOut overnight published-listing search now. Use the overnight-search skill (.claude/skills/overnight-search/skill.md): authenticate to DealStream using the credentials already provided in the environment variables DEALSTREAM_USERNAME and DEALSTREAM_PASSWORD (the runner resolves these from the macOS Keychain for headless operation — do NOT call op or op whoami yourself, and do NOT treat a failing op whoami as a stop condition). FAIL LOUD and stop ONLY if either variable is empty. If both are present, treat authentication as satisfied and proceed; log into DealStream with Playwright and search every active platform (DealStream, BizBuySell, BizQuest, and the others in config/search_config.md) for businesses matching the buy box; for each listing extract the direct listing URL, listing ID, and structured data including 2024 and 2025 revenue and cash flow; validate every link with Playwright and capture a screenshot; deduplicate against the Airtable Master Deal Pipeline (base appOsvuyy5eK43QTx, table tblSmNrHROMLm7vOS) with price-drop detection; run the prospect-evaluation skill on every new lead and every price-drop; create or update Airtable records with Source = "Overnight Search"; draft broker outreach to files and the Notes field only (NEVER send email); and generate the daily HTML dashboard. Run at normal nightly scope.'

{
  echo "=== overnight-search run started $(date -u +%FT%TZ) ==="
  # Model routing: the orchestrator (search, dedup, Airtable writes, outreach
  # templating) runs on Sonnet; per-listing extraction is delegated to the Haiku
  # listing-processor agent and scoring to the Opus prospect-scorer agent (see
  # .claude/agents/). Scoring is the only step that earns the strong model.
  claude -p "$PROMPT" --model sonnet --dangerously-skip-permissions
  rc=$?
  echo "=== overnight-search run finished $(date -u +%FT%TZ) (exit $rc) ==="
} >> "$LOG" 2>&1
