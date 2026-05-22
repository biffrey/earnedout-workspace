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

### IMPROVE-s5-4 — IMPROVE — s5 — self-test C7 cites stale line numbers
**Raised:** iter 16 VERIFY (s5 critic, re-run).
**Where:** `Off-Market Search/_ralph_build/evidence/s5-selftest.md` lines 174 and
177 (C7).
**Problem:** C7 claims the R1 packet "Matches line 97 of this file" and the R2
packet "Matches line 125". After the iter-15 self-test rewrite, the actual
`gov_data_source` rows are at lines 104 and 132; lines 97/125 are unrelated rows
(`years_in_business`, `formation_date`). Stale iter-14 cross-references.
**Fix:** change "line 97" → "line 104" and "line 125" → "line 132", or drop the
line citations.
**Status:** OPEN.

### IMPROVE-s6-1 — IMPROVE — s6 — dangling `buy-box-and-scoring.md` reference
**Raised:** iter 19 VERIFY (s6 critic).
**Where:** `.claude/skills/off-market-search/references/scoring_integration.md:20`;
also `OFFMARKET_BUILD_PLAN.md:229` and `.claude/skills/off-market-search/skill.md:43`.
**Problem:** the s6 spec (and the build plan) cite
`.claude/skills/prospect-evaluation/references/buy-box-and-scoring.md` as a file
used verbatim by the scorer. That file does not exist on disk and never existed
in any commit — `prospect-evaluation/` contains only `skill.md`, with the buy-box
rubric embedded inside it. Not an s6 functional defect (the scorer ran fine),
but the off-market docs cite a non-existent companion file.
**Fix:** point the reference at `.claude/skills/prospect-evaluation/skill.md`
(or drop the `references/` path) in `scoring_integration.md`, `skill.md`, and the
build plan's constraints section.
**Status:** OPEN.

### IMPROVE-s6-2 — IMPROVE — s6 — both scored candidates are build-loop test inputs
**Raised:** iter 19 VERIFY (s6 critic).
**Where:** `Off-Market Search/_ralph_build/evidence/s6-selftest.md`;
`output/reports/uei-zztest00fix1/`.
**Problem:** R1 is a synthetic fixture (`_fixture_note` in its packet) and R2 is
a real SBIC; s6's integration plumbing is fully exercised, but neither captured
report is a genuine real-company Class-1 ASL/CART assessment. The real Class-1
end-to-end score is deferred to s10, gated on the S1 USAspending `uei` gap.
**Fix:** s10's larger-sample end-to-end run must score at least one real Class-1
ASL/CART company; gate that on IMPROVE-s3-1 / IMPROVE-s4-4 closing.
**Status:** OPEN.

### NIT-s6-1 — NIT — s6 — self-test cites a stale score line number
**Raised:** iter 19 VERIFY (s6 critic).
**Where:** `Off-Market Search/_ralph_build/evidence/s6-selftest.md:18`.
**Problem:** the self-test cites the R1 score lines as `report.md:29,64,70`, but
the breakdown total is at line 85, not 70. The score itself (30/110) is correct
and internally consistent; only the line citation is off.
**Fix:** change `70` → `85` in the C1 evidence citation.
**Status:** OPEN.

### NIT-s6-2 — NIT — s6 — `prospect-evaluation/skill.md` has owner-only file mode
**Raised:** iter 19 VERIFY (s6 critic).
**Where:** `.claude/skills/prospect-evaluation/skill.md`.
**Problem:** the file mode is `-rw-------` (owner-only), inconsistent with the
other skill files. Harmless and pre-existing (not caused by the s6 build).
**Fix:** optionally `chmod 644` for consistency; no functional impact.
**Status:** OPEN.

### IMPROVE-s8-1 — IMPROVE — s8 — OM-2 drafted to a non-principal contact
**Raised:** iter 24 VERIFY (s8 critic).
**Where:** `config/offmarket_outreach_template.md` (OM-2 body) and
`.claude/skills/off-market-search/references/outreach_drafting.md`.
**Problem:** the OM-2 fixed body addresses the recipient "as a principal", but
the contact gate accepts any direct contact (name OR email). In the self-test,
R2's only enriched contact was titled "Investor Relations", not a GP managing
principal — a tone mismatch. Not fabrication (it uses the only real contact
available) and not a Done-when breach, but worth tightening.
**Fix:** when the Class-2 contact title is not principal-level, either prefer a
principal-titled contact during s5 enrichment or soften the OM-2 body wording.
**Status:** OPEN.

