# BLOCKERS — external dependencies the loop cannot resolve itself

Each blocker records the stage, what is blocked, the precondition that must
clear, and exact fix instructions for Biffrey. When a precondition is
satisfied, the blocker is marked RESOLVED and the affected stage is reset.

## Counting blockers (gate the COMPLETE phase; `open_blockers` counts these)

### B1 — s3_onepassword — `op` (1Password CLI) not available in the execution sandbox

**Raised:** iteration 14 (2026-05-21T02:15:09Z)
**Stage blocked:** `s3_onepassword` (status set `implemented` → `blocked`)
**`open_blockers`:** incremented 0 → 1

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

_No other open counting blockers._

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
