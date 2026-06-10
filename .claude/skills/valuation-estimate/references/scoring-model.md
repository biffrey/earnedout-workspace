# Valuation Estimate — Canonical Scoring Model

Extracted from the "2025 YTD Value Estimate" tab of Biffrey's scorecard workbook
(`AD P&L EBITDA thru Mar 2025_BBr2.xlsx`). Replicate exactly. Every threshold,
point value, and definition below is frozen.

## 1. Financial basis for Revenue and EBITDA

Choose ONE basis for both Revenue and EBITDA, in this priority order, using
whatever the documentation supports. Always state in the report which basis was
used and show the math.

1. **Trailing-24-month average** — sum the trailing 24 months and divide by 2
   (a smoothed annual run-rate). Preferred whenever 24 months are derivable
   from the documents.
2. **Most recent complete fiscal year.**
3. **Annualized partial year** — YTD × (12 ÷ months elapsed). This mirrors the
   workbook's approach (3 months YTD × 4).

## 2. Baseline EBITDA multiple (lookup from EBITDA dollars)

| EBITDA $ | Baseline multiple |
|---|---|
| < $1M | 2x |
| $1M – $3M | 3x |
| $3M – $5M | 4x |
| $5M – $10M | 5x |
| $10M+ | 6x |

Show this full table in the report (the workbook displays it as the
"Baseline Range" block).

## 3. Value adders (added to the baseline multiple)

| Line | Input | Rubric |
|---|---|---|
| Revenue Growth % | Growth vs. the prior comparable period (state the basis used in the report) | 0 if 0–30% · +1 if 30–100% · +2 if 100%+ |
| Yearly Revenue Retention % | Documented or estimated annual revenue retention | 0 if <80% · +2 if >80% |
| EBITDA Margin | EBITDA ÷ Revenue (chosen basis) | 0 if <30% · +0.5 if 30%+ |
| LTV:CAC Ratio | LTV ÷ CAC (see unit economics below) | 0 if <10 · +1 if >10 |
| TS Clearance | Does the business hold Top Secret-cleared contracts, facility clearance, or cleared staff? | +1 if yes · 0 otherwise |

**TS Clearance is literal.** Most non-govcon prospects score 0. Do not
generalize the line into certifications, licenses, or moats.

**Total adders = sum of the five lines** (range 0 to 6.5).

## 4. Value subtractors (subtracted from the multiple, each Y/N)

| Line | Points if risk | Definition / what to look for |
|---|---|---|
| Key Man Risk | −3 | Business depends on one person (usually the owner) for sales, delivery, relationships, or licenses |
| Key Client Risk | −2 | Material revenue concentration in one or few clients |
| Single Channel Risk | −1 | One dominant lead/revenue channel (one contract vehicle, one referral source, one platform) |
| Market Risk | −1 | Demand-side risk: shrinking market, regulatory exposure, fad dependence |
| Data Risk | −1 | Unreliable, incomplete, or unauditable financial records/books/systems |

Each line scores its full penalty if **Y** (risk present), 0 if **N**.

**The skill makes all five Y/N calls itself** from the documentation and shows
written reasoning for each in the report. The user overrides afterwards if
they disagree.

**Total subtractors = sum of the five lines** (range 0 to 8).

## 5. Unit-economics inputs (the workbook's J–L block)

| Input | Definition |
|---|---|
| Customers Acquired Last Period | Count of new customers/contracts won in the last period |
| LTV | (total contract value ÷ number of contracts) ÷ customers acquired last period |
| CAC | (GA Business Development expense + B&P/proposal expenses) ÷ customers acquired last period. For non-govcon businesses, use the closest documented equivalent: sales & marketing + business-development spend |
| LTGP | gross profit ÷ customers acquired last period |

**Scoring impact:** only the **LTV:CAC ratio** feeds the score (the adder in
§3). LTV, CAC, and LTGP are display-only on their own; **LTGP never affects
the score**.

## 6. Valuation

- **Multiple Score = Baseline Multiple + Total Value Adders − Total Value Subtractors**
- **Estimated Valuation = EBITDA (chosen basis) × Multiple Score**

The workbook writes these equations as "C5 + C12 − C19" and "B5 x C21";
the report must express them in plain words exactly as above, with the
substituted numbers shown — never as cell references.

## 7. Worked verification example (from the source workbook)

Inputs as the workbook computes them (annualized YTD basis, Mar 2025 YTD × 4):

| Input | Value | Result |
|---|---|---|
| Revenue | $9,147,541.64 | — |
| EBITDA | $1,374,678.28 | baseline **3x** ($1M–$3M band) |
| Revenue Growth % | 4.48% | adder **0** |
| Yearly Revenue Retention % | 91% | adder **+2** |
| EBITDA Margin | 15.03% | adder **0** |
| Customers Acquired Last Period | 3 | — |
| LTV | $726,126.46 | — |
| CAC | $20,725.72 | — |
| LTV:CAC | 35.04 | adder **+1** |
| TS Clearance | Yes | adder **+1** |
| All five subtractors | N | **0** |

- Total adders = 0 + 2 + 0 + 1 + 1 = **4**
- Total subtractors = **0**
- Multiple Score = 3 + 4 − 0 = **7**
- Estimated Valuation = $1,374,678.28 × 7 = **$9,622,747.96**

Any implementation of this model must reproduce these numbers from these
inputs. If your computation disagrees, your implementation is wrong — fix it
before producing a report.
