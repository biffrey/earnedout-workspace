# Off-Market Build Loop — Implementation Log

One entry per IMPLEMENT phase: date, iteration, stage, and what was built.

## iter 1 — 2026-05-22 — s1 (Foundations & config) — IMPLEMENT

Built the stage-s1 deliverables:

- **`config/offmarket_sources.md`** — verified-codes source config. Contains:
  the two target classes; the verified search keys (NAICS `541930` CONFIRMED,
  PSC `R608` CONFIRMED — "low confidence" flag cleared, GSA MAS SIN `541930`);
  the Class-1 core keyword list + exclusion/down-weight terms; the Class-2
  keywords + the B2 default (all licensed SBIC types); 11 sources (S1–S11) each
  with access method, endpoint, extract fields, rate-limit/ToS, target class,
  and blocked-status; the entity-identifier priority order; the Airtable target;
  the compliance posture. **No `⚠ VERIFY:` placeholders remain** — every code
  and endpoint is resolved from the §13 resolution doc.
- **`.claude/skills/off-market-search/skill.md`** — the skill scaffold. Valid
  YAML frontmatter (`name`, `description`); the §9.1 nine-step outline (read
  config & preflight → query sources → resolve & dedup → enrich → qualify &
  score → Airtable write → outreach → dashboard → run logs); the manual
  single-entity path; cadence; and the invariant constraints. Each step is
  annotated with the build-loop stage (s2–s9) that completes it, and the file
  is clearly marked **SKELETON / do not run live** until the loop verifies.

Source layer is documented as swappable (the FPDS-decommission lesson). FPDS-NG
is explicitly excluded; SAM.gov Contract Awards API named as the successor;
USAspending.gov is the primary award source.

Stage s1 → `drafted`. Next phase for s1: SELF-TEST.

## iter 4 — 2026-05-22 — s2 (Airtable schema) — IMPLEMENT

Applied the s2 schema deliverables to base `appOsvuyy5eK43QTx` / table
`tblSmNrHROMLm7vOS`:

- **Five §8.4 fields created live** via the Airtable MCP `create_field` tool —
  `Gov Entity ID` (singleLineText), `SBIC License #` (singleLineText),
  `SBIC License Status` (singleSelect: Good Standing / Under Review /
  Surrendered / Revoked / Unknown), `Gov Data Source` (multipleSelects),
  `Federal Award History $` (currency, $, precision 0). Tool responses confirm
  creation; field IDs recorded in `evidence/s2-airtable-schema.md`. The
  `Gov Data Source` choice set follows the §13 resolution (FPDS-NG → SAM.gov
  Contract Awards, DSBS → SBS, RID added) rather than the literal PRD §8.4 list.
- **Schema-preflight reference written** —
  `.claude/skills/off-market-search/references/airtable_schema_preflight.md`: the
  fail-loud Step-1 check that verifies all six fields, both off-market `Source`
  values, and the `SBIC License Status` options before any write, halting with a
  specific operator message (never auto-creating) on any miss. `skill.md` Step 1
  updated to point at it.

**Blocked — the two §8.3 `Source` values were NOT added.** The `Source`
single-select still has only `Overnight Search` / `Manual Submission`. The
Airtable MCP `update_field` tool cannot add `choices` to an existing
single-select, so the loop cannot create `Off-Market — ASL Bolt-on` /
`Off-Market — SBIC` itself — an operator action is required. B4 updated and
narrowed to this remaining item; stage s2 set to `blocked`.

Stage s2 → `blocked` (B4). The loop continues with the next non-blocked stage
(s3).

## iter 5 — 2026-05-22 — s3 (Source adapters) — IMPLEMENT

Built the stage-s3 deliverable: **one query module ("adapter") per source
behind a single common interface** so a source can be swapped without touching
downstream stages (the FPDS-decommission lesson).

- **`.claude/skills/off-market-search/references/source_adapters.md`** — the
  s3 reference. Contents:
  - **Common interface** — every adapter invoked `adapter.query(target_class,
    params)`; returns `{records: [RawRecord], meta: AdapterMeta}`. Downstream
    stages only ever see `RawRecord`s and never know which source produced one.
  - **`RawRecord`** normalized schema (23 fields: identifiers UEI/CAGE/DUNS/SBIC
    license #, address, NAICS/PSC, award totals, socioeconomic flags, POC,
    keyword hits/tier, provenance). **Unknown → `null`** — never invented; s5
    converts `null` to "needs follow-up".
  - **`AdapterMeta`** per-call status (`ok`/`blocked`/`degraded`/`n/a`/`error`,
    `blocker_id`, query filters, rate-limit note). A blocked/error adapter
    degrades the run gracefully — it does not halt; only the s2 schema preflight
    is fail-loud.
  - **Fixture mode** — adapters can map a recorded payload from
    `_ralph_build/evidence/s3-fixtures/<id>.json` through identical
    normalization, so SELF-TEST + downstream stages run without a blocked
    credential.
  - **11 per-source adapters** (S1–S11) — each with transport, query procedure,
    NAICS/PSC/keyword filter, field mapping, rate-limit/ToS handling, and live
    status. S1 USAspending (primary, key-free), S2/S3 SAM.gov APIs (built,
    `blocked` B3, fixture fallback), S4 SBIC directory CSV-diff, S5 good-standing
    cross-check, S6 SBS, S7 GSA eLibrary, S8 state portals (`blocked` B1, shell
    only), S9 RID (point-of-need, no-bulk-copy enforced in code), S10 IAPD,
    S11 U.S. Courts.
  - **Adapter registry** — orchestrator (s9) iterates it; add/remove a source is
    a one-line registry change. Discovery vs. enrichment roles tabulated.
- **`skill.md` Step 2 updated** to point at `references/source_adapters.md` and
  describe the common-interface invocation + graceful degradation.

Constraints honored: API/bulk-download over scraping per source; RID
no-bulk-copy enforced (`status: n/a` if called without a name); SBIC GP — not
fund/portfolio — is the target; SBA-prior-approval fact carried on every S4
record; B1/B3 adapters built but marked `blocked`, not faked.

Stage s3 → `drafted`. Next phase for s3: SELF-TEST.

## iter 8 — 2026-05-22 — s4 (Entity resolution & de-duplication) — IMPLEMENT

Built the stage-s4 deliverable: the resolver + tracker dedup that turns the s3
multi-source `RawRecord` set into one canonical entity per company and prevents
re-surfacing a target already in the tracker.

- **`.claude/skills/off-market-search/references/entity_resolution.md`** — the
  s4 reference. Contents:
  - **Stage I/O** — input is the combined s3 record set; output is a list of
    **`CanonicalEntity`** objects, each tagged `dedup_verdict: new | existing`.
    Only `new` flows to s5; `existing` carries the matched `tracker_record_id`
    so s7 updates instead of creating.
  - **`CanonicalEntity`** schema (24 fields: resolved identifiers, `all_names`,
    union NAICS/PSC/flags/keywords, provenance `source_ids`/`source_urls`/
    `constituent_records`, `resolution_key`/`resolution_confidence`,
    `dedup_verdict`/`dedup_key`/`tracker_record_id`). Unknown → `null`.
  - **§6.1 resolver** — normalization helpers (`norm_name` strips entity
    suffixes; `norm_addr` USPS-style at ZIP / city+state grain; `norm_uei/cage/
    duns`) and the priority key ladder **UEI → CAGE → legacy DUNS → normalized
    name+address**. DUNS is a fallback bridge only (§13 item 12 — retired
    2022-04-01); name+address is a `probable` match, never exact. Class-2 also
    clusters on `sbic_license_no`. Cluster-merge rules; an exact-id conflict is
    never auto-merged.
  - **§6.2 tracker dedup** — three match keys (A gov identifier vs.
    `Gov Entity ID`; B normalized name+address; C `SBIC License #`, Class 2),
    evaluated A→C against `tblSmNrHROMLm7vOS`. On a match: update, never
    duplicate — refresh `Link Last Checked`/`Date Updated`, fill blank gov
    fields without overwriting, append a dated `Notes` line for an on-market
    row, never flip an existing row to a new lead.
  - **Cross-run dedup** — the tracker is the cross-run memory (every off-market
    entity is written there), so a prior-run target resolves to `existing`; no
    separate state file.
  - **Failure handling** — identifier-less + address-less entities go to
    `needs_operator_review` (not fabricated into a row, not silently dropped);
    a failed tracker read **halts the write step** rather than writing blind
    (fail loud); `probable` matches are flagged for spot-check.
  - **`Gov Entity ID` construction** — deterministic, prefixed (`UEI:` / `CAGE:`
    / `SBIC:` / `NAME:<norm_name>|<zip>`), stable across runs.
  - **Accuracy spot-check** — s4 SELF-TEST and s10 sample clusters/verdicts and
    record sampled accuracy against the §2.2 ≥95% resolution / <5% duplicate
    targets.
- **`skill.md` Step 3 updated** to point at `references/entity_resolution.md`
  and describe the `new`/`existing` tagging, the tracker-as-cross-run-memory
  fact, and the fail-loud halt on a tracker read failure.

Constraints honored: no parallel tracker / no new scorer (dedup reads/writes
only `tblSmNrHROMLm7vOS`); never fabricate (identifier-less entities are
reviewed, not invented); fail loud on a tracker read failure; the §8 ⚠ VERIFY
is treated as resolved (dedicated `Gov Entity ID` field, operator-approved).

Stage s4 → `drafted`. Next phase for s4: SELF-TEST.

## iter 11 — 2026-05-22 — s5 (Enrichment & qualification pre-filters) — IMPLEMENT

Built the stage-s5 deliverable: the procedure that turns each thin `new`
canonical entity from s4 into a scorable `LeadPacket`, dropping obvious
non-fits cheaply before any expensive enrichment.

