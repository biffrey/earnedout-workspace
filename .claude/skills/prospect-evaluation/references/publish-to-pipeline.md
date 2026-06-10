# Publish-to-Pipeline (EarnedOut)

How to publish a completed **single-business** Prospect Evaluation so it lands on the smbsteward.com dashboard and the EarnedOut Master Deal Pipeline Airtable.

This step is **EarnedOut-specific**. It only runs if **all** of the following are true:

- The folder `/Users/biffreybraxton/published-listing-search/output/reports/` exists on this machine
- The user did not opt out (e.g. "don't publish", "just write it locally", "skip the dashboard")
- This run is **single mode** (batch reports stay in the working directory)
- The Airtable MCP tools (`mcp__airtable__*`) are available in this session

If any of those is false, skip this entire reference (Step 9 of SKILL.md) and continue with SKILL.md Step 10 — the valuation-estimate chain offer still applies to unpublished single-mode runs.

### Rescore mode

If the caller signals a **rescore** (the `process-pending-rescores` runner re-evaluating an already-flagged prospect against its updated working folder), this whole flow still runs, with two differences:

- **Step A is skipped** — do not prompt for a Disposition. The row already exists with a Disposition that reflects the latest human decision; reuse it unchanged.
- **Working Folder Path** (Step B/E) is set/refreshed to the folder the runner evaluated, so the link between the row and its source documents stays current.

Everything else is identical to a normal single-mode publish (refresh Lead Score and report path, append to Notes).

> **Order matters:** the Airtable row is found/created (Step B) **before** the HTML is copied into the publish folder (Step D), because the report HTML embeds a deep link to its own Airtable record (Step C). Copying first would publish a report with an unresolved link.

---

## Step A — Ask the user for the disposition

> **Rescore mode:** skip this step entirely. Do not prompt. Leave the existing Disposition untouched and go straight to Step B.

Stop and ask the user to pick the deal's current disposition. Present the Airtable options as a numbered list:

```
What disposition should I assign to <Company>?

  1. Active                  — actively pursuing now
  2. Contacted               — initial outreach made
  3. Maybe Later             — interesting, not now
  4. Revisit for Roll-up     — promising add-on, revisit later
  5. Passed                  — reviewed and decided not to pursue
  6. Dead Link               — opportunity gone
```

**Do not proceed until the user responds.** This is a deliberate gate so the user can decide post-review whether to actually pursue.

If the user picks **Passed** or **Dead Link**, still create the Airtable row — the dashboard filters on disposition, so the prospect is on record but won't pollute active views.

If the user wants to add a new disposition option not in this list, suggest they add it directly in Airtable (Disposition field → "Add option") and then re-run this step.

---

## Step B — Find or create the Airtable row

**Base / table:**

- `baseId`: `appOsvuyy5eK43QTx` (Deal Pipeline Tracker)
- `tableId`: `tblSmNrHROMLm7vOS` (Master Deal Pipeline)

**Check first** whether the prospect is already in the table. Use `mcp__airtable__search_records` with the company name as the query (fuzzy-matches). Inspect the result:

- **No matching record** → create a new one (this section continues).
- **One clearly-matching record** → update it instead (see Step E), then continue to Step C with its record ID.
- **Multiple ambiguous matches** → list them to the user and ask which one is this prospect (or whether to create a new row anyway).

Either way, **capture the record ID (`rec…`)** — Step C needs it.

**Fields to set on a new row** (use field IDs, not names — IDs are stable across renames):

| Field | Field ID | Value |
|---|---|---|
| Business Name | `fldquYtYnHJ1YzUR7` | Full legal name (e.g. "Linguabee LLC") |
| Lead Score | `fld2ipICYNLjaDm39` | Integer score from the report (0–100 or 0–110) |
| Industry Match | `fldyJH0ZsOJD29wEg` | singleSelect — see "Industry Match selection" below |
| Business Address | `fldkVBunWYKdXkgpB` | Full street address if known, else "City, ST" |
| Disposition | `fldw0xk1YBkmP7sBD` | The disposition picked in Step A (singleSelect) |
| Source | `fldiGyXTk6Ybb6J1L` | `"Manual Submission"` (singleSelect) |
| Website | `fldTRaz0PzBYS9ICl` | Primary company URL |
| Prospect Eval Report | `fld9InVXs4RqgtNDo` | `https://smbsteward.com/SMBSSearch001/reports/name-<slug>[-<state>]/<slug>-report.html` — the LIVE URL (behind the SMB Steward password), not a file:// path. All 308 existing rows were normalized to this format on 2026-06-10. |
| Working Folder Path | `fldJCqHDRnpbVPaZa` | Absolute path to the prospect's working folder under `My Drive/Investments/Prospects/…` if one exists (the folder of CIMs/financials this evaluation read). Leave blank if the prospect has no document folder (e.g. an off-market fund sourced purely from web research). |
| Notes | `fldbEqYoyoPNthNoV` | One short paragraph: lead source, report date, anything notable. Example: `"Lead source: Lion People Global (Anonymous Teaser 1322). Report 2026-05-11, score 95/110. ASL interpreting agency in Arvada, CO; active LOI work."` |

