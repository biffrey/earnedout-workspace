# Publish-to-Pipeline (EarnedOut)

How to publish a completed **single-business** Prospect Evaluation so it lands on the smbsteward.com dashboard and the EarnedOut Master Deal Pipeline Airtable.

This step is **EarnedOut-specific**. It only runs if **all** of the following are true:

- The folder `/Users/biffreybraxton/published-listing-search/output/reports/` exists on this machine
- The user did not opt out (e.g. "don't publish", "just write it locally", "skip the dashboard")
- This run is **single mode** (batch reports stay in the working directory)
- The Airtable MCP tools (`mcp__airtable__*`) are available in this session

If any of those is false, skip this entire reference and stop after Step 8 of SKILL.md.

### Rescore mode

If the caller signals a **rescore** (the `process-pending-rescores` runner re-evaluating an already-flagged prospect against its updated working folder), this whole flow still runs, with two differences:

- **Step B is skipped** — do not prompt for a Disposition. The row already exists with a Disposition that reflects the latest human decision; reuse it unchanged.
- **Working Folder Path** (Step C/D) is set/refreshed to the folder the runner evaluated, so the link between the row and its source documents stays current.

Everything else is identical to a normal single-mode publish (refresh Lead Score and report path, append to Notes).

---

## Step A — Copy the HTML report into the consolidated reports folder

Pick a directory name from the company:

- **Slug** — lowercase, hyphens, drop legal suffixes (Inc., LLC, Corp., etc.). Examples:
  - `Linguabee LLC` → `linguabee`
  - `Ridgeline Capital Management, LLC` → `ridgeline-capital-management`
  - `Silverfox Inc.` → `silverfox`
- **State suffix** — the 2-letter US state abbreviation where the company is HQ'd, lowercase. **Omit if unknown.**
  - `Linguabee` HQ in Arvada, CO → `co`
  - `Flying Zebra` (HQ unknown) → no suffix

Target directory:

```
/Users/biffreybraxton/published-listing-search/output/reports/name-<slug>[-<state>]/
```

Worked examples:

| Company | HQ | Target directory |
|---|---|---|
| Linguabee LLC | Arvada, CO | `name-linguabee-co/` |
| Silverfox Inc. | Houston, TX | `name-silverfox-tx/` |
| Flying Zebra LLC | unknown | `name-flying-zebra/` |

Create the directory and copy the report HTML into it:

```bash
mkdir -p "/Users/biffreybraxton/published-listing-search/output/reports/name-<slug>[-<state>]/"
cp "<slug>-report.html" "/Users/biffreybraxton/published-listing-search/output/reports/name-<slug>[-<state>]/"
```

Leave the `.md` and `.html` originals in the working directory — they remain the working source of truth. Only the `.html` gets published.

When the file lands in `output/reports/`, the macOS `launchd` watcher (`com.smbsteward.sync.watch`) fires within ~30 seconds and uploads it to `https://smbsteward.com/SMBSSearch001/reports/...` via FTPS.

---

## Step B — Ask the user for the disposition

> **Rescore mode:** skip this step entirely. Do not prompt. Leave the existing Disposition untouched and go straight to Step C → Step D (update path).

Stop and ask the user to pick the deal's current disposition. Present the Airtable options as a numbered list:

```
What disposition should I assign to <Company>?

  1. Active                  — actively pursuing now
  2. Contacted               — initial outreach made
  3. Maybe Later             — interesting, not now
  4. Revisit for Roll-up     — promising add-on, revisit later
  5. Passed                  — reviewed and decided not to pursue
  6. Dead Link               — opportunity gone

Pick a number or type the name.
```

**Do not proceed until the user responds.** This is a deliberate gate so the user can decide post-review whether to actually pursue.

If the user picks **Passed** or **Dead Link**, still create the Airtable row — the dashboard filters on disposition, so the prospect is on record but won't pollute active views.

If the user wants to add a new disposition option not in this list, suggest they add it directly in Airtable (Disposition field → "Add option") and then re-run this step.

---

## Step C — Find or create the Airtable row

**Base / table:**

- `baseId`: `appOsvuyy5eK43QTx` (Deal Pipeline Tracker)
- `tableId`: `tblSmNrHROMLm7vOS` (Master Deal Pipeline)

**Check first** whether the prospect is already in the table. Use `mcp__airtable__search_records` with the company name as the query (fuzzy-matches). Inspect the result:

- **No matching record** → create a new one (this section continues).
- **One clearly-matching record** → update it (jump to Step D).
- **Multiple ambiguous matches** → list them to the user and ask which one is this prospect (or whether to create a new row anyway).

**Fields to set on a new row** (use field IDs, not names — IDs are stable across renames):

