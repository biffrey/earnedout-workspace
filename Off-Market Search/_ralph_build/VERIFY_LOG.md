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
