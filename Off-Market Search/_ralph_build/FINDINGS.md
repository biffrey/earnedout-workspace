# Off-Market Build Loop — Findings

`BLOCKING` / `IMPROVE` / `NIT` findings raised by the per-stage critic subagent
and the final-audit auditor, with their resolutions. `unresolved_findings` in
`STATE.md` must always equal the count of open findings here.

## Open

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

### NIT-s9-4 — NIT — s9 — frozen s9 dry-run evidence run log lists B4 as an open blocker
**Raised:** iter 50 VERIFY (s9 critic).
**Where:** `Off-Market Search/_ralph_build/evidence/s9-offmarket_run_log_dryrun.md`
lines 11-12 ("Open blockers" / "a live run would halt at Step 1 preflight") and
line 53 (the "B4 — add the two off-market `Source` values" operator follow-up).
**Problem:** this frozen iter-26 s9 SELF-TEST dry-run evidence run log still
lists B4 as an open blocker and carries a B4 operator follow-up. B4 is RESOLVED
(`BLOCKERS.md`; `open_blockers: 0`) — the two off-market `Source` values are
live and the Step 1 preflight now passes (confirmed by the iter-38 s7 live
write `recklDY7vHFmKauQD`). Same stale-blocker class as IMPROVE-s10-3 /
IMPROVE-s10-4 / NIT-s9-3. Not BLOCKING: this is a frozen SELF-TEST artifact
documenting the state at the time it was produced, not a skill/spec deliverable
or a live run log — and the s9 Done-when criteria are all met.
**Fix:** add a note that the artifact is frozen at iter-26 state, or refresh
the "Open blockers" / operator-follow-up lines to re-attribute the fixture
usage to the still-open `IMPROVE-s3-2`/`-s3-3`/`-s5-5` adapter-rebuild findings.
Best done in the RESOLVE phase alongside IMPROVE-s10-3 and NIT-s9-3.
**Status:** OPEN.

## Resolved

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
**Resolution (iter 76, RESOLVE):** chose the footnote fix. Reworded the §1
hand-off table Step 3 "Produces" cell in `orchestration.md` so it no longer
presents `needs_operator_review` as a third `dedup_verdict` tag — it now reads
`CanonicalEntity[]`, each carrying `dedup_verdict` `new` / `existing`, with
identifier-and-address-less entities excluded as `needs_operator_review` and a
`[†]` marker. Added the matching `[†]` footnote immediately after the table: it
states Step 3 produces exactly two `dedup_verdict` values (`new`, `existing`),
that only an entity surviving §2 resolution is assigned one
(cross-referencing `entity_resolution.md:61`), and that `needs_operator_review`
is the run-log exclusion status (`entity_resolution.md` §4) applied before §3
dedup runs — never passed downstream, since Step 4 consumes only `new` entities.
This aligns `orchestration.md` with the `entity_resolution.md:61` note already
added by the IMPROVE-s4-1 resolution (iter 56). Spec-text clarity only; no
orchestration, resolution, or dedup behavior changed — needs-review entities
were already excluded from the write, not handed downstream. s9 stays
`verified`.
**Status:** RESOLVED.

### NIT-s9-3 — NIT — s9 — dry-run mode passage cites resolved blockers B3/B4 as open
**Raised:** iter 49 SELF-TEST (s9 re-run).
**Where:** `.claude/skills/off-market-search/references/orchestration.md` §5
(Dry-run / fixture mode), line 150.
**Problem:** §5 said dry-run mode applies "For SELF-TEST (s9, s10) and any run
while B3/B4 are open". B3 and B4 are both RESOLVED (`BLOCKERS.md`;
`open_blockers: 0`), so the "while B3/B4 are open" clause was a stale reference
to closed blockers. Same stale-attribution class as IMPROVE-s10-3 /
IMPROVE-s10-4. It did not misstate the registered cron state and did not break
anything — dry-run mode is still legitimately used for SELF-TEST, and the
live-run boundary is correctly governed by `OFFMARKET_BUILD_VERIFIED` — so it
was a NIT.
**Resolution (iter 75, RESOLVE):** rewrote the §5 opening sentence of
`orchestration.md`. The stale "and any run while B3/B4 are open" clause is
dropped; the sentence now reads dry-run mode applies "For SELF-TEST (s9, s10) —
and for any run that must avoid spending a quota-limited source's live request
budget (e.g. the SAM.gov public ~10/day tier) or that would query a state
portal whose per-jurisdiction ToS is not yet confirmed". This re-attributes
fixture/dry-run usage to its real current reasons — the same non-blocker
reasons the iter-73 IMPROVE-s10-3 resolution gave for the s10 dry-run fixture
use (the now-resolved `IMPROVE-s3-2`/`-s3-3`/`-s5-5` adapter-rebuild findings
having documented those reasons before they closed). Spec-text clarity only; no
orchestration, adapter, or write behavior changed — dry-run mode is still used
for SELF-TEST and the live-run boundary is unchanged. s9 stays `verified`.
**Status:** RESOLVED.

