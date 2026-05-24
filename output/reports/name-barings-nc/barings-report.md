# Barings — SBIC Prospect Evaluation

**Prepared for:** Biffrey Braxton / EarnedOut
**Report date:** 2026-05-23
**Prepared by:** Claude (Prospect Evaluation skill — off-market-search invocation, sbic mode)
**Lead source:** Off-Market — SBIC (SBA SBIC Directory)

> **SBIC target** — screened on SBA license good standing; standard financial criteria and the 0–100 score are **informational only** (per prospect-evaluation rule 13 and `buy-box-and-scoring.md` § "SBIC targets").
>
> **Closing condition (carried on every Class-2 record):** Any **change of control** of a licensed SBIC requires **SBA prior approval**. Treat as a closing condition, not a screening gate.

---

## SBIC Gate (sole pass/fail)

| Criterion | Status | Evidence |
|---|:---:|---|
| SBIC license active and in good standing | ⚠️ | License appears on the SBA SBIC directory (currently licensed). Good-standing cross-check (Federal Register / SBA enforcement / OIG) **NOT yet performed for this entity** — S5 enrichment is a per-entity follow-up. **`SBIC License Status: Unknown`** until cross-checked. |

**Overall verdict:** **CONDITIONAL** — license confirmed currently listed on the SBA SBIC directory; good standing pending operator confirmation via S5 cross-check.

**Informational Lead Score:** **30 / 100** (sbic mode — informational only, does not drive the pursue/pass decision; gate is the sole determinant).

---

## Buy Box Screening (informational only — per SBIC mode)

| # | Criterion | Status | Evidence |
|---|-----------|:------:|----------|
| 1 | ≥ 10 full-time employees (GP staff) | ⚠️ | GP staff count not in SBA SBIC directory |
| 2 | EBITDA ≥ $1M / year | ⚠️ | GP mgmt-fee economics not publicly disclosed |
| 3 | 10+ years in business | ⚠️ | earliest fund vintage 2021 (~5 yrs of SBIC history) |
| 4 | 3+ yrs YoY revenue and profit growth | ⚠️ | Not publicly disclosed |
| 5 | Asking price ≤ 4.0x EBITDA | ⚠️ | Off-market — no asking price |
| 6 | DSCR > 1.4 (informational) | ⚠️ | Not computable |

---

## GP / Management Entity Profile (informational)

| Field | Value | Source |
|---|---|---|
| Management entity | Barings | SBA SBIC Directory ("Managed by") |
| Location (city, state) | Charlotte, NC | SBA SBIC Directory |
| # licensed funds under this GP | 2 | SBA SBIC Directory |
| Total committed capital (sum of fund sizes) | $256,872,224 | SBA SBIC Directory |
| Earliest fund vintage | 2021 | SBA SBIC Directory |
| Latest fund vintage | 2025 | SBA SBIC Directory |
| Any fund making new investments? | Yes | SBA SBIC Directory |
| Investment strategies | Mezzanine | SBA SBIC Directory |
| Fund styles | Hybrid, Private Credit | SBA SBIC Directory |
| Investor Relations contact (primary) | Scott Chappell — schappell@babsoncapital.com — (704) 805-7671 | SBA SBIC Directory |

### Licensed funds (full directory data)
- **Barings Small Business Fund II, LP** — vintage 2025, size $50,560,195, avg inv $0, strategy: Mezzanine, style: Private Credit, making new investments: Yes
- **Barings Small Business Fund, L.P.** — vintage 2021, size $206,312,029, avg inv $1,823,809, strategy: Mezzanine, style: Hybrid, making new investments: Yes

---

## Lead Score Breakdown (per-line math from buy-box-and-scoring.md — applied verbatim)

| # | Item | Awarded | Note |
|---|------|---------|------|
| 1 | Industry match (SBIC as recognized acquisition target — rule 13) | **20** | Target type recognized under prospect-evaluation rule 13. |
| 2 | EBITDA tier | **0** | GP mgmt-fee economics not publicly disclosed — insufficient data → not awarded. |
| 3 | Years in business | **0** | earliest fund vintage 2021 (~5 yrs of SBIC history) |
| 4 | 3-yr rev + profit growth | **0** | Insufficient data — not awarded. |
| 5 | Recurring revenue | **10** | SBIC mgmt-fee revenue is contracted during fund life; carry is performance-based but recurring |
| 6 | Customer concentration | **0** | LP concentration not disclosed — insufficient data. |
| 7 | Employees (≥10 FTE) | **0** | GP staff count not in directory — insufficient data. |
| 8 | Valuation multiple | **0** | Off-market — no asking price → insufficient data (per scoring_integration.md §3.2). |
| 9 | Low owner dependence | **0** | Insufficient data — not awarded. |
| 10 | Roll-up / add-on strategic fit | **0** | SBIC is not an Applied Development or Fambro Waste add-on — 0 (standalone SBIC acquisition). |
| | **TOTAL (informational)** | **30 / 100** | |

