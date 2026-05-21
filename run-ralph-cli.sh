#!/usr/bin/env bash
#
# run-ralph-cli.sh — Run the EarnedOut revamp Ralph loop via Claude Code on macOS.
#
# Each `claude -p` invocation is ONE fresh-context iteration: it reads
# _ralph/STATE.md, advances the loop by exactly one phase, commits, and exits.
# This wrapper re-invokes it until the loop sets `active: false` in STATE.md
# (COMPLETE or the iteration cap), or the safety limit below is reached.
#
# Usage:   ./run-ralph-cli.sh [max_invocations]      (default 30)
# Resume:  if it stops early, just run it again — all state lives in STATE.md.
#
# Prereqs (see the chat instructions): Claude Code installed; `op` signed in
# (`op whoami`); Playwright + Airtable MCP servers configured (`claude mcp list`);
# the Cowork "earnedout-revamp-loop" scheduled task DISABLED so the two runners
# do not collide on STATE.md / git.
#
set -u
cd "$(dirname "$0")" || { echo "cannot cd to script dir" >&2; exit 1; }

PROMPT_FILE="REVAMP_LOOP_PROMPT.md"
STATE_FILE="_ralph/STATE.md"
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
  echo "=== Ralph CLI invocation $i — $(date -u +%FT%TZ) ==="
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
