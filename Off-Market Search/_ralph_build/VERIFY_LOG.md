# Off-Market Build Loop — Verify Log

One entry per VERIFY phase (per-stage critic subagent) and for the FINAL AUDIT
(independent auditor subagent): date, iteration, stage, verdict, and findings
classified `BLOCKING` / `IMPROVE` / `NIT`.

## iter 3 — 2026-05-22 — s1 (Foundations & config) — VERIFY

Fresh-context critic subagent inspected the actual s1 deliverables on disk
(`.claude/skills/off-market-search/skill.md`, `config/offmarket_sources.md`)
and cross-checked codes/endpoints against the §13 resolution doc. Not given the
loop's logs or reasoning.

**Verdict: PASS (0 BLOCKING).**

All four Done-when criteria met:
- C1 — skill scaffold + `skill.md` with valid `name`/`description` frontmatter
  and the §9.1 nine-step outline in the exact specified order. PASS.
- C2 — `config/offmarket_sources.md` lists all 11 sources (S1–S11) each with a
  verified access method, endpoint, rate-limit/ToS. PASS.
- C3 — no `⚠ VERIFY:` placeholders remain (the single grep hit is the
  self-referential negation sentence at config line 7). PASS.
- C4 — verified codes correct: NAICS 541930 (CONFIRMED, includes sign
  language), PSC R608 (CONFIRMED, low-confidence flag cleared), GSA MAS SIN
  541930 — all consistent with the §13 resolution doc. PASS.

Hard constraints honored: SKELETON marking present; source layer documented
swappable; FPDS-NG explicitly excluded with SAM.gov Contract Awards API named
as successor and USAspending.gov as primary; Class-1/Class-2 keyword lists +
B2 default present; entity-identifier priority order documented; no fabricated
codes/endpoints.

Findings (non-blocking, filed in `FINDINGS.md`):
- F1 IMPROVE — `offmarket_sources.md` lines 10–12 use a non-standard `/ … /`
  comment delimiter that renders literally in Markdown.
- F2 NIT — config line 7's literal `⚠ VERIFY:` string inside a negation
  sentence could trip a future automated placeholder scan.

Stage s1 → `verified`. `unresolved_findings` → 2.

## iter 7 — 2026-05-22 — s3 (Source adapters) — VERIFY

Fresh-context critic subagent independently inspected the actual s3 artifacts
on disk — `.claude/skills/off-market-search/references/source_adapters.md`,
`skill.md` Step 2, `config/offmarket_sources.md`, and the four
`evidence/s3-fixtures/*.json` recordings — against the s3 `Done-when` criteria
and the build-plan constraints. Not given the loop's logs or reasoning.

**Verdict: PASS (0 BLOCKING).**

All three Done-when criteria met:
- Common interface — `source_adapters.md` §1 defines a single
  `adapter.query(target_class, params)` contract returning
  `{records:[RawRecord], meta:AdapterMeta}`; `RawRecord` (23 fields) and
  `AdapterMeta` (6 fields) are concretely specified. PASS.
- All named sources covered behind that interface — 11 adapters S1–S11; the §3
  registry table makes swap a one-line change. PASS.
- Each adapter returns normalized records from a live or recorded-fixture
  query — S1/S4 live recordings, S2/S3 structural fixtures (honestly labeled,
  placeholder UEIs, write-guard documented), all map cleanly to `RawRecord`.
  PASS.
- Rate limits / ToS documented per source S1–S11. PASS.

Hard constraints honored: no `fpds.gov` (SAM Contract Awards API used instead);
RID no-bulk-copy enforced in code (`status: n/a` without a name); SBA
prior-approval government fact on every Class-2 record (confirmed in the S4
fixture mapping); blocked adapters S2/S3 (B3) and S8 (B1) degrade gracefully —
not faked PASSes; unknown fields → `null`, never fabricated.

Findings (non-blocking, filed in `FINDINGS.md`):
- NIT-s3-1 — `source_adapters.md:174` cites CSV column `"Managed by"`; the live
  SBIC CSV header is `Manager`.
- IMPROVE-s3-1 — S1 `uei` (primary s4 resolution key) is not returned by
  `spending_by_award`; the adapter needs a recipient-detail follow-up call.

Stage s3 → `verified`. `unresolved_findings` → 4.