(The `name-<slug>[-<state>]` directory naming is defined in Step D — pick the slug now so the report path is correct.)

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

## Step C — Embed the Airtable deep link in the report HTML

Every published report carries a one-click link to its own Airtable row, so the user can update the Disposition while reading the report.

The report template (`templates/single-report.html`) contains this block right after the `<h1>`, with a `{{Airtable Record ID}}` placeholder:

```html
<!-- airtable-deep-link --><div style="margin-top:8px;"><a href="https://airtable.com/appOsvuyy5eK43QTx/tblSmNrHROMLm7vOS/{{Airtable Record ID}}" target="_blank" rel="noopener" style="display:inline-block;font-size:12.5px;font-weight:600;color:var(--accent,#1283da);border:1px solid var(--accent,#1283da);background:transparent;padding:4px 12px;border-radius:999px;text-decoration:none;">Update Disposition in Airtable ↗</a></div><!-- /airtable-deep-link -->
```

In the **working-directory copy** of the report HTML:

- Replace `{{Airtable Record ID}}` with the record ID captured in Step B.
- If the HTML predates the template change and has no `airtable-deep-link` block at all, insert the block above (with the real record ID) immediately after the first closing `</h1>` tag.
- If a block is already present with a different record ID (e.g. a re-publish that matched a different row), replace the record ID in the existing block.

The link format is `https://airtable.com/{baseId}/{tableId}/{recordId}` — it opens the record expanded in Airtable's own UI, where Disposition is a validated single-select. Editing requires being an Airtable collaborator; the link grants nothing by itself.

---

## Step D — Copy the HTML report into the consolidated reports folder

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

Create the directory and copy the report HTML into it (**after** Step C, so the copy already contains the resolved deep link):

```bash
mkdir -p "/Users/biffreybraxton/published-listing-search/output/reports/name-<slug>[-<state>]/"
cp "<slug>-report.html" "/Users/biffreybraxton/published-listing-search/output/reports/name-<slug>[-<state>]/"
```

Leave the `.md` and `.html` originals in the working directory — they remain the working source of truth. Only the `.html` gets published.

When the file lands in `output/reports/`, the macOS `launchd` watcher (`com.smbsteward.sync.watch`) fires within ~30 seconds and uploads it to `https://smbsteward.com/SMBSSearch001/reports/...` via FTPS.

---

## Step E — Updating an existing row

If you found a matching record in Step B, update it instead of creating a duplicate. Use `mcp__airtable__update_records_for_table` with the record's `id`.

Update with care:

- **Lead Score** — always update to this run's score.
- **Prospect Eval Report** — always update to the new path (this run's report supersedes the prior one).
- **Disposition** — do NOT change unless the user explicitly told you to. The disposition on file is more likely to reflect the latest decision than this run's evaluation context. (In **rescore mode** this is mandatory — never touch it.)
- **Working Folder Path** (`fldJCqHDRnpbVPaZa`) — set/refresh to the absolute path of the working folder this evaluation read, if known. In a rescore this is the folder the runner handed you; on a manual re-publish, fill it if it's currently empty.
- **Notes** — APPEND, don't replace. Read the current Notes value first, then write back: `<existing notes>\n\nRe-evaluated YYYY-MM-DD: score now XX/100. <One-line delta from prior eval.>`
- **Business Name / Address / Website / Industry Match** — update only if the existing value is empty OR clearly wrong. Otherwise leave alone.

Then continue with Step C (embed the deep link with this record's ID) and Step D (copy).

---

## Step F — Confirm to the user

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
