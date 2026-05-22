# s6 Scoring Integration — SELF-TEST evidence

**iter 18, 2026-05-22** — drove the s6 procedure (`.claude/skills/off-market-search/references/scoring_integration.md`) over the two s5 SELF-TEST `LeadPacket`s (`evidence/s5-selftest.md` C4/C5): the Class-1 fixture **R1** and the Class-2 real SBIC **R2**. Each `LeadPacket` was scored by invoking the **existing, unmodified** `prospect-evaluation` skill in the s6-selected mode; the score and both `.md`+`.html` reports were captured to `output/reports/{report_slug}/`. Seven checks against the `OFFMARKET_BUILD_PLAN.md` s6 `Done-when` criteria.

## Inputs — the two s5 `LeadPacket`s

| id | class | candidate | nature |
|---|---|---|---|
| R1 | 1 | EXAMPLE INTERPRETING FIXTURE LLC (`UEI:ZZTEST00FIX1`) | synthetic build-loop **fixture** — scored from packet data only, no external research |
| R2 | 2 | 1st Source Capital Corporation, South Bend IN (`NAME:1st source capital\|south bend in`) | **real** SBA-licensed SBIC — genuine web research by the scorer |

---

## C1 — Class-1 candidate produces a score + report via the unmodified scorer (§2 `rollup_addon`)

R1 driven through s6 §2 (Class 1 → `eval_mode: rollup_addon`, platform = Applied Development, NAICS 541930, **no size floor**, **/110 scale**, `keyword_tier: core` → full **+10** line-10 bonus). `prospect-evaluation` invoked **as-is** in single mode.

- **Score: 30 / 110** — header line, scorecard field 26, and the per-line breakdown total are all internally consistent (`output/reports/uei-zztest00fix1/example-interpreting-fixture-llc-report.md:29,64,85`).
- Breakdown: Industry match 20/20 + line-10 roll-up bonus 10/10 = 30; the other 8 base rubric lines scored 0 / "insufficient data — not awarded" against the packet's 5 open enrichment gaps. Low score is the **honest** outcome for an unenriched off-market fixture — nothing fabricated to lift it.
- Both reports on disk: `example-interpreting-fixture-llc-report.md` (21.9 KB) + `.html` (32.8 KB), plus `lead-packet.json`. Both reports banner-marked at top + footer as a **build-loop s6 SELF-TEST fixture artifact**.

`/110` scale confirmed, roll-up add-on mode confirmed, unmodified scorer confirmed. **PASS.**

## C2 — Class-2 candidate produces a score + report via the unmodified scorer (§2 `sbic`, §4 gate)

R2 driven through s6 §2 (Class 2 → `eval_mode: sbic`, score informational only) and §4 (gate fed from `sbic_license_status`). `prospect-evaluation` invoked **as-is** in SBIC mode.

- **Score: 30 / 100**, explicitly labelled **"informational only"** in the report header and the SBIC-mode note (`output/reports/name-1st-source-capital-south-bend-in/1st-source-capital-corporation-report.md:21-22,37,44`).
- **SBIC License Gate: ✅ PASS** — derived per s6 §4 from `sbic_license_status: Good Standing` → `buybox_gate: pass` (report line 33). The report states the gate is the **sole hard criterion** and the 0–100 score does not gate the decision.
- Scorer did its own research on the real entity: corroborated 1983 Indiana incorporation and the South Bend location, awarding "Years in business ≥10" = 10. `sbic_gp_economics` was treated as informational fund-level data, never mapped onto an EBITDA/valuation criterion (§3.1) — confirmed at report line 27.
- Both reports on disk: `1st-source-capital-corporation-report.md` (25.0 KB) + `.html` (36.4 KB), plus `lead-packet.json`. Both banner-marked as an s6 SELF-TEST artifact.

`/100` informational score, SBIC mode, gate derived from `sbic_license_status`, unmodified scorer — all confirmed. **PASS.**

## C3 — "no asking price" handled as "insufficient data — not awarded", not a failure (§3.2)

Both candidates carry `asking_price: "not for sale — no asking price"`. In **both** reports the scorer ran to completion — no crash, no abort, candidate not dropped:

