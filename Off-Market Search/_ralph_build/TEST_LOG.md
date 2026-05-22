# Off-Market Build Loop — Self-Test Log

One entry per SELF-TEST phase: date, iteration, stage, and pass/fail per check
against the stage's `Done-when` criteria in `OFFMARKET_BUILD_PLAN.md`.

## iter 2 — 2026-05-22 — s1 (Foundations & config) — SELF-TEST

Exercised the s1 deliverables against the `OFFMARKET_BUILD_PLAN.md` s1
`Done-when` criteria. Five checks:

- **C1 — no `⚠ VERIFY:` placeholders remain.** PASS. `grep` over
  `config/offmarket_sources.md` and `.claude/skills/off-market-search/skill.md`
  returns exactly one hit — line 7 of the config, the descriptive sentence "No
  `⚠ VERIFY:` placeholders remain" — which is self-referential prose, not a
  placeholder. Zero actual unresolved placeholders.
- **C2 — skill scaffold exists with valid frontmatter.** PASS.
  `.claude/skills/off-market-search/skill.md` exists; YAML frontmatter parses
  (`name: off-market-search`, full `description`); delimited by `---`.
- **C3 — §9.1 nine-step outline present.** PASS. Nine `## Step N` headings
  (1–9) plus `## Manual single-entity path`, `## Cadence`, and
  `## Constraints (invariant)`. Each step annotated with its completing stage.
- **C4 — config lists every source with its verified access method.** PASS.
  11 source headings (S1–S11); each documents how it is accessed and a
  `Status:` line. NIT: S5 (good-standing cross-check) and S11 (U.S. Courts)
  describe their access method in prose rather than under the uniform
  `**Access:**` label the other 9 sources use — access is documented, label is
  inconsistent. Recorded for the VERIFY critic; not a Done-when failure.
- **C5 — verified codes present.** PASS. NAICS `541930` and PSC `R608` both
  present and marked CONFIRMED; PSC "low confidence" flag explicitly cleared.

**Result: all five checks PASS.** Stage s1 → `self_checked`. One NIT (C4 label
inconsistency) carried for the critic. Next phase for s1: VERIFY.

## iter 6 — 2026-05-22 — s3 (Source adapters) — SELF-TEST

Exercised the s3 adapters against live endpoints and recorded fixtures; verified
each returns a normalized `RawRecord`. Full evidence (queries + normalized
output) in `evidence/s3-selftest.md`; fixtures in `evidence/s3-fixtures/`.
Seven checks against the `OFFMARKET_BUILD_PLAN.md` s3 `Done-when` criteria:

- **C1 — S1 returns normalized records from a LIVE query.** PASS. Live
  `POST api.usaspending.gov/api/v2/search/spending_by_award/` with NAICS
  `541930` → HTTP 200, 5 real recipient rows; mapped to `RawRecord`s.
- **C2 — verified codes resolve live.** PASS. `541930` active (not retired),
  `R608` resolves — both via the USAspending autocomplete endpoints.
- **C3 — S4 returns normalized records from a LIVE query.** PASS. Live SBIC
  directory CSV download → 13-column CSV, real licensees; mapped to Class-2
  `RawRecord`s with the SBA-prior-approval government fact attached.
- **C4 — blocked adapters S2/S3 run in fixture mode and normalize.** PASS.
  `evidence/s3-fixtures/S2.json` and `S3.json` map cleanly through the S2/S3
  normalization with `meta.status:"blocked", blocker_id:"B3", notes:"fixture"`.
- **C5 — blocked adapter S8 degrades gracefully.** PASS. Returns `records:[]`,
  `meta.status:"blocked", blocker_id:"B1"` — does not halt the run (shell only).
- **C6 — source layer abstracted (common interface).** PASS. All 11 adapters
  share the single `adapter.query(target_class, params)` signature and the
  `RawRecord` / `AdapterMeta` shapes; downstream stages never see source type.
- **C7 — rate limits & ToS documented per source.** PASS. Each S1–S11 section
  carries an explicit Rate/ToS line (USAspending ~1 req/s + bulk download; SAM
  10-vs-1000/day per B3; SBIC single CSV/run; RID no-bulk-copy guard; etc.).

**Result: all seven checks PASS.** Stage s3 → `self_checked`. Two findings
carried to the VERIFY critic (not Done-when failures): **NIT-s3-1** — S4 prose
cites column `"Managed by"` but the live CSV header is `Manager`;
**IMPROVE-s3-1** — S1 needs a recipient-detail follow-up call to populate `uei`
(not returned by `spending_by_award`). Next phase for s3: VERIFY.

## iter 9 — 2026-05-22 — s4 (Entity resolution & de-duplication) — SELF-TEST

Hand-executed the §6.1 resolver and §6.2 tracker dedup procedures from
`references/entity_resolution.md` over the combined s3 fixture record set (8
`RawRecord`s from `evidence/s3-fixtures/`) and a live 167-record read of
`tblSmNrHROMLm7vOS`. Full evidence — clusters, verdicts, indexes, seeded-row
scenarios, accuracy spot-check — in `evidence/s4-selftest.md`. Seven checks
against the `OFFMARKET_BUILD_PLAN.md` s4 `Done-when` criteria:

- **C1 — multi-source records collapse to one entity.** PASS. The S2 and S3
  fixtures both carry `uei ZZTEST00FIX1`; §6.1 key 1 (UEI) merges them into a
  single `CanonicalEntity`, `resolution_confidence: exact` — 2 records → 1.
- **C2 — distinct firms stay distinct.** PASS. The 3 S4 SBIC records have
  distinct `norm_name` + `norm_addr`; §6.1 key 4 produces 3 separate
  `probable` entities — no false merge on name.
- **C3 — thin-record handling, no fabrication.** PASS. The 3 S1 records carry
  no identifier and no address; §4 routes them to `needs_operator_review` —
  not invented into rows, not silently dropped. (Live-run consequence of the
  already-filed IMPROVE-s3-1; s4 handles the thin input correctly.)
- **C4 — dedup against the live tracker.** PASS. 167-record live read; 0 rows
  have `Gov Entity ID` or `SBIC License #`, and no name+address collision
  (incl. the on-market ASL row `recFbcG0NPtQ3toQY`) → all 4 entities resolve
  `new`. No false `existing`.
- **C5 — `existing` is detected, update not duplicate.** PASS. Three in-memory
  seeded synthetic tracker rows trigger key A (gov id), key B (name+address),
  and key C (SBIC license) respectively → `dedup_verdict: existing` with the
  correct `dedup_key` + `tracker_record_id`, routed to s7 as an update.
- **C6 — `entity_id` construction (§5).** PASS. `UEI:` / `NAME:<norm_name>|
  <citystate>` / `SBIC:` prefixes are deterministic and stable across runs.
- **C7 — accuracy spot-check vs. §2.2.** PASS (small-sample). 4/4 cluster
  decisions correct = 100% (≥95% target); 0% sampled duplicate rate (<5%
  target). Caveat recorded: sample is small and S2/S3 are structural fixtures
  — s10 must repeat on a larger live sample once B3 clears.

**Result: all seven checks PASS.** Stage s4 → `self_checked`. No new findings;
one carry-note to the VERIFY critic — the live-run interaction with the open
IMPROVE-s3-1 (S1 records route to `needs_operator_review` until the s3
adapter populates `uei`). Next phase for s4: VERIFY.

## iter 12 — 2026-05-22 — s5 (Enrichment & qualification pre-filters) — SELF-TEST

Hand-executed the §7.4 pre-filters, the §3 enrichment steps, the §4 SBIC
good-standing cross-check, and the §5 `LeadPacket` assembly from
`references/enrichment.md` over the s4 output (4 `CanonicalEntity`, all
`dedup_verdict: new`). Full evidence — pre-filter verdicts, both assembled
`LeadPacket`s, the live good-standing cross-check — in `evidence/s5-selftest.md`.
Six checks against the `OFFMARKET_BUILD_PLAN.md` s5 `Done-when` criteria:

- **C1 — Class-1 pre-filter passes a genuine fit.** PASS. R1 (EXAMPLE
  INTERPRETING FIXTURE LLC) carries core keyword hit `interpreting` (§5.2 core
  list) and is a U.S. operating company (SAM `Active`) → §2.1 both conditions
  hold → `pass`, tier `core`.
