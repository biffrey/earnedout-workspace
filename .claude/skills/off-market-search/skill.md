---
name: off-market-search
description: Runs the EarnedOut off-market target search pipeline. Mines U.S. government / open-data sources (USAspending.gov, SAM.gov, the SBA SBIC directory, GSA eLibrary, and others) for two target classes — ASL / CART / deaf-services companies acquirable as Applied Development roll-up add-ons, and licensed SBIC management firms acquirable outright — then resolves, de-duplicates, enriches, scores them with the prospect-evaluation skill, and writes them into the same Master Deal Pipeline Airtable table as on-market leads. Use when the user says "run the off-market search", "find off-market targets", "search government data for acquisition targets", or on the weekly schedule.
---

# Off-Market Search Skill

> **⚠ BUILD STATUS — SKELETON.** This file is the stage-s1 scaffold produced by
> the off-market build loop (`OFFMARKET_BUILD_LOOP_PROMPT.md`). The nine steps
> below are outlined but not yet fully wired. Each step is annotated with the
> build-loop stage that completes it. Do **not** run this skill against live
> systems until the build loop reaches `OFFMARKET_BUILD_VERIFIED`.

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
3. **Schema preflight (fail loud).** Confirm the Airtable `Source` field has the
   values `Off-Market — ASL Bolt-on` and `Off-Market — SBIC` and that the §8.4
   fields + `Gov Entity ID` exist with the correct types. If anything is
   missing, **stop immediately** with a clear operator message — never silently
   create or skip. _(Preflight logic: s2.)_

## Step 2 — Query government sources
*Built by s3 (source adapters).*

For each target class, query the sources in `config/offmarket_sources.md` via
the s3 adapters (USAspending primary; SAM.gov Entity + Contract Awards APIs; SBA
SBIC directory CSV; SBA SBS; GSA eLibrary; priority-state portals; RID
point-of-need; IAPD). Each adapter filters by NAICS `541930` / PSC `R608` + the
keyword strategy and returns normalized raw-record objects. Respect each
source's rate limits and ToS. _(Adapters + interface: s3.)_

## Step 3 — Resolve & de-duplicate
*Built by s4.*

Collapse multi-source records to one canonical entity (UEI → CAGE → legacy DUNS
→ normalized name+address; plus SBIC license # for Class 2). De-duplicate
against `tblSmNrHROMLm7vOS` on the three keys (gov identifier / name+address /
SBIC license #) — **never re-surface a target already in the tracker** as new.
Cross-run dedup within the off-market run itself. _(Resolver + dedup: s4.)_

## Step 4 — Enrich
*Built by s5.*

Turn each thin gov record into a scorable lead packet: website discovery +
Playwright validation + screenshot (reuse `overnight-search` Step 3 logic); SOS
formation-date lookup; financial-signal enrichment; the §7.4 pre-filters
(Class 1 — keyword filter must indicate a sign-language/deaf-services line;
Class 2 — current licensee, good-standing cross-check). **Missing fields are
marked "needs follow-up" — never fabricated.** _(Enrichment + pre-filters: s5.)_

## Step 5 — Qualify & score
*Built by s6.*

Invoke the **existing** `prospect-evaluation` skill — no new scoring:
- **Class 1:** roll-up add-on mode (Applied Development, no size floor, /110
  scale). Off-market "no asking price" → "insufficient data — not awarded", not
  a failure.
- **Class 2:** SBIC mode (license-good-standing gate; financials + 0–100 score
  informational).
Capture the score and the `.md` + `.html` reports to
`output/reports/{entity-id}/`. _(Scoring integration: s6.)_

## Step 6 — Create / update the Airtable record
*Built by s7.*

Write each scored prospect into `tblSmNrHROMLm7vOS`, mapped field-by-field per
PRD §8 — existing fields, the 16 reused fields, the new §8.4 fields +
`Gov Entity ID`, and `Source = "Off-Market — ASL Bolt-on"` or
`"Off-Market — SBIC"`. `Disposition = Active`. Off-market and on-market rows are
interchangeable. _(Record mapping + write: s7.)_

## Step 7 — Draft outreach
*Built by s8.*

Where a direct contact exists (business owner / SBIC GP principal), draft
**proprietary-approach** outreach using the dedicated off-market template — the
business is not for sale, so the broker templates do not apply. Store drafts in
`Notes` + `search_reports/`. **Never send email.** _(Off-market template +
drafting: s8.)_

## Step 8 — Generate the daily dashboard
*Built by s7 (badge) + s9 (wiring).*

Regenerate `output/dashboards/dashboard_YYYY-MM-DD.html` from
`templates/daily-dashboard.html`. Off-market leads appear alongside on-market
leads with an **"Off-Market" badge** on their rows. _(Badge: s7; wiring: s9.)_

## Step 9 — Write run logs
*Built by s9.*

Write a run summary to `search_reports/offmarket_run_log_YYYY-MM-DD.md` (counts
per source, per class, new vs. updated, blocked sources). Report completion.
_(Run-log output: s9.)_

---

## Manual single-entity path
*Built by s9 — mirrors the `submit-url` skill.*

A manual path pushes one operator-supplied company or SBIC through Steps 3–9 on
demand (resolve → enrich → score → record → outreach → dashboard). Use when a
specific target is identified outside the scheduled run.

## Cadence
*Registered by s9.*

Weekly, both target classes, via a `/schedule` cron (per §13 Q1).

## Constraints (invariant)

- No parallel tracker; no new scorer — reuse `tblSmNrHROMLm7vOS` and
  `prospect-evaluation`.
- Fail loud on a missing `Source` value or field — never silently create/skip.
- Never fabricate data — unknown fields are "needs follow-up".
- Never auto-send outreach — drafts only.
- API / bulk download over scraping; respect rate limits and ToS.
- Every Class-2 record carries the fact: acquiring a licensed SBIC requires SBA
  prior approval of the change of control.
