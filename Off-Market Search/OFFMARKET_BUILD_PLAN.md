# Off-Market Target Search — Canonical Build Plan (the "what")

> This is the **canonical plan** the off-market **BUILD** Ralph loop drives to
> completion. `OFFMARKET_BUILD_LOOP_PROMPT.md` describes *how* to drive it; this
> file describes *what* must end up built. Re-read it every iteration.
>
> **Deliverable of the loop:** a working `off-market-search` skill (plus a manual
> single-entity path, config, Airtable schema changes, a dashboard badge, and an
> off-market outreach template) that surfaces off-market acquisition targets and
> writes them into the existing Master Deal Pipeline tracker.
>
> **This loop is a BUILD pass.** Unlike the PRD loop (which was planning-only),
> this loop writes real code/config/skill files, calls live government APIs, and
> makes real changes to Airtable and the dashboard. It is bounded by the
> constraints in the final section — never auto-send outreach, never fabricate
> data, never create a parallel tracker.

| | |
|---|---|
| **Predecessor loop** | Off-Market PRD loop — COMPLETE (`_ralph/STATE.md`, iter 6, `OFFMARKET_PRD_VERIFIED`) |
| **This loop's working dir** | `Off-Market Search/_ralph_build/` |
| **This loop's promise token** | `OFFMARKET_BUILD_VERIFIED` |
| **Bootstrapped** | 2026-05-21 — iteration 0, awaiting first run |

---

## Authoritative inputs (re-read the relevant parts every iteration)

1. **`PRD_OFF_MARKET_SEARCH.md` v1.0** — the requirements. §3 target classes,
   §4 sources, §5 keys, §6 resolution, §7 qualification, §8 schema, §9 workflow,
   §10 integration, §11 compliance.
2. **`PRD_OFF_MARKET_SEARCH_Section13_Resolution.md`** — operator decisions and
   the primary-source verification of every `⚠ VERIFY:` item. **Where the
   resolution doc and the PRD conflict, the resolution doc wins** (it is newer
   and operator-approved).
3. **On-market system, for parity:** `REVAMP_PLAN.md` (canonical on-market
   plan), the `overnight-search` and `submit-url` skills, the
   `prospect-evaluation` skill (`.claude/skills/prospect-evaluation/skill.md`,
   which embeds the buy-box rubric), `templates/daily-dashboard.html`. The
   off-market skill mirrors `overnight-
   search`'s structure and reuses every downstream stage.
4. **`_ralph/evidence/onmarket-system-summary.md`** — the on-market facts on disk.

## Objective

Build the **Off-Market Target Search** intake pipeline specified by the PRD: a
new `off-market-search` skill that mines U.S. government / open-data sources for
the two target classes, resolves and de-duplicates the records, enriches and
scores them with the **existing** `prospect-evaluation` skill, and writes them
into the **same** Airtable table as on-market leads — interchangeable rows, same
dashboard, same review cadence. Only the sourcing front-end is new.

## Deliverables (the loop is done when all exist and pass the final audit)

1. `~/published-listing-search/.claude/skills/off-market-search/skill.md` — the
   main weekly intake pipeline, structured to mirror `overnight-search`.
2. A **manual single-entity path** (mirrors `submit-url`) — pushes one known
   company or SBIC through the same pipeline on demand.
3. `~/published-listing-search/config/offmarket_sources.md` — source URLs,
   verified codes (NAICS 541930, PSC R608), API endpoints, keyword lists.
4. **Airtable schema changes** applied to base `appOsvuyy5eK43QTx` /
   table `tblSmNrHROMLm7vOS` — the §8.3 `Source` values and the §8.4 new fields
   (see "Decisions locked in").
5. **Dashboard off-market badge** in `templates/daily-dashboard.html`.
6. **Off-market outreach template** added under `config/outreach_templates.md`
   (or a sibling file) — a proprietary-approach template, distinct from the
   broker templates.
7. A **weekly `/schedule` cron** registered to run `off-market-search`.

## Decisions locked in (from the §13 resolution — do not re-litigate)

- **Cadence:** weekly, both target classes, via a `/schedule` cron.
- **New Airtable fields:** create all five §8.4 fields — `SBIC License #`,
  `SBIC License Status`, `Gov Data Source`, `Federal Award History $` — **plus a
  dedicated `Gov Entity ID`** field (do not reuse `Listing ID`).
- **`Source` single-select:** add `Off-Market — ASL Bolt-on` and
  `Off-Market — SBIC`. The skill must **fail loud** if these are missing.
- **Dashboard:** add an **"Off-Market" badge** to off-market rows — no `Source`
  column.
- **State sources:** **in Phase 1** (not deferred). Priority-state list is an
  open blocker — see B1.
- **Outreach:** a **dedicated off-market outreach template** is in scope; keep
  the broker templates for on-market.
- **Success metrics:** the §2.2 numbers are accepted as-is (≥80% precision,
  <5% duplicate rate, ≥95% entity-resolution accuracy).
