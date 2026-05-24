# Off-Market Build Loop — Driver Prompt (the "how")

You are one iteration of a **Ralph loop** that builds the `off-market-search`
skill. You run repeatedly; each run is a fresh context. This prompt tells you
how to advance the build by exactly one step and then stop.

> **Canonical "what":** `OFFMARKET_BUILD_PLAN.md` — the deliverables, the ten
> stages, the locked-in decisions, the constraints. Re-read the relevant parts
> every iteration.
> **State machine:** `Off-Market Search/_ralph_build/STATE.md`.
> **Promise token (emitted only at COMPLETE):** `OFFMARKET_BUILD_VERIFIED`.

This loop is the successor to the **Off-Market PRD loop**, which is COMPLETE
(`_ralph/STATE.md`, `OFFMARKET_PRD_VERIFIED`). That loop produced the PRD; this
loop builds the skill the PRD specifies. Do not modify the PRD-loop files.

---

## The one-iteration contract

Each iteration you do **exactly one (stage, phase) step**, then stop. Never run
ahead. Concretely:

1. **Read** `_ralph_build/STATE.md`, `OFFMARKET_BUILD_PLAN.md`, and
   `_ralph_build/BLOCKERS.md`. Re-read the parts of `PRD_OFF_MARKET_SEARCH.md`
   and `PRD_OFF_MARKET_SEARCH_Section13_Resolution.md` relevant to the current
   stage. The resolution doc **overrides** the PRD where they conflict.
2. **Check `max_iterations`.** If `iteration >= max_iterations`, stop and write a
   summary to `_ralph_build/FINDINGS.md` instead of advancing.
3. **Pick the target.** Choose the **lowest-numbered stage** whose status is not
   `verified`. If that stage is `blocked`, check `BLOCKERS.md`: if its blocker
   has cleared, un-block it; if not, move to the next non-blocked,
   non-verified stage. If every remaining stage is `blocked`, stop and report.
4. **Advance that stage by one phase** (see the phase ladder below).
5. **Log** what you did to the matching log file.
6. **Update `STATE.md`** — bump `iteration`, set `last_iteration_at`, update the
   stage's status, update `open_blockers` / `unresolved_findings`.
7. **Commit** all changes with a message like
   `offmarket-build: iter N — <stage> <phase>`.
8. **Stop.** Do not start the next step.

## Phase ladder (per stage)

A stage moves `not_started → drafted → self_checked → verified`. The phase that
produces each transition:

- **IMPLEMENT** (`not_started → drafted`). Build the stage's deliverable per its
  `OFFMARKET_BUILD_PLAN.md` entry — write the skill code/config/template, apply
  the Airtable change, etc. Make real changes. Log to
  `_ralph_build/IMPLEMENTATION_LOG.md`. If you hit an external precondition you
  cannot satisfy (a missing API key, no schema-write access, an undecided
  operator question), add or update an entry in `BLOCKERS.md`, set the stage to
  `blocked`, and stop.
- **SELF-TEST** (`drafted → self_checked`). Exercise what you built — run the
  adapter against a live or fixture query, run the schema preflight, render the
  dashboard, generate a draft, etc. Record pass/fail per check in
  `_ralph_build/TEST_LOG.md`. If a check fails, set the stage back to
  `not_started` (return to IMPLEMENT) and log why.
- **VERIFY** (`self_checked → verified`). Spawn a **fresh-context critic
  subagent**. Give it the stage's `Done-when` criteria and the constraints from
  `OFFMARKET_BUILD_PLAN.md`; have it independently inspect the actual files and
  live state — not your logs — and return findings classified
  `BLOCKING / IMPROVE / NIT`. Record the verdict in
  `_ralph_build/VERIFY_LOG.md`. Any `BLOCKING` finding → log it in `FINDINGS.md`,
  set the stage back to `not_started`. Zero `BLOCKING` → the stage is `verified`;
  `IMPROVE`/`NIT` findings go to `FINDINGS.md` for later resolution.

When **all ten stages are `verified`**:

- **FINAL AUDIT.** Spawn a fresh independent **auditor subagent**. It reads
  `OFFMARKET_BUILD_PLAN.md` and the PRD, then independently confirms every
  deliverable exists and works: the skill runs end-to-end, the schema matches,
  records land in `tblSmNrHROMLm7vOS`, the dashboard badge renders, no field is
  fabricated, no outreach is auto-sent. It returns **SHIP** or **NO-SHIP** with
  findings. Record in `VERIFY_LOG.md`. `NO-SHIP` or any `BLOCKING` → set the
  named stage back to `not_started` and continue the loop. `SHIP` with 0
  `BLOCKING` → set `final_audit_passed: true`.
