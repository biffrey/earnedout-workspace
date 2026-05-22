# Orchestration & Cadence — `off-market-search` (stage s9)

The s9 reference. It wires the stage references (s2–s8) into one end-to-end run,
defines the **manual single-entity path**, the **run-log** format, and the
**weekly cadence**. The skill's `skill.md` Steps 1–9, the manual path, and the
Cadence section all point here.

> **Scope.** s9 adds **no new pipeline logic** — every stage's behaviour lives
> in its own reference (`airtable_schema_preflight.md`, `source_adapters.md`,
> `entity_resolution.md`, `enrichment.md`, `scoring_integration.md`,
> `airtable_write.md`, `outreach_drafting.md`). s9 is the *glue*: run order,
> data hand-off between stages, failure containment, the manual path, the
> run log, and the schedule.

---

## 1. Stage hand-off contract

The weekly run is a linear pipeline. Each step consumes the previous step's
typed output; s9 owns the hand-off, not the per-step logic.

| Step | Reference | Consumes | Produces |
|------|-----------|----------|----------|
| 1 Preflight | `airtable_schema_preflight.md` | live Airtable schema | pass / **fail-loud halt** |
| 2 Query | `source_adapters.md` | target class + params | `RawRecord[]` + `AdapterMeta[]` |
| 3 Resolve/dedup | `entity_resolution.md` | `RawRecord[]` | `CanonicalEntity[]` tagged `new` / `existing` / `needs_operator_review` |
| 4 Enrich | `enrichment.md` | `new` entities | `LeadPacket[]` (`prefilter_verdict: pass`) |
| 5 Score | `scoring_integration.md` | `LeadPacket[]` | `ScoredLead[]` |
| 6 Airtable write | `airtable_write.md` | `ScoredLead[]` (`new`) + `existing` entities | one row per lead in `tblSmNrHROMLm7vOS` |
| 7 Outreach | `outreach_drafting.md` | rows written this run | drafts in `Notes` + daily drafts file |
| 8 Dashboard | `airtable_write.md` §5 | the tracker | `output/dashboards/dashboard_YYYY-MM-DD.html` |
| 9 Run log | this file §3 | counts from every step | `search_reports/offmarket_run_log_YYYY-MM-DD.md` |

**Run order is fixed 1→9.** Step 1 is a hard gate: a preflight failure halts the
run before any source is queried (never write blind). Steps 2–8 degrade
gracefully per §2. Step 9 always runs — even on an aborted run it records what
happened and why.

## 2. Failure containment (what halts vs. what degrades)

The run distinguishes a **hard halt** from a **per-item / per-source
degradation**. This is the core orchestration rule.

**Hard halt — stop the run, write the run log, exit non-zero:**
- Step 1 schema preflight fails (a missing `Source` value or §8.4 field) — emit
  the operator message from `airtable_schema_preflight.md`.
- The Step 3 tracker read fails — cannot dedup, so cannot write without risking
  duplicates; halt the write step (per `entity_resolution.md`).
- An unrecoverable environment fault (no Airtable MCP, no Playwright).

**Degrade — log it, continue the run:**
- A `blocked` adapter (B1 state portals, B3 SAM.gov above the free tier) — its
  `AdapterMeta.status` is recorded; other adapters still run. A fixture is used
  where one is recorded (`source_adapters.md` fixture mode).
- A single adapter `error` — that source contributes nothing; the run continues.
- A per-candidate enrichment failure (Playwright timeout, no website) — that
  candidate carries the gap into its `LeadPacket`; the run continues.
- A per-candidate scorer failure — `lead_score: null`, candidate still written.
- A per-record Airtable write failure — retry once, then log for manual entry.
- A candidate with no direct contact — no outreach draft, logged as a
  contact-discovery follow-up (not a failure).

A degraded run is still a **successful run** — it just surfaces fewer or
gap-flagged leads, every gap explicit in the run log. Honesty over completeness.

## 3. Run log — `search_reports/offmarket_run_log_YYYY-MM-DD.md`

Step 9 writes one run log per run, mirroring `search_reports/run_log_*.md` from
the on-market pipeline. It is the audit trail: what was queried, what was found,
what was skipped and why. Template:

```markdown
# Off-Market Search — Run Log YYYY-MM-DD

- **Run type:** weekly scheduled run | manual single-entity
- **Started / finished (UTC):** … / …
- **Outcome:** completed | completed-degraded | halted-preflight | halted-error
- **Open blockers affecting this run:** B1 (state portals), B3 (SAM.gov tier) …

## Sources queried
| Source | Class | Status | Records | Note |
|--------|-------|--------|---------|------|
| S1 USAspending.gov | 1+2 | ok | 42 | live |
| S3 SAM.gov Contract Awards | 1 | blocked (B3) | 0 | fixture used / skipped |
| … | | | | |

## Resolution & dedup
- Raw records in: N  →  canonical entities: M
- New: X   Existing (updated in place): Y   Needs operator review: Z

## Enrichment & scoring
- Pre-filter: passed P, dropped D (reasons summarised)
- Scored: Class 1 (rollup_addon /110): … ; Class 2 (sbic, informational): …
- Scorer failures: …

## Airtable writes
- Created: … rows   Updated: … rows   Write failures (manual entry needed): …
- Record URLs: …

## Outreach drafts
- Drafts generated: … (Class 1 OM-1 / Class 2 OM-2)
- No-contact (no draft, follow-up logged): …
- File: search_reports/offmarket_outreach_drafts_YYYY-MM-DD.md   — NOT SENT

## Dashboard
- output/dashboards/dashboard_YYYY-MM-DD.html — off-market badge on N rows

## Follow-ups for the operator
- … (needs-operator-review entities, blocked sources, write failures)
```

Counts must be **real** — taken from each step's actual output, never estimated
or rounded to look complete. A `0` is reported as `0`.

## 4. Manual single-entity path

Mirrors the `submit-url` skill: pushes **one** operator-named company or SBIC
through the same pipeline on demand, for a target identified outside the
weekly run (a conference lead, a referral, a name from a deal conversation).

**Input.** One of: a company/SBIC **name** (+ state if known); a **gov
identifier** (UEI, CAGE, or SBIC license #); or a **website URL**. The operator
also states the **target class** (1 ASL/CART bolt-on, or 2 SBIC) — if omitted,
infer it and confirm in the output, never silently guess.

**Procedure.**
1. **Preflight** — same Step 1 schema preflight; fail loud identically.
2. **Skip bulk discovery (Step 2).** Instead, seed resolution directly:
   - identifier given → query the matching adapter for that one entity
     (USAspending / SAM.gov Entity by UEI; SBIC directory by license #);
   - name/URL given → look the entity up via SAM.gov Entity / SBS / a website
     check to obtain its identifiers.
   Produce the same `RawRecord[]` for that single entity.
3. **Steps 3–9 run unchanged** — resolve & dedup (an already-tracked entity
   updates in place, exactly as in the weekly run), enrich, score, write,
   draft outreach, refresh the dashboard.
4. **Run log** — write `offmarket_run_log_YYYY-MM-DD.md` with
   `Run type: manual single-entity` and the supplied identifier; if a run log
   for today already exists (a weekly run ran), **append a dated manual-run
   section** rather than overwriting it.
5. **Report to the operator** — the lead score (or "insufficient data — not
   awarded"), the Airtable record URL, the dedup verdict (new vs. updated),
   and any enrichment gaps marked "needs follow-up".

The manual path **never** auto-sends outreach and **never** fabricates a field
to fill the single record — identical constraints to the weekly run.

## 5. Dry-run / fixture mode

For SELF-TEST (s9, s10) — and for any run that must avoid spending a
quota-limited source's live request budget (e.g. the SAM.gov public ~10/day
tier) or that would query a state portal whose per-jurisdiction ToS is not yet
confirmed — the skill supports a **dry run**: adapters read recorded payloads
from
`_ralph_build/evidence/s3-fixtures/` (`source_adapters.md` fixture mode), and
the Airtable write is directed at a test context — **not** `tblSmNrHROMLm7vOS` —
or stubbed, with every intended field value logged. A dry run is labelled
`Run type: dry-run` in the run log and **must not** create live tracker rows.
The live weekly run uses real adapters and writes the live table.

## 6. Cadence — weekly `/schedule` cron

Per §13 Q1 and the build plan's locked-in decisions: **weekly, both target
classes, via a `/schedule` cron.** The cadence definition, the trigger prompt,
the registration command, and the prerequisites live in
`config/offmarket_schedule.md`; the headless entrypoint is
`run-offmarket-search.sh` at the repo root. s9 produces those artifacts; the
**live registration is done** — once blocker B4 cleared (build loop iter 46),
the cron was installed as the local `launchd` agent
`ai.earnedout.offmarket-search` (Monday 06:00 local). See that file's
"Registration" section.

The off-market run is **independent of the nightly on-market run** — different
skill, different schedule label, different log files. It does **not** need the
`op` 1Password CLI (no DealStream login); it does need the Airtable and
Playwright MCP servers.

## 7. Constraints (invariant — re-stated for the orchestration layer)

- **No parallel tracker / no new scorer** — every step writes only
  `tblSmNrHROMLm7vOS` and scores only via `prospect-evaluation`.
- **Fail loud, never silent** — Step 1 preflight halts the run; a tracker-read
  failure halts the write step.
- **Never fabricate** — degraded steps produce gap-flagged records, never
  invented values; the run log reports real counts.
- **Never auto-send outreach** — Step 7 drafts only.
- **A degraded run still completes and logs** — partial results are surfaced
  honestly with every gap and blocker named.