### NIT-s8-1 — NIT — s8 — stray trailing tokens in s8 evidence files
**Raised:** iter 24 VERIFY (s8 critic).
**Where:** `evidence/s8-selftest.md:238-239` and
`evidence/s8-offmarket_outreach_drafts_2026-05-22.md:106`.
**Problem:** stray trailing `</content>` / `</invoke>` artifact-formatting
tokens leaked into the evidence files. Cosmetic; does not affect deliverables.
**Fix:** strip the trailing tokens from the two evidence files.
**Status:** OPEN.

### NIT-s9-1 — NIT — s9 — `dedup_verdict` enum omits the third hand-off state
**Raised:** iter 27 VERIFY (s9 critic).
**Where:** `references/orchestration.md:26` vs.
`references/entity_resolution.md:61`.
**Problem:** the §1 hand-off table lists Step 3 output tags as
`new / existing / needs_operator_review`, but `entity_resolution.md:61` types
the `dedup_verdict` field as only `new | existing`. `needs_operator_review` is
real (`entity_resolution.md:188`) but is a run-log/exclusion status, not a
`dedup_verdict` enum value. Cosmetic; does not break the hand-off (needs-review
entities are excluded from the write, not passed downstream).
**Fix:** tighten the `dedup_verdict` type union or add a footnote distinguishing
the enum from the exclusion status.
**Status:** OPEN.

### NIT-s9-2 — NIT — s9 — dry-run run log omits enrichment-only sources
**Raised:** iter 27 VERIFY (s9 critic).
**Where:** `evidence/s9-offmarket_run_log_dryrun.md` "Sources queried" table.
**Problem:** S5/S6/S7 source rows from `config/offmarket_sources.md` are omitted
from the dry-run log's "Sources queried" table. Acceptable for a fixture
exercise, but a live run should list every source attempted.
**Fix:** in a live run, list every source queried (including enrichment-only
sources) in the run-log table.
**Status:** OPEN.

### NIT-s10-1 — NIT — s10 — reused fixture artifacts carry stale stage-provenance labels
**Raised:** iter 30 VERIFY (s10 critic).
**Where:** `output/reports/uei-zztest00fix1/lead-packet.json` `_fixture_note`
and the R1 report headers.
**Problem:** the R1 fixture artifacts label their provenance "stage s6
SELF-TEST"; they are now reused as the s10 dry-run inputs, so the provenance
labels lag the current stage. Harmless.
**Fix:** when fixture artifacts are reused across stages, note the reuse (or
add an s10-reuse line) so provenance labels do not mislead.
**Status:** OPEN.

_(The critic also flagged a stray `</content>` tag at
`evidence/s8-offmarket_outreach_drafts_2026-05-22.md:106`; this is already
tracked as NIT-s8-1 — not double-counted here.)_

### IMPROVE-s3-2 — IMPROVE — s3 — state-source adapter (S8) is a fixture-shell; B1 now resolved
**Raised:** 2026-05-22, operator intervention (B1 resolved).
**Where:** s3 source-adapter deliverable — the S8 (state portals / SOS) adapter;
`config/offmarket_sources.md` state-source entries.
**Problem:** s3 was verified while B1 was open, so S8 was built as a
fixture-shell rather than a working adapter (IMPLEMENTATION_LOG iter 5: "S8
state portals (`blocked` B1, shell ...)"). B1 is now resolved with the Phase-1
priority jurisdictions **DC, VA, MD, PA, WV**.
**Fix:** build the S8 adapter for real against each of the five jurisdictions'
eProcurement portal and Secretary-of-State / business registry; confirm and
document each portal's ToS and rate limits before automating (per BLOCKERS.md
B1); record a live or recorded-fixture query per jurisdiction. Keep the common
adapter interface unchanged so s4–s6 are unaffected.
**Status:** OPEN.

### IMPROVE-s5-5 — IMPROVE — s5 — SOS formation-date lookup not wired; B1 now resolved
**Raised:** 2026-05-22, operator intervention (B1 resolved).
**Where:** s5 enrichment deliverable — the B1-gated Secretary-of-State
formation-date lookup.
**Problem:** s5 was verified while B1 was open, so the SOS formation-date /
years-in-business lookup was left as a logged gap rather than a working lookup
("B1-blocked SOS leaves a gap" in the s5 implementation notes). B1 is now
resolved (DC, VA, MD, PA, WV).
**Fix:** wire the SOS formation-date lookup for the five priority jurisdictions
so a candidate registered in one of them gets a real formation date /
years-in-business instead of a "needs follow-up" gap. Candidates in other
states remain a logged gap, as designed.
**Status:** OPEN.

