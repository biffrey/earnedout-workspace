---
name: Valuation Estimate
description: Produces an estimated EBITDA multiple score and estimated valuation for an acquisition prospect, replicating Biffrey Braxton / EarnedOut's "Value Estimate" scorecard (VAM — baseline multiple from EBITDA size, value adders, value subtractors, LTV/CAC/LTGP unit economics). Use when the user asks to "estimate the valuation", "run the value estimate", compute a "multiple score" or "value estimate", asks "what's it worth", "what multiple does it deserve", or says "run the value estimate on <prospect>". Works standalone on any prospect working folder containing a prospect-evaluation report and supporting documents (P&Ls, CIMs, tax returns, backlog data), and as a chained follow-on after the prospect-evaluation skill scores a single prospect. Outputs a single HTML report into the prospect's working folder.
---

# Valuation Estimate Skill

> **Skill copies & sync policy.** Same policy as prospect-evaluation: the PRIMARY copy is `/Users/biffreybraxton/.claude/skills/valuation-estimate/` — make all edits there. Mirrors (never edit directly; refresh via `rsync -a --delete` from the PRIMARY): the git repo at `…/My Drive/Investments/Prospect Evaluation/Prospect-Evaluation-Skill/.claude/skills/valuation-estimate/` (commits to GitHub only from PRIMARY-synced content) and the project mirror at `/Users/biffreybraxton/published-listing-search/.claude/skills/valuation-estimate/`. Clones of the git repo at `/Users/biffreybraxton/Prospect-Evaluation-Skill/` and `/Users/biffreybraxton/Code/Prospect-Evaluation-Skill/` are pull-only. The project mirror is additionally tracked in the `earnedout-workspace` GitHub repo — commits there must also contain only PRIMARY-synced content.

Given a prospect's working folder — containing a prospect-evaluation report (Markdown/HTML deal memo) and any supporting documentation (P&Ls, CIMs, broker teasers, tax returns, contract/backlog data) — produce an **estimated EBITDA multiple score** and an **estimated valuation**, rendered as ONE HTML report that mirrors the information content of the "Value Estimate" tab of Biffrey's scorecard workbook.

The scoring model is canonical and must be replicated exactly. It lives in `references/scoring-model.md` — load it at the start of every run. Do not improvise rubric thresholds, point values, or definitions.

## Core output

- **One HTML file, no Markdown twin**, saved into the prospect's working folder.
- File naming: follow the same slug convention as the existing prospect-evaluation reports in that folder. If the folder contains `<company-slug>-report.html`, write `<company-slug>-value-estimate.html`. If no report exists yet, derive the slug from the company name the same way prospect-evaluation does.
- Instantiate `templates/value-estimate.html`. The report must contain everything the workbook tab contains — see "Report contents" below.

## Workflow

### Step 1 — Locate and read the prospect folder
- Accept a prospect working folder path from the user, or infer it when chained from the prospect-evaluation skill (use the folder that skill just wrote its report into).
- Read the prospect-evaluation report **first** (it concentrates the researched facts), then read **all** supporting documents in the folder: P&Ls, CIMs, broker teasers, tax returns, contract/backlog data, emails, spreadsheets.

### Step 2 — Build the full input list
Build the complete set of inputs the scorecard needs (every item is defined precisely in `references/scoring-model.md`):

- **Financial basis**: Revenue and EBITDA on the chosen basis (see basis rules in the reference).
- **Baseline**: EBITDA dollars → baseline multiple via the lookup table.
- **Adders**: Revenue Growth %, Yearly Revenue Retention %, EBITDA Margin, LTV:CAC Ratio, TS Clearance.
- **Subtractors (five Y/N calls)**: Key Man Risk, Key Client Risk, Single Channel Risk, Market Risk, Data Risk.
- **Unit-economics block**: Customers Acquired Last Period, LTV, CAC, LTGP.

For **each** input record three things: the value, the source document (with location if useful), and whether it was **found** (documented) or **estimated**.

You make all five subtractor Y/N calls yourself from the documentation and show your reasoning for each in the report. The user overrides after the fact if they disagree — never block waiting for risk judgments.

### Step 3 — Handle missing inputs
- Identify every input the documentation does not directly supply.
- For each, propose an estimated answer **grounded in the available documentation**, with a one-line rationale.
- No fabricated precision. If nothing in the documents supports an estimate, say so and use a conservative default, flagged as **low-confidence**.