---

## Supporting Deal Memo

### 1. Executive Summary
Barings is a licensed SBIC general partner / management entity headquartered in Charlotte, NC that manages **2 licensed SBIC fund(s)** with **$256,872,224** of total committed capital across vintages 2021–2025. The acquisition target here is the **management entity that holds the SBIC license**, not the portfolio companies. The strategic rationale is acquiring an SBIC license already in good standing — short-circuiting the multi-year de novo SBA SBIC licensing process. **The company is not for sale**; outreach must be proprietary-approach via Template OM-2.

### 2. SBIC License Status (the gate)
- **Currently licensed:** ✅ confirmed via the SBA SBIC Directory (entry present in the 2026-05-23 CSV).
- **Good standing:** **⚠️ unconfirmed** — S5 enrichment (SBA enforcement actions, OIG reports, Federal Register license actions) not yet performed for this entity in this run. Operator follow-up needed before any LOI conversation.
- **License #:** not published in the directory — to be obtained from SBA on follow-up.
- **Outstanding SBA leverage:** not published — to be obtained from SBA on follow-up.

### 3. GP Economics (informational only)
Not publicly disclosed. Mgmt-fee revenue (typically 2.0–2.5% of committed capital during investment period, stepping down post-investment-period) and carried interest are the GP's two revenue streams. With $256,872,224 of committed capital, a typical mgmt-fee yield is in the rough range of **$3,853,083–$6,421,805 / year** during active fund life — this is a **rough size signal**, not a disclosed figure.

### 4. Investment Strategy & Activity
Strategies on file: Mezzanine. Fund styles: Hybrid, Private Credit. Active for new investments: **Yes** — an active GP suggests an ongoing economic engine.

### 5. Closing condition — SBA prior approval of change of control
Per SBA SBIC program rules, **any change of control of a licensed SBIC requires prior SBA approval**. This is a deterministic closing condition — not a screening gate — but it materially extends the timeline (typical SBA review: 90–180 days) and constrains acceptable buyers (the SBA evaluates the proposed new control party). Build this into the timeline from day one.

### 6. Recommendation & Next Steps
1. **S5 good-standing cross-check** (operator follow-up) — search SBA enforcement actions, OIG reports, and Federal Register SBIC license actions for "Barings" and any of its licensed fund names.
2. **Establish a direct line** — IR contact on file: Scott Chappell.
3. **Proprietary outreach Template OM-2** — discreet, principal-to-principal approach focused on the management-entity / license-transfer opportunity. Email: schappell@babsoncapital.com.
4. **Pre-LOI diligence** — pull SBA license number, outstanding SBA leverage, GP/LP partnership agreements (preferred-return waterfall, key-man provisions, mgmt-fee structure, carried-interest splits), fund expiration schedule.

### 7. Risks
- License-status risk: **Unknown** standing must be resolved before any binding commitment.
- SBA-approval timeline risk: closing extends to 90–180 days post-LOI.
- Key-man risk: GP economics often depend on a small set of senior principals.
- LP-consent risk: many LPA's require LP consent for a change of control of the GP.

### 8. Sources fetched this run
- SBA SBIC Directory CSV: `https://www.sba.gov/export/contacts/sbic` (downloaded 2026-05-23)
- Local snapshot: `search_reports/sbic_directory/2026-05-23.csv`

### 9. Scoring methodology notes
- Rubric applied verbatim from `.claude/skills/prospect-evaluation/references/buy-box-and-scoring.md` §6 — including SBIC mode rule (financials and 0–100 score informational only; gate is sole determinant).
- Off-market "no asking price" handled per `scoring_integration.md` §3.2 — valuation line scores 0 ("insufficient data — not awarded"), not a failure.
- `SBIC License Status: Unknown` is the default per `scoring_integration.md` §4 — never assume Good Standing.
