# Run the Off-Market Build Loop Overnight

Paste the prompt in the code block below into a Claude Code session.

**Before you paste it:**
- Open Claude Code with its working directory at the repo root
  `~/published-listing-search`.
- For a truly unattended run, start the session so it will **not pause on
  permission prompts** (enable auto-accept for edits and commands, or run in a
  headless/skip-permissions mode). Otherwise it will wait at the first tool
  prompt instead of running through the night.
- It commits locally after each iteration and never pushes — your work is safe
  and reviewable in the morning.

When it stops, read `Off-Market Search/_ralph_build/MORNING_QUESTIONS.md` — that
is your morning to-do list.

---

```
You are running the off-market build loop autonomously and unattended
overnight. I am asleep; do not pause for interactive confirmation — defer every
question to the morning. Run from the repo root ~/published-listing-search.

FIRST, read in full:
- Off-Market Search/OFFMARKET_BUILD_LOOP_PROMPT.md  (your per-iteration contract)
- Off-Market Search/OFFMARKET_BUILD_PLAN.md         (the canonical plan: 10
  stages, locked-in decisions, constraints)
- Off-Market Search/_ralph_build/STATE.md           (the state machine)
- Off-Market Search/PRD_OFF_MARKET_SEARCH.md and
  Off-Market Search/PRD_OFF_MARKET_SEARCH_Section13_Resolution.md
  (requirements + verified operator decisions; the resolution doc wins on any
  conflict with the PRD)

THEN act as both the loop runner and the iteration executor:
1. Set `active: true` in Off-Market Search/_ralph_build/STATE.md.
2. Repeatedly execute the single-iteration contract from
   OFFMARKET_BUILD_LOOP_PROMPT.md: advance exactly one (stage, phase) step,
   write the matching _ralph_build log, update STATE.md, and commit locally
   (if the project uses git; never push). Before each iteration, re-read
   STATE.md and _ralph_build/BLOCKERS.md fresh, and rely on the _ralph_build/
   log files as your memory rather than this conversation.
3. Continue iteration after iteration on your own — do NOT stop or ask
   permission between iterations — as long as any non-blocked work remains.

BLOCKER HANDLING:
- When a stage hits an external precondition you cannot satisfy (a missing
  credential, no permission, an undecided question with no default), mark it
  blocked in BLOCKERS.md, set its stage status to `blocked` in STATE.md, and
  move on to the next non-blocked stage. Do NOT stop the loop just because one
  stage is blocked.
- For B2 (SBIC scope): proceed on the documented default — all licensed SBIC
  types — and note it for my confirmation. B2 does not stop you.
- Actually attempt the work before declaring it blocked: try the Airtable
  schema writes via the Airtable connector, the key-free USAspending API, etc.
  Block only on a genuine failure, not a guess.
- If an API rate-limits you, back off and continue with other non-blocked work.
- If a file the plan depends on is missing, record it as a blocker and continue.

STOP the loop and wait for me when ANY of these is true:
- COMPLETE conditions hold and you have emitted
  <promise>OFFMARKET_BUILD_VERIFIED</promise> — the build is finished.
- `iteration` reaches `max_iterations`.
- Every stage that is not `verified` is `blocked` — all remaining work needs me.
- An unrecoverable error (repo root not found, or the plan files cannot be read).

NEVER, while unattended: send any outreach email; guess or fabricate a value to
clear a blocker; create a parallel tracker or a new scorer; emit the promise
token unless COMPLETE genuinely holds; push to a git remote.

WHEN YOU STOP, write Off-Market Search/_ralph_build/MORNING_QUESTIONS.md — a
numbered, plain-language list of everything you need from me to finish. For each
item state: what you need, why, which stage/blocker it clears, and the default
you used (if any). Commit it. Then print, as your final terminal message:
(a) that same numbered question list, and (b) a short summary of the overnight
run — stages verified, stages blocked and why, and how many iterations and
commits ran.

Begin now.
```