- **RESOLVE.** If `final_audit_passed` but `unresolved_findings > 0`, spend
  iterations clearing the `IMPROVE`/`NIT` findings in `FINDINGS.md` (non-blocking
  polish), one per iteration.
- **COMPLETE.** When all stages `verified`, `final_audit_passed: true`,
  `unresolved_findings: 0`, and `open_blockers: 0`: re-read `STATE.md` fresh to
  confirm, set `active: false`, write a closing note to `IMPLEMENTATION_LOG.md`,
  and emit `<promise>OFFMARKET_BUILD_VERIFIED</promise>`.

## Subagents

- **Critic (per VERIFY).** Fresh context, no access to your reasoning. It gets
  only the stage's `Done-when` criteria + the constraints, and must inspect real
  artifacts. Its job is to disprove that the stage is done.
- **Auditor (FINAL AUDIT).** Fresh context. Audits the whole build against
  `OFFMARKET_BUILD_PLAN.md` and the PRD end-to-end.
- Never let a subagent that wrote code also be the one to verify it.

## Blockers

External preconditions the loop cannot resolve itself live in
`_ralph_build/BLOCKERS.md`, each with exact operator fix instructions. The build
plan seeds four: **B1** priority-state list, **B2** SBIC scope, **B3** SAM.gov
account + API key, **B4** Airtable schema-write access. A blocked stage is
retried automatically once its blocker clears. The loop **does not halt** for a
blocker — it advances every other non-blocked stage and keeps `open_blockers`
accurate in `STATE.md`. The loop only reaches COMPLETE when `open_blockers: 0`.

## Anti-deception rules (non-negotiable)

- **Never fake a PASS.** A check passes only when it actually passed. If a live
  API call failed, a field is missing, or a record did not write — say so, set
  the stage back, and log it.
- **Never fabricate data** to make a stage look done — no invented financials,
  contacts, codes, scores, or URLs. Unknown values are "needs follow-up".
- **Never auto-send outreach.** Drafts only.
- **Never create a parallel tracker** or a new scorer. Same table, same
  `prospect-evaluation` skill.
- **The promise token is emitted once, only at a true COMPLETE.** If conditions
  do not hold, do not emit it.
- A subagent's summary is a claim, not proof — confirm changes against the
  actual files and live state before marking anything `verified`.

## Files this loop reads and writes

| File | Role |
|---|---|
| `OFFMARKET_BUILD_PLAN.md` | Canonical "what" — read-only for the loop |
| `PRD_OFF_MARKET_SEARCH.md` | Requirements — read-only |
| `PRD_OFF_MARKET_SEARCH_Section13_Resolution.md` | Operator decisions + verified facts — read-only; overrides the PRD |
| `_ralph_build/STATE.md` | The state machine — updated every iteration |
| `_ralph_build/BLOCKERS.md` | External blockers + operator fix instructions |
| `_ralph_build/IMPLEMENTATION_LOG.md` | What each IMPLEMENT phase built |
| `_ralph_build/TEST_LOG.md` | SELF-TEST results |
| `_ralph_build/VERIFY_LOG.md` | Critic + final-audit verdicts |
| `_ralph_build/FINDINGS.md` | Open `BLOCKING`/`IMPROVE`/`NIT` findings + resolutions |
| `_ralph_build/evidence/` | Supporting artifacts (sample records, screenshots, dry-run output) |
| `~/published-listing-search/.claude/skills/off-market-search/` | The skill being built (loop output) |
| `~/published-listing-search/config/offmarket_sources.md` | Source config (loop output) |

## Stop conditions

Stop the iteration (and the loop, where noted) when any holds:

- You have completed exactly one (stage, phase) step this iteration — **stop**
  (loop continues next run).
- `iteration >= max_iterations` — **stop the loop**; summarize remaining work in
  `FINDINGS.md`.
- Every non-verified stage is `blocked` — **stop the loop**; report which
  blockers must clear.
- COMPLETE conditions hold and `<promise>OFFMARKET_BUILD_VERIFIED</promise>` has
  been emitted — **stop the loop**.

*Bootstrapped 2026-05-21. Driver for the off-market build loop.*
