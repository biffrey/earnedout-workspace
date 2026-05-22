# Off-Market Build Loop — Findings

`BLOCKING` / `IMPROVE` / `NIT` findings raised by the per-stage critic subagent
and the final-audit auditor, with their resolutions. `unresolved_findings` in
`STATE.md` must always equal the count of open findings here.

## Open

### F1 — IMPROVE — s1 — non-standard Markdown comment delimiter
**Raised:** iter 3 VERIFY (s1 critic).
**Where:** `config/offmarket_sources.md` lines 10–12.
**Problem:** the "Built by stage s1" note uses a `/ … /` delimiter, which is not
valid Markdown comment syntax, so the text renders literally.
**Fix:** wrap the note in `<!-- … -->`.
**Status:** OPEN.

### F2 — NIT — s1 — literal placeholder string trips automated scans
**Raised:** iter 3 VERIFY (s1 critic).
**Where:** `config/offmarket_sources.md` line 7.
**Problem:** the line contains the literal string `⚠ VERIFY:` inside a negation
sentence ("No `⚠ VERIFY:` placeholders remain"); a future automated placeholder
scan could false-positive on it.
**Fix:** reword to avoid the literal token (e.g. describe it without quoting it).
**Status:** OPEN.

### NIT-s3-1 — NIT — s3 — SBIC CSV column label mismatch
**Raised:** iter 7 VERIFY (s3 critic).
**Where:** `.claude/skills/off-market-search/references/source_adapters.md:174`
(S4 adapter prose).
**Problem:** the S4 adapter prose says map the `"Managed by"` column, but the
live SBIC directory CSV header is actually named `Manager`. Mapping intent is
correct; the cited column label is wrong.
**Fix:** change `"Managed by"` to `Manager` in the S4 section.
**Status:** OPEN.

### IMPROVE-s3-1 — IMPROVE — s3 — S1 UEI not populated
**Raised:** iter 7 VERIFY (s3 critic).
**Where:** `.claude/skills/off-market-search/references/source_adapters.md`
(S1 USAspending adapter, Query block ~line 121).
**Problem:** `uei` — the primary s4 entity-resolution key — is not returned by
the USAspending `spending_by_award` endpoint, so S1 records currently resolve
only on name+address, weakening s4.
**Fix:** add a recipient-detail follow-up call
(`/api/v2/recipient/{recipient_id}/`) or request UEI in the `fields` list, so
S1 `RawRecord`s carry `uei`.
**Status:** OPEN.

### IMPROVE-s4-1 — IMPROVE — s4 — `dedup_verdict` enum omits `needs_operator_review`
**Raised:** iter 10 VERIFY (s4 critic).
**Where:** `.claude/skills/off-market-search/references/entity_resolution.md:36`.
**Problem:** the `dedup_verdict` field enum is `new` | `existing`, but §4 routes
identifier-less/address-less entities to a `needs_operator_review` state never
represented in the enum.
**Fix:** add `needs_operator_review` to the `dedup_verdict` enum, or note
explicitly that such entities are excluded before a verdict is assigned.
**Status:** OPEN.