## iter 10 — 2026-05-22 — s4 (Entity resolution & de-duplication) — VERIFY

Fresh-context critic subagent independently inspected the actual s4 artifacts on
disk — `.claude/skills/off-market-search/references/entity_resolution.md`,
`skill.md` Step 3/4, `references/source_adapters.md`, `evidence/s4-selftest.md`,
the `evidence/s3-fixtures/*.json` recordings — and independently sanity-checked
the live `tblSmNrHROMLm7vOS` schema via the Airtable MCP (read-only). Not given
the loop's logs or reasoning.

**Verdict: PASS (0 BLOCKING).**

All three Done-when criteria met:
- C1 — distinct gov records collapse to one candidate. The §6.1 UEI→CAGE→DUNS→
  name+address ladder is fully specified; S2/S3 fixtures genuinely both carry
  `uei ZZTEST00FIX1` and merge to one `CanonicalEntity` (2→1, real not faked).
  PASS.
- C2 — an `existing` candidate is updated, not duplicated. §3 defines all three
  dedup keys (A gov-id / B name+address / C SBIC license), the `existing`
  verdict, `tracker_record_id`, and the fill-blanks update path; the self-test
  exercises each key. PASS.
- C3 — resolution accuracy spot-checked toward ≥95%. §6 mandates the check;
  self-test records 4/4 correct (100%), 0% duplicate rate, and honestly defers a
  larger live sample to s10. PASS.

Honesty/constraints honored: seeded `existing` rows SR-A/B/C are explicitly
in-memory only — no production write occurred (critic confirmed 0/167 live rows
carry `Gov Entity ID`/`SBIC License #`); S1 thin records route to
`needs_operator_review`, not fabricated; fail-loud on tracker-read failure;
DUNS as legacy bridge only; same base/table — no parallel tracker; `RawRecord`
field names match `source_adapters.md` exactly.

Findings (non-blocking, filed in `FINDINGS.md`):
- IMPROVE-s4-1 — `entity_resolution.md:36` `dedup_verdict` enum omits the
  `needs_operator_review` state used in §4.
- IMPROVE-s4-2 — `entity_resolution.md:89/101` DUNS step is a non-obvious
  exception to "first match wins"; state it explicitly.
- IMPROVE-s4-3 — `evidence/s4-selftest.md:28-29` asserts R1's merged
  `naics`/`psc`/`award_total` without showing the per-field union trace.
- IMPROVE-s4-4 — `evidence/s4-selftest.md:42-43` until IMPROVE-s3-1 closes,
  every S1 record routes to `needs_operator_review`, so the accuracy spot-check
  never exercises real S1 data; gate s10's larger sample on IMPROVE-s3-1.
- NIT-s4-1 — `entity_resolution.md:206` example `entity_id` `SBIC:09/79-0292`
  embeds a slash; harmless in a text field but mildly fragile.

Stage s4 → `verified`. `unresolved_findings` → 9.

## iter 13 — 2026-05-22 — s5 (Enrichment & qualification pre-filters) — VERIFY

Fresh-context critic subagent independently inspected the actual s5 artifacts on
disk — `.claude/skills/off-market-search/references/enrichment.md`, `skill.md`
enrichment/pre-filter steps, `references/airtable_schema_preflight.md`,
`config/offmarket_sources.md`, `references/source_adapters.md`,
`references/entity_resolution.md`, `evidence/s5-selftest.md` — and cross-checked
the §3/§7/§11 PRD requirements and the §13 resolution doc. Not given the loop's
logs or reasoning. The critic also cross-checked the live `Gov Data Source`
choice set against `evidence/s2-airtable-schema.md`.

**Verdict: FAIL (1 BLOCKING).**

The s5 spec is largely sound — the §7.4 pre-filters are specified to run before
enrichment, the SBIC good-standing cross-check goes beyond the directory, the
"never fabricate" rule is honored, no new scorer is introduced, and the
SBA-prior-approval change-of-control fact is carried on every Class-2 packet
(`enrichment.md:187-189`). One Done-when / hard-constraint violation blocks it:

