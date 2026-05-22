---
name: off-market-search
description: Runs the EarnedOut off-market target search pipeline. Mines U.S. government / open-data sources (USAspending.gov, SAM.gov, the SBA SBIC directory, GSA eLibrary, and others) for two target classes — ASL / CART / deaf-services companies acquirable as Applied Development roll-up add-ons, and licensed SBIC management firms acquirable outright — then resolves, de-duplicates, enriches, scores them with the prospect-evaluation skill, and writes them into the same Master Deal Pipeline Airtable table as on-market leads. Use when the user says "run the off-market search", "find off-market targets", "search government data for acquisition targets", or on the weekly schedule.
---

# Off-Market Search Skill

> **⚠ BUILD STATUS — WIRED, PENDING FINAL VERIFICATION.** The nine steps below
> are fully wired end-to-end by the off-market build loop
> (`OFFMARKET_BUILD_LOOP_PROMPT.md`): each step points at its stage reference
> and the run order, hand-off, and failure handling are specified in
> `references/orchestration.md`. Blocker B4 is **resolved** — the two off-market
> `Source` values are live, so the Step 1 schema preflight passes. The skill is
> still **not yet cleared for an unattended live run** — the build loop has not
> reached `OFFMARKET_BUILD_VERIFIED`. Until it does, run in **dry-run / fixture
> mode** (`references/orchestration.md` §5).

You are running the EarnedOut **off-market** target search pipeline. Unlike the
`overnight-search` skill (which searches broker listing sites for businesses
*listed for sale*), this skill mines U.S. government / open data to surface
companies that are **not for sale** but may be acquirable. It is an **intake
front-end only** — every downstream stage (scoring, tracking, dashboard,
outreach) reuses the existing on-market machinery. There is **no parallel
tracker and no new scorer**.

Canonical references — read the relevant parts at runtime:
- `config/offmarket_sources.md` — sources, verified codes, keywords, endpoints
- `Off-Market Search/PRD_OFF_MARKET_SEARCH.md` — requirements
- `Off-Market Search/PRD_OFF_MARKET_SEARCH_Section13_Resolution.md` — operator
  decisions + verified facts (**overrides the PRD on conflict**)
- `.claude/skills/prospect-evaluation/skill.md` — the scorer (invoked unchanged)

**Airtable target:** base `appOsvuyy5eK43QTx`, table `tblSmNrHROMLm7vOS`
("Master Deal Pipeline") — the same table as on-market leads.

**Two target classes** (see `config/offmarket_sources.md`): Class 1 — ASL /
CART / deaf-services operating companies (Applied Development roll-up add-ons);
Class 2 — licensed SBIC management firms acquired for the license itself.

---

## Step 1 — Read config & preflight
*Built by s1 (this scaffold) + s2 (schema preflight).*

1. Read `config/offmarket_sources.md`, `config/search_config.md`,
   `config/outreach_templates.md`, and the off-market outreach template.
2. Read `.claude/skills/prospect-evaluation/skill.md`.
3. **Schema preflight (fail loud).** Run the procedure in
   `references/airtable_schema_preflight.md`: confirm the Airtable `Source` field
   has the values `Off-Market — ASL Bolt-on` and `Off-Market — SBIC` and that the
   five §8.4 fields (`Gov Entity ID`, `SBIC License #`, `SBIC License Status`,
   `Gov Data Source`, `Federal Award History $`) exist with the correct types.
   If anything is missing, **stop immediately** with the operator message in that
   reference — never silently create or skip. _(Preflight logic: s2.)_

## Step 2 — Query government sources
*Built by s3 (source adapters).*

For each target class, query the sources in `config/offmarket_sources.md` via
the s3 adapters. The adapters and their **common interface** are specified in
`references/source_adapters.md` — every adapter is invoked
`adapter.query(target_class, params)` and returns normalized `RawRecord`
objects plus an `AdapterMeta` status, so a source can be swapped without
touching downstream stages. Discovery adapters (USAspending primary; SAM.gov
Entity + Contract Awards APIs; SBA SBIC directory CSV; SBA SBS; GSA eLibrary;
priority-state portals) emit new records; enrichment adapters (SBIC
good-standing, RID point-of-need, IAPD, U.S. Courts) amend them. Each adapter
applies its own NAICS `541930` / PSC `R608` / keyword filter and respects its
source's rate limits and ToS. A `blocked`/`error` adapter (B1, B3) degrades the
run gracefully — its `meta` is logged, the run continues. _(Adapters +
interface: s3 — see `references/source_adapters.md`.)_