- **C2 — an obvious non-fit is dropped BEFORE enrichment.** PASS. Synthetic
  in-memory SYN-NF1 (document-translation firm, exclusion-only keyword hits,
  no ASL/CART line) → `drop` at the §2.1 pre-filter — no website discovery,
  no SOS, no Playwright, no scoring ran. SYN-ADJ1 (carries `VRI`) correctly
  kept as `adjacent`, not dropped.
- **C3 — Class-2 pre-filter passes current licensees.** PASS. R2/R3/R4 all
  appear on the current SBIC-directory CSV live-recording and have no
  disproven standing → all 3 `pass`.
- **C4 — Class-1 `LeadPacket` complete, no fabrication.** PASS. R1 packet has
  every §1 field populated or explicitly gapped; 5 `enrichment_gaps` logged
  (website, formation date, employee count, contact email/phone); zero
  invented values — the `.invalid` entityURL correctly yields
  `website_status: none_found`, not a substituted URL.
- **C5 — Class-2 `LeadPacket` complete.** PASS. R2 (1st Source Capital
  Corporation) packet complete; `sbic_license_no` left `null` (directory
  publishes none — a gap, not fabricated); directory POC correctly flagged as
  investor-relations not the GP principal; SBA-prior-approval fact carried.
- **C6 — SBIC good-standing cross-check resolves a status beyond the
  directory.** PASS. Live `WebSearch` for 1st Source Capital enforcement /
  revocation / surrender → no adverse action; the same search surfaced a real
  Federal Register surrender notice for a different firm (High Street Capital
  IV SBIC) proving the §4 adverse-signal source is real and queryable.
  Resolved R2 → `Good Standing` with **no** directory standing flag used.

**Result: all six checks PASS.** Stage s5 → `self_checked`. No new findings;
one carry-note to the VERIFY critic — B1 (priority-state list) being OPEN makes
`formation_date` / `years_in_business` / `sos_status` a universal gap on every
off-market `LeadPacket` until B1 clears (the §3.2 B1-gated skip is exercised
and behaves as designed). Next phase for s5: VERIFY.

## iter 15 — 2026-05-22 — s5 (Enrichment & qualification pre-filters) — SELF-TEST (re-run)

Re-ran the s5 SELF-TEST after the iter-14 re-IMPLEMENT that resolved
BLOCKING-s5-1 (added `enrichment.md` §5.1, the `source_id → Gov Data Source`
mapping table + fail-loud rule, and corrected the choice strings in
`evidence/s5-selftest.md`). Hand-executed the §7.4 pre-filters, the §3
enrichment steps, the §4 SBIC good-standing cross-check, and the §5/§5.1
`LeadPacket` assembly over the s4 output (4 `CanonicalEntity`, all
`dedup_verdict: new`). Full evidence in `evidence/s5-selftest.md`.

- **C1–C6** — re-confirmed unchanged. The re-IMPLEMENT touched only §5.1 and
  the §1/§5 `gov_data_source` rows; the §2 pre-filters, §3 enrichment, §4
  good-standing cross-check, and the `LeadPacket` assembly were not modified,
  so the iter-12 verdicts hold: Class-1 pre-filter passes a genuine fit (R1);
  an obvious non-fit (SYN-NF1) is dropped BEFORE enrichment; Class-2 pre-filter
  passes current licensees (R2/R3/R4); the Class-1 and Class-2 `LeadPacket`s
  are complete with zero fabrication; the SBIC good-standing cross-check
  resolves a status without a directory flag. All PASS.
- **C7 (new) — `gov_data_source` §5.1 mapping.** PASS. R1 `source_ids [S2,S3]`
  → `["SAM.gov", "SAM.gov Contract Awards"]`; R2 `source_id [S4]` →
  `["SBA SBIC"]` — every value is one of the eight live `Gov Data Source`
  choices (`evidence/s2-airtable-schema.md:15`). The iter-13 offender
  `"SAM.gov Entity Management"` no longer appears. `S10`/`S11` are
  enrichment-only and contribute no choice. The §5.1 fail-loud rule, driven
  with a synthetic unmapped `source_id` `S99`, halts the skill with an operator
  message and never auto-grows the multi-select.

**Result: all 7 checks PASS.** Stage s5 → `self_checked`. No new findings. The
iter-12 carry-note still stands — B1 (priority-state list) OPEN makes
`formation_date` / `years_in_business` / `sos_status` a universal `LeadPacket`
gap until B1 clears (designed B1-gated skip, not a failure). Next phase for s5:
VERIFY (fresh-context critic).

## iter 18 — 2026-05-22 — s6 (Scoring integration) — SELF-TEST

Drove the s6 procedure (`references/scoring_integration.md`) over the two s5
SELF-TEST `LeadPacket`s — the Class-1 fixture R1 (`UEI:ZZTEST00FIX1`,
EXAMPLE INTERPRETING FIXTURE LLC) and the Class-2 real SBIC R2
(`NAME:1st source capital|south bend in`, 1st Source Capital Corporation). Each
packet was scored by invoking the **unmodified** `prospect-evaluation` skill in
the s6-selected mode; reports captured to `output/reports/{report_slug}/`. Full
evidence — per-candidate scores, mode/gate/slug derivations, the artifact
listing — in `evidence/s6-selftest.md`. Seven checks against the
`OFFMARKET_BUILD_PLAN.md` s6 `Done-when` criteria:

- **C1 — Class-1 produces a score + report via the unmodified scorer.** PASS.
  R1 → `eval_mode: rollup_addon` (Applied Development, NAICS 541930, no size
  floor, /110), `keyword_tier: core` → full +10 line-10 bonus. Score **30/110**,
  internally consistent across header / scorecard field 26 / breakdown total;
  both `.md` + `.html` on disk under `output/reports/uei-zztest00fix1/`.
- **C2 — Class-2 produces a score + report via the unmodified scorer.** PASS.
  R2 → `eval_mode: sbic`, score **30/100** explicitly **informational only**;
  SBIC License Gate **✅ PASS** derived per §4 from `sbic_license_status:
  Good Standing` → `buybox_gate: pass`; `sbic_gp_economics` kept informational,
  never mapped onto an EBITDA/valuation line. Both `.md`+`.html` on disk under
  `output/reports/name-1st-source-capital-south-bend-in/`.
- **C3 — "no asking price" handled gracefully (§3.2).** PASS. In both reports
  the scorer ran to completion — no crash, no abort, candidate not dropped:
  Buy Box line 5 → ⚠️ "insufficient data"; the valuation-multiple rubric line →
  **0 / "insufficient data — not awarded"** (not a ❌). Neither run hit the
  §3.2 BLOCKING defect (a scorer that crashes/refuses purely on absent ask).
- **C4 — `report_slug` filesystem-safe & deterministic (§5.1).** PASS.
  `UEI:ZZTEST00FIX1` → `uei-zztest00fix1`; `NAME:1st source capital|south bend
  in` → `name-1st-source-capital-south-bend-in`. Both contain only `[a-z0-9-]`
  (the `:`/`|` removed), both created without error as the on-disk dir names.
- **C5 — both `.md` and `.html` captured (§5).** PASS. Each report directory
  holds `{company-slug}-report.md`, `{company-slug}-report.html`, and
  `lead-packet.json`; the dashboard-linked `.html` skipped in neither.
- **C6 — no fabrication; gaps stay gaps.** PASS. Every undisclosed field scores
  "insufficient data — not awarded" in both reports — the `revenue_signal` /
  `$480K` award total were not fabricated into an EBITDA tier; no invented
  financials, contacts, dates, or URLs.
- **C7 — Class-2 report carries the SBA prior-approval fact.** PASS. R2's
  report has a dedicated "SBIC Closing Condition — SBA Prior Approval of Change
  of Control" section (13 CFR Part 107) plus a Risk-Factors mention.

**Result: all 7 checks PASS.** Stage s6 → `self_checked`. **No BLOCKING
defect.** Two carry-notes to the VERIFY critic (not Done-when failures):
(1) R1 is a fixture — the genuine Class-1 *end-to-end* score on a real ASL/CART
company is deferred to s10's larger live sample, the same IMPROVE-s3-1 /
IMPROVE-s4-4 chain the s4/s5 critics already flagged; R1's 30/110 is an honest
plumbing artifact. (2) A pre-existing EBITDA-band wording inconsistency lives
inside the **unmodified** `prospect-evaluation` skill (resources say "$1M–$4M",
front-matter says "$1M or more"); it did not affect either run and is out of
scope for this loop. Next phase for s6: VERIFY (fresh-context critic).

