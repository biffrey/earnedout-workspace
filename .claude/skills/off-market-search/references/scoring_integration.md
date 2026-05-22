# Off-Market Scoring Integration

Built by build-loop **stage s6**. This reference defines how each `LeadPacket`
produced by s5 is scored — by invoking the **existing, unmodified**
`prospect-evaluation` skill. There is **no new scoring logic, no new rubric, and
no parallel scorer**: s6 is purely an integration layer that (a) selects the
correct `prospect-evaluation` mode per target class, (b) maps `LeadPacket`
fields onto the inputs the scorer expects, (c) handles the off-market "no
asking price" reality, and (d) captures the score and the `.md` + `.html`
reports.

Implements PRD **§7.5** (score with the existing scorer) and the §13 resolution
decisions: Class 1 is a roll-up add-on for **Applied Development** (NAICS
541930, no size floor, /110 scale); Class 2 is an **SBIC** acquisition (the
license-good-standing gate is the sole hard criterion, the 0–100 score is
informational).

Companion files:
- `references/enrichment.md` — produces the `LeadPacket` input (its §1 schema).
- `.claude/skills/prospect-evaluation/skill.md` — the scorer, invoked **as-is**.
- `config/offmarket_sources.md` — the target-class definitions.
- This stage's output is consumed by s7 (`references/` — Airtable write).

> Markdown-driven, like the adapters / resolver / enrichment: the procedure
> below is executed at runtime by the skill (it invokes another skill, reads
> the generated report, and copies files) — not compiled code.

---

## 1. Stage inputs and outputs

**Input:** the s5 output — a list of `LeadPacket` objects, one per
pre-filter-passing candidate (`prefilter_verdict: pass`). Entities tagged
`existing` by s4, and `needs_operator_review` entities, never reach s6.

**Output:** one `ScoredLead` object per input packet, handed to s7. A
`ScoredLead` is the `LeadPacket` plus the scoring result:

| field | type | source |
|---|---|---|
| `lead_packet` | object | the s5 `LeadPacket`, carried through unchanged |
| `eval_mode` | enum | `rollup_addon` (Class 1) or `sbic` (Class 2) — see §2 |
| `lead_score` | number \| null | extracted from the report header (§5); `null` if scoring failed for this candidate |
| `score_denominator` | enum | `110` (Class 1 add-on) or `100` (Class 2) — see §3 |
| `score_is_informational` | bool | `true` for Class 2 (SBIC), `false` for Class 1 |
| `buybox_gate` | enum | Class 1: `n/a`. Class 2: `pass` / `conditional` / `fail` — the SBIC license-good-standing gate (§4) |
| `report_md_path` | string | `output/reports/{report_slug}/{company-slug}-report.md` |
| `report_html_path` | string | `output/reports/{report_slug}/{company-slug}-report.html` |
| `report_slug` | string | filesystem-safe form of `lead_packet.entity_id` (§5.1) |
| `scoring_notes` | list[string] | how "no asking price" / missing financials / the SBIC gate were handled; carried into the run log and the s7 `Notes` line |

`ScoredLead` adds nothing to the scoring math — it only records what the
unmodified scorer returned plus the bookkeeping s7 needs.

---

## 2. Mode selection — pick the `prospect-evaluation` mode by target class

`prospect-evaluation` already auto-detects roll-up add-on context (its skill.md
rule 11) and SBIC context (rule 13). s6 makes the intended mode **explicit** in
the invocation so detection is never ambiguous, but it must not override the
scorer's own rubric.

- **Class 1 (`target_class: 1`) → `eval_mode: rollup_addon`.** The candidate is
  an ASL / CART / deaf-services company evaluated as an **Applied Development**
  roll-up add-on. NAICS 541930 → the scorer applies **no size floor** (any size
  is worth scoring), the **+10 line-10 bonus**, and the **/110** scale. The
  invocation must name the platform company explicitly: **Applied Development**.
  - **Adjacent firms.** If `lead_packet.keyword_tier == "adjacent"` (a
    spoken-language firm carrying an ASL/CART signal — §13), tell the scorer to
    award the **line-10 bonus at 5, not 10**. This is the only place the
    adjacent flag changes scoring; the rubric itself is untouched.
