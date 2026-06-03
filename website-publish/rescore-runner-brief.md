# Brief — "Process Pending Rescores" automation

A handoff document for whoever picks up this work next (new Cowork session, Claude Code session, or future me). Self-contained: doesn't assume any context from prior chats.

---

## STATUS — as of 2026-06-02

**23.5a (manual runner) and 23.5b (Working Folder Path field) are DONE, pushed, and live-tested.** Decisions made with Biffrey: runtime = manual Cowork command (option c); folder resolution = Working Folder Path field (recommended); caps = sequential, max 5/run; backfill = interactive confirm (only cleanly-matched rows filled).

What now exists:

- **`process-pending-rescores` skill** — installed at `~/.claude/skills/process-pending-rescores/`; source in `~/published-listing-search/website-publish/process-pending-rescores/` (`SKILL.md` + `resolve-working-folder.py`, a stdlib Business-Name→folder fallback matcher). Trigger: say *"process pending rescores"* in Cowork. Sequential, cap 5, logs to `~/Library/Logs/smbs-rescore-runner.log`. On failure leaves the flag set and continues.
- **Airtable `Working Folder Path` field** — id `fldJCqHDRnpbVPaZa` on the Master Deal Pipeline. Backfilled for the cleanly-resolvable rows (Linguabee, Silverfox, Flying Zebra, Hampton Aviation/Mena); the rest are intentionally blank and fill on next publish (most of the 411 rows are off-market PE/SBIC funds with no document folder).
- **`prospect-evaluation` Step 9 gained rescore mode** — skips the disposition prompt, preserves the existing Disposition, sets/refreshes Working Folder Path. Reconciled prior skill drift (the installed copy had SBIC/NAICS refinements; the repo had Step 9) into one canonical union across all three copies.
- **Pushed:** skill repo branch `claude/plan-business-evaluation-skill-tY1Us` (commit `a941fd7`); workspace branch `claude/rescore-runner` (off `main` — fast-forward/merge when ready).
- **Live test passed:** flagged Linguabee, ran the full loop, score held 95/110, Active disposition preserved, flag cleared, queue empty.

What's NOT built yet: **23.5c (nightly scheduled run), 23.5d (cost/visibility digest), 23.5e (diff/digest).** Runner is manual-trigger only — prove it on a few more real prospects before automating nightly (caveat 5 below).

⚠️ **Drift trap:** the installed skill at `~/.claude/skills/prospect-evaluation/` does **not** auto-sync from git. After any skill edit in the repo, re-copy into `~/.claude/skills/` or Cowork runs the stale version. This is exactly what stalled the original handoff (Step 9 was committed in the repo but never installed).

---

## What we want to accomplish

A prospect's evaluation report can become stale as new information arrives — a CIM, a tax return, a meeting transcript, an updated org chart. We have a watcher that already detects "new info arrived" and flags the prospect in Airtable. **What we don't have yet is the second half of the loop — a runner that takes each flagged prospect, re-runs the Prospect Evaluation against its current folder contents, writes a fresh report, and clears the flag.**

End state we want: a deal lead drops a CIM into `Prospects/<industry>/<company>/`, walks away, and a few hours later (or on demand) the dashboard's row for that company shows a fresher score, fresher Notes, and a fresher linked report — without anyone having to think about it.

---

## What's already in place (foundation the runner builds on)

**Airtable** — base `appOsvuyy5eK43QTx`, table `tblSmNrHROMLm7vOS` ("Master Deal Pipeline"):

- `Needs Rescore` checkbox field — id `fldqJSo0N890SxtTP`. Set to `true` automatically by the file watcher when a new `.pdf`/`.docx`/`.xlsx`/`.pptx`/`.doc`/`.xls`/`.ppt` lands in any prospect folder.
- `Business Name` — id `fldquYtYnHJ1YzUR7`.
- `Prospect Eval Report` — id `fld9InVXs4RqgtNDo`. Holds a `file://` URL pointing at `~/published-listing-search/output/reports/name-<slug>[-<state>]/<slug>-report.html`.
- "Pending Rescore" view — already filters to `Needs Rescore = true`.

**Mac filesystem watcher** — already running:

- `~/Library/LaunchAgents/com.smbsteward.prospects.watch.plist` — launchd KeepAlive agent.
- `~/published-listing-search/website-publish/mac-install/flag-prospect-for-rescore.py` — flips the Airtable checkbox when a relevant file event fires. Walks UP the path to find a folder whose name matches an existing Airtable Business Name (deepest match wins).
- `~/.config/smbs/airtable-token` (chmod 0600) — Airtable Personal Access Token scoped read+write on this base. **The runner can reuse this same token file.**

**Prospect Evaluation Skill** — at `biffrey/Prospect-Evaluation-Skill`, on branch `claude/plan-business-evaluation-skill-tY1Us`:

