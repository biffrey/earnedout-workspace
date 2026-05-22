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