- **Class 2 (`target_class: 2`) → `eval_mode: sbic`.** The candidate is a
  licensed **SBIC GP / management company**. The scorer runs in SBIC mode
  (rule 13): the **sole gating criterion is an active, good-standing SBIC
  license**; the standard EBITDA / FTE / growth / valuation criteria are
  reported but **non-gating**, and the **0–100 score is informational only**
  (`score_is_informational: true`). The report must carry the closing-condition
  fact: **any change of control of a licensed SBIC requires SBA prior
  approval** — already present on every Class-2 `LeadPacket`; pass it through.

s6 never edits `prospect-evaluation`, `references/buy-box-and-scoring.md`, or
the rubric. If the scorer's auto-detection and the `eval_mode` above ever
disagree, that is a **BLOCKING** defect to log — not something s6 patches over.

---

## 3. Field mapping — `LeadPacket` → `prospect-evaluation` inputs

The scorer expects the same lead data the `overnight-search` skill passes it
(its Step 6). Map each `LeadPacket` field to the scorer input; **a gap stays a
gap** — `null` / `"needs follow-up"` is passed through, never back-filled.

| `prospect-evaluation` input | `LeadPacket` field | notes |
|---|---|---|
| Business name | `business_name` | |
| Industry | `industry` | already names NAICS 541930 / SBIC |
| Location | `location` | city + state |
| Founding year / years in business | `years_in_business`, `formation_date` | usually a B1 gap → passed as missing → scorer marks "insufficient data" |
| Employee count | `employee_count` | often `null` (a gap → passed as missing) |
| Revenue / EBITDA / financials | `revenue_signal`, `federal_award_total` | **signals only** — see §3.1 |
| Asking price | `asking_price` | always `"not for sale — no asking price"` — see §3.2 |
| Direct URL | `website` (+ `provenance_urls`) | `null` if `website_status: none_found` |
| Screenshot path | `screenshot_path` | `null` if no first-party site validated |
| Direct contact | `contact` | owner / SBIC GP principal |
| SBIC license # / status | `sbic_license_no`, `sbic_license_status` | Class 2 only — feeds the §4 gate |
| Enrichment gaps | `enrichment_gaps` | each gap → a ⚠️ "insufficient data" line, never a guess |

### 3.1 Financial signals are not disclosed financials

`revenue_signal` (e.g. `"signal: small (<$5M est., gov-contract revenue)"`) and
`federal_award_total` are **qualitative / partial signals**, not audited P&L
figures. Pass them to the scorer **labelled as signals**, so the scorer applies
its own rule 1 ("never fabricate financials — missing > guessed"): an
undisclosed EBITDA stays blank, the EBITDA-tier line scores 0, and the Buy Box
EBITDA check is ⚠️ "insufficient data". `sbic_gp_economics` (Class 2) is
**informational** — fund vintage / size / strategy — never mapped onto a Buy
Box financial criterion.

### 3.2 "No asking price" → "insufficient data — not awarded", not a failure

Off-market targets are **not for sale**, so there is never an asking price.
This is the expected state, **not an error**:

- The Buy Box check "Asking price ≤ 4× EBITDA" is marked **⚠️ "insufficient
  data"** (`prospect-evaluation` Step 4 — never guess a pass).
- The scoring rubric's **valuation-multiple line** (≤4.0x = 15 pts, etc.)
  scores **0 — "insufficient data — not awarded"**. It is **not** a ❌, the run
  does **not** abort, and the candidate is **not** dropped.
- Record this in `scoring_notes`: `"no asking price (off-market) — valuation
  line not awarded, not a failure"`.

A scorer invocation that *crashes* or *refuses to score* purely because asking
price is absent is a **BLOCKING** defect — the Done-when criterion is that
off-market "no asking price" is handled gracefully.

---

## 4. The SBIC good-standing gate (Class 2 only)

For Class 2, `prospect-evaluation` rule 13 makes the **SBIC license active and
in good standing** the sole hard gate. s6 feeds the gate from the s5
`sbic_license_status` (resolved by the §4 good-standing cross-check, since the
SBIC directory publishes no standing flag):

| `sbic_license_status` | `buybox_gate` | meaning |
|---|---|---|
| `Good Standing` | `pass` | active, no adverse signal |
| `Under Review` / `Unknown` | `conditional` | standing unconfirmed — scored, flagged for operator confirmation |
| `Surrendered` / `Revoked` | `fail` | license lost — still scored (informational), but the gate fails loud in the report |

