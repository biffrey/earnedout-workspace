/ultraplan

# Objective
Produce a Product Requirements Document (PRD) for an "Off-Market Target Search" system. This run is a PLANNING pass only — write the PRD, do NOT perform live searches, fetch from external sites, or build the tool.

# Step 1 — Understand the existing on-market system before planning anything
The published-listings (on-market) workflow lives in ~/published-listing-search. Read these two files in full and report back to me, in your own words, how on-market opportunities are sourced, scored, stored, and iterated on:
- ~/published-listing-search/REVAMP_PLAN.md
- ~/published-listing-search/REVAMP_LOOP_PROMPT.md

Then inspect the surrounding repo: folder structure, any tracker/database files, the schema of records, every CSV/JSON/Markdown file the loop reads or writes, and the prospect-evaluation skill / Buy Box if it is present. The off-market PRD must make off-market targets flow into the EXACT SAME tracking, scoring, and review structure as on-market listings — same fields, same files, same review cadence — with only the sourcing front-end being new. Do not invent a parallel system; the deliverable is a new intake pipeline feeding the existing tracker.

# Step 2 — The two target classes the PRD must cover
1. Bolt-on acquisitions for our ASL platform company. Our platform is the sign-language / CART captioning company referred to in the prospect-evaluation skill as Applied Development — confirm the exact entity name and thesis from the repo. "Off-market" means not currently listed for sale. We want operating companies providing sign-language interpretation, CART / realtime captioning, or related deaf/hard-of-hearing communication-access services that we could acquire and bolt onto the platform.
2. SBIC firms to acquire outright. We want to buy the SBIC management company itself — including its SBA SBIC license / fund — NOT its portfolio companies. Identify licensed Small Business Investment Companies that may be acquirable (e.g., aging fund managers, wind-down vintages, single-GP shops, dormant licensees).

# Step 3 — Required data sources (all government / open data)
The PRD must specify, source by source, exactly how to query each source and what to extract:
- FPDS-NG — Federal Procurement Data System, at fpds.gov — federal contract award history; use it to find companies that have won interpretation/captioning contracts.
- SAM.gov — entity registrations, NAICS codes, socioeconomic / small-business status, and contract opportunities.
- USAspending.gov — federal award and recipient data, prime- and sub-award contract history.
- SBA.gov — the official SBIC Program directory of licensed SBICs (primary source for target class 2); also the SBA Dynamic Small Business Search (DSBS) for target class 1.
- Any other relevant .gov sources you identify — e.g., GSA eLibrary / GSA Advantage schedule holders, state procurement portals, state Secretary of State business registries, the federal courts' interpreter procurement. List each in the PRD with a rationale.

For target class 1, propose candidate search keys and explicitly flag them for me to verify rather than stating them as confirmed: NAICS 541930 (Translation and Interpretation Services) and PSC code R608 (translation/interpreting) are starting points only — instruct that the exact current codes must be confirmed. Also define a keyword strategy (ASL, sign language, interpreting, CART, realtime captioning, communication access, deaf/HoH).

# Step 4 — Required PRD contents
Write a complete PRD that includes at least:
- Objective, success metrics, scope, and explicit non-goals.
- Definitions of the two target classes.
- Per-source methodology: query parameters, codes, filters, fields to extract, access method (UI vs. API vs. bulk download), and rate-limit / terms-of-service notes.
- Entity resolution and de-duplication: how to recognize the same company across FPDS-NG, SAM.gov, and USAspending, and how to avoid re-surfacing targets already in the tracker.
- Qualification: how a raw government record becomes a scored prospect using our existing Buy Box / prospect-evaluation criteria.
- Data schema, mapped field-by-field to the on-market tracker so off-market and on-market records are interchangeable.
- Workflow and cadence, mirroring the loop defined in REVAMP_LOOP_PROMPT.md.
- Integration plan: which existing files / trackers get written to, and how.
- Compliance and legal notes on using government data (ToS, bulk-access rules, FOIA considerations).
- Risks and an explicit open-questions list.

# Process and constraints
- This is a /ultraplan planning pass: think hard, explore the repo thoroughly, and ask me clarifying questions BEFORE you finalize the PRD.
- Flag every assumption, statistic, or code (NAICS/PSC) you are not fully certain about, and tell me to verify it from the primary source. Do not state guesses as facts.
- Deliverable is the PRD only. Do NOT run live searches, fetch from the sites above, or implement the tool in this run.
- Save the finished PRD to: ~/published-listing-search/Off-Market Search/PRD_OFF_MARKET_SEARCH.md