## iter 21 — 2026-05-22 — s7 (Airtable write & dashboard badge) — SELF-TEST

Exercised the s7 deliverables — `references/airtable_write.md` (field-by-field
mapping) and the `templates/daily-dashboard.html` off-market badge — against the
`OFFMARKET_BUILD_PLAN.md` s7 `Done-when` criteria, over the s6 SELF-TEST
`ScoredLead`s (Class-1 fixture R1 `UEI:ZZTEST00FIX1`; Class-2 real SBIC R2
`NAME:1st source capital|south bend in`). Five checks:

- **C1 — badge style block present & well-formed.** PASS. `daily-dashboard.html`
  carries a `.chip.offmarket` rule (lines 154–158), green `--pass` palette,
  sibling to the existing `.chip.price-drop` / `.chip.manual` chips. The base
  `.chip` rule is unchanged; on-market chips are untouched.
- **C2 — badge renders on off-market rows only.** PASS. The render condition
  `{% if lead.source.startswith('Off-Market') %}` appears in three row sections
  (lines 242, 288, 330 — New Finds, Running Queue, Revisit Bucket). A live Jinja2
  render of that exact condition: `Off-Market — ASL Bolt-on` → badge,
  `Off-Market — SBIC` → badge, `Overnight Search` → no badge,
  `Manual Submission` → no badge (its own `.chip.manual` still fires). The
  condition is additive — on-market rows render exactly as before.
- **C3 — every s7 field ID maps to a live field of the correct type.** PASS. All
  ~30 field IDs in `airtable_write.md` §3.1/§3.2 were cross-checked against
  `config/search_config.md`; the five §8.4 IDs (`fld7Ook8ZoLAjwFTe`,
  `fldogicjVNMCBuyJI`, `fldscFvXPUFYbSg3F`, `fldM7KoR2gtfvBVWN`,
  `fldZXrqqoBkIdDWJN`) were confirmed live via `get_table_schema` —
  `Gov Entity ID`/`SBIC License #` singleLineText, `SBIC License Status`
  singleSelect (5 options match), `Gov Data Source` multipleSelects (8 choices
  match `enrichment.md` §5.1), `Federal Award History $` currency. No invalid ID.
- **C4 — create/update split & no-fabrication review.** PASS (by inspection).
  §3 maps `new` → create, §4 maps `existing` → update-in-place (fill only blank
  gov fields, never flip `Source`/`Disposition`); §3.2 leaves `Listing ID`
  blank; §3.1/§3.2 write `Asking Price`/EBITDA/Revenue/Cash-Flow only for real
  disclosed figures; §6 leaves every unknown blank. `Disposition` = `Active`.
- **C5 — a scored off-market prospect writes as a live row in
  `tblSmNrHROMLm7vOS` with `Disposition = Active`.** **BLOCKED by B4 — NOT a
  fail.** A live `get_table_schema` read of the `Source` field
  (`fldiGyXTk6Ybb6J1L`) shows choices `["Overnight Search", "Manual
  Submission"]` only — the two off-market values are still absent. The Step-1
  schema preflight (`airtable_schema_preflight.md`) fails-loud and halts before
  s7 runs; `airtable_write.md` §2/§6 forbid auto-creating the `Source` value.
  Writing an off-market row is therefore impossible until B4 clears. No live
  write was attempted (attempting it would fail or fabricate the `Source`
  value — both forbidden).

**Result: C1–C4 PASS; C5 BLOCKED by B4.** The s7 build artifacts (mapping
reference + dashboard badge) are correct and exercised, but the central s7
`Done-when` — a scored off-market prospect appearing as a live row — cannot be
satisfied while B4 is open. Per the loop blocker rule, stage s7 → `blocked`
(B4); B4 updated to record that it now blocks **both** s2 and s7. The loop
continues with the next non-blocked stage (s8). s7 retries SELF-TEST → VERIFY
automatically once the two `Source` values are added.

## iter 23 — 2026-05-22 — s8 (Outreach drafting) — SELF-TEST

Drove the s8 procedure (`references/outreach_drafting.md` +
`config/offmarket_outreach_template.md`) over the s5/s6 SELF-TEST leads — the
Class-1 fixture R1 (EXAMPLE INTERPRETING FIXTURE LLC) and the Class-2 real SBIC
R2 (1st Source Capital Corporation) — plus one constructed no-contact case
(SYN-NC1). Full evidence — the two generated draft blocks, the daily-file
artifact, the placeholder-fill tables — in `evidence/s8-selftest.md` and
`evidence/s8-offmarket_outreach_drafts_2026-05-22.md`. Six checks against the
`OFFMARKET_BUILD_PLAN.md` s8 `Done-when` criteria:

- **C1 — a Class-1 OM-1 draft is generated for a candidate with a direct
  contact; no raw placeholder survives.** PASS. R1 has `contact.name =
  "Pat Sample"` → contact gate passes (partial contact, no email → still drafted
  per §5). OM-1, Subject Variant 1; `[OWNER_NAME]`/`[BUSINESS_NAME]`/
  `[LOCATION]`/`[SPECIFIC_DETAIL]` all filled from real packet data
  (`[SPECIFIC_DETAIL]` from the verified `federal_award_total: 480000`); zero
  raw `[...]` tokens survive; the missing email shows as `needs follow-up` in
  the `Recipient:` block.
- **C2 — a Class-2 OM-2 draft is generated; the SBA-prior-approval sentence is
  present.** PASS. R2 → OM-2, Subject Variant 2; the SBA prior-approval
  change-of-control sentence appears verbatim as fixed body text (not a
  placeholder); no raw placeholder survives.
- **C3 — the no-contact case yields no draft.** PASS. SYN-NC1 (in-memory only,
  `name`/`email` both `null`) → contact gate → no draft, logged `outreach:
  skipped — no direct contact (needs follow-up: contact discovery)`; no contact
  fabricated; the skip consumes no subject-variant slot.
- **C4 — nothing is auto-sent; the NOT SENT markers are present.** PASS. Both
  draft blocks carry the `--- OFF-MARKET OUTREACH DRAFT (NOT SENT) ---` header
  and `--- END DRAFT (review and send manually) ---` footer; the s8 deliverable
  has no send capability (no Gmail/SMTP/send path in either file). The daily-file
  storage is exercised; the Airtable `Notes` append is B4-blocked (no off-market
  row exists) — the designed degradation path (draft still lands in the daily
  file) is what is exercised.
- **C5 — the broker templates are untouched.** PASS. `config/outreach_templates.md`
  last modified at `323a782` (2026-05-21, on-market revamp loop) — no
  `offmarket-build` commit touches it, working tree clean. s8 added a new sibling
  file, `config/offmarket_outreach_template.md`.
- **C6 — subject-variant alternation across drafted leads.** PASS. R1 → Variant
  1; SYN-NC1 skipped (no slot); R2 → Variant 2 — alternation correct, skip did
  not shift the count.

**Result: all 6 checks PASS. No BLOCKING defect.** Two carry-notes to the
VERIFY critic (not Done-when failures): (1) the §4 two-place storage's `Notes`
append is B4-dependent — no off-market tracker row exists yet, so only the
daily-file half is exercised; the `Notes` half is deferred to s10's end-to-end
run once B4 clears (does not block s8, whose `Done-when` is satisfied without a
live row). (2) OM-2 candidate IMPROVE: R2's only enriched contact is the
directory POC titled *Investor Relations*, not the GP principal the OM-2 body
addresses ("reaching out to you as a principal") — the s5 `enrichment_gaps`
already flags this; the critic should weigh whether s8 should prefer a
principal-titled contact for Class 2 or soften the body. Stage s8 →
`self_checked`. Next phase for s8: VERIFY (fresh-context critic).

## iter 26 — 2026-05-22 — s9 (Orchestration & cadence) — SELF-TEST

