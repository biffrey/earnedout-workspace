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
