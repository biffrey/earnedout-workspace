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