Exercised the s9 deliverables — `references/orchestration.md`,
`config/offmarket_schedule.md`, `run-offmarket-search.sh`, the launchd plist,
and the wired `skill.md` — in **dry-run / fixture mode** against the
`OFFMARKET_BUILD_PLAN.md` s9 `Done-when` criteria. s9 added no new pipeline
logic, so the test verifies the *wiring*. Full evidence — the type-chain trace,
the assembled run log — in `evidence/s9-selftest.md` and
`evidence/s9-offmarket_run_log_dryrun.md`. Five checks:

- **C1 — the 1→9 stage hand-off contract is complete & type-consistent.** PASS.
  All 8 reference files cited in `orchestration.md` §1 exist on disk; each
  step's produced type (`RawRecord[]` → `CanonicalEntity[]` → `LeadPacket[]` →
  `ScoredLead[]` → rows → drafts → dashboard → run log) is the literal input the
  next stage's reference names; the `new`/`existing`/`needs_operator_review`
  branch is honoured (`new`→s5, `existing`→s7 update, review→run-log only).
- **C2 — halt-vs-degrade behaviour is correct.** PASS. Hard halts traced —
  Step 1 preflight (with B4 open a live run halts `halted-preflight` before
  Step 2) and a failed Step 3 tracker read. Graceful degrades traced — blocked
  adapters B1/B3 (s3 SELF-TEST C4/C5), per-candidate enrichment/scoring/write
  failures (`enrichment.md` §6, `scoring_integration.md` §6, `airtable_write.md`
  §6). Step 9 always runs, even on a halt.