- **BLOCKING-s5-1** — `LeadPacket.gov_data_source` points at a non-existent
  mapping table and the self-test emits an **invalid Airtable choice**.
  `enrichment.md:64` and `:231` say `source_ids` are "mapped to the
  `Gov Data Source` Airtable choice (per `airtable_schema_preflight.md`)", but
  that file contains no `source_id → choice` mapping table. `s5-selftest.md:97`
  then emits `["SAM.gov Entity Management", "SAM.gov Contract Awards"]` — but
  `"SAM.gov Entity Management"` is not one of the eight live `Gov Data Source`
  choices (`evidence/s2-airtable-schema.md:15`: USAspending / SAM.gov / SAM.gov
  Contract Awards / SBA SBIC / SBS / GSA eLibrary / State / RID). The correct S2
  value is `SAM.gov`. Because multi-select choices auto-grow on write
  (`s2-airtable-schema.md:23`), writing the wrong string would silently create a
  spurious 9th choice — violating the "fail loud, never silently create"
  invariant and breaking field-value consistency with the s7 Airtable write.

Findings filed in `FINDINGS.md`: BLOCKING-s5-1 (above), IMPROVE-s5-1 (screenshot
path not filesystem-safe for `entity_id`s containing `:`/`|`/spaces),
IMPROVE-s5-2 (Class-2 pre-filter §2.2 condition 2 is a no-op on a first run —
state that plainly), IMPROVE-s5-3 (good-standing cross-check demonstrated for
only one Class-2 entity — s10 must repeat across all), NIT-s5-1
(`s4-selftest.md:29` provenance note cites the wrong source record), NIT-s5-2
(`enrichment.md:53` `employee_count` typed `number | string`, inconsistent with
the `... | null` unknown-able fields).

Stage s5 → `not_started` (BLOCKING → return to IMPLEMENT). `unresolved_findings`
→ 15.

## iter 16 — 2026-05-22 — s5 (Enrichment & qualification pre-filters) — VERIFY (re-run)

Fresh-context critic subagent independently re-inspected the actual s5 artifacts
on disk after the iter-14 re-IMPLEMENT and iter-15 re-SELF-TEST —
`.claude/skills/off-market-search/references/enrichment.md`, `skill.md`,
`references/airtable_schema_preflight.md`, `references/source_adapters.md`,
`references/entity_resolution.md`, `evidence/s5-selftest.md`,
`evidence/s2-airtable-schema.md`, `config/offmarket_sources.md` — cross-checked
the §3/§7/§11 PRD + §13 resolution doc, and independently queried the **live
Airtable `Gov Data Source` field** (`fldM7KoR2gtfvBVWN`) to confirm its eight
choices. Not given the loop's logs or reasoning. Tasked specifically with
disproving that BLOCKING-s5-1 is resolved.

**Verdict: PASS (0 BLOCKING).**

BLOCKING-s5-1 confirmed genuinely fixed:
- `enrichment.md` §5.1 (lines 240-264) is a real `source_id → Gov Data Source`
  mapping table; every right-hand value is a member of the live eight-choice set
  (critic queried the live field: USAspending / SAM.gov / SAM.gov Contract
  Awards / SBA SBIC / SBS / GSA eLibrary / State / RID). S10/S11 correctly
  excluded as enrichment-only.
- The fail-loud rule (`enrichment.md:266-273`) concretely halts the skill on an
  unmapped `source_id` with a schema-preflight-style operator message; the
  multi-select is never auto-grown. Exercised by self-test C7 step 5 (`S99`).
- The iter-13 offender `"SAM.gov Entity Management"` now appears only as an
  adapter-name *description* (mapping S2 → choice `SAM.gov`) and in an explicit
  negative in the self-test — never as an emitted `gov_data_source` value.

All three Done-when criteria met: complete lead packet (C4/C5, zero
fabrication); pre-filters run first and drop non-fits before any enrichment
(C2); SBIC standing cross-referenced beyond the directory via SBA OIG / press
releases / federal court records / IAPD, no directory flag (C6). Hard
constraints honored: never fabricate, fail loud, no new scorer, no parallel
tracker, SBA prior-approval change-of-control fact on every Class-2 packet.

Findings (non-blocking, filed in `FINDINGS.md`):
- IMPROVE-s5-4 (new) — `s5-selftest.md:174`/`:177` C7 cites stale line numbers
  (97/125) for the `gov_data_source` rows; after the iter-15 rewrite they are at
  lines 104/132.