### IMPROVE-s3-3 — IMPROVE — s3 — SAM.gov adapters (S2/S3) are fixture-shells; B3 now resolved
**Raised:** 2026-05-22, operator intervention (B3 resolved — key stored).
**Where:** s3 source-adapter deliverable — the S2 (SAM.gov Entity Management
API) and S3 (SAM.gov Contract Awards API) adapters.
**Problem:** s3 was verified while B3 was open, so S2/S3 were built as
fixture-shells rather than working adapters (IMPLEMENTATION_LOG iter 5:
"B1/B3 adapters built but marked `blocked`, not faked"). B3 is now resolved —
the SAM.gov Public API Key is stored in the macOS login keychain.
**Fix:** wire S2/S3 to read the key at runtime via
`security find-generic-password -s samgov-api-key -a off-market-search -w`
(never commit it to a file), send it as the `x-api-key` header, and build the
adapters for real against `api.sam.gov`; record a live or recorded-fixture
query for each. Handle the one-time keychain "Always Allow" prompt, and respect
the per-account daily request limit (~10/day on the public tier until SAM.gov
entity registration completes for the ~1,000/day tier). Keep the common adapter
interface unchanged so s4–s6 are unaffected.
**Status:** OPEN.

### IMPROVE-s10-3 — IMPROVE — s10 — dry-run artifacts cite resolved blockers as open
**Raised:** iter 40 SELF-TEST (s10 re-run).
**Where:** `Off-Market Search/_ralph_build/evidence/s10-e2e-dryrun.md`
(Step 1, "Known limitations" 1–3) and
`evidence/s10-offmarket_run_log_e2e_dryrun.md` (lines 13–14, 20–23, 46, 66–68).
**Problem:** the s10 dry-run artifacts were produced at iter 28 / re-IMPLEMENT
iter 31, before the operator resolved B1–B4 on 2026-05-22. They still state
"Open blockers affecting this run: B1, B3, B4", attribute S2/S3 fixture usage to
"blocked (B3)" and S8 to "blocked (B1)", and assert "a live run would HALT here
(fail-loud, B4)" at the Step 1 preflight. All four blockers are now RESOLVED
(`BLOCKERS.md`); `open_blockers: 0`. The fixture usage itself is still correct —
the SAM and state adapters remain fixture-shells — but that is now governed by
the still-open `IMPROVE-s3-2` / `IMPROVE-s3-3` / `IMPROVE-s5-5` adapter-rebuild
findings, not by the closed blockers. Not a fabrication and not an s10
`Done-when` breach (the dry run still produces ≥1 scored record per class with
no fabricated fields), but the stale attribution would mislead the FINAL AUDIT.
**Fix:** refresh `s10-e2e-dryrun.md` and `s10-offmarket_run_log_e2e_dryrun.md`
to re-attribute the SAM/state fixture usage to `IMPROVE-s3-2`/`-s3-3`/`-s5-5`,
remove the "live run halts at preflight (B4)" claim (B4 is resolved; the live
preflight now passes — confirmed by the iter-38 s7 live write
`recklDY7vHFmKauQD`), and update "Known limitations" 1–3. Best done as part of
the s10 re-IMPLEMENT that the adapter-rebuild findings will require, or in the
RESOLVE phase.
**Status:** OPEN.

### IMPROVE-s10-4 — IMPROVE — s10 — outreach-drafts file header still labels itself an s8-only artifact
**Raised:** iter 41 VERIFY (s10 critic).
**Where:** `Off-Market Search/_ralph_build/evidence/s8-offmarket_outreach_drafts_2026-05-22.md`
line 3 (file header).
**Problem:** the drafts file header calls itself a "BUILD-LOOP s8 SELF-TEST
ARTIFACT", but the file is also the outreach-draft deliverable the s10 end-to-end
dry run depends on (Step 7). The label lags the artifact's reuse — the same
stale-provenance class as NIT-s10-1 / IMPROVE-s10-3.
**Fix:** add an s10-reuse note to the header, or relabel it as shared s8/s10
evidence. Best done with the IMPROVE-s10-3 artifact refresh.
**Status:** OPEN.