| Field | Field ID | Value |
|---|---|---|
| Business Name | `fldquYtYnHJ1YzUR7` | Full legal name (e.g. "Linguabee LLC") |
| Lead Score | `fld2ipICYNLjaDm39` | Integer score from the report (0–100 or 0–110) |
| Industry Match | `fldyJH0ZsOJD29wEg` | singleSelect — see "Industry Match selection" below |
| Business Address | `fldkVBunWYKdXkgpB` | Full street address if known, else "City, ST" |
| Disposition | `fldw0xk1YBkmP7sBD` | The disposition picked in Step B (singleSelect) |
| Source | `fldiGyXTk6Ybb6J1L` | `"Manual Submission"` (singleSelect) |
| Website | `fldTRaz0PzBYS9ICl` | Primary company URL |
| Prospect Eval Report | `fld9InVXs4RqgtNDo` | `file:///Users/biffreybraxton/published-listing-search/output/reports/name-<slug>[-<state>]/<slug>-report.html` |
| Working Folder Path | `fldJCqHDRnpbVPaZa` | Absolute path to the prospect's working folder under `My Drive/Investments/Prospects/…` if one exists (the folder of CIMs/financials this evaluation read). Leave blank if the prospect has no document folder (e.g. an off-market fund sourced purely from web research). |
| Notes | `fldbEqYoyoPNthNoV` | One short paragraph: lead source, report date, anything notable. Example: `"Lead source: Lion People Global (Anonymous Teaser 1322). Report 2026-05-11, score 95/110. ASL interpreting agency in Arvada, CO; active LOI work."` |

**Industry Match selection.** This is a singleSelect with a finite list of options. Before writing, call `mcp__airtable__get_table_schema` for `fldyJH0ZsOJD29wEg` to see the current choices. Pick the closest fit. Common existing options:

- `Sign Language / Translation` — ASL, CART, foreign-language interpretation
- `Part 135 Aviation` — on-demand jet charter, air taxi
- `Part 145 Aviation` — aircraft repair stations, MRO
- `Trash & Waste` — commercial/construction waste, dumpster, debris
- `HVAC`, `Residential HVAC`, `Commercial HVAC`
- `Plumbing`, `Roofing`, `Garage Door`
- `Kitchen Exhaust`, `Kitchen Exhaust Cleaning`
- `Water Damage/Restoration`
- `Law Firm (ABS)` — AZ/PR/UT/MD/DC/VA only
- `Aerospace Support` — defense, A&D, supplier
- `GovCon`
- `SBIC` — only for SBIC fund management evaluations
- `Other` — when nothing else fits cleanly

If nothing fits, use `Other` rather than inventing a new option. Adding new singleSelect options should be a deliberate decision the user makes in Airtable directly.

Create the row with `mcp__airtable__create_records_for_table`. Pass the field IDs above. For singleSelect fields, pass the option name as a plain string (e.g. `"Active"`, not the option object).

---

## Step D — Updating an existing row

If you found a matching record in Step C, update it instead of creating a duplicate. Use `mcp__airtable__update_records_for_table` with the record's `id`.

Update with care:

- **Lead Score** — always update to this run's score.
- **Prospect Eval Report** — always update to the new path (this run's report supersedes the prior one).
- **Disposition** — do NOT change unless the user explicitly told you to. The disposition on file is more likely to reflect the latest decision than this run's evaluation context. (In **rescore mode** this is mandatory — never touch it.)
- **Working Folder Path** (`fldJCqHDRnpbVPaZa`) — set/refresh to the absolute path of the working folder this evaluation read, if known. In a rescore this is the folder the runner handed you; on a manual re-publish, fill it if it's currently empty.
- **Notes** — APPEND, don't replace. Read the current Notes value first, then write back: `<existing notes>\n\nRe-evaluated YYYY-MM-DD: score now XX/100. <One-line delta from prior eval.>`
- **Business Name / Address / Website / Industry Match** — update only if the existing value is empty OR clearly wrong. Otherwise leave alone.

---

## Step E — Confirm to the user

After the Airtable write succeeds, print a short summary:

```
✅ Published <Company> to the pipeline.

Airtable row:    rec.................  (created | updated)
Disposition:     <chosen disposition>
Score:           XX/100  (or XX/110)
Report file:     /Users/.../output/reports/name-<slug>[-<state>]/<slug>-report.html
Dashboard URL:   https://smbsteward.com/SMBSSearch001/reports/name-<slug>[-<state>]/<slug>-report.html
                  (live within ~30 seconds, behind the SMB Steward password)

The new row will appear on the live dashboard at https://smbsteward.com/SMBSSearch001/
on the next page load.
```

If the publish step fails partway (e.g. the file copy works but the Airtable write errors), say so loudly and tell the user the exact state so they can fix it manually.
