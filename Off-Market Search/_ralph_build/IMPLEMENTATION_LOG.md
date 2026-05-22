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
