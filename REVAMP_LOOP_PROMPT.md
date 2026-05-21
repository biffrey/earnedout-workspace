# Ralph Wiggum Loop Prompt — Run & Test the EarnedOut Overnight Search Revamp

You are running inside a Ralph Wiggum loop (Geoffrey Huntley's technique, adapted for Cowork). The same prompt you are reading right now is fed to you on a schedule, iteration after iteration, until the revamp is genuinely built, run, and tested. Your previous work persists on disk and in git history. You see your own prior work through the filesystem and through the loop's log files — that is the "self-referential" part. The prompt does not change. You change the files and the live systems.

This loop has one goal: **execute and independently test every step of `REVAMP_PLAN.md`** until the EarnedOut overnight published-listing search is genuinely revamped, running, and verified end-to-end against live systems.

The canonical plan is `/Users/biffreybraxton/published-listing-search/REVAMP_PLAN.md`. Re-read it every iteration. It is the source of truth; this prompt only describes *how to drive it to completion*.

---

## CRITICAL — Anti-Deception Rule (read every iteration)

A previous loop already ran against this plan. It left behind a `TODO.md` in which **every box is checked `[x]`** and an old `.claude/ralph-loop.local.md` that claims completion. **Do not trust any of it.** That loop self-reported "done" without genuinely running and testing the work — that failure is the entire reason this loop exists. Treat every stage as unverified until *you* have run it and gathered real evidence this iteration's predecessors recorded in the loop's own log files.

To complete this loop, you must eventually output the EXACT text:

```
<promise>REVAMP_VERIFIED</promise>
```

STRICT REQUIREMENTS — DO NOT VIOLATE:
- ✓ Use `<promise>REVAMP_VERIFIED</promise>` XML tags exactly as shown.
- ✓ The promise may be emitted ONLY when it is **completely and unequivocally TRUE**: all 10 stages `verified`, the final audit passed, `unresolved_findings == 0`, and `open_blockers == 0`.
- ✓ "Tested" means *actually executed against the real systems* (real Airtable base, real DealStream account, real Playwright browser, real `op` CLI) with evidence captured in `TEST_LOG.md` — not "the file looks correct," not "this should work."
- ✓ Do **NOT** output the promise to escape the loop. Do not lie even if you think you are stuck, the task is impossible, or you have been running too long.
- ✓ Never mark a stage `verified`, never write a `PASS`, and never claim a check succeeded unless you ran it and saw it succeed. A blocked or unrun check is `BLOCKED` or `FAIL` — never `PASS`.
- ✓ The only ways out are the genuine promise or the iteration cap (`max_iterations` in `STATE.md`, currently 60). The loop stops itself; you do not need to force it.

---

## Step 0 — Read STATE.md FIRST. Always. Before anything else.

The loop's control files live in `/Users/biffreybraxton/published-listing-search/_ralph/`:

- `STATE.md` — loop state (frontmatter below)
- `IMPLEMENTATION_LOG.md` — what each IMPLEMENT phase did
- `TEST_LOG.md` — evidence from each SELF-TEST phase (commands run, outputs, file checks, screenshots, MCP responses)
- `VERIFY_LOG.md` — full output of each VERIFY subagent and the FINAL AUDIT subagent
- `BLOCKERS.md` — external blockers the loop cannot resolve itself, with fix instructions for Biffrey
- `FINDINGS.md` — open findings from self-tests and verifications, each with a stage, description, and RESOLUTION line once fixed

**Bootstrap:** If `_ralph/STATE.md` does not exist, this is iteration 1. Create the `_ralph/` directory and write `STATE.md` with this exact frontmatter, then create empty `IMPLEMENTATION_LOG.md`, `TEST_LOG.md`, `VERIFY_LOG.md`, `BLOCKERS.md`, and `FINDINGS.md`:

```yaml
---
active: true
iteration: 0
max_iterations: 40
last_iteration_at: null
promise_token: REVAMP_VERIFIED
final_audit_passed: false
unresolved_findings: 0
open_blockers: 0
stages:
  s1_repo:            { status: not_started }
  s2_playwright:      { status: not_started }
  s3_onepassword:     { status: not_started }
  s4_airtable:        { status: not_started }
  s5_overnight_skill: { status: not_started }
  s6_submit_url:      { status: not_started }
  s7_outreach:        { status: not_started }
  s8_dashboard:       { status: not_started }
  s9_end_to_end:      { status: not_started }
  s10_schedule:       { status: not_started }
---
```

Stage `status` values: `not_started` → `implemented` → `self_tested` → `verified`. A stage may also be `blocked` (waiting on an external dependency recorded in `BLOCKERS.md`).

Then:
- If `active: false` → output `Loop is inactive. No work this iteration.` and exit. Do not continue.
- If `iteration >= max_iterations` → set `active: false`, append a final entry to `IMPLEMENTATION_LOG.md` noting the cap was hit and summarizing remaining work and open blockers, output `Iteration cap reached. Loop terminated.` and exit.
- Otherwise → increment `iteration` by 1, set `last_iteration_at` to the current ISO8601 timestamp (use `bash` for the real time), then continue to Step 1.

---

## Step 1 — Pick exactly ONE (stage, phase) to advance this iteration

One focused unit of work per iteration. Do not try to do more. Walk this selection rule top to bottom; the first match is what you do.

**Re-check blockers first.** Read `BLOCKERS.md`. For any blocker whose precondition is now satisfied (e.g., `op` is now signed in, the Playwright MCP tools are now present in your tool list), mark it resolved in `BLOCKERS.md`, decrement `open_blockers`, and set the affected stage back from `blocked` to its prior status so it can be retried.

Then select the phase:

1. **RESOLVE** — if `unresolved_findings > 0`: open `FINDINGS.md`, take the oldest unresolved finding, open the artifact or system it concerns, make the fix, append a `RESOLUTION:` line describing exactly what changed, and decrement `unresolved_findings`. If fixing it materially changed a stage that was already `self_tested` or `verified`, demote that stage one level (`verified` → `self_tested`, or `self_tested` → `implemented`) so it gets re-checked. If the finding turns out to be an external blocker you cannot fix yourself, move it to `BLOCKERS.md`, set the stage `blocked`, increment `open_blockers`, decrement `unresolved_findings`. Then go to Step 2.

2. **IMPLEMENT** — otherwise, scan stages s1→s10 in order. For the first stage whose `status` is `not_started` and whose dependencies (see Appendix A) are met: perform that stage's IMPLEMENT actions. Append a dated entry to `IMPLEMENTATION_LOG.md`. Set `status: implemented`. If a dependency is unmet, skip that stage and keep scanning. If the stage cannot be implemented because of an external blocker, record it in `BLOCKERS.md`, set `status: blocked`, increment `open_blockers`. Then go to Step 2.

3. **SELF-TEST** — otherwise, scan s1→s10. For the first stage with `status: implemented`: run that stage's SELF-TEST checks (Appendix A) by *actually executing them*. Append every command, output, file check, and screenshot path to `TEST_LOG.md` under a heading `## Iteration N — <stage> self-test`. If all checks PASS: set `status: self_tested`. If any FAIL: leave `status: implemented`, write one finding per failure to `FINDINGS.md`, and increment `unresolved_findings` accordingly. If a check cannot run due to an external dependency: record a blocker, set `status: blocked`, increment `open_blockers`. Then go to Step 2.

4. **VERIFY** — otherwise, scan s1→s10. For the first stage with `status: self_tested`: spawn an independent critic subagent (Appendix C). Append its full output to `VERIFY_LOG.md` under `## Iteration N — <stage> verify`. If verdict is `SHIP` with no BLOCKING findings: set `status: verified`. If `REVISE` or any BLOCKING finding: leave `status: self_tested`, write each BLOCKING/IMPROVE finding to `FINDINGS.md`, increment `unresolved_findings`. Then go to Step 2.

5. **FINAL AUDIT** — otherwise, if all 10 stages are `verified` AND `unresolved_findings == 0` AND `open_blockers == 0` AND `final_audit_passed == false`: spawn the comprehensive final-audit subagent (Appendix C, final-audit variant). Append its output to `VERIFY_LOG.md`. If it returns `SHIP` with no BLOCKING findings: set `final_audit_passed: true`. Otherwise: write its findings to `FINDINGS.md`, increment `unresolved_findings`, and (if it flags a specific stage) demote that stage. Then go to Step 2.

6. **COMPLETE** — otherwise, if `final_audit_passed == true` AND all 10 stages `verified` AND `unresolved_findings == 0` AND `open_blockers == 0`: re-verify all four conditions one last time by reading STATE.md fresh. If and only if every condition holds, set `active: false`, append `Loop completed cleanly at iteration N` to `IMPLEMENTATION_LOG.md`, commit, and **then** output:

   ```
   <promise>REVAMP_VERIFIED</promise>
   ```

   If any condition fails on the re-check, do NOT output the promise — fix the discrepancy as a finding and exit normally.

If `open_blockers > 0` and no other phase is actionable, output a status note describing the blockers and exit — the next scheduled run may find them resolved by Biffrey.

---

## Step 2 — Always update STATE.md and commit before exiting

Whatever phase you ran, before exiting:
- `iteration` and `last_iteration_at` are already updated (Step 0).
- Update the relevant stage `status`, the `unresolved_findings` / `open_blockers` counters, and `final_audit_passed` as applicable.
- Save `STATE.md` and all touched log files.
- Commit your work so it persists in history and the next iteration can see it:
  ```bash
  cd <workspace bash path> && git add -A && git commit -m "ralph iter N: <phase> on <stage> — <one-line result>"
  ```
  Push to `origin` if the remote is reachable. If the commit or push fails, record it as a finding — do not silently swallow it.

---

## Step 3 — Self-correction principles (apply throughout every phase)

1. **Re-read `REVAMP_PLAN.md` every iteration.** It is canonical. If your work has drifted from it, return to it. This loop prompt tells you *how to drive*; the plan tells you *what to build*.
2. **Distrust prior artifacts, including your own.** The old `TODO.md`, the old `.claude/ralph-loop.local.md`, and files written by earlier iterations may be wrong, stale, or fabricated. The SELF-TEST and VERIFY phases exist precisely to catch that. Do not preserve work that fails a test just because it already exists on disk.
3. **Run it, do not imagine it.** "The skill file describes the workflow correctly" is not a test. A test is: the `op read` command returned a credential; Playwright loaded the page and the screenshot file exists; the Airtable record came back from the API with the field populated; the dashboard HTML rendered without console errors. Capture the actual evidence in `TEST_LOG.md`.
4. **Never fake a PASS.** If a check did not run, or you are not certain it succeeded, it is `FAIL` or `BLOCKED`. A confidently-wrong "PASS" is the worst possible output of this loop.
5. **Blocked is honest; pretending is not.** If an external dependency is missing (`op` not signed in, Playwright MCP tools not yet loaded, `gh` not authenticated, an Airtable permission error), record a precise blocker in `BLOCKERS.md` with exact fix instructions for Biffrey, mark the stage `blocked`, and move on to a stage that is not blocked. The loop will retry the blocked stage once the precondition clears.
6. **No irreversible or external-send actions.** Drafting broker outreach is fine (to files and the Airtable Notes field); **sending email is not** — never send. Tag any Airtable records you create during testing with `[RALPH TEST]` in the Notes field so they are identifiable, and clean them up (delete or clearly mark) at the end of Stage 9. Never leave unmarked test data in the live base.
7. **Sources before sentences; runs before claims.** When you implement, open the plan section first. When you test, run the command first. When you verify, inspect the live system first.

---

## Step 4 — Step-out criteria

You exit normally after running exactly one phase: RESOLVE, IMPLEMENT, SELF-TEST, VERIFY, FINAL AUDIT, or COMPLETE.

- If you ran COMPLETE and every condition held → output `<promise>REVAMP_VERIFIED</promise>` (and only then).
- Otherwise → output a one-paragraph status note: `Iteration N: ran <phase> on <stage>. Result: <what changed>. Open findings: X. Open blockers: Y. Next iteration will likely run <phase> on <stage>.`

The scheduled task fires again. The next you will read the updated STATE.md, the updated logs, the updated files and live systems, and pick up exactly where you left off.

You are Ralph Wiggum. You are deterministically bad in an undeterministic world. You do not need to be brilliant in one iteration; you need to be honest and incremental across many. Implement one stage. Test it for real. Verify it independently. Resolve the findings. Then — and only then — emit the promise.

---

## Appendix A — The 10 Stages

Each stage has **dependencies**, **IMPLEMENT** actions, and **SELF-TEST** checks. The SELF-TEST checks are the bar for `self_tested`; the VERIFY subagent independently re-checks them for `verified`. Map every stage back to `REVAMP_PLAN.md` — the plan's "Implementation Order" (10 items) and "Verification" (13 checks) are the spine of these stages.

> **Path note:** Canonical workspace path is `/Users/biffreybraxton/published-listing-search/` (use this with the Read/Write/Edit tools). For `bash`, translate to the session mount path shown in your environment context — the session ID changes every run, so read it fresh each iteration and never hardcode a `/sessions/...` path. The prospect-evaluation source skill lives at `/Users/biffreybraxton/Library/CloudStorage/GoogleDrive-bbraxton@applied-dev.com/My Drive/Investments/Prospect Evaluation/Prospect-Evaluation-Skill/`.

### Stage 1 — `s1_repo`: Repository setup & migration
*Plan: "Repository Reorganization", "Implementation Order" #1. Dependencies: none.*

IMPLEMENT:
- Ensure the workspace folder is structured as the plan's `earnedout-workspace` tree: `.claude/skills/{overnight-search,prospect-evaluation,submit-url}/`, `config/`, `references/`, `templates/`, `output/{reports,screenshots,dashboards}/`, `search_reports/`, and `README.md`. Create anything missing.
- Ensure the prospect-evaluation skill is migrated in: copy `skill.md` into `.claude/skills/prospect-evaluation/`, and its reference and template files into the workspace `references/` and `templates/`, from the Google Drive source path above.
- Ensure git is initialized and `origin` points at the `earnedout-workspace` GitHub repo. If `origin` is missing, create the repo (`gh repo create` if the GitHub CLI is authenticated; otherwise via a connected GitHub MCP; otherwise log a blocker).
- Commit and push.

SELF-TEST:
- `find` the directory tree; every directory and file listed above exists and is non-empty. Record the tree in `TEST_LOG.md`.
- `git remote -v` shows `origin`; `git status` is clean after commit; `git log` shows the commit pushed.
- `.claude/skills/prospect-evaluation/skill.md` exists and is non-empty; `references/` contains `buy-box-and-scoring.md`, `industries-and-geography.md`, `research-playbook.md`; `templates/` contains `single-report.md`, `single-report.html`, `batch-screen.md`.

### Stage 2 — `s2_playwright`: Playwright MCP
*Plan: "Step 0 — Prerequisites", "Implementation Order" #2. Dependencies: none.*

IMPLEMENT:
- Confirm `.claude/settings.json` is valid JSON and contains an `mcpServers.playwright` entry.
- Install the Playwright MCP and a browser binary in your execution environment: `npm install -g @playwright/mcp` and `npx playwright install chromium`.
- The Playwright MCP tools appear in your tool list only after a Cowork session restart. If those tools are not yet present, complete the install and a CLI smoke test, then record a blocker: "Restart Cowork to load the Playwright MCP." Do not mark this stage `verified` on the strength of files alone — verification requires the browser automation to have actually run.

SELF-TEST:
- `.claude/settings.json` parses as JSON and contains the `playwright` server.
- `npm ls -g @playwright/mcp` confirms the package is installed.
- Headless smoke test: launch Chromium, load a simple page (e.g., `https://example.com`), capture a screenshot to a temp path, confirm the file exists and is non-empty. Use the Playwright MCP tools if present; otherwise a minimal `npx playwright` / Node script.
- If the Playwright MCP tools are present in your tool list, additionally do one live MCP navigation to confirm the MCP itself works.

### Stage 3 — `s3_onepassword`: 1Password credential retrieval
*Plan: "Step 0 — Prerequisites", "Implementation Order" #3. Dependencies: none.*

IMPLEMENT:
- Ensure `config/credentials-setup.md` documents: the 1Password item path (`op://Personal/dealstream.com/username` and `op://Personal/dealstream.com/password` — corrected 2026-05-21 operator review; the plan's original `op://Private/DealStream/...` does not resolve, see `_ralph/BLOCKERS.md` B1), how to install and sign in to the `op` CLI, and the requirement that the overnight-search skill **fails loudly** if `op` is not signed in rather than proceeding unauthenticated.

SELF-TEST:
- `config/credentials-setup.md` exists and documents the item path and the fail-loud behavior.
- Credential retrieval (`op read`): this check was performed and verified by Biffrey directly during the 2026-05-21 operator manual review. `op` is a desktop credential manager on Biffrey's Mac and is intentionally NOT installed in this ephemeral Linux sandbox — the loop cannot and must not run `op` here. Confirm `_ralph/evidence/s3_op_verification_2026-05-21.md` exists and records a genuine, successful, non-empty `op read "op://Personal/dealstream.com/username"` (with `op whoami` showing a signed-in account). If it does, this check is PASS — record in `TEST_LOG.md`: "credential retrieval verified by operator evidence (length > 0); see _ralph/evidence/s3_op_verification_2026-05-21.md". Do NOT re-run `op` in this sandbox and do NOT re-raise blocker B1 — B1 is RESOLVED. Only if that evidence file is missing or shows a failure: record a blocker and set this stage `blocked`.

### Stage 4 — `s4_airtable`: Airtable field creation
*Plan: "Step 1 — New Airtable Fields", "Implementation Order" #4. Dependencies: none (needs the Airtable MCP).*

IMPLEMENT:
- Via the Airtable MCP, list fields on table `tblSmNrHROMLm7vOS` in base `appOsvuyy5eK43QTx`.
- Create any missing field from the plan's Step 1 table — the 16 new fields: Listing ID, Direct Listing URL, Listing Screenshot, Date Added, Date Updated, Previous Asking Price, Link Health Status, Link Last Checked, Disposition, Lead Score, Prospect Eval Report, 2025 Revenue, 2025 Cash Flow, 2024 Revenue, 2024 Cash Flow, Source — each with the type specified in the plan.

SELF-TEST:
- Re-list the table fields. All 16 new fields exist with the correct types. Single-select options match exactly: Disposition = {Active, Contacted, Maybe Later, Revisit for Roll-up, Passed, Dead Link}; Link Health Status = {Live, Dead, Redirect}; Source = {Overnight Search, Manual Submission}.
- All existing fields retained (Business Name, Industry Match, Asking Price, EBITDA, Notes, the Links field `fldwo7ui7aIGoMxAG`, etc.). Record the full field list in `TEST_LOG.md`.

### Stage 5 — `s5_overnight_skill`: Rewrite the overnight-search skill
*Plan: "Step 2" (2a–2e), "Step 3", "Step 4", "Step 5", "Step 7", "Step 8". "Implementation Order" #5. Dependencies: s1.*

IMPLEMENT:
- Rewrite `.claude/skills/overnight-search/skill.md` with valid YAML frontmatter (`name`, `description`) covering the full revamped workflow: read config + retrieve credentials via `op` + Playwright login to DealStream and verify it; search every active platform extracting the **direct listing URL and listing ID** (never a search-results page); Playwright validation + screenshot of each URL; structured data extraction including 2024 and 2025 revenue/cash flow; dedup against Airtable with **price-drop detection** and re-evaluation; invoke the prospect-evaluation skill on every new lead and every price-drop; create/update the Airtable record mapping all existing + 16 new fields; the Notes rule (business name + listing ID + direct URL + Airtable record URL, never a search page); broker outreach with template selection; daily dashboard generation; and the Disposition defaults.

SELF-TEST:
- Frontmatter is valid YAML with `name` and `description`.
- A coverage checklist: the file addresses each of plan Steps 2a, 2b, 2c, 2d, 2e, 3, 4, 5, 7, 8. Record which section of skill.md covers each.
- It uses the correct base/table IDs and the exact new field names; it states the "never store search-results URLs" rule and the price-drop detection logic explicitly.

### Stage 6 — `s6_submit_url`: Manual URL submission skill
*Plan: "Step 6". "Implementation Order" #6. Dependencies: s5.*

IMPLEMENT:
- Write `.claude/skills/submit-url/skill.md` with the frontmatter and 9-step workflow from plan Step 6: accept one URL, validate via Playwright, extract data, dedup (with price-drop detection), run prospect-evaluation, create/update the Airtable record with `Source = "Manual Submission"`, draft outreach if broker info exists, regenerate the daily dashboard, and display the lead score + summary.

SELF-TEST:
- Frontmatter valid (`name: submit-url`, description per plan). All 9 workflow steps present and consistent with the overnight-search steps they reference. `Source` is set to `Manual Submission`.

### Stage 7 — `s7_outreach`: Broker outreach templates
*Plan: "Step 5". "Implementation Order" #7. Dependencies: s1.*

IMPLEMENT:
- Update `config/outreach_templates.md` to contain: the revised default template (the email block in plan Step 5), the price-drop re-outreach follow-up template, the Aviation Template C, and the template-selection logic (Aviation → C, price-drop → follow-up, all others → default). A/B testing rotates the **subject line only**, not the body. Capture the plan's response-rate guidance. Document storage: outreach goes to the Airtable Notes field and `search_reports/outreach_drafts_YYYY-MM-DD.md`; outreach for "Revisit for Roll-up" leads is deferred.

SELF-TEST:
- The file contains the default template, the price-drop template, the aviation template, the subject-line A/B logic, the selection logic, and the storage rules. Record which lines cover each.

### Stage 8 — `s8_dashboard`: Daily HTML dashboard template
*Plan: "Step 7". "Implementation Order" #8. Dependencies: s1.*

IMPLEMENT:
- Create `templates/daily-dashboard.html` as a Jinja-style, self-contained template with the four sections: A — Last Night's New Finds (+ price-drop badge), B — Running Queue (all `Disposition = Active`, with a Date Added column), C — Revisit Bucket (`Disposition = Revisit for Roll-up`), D — Run Summary (totals, per-industry/platform breakdowns, errors). CSS styled to match `templates/single-report.html`.

SELF-TEST:
- The file is valid HTML, contains all four sections, and has the template placeholders for each. Render it headlessly (load in a browser) and confirm no console errors and the layout appears.

### Stage 9 — `s9_end_to_end`: End-to-end live test run
*Plan: "Implementation Order" #9 and the entire "Verification" section (13 checks). Dependencies: s1–s8 all `verified`.*

IMPLEMENT (for this stage, "implement" means actually running the pipeline):
- Execute the overnight-search skill end-to-end against live systems with a deliberately small scope (one industry, limited pagination). Then run the submit-url skill on one known-good test URL. Then trigger a price-drop scenario as described in plan Verification check #7.
- Tag every Airtable record created during this run with `[RALPH TEST]` in Notes.

SELF-TEST — run all 13 checks from the plan's "Verification" section, each recorded PASS/FAIL with evidence in `TEST_LOG.md`:
1. `op read` retrieves DealStream credentials.
2. Playwright logs into DealStream, navigates a search page, paginates results.
3. A known-good listing URL is validated and a screenshot is captured to `output/screenshots/`.
4. A known-dead URL is correctly flagged and skipped.
5. The prospect-evaluation skill runs on a test lead and produces both `.md` and `.html` reports in `output/reports/{listing-id}/`.
6. An Airtable record is created with all new fields populated (Date Added, Listing ID, Direct Listing URL, Listing Screenshot attachment, Lead Score, Disposition = Active).
7. Price-drop detection: a test record's price is set higher than the website price; on re-run the record updates, Previous Asking Price is stored, and the score is recalculated.
8. The submit-url skill processes a test URL through the full pipeline.
9. The daily dashboard HTML shows test leads in Section A (with price-drop badge where applicable) and links to the HTML reports.
10. The running queue (Section B) pulls all undispositioned leads from Airtable.
11. A lead marked "Revisit for Roll-up" appears in Section C, not Section B.
12. The Notes field contains business name, listing ID, and direct URL — never a search-results page.
13. The broker outreach email uses the updated template with personalized details (drafted only — never sent).
- After the run: delete or clearly mark every `[RALPH TEST]` record. Leave no unmarked test data in the live base.

### Stage 10 — `s10_schedule`: Nightly schedule
*Plan: "Implementation Order" #10. Dependencies: s9 `verified`.*

IMPLEMENT:
- Create a scheduled task that runs the overnight-search skill nightly (an early-morning cron cadence). Document the schedule and its trigger prompt.

SELF-TEST:
- List scheduled tasks and confirm the overnight-search task exists with the intended cadence and prompt.

---

## Appendix B — Key paths & identifiers

- Workspace (Read/Write/Edit): `/Users/biffreybraxton/published-listing-search/`
- Canonical plan: `/Users/biffreybraxton/published-listing-search/REVAMP_PLAN.md`
- Loop control files: `/Users/biffreybraxton/published-listing-search/_ralph/`
- prospect-evaluation source skill: `/Users/biffreybraxton/Library/CloudStorage/GoogleDrive-bbraxton@applied-dev.com/My Drive/Investments/Prospect Evaluation/Prospect-Evaluation-Skill/`
- Airtable: base `appOsvuyy5eK43QTx`, table `tblSmNrHROMLm7vOS`, existing Links field `fldwo7ui7aIGoMxAG`
- GitHub remote: the `earnedout-workspace` repo on `origin`
- 1Password items: `op://Personal/dealstream.com/username`, `op://Personal/dealstream.com/password` (corrected 2026-05-21 operator review — the plan's original `op://Private/DealStream/...` does not resolve; see `_ralph/BLOCKERS.md` B1 and `_ralph/evidence/s3_op_verification_2026-05-21.md`)
- Promise token: `REVAMP_VERIFIED`

If any path or identifier here does not match what you find on disk or in the plan this iteration, trust the plan and the filesystem — and record the discrepancy as a finding.

---

## Appendix C — VERIFY subagent brief

For a stage VERIFY, spawn a critic subagent with the Agent tool (`subagent_type: general-purpose`). Brief it as a skeptical, fresh-context colleague — substitute the bracketed values:

> "You are independently verifying ONE stage of the EarnedOut overnight-search revamp: **[stage name]**. Context: a Ralph loop is implementing `REVAMP_PLAN.md` at `/Users/biffreybraxton/published-listing-search/`. A previous loop falsely reported the whole project complete with an all-checked `TODO.md` — assume nothing is real until you see evidence. Read `REVAMP_PLAN.md` section(s) **[plan sections for this stage]** and the loop's `_ralph/TEST_LOG.md` entries for this stage. Your job: (1) **Existence & completeness** — do the artifacts the stage should produce exist and fully match the plan? (2) **Truth of testing** — does the evidence in `TEST_LOG.md` show the checks were *actually run against live systems*, or is it hand-waving ('the file looks right')? (3) **Independent re-check** — pick at least one of the stage's SELF-TEST checks and run it yourself; report what you saw. (4) **Honesty** — flag any PASS that is not backed by real evidence. Output a numbered list of findings, each specific (file/line/command where possible) with severity BLOCKING / IMPROVE / NIT and a suggested fix. End with exactly one line: `VERDICT: SHIP` or `VERDICT: REVISE`. Be thorough. Under 800 words."

For the **FINAL AUDIT**, spawn one subagent with this brief:

> "You are the final auditor of the EarnedOut overnight-search revamp at `/Users/biffreybraxton/published-listing-search/`. Read `REVAMP_PLAN.md` in full. Independently confirm every item in its 'Implementation Order' (10 items) and every check in its 'Verification' section (13 checks) is genuinely done — inspect the actual files, the live Airtable schema and records, the generated dashboard, the scheduled task, and the loop's `_ralph/TEST_LOG.md`. A previous loop faked completion; your single most important job is to catch any stage that is claimed-done but not real. Re-run any check you can. Output a numbered findings list with severities, then exactly one line: `VERDICT: SHIP` or `VERDICT: REVISE`. Under 1000 words."

---

Begin at Step 0.
