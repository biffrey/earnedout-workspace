# BLOCKERS — external dependencies the loop cannot resolve itself

Each blocker records the stage, what is blocked, the precondition that must
clear, and exact fix instructions for Biffrey. When a precondition is
satisfied, the blocker is marked RESOLVED and the affected stage is reset.

## Counting blockers (gate the COMPLETE phase; `open_blockers` counts these)

_No open counting blockers._

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
