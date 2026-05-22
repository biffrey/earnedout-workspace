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