- **`.claude/skills/off-market-search/references/enrichment.md`** — the s5
  reference. Contents:
  - **Stage I/O** — input is the s4 output filtered to `dedup_verdict: new`
    entities (`existing` → straight to s7 update; `needs_operator_review` →
    run log). Output is one **`LeadPacket`** per candidate that passes the
    §7.4 pre-filter; failed candidates are dropped with a logged reason.
  - **`LeadPacket`** schema (24 fields: identifiers, name/industry/location,
    website + `website_status` + `screenshot_path`, `formation_date` /
    `years_in_business` / `sos_status`, `employee_count`, `revenue_signal`,
    `federal_award_total`, `asking_price` fixed to "not for sale", `contact`,
    Class-2 `sbic_license_no` / `sbic_license_status` / `sbic_gp_economics`,
    `gov_data_source`, provenance, `prefilter_verdict`, `enrichment_gaps`).
    **Unknown → "needs follow-up"/`null`, never fabricated**; every gap is
    enumerated in `enrichment_gaps` for the audit trail.
  - **§7.4 cheap pre-filters run FIRST** (cost control — before any Playwright
    / SOS work). Class 1: keyword hits must indicate a sign-language/
    deaf-services line per `config/offmarket_sources.md` §5.2 (exclusion-only
    hits → drop; ASL-carrying spoken-language firm → kept as `adjacent`,
    line-10 bonus 5 not 10) **and** the entity must be a U.S. operating
    company. Class 2: current SBIC licensee, not already disproven on standing
    (unconfirmed standing is **not** a drop — it passes and the scorer gate
    handles it CONDITIONAL).
  - **Enrichment steps** for pre-filter passes: §3.1 website discovery +
    Playwright validation + screenshot to `output/screenshots/{entity-id}.png`
    (reuses `overnight-search` Step 3 verbatim); §3.2 SOS formation-date lookup
    (Phase-1 scope gated by B1 — a non-priority state is a logged gap, not a
    fabrication); §3.3 financial-**signal** enrichment (federal award total
    labelled as gov-contract-only, employee count, qualitative revenue band —
    never written as a disclosed numeric); §3.4 owner / SBIC GP-principal
    contact discovery (RID = point-of-need only, no bulk copy); §3.5 Class-2 GP
    economics (informational).
  - **SBIC good-standing cross-check (§4)** — the SBIC directory publishes no
    standing flag, so standing is cross-referenced (directory presence +
    SBA OIG/press enforcement + S11 court records + S10 IAPD adverse events)
    and resolved to a `SBIC License Status` value; `Unknown` is an honest
    output (→ scorer CONDITIONAL), never `Good Standing`-by-default.
  - **`LeadPacket` assembly (§5)** and **failure/edge handling (§6)** — a
    Playwright failure degrades one candidate, not the run; a sparse-enrichment
    pre-filter pass is still scored; B1-blocked SOS leaves a gap.
- **`skill.md` Step 4 updated** to point at `references/enrichment.md` and
  describe the pre-filter-then-enrich order, the B1-gated SOS lookup, the SBIC
  good-standing cross-check, and the `LeadPacket` output.

Constraints honored: never fabricate (every unknown is a logged gap, financial
signals are explicitly labelled estimates); API/source reuse over scraping
(`overnight-search` Step 3 reused, RID no-bulk-copy enforced); no parallel
tracker / no new scorer (s5 only builds the packet the existing scorer eats);
SBA-prior-approval fact carried on every Class-2 packet; B1 handled as a
graceful gap, not a hard stop.

Stage s5 → `drafted`. Next phase for s5: SELF-TEST.

## iter 14 — 2026-05-22 — s5 (Enrichment & qualification pre-filters) — IMPLEMENT (re-implement)

Re-IMPLEMENT after iter-13 VERIFY returned s5 to `not_started` on **BLOCKING-s5-1**
(`LeadPacket.gov_data_source` pointed at a non-existent `source_id → choice`
mapping table; the self-test emitted `"SAM.gov Entity Management"`, not a live
`Gov Data Source` choice — which would silently auto-grow the multi-select).

Fix applied:
- **`references/enrichment.md` §5.1 added** — an explicit
  `source_id → Gov Data Source` mapping table using only the eight live choices
  (`evidence/s2-airtable-schema.md`): `S1→USAspending`, `S2→SAM.gov`,
  `S3→SAM.gov Contract Awards`, `S4→SBA SBIC`, `S5→SBA SBIC`, `S6→SBS`,
  `S7→GSA eLibrary`, `S8→State`, `S9→RID`. `S10` (IAPD) and `S11` (U.S. Courts)
  are documented as enrichment-only — not discovery sources — so neither ever
  contributes a `Gov Data Source` value.
- **Fail-loud rule** stated in §5.1: every `gov_data_source` value must come
  from the table; an unmapped `source_id` halts the skill with a
  schema-preflight-style operator message; the multi-select is never auto-grown
  with a free-text/mistyped string.
- **`enrichment.md` §1 and §5** `gov_data_source` rows re-pointed at §5.1
  (was the dangling "per `airtable_schema_preflight.md`" reference).
- **`evidence/s5-selftest.md`** corrected — line 97
  `["SAM.gov", "SAM.gov Contract Awards"]` and line 125 `["SBA SBIC"]`, both now
  live choices, each annotated with its §5.1 derivation.
- **`FINDINGS.md`** — BLOCKING-s5-1 moved to a new `## Resolved` section with
  the resolution recorded; `unresolved_findings` 15 → 14.

Constraints honored: fail-loud / never silently create a choice (the core of
the finding); no fabricated values; no new scorer or parallel tracker; field-
value consistency with the s7 Airtable write preserved.

Stage s5 → `drafted`. Next phase for s5: SELF-TEST (re-run the pre-filters +
enrichment + `LeadPacket` assembly, confirming §5.1 yields only live
`Gov Data Source` choices).

## iter 17 — 2026-05-22 — s6 (Scoring integration) — IMPLEMENT

Built the stage-s6 deliverable: the integration layer that scores each s5
`LeadPacket` by invoking the **existing, unmodified** `prospect-evaluation`
skill — no new scoring logic, no new rubric, no parallel scorer.

- **`.claude/skills/off-market-search/references/scoring_integration.md`** — the
  s6 reference. Contents:
  - **Stage I/O** — input is the s5 `LeadPacket` list (`prefilter_verdict:
    pass`); output is one **`ScoredLead`** per packet (the `LeadPacket` carried
    through unchanged + `eval_mode`, `lead_score`, `score_denominator`,
    `score_is_informational`, `buybox_gate`, `report_md_path` /
    `report_html_path` / `report_slug`, `scoring_notes`). `ScoredLead` adds no
    scoring math — only what the unmodified scorer returned + s7 bookkeeping.
  - **§2 mode selection** — Class 1 → `rollup_addon` (Applied Development named
    explicitly, NAICS 541930, no size floor, +10 line-10 bonus, /110 scale; an
    `adjacent` keyword tier awards the line-10 bonus at **5 not 10** per §13).
    Class 2 → `sbic` (license-good-standing gate is the sole hard criterion;
    0–100 score informational). s6 makes the intended mode explicit but never
    edits `prospect-evaluation` or its rubric; a detection/`eval_mode`
    disagreement is a BLOCKING defect to log, not patch over.
  - **§3 field mapping** — `LeadPacket` → the same lead-data inputs
    `overnight-search` Step 6 passes the scorer; a gap stays a gap (`null` /
    "needs follow-up" passed through, never back-filled). §3.1: `revenue_signal`
    / `federal_award_total` / `sbic_gp_economics` are **signals**, passed
    labelled as such so the scorer's own "never fabricate financials" rule
    leaves undisclosed EBITDA blank.
  - **§3.2 "no asking price"** — off-market literal `"not for sale — no asking
    price"` → Buy Box asking-price check ⚠️ "insufficient data"; valuation-
    multiple rubric line scores **0 — "insufficient data — not awarded"**, not a
    ❌, no abort, candidate not dropped. A scorer that crashes/refuses purely
    for absent asking price is flagged BLOCKING (the Done-when criterion).
  - **§4 SBIC good-standing gate** (Class 2) — `sbic_license_status` →
    `buybox_gate`: `Good Standing`→`pass`, `Under Review`/`Unknown`→
    `conditional`, `Surrendered`/`Revoked`→`fail`. A `fail`/`conditional` gate
    does **not** drop the candidate (still scored, still written by s7, gate
    surfaced); score stays informational; SBA prior-approval fact carried.
  - **§5 capture** — mirrors `overnight-search` Step 6: `output/reports/
    {report_slug}/` with `lead-packet.json`, the screenshot, and both
    `{company-slug}-report.md` + `.html`; `lead_score` + `score_denominator`
    extracted from the report header. **§5.1** defines `report_slug` — a
    deterministic filesystem-safe form of `entity_id` (which carries `:` / `|`),
    stable across runs so a re-score overwrites its own dir, no duplicate.
  - **§6 failure handling** — a per-candidate scorer failure sets
    `lead_score: null` and continues (one failed score ≠ a failed run); sparse
    enrichment is still scored; a fail-the-gate target still gets a full report
    (scorer rule 10); never fabricate to lift a score.
- **`skill.md` Step 5 updated** to point at `references/scoring_integration.md`
  and describe the per-class mode, the adjacent-tier bonus, the graceful "no
  asking price" handling, the SBIC gate, and the `ScoredLead` / `report_slug`
  output.

Constraints honored: no new scorer / no parallel tracker (s6 only invokes
`prospect-evaluation` unchanged and feeds s7); never fabricate (gaps passed
through as gaps; financial signals labelled as signals); off-market "no asking
price" handled as insufficient-data, not a failure; SBA-prior-approval fact
carried on every Class-2 `ScoredLead`.

Stage s6 → `drafted`. Next phase for s6: SELF-TEST (drive the procedure over the
s5 SELF-TEST `LeadPacket`s — R1 Class 1 `rollup_addon` /110, R2 Class 2 `sbic`
informational with a `buybox_gate` from `sbic_license_status`; confirm the
"no asking price" handling and the filesystem-safe `report_slug`).

## iter 20 — 2026-05-22 — s7 (Airtable write & dashboard badge) — IMPLEMENT

Built the stage-s7 deliverable: the procedure that persists each s6 `ScoredLead`
to the **existing** Master Deal Pipeline tracker and the off-market dashboard
badge — no parallel tracker, off-market rows interchangeable with on-market.

- **`.claude/skills/off-market-search/references/airtable_write.md`** — the s7
  reference. Contents:
  - **Stage I/O** — input is the s6 `ScoredLead` list (`new` entities) plus the
    s4 `existing`-tagged `CanonicalEntity`s (each with a `tracker_record_id`);
    `new` → create, `existing` → update in place. Output: one Airtable row per
    lead, the record URL written back into `Notes`, and the dashboard
    regenerated with the badge.
  - **§2 preconditions — never write blind** — the Step-1 schema preflight must
    have passed (a missing `Source` value already halted the skill; s7 never
    re-checks or auto-creates); a failed s4 tracker read halts the write step.
  - **§3 field-by-field mapping (PRD §8)** for a new record — §3.1 existing
    fields, §3.2 the 16 reused fields, §3.3 the five new §8.4 fields, each with
    its live field ID (existing/reused from `config/search_config.md`; new from
    `evidence/s2-airtable-schema.md`). `Source` = `Off-Market — ASL Bolt-on`
    (Class 1) / `Off-Market — SBIC` (Class 2); `Disposition` = `Active`;
    `Listing ID` left blank (off-market uses the dedicated `Gov Entity ID`
    field per the §13 decision); `Asking Price`/EBITDA/Revenue/Cash-Flow written
    only for real disclosed figures, never signals. §3.4 the adapted
    4-identifier `Notes` block (carries the SBA-prior-approval fact for Class 2).
  - **§4 update an existing record** — refresh `Link Last Checked`/`Date
    Updated`, fill only blank gov fields without overwriting, update
    `Lead Score`/`Prospect Eval Report`, append a dated `Notes` line; never flip
    an on-market row's `Source`/`Disposition`.
  - **§5 the dashboard badge** — a `.chip.offmarket` class, sibling to the
    existing chips; rendered when `lead.source` starts with `"Off-Market"`;
    on-market rows unchanged; no `Source` column added.
  - **§6 failure/edge handling** — write retry-once then log for manual entry;
    `lead_score: null` still written (score blank, noted); Class-2
    `fail`/`conditional` gate still written as a normal `Active` row; never
    fabricate to fill a field; never auto-create a `Source` value/field.