- Already does the actual evaluation work — Buy Box gate, 26-field scorecard, 0–100 (or 0–110 for roll-up add-ons) score, full memo, HTML + Markdown report.
- **Step 9 (auto-publish)** is already wired up: writes the HTML to `~/published-listing-search/output/reports/name-<slug>[-<state>]/`, asks the user for a Disposition, and creates-or-updates the Airtable row. The reference doc is at `.claude/skills/prospect-evaluation/references/publish-to-pipeline.md` in that repo.
- The Step 9 dedup logic already handles "update existing row vs create new" cleanly — for a rescore, it'll update.

**Consolidated reports folder** — `~/published-listing-search/output/reports/`. Synced to `https://smbsteward.com/SMBSSearch001/reports/` by a separate launchd-driven sync (`sync-reports.sh`).

**Prospect working folders** — `/Users/biffreybraxton/Library/CloudStorage/GoogleDrive-bbraxton@applied-dev.com/My Drive/Investments/Prospects/<industry>/<company>/`. These hold the source material (CIMs, financials, transcripts, NDAs, LOIs, ownership briefs).

---

## What needs to be built — concretely

A runner that does the following loop:

1. **Query Airtable** for all rows where `Needs Rescore = true`. Sort by lead score desc or by created-time, your choice.
2. **For each flagged row, decide which working folder it maps to.** This is the load-bearing decision; see "Open design decisions" below.
3. **Run Prospect Evaluation against that folder.** Read every file in it, do whatever WebSearch/WebFetch the skill normally does, produce a fresh report. The skill's Step 9 auto-publish takes care of writing the new HTML and updating the Airtable row's score / report path / notes — so the runner doesn't have to duplicate that logic.
4. **Skip the Step 9 disposition prompt** during a rescore — the existing disposition is fresher than this re-eval's context. Update the runner's invocation of the skill to suppress that prompt, or have the skill detect "this is a rescore" mode.
5. **Clear `Needs Rescore = false`** on the row.
6. **Log** what happened — at minimum: prospect, started-at, finished-at, new score, error if any.

On failure (file unreadable, network drop, LLM rate-limit, whatever): leave `Needs Rescore = true` so the next run picks it up, log the error, move on to the next prospect.

---

## Open design decisions for the next worker

These are the calls that have to be made before implementation can start. The user (Biffrey) has not committed to any of these yet — they should be confirmed as part of starting the new task.

### 1. Where does the runner run?

Three viable options:

- **(a) Cowork scheduled task.** Runs in Anthropic's hosted environment. LLM is built in. Mounts the user's published-listing-search and Prospects/ folders. Honest unknowns: time limits per task, whether long-running multi-prospect sequences fit, whether the watcher's flag flip propagates fast enough to make scheduled runs the right shape. Worth checking Cowork's scheduled-task docs before committing.

- **(b) Claude Code in headless mode, driven by a Mac launchd timer.** Runs on the user's Mac. Bring-your-own Anthropic API key for billing. Has full local filesystem access (no mount tax). Trickier to set up cleanly but more direct control.

- **(c) Manual command only — "process pending rescores".** User (or Trisha) types it in Cowork when they want to. Cheapest, simplest, no surprise bills. Loses the "set it and forget it" feel but is the lowest-risk starting point. **Recommended as Phase 1; graduate to (a) or (b) once the workflow is proven.**

### 2. How does the runner find the prospect's working folder?

Right now, Airtable has the company name but not a folder path. Three approaches:

- **Add a `Working Folder Path` field to Airtable**, populated by Step 9 of the skill on every publish, backfilled for existing rows by a one-time scan. Most robust. **Recommended.**
- **Filesystem search by Business Name** — slow, fragile (name vs folder mismatch), but no schema change.
- **Convention-based derivation** — `Industry Match` + slugified name. Fragile; folder structure isn't strictly Industry/Company everywhere (Prospects/ has folders like "Mark McLindon" and "Samuel Morgan Wiseman" that are people-grouped, not industry-grouped).

### 3. Trigger model

