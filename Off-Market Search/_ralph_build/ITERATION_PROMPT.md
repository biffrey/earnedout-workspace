# Off-Market Build Loop — Single Iteration

You are ONE iteration of the off-market build loop, invoked headlessly by a
shell runner (`run-offmarket-build-loop.sh`). Do exactly one step, then stop —
the runner will invoke you again with fresh context. Shared memory across
iterations is the `_ralph_build/` state and log files, NOT conversation history.

Repo root: `~/published-listing-search`. All paths below are relative to it.

## Read first
- `Off-Market Search/OFFMARKET_BUILD_LOOP_PROMPT.md` — your per-iteration contract
- `Off-Market Search/OFFMARKET_BUILD_PLAN.md` — the canonical plan (10 stages)
- `Off-Market Search/_ralph_build/STATE.md` — the state machine
- `Off-Market Search/_ralph_build/BLOCKERS.md` — current blockers
- the parts of `Off-Market Search/PRD_OFF_MARKET_SEARCH.md` and
  `Off-Market Search/PRD_OFF_MARKET_SEARCH_Section13_Resolution.md` relevant to
  the current stage (the resolution doc wins on any conflict with the PRD)

## Do this, in order
1. If `STATE.md` has `active: false`, set it to `true`.
2. **Stop checks — evaluate before doing any build work:**
   - If COMPLETE conditions hold (all 10 stages `verified`, `final_audit_passed:
     true`, `unresolved_findings: 0`, `open_blockers: 0`): make sure
     `<promise>OFFMARKET_BUILD_VERIFIED</promise>` has been emitted, then signal
     **STOP-COMPLETE**.
   - Else if `iteration` >= `max_iterations`: refresh
     `_ralph_build/MORNING_QUESTIONS.md`, then signal **STOP-BLOCKED**.
   - Else if every stage that is not `verified` is `blocked`: refresh
     `_ralph_build/MORNING_QUESTIONS.md`, then signal **STOP-BLOCKED**.
   - If a stop check fired, skip to step 5 — do no build work this iteration.
3. Otherwise execute **exactly one (stage, phase) step** per
   `OFFMARKET_BUILD_LOOP_PROMPT.md`: pick the lowest-numbered stage that is not
   `verified` and not `blocked`; advance it one phase (IMPLEMENT → SELF-TEST →
   VERIFY), or run FINAL AUDIT / RESOLVE if all 10 stages are already
   `verified`. Write the matching `_ralph_build/` log, update `STATE.md` (bump
   `iteration`, set `last_iteration_at`, update the stage status and the
   `open_blockers` / `unresolved_findings` counts), and `git commit` locally
   (never push).
4. **Rules while unattended:** never send outreach email; never fabricate a
   value to clear a blocker; use the B2 default (all licensed SBIC types); when
   you hit an external precondition you cannot satisfy, mark the stage `blocked`
   in `BLOCKERS.md` and `STATE.md` and let the runner move on. On an
   unrecoverable error, signal **STOP-ERROR**.
5. **Signal — your final action.** Overwrite the file
   `Off-Market Search/_ralph_build/.loop_signal` with **exactly one word and
   nothing else**:
   - `CONTINUE` — you completed one step and more non-blocked work remains.
   - `STOP-COMPLETE` — the build loop is finished.
   - `STOP-BLOCKED` — all remaining work needs the operator.
   - `STOP-ERROR` — an unrecoverable error occurred.

Do not perform more than one (stage, phase) step. Do not ask interactive
questions — record everything you need from the operator in
`_ralph_build/MORNING_QUESTIONS.md`.