- **`templates/daily-dashboard.html` — badge added** — new `.chip.offmarket`
  style (green, matching the `--pass` palette); the data-contract comment
  extended with the two off-market `source` values; the conditional
  `{% if lead.source.startswith('Off-Market') %}<span class="chip offmarket">
  OFF-MARKET</span>{% endif %}` added to Section A (New Finds), Section B
  (Running Queue), and Section C (Revisit Bucket) next to the business name.
  The condition is additive — `Overnight Search` / `Manual Submission` rows
  render exactly as before; the Section A `Source` column is unchanged.
- **`skill.md` Steps 6 and 8 updated** to point at `references/airtable_write.md`
  and describe the create/update split, the fail-loud-not-fabricate posture, and
  the badge render condition.

Constraints honored: no parallel tracker / no new scorer (s7 writes only
`tblSmNrHROMLm7vOS` and consumes the unmodified scorer's `ScoredLead`); never
fabricate (unknown fields left blank, signals never written into disclosed-
figure fields); fail loud (preflight is Step 1's job — s7 writes against a
confirmed schema, never auto-creates); never auto-send outreach (drafting is
s8, not here); SBA-prior-approval fact carried in the Class-2 `Notes` block;
B4 does not block this IMPLEMENT — the mapping reference and badge are built
regardless; the live record write is exercised in SELF-TEST.

Stage s7 → `drafted`. Next phase for s7: SELF-TEST (drive the procedure over the
s6 SELF-TEST `ScoredLead`s — confirm a Class-1 and a Class-2 record map
field-by-field per §3 with no fabricated field, an `existing` entity updates in
place per §4, and the `.chip.offmarket` badge renders on an off-market row while
an on-market row is unchanged).

## iter 22 — 2026-05-22 — s8 (Outreach drafting) — IMPLEMENT

Built the stage-s8 deliverable: the dedicated **proprietary-approach** off-market
outreach template and the draft-generation procedure — drafts only, never sent.

- **`config/offmarket_outreach_template.md`** — a **new sibling file**, not an
  edit to `config/outreach_templates.md`. The broker Templates A / C / D and
  their file are left exactly as they were (s8 Done-when: "the broker templates
  are untouched"). Contents:
  - A side-by-side of why off-market outreach differs (recipient = owner / SBIC
    GP principal directly, not a broker; premise = not for sale; ask = an
    exploratory conversation, no NDA/CIM). Cites §13 Q7 (operator-approved) and
    PRD §12 risk **R11** (broker-template mis-tone) as the rationale.
  - **Template OM-1 — Owner Approach** (Class 1, `Off-Market — ASL Bolt-on`):
    a peer-to-peer note from Applied Development to an ASL/CART/deaf-services
    company owner; two A/B subject variants; placeholders `[OWNER_NAME]`,
    `[BUSINESS_NAME]`, `[LOCATION]`, `[SPECIFIC_DETAIL]` with explicit
    never-fabricate fallbacks (unknown name → neutral greeting; no verified
    detail → omit the paragraph).
  - **Template OM-2 — SBIC GP Principal Approach** (Class 2, `Off-Market —
    SBIC`): a confidential note to a GP principal; the
    **SBA-prior-approval-of-change-of-control sentence is fixed body text**, not
    a placeholder, so every Class-2 draft carries the government
    change-of-control fact; two subject variants; same never-fabricate
    placeholder rules.
  - Subject-line-only A/B rotation (mirrors the broker file); Tone Guidance
    (6 points); Storage & Handling (draft only, `Notes` + dated
    `search_reports/offmarket_outreach_drafts_YYYY-MM-DD.md`, no-contact → no
    draft, variant tracking).
- **`.claude/skills/off-market-search/references/outreach_drafting.md`** — the
  s8 reference / Step-7 procedure. Stage I/O (consumes s7's written leads);
  the contact gate (no direct contact → no draft, logged contact-discovery
  follow-up) and disposition gate (`Revisit for Roll-up` → deferred); template +
  subject-variant selection; placeholder fill from real data only; the
  `--- OFF-MARKET OUTREACH DRAFT (NOT SENT) ---` draft-block format with the
  mandatory no-send markers; two-place storage mirroring on-market (`Notes` +
  the distinctly-named off-market daily drafts file); edge/failure handling
  (partial contact, no detail, per-lead error degradation, `Notes`-append
  failure still writes the file); constraints honored.
- **`skill.md` Step 7 updated** to point at `references/outreach_drafting.md`
  and `config/offmarket_outreach_template.md`, the OM-1/OM-2 per-class
  selection, the never-fabricate placeholder posture, the no-contact → no-draft
  rule, the two storage locations, and the no-send rule.

Constraints honored: never auto-send (drafts only, two storage locations both
marked NOT SENT); never fabricate (unknown contact/detail → "needs follow-up"
or omitted, no invented names/emails/facts); no parallel tracker (drafts append
to the existing row's existing `Notes` field; the daily file is a report
artifact); broker templates untouched (off-market uses its own sibling file —
`config/outreach_templates.md` not read or modified); SBA-prior-approval fact
carried on every Class-2 draft as fixed body text.

Stage s8 → `drafted`. Next phase for s8: SELF-TEST (generate a Class-1 OM-1
draft and a Class-2 OM-2 draft from the s6/s7 SELF-TEST leads — confirm no raw
`[...]` placeholder survives, the no-contact case yields no draft, the
SBA-prior-approval sentence appears in the OM-2 draft, and both storage
locations carry the NOT SENT markers).

## iter 25 — 2026-05-22 — s9 (Orchestration & cadence) — IMPLEMENT

Built the stage-s9 deliverable: the orchestration layer that wires the s2–s8
stage references into one end-to-end run, the manual single-entity path, the
run-log format, and the weekly cadence. s9 adds **no new pipeline logic** — it
is the glue between stages.

- **`.claude/skills/off-market-search/references/orchestration.md`** — the s9
  reference. Contents:
  - **§1 Stage hand-off contract** — a table of the fixed 1→9 run order, each
    step's reference, what it consumes, and the typed output it produces
    (`RawRecord[]` → `CanonicalEntity[]` → `LeadPacket[]` → `ScoredLead[]` →
    rows → drafts → dashboard → run log).
  - **§2 Failure containment** — the core orchestration rule: **hard halt**
    (Step 1 preflight fail, a failed Step 3 tracker read, an unrecoverable
    environment fault) vs. **graceful degrade** (a blocked adapter B1/B3, a
    single adapter error, a per-candidate enrichment/scoring failure, a
    per-record write failure, a no-contact lead). A degraded run is still a
    successful run — fewer/gap-flagged leads, every gap explicit in the log.
  - **§3 Run log** — the `search_reports/offmarket_run_log_YYYY-MM-DD.md`
    template (run type/outcome/blockers; sources queried with per-source status
    and counts; resolution & dedup counts; enrichment & scoring per class;
    Airtable creates/updates; outreach drafts; dashboard; operator follow-ups).
    Counts must be real, never estimated; Step 9 runs even on a halted run.
  - **§4 Manual single-entity path** — mirrors `submit-url`: one operator-named
    company/SBIC (by name+state, gov identifier, or URL) + target class; runs
    the Step 1 preflight, **seeds resolution directly** for that one entity
    (skips Step 2 bulk discovery), then Steps 3–9 unchanged; appends a dated
    manual section if a run log for today already exists; reports score, record
    URL, dedup verdict, and gaps. Same no-send / no-fabricate constraints.
  - **§5 Dry-run / fixture mode** — adapters read recorded `s3-fixtures/`
    payloads and the write is directed at a test context (never
    `tblSmNrHROMLm7vOS`); the run is labelled `dry-run`. Used for SELF-TEST and
    while B3/B4 are open.
  - **§6 Cadence** and **§7 Constraints** — point at `config/offmarket_schedule.md`.
- **`config/offmarket_schedule.md`** — the cadence definition. Weekly `/schedule`
  cron, **Mondays 06:00 local** (per §13 Q1); the trigger prompt summary; the
  registration command; **registration gated on B4** so the cron does not
  fail-loud weekly before the `Source` values exist; a local `launchd` fallback
  (for an environment without the Airtable/Playwright MCP servers); run-log
  locations; prerequisites. The off-market schedule is separate from the nightly
  on-market `config/schedule.md` and needs **no `op`** credential (no
  login-walled source) — which is why `/schedule` (not the on-market launchd)
  is appropriate, exactly as §13 directed.
- **`run-offmarket-search.sh`** (repo root, `chmod +x`, `bash -n` clean) — the
  headless `claude -p` weekly entrypoint, mirroring `run-overnight-search.sh`
  minus the `op` retrieval; logs to `output/logs/offmarket-search_YYYY-MM-DD.log`.
- **`config/launchd/ai.earnedout.offmarket-search.plist`** (`plutil -lint` OK) —
  the version-controlled launchd plist for the local fallback; weekly trigger
  `Weekday=1, Hour=6`.
- **`skill.md` updated** — the SKELETON banner replaced with a **WIRED, PENDING
  FINAL VERIFICATION** status (dry-run only until `OFFMARKET_BUILD_VERIFIED` and
  B4 cleared); Step 9 expanded to the §3 run-log template; a new **Orchestration**
  section summarising the halt-vs-degrade rule; the **Manual single-entity path**
  and **Cadence** sections expanded to point at `references/orchestration.md` §4
  and `config/offmarket_schedule.md`.

**Note on "cron registered" (s9 Done-when).** The cadence is fully *defined* and
version-controlled (config + trigger script + plist), but the **live** cron
registration is deliberately **not** performed by this unattended build
iteration: registering it now — while B4 is open — would make the weekly run
fail-loud at the schema preflight every Monday. `config/offmarket_schedule.md`
documents the one-line registration command as the install step gated on B4
clearing. This is the honest call (never schedule a run that is designed to
halt); SELF-TEST validates the definition artifacts.

Constraints honored: no new pipeline logic (s9 is glue only); no parallel
tracker / no new scorer; fail-loud halt vs. graceful degrade made explicit;
never fabricate (run-log counts are real); never auto-send outreach (Step 7
drafts only); dry-run mode prevents a build-time live write.

Stage s9 → `drafted`. Next phase for s9: SELF-TEST (exercise the end-to-end
wiring in dry-run/fixture mode — confirm the 1→9 hand-off, the halt-vs-degrade
behaviour, a manual single-entity run, and the run-log output; validate the
schedule artifacts: `bash -n` the script, `plutil -lint` the plist).

## iter 28 — 2026-05-22 — s10 (Assembly, end-to-end self-test & final audit) — IMPLEMENT

Built the stage-s10 IMPLEMENT deliverable: **the assembled end-to-end dry run on
a small fixture sample for both target classes** (`OFFMARKET_BUILD_PLAN.md` s10
"Builds": *"an end-to-end dry run on a small live (or fixture) sample for both
classes"*). s10 adds **no new pipeline logic** — it assembles. Where s9's
SELF-TEST verified the 1→9 *wiring*, this artifact runs the whole pipeline
through to scored records and a written-out run log for both classes.

- **`evidence/s10-e2e-dryrun.md`** — the end-to-end assembly. A small sample
  (R1 Class-1 fixture, R2 real Class-2 SBIC, plus SYN-NF1 / SYN-NC1 to exercise
  the pre-filter-drop and no-contact paths, plus the 3 live S1 + S3 fixture
  records for resolution volume); a step-by-step trace of Steps 1–9 against the
  stage references; the result — **≥1 scored record per class** (R1 30/110
  `rollup_addon`; R2 30/100 `sbic` informational, license gate PASS), both
  reports already on disk under `output/reports/`; and four honestly-carried
  limitations (B1/B3/B4 still open; R1 is a synthetic fixture, not a real
  S1-discovered company — IMPROVE-s3-1/s4-4/s6-2).
- **`evidence/s10-offmarket_run_log_e2e_dryrun.md`** — the Step-9 consolidated
  run log for the assembly, built from the `orchestration.md` §3 template using
  the **real** Step 2–8 counts (8 raw records → 7 canonical → 4 scored-eligible
  → 2 scored; 0 Airtable writes — dry-run; 2 drafts NOT SENT). A `0` is reported
  as `0`; every blocker and gap is named.

**Dry-run, not live (honest call).** Adapters read recorded `s3-fixtures/`
payloads + live key-free sources; the Airtable write is directed at a test
context, never `tblSmNrHROMLm7vOS`. A live weekly run halts at Step 1 (B4 — the
two off-market `Source` values do not exist; confirmed again this iteration by a
live `get_table_schema` read of `fldiGyXTk6Ybb6J1L` → only `Overnight Search` /
`Manual Submission`). No row written; nothing sent.

Constraints honored: no new pipeline logic / no parallel tracker / no new
scorer (s10 only assembles s1–s9); never fabricate (every unknown is a logged
gap; the two scored reports are the unmodified `prospect-evaluation` outputs);
never auto-send (2 drafts, NOT SENT); dry-run mode prevents a build-time live
write; the four open limitations are recorded, not papered over.

Stage s10 → `drafted`. Next phase for s10: SELF-TEST (exercise this assembly
against the s10 `Done-when` — confirm the dry run produces ≥1 scored record per
class into a test context with no fabricated field; then VERIFY by critic, then
the build-wide FINAL AUDIT once all 10 stages are `verified`).

---

## iter 31 — 2026-05-22 — s10 (Assembly, end-to-end dry run) — re-IMPLEMENT (BLOCKING-s10-1 fix)

The iter-30 VERIFY returned s10 to `not_started` on **BLOCKING-s10-1**: the R2
Class-2 report (`output/reports/name-1st-source-capital-south-bend-in/`) awarded
**10/10** for "Years in business ≥10" and returned Buy Box line 3 `✅ PASS`,
citing a formation date (1983-11-16), street address, SEC CIK, and CB Insights
data **absent** from its own `lead-packet.json` — which sets `formation_date`
and `years_in_business` to `null` and lists "formation date" in
`enrichment_gaps`. The report back-filled a gap the scorer must pass through as
missing (`scoring_integration.md` §3, lines 91-92/99), so packet and report
contradicted each other on disk.

This re-IMPLEMENT fixes it by reconciling the **report to the packet** (the
packet was already clean — the iter-30 critic confirmed it — so it was not
modified):

- **Re-scored R2 strictly from `lead-packet.json`.** Buy Box line 3 and the
  years-in-business rubric line are now ⚠️ "insufficient data — not awarded"
  (0/10). R2's honest score is **20/100**, not 30. Math: 20 (industry) + eight
  zero lines = 20.
- **Rewrote `1st-source-capital-corporation-report.md` and `.html`** so every
  value traces to the packet. Stripped the formation/incorporation date,
  street address, parent-company identity (1st Source Bank / Corp / Nasdaq
  SRCE) and parent financials, SEC EDGAR CIK, CB Insights portfolio data, and
  Wikipedia data. Appendix A now lists only the SBA SBIC directory and the
  `LeadPacket`; the report explicitly states no external sources were used.
  The SBIC fund vintage (1983) is retained **only** as informational
  fund-level data per `scoring_integration.md` §3.1 — not mapped to
  years-in-business.
- **Re-stamped the report banner** s6 SELF-TEST → s10 end-to-end dry-run
  artifact (it is now the s10 artifact), and updated the build-loop notes /
  footer to the 20/100 score.
- **Updated the s10 evidence** — `s10-e2e-dryrun.md` and
  `s10-offmarket_run_log_e2e_dryrun.md` now report R2 = 20/100, with an
  iter-31 re-IMPLEMENT note describing the fix.

Two non-blocking s10 findings were closed in the same files while reconciling
them: **IMPROVE-s10-1** (run-log outreach-draft path relabelled as the
dry-run/evidence path) and **IMPROVE-s10-2** (run log now states R3/R4 were
carried as Class-2 candidates but not scored).

Constraints honored: never fabricate (the report now contains no value outside
`lead-packet.json`); a gap stays a gap (`scoring_integration.md` §3); no new
scorer / no parallel tracker; the `prospect-evaluation` skill is unmodified;
nothing sent; no live Airtable write.

`unresolved_findings` 27 → 24 (BLOCKING-s10-1 + IMPROVE-s10-1 + IMPROVE-s10-2
resolved). Stage s10 → `drafted`. Next phase for s10: SELF-TEST — which **must**
read the report bodies field-by-field against `lead-packet.json` (not just the
two packet files — the gap the iter-29 SELF-TEST C3 check missed).

## iter 32 — 2026-05-22 — s2 (Airtable schema) — re-IMPLEMENT (B4 resolved)

s2 was reset `verified`-era → `not_started` by the operator intervention when
B4 was resolved, so the loop re-runs it against the now-complete live schema.
This re-IMPLEMENT confirms the deliverable and clears the stale "blocked /
operator-required" prose left over from when B4 was open.

- **Live schema re-confirmed.** A `get_table_schema` read of base
  `appOsvuyy5eK43QTx` / table `tblSmNrHROMLm7vOS` confirms every s2 element:
  - `Source` (`fldiGyXTk6Ybb6J1L`, singleSelect) — four choices:
    `Overnight Search`, `Manual Submission`, `Off-Market — ASL Bolt-on`
    (`selezt48WJR6jPv2m`), `Off-Market — SBIC` (`seltqCid0e9t6aijI`). The two
    off-market values verified byte-for-byte against `OFFMARKET_BUILD_PLAN.md`
    §8.3 — em dash U+2014, exact spacing/casing.
  - The five §8.4 fields — `Gov Entity ID` (singleLineText),
    `SBIC License #` (singleLineText), `SBIC License Status` (singleSelect, the
    five standing choices), `Gov Data Source` (multipleSelects, all eight
    choices), `Federal Award History $` (currency, `$`, precision 0) — all
    present with the correct types and field IDs.
- **`references/airtable_schema_preflight.md`** — the "Why `Source` options
  need an operator" section (which said the values *must* be added by the
  operator and cited B4 as open) was rewritten to "Schema status & why the
  preflight stays fail-loud": records the schema as complete, B4 as RESOLVED,
  and states the preflight still runs every invocation as a guard against later
  schema drift / a different base, never auto-creating. The Procedure section
  was already correct and is unchanged.
- **`evidence/s2-airtable-schema.md`** — rewritten from the iter-4 capture (which
  marked the `Source` values "NOT DONE" and s2 "blocked") to the iter-32 live
  re-confirmation: all six elements DONE, B4 resolved, with the live choice IDs
  recorded.

No schema write was performed this iteration — the fields and `Source` values
already exist (created via `create_field` in iter 4 and added by the operator
in the Airtable UI respectively). s2's deliverable — the schema changes plus the
fail-loud preflight — is complete.

Constraints honored: fail loud, never silent (the preflight is unchanged in
behaviour and still halts on any miss, never auto-creates); no parallel tracker
(same base/table); never fabricate (the schema was read live, not assumed).

Stage s2 → `drafted`. Next phase for s2: SELF-TEST (run the preflight procedure
against the live schema — confirm all six fields, both off-market `Source`
values, and the five `SBIC License Status` options are detected, and confirm
the check fails loud against a simulated missing element).

## iter 34 — 2026-05-22 — s7 (Airtable write & dashboard badge) — re-IMPLEMENT (B4 resolved)

s7 was built at iter 20 and reached `verified` before the operator intervention
reset it `verified`-era → `not_started` when B4 was resolved (so s8/s9, which
followed, were verified on top of a verified s7). The loop re-runs s7 against
the now-complete live schema. Like the iter-32 s2 re-IMPLEMENT, the deliverable
already exists and required no code change — this is a confirmation pass.

- **`references/airtable_write.md` confirmed intact.** The five §8.4 field IDs
  in §3.3 were cross-checked against `evidence/s2-airtable-schema.md` (which
  iter 32 re-confirmed live) — all five match byte-for-byte
  (`Gov Entity ID` `fld7Ook8ZoLAjwFTe`, `SBIC License #` `fldogicjVNMCBuyJI`,
  `SBIC License Status` `fldscFvXPUFYbSg3F`, `Gov Data Source`
  `fldM7KoR2gtfvBVWN`, `Federal Award History $` `fldZXrqqoBkIdDWJN`). The
  `Source` field ID `fldiGyXTk6Ybb6J1L` matches; the two off-market values it
  writes both exist as live `Source` choices since B4 resolved. The §2
  "never write blind" preconditions are forward-correct — the Step-1 preflight
  now passes, so s7 writes against a confirmed schema. **No stale "B4 open /
  blocked" prose is present** (s7 was written at iter 20 forward-correctly,
  unlike s2's preflight prose which iter 32 had to clean up).
- **Dashboard badge confirmed intact** — `templates/daily-dashboard.html`: the
  `.chip.offmarket` style (lines 154–155), the data-contract comment
  (lines 42–43), and the `lead.source.startswith('Off-Market')` render
  condition in all three row sections (lines 242 / 288 / 330). Additive — on-
  market rows unchanged, no `Source` column added.
- **`evidence/s7-airtable-write.md`** written — the field-ID cross-check table
  and the badge line references.

No live Airtable write was performed this iteration (the live record write is a
SELF-TEST concern, directed at a test context per the dry-run rule). s7's
deliverable — the field-by-field write procedure plus the dashboard badge —
is complete and consistent with the schema.

Constraints honored: no parallel tracker / no new scorer; never fabricate
(field IDs read from recorded live evidence, not assumed); fail loud (the
preflight is Step 1's job, unchanged); never auto-send (drafting is s8).

Stage s7 → `drafted`. Next phase for s7: SELF-TEST (drive the write procedure
over the s6 SELF-TEST `ScoredLead`s into a test context — confirm a Class-1 and
a Class-2 record map field-by-field per §3 with no fabricated field, an
`existing` entity updates in place per §4, and the `.chip.offmarket` badge
renders on an off-market row while an on-market row is unchanged).

## iter 37 — 2026-05-22 — s7 (Airtable write & dashboard badge) — IMPLEMENT (re-IMPLEMENT, BLOCKING-s7-1)

The iter-36 SELF-TEST failed C5 — the live `create_records_for_table` for R2
was rejected atomically with `HTTP 422: Insufficient permissions to create new
select option` — and logged BLOCKING-s7-1: `airtable_write.md` §3.1 mapped
`Lead Source` (`fldI1h3qmNI6vc5rr`) to a free-text human-readable gov-source
string, but the live field is a **singleSelect** restricted to 14
broker-platform options. Writing a gov-source string into it forces Airtable to
create a new select option, which the build constraints forbid (fail loud,
never silently create). This iteration fixes that defect.

- **§3.1 `Lead Source` row rewritten.** The off-market value is now **blank**.
  The row documents why: `Lead Source` is a singleSelect restricted to the 14
  broker-platform options (`Direct Outreach` … `BusinessBroker.net`), it cannot
  hold a gov-source string, and a gov source is not a broker platform. Gov
  provenance is already carried by the dedicated `Gov Data Source` multi-select
  (§3.3) and the source URL(s) in `Links` (§3.1) — no information is lost by
  leaving `Lead Source` blank. The row explicitly forbids auto-creating a select
  option to hold a gov value.
- **§6 hardened.** Added a bullet — "Never auto-create a select option on any
  field" — naming the exact failure mode: writing a value outside a
  singleSelect/multipleSelects option set makes Airtable reject the whole
  `create_records_for_table` call atomically with the 422 seen in iter 36. The
  rule: map only to existing options, or leave the field blank. This generalizes
  the pre-existing "never auto-create a `Source` value" rule to every select
  field.

No other §3/§4 mapping changed — every other field was already either an
existing option, a free-text/number/currency/date field, or a confirmed-live
select value (`Source`, `SBIC License Status`, `Gov Data Source`,
`Disposition`, `Industry Match`). No live Airtable write was performed this
iteration (the live R2 write is the SELF-TEST's job, next phase).

Constraints honored: no parallel tracker / no new scorer; never fabricate;
fail loud (the fix removes a silent-create path, it does not add one); never
auto-send. BLOCKING-s7-1 is resolved — moved to the FINDINGS.md "Resolved"
section; `unresolved_findings` 28 → 27.

Stage s7 → `drafted`. Next phase for s7: SELF-TEST — re-run the write procedure
including the live `create_records_for_table` of R2, now with `Lead Source`
left blank; confirm the row lands in `tblSmNrHROMLm7vOS` with `Disposition =
Active` (C5), and re-confirm C1–C4 and the badge.

## iter 42 — 2026-05-22 — s10 (Assembly, end-to-end dry run) — IMPLEMENT (re-IMPLEMENT, BLOCKING-s10-2)

The iter-41 VERIFY returned s10 to `not_started` on **BLOCKING-s10-2**: the R2
OM-2 outreach draft asserted "1st Source Capital Corporation has operated as a
licensed SBIC pursuing a direct-lending strategy **since 1983** — a long,
durable track record in the program." But the R2 lead packet
(`output/reports/name-1st-source-capital-south-bend-in/lead-packet.json`) sets
`formation_date: null` / `years_in_business: null` and lists "formation date —
needs follow-up (B1)" as an enrichment gap. `1983` is
`sbic_gp_economics.vintage` — the SBIC **fund's** vintage year — not a verified
company operating-start date. This is the BLOCKING-s10-1 fabrication defect
class recurring in the s10 dry run's outreach deliverable (Step 7). This
iteration fixes the draft and hardens the drafting logic so it cannot recur.

- **OM-2 draft rewritten** in
  `evidence/s8-offmarket_outreach_drafts_2026-05-22.md` (lines 85–87). The
  `[SPECIFIC_DETAIL]` sentence now reads "1st Source Capital Corporation is a
  licensed SBIC in good standing, pursuing a direct-lending investment
  strategy — exactly the kind of platform I follow closely." Both facts —
  `sbic_license_status: "Good Standing"` and `sbic_gp_economics.strategy:
  "Direct Lending"` — are verified in the R2 packet. The fabricated "since
  1983" operating-start year and the "long, durable track record" claim
  derived from it are removed.
- **`config/offmarket_outreach_template.md` OM-2 hardened.** The
  `[SPECIFIC_DETAIL]` placeholder spec — which previously listed "license
  vintage" as an allowed fact — now lists license status / investment
  strategy / license type, and adds an explicit rule: the packet's
  `sbic_gp_economics.vintage` is the *fund's* vintage year, **never** the
  management company's formation date / incorporation year / years in
  business; it must never be rendered as "operating since [vintage]" or any
  operating-start / track-record-length claim. Company operating history may
  be stated only from a non-null `formation_date` / `years_in_business`.
- **`references/outreach_drafting.md` hardened.** §2 step 5's `[SPECIFIC_DETAIL]`
  description drops "years operating, SBIC license type/vintage" in favor of
  "SBIC license status, investment strategy", with the same fund-vintage
  prohibition spelled out; §5 (Edge & failure handling) gains a dedicated
  "Fund vintage is not a company operating history" bullet.

Constraints honored: never fabricate (the `[SPECIFIC_DETAIL]` now traces
field-by-field to the packet; the fund-vintage rule prevents the same defect
class recurring); no new scorer / no parallel tracker; never auto-send (the
draft retains its NOT-SENT markers). BLOCKING-s10-2 is resolved — moved to the
FINDINGS.md "Resolved" section; `unresolved_findings` 30 → 29.

Stage s10 → `drafted`. Next phase for s10: SELF-TEST — re-run the s10 end-to-end
dry-run checks, reading the outreach drafts field-by-field against each lead
packet to confirm no draft asserts an operating history its packet flags as a
`null` gap.

## iter 46 — 2026-05-22 — s9 (Orchestration & cadence) — IMPLEMENT (re-IMPLEMENT, BLOCKING-s9-1)

The iter-45 FINAL AUDIT returned s9 to `not_started` on **BLOCKING-s9-1**: the
weekly cron was never live. `CronList` returned "No scheduled jobs" and
`launchctl list | grep offmarket` returned nothing. The script
(`run-offmarket-search.sh`), the launchd plist
(`config/launchd/ai.earnedout.offmarket-search.plist`) and
`config/offmarket_schedule.md` all existed and were correct, but live
registration had been honestly gated on blocker B4 (the iter-27 s9 VERIFY
documented it as the post-B4 install step). B4 is now RESOLVED — the gate has
cleared — so this iteration runs the registration.

- **Mechanism chosen: local `launchd` agent.** `config/offmarket_schedule.md`
  names a `/schedule` cron as the primary mechanism but explicitly directs the
  **local launchd fallback** when the `/schedule` environment cannot run the
  Airtable / Playwright MCP servers. The off-market skill writes to local repo
  files (`search_reports/`, `output/`, the dashboard) and drives the local
  Airtable + Playwright MCP servers, so a remote `/schedule` routine cannot run
  it — launchd is the correct, proven mechanism (it mirrors the on-market
  `ai.earnedout.overnight-search` agent). The `CronCreate` in-memory scheduler
  was rejected: its jobs only fire while a Claude REPL is idle, so a weekly
  Monday-06:00 trigger would not fire unattended.
- **Registered the weekly agent.** Copied
  `config/launchd/ai.earnedout.offmarket-search.plist` to
  `~/Library/LaunchAgents/` and bootstrapped it:
  `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.earnedout.offmarket-search.plist`
  (rc 0). `launchctl list | grep offmarket` now shows
  `ai.earnedout.offmarket-search`; `launchctl print` confirms the
  `StartCalendarInterval` is `Weekday => 1` (Monday), `Hour => 6` — matching
  `config/offmarket_schedule.md` (weekly, Monday 06:00 local) and
  build-plan Deliverable #7. State is `not running` (correct — `RunAtLoad` is
  `false`; the agent fires only on the calendar trigger).
- **`config/offmarket_schedule.md` Registration section updated** to record
  that the launchd agent is the registered mechanism (B4 cleared, the
  `/schedule` environment cannot reach the local repo / MCP), and that it is
  now live.

Constraints honored: never auto-send (the agent only invokes the skill, which
drafts outreach; no email path); no parallel tracker / no new scorer (the agent
runs the existing `off-market-search` skill against `tblSmNrHROMLm7vOS`);
nothing fabricated. BLOCKING-s9-1 is resolved — moved to the FINDINGS.md
"Resolved" section; `unresolved_findings` 30 → 29.

Stage s9 → `drafted`. Next phase for s9: SELF-TEST — exercise the assembled
skill / manual path and confirm the weekly agent is live and correctly
scheduled (`launchctl print` calendar interval), recording each check in
`TEST_LOG.md`.

## iter 48 — 2026-05-22 — s9 (Orchestration & cadence) — IMPLEMENT (re-run)

Re-IMPLEMENT after the iter-47 SELF-TEST T5 FAIL: three skill files still
documented the weekly cron as *not yet registered* and B4 as *open*, though
iter 46 registered the launchd agent live and B4 is resolved. No pipeline logic
changed — this iteration corrects only the three stale self-documentation
passages so the skill matches the registered reality.

- **`skill.md` BUILD STATUS header.** Dropped the stale claim that "the Step 1
  schema preflight will fail loud until blocker B4 ... is resolved". Now states
  B4 is resolved and the preflight passes. Kept the still-true status — the
  skill is not yet cleared for an unattended live run because the build loop
  has not reached `OFFMARKET_BUILD_VERIFIED`; run in dry-run / fixture mode
  until it does.
- **`skill.md` Cadence section.** Replaced "Live cron registration is gated on
  blocker B4 ..." with the registered reality: the weekly cron is registered
  and live as the local `launchd` agent `ai.earnedout.offmarket-search`
  (Monday 06:00 local), installed once B4 cleared (iter 46); pointer to
  `config/offmarket_schedule.md` "Registration".
- **`references/orchestration.md` §6.** Replaced "the **live registration** is
  the install step ... (it is gated on the B4 schema work ...)" with "the live
  registration is done — once B4 cleared (iter 46), the cron was installed as
  the local `launchd` agent `ai.earnedout.offmarket-search` (Monday 06:00
  local)".

Constraints honored: no pipeline logic touched; no parallel tracker / no new
scorer; nothing fabricated; the launchd state itself is unchanged (verified
live in the iter-47 SELF-TEST T3 — `ai.earnedout.offmarket-search` loaded,
`Minute=0, Hour=6, Weekday=1`). All three files now agree with
`config/offmarket_schedule.md`, which iter 46 already corrected.

Stage s9 → `drafted`. Next phase for s9: SELF-TEST — re-run the five checks,
which T5 (skill self-documentation matches the registered state) must now pass.

## iter 52 — 2026-05-23 — RESOLVE — F1 (s1 Markdown comment delimiter)

All 10 stages `verified`, `final_audit_passed: true`, `open_blockers: 0` —
the loop is in the RESOLVE phase, clearing `IMPROVE`/`NIT` findings one per
iteration before COMPLETE.

Resolved **F1** (IMPROVE, s1) — `config/offmarket_sources.md` lines 10–12
used a `/ … /` delimiter for the "Built by stage s1" note, which is not valid
Markdown comment syntax and rendered literally. Wrapped the note in a proper
`<!-- … -->` HTML comment so it no longer renders. No content or source-config
fact changed — cosmetic only. Confirmed no remaining `/ … /` pseudo-comment in
the file.

F1 moved to the FINDINGS.md "Resolved" section; `unresolved_findings` 31 → 30.
30 findings remain (F2 next). RESOLVE phase continues.

## iter 53 — 2026-05-23 — RESOLVE — F2 (s1 literal placeholder string)

All 10 stages `verified`, `final_audit_passed: true`, `open_blockers: 0` —
RESOLVE phase, clearing `IMPROVE`/`NIT` findings one per iteration.

Resolved **F2** (NIT, s1) — `config/offmarket_sources.md` line 7 carried the
literal string `⚠ VERIFY:` inside a negation sentence ("No `⚠ VERIFY:`
placeholders remain"), which a future automated placeholder scan could
false-positive on. Reworded the sentence to describe the marker without
quoting the literal token — now "No verify-this-value placeholder markers
remain". Confirmed the file no longer contains the `⚠ VERIFY:` literal
anywhere. Cosmetic only — no source-config fact changed.

F2 moved to the FINDINGS.md "Resolved" section; `unresolved_findings` 30 → 29.
29 findings remain. RESOLVE phase continues.

## iter 55 — 2026-05-22 — RESOLVE — IMPROVE-s3-1 (S1 USAspending UEI not populated)

All 10 stages `verified`, `final_audit_passed: true`, `open_blockers: 0` —
RESOLVE phase, clearing `IMPROVE`/`NIT` findings one per iteration.

Resolved **IMPROVE-s3-1** (IMPROVE, s3) — the S1 USAspending adapter in
`.claude/skills/off-market-search/references/source_adapters.md` claimed to map
`recipient UEI→uei`, but the `spending_by_award` endpoint does not return a
recipient UEI (only `Recipient Name` and the internal hashed `recipient_id`),
so S1 records resolved only on name+address — weakening s4 entity resolution,
whose primary key is `uei`.

Fix (doc/spec change to the adapter contract): rewrote the S1 Query block —
- step 1 now requests `recipient_id` in `fields` and states explicitly that
  `spending_by_award` carries no UEI;
- new step 2 adds the required recipient-detail follow-up:
  `GET /api/v2/recipient/{recipient_id}/` per distinct `recipient_id`, reading
  `uei` (plus `duns`/location), cached per `recipient_id`, paced ~1 req/sec; a
  failed/empty detail call sets `uei: null` (s4 falls back to the name+address
  ladder) — never fabricate a UEI;
- the bulk-download path (step 3) reads the `recipient_uei` CSV column directly
  and skips the follow-up;
- the Map bullet now states `uei` comes from the follow-up or the bulk CSV
  column, never from `spending_by_award`, and groups by `recipient_id` then
  resolved UEI.

Constraints honored: no fabrication (missing UEI → `null`, not invented);
common adapter interface unchanged so s4–s6 are unaffected; no pipeline logic,
no parallel tracker, no new scorer touched.

IMPROVE-s3-1 moved to the FINDINGS.md "Resolved" section; `unresolved_findings`
28 → 27. 27 findings remain. RESOLVE phase continues.

## iter 56 — 2026-05-22 — RESOLVE — IMPROVE-s4-1 (`dedup_verdict` enum omits `needs_operator_review`)

All 10 stages `verified`, `final_audit_passed: true`, `open_blockers: 0` —
RESOLVE phase, clearing `IMPROVE`/`NIT` findings one per iteration.

Resolved **IMPROVE-s4-1** (IMPROVE, s4) — the `CanonicalEntity.dedup_verdict`
field in `.claude/skills/off-market-search/references/entity_resolution.md` was
typed `new | existing`, but §4 routes an entity missing all identifiers and
address to a `needs_operator_review` state that the enum never represented.

Fix (spec-clarity change): of the two fixes the critic offered — widen the enum,
or note that such entities are excluded before a verdict — chose the note.
`needs_operator_review` is genuinely a run-log exclusion status, not a verdict:
§4 excludes such an entity from the write *before* §3 dedup runs, so it never
reaches a verdict. Expanded the `dedup_verdict` row note (line 61) to state the
verdict is assigned only to an entity that survives §2 resolution, that an
identifier-and-address-less entity is excluded as `needs_operator_review` (§4)
before any verdict is assigned, and that `needs_operator_review` is a run-log
exclusion status, not a `dedup_verdict` value.

Constraints honored: cosmetic/spec-clarity only — no resolution, dedup, or
write behavior changed; no pipeline logic, parallel tracker, or scorer touched.
(Note: NIT-s9-1 flags the same enum/status distinction at
`orchestration.md:26` — left open for its own RESOLVE iteration.)

IMPROVE-s4-1 moved to the FINDINGS.md "Resolved" section; `unresolved_findings`
27 → 26. 26 findings remain. RESOLVE phase continues.

---

## Iteration 58 — RESOLVE — IMPROVE-s4-2

RESOLVE phase, clearing `IMPROVE`/`NIT` findings one per iteration.

Resolved **IMPROVE-s4-2** (IMPROVE, s4) — the §2.1 resolution key ladder in
`.claude/skills/off-market-search/references/entity_resolution.md` is headed
"first key that produces a match," but the Legacy DUNS step (item 3) carried a
non-obvious override ("never resolve solely on DUNS when a UEI is available"),
leaving the ladder semantics ambiguous about when the DUNS step actually runs.

Fix (spec-clarity change): rewrote item 3 to state explicitly that the DUNS
step is a documented exception to first-match-wins — the DUNS key is evaluated
only after confirming that neither record under comparison carries a
`norm_uei`; if either record has a UEI, the DUNS step is skipped entirely, the
UEI cluster is preferred, and the DUNS is attached to it. The step now reads
unambiguously: DUNS is never the deciding key whenever a UEI is present on
either side.

Constraints honored: cosmetic/spec-clarity only — no resolution, dedup, or
write behavior changed (the prior text already mandated the same outcome); no
pipeline logic, parallel tracker, or scorer touched.

IMPROVE-s4-2 moved to the FINDINGS.md "Resolved" section; `unresolved_findings`
25 → 24. 24 findings remain. RESOLVE phase continues.

---

## Iteration 59 — RESOLVE — NIT-s4-1

RESOLVE phase, clearing `IMPROVE`/`NIT` findings one per iteration.

Resolved **NIT-s4-1** (NIT, s4) — the iter-10 s4 critic flagged the example
`entity_id` `SBIC:09/79-0292` in `entity_resolution.md` §5 as embedding a slash:
harmless in the plain-text `Gov Entity ID` field, but mildly fragile as an
identifier key, with no spec text addressing how slashes are handled.

Fix (spec-clarity change): added a "Slashes in `SBIC:<license_no>`" note to
`.claude/skills/off-market-search/references/entity_resolution.md` §5, after the
`entity_id` construction bullets. It states SBA SBIC license numbers carry an
embedded slash (e.g. `09/79-0292` → `SBIC:09/79-0292`), that the license number
is retained **verbatim** in the `SBIC:` key — not stripped, escaped, or
normalized — and why that is safe: `entity_id` / `Gov Entity ID` is a plain
identifier string, compared literally by dedup key A and stored as text in
Airtable, so an embedded slash is harmless there. It also notes any
filesystem-path use must sanitize at the consuming step, while the canonical
key stays verbatim so the same firm yields the same id across runs.

The stale `SBIC:09/79-0292` literal the critic cited had already been removed
by a prior edit (§5 now carries the `SBIC:<license_no>` placeholder); this
RESOLVE adds the missing slash-handling note the finding's fix called for.

Constraints honored: cosmetic/spec-clarity only — no resolution, dedup, or
`entity_id` construction behavior changed; no pipeline logic, parallel tracker,
or scorer touched.

NIT-s4-1 moved to the FINDINGS.md "Resolved" section; `unresolved_findings`
24 → 23. 23 findings remain. RESOLVE phase continues.

---

## Iteration 60 — RESOLVE — IMPROVE-s4-3

RESOLVE phase, clearing `IMPROVE`/`NIT` findings one per iteration.

Resolved **IMPROVE-s4-3** (IMPROVE, s4) — the iter-10 s4 critic flagged that
the s4 SELF-TEST evidence asserts R1's merged `naics`/`psc`/`award_total`
values in the §6.1 cluster bullet without showing the per-field union
derivation, so the merge spot-check was not fully reproducible from the
evidence alone.

Fix (evidence-only change): added an "R1 per-field merge trace" subsection to
`evidence/s4-selftest.md`, immediately after the §6.1 output line. It is an
8-row table covering every R1 field (`legal_name`, `uei`, `cage_code`, `naics`,
`psc`, `award_total`, `source_ids`, `source_urls`) and shows
`rec 4 (S2) value` ⊕ `rec 5 (S3) value` → `merged value` plus the union step
for each — deduped set union for the multi-valued fields, single non-null /
identical value for the scalars. Each merged value was cross-checked against
the s3 fixtures (`evidence/s3-fixtures/S2.json`, `S3.json`): `cage_code 0ZZ11`
is rec 4 only; `psc [R608]` and `award_total 480000` are rec 5 only (S3
`pscCode` / `obligatedAmount`); `naics [541930]`, `uei`, `legal_name` are
identical in both contributors. The trace also footnotes that the cluster
bullet's inline `psc … (from rec 3-shape)` provenance label is a separate
cosmetic mis-citation tracked as NIT-s5-1 (the correct contributor is rec 5/S3,
as the trace shows) — so the new trace introduces no hidden contradiction.

Constraints honored: evidence-only change — no resolution, dedup, or merge
behavior changed; the §6.1 cluster bullet's asserted values are unchanged, the
trace only makes them reproducible; no pipeline logic, parallel tracker, or
scorer touched.

IMPROVE-s4-3 moved to the FINDINGS.md "Resolved" section; `unresolved_findings`
23 → 22. 22 findings remain. RESOLVE phase continues.

---

## Iteration 61 — RESOLVE — NIT-s5-1

RESOLVE phase, clearing `IMPROVE`/`NIT` findings one per iteration.

Resolved **NIT-s5-1** (NIT, s5) — the iter-13 s5 critic flagged that the §6.1
R1 cluster bullet in the s4 SELF-TEST evidence describes R1's merged
`psc [R608]` as coming "from rec 3-shape", but record 3 is a different entity
(an S1 record), not a contributor to the R1 (rec 4 + rec 5) UEI merge. Cosmetic
provenance mis-citation in the s4 evidence.

Fix (evidence-only change): changed the §6.1 R1 cluster bullet in
`evidence/s4-selftest.md` from `psc [R608]` "(from rec 3-shape)" to
`psc [R608]` "(from rec 5/S3 only)". The correct sole contributor is rec 5
(S3 `pscCode`) — rec 4 (S2) carries no `psc` — as the iter-60 "R1 per-field
merge trace" table already establishes. Also refreshed the merge-trace
footnote, which had named the inline label as a still-open NIT-s5-1
mis-citation; it now records that the citation was corrected in this iteration
and matches the trace.

Constraints honored: evidence-only change — no resolution, dedup, or merge
behavior changed; the merged R1 `psc` value itself is unchanged ([R608]); no
pipeline logic, parallel tracker, or scorer touched.

NIT-s5-1 moved to the FINDINGS.md "Resolved" section; `unresolved_findings`
22 → 21. 21 findings remain. RESOLVE phase continues.

## Iteration 62 — RESOLVE — NIT-s6-1

RESOLVE phase, clearing `IMPROVE`/`NIT` findings one per iteration.

Resolved **NIT-s6-1** (NIT, s6) — the iter-19 s6 critic flagged that the C1
evidence line in `evidence/s6-selftest.md` (line 18) cites the R1 score lines
as `example-interpreting-fixture-llc-report.md:29,64,70`, but the per-line
breakdown total is at line 85, not 70. Cosmetic stale line citation.

Fix (evidence-only change): changed the C1 citation from `:29,64,70` to
`:29,64,85`. Verified against `output/reports/uei-zztest00fix1/example-
interpreting-fixture-llc-report.md` on disk — line 29 is the
`**Lead Score:** **30 / 110**` header, line 64 is scorecard field 26, and the
breakdown **total** row (`| **Total** | **30** | **110** | |`) is at line 85;
line 70 is only the `## Lead Score Breakdown` heading. The self-test text
describes the third citation as "the per-line breakdown total", so 85 is the
intended target.

Constraints honored: evidence-only change — the 30/110 R1 score, the C1 PASS
verdict, and the report on disk are all unchanged; no skill code, spec,
parallel tracker, or scorer touched.

NIT-s6-1 moved to the FINDINGS.md "Resolved" section; `unresolved_findings`
21 → 20. 20 findings remain. RESOLVE phase continues.

## Iteration 63 — RESOLVE — IMPROVE-s5-4

RESOLVE phase, clearing `IMPROVE`/`NIT` findings one per iteration.

Resolved **IMPROVE-s5-4** (IMPROVE, s5) — the iter-16 s5 critic flagged that
C7 of `evidence/s5-selftest.md` cites stale "Matches line 97" / "Matches line
125" cross-references. After the iter-15 self-test rewrite the actual
`gov_data_source` rows moved; lines 97/125 are now unrelated rows
(`years_in_business`, `formation_date`).

Fix (evidence-only change): changed C7 item 1 "Matches line 97 of this file"
→ "line 104" and C7 item 2 "Matches line 125" → "line 132". Verified against
the file on disk — the R1 `gov_data_source` row
(`["SAM.gov", "SAM.gov Contract Awards"]`) is at line 104 and the R2
`gov_data_source` row (`["SBA SBIC"]`) is at line 132; old lines 97/125 are the
unrelated `years_in_business` / `formation_date` rows. The iter-15 re-run
header (line 5) carried the identical stale `97 / 125` pair describing the
iter-14 choice-string fix — updated it to `104 / 132` so the whole file is
internally consistent.

Constraints honored: evidence-only change — the C7 PASS verdict, the §5.1
`source_id → Gov Data Source` mapping behavior, and every `gov_data_source`
value are unchanged; no skill code, spec, parallel tracker, or scorer touched.

IMPROVE-s5-4 moved to the FINDINGS.md "Resolved" section; `unresolved_findings`
20 → 19. 19 findings remain. RESOLVE phase continues.

## Iteration 64 — RESOLVE — IMPROVE-s5-1

RESOLVE phase, clearing `IMPROVE`/`NIT` findings one per iteration.

Resolved **IMPROVE-s5-1** (IMPROVE, s5) — the iter-13 s5 critic flagged that
the §3.1 screenshot path `output/screenshots/{entity-id}.png` claimed to match
the `overnight-search` convention, but `overnight-search` uses a plain
alphanumeric `listing-id` whereas the off-market `entity_id` embeds `:`, `|`,
spaces, and `/` (SBIC license numbers) — characters that are illegal or fragile
in filenames.

Fix (spec-clarity change to `.claude/skills/off-market-search/references/enrichment.md`
§3.1): changed `{entity-id}` to `{entity-id-slug}` and added an explicit slug
rule — lowercase the `entity_id`, replace every run of any character outside
`[a-z0-9]` (covering `:`, `|`, `/`, whitespace) with a single `-`, collapse
consecutive `-`, trim leading/trailing `-`. Worked examples added:
`UEI:ZZTEST00FIX1` → `uei-zztest00fix1`,
`NAME:abacus finance group|new york ny` → `name-abacus-finance-group-new-york-ny`,
`SBIC:09/79-0292` → `sbic-09-79-0292`. The rule states the canonical
`entity_id` is unchanged (stays verbatim in `Gov Entity ID` per
`entity_resolution.md` §5) and that only the screenshot filename is slugified;
`screenshot_path` records the actual on-disk path. The slug form matches the
existing `output/reports/` directory naming (`uei-zztest00fix1/`,
`name-1st-source-capital-south-bend-in/`), so the skill is now internally
consistent.

Constraints honored: spec-clarity only — no enrichment behavior changed (R1's
`screenshot_path` was `null`, so the path was never exercised); no parallel
tracker, no scorer touched, no data fabricated.

IMPROVE-s5-1 moved to the FINDINGS.md "Resolved" section; `unresolved_findings`
19 → 18. 18 findings remain. RESOLVE phase continues.

---

## iter 65 — RESOLVE — NIT-s5-2

RESOLVE phase, clearing `IMPROVE`/`NIT` findings one per iteration.

Resolved **NIT-s5-2** (NIT, s5) — the iter-13 s5 critic flagged that the
`LeadPacket.employee_count` field was typed `number | string`, inconsistent
with every other unknown-able field, which uses a `… | null` type plus an
`enrichment_gaps` `"needs follow-up"` entry.

Fix (spec-clarity change):
- `.claude/skills/off-market-search/references/enrichment.md` — retyped
  `employee_count` in the `LeadPacket` table from `number | string` to
  `number | null` (note: "§3.3 — number, else `null` with an
  `"employee count — needs follow-up"` gap"). Reworded the §3.3
  `employee_count` bullet so an absent count yields `null` (not the string
  `"needs follow-up"`) with the gap recorded in `enrichment_gaps` — the same
  pattern `website` / `formation_date` already use.
- `.claude/skills/off-market-search/references/scoring_integration.md:100` —
  changed the Employee count row note `often "needs follow-up"` → `often null
  (a gap → passed as missing)`, consistent with the adjacent
  years-in-business row.
- `Off-Market Search/_ralph_build/evidence/s5-selftest.md` C4 row — changed
  the R1 `employee_count` value `"needs follow-up"` → `null`; the
  `"employee count — needs follow-up"` gap was already enumerated in that
  packet's `enrichment_gaps` (line 107).

`airtable_write.md:89` already maps a non-real count to blank — consistent
with `null`, no change needed.

Constraints honored: spec-clarity only — an absent count was already a gap
listed in `enrichment_gaps`; only its typed value/sentinel is now consistent.
No enrichment, scoring, or Airtable-write behavior changed; no parallel
tracker, no scorer touched, no data fabricated.

NIT-s5-2 moved to the FINDINGS.md "Resolved" section; `unresolved_findings`
18 → 17. 17 findings remain. RESOLVE phase continues.

---

## iter 69 — RESOLVE — IMPROVE-s3-2

RESOLVE phase, clearing `IMPROVE`/`NIT` findings one per iteration.

Resolved **IMPROVE-s3-2** (IMPROVE, s3) — s3 was verified while blocker B1 was
open, so the S8 state-source adapter (priority-state eProcurement portals +
Secretary-of-State registries) was left as a fixture-shell. B1 is now RESOLVED:
the Phase-1 priority jurisdictions are **DC, VA, MD, PA, WV**.

Fix — rebuilt the S8 adapter from a fixture-shell to a working adapter:
- `.claude/skills/off-market-search/references/source_adapters.md` — rewrote the
  S8 section. Header `BLOCKED by B1` → `B1 RESOLVED — DC, VA, MD, PA, WV`. Added
  a per-jurisdiction portal table (eProcurement portal + SOS registry hosts for
  each of DC/VA/MD/PA/WV), a B1-mandated per-jurisdiction ToS-confirmation gate
  (honor `robots.txt`, read Terms of Use, prefer official open-data export/API
  over scraping, pace ≤1 req/2s, skip — `degraded` — any jurisdiction whose ToS
  is unconfirmed or prohibits automation), the eProcurement keyword query + SOS
  name-lookup query, the `RawRecord` mapping (state portals carry no UEI/CAGE →
  s4 resolves on name+address; SOS formation date/status/officers feed s4 and
  the s5 SOS lookup), and `ok`/`degraded`/`error` status semantics — never
  `blocked`. Registry table S8 row updated to `ok (B1 resolved …)`. The
  `AdapterMeta.blocker_id` example was genericized off the resolved B1/B3
  literals.
- `Off-Market Search/_ralph_build/evidence/s3-fixtures/S8.json` — new structural
  fixture with one sample record per jurisdiction (DC/VA/MD/PA/WV) in the
  eProcurement + SOS shape; fixtures `README.md` updated with the S8 row.
- `config/offmarket_sources.md` — S8 entry status `blocked by B1` →
  `not blocked (B1 resolved)`, with the five jurisdictions' portals listed.

No live state-portal call was made this iteration — each of the five portals'
Terms of Use must be confirmed first (the B1 mandate), which a headless run
cannot complete. The adapter is spec-complete; the per-jurisdiction ToS gate +
fixture fallback are documented for the live run (same posture as IMPROVE-s3-3
took for the SAM adapters). The common adapter interface is unchanged, so
s4–s6 are unaffected.

Constraints honored: no data fabricated (fixture identifiers are explicit
placeholders), no parallel tracker, no scorer touched, no outreach sent. The
B1-gated s5 SOS formation-date lookup remains separately tracked as the
still-open IMPROVE-s5-5.

IMPROVE-s3-2 moved to the FINDINGS.md "Resolved" section; `unresolved_findings`
14 → 13. 13 findings remain. RESOLVE phase continues.

## iter 70 — RESOLVE — IMPROVE-s5-2

Resolved **IMPROVE-s5-2** (IMPROVE, s5) — the Class-2 SBIC pre-filter §2.2
condition 2 ("good standing not already disproven") depends on the §4
good-standing cross-check, but §2 pre-filters run **before** §3/§4 enrichment.
On a first run the cross-check has not executed, so the condition can only fire
on a re-run with a cached/prior-run result — it read as a substantive
first-pass gate that it is not.

Fix — reworded §2.2 condition 2 in
`.claude/skills/off-market-search/references/enrichment.md` to state explicitly
that it checks only a *prior-run or cached* §4 standing result: on a first run
no §4 cross-check has executed yet, so there is nothing to disprove and the
candidate passes; a cached `Revoked`/`Surrendered` standing drops it here, and
otherwise (no cached standing, or unconfirmed) the candidate passes the
pre-filter, the §4 cross-check then runs in this run's enrichment, and the
scorer's SBIC gate handles an unconfirmed standing as CONDITIONAL (§7.3).

Spec-clarity only; no pre-filter, enrichment, or scoring behavior changed — an
unconfirmed standing already passed the pre-filter, and the §4 cross-check
already runs as enrichment. Constraints honored: no data fabricated, no
parallel tracker, no scorer touched, no outreach sent.

IMPROVE-s5-2 moved to the FINDINGS.md "Resolved" section; `unresolved_findings`
13 → 12. 12 findings remain. RESOLVE phase continues.

## iter 71 — RESOLVE — IMPROVE-s5-5

Resolved **IMPROVE-s5-5** (IMPROVE, s5) — the §3.2 Secretary-of-State
formation-date lookup was left as a B1-gated "skip the lookup" placeholder when
s5 was verified with B1 open. B1 is resolved (DC, VA, MD, PA, WV) and last
iteration's IMPROVE-s3-2 turned the s3 S8 adapter into a working adapter with
named SOS / business-registry surfaces — so the s5 lookup is now wirable.

Fix — rewrote §3.2 of
`.claude/skills/off-market-search/references/enrichment.md`:
- the SOS lookup now **runs** for any entity in one of the five Phase-1
  jurisdictions, driving the matching S8 SOS-registry surface (DC CorpOnline,
  VA SCC CIS, MD SDAT / Business Express, PA Dept. of State, WV SOS), each
  named with its host, under the S8 per-jurisdiction ToS gate; a `legal_name` +
  city name lookup yields `formation_date`, `sos_status`, officers;
- an out-of-Phase-1 entity is skipped by design with the gap reworded to drop
  the resolved-B1 reference (`"… (state SOS not in Phase-1 scope)"`);
- an in-scope no-match / ToS-skipped registry is a distinct logged gap — never
  a fabricated date.
Also updated the file intro paragraph and the §6 edge-handling bullet to drop
the stale "B1 unresolved" wording.

Spec-clarity + wiring of a now-available deliverable; no fabrication path
introduced — every not-found case stays a logged gap. Constraints honored: no
data fabricated, no parallel tracker, no scorer touched, no outreach sent.

IMPROVE-s5-5 moved to the FINDINGS.md "Resolved" section; `unresolved_findings`
12 → 11. 11 findings remain. RESOLVE phase continues.

---

## iter 72 — RESOLVE — IMPROVE-s4-4 (S1 not exercised by the accuracy spot-check)

RESOLVE phase. All 10 stages `verified`, `final_audit_passed: true`,
`open_blockers: 0`; cleared one IMPROVE finding.

IMPROVE-s4-4 — the s4 resolution-accuracy spot-check only ever exercised the
S2/S3/S4 structural fixtures: every S1 (USAspending) record routed to
`needs_operator_review` because the S1 adapter did not populate `uei`/address
(IMPROVE-s3-1), so the ≥95% target was never measured against the primary
Class-1 discovery source. The fix asked to gate s10's larger-sample spot-check
on IMPROVE-s3-1 closing.

IMPROVE-s3-1 is now resolved (iter 55 — S1 adapter populates a real `uei` via
the `recipient/{recipient_id}` follow-up), so the gate's precondition has
cleared. Fix:
- added an **"S1 coverage gate"** paragraph to §6 of
  `.claude/skills/off-market-search/references/entity_resolution.md` —
  it records why the s4 SELF-TEST sample never exercised S1, notes IMPROVE-s3-1
  is resolved, and **requires s10's larger-sample accuracy spot-check to
  include real S1-sourced resolution clusters** once a live S1 query has run,
  recorded in `TEST_LOG.md`;
- refreshed the stale "Caveat" bullet in `evidence/s4-selftest.md` — it cited
  "once B3 (SAM.gov key) clears" (B3 was never the real gate); it now
  attributes the gap to IMPROVE-s3-1 and points at the §6 S1-coverage gate.

Spec-clarity / evidence change only; no resolution, dedup, or merge behavior
changed. Constraints honored: no data fabricated, no parallel tracker, no
scorer touched, no outreach sent.

IMPROVE-s4-4 moved to the FINDINGS.md "Resolved" section; `unresolved_findings`
11 → 10. 10 findings remain. RESOLVE phase continues.

---

## iter 76 — RESOLVE — NIT-s9-1 (`dedup_verdict` enum vs. hand-off table)

RESOLVE phase. All 10 stages `verified`, `final_audit_passed: true`,
`open_blockers: 0`; cleared one NIT finding.

NIT-s9-1 — the §1 stage hand-off table in `orchestration.md` listed Step 3's
output as `CanonicalEntity[]` tagged `new / existing / needs_operator_review`,
presenting `needs_operator_review` as if it were a third `dedup_verdict` enum
value. `entity_resolution.md:61` types `dedup_verdict` as only `new | existing`;
`needs_operator_review` is a run-log exclusion status (§4), not a verdict.
Cosmetic — needs-review entities are excluded from the write before §3 dedup,
never handed downstream.

Fix (footnote option):
- reworded the §1 table Step 3 "Produces" cell — now `CanonicalEntity[]`, each
  carrying `dedup_verdict` `new` / `existing`; identifier-and-address-less
  entities excluded as `needs_operator_review`, with a `[†]` marker;
- added a `[†]` footnote after the table stating Step 3 yields exactly two
  `dedup_verdict` values, that only entities surviving §2 resolution are
  assigned one (cross-ref `entity_resolution.md:61`), and that
  `needs_operator_review` is the §4 exclusion status applied before §3 dedup —
  never passed downstream since Step 4 consumes only `new` entities.

Aligns `orchestration.md` with the `entity_resolution.md:61` note from the
IMPROVE-s4-1 resolution (iter 56). Spec-text clarity only; no orchestration,
resolution, or dedup behavior changed. Constraints honored: no data fabricated,
no parallel tracker, no scorer touched, no outreach sent.

NIT-s9-1 moved to the FINDINGS.md "Resolved" section; `unresolved_findings`
7 → 6. 6 findings remain. RESOLVE phase continues.

---

## iter 77 — RESOLVE — NIT-s9-4 (frozen s9 dry-run run log cited B4 as open)

RESOLVE phase. All 10 stages `verified`, `final_audit_passed: true`,
`open_blockers: 0`; cleared one NIT finding.

NIT-s9-4 — `evidence/s9-offmarket_run_log_dryrun.md`, the frozen iter-26 s9
SELF-TEST dry-run run log, still listed B4 as an open blocker ("a live run
would halt at Step 1 preflight") and carried a B4 operator follow-up. B4 — and
B1/B3 — are all RESOLVED (`BLOCKERS.md`; `open_blockers: 0`). Same stale-blocker
class as the already-resolved IMPROVE-s10-3 / NIT-s9-3. Not BLOCKING: a frozen
SELF-TEST artifact, not a skill/spec deliverable or a live run log.

Fix (refresh option):
- added an "Iter-77 refresh note (NIT-s9-4)" paragraph to the SELF-TEST callout
  box — records the run log is frozen at its iter-26 state, B1–B4 are all
  resolved, and the fixture/dry-run usage is now governed by the recorded-
  fixture practice of the (since RESOLVED) `IMPROVE-s3-2`/`-s3-3`/`-s5-5`
  adapter-rebuild findings, not any open blocker;
- "Outcome" — "blocked adapters used fixtures" → "quota-limited and ToS-gated
  adapters used recorded fixtures";
- "Open blockers affecting this run" — "B1, B3, B4" → "none — B1–B4 are all
  RESOLVED";
- "Sources queried" status column — S2/S3 `blocked (B3)` and S8 `blocked (B1)`
  → `fixture`, with recorded-fixture notes (conserve the SAM.gov public ~10/day
  quota; S8 per-jurisdiction ToS gate not exercised this dry run);
- "Airtable writes" — dropped the "B4-blocked (Step 1 preflight halt)" claim;
  now states the preflight passes (all four `Source` choices live, confirmed by
  the iter-38 s7 live write `recklDY7vHFmKauQD`);
- "Follow-ups for the operator" — removed the B1/B3/B4 bullets (all resolved);
  re-attributed the needs-operator-review bullet to `IMPROVE-s3-1` (RESOLVED
  iter 55, which rewired S1 `uei` population).

Evidence-refresh only; no skill code, spec, orchestration, scoring, or write
behavior changed — the dry run's counts and the s9 `Done-when` criteria are
unchanged and s9 stays `verified`. Constraints honored: no data fabricated, no
parallel tracker, no scorer touched, no outreach sent.

NIT-s9-4 moved to the FINDINGS.md "Resolved" section; `unresolved_findings`
6 → 5. 5 findings remain (IMPROVE-s5-3, IMPROVE-s6-2, IMPROVE-s8-1, NIT-s9-2,
NIT-s10-1). RESOLVE phase continues.
