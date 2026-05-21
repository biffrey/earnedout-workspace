# On-Market System Summary (s1 evidence)

How the existing **published-listing (on-market)** search sources, scores, stores,
and iterates on opportunities — read from the actual repo files, 2026-05-21.

## Sourced
- `overnight-search` skill (`.claude/skills/overnight-search/skill.md`): nightly
  pipeline. Authenticates to DealStream via 1Password CLI (`op read
  "op://Personal/dealstream.com/{username,password}"`), logs in with Playwright,
  searches DealStream + BizBuySell + BizQuest + other platforms by industry
  keyword + geography. Extracts a **direct listing URL + listing ID** for each
  hit — never a search-results page. Playwright validates every URL and captures
  a screenshot to `output/screenshots/{listing-id}.png`.
- `submit-url` skill: same pipeline for one manually-supplied URL; sets
  `Source = "Manual Submission"`.

## Scored
- Every new lead and every price-drop is run through the **`prospect-evaluation`
  skill** (`.claude/skills/prospect-evaluation/skill.md` +
  `references/buy-box-and-scoring.md`): Buy Box screening (6 hard checks) →
  26-field scorecard → 0–100 lead score (per-line rubric) → full deal memo in
  `.md` + `.html` at `output/reports/{listing-id}/`.
- The scorer **already supports both off-market target classes**:
  - **Roll-up add-on mode** — `references/buy-box-and-scoring.md` §"Roll-up
    add-on relaxed thresholds": "Applied Development add-ons (translation &
    interpretation — NAICS 541930: sign language interpreting, CART, VRI, deaf
    services, and spoken/foreign-language translation & interpreting): **no size
    floor.**" Roll-up add-ons score to **110** (line 10 bonus +10). Biffrey
    already holds the Applied Development platform, "valued at ~6.5x".
  - **SBIC mode** — same file §"SBIC (Small Business Investment Company)
    targets": the target is "the general partner / management entity that holds
    an SBA SBIC license". Gate = "the SBIC license is **active and in good
    standing** with the SBA". Financial checks are reported but non-gating.
    "Any change of control of a licensed SBIC requires SBA approval."

## Stored
- Airtable base **`appOsvuyy5eK43QTx`**, table **`tblSmNrHROMLm7vOS`**
  ("Master Deal Pipeline"). 16 new fields + retained existing fields; field IDs
  enumerated in `REVAMP_PLAN.md` Step 1 "Live field-name reconciliation".
- `Source` single-select (`fldiGyXTk6Ybb6J1L`) values today: `Overnight Search`,
  `Manual Submission`.
- `Disposition` single-select: Active / Contacted / Maybe Later / Revisit for
  Roll-up / Passed / Dead Link. New leads default to `Active`.
- Daily HTML dashboard `output/dashboards/dashboard_YYYY-MM-DD.html` from
  `templates/daily-dashboard.html` — Section A (new finds), B (running queue =
  Active), C (revisit bucket = Revisit for Roll-up), D (run summary). Run logs
  and outreach drafts go to `search_reports/`.

## Iterated on
- The build itself ran as a **Ralph loop**: `REVAMP_PLAN.md` (canonical "what")
  + `REVAMP_LOOP_PROMPT.md` (loop driver) + `_ralph/STATE.md` (10-stage state
  machine) + `run-ralph-cli.sh` (runner). One (stage, phase) per iteration:
  IMPLEMENT → SELF-TEST → VERIFY (critic subagent) → FINAL AUDIT → COMPLETE
  (emit `<promise>REVAMP_VERIFIED</promise>`). Completed at iteration 64, all 10
  stages `verified`.
- Operationally, the nightly cadence is the `overnight-search` run + daily
  dashboard; the human reviews the dashboard and sets `Disposition`.

## Implication for off-market
The off-market system is a **new intake front-end only**. It must write into the
SAME table, use the SAME 16+existing fields, call the SAME `prospect-evaluation`
skill, and surface in the SAME dashboard. No parallel tracker, no new scorer.
