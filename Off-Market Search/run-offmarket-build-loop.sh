#!/usr/bin/env bash
#
# run-offmarket-build-loop.sh
# Ralph runner for the off-market build loop. Calls Claude Code headlessly once
# per iteration -- each call is a FRESH context -- until the build completes,
# every remaining stage is blocked, an iteration reports an error, or the
# backstop run cap is hit. Shared memory between iterations is the _ralph_build/
# state and log files, not conversation history.
#
# Prerequisites:
#   - the `claude` CLI is installed, on PATH, and already authenticated
#   - any MCP connectors the build needs (e.g. Airtable) are configured for
#     Claude Code itself -- otherwise those stages will register as blocked
#   - run from a Mac that stays awake (see the caffeinate usage below)
#
# Usage (macOS -- caffeinate keeps the Mac awake for the whole run):
#   chmod +x "$HOME/published-listing-search/Off-Market Search/run-offmarket-build-loop.sh"
#   caffeinate -i "$HOME/published-listing-search/Off-Market Search/run-offmarket-build-loop.sh"
#
# To detach fully (survives closing the terminal):
#   nohup caffeinate -i "$HOME/published-listing-search/Off-Market Search/run-offmarket-build-loop.sh" \
#     > "$HOME/published-listing-search/Off-Market Search/_ralph_build/runner-logs/runner.out" 2>&1 &
#
set -u

REPO="$HOME/published-listing-search"
BUILD_DIR="$REPO/Off-Market Search/_ralph_build"
ITER_PROMPT="$BUILD_DIR/ITERATION_PROMPT.md"
SIGNAL_FILE="$BUILD_DIR/.loop_signal"
LOG_DIR="$BUILD_DIR/runner-logs"
MAX_RUNS=120          # backstop only; STATE.md `max_iterations` (120) is authoritative
SLEEP_BETWEEN=5       # seconds to pause between iterations

command -v claude >/dev/null 2>&1 || { echo "ERROR: 'claude' CLI not found on PATH."; exit 1; }
cd "$REPO" || { echo "ERROR: repo not found at $REPO"; exit 1; }
[ -f "$ITER_PROMPT" ] || { echo "ERROR: iteration prompt missing: $ITER_PROMPT"; exit 1; }
mkdir -p "$LOG_DIR"

echo "=== off-market build runner started $(date) ==="
run=0
while [ "$run" -lt "$MAX_RUNS" ]; do
  run=$((run + 1))
  ts="$(date +%Y%m%dT%H%M%S)"
  logfile="$LOG_DIR/iter-$run-$ts.log"
  rm -f "$SIGNAL_FILE"
  echo "--- iteration $run / $MAX_RUNS  ($ts) ---"

  # Each call is a fresh context. --dangerously-skip-permissions (equivalent to
  # --permission-mode bypassPermissions) runs every tool call without prompting.
  claude -p "$(cat "$ITER_PROMPT")" \
    --dangerously-skip-permissions \
    --output-format text \
    > "$logfile" 2>&1
  rc=$?

  tail -n 20 "$logfile"

  if [ "$rc" -ne 0 ]; then
    echo "=== STOP: claude exited non-zero ($rc). Full log: $logfile ==="
    break
  fi

  signal="$(tr -d '[:space:]' < "$SIGNAL_FILE" 2>/dev/null || true)"
  case "$signal" in
    CONTINUE)
      echo "    iteration $run done -- continuing."
      sleep "$SLEEP_BETWEEN"
      ;;
    STOP-COMPLETE)
      echo "=== DONE: build loop COMPLETE after $run iteration(s). ==="
      break
      ;;
    STOP-BLOCKED)
      echo "=== STOP: remaining work needs you. Read:"
      echo "    $BUILD_DIR/MORNING_QUESTIONS.md ==="
      break
      ;;
    STOP-ERROR)
      echo "=== STOP: an iteration hit an unrecoverable error. Log: $logfile ==="
      break
      ;;
    *)
      echo "=== STOP: no/unknown loop signal ('$signal') -- stopping for safety. Log: $logfile ==="
      break
      ;;
  esac
done

echo "=== runner finished after $run iteration(s) -- $(date). Logs in $LOG_DIR ==="
