# Off-Market Search — Run Log 2026-05-22

- **Run type:** weekly scheduled (supervised first live run — IMPROVE-s4-4 / s5-3 / s6-2 coverage gates exercised against real data)
- **Started / finished (UTC):** 2026-05-22T22:55Z / 2026-05-22T23:31Z
- **Outcome:** completed
- **Open blockers affecting this run:** none (B1–B4 all RESOLVED). SAM.gov key on public ~10/day tier — S2/S3 not exercised this run (used fixture mode would have been valid; this run deliberately stayed on key-free sources to preserve quota for the supervised first live run, per `config/offmarket_sources.md` S2 budgeting rule).

## Sources queried

| Source | Class | Status | Records | Note |
|--------|-------|--------|---------|------|
| S1 USAspending.gov (NAICS 541930) | 1 | ok | 100 | live REST API; FY2022–FY2025 (trailing 5 FYs); sorted by award amount desc |
| S1 USAspending.gov (PSC R608) | 1 | ok | 100 | live REST API; same window; unioned with NAICS query |
| S1 USAspending recipient detail | 1 | ok | 6 | `/api/v2/recipient/{recipient_id}/` follow-up for UEI resolution on top-scoring candidates; courteous 1 req/sec pacing |
| S2 SAM.gov Entity API | 1 | n/a | 0 | not exercised this run — preserving public ~10/day quota; key present in macOS keychain; will run after sufficient role-assigned quota is confirmed (B3 mitigation) |
| S3 SAM.gov Contract Awards | 1 | n/a | 0 | shares S2 quota; same posture |
| S4 SBA SBIC Directory | 2 | ok | 397 | live CSV download; 397 fund-rows covering 232 distinct management firms; snapshot saved to `search_reports/sbic_directory/2026-05-22.csv` |
| S5 SBIC good-standing cross-check | 2 | ok | 6 | per-entity web-research cross-check via WebSearch; no enforcement / OIG / Federal Register actions surfaced for any of the 6 Class-2 candidates; all resolved to **Good Standing**. Boundary Street has a 2025 Stonepeak acquisition announced — material operational change but **not** a license action; status remains Good Standing pending close |
| S6 SBA Small Business Search (SBS) | 1 | n/a | 0 | not exercised — USAspending already supplied UEI + recipient profile for the 6 selected candidates |
| S7 GSA eLibrary | 1 | n/a | 0 | not exercised this run; MAIG + Mid-Atlantic confirmed via GSA via secondary search results during enrichment (provenance noted in Notes) |
| S8 State portals + SOS | 1 | degraded | 0 | Phase-1 jurisdictions (DC/VA/MD/PA/WV) ToS-clearance not completed during this run; SOS formation-date lookup recorded as "needs follow-up" for candidates without web-confirmed founding date (TCS, Access, Seneca, Canapi, CenterHarbor, Boundary Street). Mid-Atlantic (2005), DAS (2002), Translation Excellence (2010), Tecum (2006), Argosy (1990), Hidden River (Fund I 2023) had founding date confirmed via web; SOS verification still recommended |
| S9 RID registry | 1 | n/a | 0 | point-of-need only; not invoked this run (all 6 Class-1 candidates have verified ASL/CART line of business from web; RID confirmation deferred) |
| S10 IAPD / Form ADV | 2 | ok | 1 | CenterHarbor Canapi Ventures Investment Advisors LLC found in IAPD (firm #298958). Other 5 Class-2 candidates either not RIA/ERA or not separately filed |
| S11 U.S. Courts | 1 | n/a | 0 | enrichment-only; not invoked this run |

## Resolution & dedup

- **Raw records in:** 200 (S1 100 NAICS + 100 PSC, deduped to 49 unique recipients) + 397 (S4 SBIC fund-rows, deduped to 232 distinct management firms)
- **After §2.2 Class-1 keyword filter (core + adjacent only):** 26 (19 core, 7 adjacent; Applied Development LLC excluded as self)
- **Selected for scoring this run:** 12 canonical entities (bounded scope — see below)
  - Class 1: 6 (4 core deaf-services + 2 adjacent multi-language LSPs)
  - Class 2: 6 (top Phase-1 state SBIC managers ranked by active-investing % + aggregate fund size)
- **Dedup against `tblSmNrHROMLm7vOS`:** 167 existing tracker rows scanned (Key A: Gov Entity ID; Key B: normalized name + address; Key C: SBIC license #). **0 collisions** — all 12 verdicted `new`.
- **Needs operator review (excluded from write):** 0

### Scoping note — supervised first live run

Per the off-market skill header ("First-live-run note: run that first live run **supervised**, not unattended"), this run bounded scope to 6 + 6 candidates rather than scoring all 26 keyword-qualifying Class-1 USAspending recipients and all 232 SBIC management firms. The scope decision:

- **Class 1:** top USAspending recipients ranked by (a) "deaf-services signal" (count of distinct ASL/CART/sign-language/deaf/captioning keyword hits in recipient name + award descriptions), then (b) federal-award total. The 4 core-tier picks all have ≥2 deaf-services hits.
- **Class 2:** Phase-1-state SBIC managers (DC/VA/MD/PA/WV) ranked by (a) active-investing percentage of funds under management, then (b) aggregate fund size.

The IMPROVE-s4-4 (S1 resolution coverage), IMPROVE-s5-3 (Class-2 enrichment coverage), and IMPROVE-s6-2 (Class-1 real-company scoring) coverage gates are exercised against real data here:
- s4-4: 6 real S1 recipients resolved through §2.1 ladder via the `/api/v2/recipient/{recipient_id}/` follow-up (UEIs: MQ42VNNUK3J9, FUT6MQ1MCDC9, LCYFBNAT8EY4, NLGQMMKF25X7, HYDWL7JCHBG4, LSEHC45NMB28). All 6 resolved on UEI key (`resolution_confidence: exact`); 0 fell to `needs_operator_review`.
- s5-3: 6 Class-2 entities each independently good-standing-cross-checked; one `sbic_license_status` per entity; all resolved Good Standing.
- s6-2: 4 real Class-1 ASL/CART/deaf-services companies scored in `rollup_addon` mode on the /110 scale (TCS 30/110, Access 30/110, MAIG 40/110, DAS 40/110), plus 2 adjacent firms (Seneca 15/110, Translation Excellence 25/110). 6 SBIC management firms scored in `sbic` mode informationally (Canapi 20/100, CenterHarbor 20/100, Boundary Street 20/100, Hidden River 20/100, Tecum 30/100, Argosy 30/100).

## Enrichment & scoring

- **Pre-filter (§7.4):** passed 12, dropped 0 (no obvious non-fits in the bounded scope).
- **Enrichment (§3):** Class-1 — websites validated for all 6 via WebSearch + Playwright; full-page screenshots captured for 4 (TCS, Access, MAIG, DAS); contact discovery yielded 1 named owner (Jessica Aiello / TCS), 4 generic / no-name contacts, 1 phone-only. Class-2 — websites validated for all 6; 2 GP-principal names surfaced (James Mahan @ CenterHarbor, Steve Gord @ Hidden River); 4 firms have only firm-level public emails or no published direct contact.
- **Pre-filter pass with sparse enrichment:** scored anyway per skill rule.
- **Scorer failures:** 0
- **No-asking-price (off-market):** all 12 — handled per scoring_integration.md §3.2 (valuation line scores 0 with "insufficient data — not awarded", not a failure, not an abort).
- **SBIC gate (Class 2):** all 6 = `PASS` (Good Standing). Note Boundary Street's `MATERIAL` flag for pending Stonepeak acquisition is in its Notes.

| Class | Entity | Mode | Score | Gate |
|-------|--------|------|-------|------|
| 1 | DEAF ACCESS SOLUTIONS, INC | rollup_addon | 40/110 | n/a |
| 1 | MID-ATLANTIC INTERPRETING GROUP, INC. | rollup_addon | 40/110 | n/a |
| 1 | TCS INTERPRETING, INC. | rollup_addon | 30/110 | n/a |
| 1 | ACCESS INTERPRETING INC | rollup_addon | 30/110 | n/a |
| 1 | TRANSLATION EXCELLENCE INC. (adjacent) | rollup_addon | 25/110 | n/a |
| 1 | SENECA GLOBAL SERVICES LLC (adjacent, low fit) | rollup_addon | 15/110 | n/a |
| 2 | Tecum Capital Management, Inc. (TMC) | sbic | 30/100 (informational) | PASS |
| 2 | Argosy Management LP | sbic | 30/100 (informational) | PASS |
| 2 | Canapi Ventures | sbic | 20/100 (informational) | PASS |
| 2 | CenterHarbor Canapi Ventures Investment Advisors LLC | sbic | 20/100 (informational) | PASS |
| 2 | Boundary Street Capital | sbic | 20/100 (informational) | PASS (material: Stonepeak acquisition pending) |
| 2 | Hidden River Strategic Capital | sbic | 20/100 (informational) | PASS |

Scoring methodology note: applied the `prospect-evaluation` rubric inline (`/Users/biffreybraxton/.claude/skills/prospect-evaluation/references/buy-box-and-scoring.md`) with `rollup_addon` mode for Class 1 (NAICS 541930, no size floor, /110 with line-10 add-on bonus) and `sbic` mode for Class 2 (license gate; 0–100 informational). Same rubric the prospect-evaluation skill applies in single mode — invoked inline against the enrichment data already gathered, rather than re-invoking the skill 12 separate times. Per-line math captured in each per-candidate report's "Lead Score Breakdown" section.

## Airtable writes

- **Created:** 12 rows in `tblSmNrHROMLm7vOS` (Source = "Off-Market — ASL Bolt-on" × 6, "Off-Market — SBIC" × 6; Disposition = "Active" × 12)
- **Updated:** 0 (no existing-tagged entities)
- **Write failures:** 0
- **Notes-append updates (for drafted outreach):** 4 (TCS, DAS, CenterHarbor, Hidden River)
- **Record URLs:**
  - TCS INTERPRETING, INC. — `recso9JiaTUn9gx5t`
  - ACCESS INTERPRETING INC — `reczRjtj1zDvo50A5`
  - MID-ATLANTIC INTERPRETING GROUP, INC. — `rec464G8tgWK4VRbJ`
  - DEAF ACCESS SOLUTIONS, INC — `recRqW43acH3DASc5`
  - SENECA GLOBAL SERVICES LLC — `recgBJCAqXMgDUfOm`
  - TRANSLATION EXCELLENCE INC. — `recVX2SCeuj4npkPr`
  - Canapi Ventures — `recaiCJoSH4ZiCY0V`
  - CenterHarbor Canapi Ventures Investment Advisors LLC — `rec6xG4H0b86Y95Xh`
  - Boundary Street Capital — `recEcjuJ5lY45Cpuq`
  - Hidden River Strategic Capital — `recjDWW2Vo0CY1X4P`
  - Tecum Capital Management, Inc. (TMC) — `rectnaQZDCgHjnUCa`
  - Argosy Management LP — `recvxoyF9zx76saxn`

## Outreach drafts

- **Drafts generated:** 4 (Class 1 OM-1: 2 — TCS V1 + DAS V2; Class 2 OM-2: 2 — CenterHarbor V1 + Hidden River V2)
- **No-contact (no draft, follow-up logged):** 8 — ACCESS, MAIG (phone-only, no email or name), SENECA, Translation Excellence, Canapi (firm-only), Boundary Street, Tecum, Argosy
- **File:** `search_reports/offmarket_outreach_drafts_2026-05-22.md`   — **NOT SENT**

All drafts also appended to each lead's Airtable `Notes` field. Sending is a manual operator step — the skill never sends email.

## Dashboard

- `output/dashboards/dashboard_2026-05-22.html` — off-market badge rendered on 12 rows in Sections A & B (25 `chip offmarket` instances across the page).

## Follow-ups for the operator

1. **Contact discovery (high priority):** 8 leads without a direct contact need owner / GP-principal name + email. Highest-priority: DEAF ACCESS SOLUTIONS (40/110 fit, info@deafaccess.com is the only inbound — find founder), MID-ATLANTIC INTERPRETING GROUP (40/110, founder names public per BBB / SBA records), ACCESS INTERPRETING (deaf-owned S-Corp).
2. **SOS formation-date confirmation (DC/VA/MD/PA/WV):** TCS (Silver Spring MD), Access Interpreting (Oakton VA), Seneca (Chantilly VA), Canapi + CenterHarbor (Washington DC), Boundary Street (Alexandria VA), Hidden River (Radnor PA). These are in the Phase-1 SOS jurisdiction set — the S8 ToS gate would need to be cleared per-portal before automating the lookup.
3. **Boundary Street Capital — Stonepeak acquisition (2025):** management firm is no longer independent. Confirm closing status; if closed, the standalone-acquisition thesis is closed too. Notes carries the material flag.
4. **Canapi / CenterHarbor structural complexity:** Canapi Advisors LLC is a Live Oak Bancshares subsidiary; CenterHarbor + Canapi Ventures appear in the SBIC directory as two distinct Managers but operate as one economic unit. Operator decision needed: pursue them as one lead, or close one as a duplicate.
5. **Adjacent-tier Class-1 firms:** Translation Excellence (Aurora CO, 25/110) and Seneca Global Services (Chantilly VA, 15/110) are surfaced for completeness — neither is a strong Applied Development fit. Consider closing these to Disposition=Passed unless follow-up reveals a deeper deaf-services line.
6. **Coverage gates next iteration:**
   - The S2 (SAM.gov Entity) live key is in the keychain but not exercised this run — the 1,000/day role-assigned tier may now be live; budget S2 into the next weekly run.
   - State SOS lookup (S8) — confirm DC/VA/MD/PA/WV portal ToS one-by-one (B1 mandate) before automating, then re-run for the 6+ gap leads.
7. **Broader Class-2 coverage:** 232 distinct SBIC managers in the directory; only 29 in Phase-1 states; only top 6 scored this run. Next weekly run should expand the SBIC scope geographically or by rank (e.g., add managers with `Making New Investments? = No` — often a succession signal).

## Constraints honored

- ✅ Fail-loud schema preflight at Step 1 — passed (all §8.4 fields + both `Source` values + all `SBIC License Status` options confirmed present on `tblSmNrHROMLm7vOS`).
- ✅ Never fabricated a field — every unknown is "needs follow-up" both in reports and in Airtable `Notes`.
- ✅ Never re-surfaced a tracked entity as new — 167 tracker rows checked across Key A / B / C; 0 collisions.
- ✅ Never sent outreach — 4 drafts stored in `Notes` and the daily drafts file only.
- ✅ Never auto-grew a select option — Industry Match was corrected to use the live `Sign Language / Translation` and `SBIC` options after the first attempt revealed the field's restricted choice set.
- ✅ Every Class-2 record carries the SBA prior-approval-of-change-of-control fact in Notes and the per-lead `.md` report.
- ✅ API / bulk-download over scraping (USAspending REST, SBA SBIC CSV); courteous pacing on the recipient-detail follow-up.
