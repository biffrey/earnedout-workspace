---
name: Process Pending Rescores
description: Re-evaluates EarnedOut prospects that have been flagged for rescore. Use when the user says "process pending rescores", "run pending rescores", "rescore the flagged prospects", "process the rescore queue", or asks to refresh the evaluations of prospects whose working folders got new documents. Reads the Master Deal Pipeline Airtable for rows where Needs Rescore is checked, locates each prospect's working folder, re-runs the Prospect Evaluation skill in rescore mode, refreshes the dashboard row, and clears the flag.
---

# Process Pending Rescores

The second half of the rescore loop. A file watcher already flips the **Needs Rescore** checkbox on a Master Deal Pipeline row whenever a new CIM / financial / transcript lands in a prospect's working folder. This skill drains that queue: for each flagged prospect it re-runs the **Prospect Evaluation** skill against the prospect's current folder contents, refreshes the score / report / notes on the dashboard, and clears the flag.

Runs **on demand** — the user (or Trisha) triggers it in Cowork by saying "process pending rescores". It is sequential and capped, so a stray backlog can't run up a surprise bill.

## Key identifiers

| Thing | Value |
|---|---|
| Airtable base | `appOsvuyy5eK43QTx` |
| Table (Master Deal Pipeline) | `tblSmNrHROMLm7vOS` |
| Needs Rescore (checkbox) | `fldqJSo0N890SxtTP` |
| Business Name | `fldquYtYnHJ1YzUR7` |
| Working Folder Path | `fldJCqHDRnpbVPaZa` |
| Lead Score | `fld2ipICYNLjaDm39` |
| Prospect Eval Report | `fld9InVXs4RqgtNDo` |
| Disposition | `fldw0xk1YBkmP7sBD` |
| Prospects root | `/Users/biffreybraxton/Library/CloudStorage/GoogleDrive-bbraxton@applied-dev.com/My Drive/Investments/Prospects/` |
| Runner log | `~/Library/Logs/smbs-rescore-runner.log` |
| Folder-resolver helper | this skill's `resolve-working-folder.py` (beside this file) |

## Caps (do not exceed without the user explicitly asking)

- **Max 5 prospects per run.** If more than 5 are flagged, process the 5 highest Lead Score first and tell the user how many remain.
- **Sequential, one at a time.** Never run evaluations in parallel — it muddies the log and risks rate-limit collisions.
- If the user says "do all of them" or "no cap this time", honor that for the single run only.

## Procedure

### 1. Read the queue
Use `mcp__airtable__list_records_for_table` on the base/table above, filtering `fldqJSo0N890SxtTP = true`. Request fields: Business Name, Working Folder Path, Lead Score, Disposition, Prospect Eval Report. Sort by Lead Score descending.

- If **zero** rows are flagged, say "Nothing in the rescore queue." and stop.
- Otherwise list what you found (names + current scores), note how many you'll process under the cap, then proceed one at a time.

### 2. For each flagged prospect — resolve its working folder
1. If **Working Folder Path** is set, use it. Confirm the directory exists and contains at least one `.pdf/.docx/.xlsx/.pptx/.doc/.xls/.ppt` file.
2. If the field is **blank** (or the path no longer exists), run the resolver helper to find it by Business Name:
   ```bash
   python3 "<this skill dir>/resolve-working-folder.py" "<Business Name>"
   ```
   - It prints one absolute path on a clean single match, prints nothing on no match, or prints multiple candidates (one per line) on ambiguity.
   - **Clean single match** → use it, and note that you'll write it back to Working Folder Path during publish.
   - **No match or ambiguous** → do **not** guess. Log `SKIP — folder unresolved`, leave the flag set, and move to the next prospect. Surface these to the user at the end so they can set Working Folder Path by hand.

### 3. Re-evaluate (rescore mode)
- `cd` into the resolved working folder (so report outputs land beside the source docs, matching a normal single-mode run).
- Invoke the **Prospect Evaluation** skill on that folder, explicitly telling it: *"This is a rescore (rescore mode). Single mode. Read every document in this folder and re-evaluate. At Step 9, do NOT prompt for a Disposition — preserve the existing one — and refresh the Working Folder Path to `<resolved path>`."*
- Let the skill do its normal work, including its Step 9 publish (copy HTML to `output/reports/`, update the Airtable row's Lead Score / Prospect Eval Report / Working Folder Path, append to Notes). Because it's rescore mode, Step 9 will **not** ask for a disposition.

### 4. Clear the flag
Only after the evaluation **and** its Step 9 publish succeed, set `fldqJSo0N890SxtTP = false` on the row with `mcp__airtable__update_records_for_table`.

### 5. Log it
Append one line per prospect to `~/Library/Logs/smbs-rescore-runner.log` (create the file/dir if missing). Format:
```
YYYY-MM-DD HH:MM:SS  START  <recId>  "<Business Name>"  folder=<path>
YYYY-MM-DD HH:MM:SS  DONE   <recId>  "<Business Name>"  score=<new> (prev <old>)  flag cleared
YYYY-MM-DD HH:MM:SS  FAIL   <recId>  "<Business Name>"  reason=<short reason>  flag left set
YYYY-MM-DD HH:MM:SS  SKIP   <recId>  "<Business Name>"  reason=folder unresolved  flag left set
```

### 6. Failure handling
If anything fails for a prospect (folder unreadable, web/LLM error, Airtable write error): **leave `Needs Rescore = true`** so the next run retries it, write a `FAIL` log line with the reason, and continue to the next prospect. Never abort the whole run because one prospect failed.

### 7. Final summary
After the loop (or when the cap is hit), print a table to the user: prospect, old score → new score, status (done / failed / skipped / not-reached-due-to-cap), report link. State how many remain flagged, if any.

## Notes
- This skill does not schedule itself. Nightly automation (decision 23.5c) is a separate step layered on top once this manual loop is proven.
- It never changes a Disposition. Post-review "no-go" decisions a human made stay intact across rescores.
- It is safe to run repeatedly — already-cleared rows simply won't appear in the queue.