- **Spoken-language-only translation firms:** surfaced as **"adjacent"** (Buy
  Box line-10 bonus 5, not 10) — not hard-excluded.
- **NAICS 541930** is confirmed correct (and explicitly includes sign language).
  **PSC R608** is confirmed correct — the PRD's "low confidence" flag is cleared.
- **FPDS-NG is decommissioned.** Do **not** build on fpds.gov or the FPDS ATOM
  feed. Use the **SAM.gov Contract Awards API** (`open.gsa.gov/api/contract-
  awards/`) as the FPDS successor, with **USAspending.gov as the primary award
  source**.
- **DSBS is now "Small Business Search" (SBS)** — `dsbs.sba.gov` redirects to it.
- **Form ADV** is reached via **IAPD / `adviserinfo.sec.gov`**, not SEC EDGAR.
- **RID is retained** as a supplementary Class-1 source. Use it for point-of-need
  enrichment / contact lookup, not bulk-copying the member directory.

## Open items carried as BLOCKERS

The loop proceeds on everything not blocked; a blocked stage is marked `blocked`
and retried once the precondition clears. See `_ralph_build/BLOCKERS.md`.

- **B1 — Priority-state list.** Operator must name the Phase-1 priority states
  (and the build must confirm each state portal's ToS). *Blocks the state-source
  adapter in s3.*
- **B2 — SBIC scope.** Operator must confirm which SBIC license/program types
  are in scope (current types: Standard Debenture, Accrual, Reinvestor, plus
  non-leveraged SBICs). **Default if unanswered: all licensed types.** *Blocks
  the SBIC scope filter in s3/s5.*
- **B3 — SAM.gov account + API key.** A SAM.gov account with a **role** assigned
  and a Public API Key is required; a no-role account is capped at 10 requests/
  day. *Blocks the SAM.gov adapters in s3 above the 10/day tier.*
- **B4 — Airtable schema-write permission.** Creating the §8.3 `Source` values
  and the §8.4/`Gov Entity ID` fields requires write access to the base (via the
  Airtable MCP or an operator action). *Blocks s2.*

## Stages

Each stage advances one phase per iteration (IMPLEMENT → SELF-TEST → VERIFY).
A stage is `verified` only when its **Done-when** criteria are met and a critic
subagent confirms them.

### s1 — Foundations & config
- **Goal:** stand up the skill scaffold and the verified-codes config.
- **Builds:** `.claude/skills/off-market-search/` directory + `skill.md` skeleton
  (the §9.1 nine-step outline); `config/offmarket_sources.md` populated from the
  resolution doc (NAICS 541930, PSC R608, source URLs, API endpoints, the §5.2
  Class-1 keyword list and exclusion terms, the §5.3 Class-2 keywords).
- **Done-when:** scaffold exists; config lists every source with its verified
  access method; no `⚠ VERIFY:` placeholders remain (all were resolved in §13).

### s2 — Airtable schema
- **Goal:** make the tracker able to hold off-market records.
- **Builds:** the two new `Source` single-select values; the five §8.4 fields +
  `Gov Entity ID`; a **fail-loud schema-preflight check** the skill runs before
  every write.
- **Done-when:** all fields/values exist in `appOsvuyy5eK43QTx` /
  `tblSmNrHROMLm7vOS` with the correct types; the preflight check passes against
  the live schema and fails loud (with a clear operator message) when a field is
  missing. *(Blocked by B4 until schema-write access is available.)*

### s3 — Source adapters
- **Goal:** one query module per source, behind a common interface so a source
  can be swapped without touching downstream stages (PRD R3).
- **Builds:** adapters for **USAspending.gov** (primary award source — key-free
  REST + bulk download), **SAM.gov Entity Management API** (`api.sam.gov`,
  x-api-key, public tier), **SAM.gov Contract Awards API** (FPDS successor),
  **SBA SBIC directory** (CSV export diff), **SBA Small Business Search (SBS)**,
  **GSA eLibrary** (MAS SIN 541930), **priority-state portals/SOS** (per B1),
  and **RID** (point-of-need lookup). Each adapter filters by NAICS/PSC + the
  keyword strategy and returns a normalized raw-record object.
- **Done-when:** each adapter returns normalized records from a live (or
  recorded-fixture) query; the source layer is abstracted; rate limits and ToS
  per source are respected and documented. *(SAM adapters partially blocked by
  B3; state adapter blocked by B1; SBIC filter blocked by B2.)*

### s4 — Entity resolution & de-duplication
- **Goal:** collapse multi-source records to one canonical entity and never
  re-surface an existing tracker row.
- **Builds:** the §6.1 resolver (UEI → CAGE → legacy DUNS → normalized
  name+address) and the §6.2 three-key dedup against the tracker (gov identifier
  / name+address / SBIC license number), plus cross-run dedup.
- **Done-when:** distinct gov records for one company resolve to one candidate;
  a candidate already in `tblSmNrHROMLm7vOS` is detected and updated, not
  duplicated; resolution accuracy is spot-checked toward the ≥95% target.

### s5 — Enrichment & qualification pre-filters
- **Goal:** turn a thin gov record into a scorable lead packet.
- **Builds:** website discovery + Playwright validation + screenshot (reusing
  `overnight-search` Step 3 logic); SOS formation-date lookup; financial-signal
  enrichment; the §7.4 cheap pre-filters (Class 1: keyword filter must indicate a
  sign-language/deaf-services line; Class 2: current licensee in good standing);
  the lead-packet builder. Missing fields are marked **"needs follow-up"**, never
  fabricated.
- **Done-when:** a candidate produces a complete lead packet; pre-filters drop
  obvious non-fits before scoring; the SBIC good-standing check cross-references
  beyond the directory (it does not publish a standing flag).

### s6 — Scoring integration
- **Goal:** score every qualified target with the **existing** scorer — no new
  scoring logic.
- **Builds:** invocation of `prospect-evaluation` in **roll-up add-on mode**
  (Class 1, /110 scale, no size floor) and **SBIC mode** (Class 2, license-good-
  standing gate, score informational); capture of the score and the `.md`+`.html`
  reports to `output/reports/{entity-id}/`.
- **Done-when:** a Class-1 and a Class-2 candidate each produce a score and a
  report via the unmodified `prospect-evaluation` skill; off-market "no asking
  price" is handled as "insufficient data — not awarded", not a failure.

### s7 — Airtable write & dashboard badge
- **Goal:** persist scored prospects and make them visible.
- **Builds:** record create/update mapped field-by-field per §8 (existing fields,
  the 16 reused fields, the new fields, the new `Source` values); the
  **off-market badge** in `templates/daily-dashboard.html`.
- **Done-when:** a scored off-market prospect appears as a normal row in
  `tblSmNrHROMLm7vOS` with `Disposition = Active`; the badge renders on
  off-market rows only; on-market rows are unchanged.

### s8 — Outreach drafting
- **Goal:** draft (never send) proprietary-approach outreach.
- **Builds:** the dedicated off-market outreach template (owner / SBIC GP
  principal, business not for sale); draft generation into `Notes` +
  `search_reports/`.
- **Done-when:** a draft is generated for a candidate with a direct contact;
  **nothing is auto-sent**; the broker templates are untouched.

### s9 — Orchestration & cadence
- **Goal:** assemble the end-to-end skill and schedule it.
- **Builds:** the full `off-market-search` skill (the §9.1 steps 1–9 wired
  together); the manual single-entity path mirroring `submit-url`; the weekly
  `/schedule` cron; run-log output to `search_reports/offmarket_run_log_YYYY-MM-
  DD.md`.
- **Done-when:** the skill runs the full pipeline; the manual path works for one
  supplied company/SBIC; the weekly cron is registered.

### s10 — Assembly, end-to-end self-test & final audit
- **Goal:** prove the whole thing works and is honest.
- **Builds:** an end-to-end dry run on a small live (or fixture) sample for both
  classes; a final independent-auditor pass.
- **Done-when:** the dry run produces at least one scored record per class into
  a test context with no fabricated fields; the final-audit subagent returns
  **SHIP** with **0 BLOCKING**; STATE shows all stages `verified`.

## Constraints (invariant — apply at every stage)

- **No parallel tracker.** Same base `appOsvuyy5eK43QTx`, same table
  `tblSmNrHROMLm7vOS`. Off-market and on-market rows are interchangeable.
- **No new scorer.** Qualification reuses the `prospect-evaluation` skill
  (`.claude/skills/prospect-evaluation/skill.md`, which embeds the buy-box
  rubric) verbatim.
- **Fail loud, never silent.** Missing `Source` options or fields → stop with a
  clear operator message; do not silently create or skip.
- **Never fabricate.** Unknown fields are "needs follow-up". No invented
  financials, contacts, codes, or URLs.
- **Never auto-send outreach.** Drafts only — consistent with the on-market
  skills.
- **API / bulk download over scraping.** Where a source offers an API or bulk
  download, use it; respect `robots.txt`, rate limits, and each source's ToS
  (§11). No scraping behind logins or paywalls.
- **RID** is used for point-of-need enrichment / contact lookup only — not
  bulk-copied into the tracker.
- **Source layer stays swappable** so a decommissioned/changed source (the FPDS
  lesson) can be replaced without rewriting downstream stages.
- **Government change-of-control fact** travels on every Class-2 record:
  acquiring a licensed SBIC requires SBA prior approval.

## Definition of done

All 10 stages `verified`; the s10 end-to-end dry run produces ≥1 scored record
per target class with no fabricated fields; the final-audit subagent returns
**SHIP / 0 BLOCKING**; `_ralph_build/STATE.md` has `final_audit_passed: true`,
`unresolved_findings: 0`, `open_blockers: 0`. The loop then emits
`<promise>OFFMARKET_BUILD_VERIFIED</promise>` and stops.

*Bootstrapped 2026-05-21. Canonical "what" for the off-market build loop.*