### Step 4 — Ask which mode to use
At the start of each run (after Step 1 establishes context, before producing the report), ask the user which mode to use:

- **Confirm mode** — present every missing item with its proposed estimate and rationale; wait for the user to accept or override each; then build the report with the confirmed values.
- **Proceed mode** — generate the report immediately with best estimates.

Use AskUserQuestion with these two options. This is the one intentional pause in the workflow.

### Step 5 — Score and value
Apply the model from `references/scoring-model.md` exactly:

1. Baseline multiple from EBITDA dollars (lookup table).
2. Total adders = sum of the five adder lines.
3. Total subtractors = sum of the five risk lines.
4. **Multiple Score = baseline multiple + total adders − total subtractors.**
5. **Estimated Valuation = EBITDA (chosen basis) × Multiple Score.**

Show the equations in the report in plain words, just as the sheet does — "Multiple Score = Baseline Multiple + Total Value Adders − Total Value Subtractors" and "Estimated Valuation = EBITDA × Multiple Score" — never as spreadsheet cell references.

### Step 6 — Render the HTML report
Instantiate `templates/value-estimate.html` and write it to the prospect's working folder.

**Report contents (all required — mirrors the workbook tab):**
- **Header**: company name, evaluation date, the financial basis used (T24M avg / last FY / annualized YTD), Multiple Score badge, Estimated Valuation badge.
- **Financial basis**: which basis was chosen, the period it covers, and the math (e.g., "YTD Mar 2025 × 4").
- **Baseline**: Revenue, EBITDA, baseline multiple — with the full baseline lookup table shown (EBITDA $ ranges → multiple).
- **Value Adders**: each of the five lines with its input value, the full rubric for that line, points awarded, and source/estimate status.
- **Value Subtractors**: each of the five lines with the Y/N call, the rubric (points if risk / 0 if not), and a written reasoning paragraph for each call.
- **Unit economics (the J–L block)**: Customers Acquired Last Period, LTV, CAC, LTGP, and the LTV:CAC ratio, each with its definition formula spelled out.
- **Valuation**: Multiple Score with its plain-words equation and the substituted numbers; Estimated Valuation with its plain-words equation and the substituted numbers.
- **Inputs & sources appendix**: every input with value, source document, found-vs-estimated status, and rationale for estimates.

**Highlighting rule**: every estimated (vs. documented) value must be visually highlighted — distinct background color plus an "ESTIMATED" badge — with its rationale shown. Documented values carry a source citation instead. Low-confidence defaults get an additional "LOW CONFIDENCE" marker.

### Step 7 — Self-check before finishing
- [ ] Every rubric threshold and point value matches `references/scoring-model.md` exactly.
- [ ] Multiple Score arithmetic checks out: baseline + adders − subtractors, shown line by line.
- [ ] Estimated Valuation = EBITDA × Multiple Score, with the same EBITDA figure used in the Baseline section.
- [ ] All five subtractor calls have written reasoning.
- [ ] Every estimated value is highlighted with a rationale; every documented value has a citation.
- [ ] The financial basis and evaluation date are stated.
- [ ] Exactly one HTML file was written, into the prospect's folder, with the right slug.

## Behavioral rules

1. **The scoring model is frozen.** Never adjust thresholds, points, or definitions to fit a prospect — flag tension in prose instead.
2. **TS Clearance stays literal.** +1 only for Top Secret-cleared contracts, facility clearance, or cleared staff. Most non-govcon prospects score 0. Do not generalize it into "certifications" or "moats".
3. **LTGP never affects the score.** It is display-only, as is LTV and CAC individually — only the LTV:CAC *ratio* feeds an adder.
4. **No fabricated precision.** Estimates must trace to something in the documents; otherwise use a conservative default flagged low-confidence.
5. **State the basis.** The report always names which financial basis was used and shows the annualization or averaging math.
6. **One HTML file only.** No Markdown twin, no extra artifacts in the prospect folder.

## Reference files

- `references/scoring-model.md` — the exact scoring model: baseline lookup, adder rubrics, subtractor rubrics, unit-economics definitions, financial-basis rules, and a worked verification example. **Load on every run.**

## Templates

- `templates/value-estimate.html` — the single-page HTML report (visual language matches prospect-evaluation's reports).