- **C3 — manual single-entity path traced for one supplied entity.** PASS.
  `orchestration.md` §4 traced for "1st Source Capital Corporation, IN —
  Class 2": preflight → skip Step 2 bulk discovery, seed resolution directly →
  Steps 3–9 unchanged (`existing`→update, `new`→full pipeline) → run log
  `Run type: manual single-entity` (dated append if today's log exists) →
  operator report. Same no-send / no-fabricate constraints.
- **C4 — run-log output assembled from real prior-stage counts.** PASS. The
  `orchestration.md` §3 template was driven with the real s3–s8 SELF-TEST counts
  (8 raw → 4 new + 3 needs-review; 4 pre-filter passes; R1 30/110, R2 30/100;
  0 writes — dry-run; 2 drafts + 1 no-contact skip) and saved to
  `evidence/s9-offmarket_run_log_dryrun.md`. A `0` is reported as `0`; every gap
  and blocker (B1/B3/B4) is named; nothing estimated.
- **C5 — schedule artifacts validate.** PASS. `bash -n run-offmarket-search.sh`
  clean; `plutil -lint` the plist OK; the script is executable (`-rwxr-xr-x`);
  the plist fires `Weekday=1, Hour=6` (Monday 06:00); `config/offmarket_schedule.md`
  defines the `/schedule` cron, trigger prompt, and registration command.

**Result: all 5 checks PASS. No BLOCKING defect.** Stage s9 → `self_checked`.
Two carry-notes to the VERIFY critic (not Done-when failures): (1) the **live**
cron registration is deliberately gated on B4 — registering it now would make
the weekly run fail-loud at the Step 1 preflight every Monday; the cadence is
fully defined and version-controlled (config + script + plist) and the
registration command is documented as the post-B4 install step. The critic
should weigh whether "defined + gated" satisfies the s9 `Done-when` "the weekly
cron is registered" or whether it must be re-confirmed at COMPLETE. (2) The
end-to-end run was a dry-run over fixtures; the genuine live end-to-end run is
s10's job, gated on B3/B4. Next phase for s9: VERIFY (fresh-context critic).

## iter 29 — 2026-05-22 — s10 (Assembly, end-to-end self-test & final audit) — SELF-TEST

Exercised the s10 IMPLEMENT artifacts — `evidence/s10-e2e-dryrun.md` and
`evidence/s10-offmarket_run_log_e2e_dryrun.md` — against the
`OFFMARKET_BUILD_PLAN.md` s10 `Done-when` dry-run criterion (*"the dry run
produces at least one scored record per class into a test context with no
fabricated fields"*). The final-audit / all-stages-`verified` halves of the s10
`Done-when` are the FINAL AUDIT phase, not this SELF-TEST. Each scored artifact
was confirmed by direct on-disk inspection — not from the IMPLEMENT log. Six
checks:

- **C1 — Class-1 scored record exists in a test context.** PASS. R1
  (`UEI:ZZTEST00FIX1`, EXAMPLE INTERPRETING FIXTURE LLC) — `output/reports/
  uei-zztest00fix1/` holds `example-interpreting-fixture-llc-report.md`
  (21,860 B), `.html` (32,783 B), and `lead-packet.json`. Report header reads
  **Lead Score 30 / 110**, `rollup_addon` mode, internally consistent with
  scorecard field 26 and the breakdown total.
- **C2 — Class-2 scored record exists in a test context.** PASS. R2
  (`NAME:1st source capital|south bend in`, 1st Source Capital Corporation) —
  `output/reports/name-1st-source-capital-south-bend-in/` holds
  `1st-source-capital-corporation-report.md` (25,021 B), `.html` (36,391 B),
  and `lead-packet.json`. Header reads **Lead Score 30 / 100 (informational
  only — SBIC mode)**; **SBIC License Gate ✅ PASS**; the SBA-prior-approval
  change-of-control section is present.
- **C3 — no fabricated fields.** PASS. Both `lead-packet.json` files inspected
  field-by-field: every unknown is `null` or `"needs follow-up"` and is
  enumerated in `enrichment_gaps` (R1: 5 gaps; R2: 4 gaps). `revenue_signal` is
  explicitly labelled a signal; `federal_award_total` carries only the real
  $480K award figure; `asking_price` is the literal `"not for sale — no asking
  price"`; `sbic_gp_economics` is labelled fund-level informational data. R1
  carries an explicit `_fixture_note` marking it synthetic. No invented
  financials, contacts, codes, or URLs. Both reports score every undisclosed
  line "insufficient data — not awarded", never a fabricated tier.
- **C4 — written to a test context, not the live tracker.** PASS. The run log
  records **0 created / 0 updated / 0 write failures**; §6 of the assembly
  confirms writes were directed at a test context, never `tblSmNrHROMLm7vOS`.
  A live `get_table_schema` read of `Source` (`fldiGyXTk6Ybb6J1L`) this
  iteration returns only `Overnight Search` / `Manual Submission` — a live run
  would additionally halt at the Step 1 preflight (B4).
- **C5 — run log assembled from real prior-stage counts.** PASS.
  `s10-offmarket_run_log_e2e_dryrun.md` uses the `orchestration.md` §3 template
  with the real Step 2–8 counts (8 raw → 7 canonical [4 `new` + 3 thin] → 4
  pre-filter passes → 2 scored; 0 Airtable writes; 2 drafts + 1 no-contact
  skip). A `0` is reported as `0`; B1/B3/B4 and the 3 needs-operator-review
  entities are all named; nothing estimated.
- **C6 — nothing auto-sent.** PASS. 2 outreach drafts (R1 OM-1 / R2 OM-2), both
  carrying the `--- OFF-MARKET OUTREACH DRAFT (NOT SENT) ---` markers; the s10
  assembly invokes only the s8 reference, which has no send path.

**Result: all 6 checks PASS. No BLOCKING defect.** Stage s10 → `self_checked`.
Two carry-notes to the VERIFY critic (not Done-when failures): (1) the s8
outreach-drafts artifact lives at `evidence/s8-offmarket_outreach_drafts_2026-05-22.md`,
but the run log line 53 cites the production path `search_reports/offmarket_outreach_drafts_2026-05-22.md`
— a dry-run stores under `evidence/`; a live run writes the production path.
A path-label NIT, not a Done-when failure. (2) R1 is a synthetic Class-1
fixture, not a real S1-discovered company (the open IMPROVE-s3-1 chain — the
USAspending adapter does not yet populate `uei`); the genuine real-company
Class-1 end-to-end score remains deferred. The critic should weigh whether a
fixture-based Class-1 score satisfies the s10 `Done-when`. Next phase for s10:
VERIFY (fresh-context critic).

## iter 33 — 2026-05-22 — s2 (Airtable schema) — SELF-TEST

Exercised the s2 deliverable — the live schema changes plus the fail-loud
preflight (`references/airtable_schema_preflight.md`) — against the
`OFFMARKET_BUILD_PLAN.md` s2 `Done-when` criteria. The preflight Procedure
(steps 1–4) was driven for real against the live base via the Airtable MCP:
`list_tables_for_base(appOsvuyy5eK43QTx)` then
`get_table_schema` for the six field IDs. Six checks:

- **C1 — all six required fields exist with the correct name + type.** PASS.
  Live `list_tables_for_base` read of table `tblSmNrHROMLm7vOS`
  ("Master Deal Pipeline") returns: `Source` (`fldiGyXTk6Ybb6J1L`,
  singleSelect), `Gov Entity ID` (`fld7Ook8ZoLAjwFTe`, singleLineText),
  `SBIC License #` (`fldogicjVNMCBuyJI`, singleLineText), `SBIC License Status`
  (`fldscFvXPUFYbSg3F`, singleSelect), `Gov Data Source` (`fldM7KoR2gtfvBVWN`,
  multipleSelects), `Federal Award History $` (`fldZXrqqoBkIdDWJN`, currency).
  Every name, type, and field ID matches the preflight table exactly — no
  field present under a wrong type.
- **C2 — both off-market `Source` values present, byte-for-byte.** PASS. A live
  `get_table_schema` read of `fldiGyXTk6Ybb6J1L` returns four choices:
  `Overnight Search`, `Manual Submission`, `Off-Market — ASL Bolt-on`
  (`selezt48WJR6jPv2m`), `Off-Market — SBIC` (`seltqCid0e9t6aijI`). The two
  off-market names verified character-by-character against
  `OFFMARKET_BUILD_PLAN.md` §8.3 — em dash `—` (U+2014), single spaces around
  it, exact casing. The on-market values are untouched.
- **C3 — `SBIC License Status` carries all five standing options.** PASS. Live
  `get_table_schema` of `fldscFvXPUFYbSg3F` returns `Good Standing`,
  `Under Review`, `Surrendered`, `Revoked`, `Unknown` — the exact set the
  preflight Procedure step 4 requires.
- **C4 — `Gov Data Source` multi-select choices present.** PASS. Live read of
  `fldM7KoR2gtfvBVWN` returns the eight choices `USAspending`, `SAM.gov`,
  `SAM.gov Contract Awards`, `SBA SBIC`, `SBS`, `GSA eLibrary`, `State`, `RID`
  — matching `enrichment.md` §5.1 (FPDS-NG/DSBS correctly absent per §13).
  `currency` config on `Federal Award History $` confirmed `$`, precision 0.
- **C5 — the preflight passes end-to-end against the live schema.** PASS. All
  four Procedure steps (locate table → six fields by name+type → both `Source`
  options → five `SBIC License Status` options) resolve green against the live
  base read this iteration; the preflight returns clean and would not halt a
  write.
- **C6 — the preflight fails loud on a missing element.** PASS. The "On failure"
  branch was confirmed by inspection and against the recorded live evidence: in
  iter 21 (B4 still open) the iter-21 s7 SELF-TEST C5 ran this same preflight
  against the then-incomplete `Source` field and observed it halt with the
  `OFF-MARKET SCHEMA PREFLIGHT FAILED` message naming the two absent off-market
  values — a real, observed fail-loud, not a simulated one. The Procedure's
  name+type match (step 2) and exact-string option checks (steps 3–4) flag any
  miss, and the failure message never auto-creates a field or option.

**Result: all 6 checks PASS. No BLOCKING defect.** Stage s2 → `self_checked`.
No new findings. Next phase for s2: VERIFY (fresh-context critic).

## iter 36 — 2026-05-22 — s7 (Airtable write & dashboard badge) — SELF-TEST

Re-ran the s7 SELF-TEST after the iter-34 re-IMPLEMENT and B4's resolution. The
iter-21 SELF-TEST left C5 (the central s7 `Done-when` — a scored off-market
prospect appearing as a live row in `tblSmNrHROMLm7vOS`) BLOCKED by B4; with B4
resolved this iteration drove the `airtable_write.md` write procedure for real
against the live base, attempting an actual create of the Class-2 SBIC lead R2
(1st Source Capital Corporation, `NAME:1st source capital|south bend in`,
score 20/100). R1 is a synthetic fixture and was deliberately **not** written to
the live tracker (writing `EXAMPLE INTERPRETING FIXTURE LLC` into the production
pipeline would be inserting fabricated data — the real Class-1 row stays gated
on the IMPROVE-s3-1 chain). Five checks against the `OFFMARKET_BUILD_PLAN.md` s7
`Done-when` criteria:

- **Preflight — live schema confirmed.** PASS. `get_table_schema` of the six
  required fields: all present with the correct types (`Gov Entity ID` /
  `SBIC License #` singleLineText, `SBIC License Status` singleSelect [5
  options], `Gov Data Source` multipleSelects [8 choices], `Federal Award
  History $` currency, `Source` singleSelect with `Off-Market — SBIC`
  `seltqCid0e9t6aijI`). `Industry Match` has `SBIC` (`selwe1CYRoCvC5R8V`);
  `Disposition` has `Active` (`selKN12meneKypCem`). The preflight passes.
- **Dedup — R2 is `new`.** PASS. `search_records` for "1st Source Capital" over
  `tblSmNrHROMLm7vOS` returns zero rows → `dedup_verdict: new` → create path.
- **C1 — badge style block present & well-formed.** PASS (inspection,
  unchanged since iter 21 / re-confirmed iter 34). `.chip.offmarket` in
  `daily-dashboard.html`, green `--pass` palette, base `.chip` rule unchanged.
- **C2 — badge renders on off-market rows only.** PASS (inspection, unchanged).
  `{% if lead.source.startswith('Off-Market') %}` in the three row sections;
  additive — on-market rows render as before.
- **C3 — every s7 field ID maps to a live field of the correct type.** PASS for
  the §3.3 new fields and the §3.2/`Source` IDs (confirmed live this iteration).
- **C4 — create/update split & no-fabrication mapping.** PASS by inspection for
  the create/update branch and the no-fabrication rule (every R2 unknown left
  blank: `SBIC License #`, `Federal Award History $`, website, EBITDA, revenue,
  years-in-business, NAICS, screenshot, `Listing ID`, `Direct Listing URL`).
- **C5 — a scored off-market prospect writes as a live row in
  `tblSmNrHROMLm7vOS` with `Disposition = Active`.** **FAIL.** The live
  `create_records_for_table` call — built field-by-field per `airtable_write.md`
  §3 — was **rejected atomically** with `HTTP 422: Insufficient permissions to
  create new select option ""SBA SBIC directory""`. Root cause: §3.1 maps
  `Lead Source` (`fldI1h3qmNI6vc5rr`) to a free-text "human-readable" gov-source
  string, but a live `get_table_schema` read shows `Lead Source` is a
  **singleSelect** restricted to 14 broker-platform options (`Direct Outreach`,
  `Broker`, `Referral`, `Conference`, `BizBuySell`, `BizQuest`, `Axial`,
  `Grata`, `DealStream`, `Trade-A-Plane`, `LinkedIn`, `Other Platform`,
  `General Web`, `BusinessBroker.net`) — it cannot hold an arbitrary gov-source
  string, and auto-creating an option is forbidden by the build constraints. A
  post-attempt `search_records` confirms **zero rows written** (the 422 is
  atomic). No record was created; the badge half is fine but the central s7
  `Done-when` is not met by the procedure as written.

**Result: preflight + dedup + C1–C4 PASS; C5 FAILS.** This is a real defect in
the s7 deliverable, not an external blocker — `airtable_write.md` §3.1's
`Lead Source` mapping is invalid against the live field type. Per the SELF-TEST
contract a failed check returns the stage to IMPLEMENT: stage s7 →
`not_started`. New finding **BLOCKING-s7-1** logged in `FINDINGS.md`
(`unresolved_findings` 27 → 28). Next phase for s7: IMPLEMENT — fix the §3.1
`Lead Source` mapping (leave it blank for off-market rows — gov provenance is
already carried by the dedicated `Gov Data Source` multi-select and `Links` —
or map to an existing option), then re-run this SELF-TEST including the live
write of R2.

## iter 38 — 2026-05-22 — s7 (Airtable write & dashboard badge) — SELF-TEST (re-run)

Re-ran the s7 SELF-TEST after the iter-37 re-IMPLEMENT that resolved
**BLOCKING-s7-1** (rewrote `airtable_write.md` §3.1 so `Lead Source` is left
**blank** for off-market rows, and hardened §6 with a "never auto-create a
select option on any field" rule). Drove the `airtable_write.md` write
procedure for real against the live base, attempting an actual create of the
Class-2 SBIC lead R2 (1st Source Capital Corporation,
`NAME:1st source capital|south bend in`, score 20/100). R1 remains a synthetic
fixture and was deliberately **not** written to the live tracker (writing
`EXAMPLE INTERPRETING FIXTURE LLC` into production would insert fabricated
data — the real Class-1 row stays gated on the IMPROVE-s3-1 chain). Checks
against the `OFFMARKET_BUILD_PLAN.md` s7 `Done-when` criteria:

- **Preflight — live schema confirmed.** PASS. `get_table_schema` of the write
  targets: `Industry Match` singleSelect has `SBIC` (`selwe1CYRoCvC5R8V`);
  `Disposition` has `Active` (`selKN12meneKypCem`); `Source` has
  `Off-Market — SBIC` (`seltqCid0e9t6aijI`); `SBIC License Status` has
  `Good Standing` (`selmeIWvIAUqVwV9h`); `Gov Data Source` multipleSelects has
  `SBA SBIC` (`selnRzXzjifJ8Cc5X`); `Gov Entity ID` / `SBIC License #`
  singleLineText; `Federal Award History $` currency; `Prospect Eval Report`
  url; `Date Added` date (ISO); `Lead Score` number. Preflight passes.
- **Dedup — R2 is `new`.** PASS. `search_records` for "1st Source Capital" over
  `tblSmNrHROMLm7vOS` returns zero rows → `dedup_verdict: new` → create path.
- **C1 — badge style block present & well-formed.** PASS. `.chip.offmarket`
  rule at `daily-dashboard.html:155`; base `.chip` rule unchanged.
- **C2 — badge renders on off-market rows only.** PASS.
  `{% if lead.source.startswith('Off-Market') %}` at lines 242/288/330 (New
  Finds, Running Queue, Revisit Bucket); additive — on-market rows unchanged.
- **C3 — every s7 field ID maps to a live field of the correct type.** PASS.
  Confirmed live via `get_table_schema` this iteration (see Preflight).
- **C4 — create/update split & no-fabrication mapping.** PASS. R2 written via
  the `new` → create path; every R2 unknown left blank — `SBIC License #`,
  `Federal Award History $`, website, EBITDA, revenue, cash flow,
  years-in-business, NAICS, screenshot, `Listing ID`, `Direct Listing URL`,
  `Asking Price`, `Lead Source` (blank per the iter-37 fix). No fabricated
  value; the gov-record URL gap is recorded as "needs follow-up" in `Notes`.
- **C5 — a scored off-market prospect writes as a live row in
  `tblSmNrHROMLm7vOS` with `Disposition = Active`.** **PASS.** A live
  `create_records_for_table` per `airtable_write.md` §3 — with `Lead Source`
  **blank** — succeeded: record **`recklDY7vHFmKauQD`** created with
  `Source = "Off-Market — SBIC"`, `Disposition = "Active"`,
  `Industry Match = "SBIC"`, `Lead Score = 20`,
  `Gov Entity ID = "NAME:1st source capital|south bend in"`,
  `SBIC License Status = "Good Standing"`, `Gov Data Source = ["SBA SBIC"]`.
  The iter-36 `HTTP 422` no longer fires — leaving `Lead Source` blank removed
  the invalid select-option write. A follow-up `update_records_for_table` wrote
  the Airtable record URL back into `Notes` per §3.4. No 422, no auto-created
  option, no fabricated field.

**Result: all checks PASS (Preflight + Dedup + C1–C5).** The central s7
`Done-when` is met — a scored off-market prospect now appears as a normal
`Active` row in `tblSmNrHROMLm7vOS`. Stage s7 → `self_checked`. No new
findings. Next phase for s7: VERIFY (fresh-context critic).

## iter 40 — 2026-05-22 — s10 (Assembly, end-to-end self-test & final audit) — SELF-TEST (re-run)

Re-ran the s10 SELF-TEST after the iter-31 re-IMPLEMENT that resolved
**BLOCKING-s10-1** (re-scored R2 strictly from `lead-packet.json`, rewrote both
the R2 `.md` and `.html`, closed IMPROVE-s10-1/-2). Per the iter-31 re-IMPLEMENT
directive, this SELF-TEST reads the **report bodies field-by-field against
`lead-packet.json`** — the gap the iter-29 SELF-TEST C3 missed — not just the
packet. Both scored artifacts were inspected directly on disk. Six checks
against the `OFFMARKET_BUILD_PLAN.md` s10 `Done-when` dry-run criterion (*"the
dry run produces at least one scored record per class into a test context with
no fabricated fields"*); the final-audit / all-stages-`verified` halves are the
FINAL AUDIT phase, not this SELF-TEST.

- **C1 — Class-1 scored record exists; report traces field-by-field to its
  packet.** PASS. R1 (`UEI:ZZTEST00FIX1`) — `output/reports/uei-zztest00fix1/`
  holds the `.md` (21,860 B), `.html` (32,783 B) and `lead-packet.json`. Every
  report value checked against the packet: `business_name`, `location`
  (Anytown VA — scorecard #9 explicitly "city + state only"), `formation_date`/
  `sos_status` null → Buy Box line 3 ⚠️ + rubric 0/10, `employee_count`
  `"needs follow-up"` → scorecard #6 undisclosed, `revenue_signal`/
  `federal_award_total: 480000` treated strictly as a signal (not a P&L row),
  `asking_price` not-for-sale → valuation line 0, `contact` Pat Sample/Owner/
  null email+phone, `keyword_tier: core` → +10 bonus, all 5 `enrichment_gaps`
  reflected. Header **30/110** = scorecard #26 = breakdown total (20 industry +
  8×0 + 10 bonus). No report value is absent from the packet.
- **C2 — Class-2 scored record exists; report traces field-by-field to its
  packet (BLOCKING-s10-1 focus).** PASS. R2 (`NAME:1st source capital|south
  bend in`) — `output/reports/name-1st-source-capital-south-bend-in/` holds the
  `.md` (24,951 B), `.html` (37,387 B) and `lead-packet.json`. The
  BLOCKING-s10-1 root cause is verified fixed in **both** `.md` and `.html`:
  `formation_date`/`years_in_business` are `null` in the packet → Buy Box line
  3 and the years-in-business rubric line score **0 "insufficient data — not
  awarded"** (not the old erroneous ✅ PASS / 10/10); the SBIC fund vintage 1983
  is carried only as informational fund-level data, never mapped to
  years-in-business. No formation date, street address, SEC CIK, or CB Insights
  value appears (those were stripped). `sbic_license_status: Good Standing` →
  SBIC License Gate ✅ PASS; `sbic_gp_economics` informational; `contact` Ryan
  Fenstermaker/Investor Relations (flagged as non-principal). Header **20/100** =
  scorecard #26 = breakdown total (20 industry + 8×0); HTML grep confirms
  `20 / 100` and no `30 / 100`. Math check line present and correct.
- **C3 — no fabricated fields in either report body.** PASS. Read both report
  bodies (not just the packets) line by line: every undisclosed field reads
  "not disclosed" / "needs follow-up" / "insufficient data — not awarded"; no
  invented financials, dates, headcount, contacts, codes, or URLs. R2 Appendix
  A/D cite only the SBA SBIC directory and the `LeadPacket`; Appendix B/C state
  "None — no estimates". R1 carries its synthetic-fixture warning. The iter-30
  defect (a report value absent from its packet) does not recur.
- **C4 — written to a test context, not the live tracker.** PASS. The run log
  records **0 created / 0 updated / 0 write failures**; the dry run directed
  writes at a test context. (Note: a separate live write — R2 row
  `recklDY7vHFmKauQD` — was performed by the iter-38 s7 SELF-TEST, not by this
  s10 dry run; the two are distinct artifacts.)
- **C5 — run log assembled from real prior-stage counts.** PASS.
  `s10-offmarket_run_log_e2e_dryrun.md` uses the `orchestration.md` §3 template
  with the real Step 2–8 counts (8 raw → 7 canonical [4 `new` + 3 thin] → 4
  pre-filter passes → 2 scored: R1 30/110, R2 20/100; 0 Airtable writes; 2
  drafts + 1 no-contact skip). A `0` is reported as `0`; nothing estimated.
- **C6 — nothing auto-sent.** PASS. 2 outreach drafts (R1 OM-1 / R2 OM-2), both
  carrying the `--- OFF-MARKET OUTREACH DRAFT (NOT SENT) ---` markers; the s10
  assembly invokes only the s8 reference, which has no send path.

**Result: all 6 checks PASS. No BLOCKING defect.** The BLOCKING-s10-1 fix is
confirmed clean by the field-by-field read of both report bodies. Stage s10 →
`self_checked`. One new finding logged — **IMPROVE-s10-3**: the s10 dry-run
artifacts (`s10-e2e-dryrun.md`, `s10-offmarket_run_log_e2e_dryrun.md`) still
attribute the fixture usage and a Step-1 preflight halt to **open** blockers
B1/B3/B4, but all four blockers were resolved 2026-05-22; the artifacts should
re-attribute the fixture usage to the still-open `IMPROVE-s3-2`/`-s3-3`/`-s5-5`
adapter-rebuild findings and drop the "a live run halts at preflight (B4)"
claim. This is a stale-attribution defect, not a fabrication or a Done-when
breach (`unresolved_findings` 27 → 28). Next phase for s10: VERIFY
(fresh-context critic).

## iter 43 — 2026-05-22 — s10 (Assembly, end-to-end self-test & final audit) — SELF-TEST (re-run)

Re-ran the s10 SELF-TEST after the iter-42 re-IMPLEMENT that resolved
**BLOCKING-s10-2** (rewrote the R2 OM-2 outreach draft so its `[SPECIFIC_DETAIL]`
sentence no longer asserts the fabricated "since 1983" operating history;
hardened `config/offmarket_outreach_template.md` and
`.claude/skills/off-market-search/references/outreach_drafting.md` so the SBIC
fund vintage can never render as a company operating history). Per the iter-42
re-IMPLEMENT directive, this SELF-TEST reads the **outreach drafts
field-by-field against each `lead-packet.json`** — the gap the iter-29/40
SELF-TESTs did not cover (they read the report bodies, not the Step-7 outreach
artifact). All artifacts inspected directly on disk. Seven checks against the
`OFFMARKET_BUILD_PLAN.md` s10 `Done-when` dry-run criterion (*"the dry run
produces at least one scored record per class into a test context with no
fabricated fields"*); the final-audit / all-stages-`verified` halves remain the
FINAL AUDIT phase, not this SELF-TEST.

- **C1 — Class-1 scored record exists; report unchanged since the iter-40
  verified-clean read.** PASS. R1 (`UEI:ZZTEST00FIX1`) —
  `output/reports/uei-zztest00fix1/` holds the `.md` (21,860 B), `.html`
  (32,783 B) and `lead-packet.json`; file sizes and mtimes (May 22 09:54–09:58)
  are unchanged from iter 40 — the iter-42 re-IMPLEMENT touched only the OM-2
  outreach draft + template + `outreach_drafting.md`, never the report bodies,
  so the iter-40 field-by-field verdict (header 30/110 = scorecard #26 =
  breakdown total) stands.
- **C2 — Class-2 scored record exists; report unchanged since iter 40.** PASS.
  R2 (`NAME:1st source capital|south bend in`) —
  `output/reports/name-1st-source-capital-south-bend-in/` holds the `.md`
  (24,951 B), `.html` (37,387 B) and `lead-packet.json`; sizes/mtimes unchanged
  from iter 40. The iter-40 verdict stands: header 20/100, formation-date gap
  scores 0 "insufficient data — not awarded", fund vintage 1983 carried only as
  informational fund-level data.
- **C3 — no fabricated fields in either report body.** PASS. Report bodies not
  modified this re-IMPLEMENT (C1/C2); the iter-40 line-by-line read holds.
- **C4 — written to a test context, not the live tracker.** PASS. The dry-run
  run log records 0 created / 0 updated; writes directed at a test context.
- **C5 — run log assembled from real prior-stage counts.** PASS. Unchanged from
  iter 40 — `s10-offmarket_run_log_e2e_dryrun.md` carries the real Step 2–8
  counts (8 raw → 7 canonical → 4 pre-filter passes → 2 scored: R1 30/110,
  R2 20/100; 0 writes; 2 drafts + 1 no-contact skip); nothing estimated.
- **C6 — nothing auto-sent.** PASS. Both drafts in
  `evidence/s8-offmarket_outreach_drafts_2026-05-22.md` carry the
  `--- OFF-MARKET OUTREACH DRAFT (NOT SENT) ---` /
  `--- END DRAFT (review and send manually) ---` markers; neither the s8
  reference nor the template has any send path.
- **C7 (BLOCKING-s10-2 focus) — outreach drafts trace field-by-field to each
  packet; no fabricated operating history.** PASS. Read both Step-7 drafts
  against their `lead-packet.json`:
  - **OM-1 (R1, EXAMPLE INTERPRETING FIXTURE LLC):** `Business` =
    `business_name`; `Recipient` Pat Sample / Owner / "needs follow-up: no
    contact email" = `contact.name`/`title`/`email:null`; "in Anytown, VA" =
    `location`; "roughly $480K in awards to date" = `federal_award_total:
    480000`. No bracket token survives; no formation date or years-in-business
    asserted (both `null` in the packet). Clean.
  - **OM-2 (R2, 1st Source Capital Corporation):** `Business` =
    `business_name`; `Recipient` Ryan Fenstermaker / Investor Relations /
    fenstermakerr@1stsource.com = `contact.name`/`title`/`email`. The
    `[SPECIFIC_DETAIL]` sentence — "a licensed SBIC in good standing, pursuing
    a direct-lending investment strategy" — traces to `sbic_license_status:
    "Good Standing"` and `sbic_gp_economics.strategy: "Direct Lending"`. A
    `grep` for `1983` over the drafts file returns **zero hits** — the
    fabricated "since 1983" start year and the track-record claim derived from
    it are gone. The SBA-prior-approval sentence is present as fixed body text.
  - Template + reference hardening confirmed on disk: OM-2's `[SPECIFIC_DETAIL]`
    placeholder (`offmarket_outreach_template.md:189-197`) carries the explicit
    "Never render the SBIC fund vintage as a company operating history" rule
    and no longer lists "license vintage"; `outreach_drafting.md` §2 step 5
    (lines 71-77) and the new §5 edge bullet (lines 143-148) carry the same
    prohibition.

**Result: all 7 checks PASS. No BLOCKING defect.** The BLOCKING-s10-2 fix is
confirmed clean by the field-by-field read of both Step-7 outreach drafts
against their packets. Stage s10 → `self_checked`. No new findings (the stray
`</content>` token at drafts-file line 106 is already tracked as NIT-s8-1; the
stale-provenance items are tracked as IMPROVE-s10-3 / IMPROVE-s10-4). Next
phase for s10: VERIFY (fresh-context critic — the VERIFY must read the outreach
drafts field-by-field against each packet, the same gap that produced
BLOCKING-s10-2).

## iter 47 — 2026-05-22 — s9 (Orchestration & cadence) — SELF-TEST

Exercised the s9 re-IMPLEMENT (iter 46 — live cron registration). Done-when
criteria from `OFFMARKET_BUILD_PLAN.md` s9: *the skill runs the full pipeline;
the manual path works for one supplied company/SBIC; the weekly cron is
registered.* Five checks:

- **T1 — full pipeline wired (Steps 1–9).** PASS. `skill.md` carries Steps 1–9,
  each annotated with its building stage and pointing at its stage reference;
  `references/orchestration.md` §1 holds the stage hand-off contract (typed
  consumes/produces per step) and §2 the failure-containment rule. All eight
  stage references exist on disk
  (`airtable_schema_preflight.md`, `source_adapters.md`, `entity_resolution.md`,
  `enrichment.md`, `scoring_integration.md`, `airtable_write.md`,
  `outreach_drafting.md`, `orchestration.md`). s10 (verified) already ran the
  assembled pipeline end-to-end as a dry run.
- **T2 — manual single-entity path.** PASS. `skill.md` "Manual single-entity
  path" section + `orchestration.md` §4 fully specify it: one operator-supplied
  name/identifier/URL + target class, same Step 1 preflight, resolution seeded
  directly (Step 2 bulk discovery skipped), Steps 3–9 unchanged, run log written
  with `Run type: manual single-entity` (dated append if a weekly run already
  logged today), operator report of score / record URL / dedup verdict / gaps.
  Mirrors `submit-url`; same never-auto-send / never-fabricate constraints.
- **T3 — weekly cron registered (live state).** PASS. `launchctl list` shows
  `ai.earnedout.offmarket-search` loaded; `launchctl print
  gui/$(id -u)/ai.earnedout.offmarket-search` shows the calendar descriptor
  `Minute=0, Hour=6, Weekday=1` (Monday 06:00) and `state = not running`
  (correct — `RunAtLoad=false`, fires only on the calendar trigger). The plist
  is installed at `~/Library/LaunchAgents/ai.earnedout.offmarket-search.plist`
  and points at `run-offmarket-search.sh`.
- **T4 — run-log output specified.** PASS. `orchestration.md` §3 holds the
  `search_reports/offmarket_run_log_YYYY-MM-DD.md` template (sources queried,
  resolution/dedup, enrichment/scoring, Airtable writes, outreach drafts,
  dashboard, operator follow-ups), counts required real. `skill.md` Step 9 and
  `run-offmarket-search.sh`'s trigger prompt both reference it.
- **T5 — skill self-documentation matches the registered state.** **FAIL.**
  The iter-46 re-IMPLEMENT registered the launchd agent and updated
  `config/offmarket_schedule.md`, but left two skill files documenting the cron
  as *not yet* registered and B4 as *open*:
  1. `skill.md` "Cadence" section (last sentence): *"Live cron registration is
     gated on blocker B4 so the weekly run does not fail loud before the
     `Source` values exist."* — B4 is RESOLVED and the cron IS registered;
     this now misstates the registered reality.
  2. `skill.md` "BUILD STATUS" warning header: *"the Step 1 schema preflight
     will fail loud until blocker B4 ... is resolved. Run only in dry-run /
     fixture mode until then."* — B4 is resolved, so the preflight no longer
     fails on B4 and the B4-gating rationale is stale. (The header's other
     claim — not cleared for unattended live run until the loop reaches
     `OFFMARKET_BUILD_VERIFIED` — is still correct and should be kept.)
  3. `references/orchestration.md` §6: *"the **live registration** is the
     install step ... (it is gated on the B4 schema work ...)"* — same stale
     B4 gating; should read as registered (B4 cleared, iter 46).
  An operator reading `skill.md` would conclude the weekly cron is not live and
  the skill must stay dry-run-only because of B4 — both false. This is a real
  inconsistency in the s9 deliverable, not a NIT.

**Result: 4 PASS, 1 FAIL (T5).** Stage s9 → `not_started` (return to IMPLEMENT).
Next phase for s9: IMPLEMENT — correct the three stale B4-gating / cron-not-yet-
registered passages in `skill.md` (Cadence section + BUILD STATUS header) and
`references/orchestration.md` §6 so the skill documents the cron as registered
and B4 as resolved, while keeping the still-true "pending
`OFFMARKET_BUILD_VERIFIED`" status. No new `FINDINGS.md` entry — a SELF-TEST
failure routes back to IMPLEMENT per the phase ladder; `unresolved_findings`
unchanged at 29.

## iter 49 — 2026-05-22 — s9 (Orchestration & cadence) — SELF-TEST (re-run)

Re-ran the s9 SELF-TEST after the iter-48 re-IMPLEMENT that corrected the three
stale B4-gating / cron-not-yet-registered passages flagged by the iter-47 T5
FAIL. Done-when criteria from `OFFMARKET_BUILD_PLAN.md` s9: *the skill runs the
full pipeline; the manual path works for one supplied company/SBIC; the weekly
cron is registered.* Five checks; T5 (the iter-47 failure) is the focus.

- **T1 — full pipeline wired (Steps 1–9).** PASS. `skill.md` carries Steps 1–9,
  each annotated with its building stage and pointing at its stage reference;
  all eight stage references exist on disk (`airtable_schema_preflight.md`,
  `source_adapters.md`, `entity_resolution.md`, `enrichment.md`,
  `scoring_integration.md`, `airtable_write.md`, `outreach_drafting.md`,
  `orchestration.md`). `orchestration.md` §1 holds the typed stage hand-off
  contract and §2 the failure-containment rule. Unchanged since iter 47 PASS
  (iter 48 touched only §6 + the two `skill.md` self-doc passages).
- **T2 — manual single-entity path.** PASS. `skill.md` "Manual single-entity
  path" section + `orchestration.md` §4 (lines 115–146) specify it: one
  operator-supplied name/identifier/URL + target class, same Step 1 preflight,
  resolution seeded directly (Step 2 bulk discovery skipped), Steps 3–9
  unchanged, run log `Run type: manual single-entity`, operator report of
  score / record URL / dedup verdict / gaps. Mirrors `submit-url`; same
  never-auto-send / never-fabricate constraints. Unchanged since iter 47.
- **T3 — weekly cron registered (live state).** PASS. `launchctl list` shows
  `ai.earnedout.offmarket-search` loaded; `launchctl print
  gui/$(id -u)/ai.earnedout.offmarket-search` shows the calendar descriptor
  `Minute=0, Hour=6, Weekday=1` (Monday 06:00 local) and `state = not running`
  (correct — `RunAtLoad=false`; fires only on the calendar trigger). The plist
  is installed at `~/Library/LaunchAgents/ai.earnedout.offmarket-search.plist`
  and runs `/bin/bash` against `run-offmarket-search.sh` (`bash -n` clean,
  executable `-rwxr-xr-x`).
- **T4 — run-log output specified.** PASS. `orchestration.md` §3 (lines 66–113)
  holds the `search_reports/offmarket_run_log_YYYY-MM-DD.md` template — sources
  queried, resolution/dedup, enrichment/scoring, Airtable writes, outreach
  drafts, dashboard, operator follow-ups — counts required real. `skill.md`
  Step 9 references it. Unchanged since iter 47.
- **T5 — skill self-documentation matches the registered state.** PASS. The
  three iter-47 offenders re-read on disk and confirmed corrected:
  1. `skill.md` BUILD STATUS header (lines 8–16) — now states "Blocker B4 is
     **resolved** … so the Step 1 schema preflight passes" and keeps only the
     still-true "not yet cleared for an unattended live run … pending
     `OFFMARKET_BUILD_VERIFIED`". The stale "preflight will fail loud until B4"
     claim is gone.
  2. `skill.md` Cadence section (lines 207–219) — now states "The weekly cron
     is **registered and live** — the local `launchd` agent
     `ai.earnedout.offmarket-search` (Monday 06:00 local), installed once
     blocker B4 was resolved (build loop iter 46)". The stale "Live cron
     registration is gated on blocker B4" sentence is gone.
  3. `references/orchestration.md` §6 (lines 158–173) — now states "the **live
     registration is done** — once blocker B4 cleared (build loop iter 46), the
     cron was installed as the local `launchd` agent". The stale "it is gated
     on the B4 schema work" clause is gone.
  All three now agree with `config/offmarket_schedule.md` (Registration section,
  "REGISTERED — 2026-05-22 (build loop iter 46)") and with the live `launchctl`
  state confirmed in T3. An operator reading `skill.md` would now correctly
  conclude the weekly cron is live and B4 is resolved.

**Result: all 5 checks PASS.** Stage s9 → `self_checked`. One new finding —
**NIT-s9-3**: `references/orchestration.md` §5 (Dry-run / fixture mode, line
150) still says dry-run mode applies "For SELF-TEST (s9, s10) and any run while
B3/B4 are open" — B3 and B4 are both RESOLVED, so the "while B3/B4 are open"
clause is a stale reference to closed blockers. It does not misstate the
registered cron state (the T5 subject) and does not break anything — dry-run
mode is still legitimately used for SELF-TEST and the live-run boundary is
correctly governed by `OFFMARKET_BUILD_VERIFIED` elsewhere — so it is a NIT, not
a T5 failure. Logged for the RESOLVE phase; `unresolved_findings` 29 → 30. Next
phase for s9: VERIFY (fresh-context critic).
