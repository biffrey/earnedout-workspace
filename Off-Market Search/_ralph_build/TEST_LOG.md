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
