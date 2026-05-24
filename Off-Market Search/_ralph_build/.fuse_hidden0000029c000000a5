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
**Resolution (2026-05-22, operator decision):** Phase-1 priority jurisdictions
are **DC, VA, MD, PA, WV** — the mid-Atlantic region into the nearer Northeast.
The s3 state-source adapter and the s5 SOS formation-date lookup must be built
for these five, with each portal's / registry's ToS confirmed before
automating. Because s3 and s5 were verified earlier with the state pieces as
fixture-shells (a concession to this blocker being open), the real build is
tracked as IMPROVE-s3-2 and IMPROVE-s5-5 in FINDINGS.md — both must close
before COMPLETE.
**Status:** ~~OPEN~~ → RESOLVED 2026-05-22.

## B2 — SBIC scope decision (operator)
**Blocks:** the SBIC scope filter in s3; SBIC handling in s5.
**Why:** §13 Q8 was deferred pending research. Current SBA SBIC license types
are Standard Debenture, Accrual, and Reinvestor, plus non-leveraged licensed
SBICs. The build needs to know which are in scope.
**Fix:** Biffrey confirms scope. **Default if unanswered: all licensed SBIC
types** — the loop will proceed on the default and the good-standing gate plus
`prospect-evaluation` SBIC mode do the filtering.
**Resolution (2026-05-22, operator decision):** Confirmed — **all licensed SBIC
types are in scope** (Standard Debenture, Accrual, Reinvestor, and non-leveraged
licensed SBICs). This matches the documented default, so no build change is
required; the good-standing gate and `prospect-evaluation` SBIC mode do the
filtering.
**Status:** ~~OPEN~~ → RESOLVED 2026-05-22.

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
**Resolution (2026-05-22):** Operator obtained the Public API Key. It is stored
in the macOS **login keychain** as a generic ("application") password —
service/"Where" `samgov-api-key`, account `off-market-search` — NOT written in
plain text in any file. The skill retrieves it at runtime with:
`security find-generic-password -s samgov-api-key -a off-market-search -w`
and sends it as the `x-api-key` header. Notes for the s3 SAM-adapter rebuild
(IMPROVE-s3-3): (1) the first `security` read may raise a one-time "Always
Allow" keychain prompt — the item was created via the Keychain Access GUI, not
with the `-A` flag; (2) the weekly LaunchAgent runs in the user session, so the
login keychain is reachable while the operator is logged in; (3) the operator
should regenerate the key on SAM.gov, since this one transited a chat; (4) the
account is on the ~10-requests/day public tier until SAM.gov entity
registration completes (~2–3 weeks) for the ~1,000/day tier. The S2/S3 SAM
adapters were built as fixture-shells while B3 was open — building them for
real is tracked as IMPROVE-s3-3 in FINDINGS.md.
**Status:** ~~OPEN~~ → RESOLVED 2026-05-22.

## B4 — Airtable schema-write access (operator / MCP)
**Blocks:** s2 (Airtable schema) **and s7 (Airtable write & dashboard badge)** —
s7 cannot write an off-market row, and cannot reach `verified`, until the two
`Source` values exist. Confirmed still open at iter 21: a live `get_table_schema`
read of `Source` (`fldiGyXTk6Ybb6J1L`) returns choices `["Overnight Search",
"Manual Submission"]` only.
**Why:** s2 must add the §8.3 `Source` values (`Off-Market — ASL Bolt-on`,
`Off-Market — SBIC`) and the §8.4 fields plus `Gov Entity ID` to base
`appOsvuyy5eK43QTx` / table `tblSmNrHROMLm7vOS`.
**Progress (2026-05-22, iter 4):** the five §8.4 fields were created live via the
Airtable MCP `create_field` tool — `Gov Entity ID`, `SBIC License #`,
`SBIC License Status`, `Gov Data Source`, `Federal Award History $` (field IDs in
`evidence/s2-airtable-schema.md`). **This half of B4 is DONE.** The remaining
half: the `Source` single-select still has only `Overnight Search` /
`Manual Submission`. The MCP `update_field` tool **cannot add `choices` to an
existing single-select**, so the loop cannot create the two off-market `Source`
values itself.
**Fix (remaining):** Biffrey opens base `appOsvuyy5eK43QTx` → table
"Master Deal Pipeline" → the `Source` field — field ID `fldiGyXTk6Ybb6J1L`,
the single-select holding `Overnight Search` / `Manual Submission`, **not** the
separate `Lead Source` field (`fldI1h3qmNI6vc5rr`, broker platforms) which is a
distinct on-market column — and adds two single-select values, matching the em
dash (—, U+2014) and spacing exactly:
  - `Off-Market — ASL Bolt-on`
  - `Off-Market — SBIC`
Once added, the loop un-blocks **both s2 and s7**, the schema preflight passes,
and each can proceed to SELF-TEST/VERIFY.
**Progress (2026-05-22):** Independently re-confirmed the Airtable MCP
`update_field` tool cannot add `choices` to an existing single-select — the
tool rejects an `options.choices` payload at input validation. A live
`get_table_schema` read of `fldiGyXTk6Ybb6J1L` still shows only
`Overnight Search` / `Manual Submission`. Operator chose to add the two values
manually in the Airtable UI; re-verify via `get_table_schema` once added.
**Resolution (2026-05-22):** Operator added both values (they were hidden in
the default view — unhidden via the "hidden fields" panel, then edited). A live
`get_table_schema` read of `fldiGyXTk6Ybb6J1L` confirms the `Source`
single-select now holds four choices — `Overnight Search`, `Manual Submission`,
`Off-Market — ASL Bolt-on`, `Off-Market — SBIC` — with the two new names
verified byte-for-byte against `OFFMARKET_BUILD_PLAN.md` (em dash U+2014, exact
spacing). The five §8.4 fields were already created live in iter 4. s2 and s7
are un-blocked (reset to `not_started`).
**Status:** ~~OPEN~~ → RESOLVED 2026-05-22.

---

_Resolved blockers are struck through and dated; they are not deleted._