## Resolved

### BLOCKING-s10-2 — BLOCKING — s10 — R2 OM-2 outreach draft asserts an operating history the packet flags as a null gap
**Raised:** iter 41 VERIFY (s10 critic).
**Where:** `Off-Market Search/_ralph_build/evidence/s8-offmarket_outreach_drafts_2026-05-22.md`
lines 85-86 (the OM-2 draft for 1st Source Capital Corporation).
**Problem:** the OM-2 draft body asserted "1st Source Capital Corporation has
operated as a licensed SBIC pursuing a direct-lending strategy **since 1983** —
a long, durable track record in the program." But the R2 lead packet
(`output/reports/name-1st-source-capital-south-bend-in/lead-packet.json`) sets
`formation_date: null` and `years_in_business: null`, and lists `"formation date
— needs follow-up (B1)"` as an enrichment gap. The `1983` value is
`sbic_gp_economics.vintage` — the SBIC **fund's** vintage year — not a verified
company operating-start / formation date. The R2 report bodies were explicitly
corrected in iter 31 (BLOCKING-s10-1) never to assert this; the outreach draft —
a deliverable of the same s10 end-to-end dry run (Step 7) — still did. This was
the same fabrication defect class as BLOCKING-s10-1 recurring in the outreach
artifact.
**Resolution (iter 42, s10 re-IMPLEMENT):** rewrote the OM-2 draft
`[SPECIFIC_DETAIL]` sentence to "1st Source Capital Corporation is a licensed
SBIC in good standing, pursuing a direct-lending investment strategy — exactly
the kind of platform I follow closely" — both facts (`sbic_license_status:
"Good Standing"`, `sbic_gp_economics.strategy: "Direct Lending"`) verified in
the R2 packet; the fabricated "since 1983" start year and the track-record
claim derived from it are removed. Hardened `config/offmarket_outreach_template.md`
(OM-2 `[SPECIFIC_DETAIL]` placeholder no longer lists "license vintage"; an
explicit rule states `sbic_gp_economics.vintage` is the fund's vintage, never
a company formation date / years-in-business, and may never be rendered as an
operating-start or track-record-length claim) and
`.claude/skills/off-market-search/references/outreach_drafting.md` (§2 step 5
and a new §5 edge bullet carry the same prohibition). **Status:** RESOLVED —
s10 returns to the phase ladder (re-SELF-TEST next; the SELF-TEST must read the
outreach drafts field-by-field against each packet).

### BLOCKING-s7-1 — BLOCKING — s7 — `Lead Source` mapping invalid against the live field type
**Raised:** iter 36 SELF-TEST (s7).
**Where:** `.claude/skills/off-market-search/references/airtable_write.md` §3.1,
the `Lead Source (fldI1h3qmNI6vc5rr)` row.
**Problem:** §3.1 maps `Lead Source` to "the gov source system(s) the target
came from (human-readable, e.g. `"USAspending.gov; SAM.gov"`)" — a free-text
string. But a live `get_table_schema` read shows `Lead Source`
(`fldI1h3qmNI6vc5rr`) is a **singleSelect** restricted to 14 broker-platform
options (`Direct Outreach`, `Broker`, `Referral`, `Conference`, `BizBuySell`,
`BizQuest`, `Axial`, `Grata`, `DealStream`, `Trade-A-Plane`, `LinkedIn`,
`Other Platform`, `General Web`, `BusinessBroker.net`). A live
`create_records_for_table` per §3 was rejected atomically with `HTTP 422:
Insufficient permissions to create new select option` — so no off-market row
can be written by the procedure as written, and auto-creating an option is
forbidden by the build constraints (fail loud, never silently create). The
central s7 `Done-when` (a live row in `tblSmNrHROMLm7vOS`) cannot be met until
this is fixed.
**Fix:** change the §3.1 `Lead Source` mapping for off-market rows — leave the
field **blank** (the gov provenance is already carried by the dedicated
`Gov Data Source` multi-select and the `Links` field), or map it to an existing
singleSelect option (e.g. `Direct Outreach`). Do not auto-create a select
option. Then re-run the s7 SELF-TEST including the live write of R2.
**Resolution (iter 37, s7 re-IMPLEMENT):** rewrote the §3.1 `Lead Source` row —
the off-market value is **blank**, with the row stating `Lead Source` is a
singleSelect restricted to the 14 broker-platform options and that gov
provenance is carried by the `Gov Data Source` multi-select (§3.3) and the
source URL(s) in `Links` (§3.1). Leaving it blank loses no information. Also
hardened §6 with a new bullet — "Never auto-create a select option on any
field" — naming the exact 422 failure mode and the rule (map to existing
options or leave blank). **Status:** RESOLVED — s7 returns to the phase ladder
(re-SELF-TEST next; the SELF-TEST must re-attempt the live `create_records_for_table`
of R2 with `Lead Source` blank and confirm the row lands).

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

### BLOCKING-s10-1 — BLOCKING — s10 — Class-2 report awards points from a field its own packet lists as a gap
**Raised:** iter 30 VERIFY (s10 critic).
**Where:** `output/reports/name-1st-source-capital-south-bend-in/1st-source-capital-corporation-report.md`
(and the matching `.html`); contradicted
`output/reports/name-1st-source-capital-south-bend-in/lead-packet.json:11-12,34`.
**Problem:** the R2 lead packet sets `formation_date: null`,
`years_in_business: null`, and enumerates `"formation date — needs follow-up
(B1)"` in `enrichment_gaps`. The report declared that packet its sole input yet
Buy Box line 3 returned `✅ PASS` ("incorporated in Indiana on 1983-11-16") and
the Lead Score Breakdown awarded **10/10** for "Years in business ≥10" — 10 of
R2's 30 points — from a formation date, street address, SEC CIK, and CB Insights
data absent from the packet. Back-filled a gap the scorer must pass through as
missing (`scoring_integration.md:91-92,99`); packet and report contradicted each
other on disk.
**Resolution (iter 31, s10 re-IMPLEMENT):** re-scored R2 **strictly from
`lead-packet.json`** — Buy Box line 3 and the years-in-business rubric line are
now ⚠️ "insufficient data — not awarded" (0/10); R2's honest score is **20/100**,
not 30. Rewrote both `1st-source-capital-corporation-report.md` and `.html` so
every value traces to the packet — stripped the formation date, street address,
parent-company identity/financials, SEC EDGAR, CB Insights, and Wikipedia data;
Appendix A now lists only the SBA SBIC directory and the `LeadPacket`. The SBIC
fund vintage (1983) is retained only as informational fund-level data per
§3.1, not mapped to years-in-business. `lead-packet.json` was not modified (it
was already clean). Updated `s10-e2e-dryrun.md` and
`s10-offmarket_run_log_e2e_dryrun.md` to R2 = 20/100. **Status:** RESOLVED —
s10 returns to the phase ladder (re-SELF-TEST next; the SELF-TEST must read the
report bodies field-by-field against the packet).

