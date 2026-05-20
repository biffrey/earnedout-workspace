# Buy Box, Criteria, and Scoring

Single source of truth for evaluating a prospect.

---

## 1. Buy Box Screening Header (six hard checks)

These six checks appear at the top of every report as ✅ (meets), ❌ (likely does not meet), or ⚠️ (insufficient data).

| # | Criterion | Threshold | Notes |
|---|-----------|-----------|-------|
| 1 | Full-time employees | ≥ 10 | Full-time only. Contractors and PT not counted here. |
| 2 | EBITDA | ≥ $1,000,000 / year (no upper ceiling) | SDE is acceptable as a proxy if EBITDA is not disclosed; note the distinction. |
| 3 | Years in business | ≥ 10 | From original founding / SOS registration date. |
| 4 | Revenue + profit growth | 3 consecutive years YoY | Both top-line and bottom-line must be rising. |
| 5 | Asking price | ≤ 4.0x EBITDA | Biffrey's standard ceiling. >4x → ❌ here (header is strict), but see scoring below for the negotiation band. |
| 6 | DSCR | > 1.4 | **Informational only.** NOT part of the 0–100 score. |

**Overall Buy Box verdict:**
- **PASS** — all six ✅
- **CONDITIONAL** — 4–5 ✅ (state which ones are ❌ and whether they're negotiable)
- **FAIL** — ≤3 ✅

### Roll-up add-on relaxed thresholds

When the target is a **roll-up add-on** for an existing platform company, the Buy Box header still displays ✅/❌ against the **standard** thresholds above — but the report must also include a secondary "Add-on Thresholds" row. The relaxed floors depend on the platform company:

**Applied Development add-ons** (translation & interpretation — NAICS 541930: sign language interpreting, CART, VRI, deaf services, and spoken/foreign-language translation & interpreting): **no size floor.** Evaluate every such business that comes to market regardless of full-time employees, EBITDA, or years in business. An Applied Development add-on is never rejected for being too small — Biffrey already holds a platform company in this space (valued at ~6.5x), so any acquirable target may be worth the effort.

**Fambro Waste Management add-ons** (commercial / construction waste):

| Criterion | Standard | Add-on floor |
|---|---|---|
| Full-time employees | ≥ 10 | ≥ 5 |
| EBITDA | ≥ $1M | ≥ $500K |
| Years in business | ≥ 10 | ≥ 5 |

The other three header checks (3-yr growth, asking price ≤4x, DSCR >1.4) are unchanged for add-ons of either platform.

If a target fails the standard thresholds but qualifies as an add-on — passing the Fambro floors, or being any Applied Development add-on — the overall verdict should be **CONDITIONAL (add-on)** rather than FAIL, with a note: "Does not meet standalone thresholds but qualifies as a roll-up add-on for {{platform company}}."

### SBIC (Small Business Investment Company) targets

An SBIC target is the acquisition of the **general partner / management entity that holds an SBA SBIC license**. The strategic rationale is obtaining a license already in good standing, which short-circuits the lengthy de novo SBA SBIC licensing process.

**Gate — the only pass/fail criterion that matters:** the SBIC license is **active and in good standing** with the SBA (no revocation, surrender, capital impairment, or outstanding SBA enforcement action).

The standard Buy Box financial checks (EBITDA, full-time employees, revenue/profit growth, valuation multiple, DSCR) are **reported but non-gating** for SBIC targets — they do not drive the verdict. Still pull and show the GP entity's economics (management-fee revenue, EBITDA, FTE count, AUM / committed capital, outstanding SBA leverage, fund vintage and remaining life) as **informational** context, and compute the 0–100 score as an **informational** figure only. The pursue/pass decision rests on license good standing.

**Verdict for SBIC targets:** PASS if the license is active and in good standing; FAIL if it is not; CONDITIONAL if good standing cannot yet be confirmed. Any change of control of a licensed SBIC requires SBA approval — treat that as a closing condition, not a screening gate.

---

## 2. Full financial criteria (mandatory)

- ≥ 10 full-time employees
- EBITDA (or SDE) ≥ $1M (no upper ceiling)
- EBITDA margin ≥ 15%
- ≥ 10 years in business
- 3 consecutive years of revenue AND profit growth
- EBITDA multiple < 4x (strict for header; see scoring band below)
- Recurring revenue **preferred** — one-time/project-based allowed but scores lower
- Customer concentration ≤ 20% — allowed above 20% only if seller financing is offered

**Not required (nice to have):**
- Clean/audited financials (tax-return-based is fine)
- Low CapEx (CapEx-heavy OK)
- SBA eligibility

**Always leave blank if not provided:**
- Customer lifetime value (LTV)
- Customer acquisition cost (CAC)

---

## 3. Operational criteria

- Prefer established management in place.
- Must NOT require daily owner involvement. If the owner is the business, that's a deal-killer.
- EOS maturity not required; process implementation is a value-add.
- Operational cleanup / modernization is acceptable and often preferred.

---

## 4. Seller motivation

**Prioritize:**
- Retirement sellers

**Avoid:**
- Turnarounds
- Distressed situations

---

## 5. Deal structure preferences

**Preferred:**
- Leveraged buyouts
- Seller financing

**Optional:**
- SBA 7(a) or 504 loans (not required when seller financing is offered)

**Other:**
- Seller does NOT need to stay post-sale.

---

## 6. Lead Score (0–100) — EXACT rubric

Use this rubric verbatim. Show per-line math in the report.

| # | Item | Max pts | Rule |
|---|------|---------|------|
| 1 | Industry match | 20 | 20 if clearly in a target industry (or allowed subset). 10 if adjacent/uncertain but not excluded. 0 if excluded or off-target. |
| 2 | EBITDA tier (non-cumulative) | 15 | **>$3M → 15**. **>$2M → 10**. **>$1M → 5**. **≤$1M → 0**. Take the highest applicable tier only. |
| 3 | Years in business | 10 | 10 if ≥10 years. 0 if <10 years. |
| 4 | 3 years consistent rev + profit growth | 10 | 10 if both rev and profit grew each of the last 3 years. 5 if one of the two grew consistently. 0 otherwise. |
| 5 | Recurring revenue | 10 | 10 if majority recurring (contracts, subscriptions, MRR). 5 if mixed / repeat-but-not-contracted. 0 if pure one-time/project. |
| 6 | Customer concentration | 5 | 5 if largest customer <20% of revenue. 0 if ≥20% (but note if seller financing is offered — business may still be acceptable). |
| 7 | Employees | 10 | 10 if ≥10 FTE. 0 if <10. |
| 8 | Valuation multiple | 15 | **≤4.0x EBITDA → 15**. **4.0x–5.5x EBITDA → 7** (flag in memo: "negotiate to ≤4x as condition of deal"). **>5.5x → 0**. |
| 9 | Low owner dependence | 5 | 5 if a general manager / second-in-command runs day-to-day without the owner. 0 if owner is daily operator. |
| 10 | Roll-up / add-on strategic fit (BONUS) | 10 | **10** if the target is a direct add-on for Applied Development (translation & interpretation — NAICS 541930: sign language, CART, VRI, deaf services, spoken/foreign-language translation) or Fambro Waste Management (commercial / construction waste). **5** if the target is in an adjacent niche that could plausibly bolt onto either platform (e.g., ADA compliance consulting for Applied Development, portable toilet rental for Fambro). **0** for all standalone (non-roll-up) targets. |
| | **TOTAL** | **110** | (100 base + 10 bonus; standalone targets max at 100) |

### Scoring notes

- **Non-cumulative EBITDA tier.** A business at $3.2M EBITDA gets 15 pts, not 30.
- **Valuation tiered.** Biffrey's ceiling is 4x, but he'll consider up to 5.5x if he can negotiate down. 4.0–5.5x still earns partial credit (7 pts) but the memo must include an explicit "negotiate to ≤4x" condition in the Risk Factors and Outlook sections.
- **Buy Box header vs scoring.** The header line "Asking price <4x EBITDA" remains strict (≤4x ✅, else ❌). A 4.5x target can still score 7 pts on rubric line 8 while showing ❌ in the header — this is intentional and signals "conditional / negotiate".
- **DSCR is informational only** and does not appear in the rubric.
- **Insufficient data**: if you cannot evaluate an item, award 0 and note it as "insufficient data — not awarded" in the breakdown so it's obvious the zero isn't a judgment.
- **Roll-up bonus (line 10)** is additive. Standalone targets max at 100; roll-up add-ons can reach 110. This intentionally pushes add-on targets to the top of batch rankings. When displaying the score, show it as "XX / 110" for add-on targets and "XX / 100" for standalone targets so the reader knows the denominator.
- **Add-on thresholds** apply only when the target is a roll-up add-on. Fambro Waste add-ons use the relaxed floors (5 FTE / $500K EBITDA / 5 yrs); Applied Development add-ons have **no size floor** at all. Standalone targets must meet the full standard thresholds. SBIC targets are screened on license good standing — see "SBIC (Small Business Investment Company) targets" above.

### Interpretation bands

**Standalone targets (max 100):**
- **85–100** — Strong pursue. Schedule outreach immediately.
- **70–84** — Pursue with conditions (e.g., negotiate multiple, confirm concentration).
- **50–69** — Review with partner before spending time.
- **< 50** — Pass, unless something highly strategic is in play.

**Roll-up add-on targets (max 110):**
- **95–110** — Top-tier add-on. Immediate outreach; flag for platform company leadership review.
- **80–94** — Strong add-on. Pursue with conditions.
- **60–79** — Viable add-on but needs partner review.
- **< 60** — Weak fit; pass unless uniquely strategic (e.g., fills a critical geographic gap).

---

## 7. Worked example

A digital marketing agency in FL, 14 years old, 22 FTE, $2.6M EBITDA on $13M revenue (20% margin), 3 consecutive growth years, 60% of revenue under retainer, largest customer 12% of revenue, asking 3.8x, GM runs day-to-day:

- Industry match: **20**
- EBITDA tier ($2.6M > $2M): **10**
- Years (14 ≥ 10): **10**
- 3-yr growth: **10**
- Recurring (60% retainer = majority): **10**
- Concentration (12% < 20%): **5**
- Employees (22 ≥ 10): **10**
- Multiple (3.8x ≤ 4.0x): **15**
- Owner dependence (GM in place): **5**
- **Total: 95 / 100**

Same agency but asking 5.0x → line 8 becomes 7, total = 87. Memo must flag "negotiate to ≤4x".

### Worked example — roll-up add-on

An ASL interpreting agency in VA, 7 years old, 8 FTE (plus 30 independent interpreters on 1099), $800K EBITDA on $3.5M revenue (23% margin), 3 consecutive growth years, 70% of revenue under government/education contracts (recurring), largest customer 15% of revenue, asking 3.5x, owner manages day-to-day but has a lead scheduler:

**Standard thresholds:** ❌ employees (<10), ❌ EBITDA (<$1M), ❌ years (<10) → would be FAIL as standalone.
**Applied Development add-on:** no size floor applies to Applied Development add-ons — the target is evaluated in full and lands at **CONDITIONAL (add-on)** regardless of size.

- Industry match (sign language/CART): **20**
- EBITDA tier ($800K — below $1M): **0**
- Years (7 — below 10 but above add-on floor): **0**
- 3-yr growth: **10**
- Recurring (70% gov/edu contracts): **10**
- Concentration (15% < 20%): **5**
- Employees (8 — below 10 but above add-on floor): **0**
- Multiple (3.5x ≤ 4.0x): **15**
- Owner dependence (owner manages, partial delegation): **0**
- Roll-up strategic fit (direct add-on for Applied Development): **10**
- **Total: 70 / 110**

Verdict: viable add-on, falls in the 60–79 "partner review" band. The zero lines are not deal-killers since the platform absorbs the scale gap — but owner dependence needs a transition plan.