- IMPROVE-s5-1, IMPROVE-s5-2, NIT-s5-2 — carried open from iter 13 (still valid).

Stage s5 → `verified`. `unresolved_findings` → 15.

## iter 19 — 2026-05-22 — s6 (Scoring integration) — VERIFY

Fresh-context critic subagent independently inspected the actual s6 artifacts on
disk — `.claude/skills/off-market-search/references/scoring_integration.md`,
`skill.md` Step 5, `evidence/s6-selftest.md`, the two captured report
directories `output/reports/uei-zztest00fix1/` and
`output/reports/name-1st-source-capital-south-bend-in/` (opened the `.md` + `.html`
reports, checked header/scorecard/breakdown score consistency) — and independently
confirmed via `git status` / `git log` that `.claude/skills/prospect-evaluation/`
is unmodified by the build. Not given the loop's logs or reasoning.

**Verdict: PASS (0 BLOCKING).**

Both Done-when criteria met:
- DW1 — a Class-1 and a Class-2 candidate each produce a score + report via the
  UNMODIFIED `prospect-evaluation` skill. PASS. R1 → 30/110 (header line 29,
  scorecard field 26, breakdown total line 85 — all agree), `.md`+`.html` on
  disk under `output/reports/uei-zztest00fix1/`. R2 → 30/100 informational
  (header line 37, scorecard line 85, breakdown line 104), `.md`+`.html` on
  disk. `prospect-evaluation/` git-clean, no build-era commits — used verbatim.
- DW2 — "no asking price" handled as "insufficient data — not awarded", not a
  failure. PASS. Buy Box line 5 → ⚠️ (not ❌); valuation rubric line →
  `0 / "insufficient data — not awarded"`; neither run crashed/aborted/dropped
  the candidate.

Hard constraints honored: no new scorer (mode selection driven by target class —
`scoring_integration.md` §2 maps class 1→`rollup_addon` /110 no size floor,
class 2→`sbic` good-standing gate informational); no fabrication (every
undisclosed field "insufficient data", `$480K` award total not converted to
EBITDA, R2 contact carried verbatim from the s5 lead packet); SBA prior-approval
change-of-control fact carried on the Class-2 report (dedicated section, Risk
Factors, 13 CFR Part 107); `report_slug` filesystem-safe and deterministic.

Findings (non-blocking, filed in `FINDINGS.md`):
- IMPROVE-s6-1 — `scoring_integration.md:20` / `skill.md:43` / build-plan:229
  cite `prospect-evaluation/references/buy-box-and-scoring.md`, which does not
  exist; the rubric lives inside `prospect-evaluation/skill.md`.
- IMPROVE-s6-2 — both scored candidates are build-loop test inputs (R1 a
  synthetic fixture); a genuine real-company Class-1 score is deferred to s10.
- NIT-s6-1 — `s6-selftest.md:18` cites a stale R1 score line (70, actually 85).
- NIT-s6-2 — `prospect-evaluation/skill.md` has owner-only file mode (cosmetic,
  pre-existing).

Stage s6 → `verified`. `unresolved_findings` → 19.

## iter 24 — 2026-05-22 — s8 (Outreach drafting) — VERIFY

Fresh-context critic subagent independently inspected the s8 deliverables on
disk — `config/offmarket_outreach_template.md`, `references/outreach_drafting.md`,
the broker `config/outreach_templates.md`, and the two s8 evidence files — plus
git history. Not given the loop's logs or reasoning. Tasked to disprove that s8
is done.

**Verdict: PASS (0 BLOCKING).**

Done-when criteria, all MET:
- DW1 — a draft is generated for a candidate with a direct contact. PASS. Two
  drafts in `s8-offmarket_outreach_drafts_2026-05-22.md`: a Class-1 OM-1 draft
  (EXAMPLE INTERPRETING FIXTURE LLC, partial contact — name, no email) and a
  Class-2 OM-2 draft (1st Source Capital Corporation, full contact). No raw
  `[...]` placeholder survives in either block. The no-contact case (SYN-NC1)
  correctly yields no draft and fabricates no contact.
- DW2 — nothing is auto-sent. PASS. Independent grep across both s8 deliverables
  for `send|gmail|smtp|mailto|transport|sendmail` — every hit is a prohibition
  or the literal NOT-SENT marker. No send code path. Both stored drafts carry
  the `--- OFF-MARKET OUTREACH DRAFT (NOT SENT) ---` / `--- END DRAFT (review
  and send manually) ---` markers.