A `fail` or `conditional` gate does **not** drop the candidate — it is still
scored and still written to the tracker (s7), with the gate state surfaced in
the report and in `scoring_notes`. The 0–100 score remains **informational**
for every Class-2 outcome. Every Class-2 report carries the SBA
prior-approval-of-change-of-control fact.

---

## 5. Capture the score and the reports

Mirrors `overnight-search` Step 6 — off-market and on-market leads land in the
same report layout so s7 and the dashboard treat them identically.

1. **Create the output directory** `output/reports/{report_slug}/` (see §5.1).
   Save the `LeadPacket` as `lead-packet.json` and copy in the screenshot from
   `lead_packet.screenshot_path` if one exists.
2. **Invoke `prospect-evaluation`** (`.claude/skills/prospect-evaluation/skill.md`)
   in **single mode** with the §3-mapped lead data and the §2 `eval_mode`. It
   runs its full workflow: Buy Box screening → 26-field scorecard → lead score
   with per-line math → full deal memo.
3. **Capture both outputs** — `prospect-evaluation` writes
   `{company-slug}-report.md` and `{company-slug}-report.html` to the working
   directory; ensure both land in `output/reports/{report_slug}/`. **Never skip
   the `.html`** — the dashboard links it.
4. **Extract `lead_score`** from the generated report header (the "Lead Score
   XX / 100" or "XX / 110" line). Record `score_denominator` from the same line
   (110 for a Class-1 add-on, 100 for Class 2). If the header and the
   per-line math disagree, that is a scorer-side defect — log it, do not
   silently reconcile.
5. **Assemble the `ScoredLead`** (§1) and hand the list to s7.

### 5.1 `report_slug` — a filesystem-safe directory name

`entity_id` from s4 contains `:` and `|` (e.g. `UEI:ZZTEST00FIX1`,
`NAME:1st source capital|south bend in`), which are not safe directory names.
Derive `report_slug` deterministically: lower-case `entity_id`, replace every
run of non-`[a-z0-9]` characters with a single `-`, trim leading/trailing `-`.
So `UEI:ZZTEST00FIX1` → `uei-zztest00fix1`; `NAME:1st source capital|south bend
in` → `name-1st-source-capital-south-bend-in`. The mapping is stable across
runs (same `entity_id` → same slug), so a re-scored existing entity overwrites
its own report directory rather than spawning a duplicate.

---

## 6. Failure and edge handling

- **The scorer fails on one candidate** (web tool error, malformed input) — set
  that candidate's `lead_score: null`, record the reason in `scoring_notes`,
  and **continue** with the rest. One failed score degrades one lead, not the
  run (mirrors `overnight-search` / s5 error handling).
- **Sparse enrichment** — a candidate that enriched to thin data is **still
  scored**; `prospect-evaluation` handles thin data via its own "insufficient
  data — not awarded" / blank-field rules. Do not skip scoring because the
  packet has gaps.
- **Fail-the-gate Class-1 target** (e.g. industry mismatch slipped past the s5
  pre-filter) — `prospect-evaluation` rule 10 still produces a full scorecard
  and report explaining the rejection; keep it, so the operator sees *why*.
- **Class-2 `fail` gate** — see §4: scored, written, gate state surfaced; never
  silently dropped.
- **Never fabricate to lift a score.** A missing field stays missing; the
  scorer scores what is real. No invented EBITDA, employee count, or
  valuation multiple to clear a Buy Box line.

---

*Built by build-loop stage s6 (IMPLEMENT). Next phase: SELF-TEST — drive this
procedure over the s5 SELF-TEST `LeadPacket`s: confirm a Class-1 (R1) packet
scores via `prospect-evaluation` in `rollup_addon` mode on the /110 scale and a
Class-2 (R2) packet scores in `sbic` mode with `score_is_informational: true`
and a `buybox_gate` derived from `sbic_license_status`; confirm "no asking
price" is handled as "insufficient data — not awarded" (not a failure, not an
abort); confirm `report_slug` is filesystem-safe and both `.md` and `.html`
reports are captured to `output/reports/{report_slug}/`. Record pass/fail per
check in `_ralph_build/TEST_LOG.md`.*
