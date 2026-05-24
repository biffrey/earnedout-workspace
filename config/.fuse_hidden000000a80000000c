# Weekly Schedule — EarnedOut Off-Market Target Search

Implements `OFFMARKET_BUILD_PLAN.md` deliverable #7 and the §13 Q1 decision —
*"weekly, both target classes, via a `/schedule` cron."*

This is the **off-market** schedule. It is separate from the nightly on-market
overnight-search schedule (`config/schedule.md`) — different skill, different
label, different logs. The two never share state.

## Mechanism: weekly `/schedule` cron

The off-market pipeline is scheduled with a **`/schedule` cron** (a recurring
remote routine), as the §13 resolution directs. Unlike the on-market
overnight-search — which must use a local `launchd` agent because it retrieves
DealStream credentials via the `op` 1Password **desktop** CLI — the off-market
skill needs **no `op` credential**: it queries public U.S. government / open-data
sources. That removes the local-GUI-session requirement, so a `/schedule` cron
is appropriate.

It does still require the **Airtable** and **Playwright** MCP servers. The
cron's execution environment must have both configured (`claude mcp list`); if
the chosen `/schedule` environment lacks them, fall back to the **local launchd
agent** option in the last section.

## Cadence

- **Frequency:** weekly — **Mondays at 06:00 local time** (results ready for the
  start of the deal-review week; both target classes in one run).
- **Skill:** `off-market-search` (`.claude/skills/off-market-search/skill.md`).
- **Entrypoint:** `run-offmarket-search.sh` at the repo root — one headless
  `claude -p` invocation that loads the skill, runs the full Steps 1–9 pipeline,
  and exits.

## Trigger prompt

`run-offmarket-search.sh` invokes:

```
claude -p "<trigger prompt>" --dangerously-skip-permissions
```

The trigger prompt (full text in `run-offmarket-search.sh`) instructs Claude to
run the **off-market-search skill**: run the fail-loud schema preflight; query
the government / open-data sources for both target classes; resolve and
de-duplicate against the Airtable Master Deal Pipeline
(`appOsvuyy5eK43QTx` / `tblSmNrHROMLm7vOS`); enrich and pre-filter; score every
qualified target with the `prospect-evaluation` skill; create/update Airtable
records with `Source = "Off-Market — ASL Bolt-on"` or `"Off-Market — SBIC"`;
draft proprietary-approach outreach to files and the `Notes` field only
(**never send email**); regenerate the daily dashboard; and write the run log.

## Registration

> **REGISTERED — 2026-05-22 (build loop iter 46).** Blocker B4 is RESOLVED (both
> off-market `Source` values are live, so the Step 1 schema preflight passes),
> which cleared the registration gate. The weekly trigger is now live as the
> **local `launchd` agent** `ai.earnedout.offmarket-search`.

**Mechanism: local `launchd` agent (not a `/schedule` cron).** A `/schedule`
remote routine cannot run this pipeline — the off-market skill writes to local
repo paths (`search_reports/`, `output/`, the dashboard) and drives the local
Airtable + Playwright MCP servers, which a remote routine does not have. Per the
fallback this file already documents, registration uses the proven `launchd`
pattern (mirroring the on-market `ai.earnedout.overnight-search` agent). It was
registered once, after B4 cleared:

```bash
cp config/launchd/ai.earnedout.offmarket-search.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.earnedout.offmarket-search.plist
launchctl list | grep ai.earnedout.offmarket-search   # confirms it is loaded
```

The agent's `StartCalendarInterval` fires **weekly, Monday 06:00 local**
(`Weekday=1`, `Hour=6`); `RunAtLoad` is `false`, so it fires only on the
calendar trigger. See the **Local launchd fallback** section below for the
manual-test and reload commands.

## Pausing the cron (before the first supervised run)

The build is verified (`OFFMARKET_BUILD_VERIFIED`, 2026-05-22), but the **first
live run must be supervised** — so the one-time SAM.gov keychain "Always Allow"
prompt and the three coverage gates (`IMPROVE-s4-4`, `-s5-3`, `-s6-2`) are
handled with the operator present. Keep the weekly agent **paused** until that
supervised run is done; otherwise an unattended Monday 06:00 trigger could hang
on the keychain prompt or run before the gates are satisfied.

Run on the Mac that owns the agent:

```bash
# 1. confirm whether the agent is currently loaded
launchctl list | grep ai.earnedout.offmarket-search

# 2. unload it
launchctl bootout gui/$(id -u)/ai.earnedout.offmarket-search

# 3. stop it reloading at next login — move the plist aside
mv ~/Library/LaunchAgents/ai.earnedout.offmarket-search.plist \
   ~/Library/LaunchAgents/ai.earnedout.offmarket-search.plist.disabled
```

To re-enable after the supervised first run succeeds: move the plist back to
`~/Library/LaunchAgents/` and re-run the `launchctl bootstrap` command in the
**Registration** section above.

## Local launchd fallback

If the `/schedule` environment cannot run the Airtable / Playwright MCP servers,
schedule it locally instead — the proven pattern from `config/schedule.md`:

1. Copy `config/launchd/ai.earnedout.offmarket-search.plist` to
   `~/Library/LaunchAgents/`.
2. Load it:
   ```bash
   launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.earnedout.offmarket-search.plist
   launchctl list | grep ai.earnedout.offmarket-search
   ```
3. Manual test run:
   ```bash
   launchctl kickstart -k gui/$(id -u)/ai.earnedout.offmarket-search
   #   ...or run the script directly:
   ./run-offmarket-search.sh
   ```

The launchd plist fires weekly (`StartCalendarInterval` `Weekday=1`, `Hour=6`).

## Run logs

| Artifact | Location |
|----------|----------|
| Pipeline run log | `search_reports/offmarket_run_log_YYYY-MM-DD.md` |
| Outreach drafts (NOT SENT) | `search_reports/offmarket_outreach_drafts_YYYY-MM-DD.md` |
| Headless invocation log | `output/logs/offmarket-search_YYYY-MM-DD.log` |
| launchd stdio (fallback only) | `output/logs/launchd.offmarket-search.{out,err}.log` |

## Prerequisites for a successful weekly run

1. Blocker B4 cleared — both off-market `Source` values exist (preflight passes).
2. The `claude` CLI is on PATH.
3. The Airtable and Playwright MCP servers are configured (`claude mcp list`).
4. No `op` / 1Password requirement — the off-market skill uses no login-walled
   source.

If the schema preflight fails, the off-market skill **fails loud and stops**
rather than writing against an incomplete schema — by design.
