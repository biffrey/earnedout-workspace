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
