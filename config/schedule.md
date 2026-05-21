# Nightly Schedule — EarnedOut Overnight Search

Implements REVAMP_PLAN.md "Implementation Order" #10 — *"Schedule — Set up via
`/schedule` or cron for nightly execution."*

## Mechanism: macOS `launchd` LaunchAgent (local cron)

The overnight-search pipeline is scheduled with a **macOS `launchd` LaunchAgent**,
not a `/schedule` remote routine. This is deliberate:

- The pipeline retrieves DealStream credentials with the `op` 1Password **desktop**
  CLI, which only resolves inside Biffrey's local GUI login session. A `/schedule`
  remote/cloud agent has no `op` and would fail loud at credential retrieval.
- A `launchd` LaunchAgent runs in the user's login session, so `op` works, and it
  is persistent across reboots and does not expire.

`launchd` is the macOS equivalent of cron — the plan's "or cron" option.

## What is installed

| Artifact | Location | Purpose |
|----------|----------|---------|
| LaunchAgent plist | `~/Library/LaunchAgents/ai.earnedout.overnight-search.plist` | The schedule (installed / loaded) |
| Plist (repo copy) | `config/launchd/ai.earnedout.overnight-search.plist` | Version-controlled canonical source |
| Trigger script | `run-overnight-search.sh` (workspace root) | Headless `claude -p` invocation of the skill |
| Run logs | `output/logs/overnight-search_YYYY-MM-DD.log` | One log file per nightly run |
| launchd stdio | `output/logs/launchd.overnight-search.{out,err}.log` | launchd-captured stdout/stderr |

## Cadence

- **Label:** `ai.earnedout.overnight-search`
- **Schedule:** every day at **02:37 local time** (`StartCalendarInterval`
  `Hour=2`, `Minute=37`). Early-morning so results are ready before the workday;
  off-minute by design.
- `RunAtLoad` is `false` — it fires only on the 02:37 calendar trigger, never on
  load/reboot.

## Trigger prompt

`run-overnight-search.sh` invokes:

```
claude -p "<trigger prompt>" --dangerously-skip-permissions
```

The trigger prompt (full text lives in `run-overnight-search.sh`) instructs Claude
to run the **overnight-search skill** (`.claude/skills/overnight-search/skill.md`):
retrieve DealStream credentials via `op` (fail loud if not signed in); log into
DealStream with Playwright and search every active platform for buy-box matches;
extract each listing's direct URL, listing ID, and 2024/2025 financials; validate
links and capture screenshots; deduplicate against the Airtable Master Deal
Pipeline (`appOsvuyy5eK43QTx` / `tblSmNrHROMLm7vOS`) with price-drop detection; run
the prospect-evaluation skill on every new lead and price-drop; create/update
Airtable records with `Source = "Overnight Search"`; draft broker outreach to files
and the Notes field only (**never send email**); and generate the daily HTML
dashboard.

## Managing the schedule

```bash
# List / confirm it is loaded
launchctl list | grep ai.earnedout.overnight-search
launchctl print gui/$(id -u)/ai.earnedout.overnight-search

# Run once now (manual test)
launchctl kickstart -k gui/$(id -u)/ai.earnedout.overnight-search
#   ...or run the script directly:
./run-overnight-search.sh

# Reload after editing the plist
launchctl bootout    gui/$(id -u)/ai.earnedout.overnight-search
launchctl bootstrap  gui/$(id -u) ~/Library/LaunchAgents/ai.earnedout.overnight-search.plist

# Disable / remove
launchctl bootout gui/$(id -u)/ai.earnedout.overnight-search
rm ~/Library/LaunchAgents/ai.earnedout.overnight-search.plist
```

## Prerequisites for a successful nightly run

1. Biffrey is logged into macOS (LaunchAgents run in the GUI login session).
2. The 1Password desktop app is running and the `op` CLI integration is enabled
   and signed in (`op whoami`).
3. The `claude` CLI is on PATH (the script sets PATH explicitly).
4. The Playwright and Airtable MCP servers are configured (`claude mcp list`).

If `op` is not signed in, the overnight-search skill fails loud and stops rather
than proceeding unauthenticated — by design.
