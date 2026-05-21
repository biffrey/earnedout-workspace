#!/usr/bin/env bash
#
# run-offmarket-ralph.sh — Drive the Off-Market Target Search PRD Ralph loop
# via Claude Code on macOS.
#
# Each `claude -p` invocation is ONE fresh-context iteration: it reads
# "Off-Market Search/_ralph/STATE.md", advances the loop by exactly one phase
# (DRAFT / SELF-CHECK / VERIFY / FINAL AUDIT / COMPLETE / RESOLVE), commits, and
# exits. This wrapper re-invokes it until the loop sets `active: false` in
# STATE.md (the promise was emitted or the iteration cap was hit), or the safety
# limit below is reached.
#
# Usage:   ./run-offmarket-ralph.sh [max_invocations]      (default 30)
# Resume:  if it stops early, just run it again — all state lives in STATE.md.
#
# This loop is a PLANNING pass: it writes "Off-Market Search/PRD_OFF_MARKET_SEARCH.md".
# It does not run live searches, fetch external sites, or build the tool.
#
# Prereqs: Claude Code installed. Do NOT run this concurrently with the
# on-market loop (run-ralph-cli.sh) — both commit to the same git repo. The
# on-market loop is already COMPLETE (_ralph/STATE.md has active: false), so in
# normal use there is no collision.
#
set -u
cd "$(dirname "$0")" || { echo "cannot cd to script dir" >&2; exit 1; }

PROMPT_FILE="OFFMARKET_LOOP_PROMPT.md"
STATE_FILE="Off-Market Search/_ralph/STATE.md"
MAX_INVOCATIONS="${1:-30}"

[[ -f "$PROMPT_FILE" ]] || { echo "missing $PROMPT_FILE — run this from the published-listing-search folder" >&2; exit 1; }
[[ -f "$STATE_FILE"  ]] || { echo "missing $STATE_FILE" >&2; exit 1; }

i=0
while grep -qE '^active:[[:space:]]*true' "$STATE_FILE"; do
  if (( i >= MAX_INVOCATIONS )); then
    echo "=== Reached max_invocations ($MAX_INVOCATIONS); stopping. Re-run to continue. ==="
    break
  fi
  i=$(( i + 1 ))
  echo
  echo "=== Off-Market Ralph invocation $i — $(date -u +%FT%TZ) ==="
  claude -p "$(cat "$PROMPT_FILE")" --dangerously-skip-permissions
  rc=$?
  if (( rc != 0 )); then
    echo "=== claude exited non-zero ($rc); stopping. Inspect output, then re-run to resume. ===" >&2
    break
  fi
  sleep 5
done

echo
echo "=== Runner finished after $i invocation(s). Current STATE.md: ==="
grep -E '^(active|iteration|final_audit_passed|open_blockers|unresolved_findings):' "$STATE_FILE"
