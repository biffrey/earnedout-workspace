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
