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