### IMPROVE-s10-4 — IMPROVE — s10 — outreach-drafts file header still labels itself an s8-only artifact
**Raised:** iter 41 VERIFY (s10 critic).
**Where:** `Off-Market Search/_ralph_build/evidence/s8-offmarket_outreach_drafts_2026-05-22.md`
line 3 (file header).
**Problem:** the drafts file header calls itself a "BUILD-LOOP s8 SELF-TEST
ARTIFACT", but the file is also the outreach-draft deliverable the s10 end-to-end
dry run depends on (Step 7). The label lags the artifact's reuse — the same
stale-provenance class as NIT-s10-1 / IMPROVE-s10-3.
**Resolution (iter 74, RESOLVE):** rewrote the file header callout box of
`evidence/s8-offmarket_outreach_drafts_2026-05-22.md`. The opening line now reads
"BUILD-LOOP SHARED s8 / s10 EVIDENCE ARTIFACT" instead of "BUILD-LOOP s8
SELF-TEST ARTIFACT", and the box body states the file was first produced by the
s8 SELF-TEST and is reused as the outreach-draft deliverable of the s10
end-to-end dry run (Step 7), cross-referencing `evidence/s10-e2e-dryrun.md`.
Added an explicit iter-74 s10-reuse note recording that the OM-2 draft body was
corrected at iter 42 (BLOCKING-s10-2) so it asserts no operating history the R2
packet lists as a null gap — so the header no longer lags the artifact's
cross-stage reuse. Evidence-header relabel only; no draft content, no skill
code, spec, or write behavior changed — the drafts themselves are unchanged and
remain DRAFT ONLY. s10 stays `verified`.
**Status:** RESOLVED.

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
the SAM and state adapters used recorded fixtures — but that is now governed by
the `IMPROVE-s3-2` / `IMPROVE-s3-3` / `IMPROVE-s5-5` adapter-rebuild findings,
not by the closed blockers. Not a fabrication and not an s10 `Done-when` breach
(the dry run still produces ≥1 scored record per class with no fabricated
fields), but the stale attribution would mislead the FINAL AUDIT.
**Resolution (iter 73, RESOLVE):** refreshed both s10 dry-run evidence artifacts.
In `s10-e2e-dryrun.md`: added an iter-73 refresh note to the dry-run callout box
recording that B1–B4 are resolved and the adapter-rebuild findings
IMPROVE-s3-2/-s3-3/-s5-5 (since RESOLVED iters 68–71) now govern the fixture
usage; rewrote Step 1 to drop the "a live run would HALT here (B4)" claim and
state the `Source` single-select now holds all four choices so the preflight
passes (confirmed by the iter-38 s7 live write `recklDY7vHFmKauQD`); re-attributed
Step 2's S2/S3 "blocked B3" / S8 "blocked B1" lines to the now-resolved
adapter-rebuild findings with the real reason for fixture use (conserve the
quota-limited SAM.gov tier; S8 live query gated on per-jurisdiction ToS
confirmation); updated the Step 3 dedup B4 reference, the Step 6 "B4 preflight
halt" wording, and the Step 7 "B4-degraded" wording; and rewrote "Known
limitations" 1–3 from open-blocker items to current non-blocker reasons for
fixture use, with item 4 updated for IMPROVE-s3-1/-s4-4 now being RESOLVED. In
`s10-offmarket_run_log_e2e_dryrun.md`: changed "Outcome" and "Open blockers
affecting this run" (now "none", with a refresh note), the "Sources queried"
S2/S3/S8 status column (`blocked (B3)`/`(B1)` → `fixture` with re-attributed
notes), the "Airtable writes" B4-halt line, and the "Follow-ups for the
operator" B1/B3/B4 bullets (removed — all resolved). Evidence-refresh only; no
skill code, spec, scoring, or write behavior changed — the dry run still
produces ≥1 scored record per class with no fabricated field, and s10 remains
`verified`.
**Status:** RESOLVED.

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
**Resolution (iter 72, RESOLVE):** IMPROVE-s3-1 is now resolved (iter 55 — the
S1 USAspending adapter populates a real `uei` via the
`recipient/{recipient_id}` follow-up step), so the gate's precondition has
cleared and the gate can be made explicit. Added an **"S1 coverage gate"**
paragraph to §6 ("Resolution-accuracy spot-check") of
`.claude/skills/off-market-search/references/entity_resolution.md`: it records
that the s4 SELF-TEST sample exercised only the S2/S3/S4 fixtures (every S1
record fell to `needs_operator_review` while IMPROVE-s3-1 was open), notes that
finding is resolved, and **requires s10's larger-sample accuracy spot-check to
include real S1-sourced resolution clusters** once a live S1 query has run, so
the ≥95% resolution / <5% duplicate targets are measured against live
USAspending data and recorded in `TEST_LOG.md`. Also refreshed the stale
"Caveat" bullet in `evidence/s4-selftest.md` — it cited "once B3 (SAM.gov key)
clears" (B3 is resolved and was never the real gate); it now correctly
attributes the gap to IMPROVE-s3-1 and points at the §6 S1-coverage gate.
Spec-clarity / evidence change only; no resolution, dedup, or merge behavior
changed — the gate is documentation of what s10's live spot-check must cover.
**Status:** RESOLVED.

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
**Resolution (iter 71, RESOLVE):** rewrote §3.2 of
`.claude/skills/off-market-search/references/enrichment.md` from a B1-gated
"skip the lookup" placeholder to a wired SOS formation-date lookup:
- **Phase-1 scope** — the lookup now **runs** for any entity whose canonical
  `address.state` is one of the five B1-resolved jurisdictions (DC, VA, MD, PA,
  WV), driving the matching s3 adapter **S8** SOS / business-registry surface,
  each named with its concrete host (DC DLCP CorpOnline `corponline.dc.gov`; VA
  SCC CIS `cis.scc.virginia.gov`; MD SDAT / Maryland Business Express
  `egov.maryland.gov/businessexpress`; PA Dept. of State `file.dos.pa.gov`; WV
  SOS `apps.sos.wv.gov/business/corporations`). The lookup runs under the S8
  per-jurisdiction **ToS gate** (`robots.txt` honored, official export/API
  preferred over UI, ≤1 req/2s, no login/paywall bypass); a name lookup on
  `legal_name` + city resolves the record → `formation_date`, `sos_status`,
  officers (→ §3.4 contact discovery).
