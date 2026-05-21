# Off-Market PRD Loop — Implementation Log

## 2026-05-21 — iter 1 — DRAFT s1_foundations
Read in full: REVAMP_PLAN.md, REVAMP_LOOP_PROMPT.md, overnight-search/skill.md,
submit-url/skill.md, prospect-evaluation references (buy-box-and-scoring.md),
config/ listing, Airtable schema (from REVAMP_PLAN Step 1). Wrote
`_ralph/evidence/onmarket-system-summary.md`. Confirmed: platform company =
Applied Development (NAICS 541930, ~6.5x); SBIC criteria = license-good-standing
gate. Created `PRD_OFF_MARKET_SEARCH.md` with header, TOC, §1 Executive Summary,
§2 Objective/Metrics/Scope/Non-Goals incl. §2.5 integration subsection.

## 2026-05-21 — iter 2 — DRAFT s2..s9
Drafted the remaining PRD sections in one pass (loop driven directly, single
session): §3 two target classes; §4 per-source methodology (FPDS-NG, SAM.gov,
USAspending, SBA SBIC directory, DSBS, GSA eLibrary + 6 additional .gov sources);
§5 NAICS/PSC + keyword strategy (all codes flagged ⚠ VERIFY); §6 entity
resolution & dedup; §7 qualification via the existing prospect-evaluation skill
(roll-up add-on mode / SBIC mode); §8 field-by-field schema mapped to table
tblSmNrHROMLm7vOS with real field IDs; §9 workflow & cadence mirroring the Ralph
loop; §10 integration plan; §11 compliance & legal; §12 risks; §13 open
questions + consolidated verification checklist. All 10 required-contents items
present.