- DW3 — broker templates untouched. PASS. `git log --all -- config/
  outreach_templates.md` shows last touch at `323a782` (on-market revamp loop) —
  no `offmarket-build` commit modifies it; working tree clean. s8 added a new
  sibling file, `config/offmarket_outreach_template.md`.

Invariants honored: no fabrication (no-contact → skip, partial contact → missing
email surfaced as `needs follow-up`); SBA prior-approval change-of-control
sentence is fixed body text in OM-2 and appears verbatim in the Class-2 draft;
the off-market template is dedicated and distinct from the broker templates
(addresses owner / SBIC GP principal, business not for sale, no NDA/CIM
language).

Findings (non-blocking, filed in `FINDINGS.md`):
- IMPROVE-s8-1 — OM-2 body addresses the recipient "as a principal" but the
  contact gate accepts any direct contact; R2's only enriched contact was titled
  "Investor Relations". Prefer a principal-titled contact or soften the body.
- NIT-s8-1 — stray trailing `</content>` / `</invoke>` tokens leaked into the
  two s8 evidence files.

Stage s8 → `verified`. `unresolved_findings` 19 → 21.

## iter 27 — 2026-05-22 — s9 (Orchestration & cadence) — VERIFY

Fresh-context critic subagent independently inspected the actual s9 artifacts on
disk — `.claude/skills/off-market-search/skill.md`,
`references/orchestration.md`, the seven other stage reference files,
`run-offmarket-search.sh`, `config/offmarket_schedule.md`,
`config/launchd/ai.earnedout.offmarket-search.plist`, and
`evidence/s9-offmarket_run_log_dryrun.md` — ran `bash -n` and `plutil -lint`
itself, and independently checked live cron state (`CronList`, `launchctl`,
`~/Library/LaunchAgents`). Not given the loop's logs or reasoning. Tasked to
disprove that s9 is done.

**Verdict: PASS (0 BLOCKING).**

All three Done-when criteria met:
- DW1 — full pipeline wired end-to-end. `skill.md` Steps 1–9 in fixed order;
  the `orchestration.md` §1 hand-off table chains type-consistently at every
  boundary, confirmed against the actual `source_adapters.md` /
  `entity_resolution.md` / `enrichment.md` / `scoring_integration.md` /
  `airtable_write.md` types, not the table's own claims. PASS.
- DW2 — manual single-entity path specified end-to-end (`orchestration.md` §4,
  `skill.md:193-205`): input forms, Step-2 skip with direct resolution seeding,
  Steps 3–9 unchanged, dated-section run-log append, operator report. Mirrors
  `submit-url`. PASS.
- DW3 — weekly cadence defined and version-controlled: `config/
  offmarket_schedule.md`, `run-offmarket-search.sh` (`bash -n` clean,
  executable), plist (`plutil -lint` OK, `Weekday=1 Hour=6` = Monday 06:00).
  Live `/schedule` registration honestly gated on B4 and documented as the
  post-B4 install step — correct per the build-loop rule (a blocked precondition
  does not block a stage whose own deliverable is complete). PASS.

Hard constraints honored: no parallel tracker / no new scorer (only
`appOsvuyy5eK43QTx`/`tblSmNrHROMLm7vOS` and `prospect-evaluation`); fail-loud
halts (Step 1 preflight, Step 3 tracker read); no fabrication, no auto-send
(grep for `send/smtp/gmail/mailto` finds only prohibitions); degraded run still
completes + logs; s9 adds no new pipeline logic — glue only, all seven s2–s8
references present on disk.

Findings (non-blocking, filed in `FINDINGS.md`):
- NIT-s9-1 — `orchestration.md:26` §1 table tags Step 3 output
  `new / existing / needs_operator_review`, but `entity_resolution.md:61` types
  `dedup_verdict` as only `new | existing`; cosmetic, does not break the
  hand-off.
- NIT-s9-2 — `evidence/s9-offmarket_run_log_dryrun.md` "Sources queried" table
  omits the enrichment-only sources S5/S6/S7; a live run should list every
  source attempted.

Stage s9 → `verified`. `unresolved_findings` 21 → 23.