- **Out-of-Phase-1 entity** — the lookup is skipped by design with
  `formation_date`/`years_in_business` `null` and the gap reworded to drop the
  now-resolved B1 reference: `"formation date — needs follow-up (state SOS not
  in Phase-1 scope)"`.
- **In-scope but no match / registry skipped by the ToS gate** — a distinct gap
  (`"… (SOS lookup returned no match)"` / `"… (state registry skipped this run
  — ToS unconfirmed)"`); never fabricate a formation date.
- `years_in_business = current_year − formation_year` only when a date is found.
Also updated the file intro paragraph (state SOS / portals are "in Phase 1,
with the B1-resolved priority jurisdictions wired into the §3.2 SOS lookup")
and the §6 edge-handling bullet ("State SOS unreachable, out of Phase-1 scope,
or skipped by the ToS gate") to drop the stale "B1 unresolved" wording. Wires
the deliverable IMPROVE-s3-2 (the S8 adapter) made available last iteration;
no fabrication path is introduced — every not-found case stays a logged gap.
**Status:** RESOLVED.

### IMPROVE-s5-2 — IMPROVE — s5 — Class-2 pre-filter §2.2 condition 2 is a no-op on first run
**Raised:** iter 13 VERIFY (s5 critic).
**Where:** `.claude/skills/off-market-search/references/enrichment.md:106-109`.
**Problem:** §2.2 condition 2 ("good standing not already disproven") depends on
the §4 cross-check, but §2 pre-filters run BEFORE §3/§4 enrichment. On a first
run the cross-check has not run, so the condition can only fire on a re-run —
it reads as a substantive gate that it is not on the first pass.
**Fix:** reword §2.2 condition 2 to state it applies only to a prior-run/cached
standing result; otherwise the candidate passes.
**Resolution (iter 70, RESOLVE):** reworded §2.2 condition 2 in
`enrichment.md` to state explicitly that it checks only a *prior-run or cached*
§4 good-standing result: the §2 pre-filter runs **before** the §3/§4 enrichment
of the current run, so on a first run no §4 cross-check has executed yet and
there is nothing to disprove — the candidate passes. A cached / prior-run
`Revoked` / `Surrendered` standing drops the candidate here; otherwise (no
cached standing, or an *unconfirmed* standing) it passes the pre-filter, the §4
cross-check then runs in this run's enrichment, and the scorer's SBIC gate
handles an unconfirmed standing as CONDITIONAL (§7.3). Spec-clarity only; no
pre-filter, enrichment, or scoring behavior changed — an unconfirmed standing
already passed the pre-filter and the §4 cross-check already runs as enrichment.
**Status:** RESOLVED.

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
**Resolution (iter 69, RESOLVE):** rewrote the S8 adapter section of
`.claude/skills/off-market-search/references/source_adapters.md` from a
fixture-shell to a working adapter:
- **Header** changed from "BLOCKED by B1" to "B1 RESOLVED — DC, VA, MD, PA, WV".
- **Phase-1 jurisdiction table** — names the two surfaces per jurisdiction with
  concrete portal hosts: DC (`contracts.ocp.dc.gov` / `opendata.dc.gov`;
  `corponline.dc.gov`), VA (`eva.virginia.gov`; `cis.scc.virginia.gov`), MD
  (`emma.maryland.gov`; `egov.maryland.gov/businessexpress`), PA
  (`emarketplace.state.pa.us`; `file.dos.pa.gov`), WV (`wvpurchasing.gov`;
  `apps.sos.wv.gov/business/corporations`).
- **ToS confirmation (B1 mandate)** — a per-jurisdiction runtime gate: before
  the first automated request the adapter fetches/honors `robots.txt`, reads the
  portal's Terms of Use, **prefers** an official open-data export / API over UI
  scraping, paces ≤1 req/2s with no concurrency, and never extracts behind a
  login/paywall. A jurisdiction whose ToS prohibits automation or cannot be
  confirmed is **skipped** (`status: degraded`, per-jurisdiction `notes`) — never
  scraped, never a hard halt.
- **Query** — eProcurement keyword search (the `config/offmarket_sources.md`
  Class-1 keyword strategy, scoped to courts / public-education / voc-rehab
  buyers) + a per-candidate SOS name lookup for formation date / status /
  officers.
- **Map** — vendor name→`legal_name`, address→`address`, contract title/agency/
  value→`source_payload` (award $→`award_total` only when portal-published),
  SOS formation date/status/officers→`source_payload` (feeds s4 resolution and
  the s5 SOS lookup, IMPROVE-s5-5); state portals carry no UEI/CAGE so
  `uei`/`cage_code`/`duns` stay `null` and s4 resolves on name+address.
- **Status** semantics — `ok` / `degraded` / `error`; **never `blocked`** (B1
  resolved). Registry table row updated `blocked (B1) — shell only` →
  `ok (B1 resolved — DC/VA/MD/PA/WV; per-jurisdiction ToS gate)`. The
  `AdapterMeta.blocker_id` example row was genericized off the now-resolved
  `B1`/`B3` literals.
- **Recorded-fixture query** — added `_ralph_build/evidence/s3-fixtures/S8.json`,
  a structural fixture with one sample record per jurisdiction (DC, VA, MD, PA,
  WV) in the eProcurement + SOS shape, plus a fixtures-`README.md` row. No live
  state-portal call was made this iteration — each of the five portals' ToS must
  be confirmed first (the B1 mandate), which a headless run cannot complete; the
  adapter is spec-complete and the per-jurisdiction ToS gate + fixture fallback
  are documented for the live run.
- `config/offmarket_sources.md` S8 entry — status changed from "blocked by B1"
  to "not blocked (B1 resolved)" with the five jurisdictions' portals listed.
The common adapter interface (`adapter.query` → `{records, meta}`, the
`RawRecord` shape) is unchanged, so s4–s6 are unaffected. The B1-gated s5 SOS
formation-date lookup remains separately tracked as the still-open
`IMPROVE-s5-5`.
**Status:** RESOLVED.

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
**Resolution (iter 68, RESOLVE):** rewrote the S2 and S3 adapter sections of
`.claude/skills/off-market-search/references/source_adapters.md` from
fixture-shells to working adapters:
- **S2 (SAM.gov Entity Management API)** — header changed from "BLOCKED above
  10/day by B3" to "live, public ~10/day tier". Pinned the base to
  `https://api.sam.gov/entity-information/v3/entities` (v3 — the version the
  recorded `S2.json` fixture's `entityData` shape matches; the API is public at
  v1–v4 per §13 item 5). Added the runtime key-retrieval step:
  `security find-generic-password -s samgov-api-key -a off-market-search -w`
  → `x-api-key` header, with an explicit note that the first session read may
  raise the one-time "Always Allow" keychain prompt and that the launchd agent
  runs in `gui/<uid>` so the login keychain is reachable. A retrieval failure
  sets `status: error` → fixture fallback, never fabricates. Specified the
  real query (`primaryNaics=541930`, optional
  `physicalAddressProvinceOrStateCode`, `registrationStatus=A`,
  `includeSections=…`, `page`/`size` paging, public tier only) and a
  v3-field-precise `Map:` (`entityRegistration.legalBusinessName`/`dbaName`/
  `ueiSAM`/`cageCode`, `coreData.physicalAddress`,
  `assertions.goodsAndServices.naicsList[].naicsCode`,
  `socioEconomic.businessTypeList`, `pointsOfContact.governmentBusinessPOC`,
  `coreData.entityInformation.entityURL`).
- **S3 (SAM.gov Contract Awards API)** — header changed from "BLOCKED by B3" to
  "live, public ~10/day tier". Documented that it uses the **same** Public API
  Key as S2, retrieved by the identical `security find-generic-password`
  command, hosted under `api.sam.gov` with path/version per
  `open.gsa.gov/api/contract-awards/`; kept the FPDS-NG exclusion.
- **Shared-quota rule** — S2 and S3 share one key and therefore one daily
  budget (~10/day public tier until entity registration completes, then
  1,000/day); the orchestrator counts both against the single cap; an HTTP 429
  yields `status: degraded` (stop paging, run continues), never a hard halt.
- **Registry table** — S2/S3 live status changed from "blocked (B3) — built,
  fixture fallback" to "ok (live key; public ~10/day tier)" / "ok (live key;
  shares S2's ~10/day quota)".
- **Fixture-mode paragraph** — the stale "(B1, B3)" precondition citation was
  genericized to "a missing credential, or a portal whose ToS is not yet
  confirmed", and fixture mode is now also justified as a way to exercise the
  pipeline without spending a quota-limited source's live request budget.
- **Recorded-fixture query** — each adapter section now explicitly names its
  recorded fixture (`_ralph_build/evidence/s3-fixtures/S2.json` /
  `S3.json`, structural placeholder samples) as the recorded-fixture query the
  finding asks for; these exercise the normalization mapping without spending
  the live 10/day quota. No live SAM.gov call was made this iteration — that
  would consume the scarce public-tier quota and risk a headless keychain
  prompt; the adapters are spec-complete and the keychain command + fixture
  fallback are documented for the live run.
The common adapter interface (`adapter.query` → `{records, meta}`, the
`RawRecord` shape) is unchanged, so s4–s6 are unaffected. Remaining `B3`
mentions in `skill.md:69` and `orchestration.md` (lines 52/78/84) are a
general adapter-degradation statement and run-log-template example text — not
the S2/S3 adapter deliverable this finding scopes — and are governed by the
still-open `IMPROVE-s10-3` / `NIT-s9-3` doc-staleness findings.
**Status:** RESOLVED.

### IMPROVE-s6-1 — IMPROVE — s6 — dangling `buy-box-and-scoring.md` reference
**Raised:** iter 19 VERIFY (s6 critic).
**Where:** `.claude/skills/off-market-search/references/scoring_integration.md`;
also `OFFMARKET_BUILD_PLAN.md` (lines 38 and 229).
**Problem:** the s6 spec (and the build plan) cited
`.claude/skills/prospect-evaluation/references/buy-box-and-scoring.md` as a file
used verbatim by the scorer. That file does not exist on disk and never existed
in any commit — `prospect-evaluation/` contains only `skill.md`, with the buy-box
rubric embedded inside it. Not an s6 functional defect (the scorer ran fine),
but the off-market docs cited a non-existent companion file.
**Fix:** point the reference at `.claude/skills/prospect-evaluation/skill.md`
(or drop the `references/` path) in `scoring_integration.md`, `skill.md`, and the
build plan's constraints section.
**Resolution (iter 67, RESOLVE):** the off-market `skill.md` no longer cited the
dangling file at all (a prior edit had already removed it — confirmed by grep:
`skill.md` references only `.claude/skills/prospect-evaluation/skill.md`), so the
iter-19 `skill.md:43` citation was already stale. Two live references remained
and were corrected: (1) `scoring_integration.md` — the "s6 never edits …"
sentence now reads "s6 never edits the `prospect-evaluation` skill (`skill.md`)
or its embedded rubric" (the rubric lives inside `skill.md`, not a separate
file); (2) `OFFMARKET_BUILD_PLAN.md` — the §"Reference materials" line 38 and the
§"Constraints" line 229 now name `.claude/skills/prospect-evaluation/skill.md`
"which embeds the buy-box rubric" instead of the non-existent
`references/buy-box-and-scoring.md`. A repo-wide grep of
`.claude/skills/off-market-search/` and `OFFMARKET_BUILD_PLAN.md` for
`buy-box-and-scoring` now returns no matches. Citation-correctness only; no
scoring, mode-selection, or rubric behavior changed — the scorer was always
`prospect-evaluation/skill.md` and is invoked as-is. (Other repo files —
`PRD_OFF_MARKET_SEARCH.md`, the on-market PRD-loop docs, and
`prospect-evaluation/skill.md`'s own internal `references/` citations — still
carry the path; those are outside the s6 deliverable scope of this finding and
the build loop does not modify the PRD or the on-market skill.)
**Status:** RESOLVED.

### NIT-s6-2 — NIT — s6 — `prospect-evaluation/skill.md` has owner-only file mode
**Raised:** iter 19 VERIFY (s6 critic).
**Where:** `.claude/skills/prospect-evaluation/skill.md`.
**Problem:** the file mode is `-rw-------` (owner-only), inconsistent with the
other skill files. Harmless and pre-existing (not caused by the s6 build).
**Fix:** optionally `chmod 644` for consistency; no functional impact.
**Resolution (iter 66, RESOLVE):** ran `chmod 644
.claude/skills/prospect-evaluation/skill.md` — the file mode is now
`-rw-r--r--`, matching `.claude/skills/off-market-search/skill.md`
(`-rw-r--r--`) and the other skill files. Confirmed via `ls -la`. No file
content changed; this only restores group/other read consistency across the
skill directory. Pre-existing and harmless (not caused by the s6 build), so
purely cosmetic — no functional, scoring, or read-access behavior is affected.
**Status:** RESOLVED.

### NIT-s5-2 — NIT — s5 — `employee_count` type inconsistent with other unknown-able fields
**Raised:** iter 13 VERIFY (s5 critic).
**Where:** `.claude/skills/off-market-search/references/enrichment.md:53`.
**Problem:** `employee_count` was typed `number | string`, while every other
unknown-able field uses `... | null` plus an `enrichment_gaps` `"needs
follow-up"` entry. Cosmetic schema inconsistency.
**Fix:** align `employee_count` to the `number | null` + `"needs follow-up"`
pattern.
**Resolution (iter 65, RESOLVE):** retyped `employee_count` in the `LeadPacket`
table (`enrichment.md`, was line 53, now line 56) from `number | string` to
`number | null`, with the source note "§3.3 — number, else `null` with an
`"employee count — needs follow-up"` gap". Reworded the §3.3 `employee_count`
bullet so an absent count yields `null` (not the string `"needs follow-up"`)
with `"employee count — needs follow-up"` recorded in `enrichment_gaps` — the
same `… | null` + gap pattern `website` / `formation_date` already use.
Aligned the two downstream references: `evidence/s5-selftest.md` C4 row
(`employee_count` → `null`, with the gap already enumerated at line 107) and
`scoring_integration.md:100` (`often "needs follow-up"` → `often null (a gap →
passed as missing)`). `airtable_write.md:89` already maps a non-real count to
blank, consistent with `null`. Spec-clarity only; no enrichment, scoring, or
write behavior changed — an absent count was already a gap, only its typed
value/sentinel is now consistent.
**Status:** RESOLVED.

### IMPROVE-s5-1 — IMPROVE — s5 — screenshot path not filesystem-safe for `entity_id`
**Raised:** iter 13 VERIFY (s5 critic).
**Where:** `.claude/skills/off-market-search/references/enrichment.md` §3.1
(was line 135; the screenshot-path line).
**Problem:** screenshot path was `output/screenshots/{entity-id}.png`, claimed to
match the `overnight-search` convention. But `overnight-search` uses a plain
alphanumeric `listing-id`, whereas the off-market `entity_id` is e.g.
`UEI:ZZTEST00FIX1` or `NAME:abacus finance group|new york ny` — containing `:`,
`|`, and spaces (and `/` for SBIC license numbers), which are illegal/fragile in
filenames. Never exercised in the self-test (R1 `screenshot_path` was `null`).
**Fix:** specify a slugified/sanitized form of `entity_id` for the filename
(replace `:`, `|`, spaces), or note the existing convention does not transfer.
**Resolution (iter 64, RESOLVE):** changed the §3.1 screenshot path from
`{entity-id}` to `{entity-id-slug}` in `enrichment.md` and added an explicit
slug rule: lowercase the `entity_id`, replace every run of any character
outside `[a-z0-9]` (covering `:`, `|`, `/`, whitespace) with a single `-`,
collapse consecutive `-`, trim leading/trailing `-`. Worked examples:
`UEI:ZZTEST00FIX1` → `uei-zztest00fix1`, `NAME:abacus finance group|new york ny`
→ `name-abacus-finance-group-new-york-ny`, `SBIC:09/79-0292` →
`sbic-09-79-0292`. The rule states the canonical `entity_id` is unchanged (stays
verbatim in `Gov Entity ID` per `entity_resolution.md` §5) — only the screenshot
filename is slugified — and that `screenshot_path` records the actual on-disk
path. The slug form matches the existing `output/reports/` directory naming
(`uei-zztest00fix1/`, `name-1st-source-capital-south-bend-in/`). Spec-clarity
only; no enrichment behavior changed (R1 `screenshot_path` was `null`, never
exercised).
**Status:** RESOLVED.

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
**Resolution (iter 63, RESOLVE):** changed both stale C7 citations in
`evidence/s5-selftest.md` — item 1 "Matches line 97 of this file" → "line 104"
and item 2 "Matches line 125" → "line 132". Verified against the file on disk:
the R1 `gov_data_source` row (`["SAM.gov", "SAM.gov Contract Awards"]`) is at
line 104 and the R2 `gov_data_source` row (`["SBA SBIC"]`) is at line 132 — old
lines 97/125 are the unrelated `years_in_business` / `formation_date` rows. The
iter-15 re-run header (line 5) carried the same stale `97 / 125` pair describing
the iter-14 choice-string fix; updated it to `104 / 132` so the whole file is
internally consistent. Evidence-only change; the C7 PASS verdict, the §5.1
mapping behavior, and every `gov_data_source` value are unchanged.
**Status:** RESOLVED.

### NIT-s6-1 — NIT — s6 — self-test cites a stale score line number
**Raised:** iter 19 VERIFY (s6 critic).
**Where:** `Off-Market Search/_ralph_build/evidence/s6-selftest.md:18`.
**Problem:** the self-test cites the R1 score lines as `report.md:29,64,70`, but
the breakdown total is at line 85, not 70. The score itself (30/110) is correct
and internally consistent; only the line citation is off.
**Fix:** change `70` → `85` in the C1 evidence citation.
**Resolution (iter 62, RESOLVE):** changed the C1 evidence citation in
`evidence/s6-selftest.md` line 18 from
`example-interpreting-fixture-llc-report.md:29,64,70` to `…:29,64,85`. Verified
against the report on disk: line 29 is the `**Lead Score:** **30 / 110**`
header line, line 64 is scorecard field 26 (`| 26 | **Lead Score** | **30 / 110**
| computed |`), and the per-line breakdown **total** row
(`| **Total** | **30** | **110** | |`) is at line 85 — line 70 is only the
`## Lead Score Breakdown` heading. The self-test text describes the third
citation as "the per-line breakdown total", so 85 is the correct line. Evidence
citation only; the 30/110 score and the C1 PASS verdict are unchanged.
**Status:** RESOLVED.

### NIT-s5-1 — NIT — s5 — s4 self-test provenance note cites the wrong record
**Raised:** iter 13 VERIFY (s5 critic).
**Where:** `Off-Market Search/_ralph_build/evidence/s4-selftest.md:29`.
**Problem:** R1's `psc [R608]` is described as coming "from rec 3-shape", but
record 3 is a different entity (an S1 record). Cosmetic provenance error in the
s4 evidence, carried implicitly into the s5 input description.
**Fix:** correct the provenance note to cite the actual contributing record.
**Resolution (iter 61, RESOLVE):** changed the §6.1 R1 cluster bullet in
`evidence/s4-selftest.md` from `psc [R608]` "(from rec 3-shape)" to
`psc [R608]` "(from rec 5/S3 only)" — the correct sole contributor, as the
iter-60 R1 per-field merge trace established (rec 5 / S3 `pscCode`; rec 4 / S2
carries no `psc`). Also refreshed the merge-trace footnote that had named the
mis-citation as still-open NIT-s5-1, so it now records the citation as
corrected. Evidence-only change; no resolution, dedup, or merge behavior
changed.
**Status:** RESOLVED.

### IMPROVE-s4-3 — IMPROVE — s4 — self-test merge trace not shown
**Raised:** iter 10 VERIFY (s4 critic).
**Where:** `Off-Market Search/_ralph_build/evidence/s4-selftest.md` lines 28-29.
**Problem:** the self-test asserts R1's merged `naics`/`psc`/`award_total`
values without showing the per-field union derivation, so the spot-check is not
fully reproducible from the evidence alone.
**Fix:** add a one-line merge trace showing each field's union step.
**Resolution (iter 60, RESOLVE):** added an "R1 per-field merge trace"
subsection to `evidence/s4-selftest.md`, immediately after the §6.1 output
line. It is an 8-row table covering every R1 field (`legal_name`, `uei`,
`cage_code`, `naics`, `psc`, `award_total`, `source_ids`, `source_urls`),
showing `rec 4 (S2) value` ⊕ `rec 5 (S3) value` → `merged value` and the union
step for each — set union (deduped) for the multi-valued fields, single
non-null / identical value for the scalars. Each merged value cross-checked
against the s3 fixtures: `cage_code 0ZZ11` is rec 4 only (S2 `cageCode`); `psc
[R608]` and `award_total 480000` are rec 5 only (S3 `pscCode` /
`obligatedAmount`); `naics [541930]` and `uei`/`legal_name` are identical in
both. The merge in the cluster bullet is now fully reproducible from the
evidence. The trace also footnotes that the cluster bullet's inline `psc …
(from rec 3-shape)` provenance label is a separate cosmetic mis-citation
tracked as NIT-s5-1 (correct contributor is rec 5/S3). Evidence-only change; no
resolution, dedup, or merge behavior changed.
**Status:** RESOLVED.

### NIT-s4-1 — NIT — s4 — slash in example `entity_id`
**Raised:** iter 10 VERIFY (s4 critic).
**Where:** `.claude/skills/off-market-search/references/entity_resolution.md` §5
(`entity_id` / `Gov Entity ID` construction).
**Problem:** the example `entity_id` `SBIC:09/79-0292` embeds a slash; harmless
in a plain-text `Gov Entity ID` field but mildly fragile as an identifier key.
**Fix:** optionally note that slashes in source license numbers are retained
verbatim, or normalize them in the `SBIC:` key.
**Resolution (iter 59, RESOLVE):** added a "Slashes in `SBIC:<license_no>`"
note to `entity_resolution.md` §5 after the `entity_id` construction bullets.
It states SBA SBIC license numbers carry an embedded slash (e.g. `09/79-0292`),
that the license number is retained **verbatim** in the `SBIC:` key — not
stripped, escaped, or normalized — and explains why this is safe: `entity_id` /
`Gov Entity ID` is a plain identifier string compared literally by dedup key A
and stored as text in Airtable, so an embedded slash is harmless there. It also
notes that any filesystem-path use must sanitize at the consuming step, while
the canonical key stays verbatim so the same firm yields the same id across
runs. Spec-clarity only; no resolution or `entity_id` behavior changed (the
stale `SBIC:09/79-0292` literal flagged at iter 10 had already been removed by
a prior edit — §5 now carries `SBIC:<license_no>` plus this note).
**Status:** RESOLVED.

### IMPROVE-s4-2 — IMPROVE — s4 — DUNS ladder exception not stated explicitly
**Raised:** iter 10 VERIFY (s4 critic).
**Where:** `.claude/skills/off-market-search/references/entity_resolution.md`
§2.1 (the Legacy DUNS ladder step).
**Problem:** the §6.1 ladder header says "first key that produces a match," but
the DUNS step adds an override ("never resolve solely on DUNS when a UEI is
available"). Correct behavior, but a non-obvious exception to first-match-wins.
**Fix:** state in §2.1 that DUNS is checked only after confirming neither record
carries a UEI, so the ladder semantics stay unambiguous.
**Resolution (iter 58, RESOLVE):** rewrote the §2.1 Legacy DUNS ladder step
(item 3) to state explicitly that it is a documented exception to
first-match-wins — the DUNS key is evaluated only after confirming that neither
record under comparison carries a `norm_uei`; if either record has a UEI, the
DUNS step is skipped entirely, the UEI cluster is preferred, and the DUNS is
attached to it. The ladder now reads unambiguously: DUNS is never the deciding
key whenever a UEI is present on either side. Spec-clarity only; no resolution
behavior changed (the prior text already mandated the same outcome).
**Status:** RESOLVED.

### NIT-s8-1 — NIT — s8 — stray trailing tokens in s8 evidence files
**Raised:** iter 24 VERIFY (s8 critic).
**Where:** `evidence/s8-selftest.md:238-239` and
`evidence/s8-offmarket_outreach_drafts_2026-05-22.md:106`.
**Problem:** stray trailing `</content>` / `</invoke>` artifact-formatting
tokens leaked into the evidence files. Cosmetic; does not affect deliverables.
**Resolution (iter 57, RESOLVE):** stripped the two trailing tokens from
`evidence/s8-selftest.md` (the `</content>`/`</invoke>` pair after the final
"Stage s8 → `self_checked`" line) and the trailing `</content>` from
`evidence/s8-offmarket_outreach_drafts_2026-05-22.md` (after the final
"_Skipped (no draft)_" line). A repo-wide grep of
`_ralph_build/evidence/` for `</content>`, `</invoke>`, `</parameter>` and
`</function_calls>` now returns no matches. Cosmetic only; no evidence content
or deliverable changed.
**Status:** RESOLVED.

### IMPROVE-s4-1 — IMPROVE — s4 — `dedup_verdict` enum omits `needs_operator_review`
**Raised:** iter 10 VERIFY (s4 critic).
**Where:** `.claude/skills/off-market-search/references/entity_resolution.md:61`.
**Problem:** the `dedup_verdict` field enum is `new` | `existing`, but §4 routes
identifier-less/address-less entities to a `needs_operator_review` state never
represented in the enum.
**Resolution (iter 56, RESOLVE):** chose the "note explicitly" fix over widening
the enum — `needs_operator_review` is genuinely a run-log exclusion status, not
a verdict (an entity missing all identifiers and address is excluded from the
write *before* §3 dedup runs, so it never reaches a verdict). Expanded the
`dedup_verdict` row note in the `CanonicalEntity` table (`entity_resolution.md`
line 61) to state the verdict is assigned only to an entity that survives §2
resolution, that an entity missing all identifiers **and** address is excluded
as `needs_operator_review` (§4) before any verdict is assigned, and that
`needs_operator_review` is a run-log exclusion status, not a `dedup_verdict`
value. Cosmetic/spec-clarity only; no resolution or dedup behavior changed.
**Status:** RESOLVED.

### IMPROVE-s3-1 — IMPROVE — s3 — S1 UEI not populated
**Raised:** iter 7 VERIFY (s3 critic).
**Where:** `.claude/skills/off-market-search/references/source_adapters.md`
(S1 USAspending adapter, Query block).
**Problem:** `uei` — the primary s4 entity-resolution key — is not returned by
the USAspending `spending_by_award` endpoint, so S1 records currently resolve
only on name+address, weakening s4.
**Resolution (iter 55, RESOLVE):** rewrote the S1 adapter Query block to add a
required recipient-detail follow-up step — for each distinct `recipient_id`
returned by `spending_by_award`, `GET /api/v2/recipient/{recipient_id}/` and
read `uei` (with `duns`/location) from that response, cached per
`recipient_id`, paced ~1 req/sec; the bulk-download CSV path instead reads the
`recipient_uei` column directly and skips the follow-up. The Map bullet now
states `uei` comes from the follow-up (or the bulk CSV column), never from
`spending_by_award` directly, and that a failed/empty detail call sets
`uei: null` so s4 falls back to the name+address ladder — never fabricate a
UEI. Grouping is now by `recipient_id` then resolved UEI. So S1 `RawRecord`s
now carry a real `uei` where the recipient publishes one.
**Status:** RESOLVED.

### NIT-s3-1 — NIT — s3 — SBIC CSV column label mismatch
**Raised:** iter 7 VERIFY (s3 critic).
**Where:** `.claude/skills/off-market-search/references/source_adapters.md`
(S4 adapter prose, the `Map:` bullet).
**Problem:** the S4 adapter prose said map the `"Managed by"` column, but the
live SBIC directory CSV header is actually named `Manager`. Mapping intent was
correct; the cited column label was wrong.
**Resolution (iter 54, RESOLVE):** changed `"Managed by"` to `Manager` in the
S4 adapter `Map:` bullet so the cited column label matches the live SBIC
directory CSV header. Confirmed no remaining `Managed by` literal in the skill
directory. Cosmetic; the GP-as-target mapping intent is unchanged.
**Status:** RESOLVED.

### F2 — NIT — s1 — literal placeholder string trips automated scans
**Raised:** iter 3 VERIFY (s1 critic).
**Where:** `config/offmarket_sources.md` line 7.
**Problem:** the line contained the literal string `⚠ VERIFY:` inside a negation
sentence ("No `⚠ VERIFY:` placeholders remain"); a future automated placeholder
scan could false-positive on it.
**Resolution (iter 53, RESOLVE):** reworded the sentence to describe the marker
without quoting the literal token — now reads "No verify-this-value placeholder
markers remain". Confirmed `config/offmarket_sources.md` no longer contains the
`⚠ VERIFY:` literal anywhere. Cosmetic; no source-config fact changed.
**Status:** RESOLVED.

### F1 — IMPROVE — s1 — non-standard Markdown comment delimiter
**Raised:** iter 3 VERIFY (s1 critic).
**Where:** `config/offmarket_sources.md` lines 10–12.
**Problem:** the "Built by stage s1" note used a `/ … /` delimiter, which is not
valid Markdown comment syntax, so the text rendered literally.
**Resolution (iter 52, RESOLVE):** wrapped the note in a proper HTML/Markdown
comment — `<!-- Built by build-loop stage s1. Source adapters that consume this
config are built by s3. -->` — so it no longer renders. Verified the file has
no remaining `/ … /` pseudo-comment.
**Status:** RESOLVED.

### BLOCKING-s9-1 — BLOCKING — s9 — weekly cron is not registered though B4 is resolved
**Raised:** iter 45 FINAL AUDIT (independent auditor).
**Where:** s9 cadence deliverable — build-plan Deliverable #7 and the s9
`Done-when` ("the weekly cron is registered"); `run-offmarket-search.sh`,
`config/offmarket_schedule.md`,
`config/launchd/ai.earnedout.offmarket-search.plist`,
`.claude/skills/off-market-search/references/orchestration.md` §6.
**Problem:** `CronList` returns "No scheduled jobs" and
`launchctl list | grep offmarket` returns nothing — the weekly cron is not
live. The script, the launchd plist, and `offmarket_schedule.md` all exist and
are correct, but live registration was honestly gated on blocker B4 (the iter
27 s9 VERIFY documented it as the post-B4 install step). B4 is now RESOLVED
(`BLOCKERS.md`; the two `Source` values are live), so the gate has cleared and
the registration step should have run. Build-plan Deliverable #7 requires the
cron "registered" and s10's Definition of done requires all stages truly
`verified`; an unscheduled weekly pipeline never fires.
**Resolution (iter 46, s9 re-IMPLEMENT):** registered the weekly trigger as the
local `launchd` agent `ai.earnedout.offmarket-search` — the mechanism
`config/offmarket_schedule.md` documents as the fallback for when a `/schedule`
remote routine cannot reach the local repo / MCP servers (which this pipeline
requires). Copied `config/launchd/ai.earnedout.offmarket-search.plist` to
`~/Library/LaunchAgents/` and bootstrapped it
(`launchctl bootstrap gui/$(id -u) …`, rc 0). `launchctl list | grep offmarket`
now shows the agent; `launchctl print` confirms `StartCalendarInterval`
`Weekday => 1` / `Hour => 6` (weekly, Monday 06:00 local), matching build-plan
Deliverable #7 and `config/offmarket_schedule.md`. The `CronCreate` in-memory
scheduler was rejected (its jobs fire only while a Claude REPL is idle, so a
weekly unattended trigger would not fire). The Registration section of
`config/offmarket_schedule.md` was updated to record the live launchd agent.
**Status:** RESOLVED — s9 returns to the phase ladder (re-SELF-TEST next; the
SELF-TEST must confirm the agent is live and correctly scheduled).

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