### IMPROVE-s4-2 — IMPROVE — s4 — DUNS ladder exception not stated explicitly
**Raised:** iter 10 VERIFY (s4 critic).
**Where:** `.claude/skills/off-market-search/references/entity_resolution.md`
§2.1 (lines 89, 101).
**Problem:** the §6.1 ladder header says "first key that produces a match," but
the DUNS step adds an override ("never resolve solely on DUNS when a UEI is
available"). Correct behavior, but a non-obvious exception to first-match-wins.
**Fix:** state in §2.1 that DUNS is checked only after confirming neither record
carries a UEI, so the ladder semantics stay unambiguous.
**Status:** OPEN.

### IMPROVE-s4-3 — IMPROVE — s4 — self-test merge trace not shown
**Raised:** iter 10 VERIFY (s4 critic).
**Where:** `Off-Market Search/_ralph_build/evidence/s4-selftest.md` lines 28-29.
**Problem:** the self-test asserts R1's merged `naics`/`psc`/`award_total`
values without showing the per-field union derivation, so the spot-check is not
fully reproducible from the evidence alone.
**Fix:** add a one-line merge trace showing each field's union step.
**Status:** OPEN.

### IMPROVE-s4-4 — IMPROVE — s4 — S1 contributes zero resolvable entities until IMPROVE-s3-1 closes
**Raised:** iter 10 VERIFY (s4 critic).
**Where:** `Off-Market Search/_ralph_build/evidence/s4-selftest.md` lines 42-43.
**Problem:** because the USAspending adapter does not yet populate `uei`/address
(IMPROVE-s3-1), every S1 record routes to `needs_operator_review`. s4 handles
the thin input correctly, but the resolution-accuracy spot-check is effectively
only exercising the S2/S3 structural fixtures — the primary Class-1 discovery
source is never tested against the ≥95% target.
**Fix:** gate s10's larger-sample accuracy spot-check on IMPROVE-s3-1 being
closed, so the target is tested against real S1 data.
**Status:** OPEN.

### NIT-s4-1 — NIT — s4 — slash in example `entity_id`
**Raised:** iter 10 VERIFY (s4 critic).
**Where:** `.claude/skills/off-market-search/references/entity_resolution.md:206`.
**Problem:** the example `entity_id` `SBIC:09/79-0292` embeds a slash; harmless
in a plain-text `Gov Entity ID` field but mildly fragile as an identifier key.
**Fix:** optionally note that slashes in source license numbers are retained
verbatim, or normalize them in the `SBIC:` key.
**Status:** OPEN.

### IMPROVE-s5-1 — IMPROVE — s5 — screenshot path not filesystem-safe for `entity_id`
**Raised:** iter 13 VERIFY (s5 critic).
**Where:** `.claude/skills/off-market-search/references/enrichment.md:135`.
**Problem:** screenshot path is `output/screenshots/{entity-id}.png`, claimed to
match the `overnight-search` convention. But `overnight-search` uses a plain
alphanumeric `listing-id`, whereas the off-market `entity_id` is e.g.
`UEI:ZZTEST00FIX1` or `NAME:abacus finance group|new york ny` — containing `:`,
`|`, and spaces, which are illegal/fragile in filenames. Never exercised in the
self-test (R1 `screenshot_path` was `null`).
**Fix:** specify a slugified/sanitized form of `entity_id` for the filename
(replace `:`, `|`, spaces), or note the existing convention does not transfer.
**Status:** OPEN.

### IMPROVE-s5-2 — IMPROVE — s5 — Class-2 pre-filter §2.2 condition 2 is a no-op on first run
**Raised:** iter 13 VERIFY (s5 critic).
**Where:** `.claude/skills/off-market-search/references/enrichment.md:106-109`.
**Problem:** §2.2 condition 2 ("good standing not already disproven") depends on
the §4 cross-check, but §2 pre-filters run BEFORE §3/§4 enrichment. On a first
run the cross-check has not run, so the condition can only fire on a re-run —
it reads as a substantive gate that it is not on the first pass.
**Fix:** reword §2.2 condition 2 to state it applies only to a prior-run/cached
standing result; otherwise the candidate passes.
**Status:** OPEN.

### IMPROVE-s5-3 — IMPROVE — s5 — good-standing cross-check demonstrated for only one Class-2 entity
**Raised:** iter 13 VERIFY (s5 critic).
**Where:** `Off-Market Search/_ralph_build/evidence/s5-selftest.md` C6 (lines
133-155).
**Problem:** the §4 good-standing cross-check (WebSearch for adverse actions)
was demonstrably run only for R2; R3/R4 passed the pre-filter but the beyond-the-
directory cross-check was not shown for them.
**Fix:** s10's end-to-end run must repeat the §4 cross-check across all Class-2
entities; carry this forward to the s10 self-test.
**Status:** OPEN.

### NIT-s5-1 — NIT — s5 — s4 self-test provenance note cites the wrong record
**Raised:** iter 13 VERIFY (s5 critic).
**Where:** `Off-Market Search/_ralph_build/evidence/s4-selftest.md:29`.
**Problem:** R1's `psc [R608]` is described as coming "from rec 3-shape", but
record 3 is a different entity (an S1 record). Cosmetic provenance error in the
s4 evidence, carried implicitly into the s5 input description.
**Fix:** correct the provenance note to cite the actual contributing record.
**Status:** OPEN.

### NIT-s5-2 — NIT — s5 — `employee_count` type inconsistent with other unknown-able fields
**Raised:** iter 13 VERIFY (s5 critic).
**Where:** `.claude/skills/off-market-search/references/enrichment.md:53`.
**Problem:** `employee_count` is typed `number | string`, while every other
unknown-able field uses `... | null` plus the `"needs follow-up"` sentinel.
Cosmetic schema inconsistency.
**Fix:** align `employee_count` to the `number | null` + `"needs follow-up"`
pattern.
**Status:** OPEN.

## Resolved

### BLOCKING-s5-1 — BLOCKING — s5 — `gov_data_source` mapping invalid / table missing
**Raised:** iter 13 VERIFY (s5 critic).
**Where:** `.claude/skills/off-market-search/references/enrichment.md:64` and
`:231`; `evidence/s5-selftest.md:97`.
**Problem:** `LeadPacket.gov_data_source` was specified as `source_ids` "mapped to
the `Gov Data Source` Airtable choice (per `airtable_schema_preflight.md`)", but
no `source_id → choice` mapping table existed in that file. The self-test then
emitted `"SAM.gov Entity Management"`, which is NOT one of the eight live
`Gov Data Source` choices. Since multi-select choices auto-grow on write, the
wrong string would silently create a spurious 9th choice — violating "fail loud,
never silently create".
**Fix:** add an explicit `source_id → Gov Data Source choice` mapping table
using only the eight live choices; make `gov_data_source` fail-loud on an
unmapped `source_id`; correct the self-test choice strings.
**Resolution (iter 14, s5 IMPLEMENT):** added §5.1 to `enrichment.md` — a
`source_id → Gov Data Source` mapping table (S1→USAspending, S2→SAM.gov,
S3→SAM.gov Contract Awards, S4/S5→SBA SBIC, S6→SBS, S7→GSA eLibrary, S8→State,
S9→RID; S10/S11 enrichment-only, no choice) plus an explicit fail-loud rule
(an unmapped `source_id` halts the skill; the multi-select is never auto-grown).
Updated the `gov_data_source` rows in §1 and §5 to reference §5.1. Corrected
`s5-selftest.md` lines 97 (`["SAM.gov", "SAM.gov Contract Awards"]`) and 125
(`["SBA SBIC"]`) to live choices. **Status:** RESOLVED — s5 returns to the phase
ladder (re-SELF-TEST next).
