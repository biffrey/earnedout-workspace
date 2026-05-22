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

> **Gated on blocker B4.** The skill's Step 1 schema preflight **fails loud**
> until the two off-market `Source` values exist in Airtable (B4 — see
> `Off-Market Search/_ralph_build/BLOCKERS.md`). Registering the cron before B4
> clears would produce a fail-loud halt every Monday. **Register the cron once
> B4 is resolved** — at which point the weekly run succeeds end-to-end.

To register the weekly cron (run once, after B4 clears):

```bash
# Via the /schedule skill — register a weekly recurring routine:
#   Schedule:  weekly, Monday 06:00 local
#   Command:   ./run-offmarket-search.sh   (repo root)
#   Label:     ai.earnedout.offmarket-search
```

Use the `/schedule` skill (or the runtime's cron mechanism) to create the
routine with the above schedule and command. Confirm it is registered with the
`/schedule` list view.

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
