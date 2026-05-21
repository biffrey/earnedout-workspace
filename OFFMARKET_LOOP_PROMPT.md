# Ralph Wiggum Loop Prompt — Write & Audit the Off-Market Target Search PRD

You are running inside a Ralph Wiggum loop (Geoffrey Huntley's technique). The
same prompt you are reading right now is fed to you on a schedule, iteration
after iteration, until the Off-Market Target Search PRD is genuinely written,
internally consistent, and independently audited. Your previous work persists
on disk and in git history. You see your own prior work through the filesystem
and the loop's log files — that is the "self-referential" part. The prompt does
not change. You change the files.

This loop has one goal: **produce a complete, internally-consistent, self-
audited `Off-Market Search/PRD_OFF_MARKET_SEARCH.md`** that satisfies every
requirement in the canonical spec.

The canonical spec is `/Users/biffreybraxton/published-listing-search/Off-Market
Search/OFFMARKET_PRD_SPEC.md`. Re-read it every iteration. It is the source of
truth for *what* the PRD must contain; this prompt only describes *how to drive
it to completion*.

---

## CRITICAL — this is a PLANNING pass (read every iteration)

- This loop **writes a PRD**. It does **NOT** perform live searches, fetch from
  FPDS-NG / SAM.gov / USAspending / SBA / GSA or any external site, build the
  off-market tool, or write to the live Airtable base. The deliverable is the
  PRD document only.
- Every NAICS/PSC code, every API parameter, every rate limit, every statistic
  the loop is not **certain** of must appear in the PRD as an explicit
  `⚠ VERIFY: <what to confirm> — <primary source>` line. Stating a guess as a
  fact is the single worst output of this loop.
- The PRD must **not** invent a parallel system. Off-market records must be
  interchangeable with on-market records — same Airtable table, same fields,
  same `prospect-evaluation` scoring, same dashboard. Only the sourcing front-
  end is new.

## Anti-deception rule

To complete this loop, you must eventually output the EXACT text:

```
<promise>OFFMARKET_PRD_VERIFIED</promise>
```

STRICT REQUIREMENTS — DO NOT VIOLATE:
- ✓ Use `<promise>OFFMARKET_PRD_VERIFIED</promise>` XML tags exactly as shown.
- ✓ Emit it ONLY when it is **completely and unequivocally TRUE**: all 9 stages
  `verified`, the final audit passed, `unresolved_findings == 0`, and
  `open_blockers == 0`.
- ✓ Never mark a stage `verified`, never write a `PASS`, and never claim a check
  succeeded unless you ran it and saw it succeed. An unrun or failed check is
  `BLOCKED` or `FAIL` — never `PASS`.
- ✓ "Verified" for this loop means: the PRD section actually exists in
  `PRD_OFF_MARKET_SEARCH.md`, fully covers its part of `OFFMARKET_PRD_SPEC.md`,
  is internally consistent with the rest of the PRD and with the real on-market
  files on disk, and every uncertain item is flagged `⚠ VERIFY:`. It is NOT
  "the section looks plausible."
- ✓ Do **NOT** output the promise to escape the loop. Do not lie even if you
  think you are stuck or have been running too long.
- ✓ The only ways out are the genuine promise or the iteration cap
  (`max_iterations` in `STATE.md`). The loop stops itself.

---

## Step 0 — Read STATE.md FIRST. Always. Before anything else.

The loop's control files live in `/Users/biffreybraxton/published-listing-
search/Off-Market Search/_ralph/`:

- `STATE.md` — loop state (frontmatter below)
- `IMPLEMENTATION_LOG.md` — what each DRAFT phase did
- `TEST_LOG.md` — evidence from each SELF-CHECK phase (which spec items were
  covered, which on-disk files were cross-checked, what was found)
- `VERIFY_LOG.md` — full output of each VERIFY subagent and the FINAL AUDIT
- `BLOCKERS.md` — external blockers the loop cannot resolve itself, with fix
  instructions for Biffrey
- `FINDINGS.md` — open findings from self-checks and verifications, each with a
  stage, description, and a `RESOLUTION:` line once fixed
- `evidence/` — supporting notes (e.g., the on-market system summary)

**Bootstrap:** If `Off-Market Search/_ralph/STATE.md` does not exist, this is
iteration 1. Create the `_ralph/` directory and write `STATE.md` with the exact
frontmatter below, then create empty `IMPLEMENTATION_LOG.md`, `TEST_LOG.md`,
`VERIFY_LOG.md`, `BLOCKERS.md`, `FINDINGS.md`, and the `evidence/` directory:

```yaml
---
active: true
iteration: 0
max_iterations: 40
last_iteration_at: null
promise_token: OFFMARKET_PRD_VERIFIED
final_audit_passed: false
unresolved_findings: 0
open_blockers: 0
stages:
  s1_foundations:       { status: not_started }
  s2_target_classes:    { status: not_started }
  s3_sources:           { status: not_started }
  s4_entity_resolution: { status: not_started }
  s5_qualification:     { status: not_started }
  s6_schema:            { status: not_started }
  s7_workflow:          { status: not_started }
  s8_compliance:        { status: not_started }
  s9_assembly:          { status: not_started }
---
```

Stage `status` values: `not_started` → `drafted` → `self_checked` → `verified`.
A stage may also be `blocked` (waiting on an external dependency recorded in
`BLOCKERS.md`).

Then:
- If `active: false` → output `Loop is inactive. No work this iteration.` and
  exit. Do not continue.
- If `iteration >= max_iterations` → set `active: false`, append a final entry
  to `IMPLEMENTATION_LOG.md` noting the cap was hit and summarizing remaining
  work and open blockers, output `Iteration cap reached. Loop terminated.` and
  exit.
- Otherwise → increment `iteration` by 1, set `last_iteration_at` to the current
  ISO8601 timestamp (use `bash` for the real time), then continue to Step 1.

---

## Step 1 — Pick exactly ONE (stage, phase) to advance this iteration

One focused unit of work per iteration. Do not try to do more. Walk this
selection rule top to bottom; the first match is what you do.

**Re-check blockers first.** Read `BLOCKERS.md`. For any blocker whose
precondition is now satisfied, mark it resolved, decrement `open_blockers`, and
set the affected stage back from `blocked` to its prior status.

Then select the phase:

1. **RESOLVE** — if `unresolved_findings > 0`: open `FINDINGS.md`, take the
   oldest unresolved finding, open the PRD section it concerns, make the fix,
   append a `RESOLUTION:` line describing exactly what changed, and decrement
   `unresolved_findings`. If the fix materially changed a stage that was already
   `self_checked` or `verified`, demote that stage one level so it gets
   re-checked. If the finding is an external blocker you cannot fix, move it to
   `BLOCKERS.md`, set the stage `blocked`, increment `open_blockers`, decrement
   `unresolved_findings`. Then go to Step 2.

2. **DRAFT** — otherwise, scan stages s1→s9 in order. For the first stage whose
   `status` is `not_started` and whose dependencies (Appendix A) are met:
   perform that stage's DRAFT actions — write that section into
   `Off-Market Search/PRD_OFF_MARKET_SEARCH.md` (creating the file on s1).
   Append a dated entry to `IMPLEMENTATION_LOG.md`. Set `status: drafted`. If a
   dependency is unmet, skip and keep scanning. Then go to Step 2.

3. **SELF-CHECK** — otherwise, scan s1→s9. For the first stage with
   `status: drafted`: run that stage's SELF-CHECK list (Appendix A) by actually
   opening the PRD section and the on-disk files it must match, item by item.
   Append every item, what you checked it against, and PASS/FAIL to `TEST_LOG.md`
   under `## Iteration N — <stage> self-check`. If all PASS: set
   `status: self_checked`. If any FAIL: leave `status: drafted`, write one
   finding per failure to `FINDINGS.md`, increment `unresolved_findings`. Then
   go to Step 2.

4. **VERIFY** — otherwise, scan s1→s9. For the first stage with
   `status: self_checked`: spawn an independent critic subagent (Appendix C).
   Append its full output to `VERIFY_LOG.md` under `## Iteration N — <stage>
   verify`. If verdict is `SHIP` with no BLOCKING findings: set
   `status: verified`. If `REVISE` or any BLOCKING finding: leave
   `status: self_checked`, write each BLOCKING/IMPROVE finding to `FINDINGS.md`,
   increment `unresolved_findings`. Then go to Step 2.

5. **FINAL AUDIT** — otherwise, if all 9 stages are `verified` AND
   `unresolved_findings == 0` AND `open_blockers == 0` AND
   `final_audit_passed == false`: spawn the comprehensive final-audit subagent
   (Appendix C, final-audit variant). Append its output to `VERIFY_LOG.md`. If
   it returns `SHIP` with no BLOCKING findings: set `final_audit_passed: true`.
   Otherwise: write its findings to `FINDINGS.md`, increment
   `unresolved_findings`, and (if it flags a specific stage) demote that stage.
   Then go to Step 2.

6. **COMPLETE** — otherwise, if `final_audit_passed == true` AND all 9 stages
   `verified` AND `unresolved_findings == 0` AND `open_blockers == 0`: re-verify
   all four conditions one last time by reading STATE.md fresh. If and only if
   every condition holds, set `active: false`, append `Loop completed cleanly at
   iteration N` to `IMPLEMENTATION_LOG.md`, commit, and **then** output:

   ```
   <promise>OFFMARKET_PRD_VERIFIED</promise>
   ```

   If any condition fails on the re-check, do NOT output the promise — fix the
   discrepancy as a finding and exit normally.

If `open_blockers > 0` and no other phase is actionable, output a status note
describing the blockers and exit.

---

## Step 2 — Always update STATE.md and commit before exiting

Whatever phase you ran, before exiting:
- `iteration` and `last_iteration_at` are already updated (Step 0).
- Update the relevant stage `status`, the `unresolved_findings` /
  `open_blockers` counters, and `final_audit_passed` as applicable.
- Save `STATE.md` and all touched files (the PRD and log files).
- Commit so it persists and the next iteration can see it:
  ```bash
  cd /Users/biffreybraxton/published-listing-search && git add -A && \
    git commit -m "offmarket-ralph iter N: <phase> on <stage> — <one-line result>"
  ```
  Push to `origin` if reachable. If commit or push fails, record it as a finding
  — do not silently swallow it.

---

## Step 3 — Self-correction principles (apply throughout every phase)

1. **Re-read `OFFMARKET_PRD_SPEC.md` every iteration.** It is canonical for
   *what* the PRD must contain. If your work has drifted, return to it.
2. **Distrust prior artifacts, including your own.** Sections written by earlier
   iterations may be wrong, stale, or internally inconsistent. SELF-CHECK and
   VERIFY exist to catch that. Do not preserve a section that fails a check.
3. **Cross-check against the real on-market files, do not imagine them.** When
   the PRD claims a field name, an Airtable ID, a file path, or a workflow step,
   that claim must match the actual content of `REVAMP_PLAN.md`,
   `REVAMP_LOOP_PROMPT.md`, the skill files, or the config files on disk. Open
   the file and confirm. Record what you opened in `TEST_LOG.md`.
4. **Flag uncertainty, never fake certainty.** Any NAICS/PSC code, API detail,
   rate limit, or statistic you are not sure of goes in the PRD as
   `⚠ VERIFY: ...`. An unflagged guess is a BLOCKING finding.
5. **Never fake a PASS.** If a self-check item was not actually checked, it is
   `FAIL`. A confidently-wrong "PASS" is the worst output of this loop.
6. **Blocked is honest.** If you genuinely cannot proceed (e.g., a required
   on-market file is missing), record a precise blocker in `BLOCKERS.md`, mark
   the stage `blocked`, and move to an unblocked stage.
7. **No live searches, no external fetches, no tool build, no live Airtable
   writes.** This is a planning pass. The deliverable is the PRD.

---

## Step 4 — Step-out criteria

You exit normally after running exactly one phase: RESOLVE, DRAFT, SELF-CHECK,
VERIFY, FINAL AUDIT, or COMPLETE.

- If you ran COMPLETE and every condition held → output
  `<promise>OFFMARKET_PRD_VERIFIED</promise>` (and only then).
- Otherwise → output a one-paragraph status note: `Iteration N: ran <phase> on
  <stage>. Result: <what changed>. Open findings: X. Open blockers: Y. Next
  iteration will likely run <phase> on <stage>.`

You are Ralph Wiggum. You do not need to be brilliant in one iteration; you need
to be honest and incremental across many. Draft one section. Check it against
the real files. Verify it independently. Resolve the findings. Then — and only
then — emit the promise.

---

## Appendix A — The 9 Stages

Each stage DRAFTs one part of `PRD_OFF_MARKET_SEARCH.md`, then has SELF-CHECK
items that are the bar for `self_checked`; the VERIFY subagent independently
re-checks them for `verified`. Map every stage back to `OFFMARKET_PRD_SPEC.md`.

> **Path note:** Canonical workspace path is `/Users/biffreybraxton/published-
> listing-search/`. The deliverable is `Off-Market Search/PRD_OFF_MARKET_SEARCH.md`.
> Loop control files are under `Off-Market Search/_ralph/`. For `bash`, use the
> real paths; quote the space in `Off-Market Search`.

### Stage 1 — `s1_foundations`: On-market system + PRD front matter
*Spec: "Objective", "Constraints", "On-market system". Dependencies: none.*

DRAFT:
- Read in full: `REVAMP_PLAN.md`, `REVAMP_LOOP_PROMPT.md`,
  `.claude/skills/overnight-search/skill.md`, `.claude/skills/submit-url/skill.md`,
  `.claude/skills/prospect-evaluation/skill.md`,
  `references/buy-box-and-scoring.md`, and the `config/` files. Write a concise
  summary of how on-market opportunities are sourced, scored, stored, and
  iterated on into `_ralph/evidence/onmarket-system-summary.md`.
- Confirm the platform company entity name and thesis (Applied Development) and
  the SBIC screening criteria from `references/buy-box-and-scoring.md`. Record
  the exact quotes/locations in the evidence file.
- Create `Off-Market Search/PRD_OFF_MARKET_SEARCH.md` and write its front
  matter: title, one-paragraph summary, **Objective**, **Success metrics**,
  **Scope**, **explicit Non-goals**, and a short **"How this integrates with the
  existing on-market system"** subsection.

SELF-CHECK:
- `_ralph/evidence/onmarket-system-summary.md` exists, is non-empty, and its
  claims about fields/paths/IDs match the actual on-market files.
- The PRD file exists with Objective, Success metrics, Scope, Non-goals.
- Non-goals explicitly include: no parallel tracker, no new scoring system, no
  live searches in the planning pass.
- The Applied Development entity name and SBIC criteria in the PRD match the
  buy-box reference verbatim (quote the source line).

### Stage 2 — `s2_target_classes`: The two target classes
*Spec: "The two target classes", "Required PRD contents" #2. Deps: s1.*

DRAFT:
- Write the PRD section defining **Target Class 1 (ASL platform bolt-ons)** and
  **Target Class 2 (SBIC firms acquired outright)**. For each: definition, what
  "off-market" means, what the acquisition target is (operating company vs. GP/
  management entity holding the SBIC license — explicitly NOT portfolio
  companies for class 2), and inclusion/exclusion examples.

SELF-CHECK:
- Both classes defined; class 2 explicitly states the target is the SBIC GP /
  management company + license, not the portfolio.
- Class 1 ties to Applied Development as the platform; class 2 ties to the
  SBIC-license-good-standing thesis from the buy-box reference.

### Stage 3 — `s3_sources`: Per-source methodology
*Spec: "Required government / open-data sources", PRD contents #3. Deps: s1.*

DRAFT:
- Write the PRD's per-source methodology, one subsection each for: FPDS-NG,
  SAM.gov, USAspending.gov, SBA SBIC Program directory, SBA DSBS, plus any other
  .gov sources identified (GSA eLibrary / GSA Advantage, state procurement
  portals, state Secretary of State registries, federal-courts interpreter
  procurement) — each with a rationale.
- For each source specify: query parameters, codes, filters, fields to extract,
  access method (UI vs. API vs. bulk download), and rate-limit / ToS notes.
- Propose candidate search keys for class 1 — NAICS **541930**, PSC **R608** —
  each written as `⚠ VERIFY:` items, NOT as confirmed fact. Include the keyword
  strategy (ASL, sign language, interpreting, CART, realtime captioning,
  communication access, deaf/HoH).
- Map each source to the target class(es) it serves.

SELF-CHECK:
- All five required sources covered, plus ≥1 additional .gov source with
  rationale. Each has query params, fields, access method, and ToS/rate notes.
- NAICS 541930 and PSC R608 appear as `⚠ VERIFY:` items, never as plain fact.
- Keyword strategy present. SBA SBIC directory flagged as the primary source
  for class 2; DSBS for class 1.

### Stage 4 — `s4_entity_resolution`: Entity resolution & de-duplication
*Spec: PRD contents #4. Deps: s3.*

DRAFT:
- Write the PRD section on recognizing the same company across FPDS-NG /
  SAM.gov / USAspending — keyed on UEI, CAGE, legacy DUNS, and normalized
  name/address — and on de-duplicating against the existing Airtable tracker so
  targets already in the pipeline are not re-surfaced (match on Business Name +
  Address and, where present, a stored government identifier).

SELF-CHECK:
- Cross-source resolution and tracker dedup both addressed.
- The dedup-vs-tracker logic is consistent with the on-market dedup logic in
  `REVAMP_PLAN.md` Step 2e (cite it). Any new identifier field needed is flagged
  in the schema stage.

### Stage 5 — `s5_qualification`: Raw record → scored prospect
*Spec: PRD contents #5. Deps: s2, s1.*

DRAFT:
- Write the PRD section on how a raw government record becomes a scored
  prospect using the **existing** `prospect-evaluation` skill — class 1 via the
  roll-up add-on path (Applied Development, no size floor, 0–110 score); class 2
  via the SBIC GP screening path (gate = license good standing). No new scoring
  is defined. Specify what raw fields must be gathered before the skill can run
  and what the skill emits back into the record.

SELF-CHECK:
- The section reuses `prospect-evaluation` and `references/buy-box-and-scoring.md`
  verbatim — no parallel scorecard. Class 1 = roll-up add-on mode; class 2 =
  SBIC mode. Both cite the buy-box reference.

### Stage 6 — `s6_schema`: Data schema mapped to the tracker
*Spec: PRD contents #6. Deps: s1, s4, s5.*

DRAFT:
- Write the PRD's data-schema section as a field-by-field mapping table:
  off-market intake field → on-market Airtable field (name + field ID from
  `REVAMP_PLAN.md` Step 1). Off-market and on-market records must be
  interchangeable. Specify the new `Source` single-select value(s) to add
  (e.g., `Off-Market — ASL Bolt-on`, `Off-Market — SBIC`) and flag operator
  action to create them. List any genuinely off-market-only fields (e.g., a
  government-identifier field, SBIC license number) and flag each as a proposed
  new field for operator approval.

SELF-CHECK:
- Every field in the mapping table matches a real field name/ID in
  `REVAMP_PLAN.md` Step 1, or is explicitly marked "PROPOSED NEW FIELD".
- The off-market `Source` values are specified and flagged for operator
  creation. Base/table IDs match `REVAMP_PLAN.md`.

### Stage 7 — `s7_workflow`: Workflow, cadence & integration plan
*Spec: PRD contents #7 and #8. Deps: s3, s6.*

DRAFT:
- Write the PRD's workflow & cadence section, mirroring the loop structure of
  `REVAMP_LOOP_PROMPT.md` (staged, one-unit-per-iteration, self-test/verify
  cadence) and the review cadence of the on-market dashboard.
- Write the integration plan: which existing files / trackers get written to
  (the Airtable table, `output/dashboards/`, `search_reports/`, the dashboard
  template) and how off-market leads appear in the daily dashboard alongside
  on-market leads.

SELF-CHECK:
- Workflow mirrors `REVAMP_LOOP_PROMPT.md` (cite specific parallels).
- Integration plan names real files/paths that exist on disk; off-market leads
  flow into the same dashboard sections.

### Stage 8 — `s8_compliance`: Compliance, legal, risks & open questions
*Spec: PRD contents #9 and #10. Deps: s3.*

DRAFT:
- Write the PRD's compliance & legal section: government-data Terms of Service,
  bulk-access / API-key rules, automated-access / scraping limits, FOIA
  considerations, and PII/handling notes. Then a Risks section and an explicit
  **Open Questions** list — clarifying questions for the operator, plus every
  `⚠ VERIFY:` item collected from the rest of the PRD.

SELF-CHECK:
- ToS, bulk-access rules, and FOIA all addressed. Open-questions list is present
  and gathers every `⚠ VERIFY:` item that appears elsewhere in the PRD.

### Stage 9 — `s9_assembly`: Whole-PRD assembly & consistency
*Spec: all of "Required PRD contents". Deps: s1–s8 all `verified`.*

DRAFT:
- Read the entire `PRD_OFF_MARKET_SEARCH.md`. Add a table of contents, an
  executive summary, and a version/date header. Reconcile cross-references,
  terminology, and any duplicated or contradictory statements between sections.
  Ensure all 10 "Required PRD contents" items from the spec are present and
  clearly findable.

SELF-CHECK:
- A coverage checklist: each of the 10 required-contents items maps to a present
  PRD section — record the section heading for each in `TEST_LOG.md`.
- No section contradicts another; no unresolved `TODO`/placeholder text; every
  uncertain code/stat is `⚠ VERIFY:`-flagged; the file is at the spec's final
  deliverable path.

---

## Appendix B — Key paths & identifiers

- Workspace: `/Users/biffreybraxton/published-listing-search/`
- Canonical spec: `Off-Market Search/OFFMARKET_PRD_SPEC.md`
- Deliverable: `Off-Market Search/PRD_OFF_MARKET_SEARCH.md`
- Loop control files: `Off-Market Search/_ralph/`
- On-market plan / loop: `REVAMP_PLAN.md`, `REVAMP_LOOP_PROMPT.md`
- Skills: `.claude/skills/{overnight-search,submit-url,prospect-evaluation}/`
- Buy Box reference: `references/buy-box-and-scoring.md`
- Airtable: base `appOsvuyy5eK43QTx`, table `tblSmNrHROMLm7vOS` ("Master Deal
  Pipeline"); field IDs in `REVAMP_PLAN.md` Step 1; `Source` field
  `fldiGyXTk6Ybb6J1L`
- GitHub remote: `origin` → `earnedout-workspace`
- Promise token: `OFFMARKET_PRD_VERIFIED`

If any path or identifier here does not match what you find on disk, trust the
filesystem and the spec — and record the discrepancy as a finding.

---

## Appendix C — VERIFY subagent brief

For a stage VERIFY, spawn a critic subagent with the Agent tool
(`subagent_type: general-purpose`). Brief it as a skeptical, fresh-context
colleague — substitute the bracketed values:

> "You are independently verifying ONE section of the Off-Market Target Search
> PRD: **[stage name]**. Context: a Ralph loop is writing
> `Off-Market Search/PRD_OFF_MARKET_SEARCH.md` against the spec
> `Off-Market Search/OFFMARKET_PRD_SPEC.md`, both under
> `/Users/biffreybraxton/published-listing-search/`. This is a planning pass —
> the PRD must integrate with the EXISTING on-market system, not create a
> parallel one. Read the spec, read the relevant PRD section, and read the
> loop's `_ralph/TEST_LOG.md` entries for this stage. Your job: (1)
> **Completeness** — does the section cover every spec requirement for this
> stage? (2) **Truth** — open the on-market files it cites (`REVAMP_PLAN.md`,
> the skills, config) and confirm every field name, ID, and path the section
> claims is real. (3) **Uncertainty flagging** — every NAICS/PSC code, API
> detail, rate limit, or statistic must be flagged `⚠ VERIFY:`; flag any
> unflagged guess as BLOCKING. (4) **No parallel system** — flag anything that
> invents new scoring/tracking instead of reusing the existing skill/tracker.
> Output a numbered list of findings, each specific (file/line where possible)
> with severity BLOCKING / IMPROVE / NIT and a suggested fix. End with exactly
> one line: `VERDICT: SHIP` or `VERDICT: REVISE`. Under 800 words."

For the **FINAL AUDIT**, spawn one subagent with this brief:

> "You are the final auditor of the Off-Market Target Search PRD at
> `/Users/biffreybraxton/published-listing-search/Off-Market Search/
> PRD_OFF_MARKET_SEARCH.md`. Read `OFFMARKET_PRD_SPEC.md` in full. Independently
> confirm every one of the 10 'Required PRD contents' items is genuinely present
> and complete, that the PRD integrates with the existing on-market system (no
> parallel tracker or scorer), that every field/ID/path it cites is real on
> disk, and that every uncertain NAICS/PSC code, API detail, and statistic is
> flagged `⚠ VERIFY:`. Your single most important job is to catch any section
> that is claimed-done but incomplete, internally inconsistent, or states a
> guess as fact. Output a numbered findings list with severities, then exactly
> one line: `VERDICT: SHIP` or `VERDICT: REVISE`. Under 1000 words."

---

Begin at Step 0.