## Step 3 — Resolve & de-duplicate
*Built by s4.*

Run the procedure in `references/entity_resolution.md`. It (a) collapses the s3
multi-source `RawRecord`s to one canonical entity via the §6.1 key ladder
(UEI → CAGE → legacy DUNS → normalized name+address; plus SBIC license # for
Class 2), and (b) de-duplicates each canonical entity against
`tblSmNrHROMLm7vOS` on the three §6.2 keys (gov identifier / name+address / SBIC
license #) — **never re-surface a target already in the tracker** as a new lead.
The tracker itself is the cross-run memory, so a target from a prior off-market
run resolves to `existing`. Each entity emerges tagged `new` (→ s5 enrichment)
or `existing` (→ s7 update, never a duplicate row); a stable `Gov Entity ID` is
assigned. If the tracker read fails, the run halts the write step rather than
writing blind. _(Resolver + dedup: s4 — see `references/entity_resolution.md`.)_

## Step 4 — Enrich
*Built by s5.*

Run the procedure in `references/enrichment.md` over each `new` canonical
entity from Step 3. It first applies the cheap **§7.4 pre-filters** (Class 1 —
the keyword hits must indicate a sign-language/deaf-services line and the
entity must be a U.S. operating company; Class 2 — a current SBIC licensee not
already disproven on standing) and **drops obvious non-fits before any
expensive enrichment**. Each pre-filter-passing candidate is then enriched —
website discovery + Playwright validation + screenshot (reusing
`overnight-search` Step 3 logic); SOS formation-date lookup (Phase-1 scope
gated by B1); financial-signal enrichment; ownership/contact discovery; and,
for Class 2, the SBIC **good-standing cross-check** (the directory publishes no
standing flag — standing is cross-referenced against enforcement/court/IAPD
signals). The output is one `LeadPacket` per passing candidate. **Missing
fields are marked "needs follow-up" — never fabricated**; every gap is listed
in `enrichment_gaps`. _(Enrichment + pre-filters: s5 — see
`references/enrichment.md`.)_

## Step 5 — Qualify & score
*Built by s6.*

Run the procedure in `references/scoring_integration.md` over each `LeadPacket`
from Step 4. It invokes the **existing, unmodified** `prospect-evaluation` skill
— no new scoring logic, no new rubric:
- **Class 1:** `rollup_addon` mode (Applied Development platform, no size floor,
  /110 scale; an `adjacent` keyword tier awards the line-10 bonus at 5 not 10).
  Off-market "no asking price" → the valuation line scores "insufficient data —
  not awarded", **not a failure and not an abort**.
- **Class 2:** `sbic` mode — the SBIC license-good-standing gate (fed from
  `sbic_license_status`) is the sole hard criterion; financials and the 0–100
  score are informational. Every Class-2 report carries the SBA
  prior-approval-of-change-of-control fact.
Each candidate emerges as a `ScoredLead`; the score and the `.md` + `.html`
reports are captured to `output/reports/{report_slug}/` (a filesystem-safe form
of the `Gov Entity ID`). _(Scoring integration: s6 — see
`references/scoring_integration.md`.)_

## Step 6 — Create / update the Airtable record
*Built by s7.*

Run the procedure in `references/airtable_write.md`. It writes each `ScoredLead`
from Step 5 into `tblSmNrHROMLm7vOS`, mapped field-by-field per PRD §8 —
existing fields, the 16 reused fields, the five new §8.4 fields + `Gov Entity ID`,
and `Source = "Off-Market — ASL Bolt-on"` or `"Off-Market — SBIC"`;
`Disposition = "Active"`. An s4 `existing`-tagged entity **updates its matched
row in place** (never a duplicate, never a `Source`/`Disposition` flip on an
on-market row). Unknown fields are left blank — never fabricated; the gov record
URL goes in `Direct Listing URL`/`Links`, never a search-results page.
Off-market and on-market rows are interchangeable. _(Record mapping + write: s7 —
see `references/airtable_write.md`.)_

## Step 7 — Draft outreach
*Built by s8.*

Run the procedure in `references/outreach_drafting.md` over each off-market
lead s7 wrote this run. Where a direct contact exists (business owner / SBIC GP
principal), draft **proprietary-approach** outreach using the dedicated
off-market templates in `config/offmarket_outreach_template.md` — Template OM-1
for Class 1, Template OM-2 for Class 2. The business is **not for sale**, so the
broker templates in `config/outreach_templates.md` do not apply and are not
read or modified here. Placeholders are filled from real enrichment data only —
an unknown owner name → neutral greeting, an unverified detail → the detail
paragraph is omitted, never fabricated. A lead with **no direct contact** gets
**no draft** (logged as a contact-discovery follow-up). Each draft is stored in
two places: appended to the lead's Airtable `Notes` field, and appended to
`search_reports/offmarket_outreach_drafts_YYYY-MM-DD.md`. **Never send email —
drafts only.** _(Off-market templates + drafting: s8 — see
`references/outreach_drafting.md`.)_

## Step 8 — Generate the daily dashboard
*Built by s7 (badge) + s9 (wiring).*

Regenerate `output/dashboards/dashboard_YYYY-MM-DD.html` from
`templates/daily-dashboard.html`. Off-market leads appear alongside on-market
leads with an **"Off-Market" badge** (`.chip.offmarket`, rendered when
`lead.source` starts with `"Off-Market"`) on their rows in Sections A, B, and C
— no `Source` column is added and on-market rows are unchanged. See
`references/airtable_write.md` §5. _(Badge: s7; wiring: s9.)_

## Step 9 — Write the run log
*Built by s9.*

Write a run summary to `search_reports/offmarket_run_log_YYYY-MM-DD.md` using the
template in `references/orchestration.md` §3 — sources queried (with per-source
status and record counts), resolution & dedup counts (new / existing / needs
operator review), enrichment & scoring outcomes per class, Airtable creates vs.
updates, outreach drafts vs. no-contact follow-ups, the dashboard path, and the
operator follow-up list. Counts are **real**, taken from each step's actual
output — never estimated. Step 9 runs even on a halted run, recording what
happened and why. Report completion to the operator. _(Run-log format:
`references/orchestration.md` §3.)_

---

## Orchestration

The end-to-end run order, the typed hand-off between steps, and the
**failure-containment rule** (what halts the run vs. what degrades a single
source/candidate) are specified in **`references/orchestration.md`**. In short:
Step 1 preflight and a failed Step 3 tracker read are **hard halts**; a blocked
adapter, a per-candidate enrichment/scoring failure, or a per-record write
failure **degrade gracefully** — logged, run continues. A degraded run still
completes and writes an honest run log.

## Manual single-entity path
*Built by s9 — mirrors the `submit-url` skill.*

A manual path pushes **one** operator-supplied company or SBIC through the
pipeline on demand — for a target identified outside the scheduled run. The
operator supplies a name (+ state), a gov identifier (UEI / CAGE / SBIC license
#), or a website URL, plus the target class. The path runs the same Step 1
preflight, **seeds resolution directly** for that single entity (skipping the
Step 2 bulk discovery), then runs Steps 3–9 unchanged — an already-tracked
entity updates in place. It reports the lead score, the Airtable record URL, the
dedup verdict, and any "needs follow-up" gaps. Full procedure:
`references/orchestration.md` §4. Same constraints — never auto-send outreach,
never fabricate a field.

## Cadence
*Registered by s9.*

Weekly, both target classes, via a `/schedule` cron (per §13 Q1) — **Mondays at
06:00 local**. The cadence definition, the trigger prompt, the registration
command, the local `launchd` fallback, and the prerequisites are in
**`config/offmarket_schedule.md`**; the headless entrypoint is
`run-offmarket-search.sh` at the repo root. The off-market run needs **no `op` /
1Password** credential (no login-walled source); it does need the Airtable and
Playwright MCP servers. The weekly cron is **registered and live** — the local
`launchd` agent `ai.earnedout.offmarket-search` (Monday 06:00 local), installed
once blocker B4 was resolved (build loop iter 46). See
`config/offmarket_schedule.md` "Registration".

## Constraints (invariant)

- No parallel tracker; no new scorer — reuse `tblSmNrHROMLm7vOS` and
  `prospect-evaluation`.
- Fail loud on a missing `Source` value or field — never silently create/skip.
- Never fabricate data — unknown fields are "needs follow-up".
- Never auto-send outreach — drafts only.
- API / bulk download over scraping; respect rate limits and ToS.
- Every Class-2 record carries the fact: acquiring a licensed SBIC requires SBA
  prior approval of the change of control.
