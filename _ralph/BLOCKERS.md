# BLOCKERS — external dependencies the loop cannot resolve itself

Each blocker records the stage, what is blocked, the precondition that must
clear, and exact fix instructions for Biffrey. When a precondition is
satisfied, the blocker is marked RESOLVED and the affected stage is reset.

## Counting blockers (gate the COMPLETE phase; `open_blockers` counts these)

### B1 — s3_onepassword — `op` (1Password CLI) not available in the execution sandbox — ✅ RESOLVED

**Raised:** iteration 14 (2026-05-21T02:15:09Z)
**Stage blocked:** `s3_onepassword` (status set `implemented` → `blocked`)
**`open_blockers`:** incremented 0 → 1; decremented 1 → 0 on resolution below.

> ## ✅ RESOLVED — 2026-05-21, operator manual review (not an automated iteration)
>
> Biffrey ran the `op` 1Password CLI directly on his Mac during a manual review
> session with Claude, and the credential-retrieval check **genuinely
> succeeded**. Full transcript and evidence:
> `_ralph/evidence/s3_op_verification_2026-05-21.md`.
>
> **What was observed:**
> - `op whoami` → signed in (account `bb@braxton.ai`, `my.1password.com`).
> - `op read "op://Private/DealStream/username"` → **FAILED**: `"Private" isn't
>   a vault in this account`. The plan's original canonical path does not exist.
> - `op vault list` → the account has exactly one vault: `Personal`.
> - `op item list` → the DealStream login item is `dealstream.com` (in
>   `Personal`), not an item named `DealStream`.
> - `op read "op://Personal/dealstream.com/username"` → **SUCCESS**: returned a
>   real, non-empty value with no error. (Secret not logged — only "credential
>   retrieved, length > 0" per the s3 SELF-TEST rule.)
>
> **Path reconciliation (also closes finding F2's deferred real-world question):**
> the verified canonical path is `op://Personal/dealstream.com/username` and
> `op://Personal/dealstream.com/password`. This was propagated to
> `REVAMP_PLAN.md` Step 0, `config/credentials-setup.md`, and
> `REVAMP_LOOP_PROMPT.md` (Appendix A Stage 3 and Appendix B).
>
> **How the s3 SELF-TEST is satisfied going forward:** `op` is a desktop
> credential manager and genuinely cannot run in the ephemeral Linux sandbox —
> that is the permanent reason B1 was raised, and it does not change. The
> resolution Biffrey chose ("verify on your Mac, record the evidence") means the
> `op read` check was run for real by the operator, and its evidence is on disk.
> `REVAMP_LOOP_PROMPT.md` Appendix A Stage 3 SELF-TEST has been updated so the
> loop confirms the recorded evidence file rather than re-running `op` in the
> sandbox. **The loop must NOT re-run `op` in the sandbox and must NOT re-raise
> B1.** This is a genuine, operator-run check with its evidence preserved — not
> a faked PASS.
>
> **Counter changes:** `open_blockers` 1 → 0; `s3_onepassword` reset
> `blocked` → `implemented` (the loop will SELF-TEST then VERIFY it normally).
>
> The original blocker analysis is retained below as a historical record.

**Observed (s3 SELF-TEST Check 2, iteration 14):**
```
$ op --version
bash: line 1: op: command not found     (exit 127)
$ which op
[no output]                             (exit 1)
$ op read "op://Private/DealStream/username"
bash: line 1: op: command not found
```
The 1Password CLI `op` is not installed in the loop's Linux execution sandbox.
The sandbox is ephemeral and has no 1Password desktop app to integrate with, so
the credential read that proves DealStream authentication works cannot be
exercised here. The s3 IMPLEMENT artifact (`config/credentials-setup.md`) is
correct and passed s3 SELF-TEST Check 1 — only the live `op` check is blocked.

**Precondition to clear:** `op` must be installed and signed in somewhere the
loop's SELF-TEST can reach, AND `op read "op://Private/DealStream/username"`
must return a non-empty value.

**Why this is a COUNTING blocker (unlike finding F1 and advisory A1):**
Credential retrieval is a hard functional requirement of the revamp, not an
optional or cosmetic leg. The overnight-search and submit-url skills cannot log
into DealStream without it; the plan's Verification check #1 is literally
"`op read` retrieves DealStream credentials," and the s9 end-to-end run cannot
start without it. F1 (`git push` to a mirror) and A1 (restart-gated MCP tool
surfacing) are genuinely optional/cosmetic — this is not. Appendix A Stage 3
SELF-TEST explicitly directs: "If `op` is missing or not signed in, record a
blocker with sign-in instructions; this stage becomes `blocked`," and Step 1's
SELF-TEST rule explicitly says to increment `open_blockers`. So it counts. This
will gate the COMPLETE phase until resolved — which is the honest, correct
outcome: the loop must not fake a credential check it never ran.

**Fix instructions for Biffrey:**
1. On the machine where the loop's SELF-TEST runs, install the 1Password CLI:
   `brew install --cask 1password-cli` (macOS); other platforms:
   https://developer.1password.com/docs/cli/get-started/
2. Enable the desktop-app integration: 1Password → Settings → Developer →
   "Integrate with 1Password CLI".
3. Sign in: `op signin`; confirm with `op whoami`.
4. Confirm the DealStream item path resolves. Canonical path per
   `REVAMP_PLAN.md` Step 0: `op://Private/DealStream/username` and
   `op://Private/DealStream/password`. Run
   `op read "op://Private/DealStream/username"`. If it errors "item not found",
   the item is elsewhere — the pre-loop config documented
   `op://Personal/dealstream.com/...`. Reconcile per the "Vault / item-path
   reconciliation needed" section of `config/credentials-setup.md`: either
   move/alias the item to `op://Private/DealStream/...`, or update
   `REVAMP_PLAN.md` + `config/credentials-setup.md` to the path that resolves.
   (This folds in finding F2's open real-world question.)
5. Note: the Linux execution sandbox itself has no 1Password desktop app and
   cannot run `op` regardless of install. For the loop to clear B1, the
   SELF-TEST environment must be able to reach an `op` that is installed and
   signed in. If that is not feasible, B1 remains open and the loop will not
   reach COMPLETE — that honest state is preferable to faking the check.

**When resolved:** a future iteration's Step 1 blocker re-check will detect `op`
available, mark B1 RESOLVED, decrement `open_blockers` 1 → 0, reset
`s3_onepassword` from `blocked` back to `implemented`, and retry the s3
SELF-TEST.

_B1 is RESOLVED (2026-05-21 operator manual review)._

### B2 — s9_end_to_end — live end-to-end pipeline run cannot execute in the sandbox — ⛔ OPEN

**Raised:** iteration 43 (2026-05-21T15:08:15Z)
**Stage blocked:** `s9_end_to_end` (status set `not_started` → `blocked` —
IMPLEMENT could not be performed)
**`open_blockers`:** incremented 0 → 1.

**What is blocked:** Stage 9's IMPLEMENT bar (Appendix A Stage 9) is *actually
running the pipeline end-to-end against live systems* — execute the
overnight-search skill (one industry, limited pagination), run the submit-url
skill on a known-good URL, and trigger a price-drop scenario, then satisfy the
plan's 13 Verification checks. None of that can run from the ephemeral Linux
execution sandbox.

**Observed (iteration 43):**
```
$ which op            ; echo $?      ->  (no output) 1
$ op --version                       ->  op: command not found   (exit 127)
$ op whoami                          ->  op: command not found   (exit 127)
$ curl -s -o /dev/null -w '%{http_code}' https://www.dealstream.com   ->  000
$ curl -s -o /dev/null -w '%{http_code}' https://www.bizquest.com     ->  000
$ curl -s -o /dev/null -w '%{http_code}' https://www.bizbuysell.com   ->  403
$ curl -s -o /dev/null -w '%{http_code}' https://api.airtable.com     ->  000
```

**Root cause — two independent, sandbox-permanent reasons:**
1. **No `op`.** The overnight-search skill Step 1 retrieves DealStream
   credentials via the `op` 1Password CLI and is explicitly designed to *fail
   loud and stop* when `op` is unavailable. `op` is a desktop credential manager
   on Biffrey's Mac, not a sandbox tool (the same permanent limitation that
   produced B1). Without it the pipeline cannot authenticate to DealStream, so
   it cannot begin.
2. **No network route to the platforms.** Even with credentials, the sandbox
   network allowlist does not reach DealStream / BizQuest (`000`, no route) or
   BizBuySell (`403`). The pipeline cannot log in, paginate search results, or
   validate listing detail URLs / capture screenshots against live sites.
The Playwright MCP tools (`mcp__playwright__*`) are also still absent from the
tool list (advisory A1) — a third, lesser obstacle.

**Why this is a COUNTING blocker (unlike advisory A1 and finding F1):**
Stage 9 is the live end-to-end verification — the functional heart of the
revamp. It maps to plan Implementation Order #9 and the *entire* "Verification"
section (all 13 checks). It is in no sense optional or cosmetic, and — unlike s2,
whose SELF-TEST had a genuine `npx playwright` CLI fallback — there is **no
honest fallback** by which the loop can run the live pipeline (real DealStream
login, real crawl, real Playwright URL validation) from this sandbox. The s9
SELF-TEST's 13 checks fundamentally require live systems. Marking B2
non-counting purely to let COMPLETE proceed would be exactly the deception this
loop forbids. So B2 counts and gates the COMPLETE phase — the honest outcome.

**Precondition to clear:** EITHER (a) the loop's execution environment can run
`op` (installed + signed in) AND reach DealStream so the pipeline genuinely
runs; OR (b) an operator-recorded evidence file exists at
`_ralph/evidence/s9_e2e_verification_<date>.md` documenting a genuine live run —
the same model that resolved B1 for s3.

**Fix instructions for Biffrey (recommended — Option b, mirrors the B1 fix):**
1. On your Mac (where `op` is signed in and DealStream is reachable), run the
   overnight-search skill end-to-end at deliberately small scope: one industry,
   limited pagination. The skill is `.claude/skills/overnight-search/skill.md`.
2. Then run the submit-url skill on one known-good listing URL, and trigger the
   price-drop scenario from plan Verification check #7 (set a test record's
   Asking Price higher than the live price, re-run, confirm the update).
3. Tag every Airtable record created during the run with `[RALPH TEST]` in the
   Notes field so they are identifiable, and delete/clearly-mark them afterward.
4. Walk the plan's 13 "Verification" checks and record, for each, PASS/FAIL with
   real evidence (command output, screenshot file paths under
   `output/screenshots/`, generated report paths under `output/reports/`,
   Airtable record IDs, the dashboard path). Save this as
   `_ralph/evidence/s9_e2e_verification_<date>.md` and commit it (an operator
   identity, e.g. `Cowork Manual Review`, like the B1 evidence commit `fb0b560`).
5. The next scheduled run's Step 1 blocker re-check will detect that evidence
   file, mark B2 RESOLVED, decrement `open_blockers` 1 → 0, reset
   `s9_end_to_end` `blocked` → `not_started`, and a later iteration's SELF-TEST
   will confirm the 13 checks against the evidence rather than re-running the
   live pipeline in the sandbox (the mechanism the operator-rewritten Appendix A
   Stage 3 SELF-TEST already uses for s3).

Alternative (Option a): give the loop's execution environment a signed-in `op`
and network access to DealStream/BizQuest/BizBuySell so the loop runs s9 itself.
This is unlikely to be feasible for an ephemeral sandbox; Option b is expected.

**When resolved:** a future iteration's Step 1 blocker re-check marks B2
RESOLVED, decrements `open_blockers` 1 → 0, and resets `s9_end_to_end` to
`not_started` for retry.

_B2 is OPEN. `open_blockers: 1`. COMPLETE is gated until B2 resolves or the
60-iteration cap is reached._

## Advisory notes (non-counting — do NOT add to `open_blockers`)

These are documented external limitations that do **not** block any stage from
reaching `verified`, so they are intentionally excluded from `open_blockers` to
avoid falsely deadlocking the COMPLETE phase. Same classification rationale as
finding F1.

### A1 — s2_playwright — Playwright MCP tools require a Cowork restart

**Raised:** iteration 3 (2026-05-20T23:56:28Z)
**Observed:** After `npm install -g @playwright/mcp` (→ `@playwright/mcp@0.0.75`)
and `npx playwright install chromium` both succeeded this iteration, the
Playwright MCP tools (`mcp__playwright__*`) are still NOT in the loop's tool
list. Per Appendix A Stage 2, these tools surface only after a Cowork session
restart — the running session loaded its tool list before the MCP was
installed.

**Why non-counting:** The mandatory s2 SELF-TEST bar (settings.json parses +
has `playwright` server; `npm ls -g @playwright/mcp` confirms install; headless
Chromium smoke test loads a page and captures a screenshot) is fully executable
via the `npx playwright` / Node CLI path that Appendix A Stage 2 SELF-TEST
explicitly provides as the fallback. The live-MCP-navigation check is explicitly
conditional ("If the Playwright MCP tools are present... additionally"), so the
absence of the MCP tools does not prevent s2 from reaching `self_tested` or
`verified`. The restart precondition cannot clear inside this automated,
1-minute-interval, no-human, no-restart chained loop; escalating it to a
counting blocker would permanently deadlock COMPLETE (`open_blockers == 0`
required). Recorded here for transparency, not counted.

**Fix instructions for Biffrey (optional — enables the extra MCP-backed check):**
Restart the Cowork desktop app. On the next session the `mcp__playwright__*`
tools will load (the install persists if it lands in a persistent location;
otherwise the loop re-installs at SELF-TEST time). With the MCP tools present, a
SELF-TEST/VERIFY iteration can additionally run one live MCP navigation. This is
an enhancement, not a requirement for s2 to verify.
