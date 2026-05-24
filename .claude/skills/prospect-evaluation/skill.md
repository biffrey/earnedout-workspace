---
name: Prospect Evaluation
description: Evaluates US-based businesses against Biffrey Braxton / EarnedOut's acquisition Buy Box. Use when the user asks to screen, score, evaluate, or write a deal memo for a prospective business acquisition, LBO target, small-cap M&A prospect, roll-up add-on, or asks to "run this through the buy box" or "score this prospect". Produces a Buy Box screening header, 26-field scorecard with a 0–100 lead score (up to 110 for roll-up add-ons), and an exhaustive supporting deal memo in both Markdown and HTML. Handles both single-business deep dives and batch screening of candidate lists. Supports roll-up add-on evaluation for Applied Development (sign language/CART) and Fambro Waste Management (commercial waste). Also screens SBIC (Small Business Investment Company) GP / management-company acquisitions.
---

# Prospect Evaluation Skill

Evaluates US-based businesses as acquisition targets for Biffrey Braxton (EarnedOut). Produces a deterministic Buy Box screen, a 0–100 lead score, and a full deal memo.

> **Path note.** Every `references/…` and `templates/…` path in this skill is relative to **this skill's own directory** — the folder that contains this `skill.md`. Load those files from beside this file. Do not resolve them against the caller's working directory, and never fall back to a copy under `~/.claude/` or any other location. The rubric in `references/buy-box-and-scoring.md` is the single source of truth — read it from disk and apply it verbatim; never score from memory or approximation.

## Core outputs (always, in this order)

1. **Buy Box Screening Header** — six ✅/❌ checks, each with a cited data point.
2. **26-field Scorecard** — the exact output fields listed in `references/research-playbook.md`.
3. **Lead Score 0–100** (or 0–110 for roll-up add-ons) — computed using the exact rubric in `references/buy-box-and-scoring.md`, with per-line math shown.
4. **Supporting Deal Memo** — the 11 sections (Executive Summary → Appendix) as defined in `templates/single-report.md`.

Outputs are written to the user's current working directory as both `<company-slug>-report.md` (the working doc) and `<company-slug>-report.html` (a shareable single page). Never skip either format.

## Workflow

### Step 1 — Mode + context detection
Decide **single** vs **batch**:
- **Single** when the user gives one company name, one folder of documents, one URL, or one CIM.
- **Batch** when the user gives a list, a spreadsheet, a folder containing multiple sub-folders, or says "screen these / score this list / which of these should I pursue".

Also detect **roll-up add-on** context:
- If the target is in translation or interpretation services (NAICS 541930) — sign language interpreting, CART/captioning, VRI, deaf services, or spoken/foreign-language translation & interpreting → it's a potential **add-on for Applied Development**. There is **no size floor** for Applied Development add-ons — evaluate every such business regardless of size. Include the +10 bonus scoring line.
- If the target is in commercial waste, construction waste, dumpster rental, C&D hauling, or debris recycling → it's a potential **add-on for Fambro Waste Management**. Apply the relaxed add-on thresholds (5 FTE / $500K EBITDA / 5 yrs) and the +10 bonus line.
- For all other target industries → evaluate as **standalone** with standard thresholds and max score of 100. SBIC targets are standalone — see rule 13 below.

Ask the user for clarification only if the mode or roll-up context is genuinely ambiguous.

### Step 2 — Gather provided materials
- Use `Read` to load every document the user references (PDFs, CIMs, P&Ls, tax returns, emails, listing screenshots).
- Note any document that appears to need OCR (scanned images without text) and tell the user.
- Extract structured facts first (revenue by year, EBITDA, employees, location, asking price, founding year, principal names).

### Step 3 — Industry + geography gate
Load `references/industries-and-geography.md`. Before doing any deep research:
- Confirm the business sits inside a target industry (or is a disallowed subset — e.g., nuclear pharmacy retail, precious metals jewelry retail).
- Apply the exclusion list (restaurants, retail, distressed, weapons manufacturers).
- Apply geography rules, including the law-firm jurisdiction rule (AZ, PR, UT, MD, DC, VA only).
- If the target fails the gate, say so loudly up top but **still fill in the scorecard and score** so the user has a full record of why it was rejected.

### Step 4 — Buy Box screening
Load `references/buy-box-and-scoring.md`. Evaluate the six hard criteria:
- ≥10 full-time employees
- EBITDA $1M or more (no upper ceiling)
- 10+ years in business
- 3+ years of YoY revenue and profit growth
- Asking price ≤ 4x EBITDA
- DSCR > 1.4 (informational only — not part of the 0–100 score)

For each, emit ✅ or ❌ with a one-line evidence citation. If a criterion can't be evaluated (data missing), mark it ⚠️ "insufficient data" — never guess a pass.

### Step 5 — Data gathering (fill the 26 fields)
Load `references/research-playbook.md` for the source-priority order per field. For any field not in the provided docs, **aggressively** research the web using `WebSearch` and `WebFetch`:
- Company website, About / Team / History pages
- LinkedIn company page and principal profiles
- State Secretary of State business registries (for founding date, officers, registered agent)
- County assessor records (for owned real estate)
- BizBuySell / BizQuest / Axial / broker listing pages (for asking price)
- News, press releases, podcast interviews, awards
- Industry-specific registries (FAA repair-station search for aerospace, NRC licensing for nuclear pharmacy, state bar for law firms, NPI/CMS for medical)
- Court records (PACER / state dockets) for law firms
- Wayback Machine for history and earliest capture

