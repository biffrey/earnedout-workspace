# Off-Market Build Loop — Blockers

External preconditions the loop cannot resolve itself, each with exact fix
instructions for Biffrey. The loop advances every non-blocked stage and retries
a blocked stage once its precondition clears. COMPLETE requires `open_blockers: 0`.

---

## B1 — Priority-state list (operator)
**Blocks:** the state-source adapter in s3 (and any state enrichment in s5).
**Why:** §13 Q6 — the operator chose to include state sources in Phase 1, but no
priority states are named. State eProcurement portals and Secretary-of-State
registries are non-uniform and each has its own ToS.
**Fix:** Biffrey names the Phase-1 priority states (e.g., by population, deaf-
population concentration, or existing-deal geography). For each, the loop then
confirms the portal's terms before automating.
**Status:** OPEN.

## B2 — SBIC scope decision (operator)
**Blocks:** the SBIC scope filter in s3; SBIC handling in s5.
**Why:** §13 Q8 was deferred pending research. Current SBA SBIC license types
are Standard Debenture, Accrual, and Reinvestor, plus non-leveraged licensed
SBICs. The build needs to know which are in scope.
**Fix:** Biffrey confirms scope. **Default if unanswered: all licensed SBIC
types** — the loop will proceed on the default and the good-standing gate plus
`prospect-evaluation` SBIC mode do the filtering.
**Status:** OPEN (default available — does not hard-stop s3).

## B3 — SAM.gov account + Public API Key (operator)
**Blocks:** the SAM.gov Entity Management API and SAM.gov Contract Awards API
adapters in s3, above the 10-requests/day tier.
**Why:** verified in §13 — a SAM.gov account with **no role** is capped at 10
requests/day; a role-assigned account gets 1,000/day. The key is sent as the
`x-api-key` header.
**Fix:** Biffrey creates/uses a SAM.gov account, has a **role** assigned, and
generates the Public API Key (SAM.gov → Profile → Account Details → Public API
Key). Provide the key to the loop via the project's secret store, not in plain
text in any file.
**Status:** OPEN.

## B4 — Airtable schema-write access (operator / MCP)
**Blocks:** s2 (Airtable schema).
**Why:** s2 must add the §8.3 `Source` values (`Off-Market — ASL Bolt-on`,
`Off-Market — SBIC`) and the §8.4 fields plus `Gov Entity ID` to base
`appOsvuyy5eK43QTx` / table `tblSmNrHROMLm7vOS`.
**Fix:** confirm the Airtable MCP connection has schema-write permission on that
base, or Biffrey creates the fields/values manually per `OFFMARKET_BUILD_PLAN.md`
s2 and the PRD §8.3 / §8.4.
**Status:** OPEN.

---

_Resolved blockers are struck through and dated; they are not deleted._