- On-demand only (`"process pending rescores"` in Cowork).
- Nightly batch at fixed time (3 AM is consistent with the existing sync's catch-up).
- Continuous poll every N minutes (overkill for daily-scale ops; expensive).

The user previously chose **stale-flag + batch (recommended)** over instant-on-every-change, with "nightly OR when you say 'process pending'" as the trigger. So implement both: (a) a `"process pending rescores"` command they can run on demand, and (b) a nightly scheduled run that calls the same code.

### 4. Cost and concurrency caps

Each rescore is a real LLM run. Rough numbers (the user should confirm against their actual usage):

- A single Prospect Evaluation run is typically 10–30 minutes of Claude time with heavy WebSearch / WebFetch use.
- Per-prospect cost is variable — probably in the single-digit dollars per evaluation, but it depends on prospect complexity, how many documents have to be read, and how much web research is needed.
- A nightly batch of 10 flagged prospects could mean 3–5 hours of compute and meaningful $ on the bill.

**Design choices the user needs to make:**

- Max prospects per scheduled run (cap to, say, 5)?
- Max wall-clock time per prospect (e.g. abort after 45 min)?
- Run sequentially or in parallel?  Sequential is simpler, easier to log, lower risk of LLM rate-limit collisions.
- Should the runner cap total $ per run and skip the rest if hit? Worth asking.

### 5. Failure handling and surfacing

When a rescore fails, what happens?

- Leave the flag set, log, move on — next scheduled run retries. Default behavior, low-risk.
- After N consecutive failures, surface in a new "Rescore Failed" disposition or a dedicated Airtable field so the user can investigate.

### 6. Diff awareness (nice-to-have, not required for v1)

Should the rescore explicitly call out what changed since the prior evaluation (score delta, new buy-box pass/fail, new red flags)? Nice for a daily digest. Adds complexity. Defer to v2.

---

## Suggested incremental plan

A way to ship something useful fast without committing to the full automation:

- **23.5a — manual command.** A Cowork command / skill (or a simple Markdown spec the skill prompt understands) called `process-pending-rescores`. Reads flagged Airtable rows, for each one resolves the folder, runs Prospect Evaluation, clears the flag. Sequential, one at a time. Validates the whole loop end-to-end on real prospects before any scheduling.
- **23.5b — add `Working Folder Path` Airtable field.** Backfill for existing rows. Have Step 9 of the skill set this on every publish going forward.
- **23.5c — scheduled run.** Once 23.5a is solid, wire it to a Cowork scheduled task (or Mac launchd-driven Claude Code session, per decision 1) that fires nightly. Include a cap on number of prospects per run.
- **23.5d (optional) — cost/visibility.** Each scheduled run posts a summary somewhere — to the user, to Airtable as a separate "Rescore Log" table, or to a Slack/Email. The user can see what got re-evaluated and how much it cost.
- **23.5e (optional) — diff/digest.** Score deltas and "what changed" summaries.

---

## Files and identifiers a future worker needs

| Thing | Path / ID |
|---|---|
| This repo (where new runner code probably lives) | `~/published-listing-search/`, currently at commit `616fd3c` on `main` of `biffrey/earnedout-workspace` |
| Skill repo | `~/Code/Prospect-Evaluation-Skill`, on branch `claude/plan-business-evaluation-skill-tY1Us`, currently at commit `1b2c655` |
| Skill auto-publish reference | `.claude/skills/prospect-evaluation/references/publish-to-pipeline.md` in the skill repo |
| Prospects folders root | `/Users/biffreybraxton/Library/CloudStorage/GoogleDrive-bbraxton@applied-dev.com/My Drive/Investments/Prospects/` |
| Consolidated reports folder | `~/published-listing-search/output/reports/` |
| Existing watcher | `~/Library/LaunchAgents/com.smbsteward.prospects.watch.plist`, script `~/published-listing-search/website-publish/mac-install/flag-prospect-for-rescore.py` |
| Existing sync (don't conflict with) | `~/Library/LaunchAgents/com.smbsteward.sync.watch.plist`, `com.smbsteward.sync.nightly.plist` |
| Airtable read+write token | `~/.config/smbs/airtable-token` (chmod 0600) |
| Airtable base | `appOsvuyy5eK43QTx` |
| Airtable table | `tblSmNrHROMLm7vOS` |
| Needs Rescore field | `fldqJSo0N890SxtTP` |
| Business Name field | `fldquYtYnHJ1YzUR7` |
| Prospect Eval Report field | `fld9InVXs4RqgtNDo` |
| Disposition field | `fldw0xk1YBkmP7sBD` (singleSelect) |
| Sync log | `~/Library/Logs/smbs-sync.log` |
| Rescore-flag log | `~/Library/Logs/smbs-rescore.log` |
| Live dashboard | `https://smbsteward.com/SMBSSearch001/` (HTTP Basic Auth, user `smbs`) |

---

## Honest caveats — please flag these to the user before writing code

1. The LLM cost estimate above is rough. Before turning on a nightly scheduled run, validate against a few real prospects with the manual command and look at actual billing.
2. I do not currently know Cowork scheduled tasks' wall-clock and resource limits with certainty. Verify before committing to option (a) in design decision #1.
3. There is no current way for the runner to tell "Trisha is in the middle of triaging this prospect right now" from "this prospect is idle and ready to rescore". If concurrent human-and-runner edits become a problem, a `Rescore In Progress` field or a brief lock mechanism may be needed.
4. The existing skill in Step 9 prompts the user for Disposition. A rescore run shouldn't re-prompt — make the rescore mode pass an "inherit existing disposition" flag, or update the skill to detect "this row already exists with a disposition and we're in rescore mode → skip the prompt".
5. Build the manual command first, prove it works on a few real flagged prospects, then automate. Skipping straight to nightly scheduled is the path most likely to burn money on a workflow that has a bug.
