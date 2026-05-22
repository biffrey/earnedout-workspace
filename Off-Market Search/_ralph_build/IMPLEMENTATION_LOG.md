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