**Estimation rules:**
- Mark every estimated value with `(est.)` inline in the scorecard.
- Every estimated value MUST have a corresponding line in the Appendix showing the source, method, and math.
- Never fabricate financials. If a field cannot be sourced or reasonably estimated, leave it **blank**.
- LTV and CAC are left blank unless explicitly provided (per spec).

### Step 6 — Score (0–100 or 0–110 for add-ons)
Apply the rubric from `references/buy-box-and-scoring.md`. Show the per-line math in the "Lead Score Breakdown" section — not just the total. The base nine rubric items sum to 100. If the target is a roll-up add-on, also evaluate line 10 ("Roll-up / add-on strategic fit") for up to 10 bonus points (max 110). Show the denominator clearly: "XX / 100" for standalone, "XX / 110" for add-ons.

### Step 7 — Write the report
- **Single mode**: instantiate `templates/single-report.md` AND `templates/single-report.html` with the collected data. Write both files to the current working directory. File names: `<company-slug>-report.md` and `<company-slug>-report.html`.
- **Batch mode**: instantiate `templates/batch-screen.md` sorted by score descending, with bucketed lists (Top/Review/Pass/Excluded). After writing, offer to generate full single-business reports for the top candidates.

### Step 8 — Self-check before finishing
Verify all of:
- [ ] Every Buy Box ✅/❌/⚠️ has a cited data point in the evidence column.
- [ ] All 26 scorecard fields are filled OR explicitly blank per the rules (LTV/CAC blank is acceptable).
- [ ] The score math sums correctly and matches the header number.
- [ ] The appendix lists every URL actually fetched (not a generic "research sources" list).
- [ ] Every `(est.)` value has an appendix entry showing the method.
- [ ] Both `.md` and `.html` outputs exist in single mode.
- [ ] For law-firm targets, the state of domicile is named and the legality rationale (AZ/PR rule, UT sandbox, or Brandon Thornton jurisdictions MD/DC/VA) is stated.

## Behavioral rules (always)

1. **Never fabricate financials.** Missing > guessed.
2. **Tag estimates with `(est.)`** and justify them in the Appendix.
3. **Leave LTV and CAC blank** unless the user provided them.
4. **Valuation multiple tiered scoring** (≤4.0x = 15 pts, 4.0–5.5x = 7 pts, >5.5x = 0 pts). See scoring reference for details.
5. **EBITDA tier is non-cumulative** — take the highest applicable tier only.
6. **DSCR > 1.4 is informational only** — it appears in the header but is NOT part of the 0–100 score.
7. **Law firms**: explicitly state the state of domicile and the legality rationale. Reject law firms outside AZ, PR, UT, MD, DC, VA.
8. **Precious metals and nuclear pharmacy**: confirm the target sits in the allowed subset (refiners/recyclers; radiopharma/oncology compounding). Otherwise reject.
9. **Weapons manufacturers**: reject. Government / DOD / cybersecurity / aerospace-support / emergency-management firms are fine.
10. **Fail-the-gate targets still get a full scorecard and report** — the user wants a clear record of *why* a prospect was rejected, not just a one-word "no".
11. **Roll-up add-on detection is automatic.** If the target's industry matches translation/interpretation services (NAICS 541930 — sign language, CART, VRI, deaf services, or spoken/foreign-language translation) → Applied Development add-on, evaluated with **no size floor** (any size is worth evaluating). If it matches commercial/construction waste → Fambro Waste Management add-on, evaluated with the relaxed add-on thresholds (5 FTE / $500K EBITDA / 5 yrs). Both include the +10 bonus scoring line and use the add-on interpretation bands (max 110). The report must name the platform company explicitly.
12. **Platform companies:**
    - **Applied Development** — communications access, sign language interpretation, CART.
    - **Fambro Waste Management** — construction and commercial trash management.
13. **SBIC targets.** An SBIC acquisition is the purchase of the GP / management entity holding an SBA SBIC license. The sole gating criterion is that the license is **active and in good standing**; the standard EBITDA / FTE / growth / valuation criteria are reported but non-gating, and the 0–100 score is informational only. Any change of control of a licensed SBIC requires SBA approval (closing condition). See `references/buy-box-and-scoring.md` → "SBIC (Small Business Investment Company) targets".

## Reference files (load only when needed)

These live in this skill's own `references/` directory, beside this `skill.md` (see the Path note above).

- `references/buy-box-and-scoring.md` — Buy Box criteria, full financial/operational criteria, deal structure prefs, and the exact 0–100 rubric.
- `references/industries-and-geography.md` — Target industries with keyword lists, exclusions, geography priorities, law-firm jurisdiction rules.
- `references/research-playbook.md` — Field-by-field source playbook for the 26 scorecard items.

## Templates (instantiate on output)

- `templates/single-report.md` — Full Markdown deal memo.
- `templates/single-report.html` — Styled HTML single page.
- `templates/batch-screen.md` — Batch ranked screen table.