### IMPROVE-s10-1 — IMPROVE — s10 — run log cites a production path for a dry-run file
**Raised:** iter 30 VERIFY (s10 critic).
**Where:** `evidence/s10-offmarket_run_log_e2e_dryrun.md:53`;
`evidence/s10-e2e-dryrun.md` Step 7.
**Problem:** the run log cited the outreach drafts at the production path
`search_reports/offmarket_outreach_drafts_2026-05-22.md`, but the file exists
only at `_ralph_build/evidence/s8-offmarket_outreach_drafts_2026-05-22.md`.
**Resolution (iter 31, s10 re-IMPLEMENT):** relabelled the run-log and
`s10-e2e-dryrun.md` lines as the dry-run/evidence path, with an explicit note
that a live run writes `search_reports/offmarket_outreach_drafts_<date>.md`.
**Status:** RESOLVED.

### IMPROVE-s10-2 — IMPROVE — s10 — Class-2 scored count omits carried-but-unscored R3/R4
**Raised:** iter 30 VERIFY (s10 critic).
**Where:** `evidence/s10-offmarket_run_log_e2e_dryrun.md` "Enrichment & scoring".
**Problem:** R3/R4 passed the pre-filter as Class-2 candidates but were never
scored (only R2 was); the run log's scored-count line did not state it.
**Resolution (iter 31, s10 re-IMPLEMENT):** the run log's "Scored — Class 2"
line now states R3/R4 were carried as Class-2 candidates but not scored in the
dry run (only R2 was scored as the representative Class-2 lead).
**Status:** RESOLVED.