- **R1:** Buy Box line 5 (Asking price ≤ 4× EBITDA) → ⚠️ "insufficient data" (not ❌); valuation-multiple rubric line → **0 / "insufficient data — not awarded"** (report line 31 explicitly: "does **not** abort the evaluation").
- **R2:** Buy Box line 5 → ⚠️ "Off-market target — not for sale… the expected state… **not an error**… not a ❌" (report line 30); valuation rubric line → 0 "insufficient data — not awarded".

A scorer invocation that crashed/refused purely on absent asking price would be the s6 §3.2 BLOCKING defect — **neither run hit it.** **PASS.**

## C4 — `report_slug` is filesystem-safe and deterministic (§5.1)

§5.1 derivation (lowercase `entity_id`, non-`[a-z0-9]` runs → single `-`, trim) verified against the on-disk directory names:

- `UEI:ZZTEST00FIX1` → `uei-zztest00fix1` ✓ (dir exists)
- `NAME:1st source capital|south bend in` → `name-1st-source-capital-south-bend-in` ✓ (dir exists)

Both slugs contain only `[a-z0-9-]` — the `:` and `|` from `entity_id` are gone; both are valid directory names and were created without error. Deterministic → a re-score overwrites its own dir, no duplicate. **PASS.**

## C5 — both `.md` and `.html` reports captured to `output/reports/{report_slug}/` (§5)

`ls` of both report directories confirms, for each candidate: `{company-slug}-report.md`, `{company-slug}-report.html`, and `lead-packet.json` (the s5 packet captured as JSON, §5 step 1). The `.html` — which the dashboard links — was **not** skipped in either case. **PASS.**

## C6 — no fabrication; every gap stays a gap

Both reports score every undisclosed field as "insufficient data — not awarded" rather than guessing: R1 — EBITDA, founding date, growth, recurring revenue, employees, concentration all 0/insufficient (the `revenue_signal` and `$480K` award total were explicitly *not* fabricated into an EBITDA tier — report line 75). R2 — standalone GP P&L, FTE, growth, concentration all ⚠️ insufficient; `sbic_gp_economics` kept informational. No invented financials, contacts, dates, or URLs in either report. **PASS.**

## C7 — Class-2 report carries the SBA prior-approval change-of-control fact

R2's report has a dedicated section **"⚠️ SBIC Closing Condition — SBA Prior Approval of Change of Control"** (`1st-source-capital-corporation-report.md:50-52`): "Acquiring a licensed SBIC requires SBA prior approval of the change of control… mandatory regulatory closing condition… (13 CFR Part 107)." The fact also appears in the Risk Factors section. Carried through from the s5 Class-2 `LeadPacket` as required by s6 §2/§4. **PASS.**

---

## Result

All **7** SELF-TEST checks PASS. A Class-1 (R1, `rollup_addon`, /110) and a Class-2 (R2, `sbic`, /100 informational) candidate each produced a score and both report formats via the **unmodified** `prospect-evaluation` skill; the off-market "no asking price" reality was handled as "insufficient data — not awarded" in both runs without a crash, abort, or drop; `report_slug` is filesystem-safe and deterministic; no value was fabricated; the SBIC SBA-prior-approval fact is carried on the Class-2 report. **No BLOCKING defect.**

**Carry-notes to the VERIFY critic** (not Done-when failures):

1. **R1 is a fixture.** The genuine Class-1 *end-to-end* score on a **real** ASL/CART company is deferred to s10's larger live sample — this is the same chain noted by the s4/s5 critics (IMPROVE-s3-1: the S1 USAspending adapter does not populate `uei`, so real S1 records route to `needs_operator_review` until that closes; IMPROVE-s4-4 gates s10's real-data sample on it). The s6 SELF-TEST exercised the integration plumbing fully on the fixture; R1's 30/110 is an honest plumbing artifact, not a real-company assessment.
2. **Pre-existing `prospect-evaluation` inconsistency (not an s6 defect).** The on-disk `prospect-evaluation` resources state the EBITDA Buy Box band as "$1M–$4M" while the skill front-matter / behavioral-rule text say "$1M or more (no upper ceiling)". This lives entirely inside the *unmodified* `prospect-evaluation` skill and did not affect either run (EBITDA undisclosed → insufficient data either way). Flagged for the owner of that skill; out of scope for the off-market build loop.

Stage s6 → `self_checked`. Next phase: VERIFY (fresh-context critic).
