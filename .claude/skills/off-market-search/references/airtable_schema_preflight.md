# Airtable Schema Preflight — Off-Market Search

The `off-market-search` skill runs this **fail-loud** check at Step 1, before any
record write. Its job: prove the Master Deal Pipeline table can hold an
off-market record. If anything required is missing, the skill **stops
immediately** with a clear operator message — it never silently creates a field
or a `Source` option, and never writes a partial record.

**Target:** base `appOsvuyy5eK43QTx`, table `tblSmNrHROMLm7vOS`
("Master Deal Pipeline").

## Procedure

1. Call `list_tables_for_base(appOsvuyy5eK43QTx)` and locate table
   `tblSmNrHROMLm7vOS`.
2. **Required fields** — confirm each exists with the expected type:

   | Field name | Type | Field ID (created 2026-05-22) |
   |---|---|---|
   | `Gov Entity ID` | `singleLineText` | `fld7Ook8ZoLAjwFTe` |
   | `SBIC License #` | `singleLineText` | `fldogicjVNMCBuyJI` |
   | `SBIC License Status` | `singleSelect` | `fldscFvXPUFYbSg3F` |
   | `Gov Data Source` | `multipleSelects` | `fldM7KoR2gtfvBVWN` |
   | `Federal Award History $` | `currency` | `fldZXrqqoBkIdDWJN` |
   | `Source` | `singleSelect` | `fldiGyXTk6Ybb6J1L` |

   Match on **name + type**. A field present under a different type is a
   failure, not a pass.

3. **Required `Source` options** — call
   `get_table_schema(appOsvuyy5eK43QTx, [{tableId: tblSmNrHROMLm7vOS,
   fieldIds: [fldiGyXTk6Ybb6J1L]}])` and confirm the `Source` single-select
   `choices` include **both**:
   - `Off-Market — ASL Bolt-on`  (Class 1)
   - `Off-Market — SBIC`  (Class 2)

   The em dash (`—`, U+2014) and spacing must match exactly.

4. **`SBIC License Status` options** — confirm the choices include
   `Good Standing`, `Under Review`, `Surrendered`, `Revoked`, `Unknown`.

## On failure — stop, do not write

If any field, any `Source` option, or any `SBIC License Status` option is
missing, the skill **halts** and prints, naming exactly what is missing:

```
OFF-MARKET SCHEMA PREFLIGHT FAILED — aborting before any Airtable write.
Missing: <list of missing fields / Source options>.
Fix (operator action — the Airtable MCP cannot add single-select options):
  Open base appOsvuyy5eK43QTx > table "Master Deal Pipeline" and add the
  missing item(s):
    - Source field: add the single-select values
        "Off-Market — ASL Bolt-on" and "Off-Market — SBIC"
    - any missing §8.4 field per OFFMARKET_BUILD_PLAN.md s2
Re-run the skill once the schema matches. The skill will NOT create these
itself — fail-loud is intentional (PRD §8.3, OFFMARKET_BUILD_PLAN constraints).
```

## Schema status & why the preflight stays fail-loud

As of 2026-05-22 the live schema is **complete** — a `get_table_schema` read of
`tblSmNrHROMLm7vOS` confirms all five §8.4 fields plus the two off-market
`Source` values (`Off-Market — ASL Bolt-on`, `Off-Market — SBIC`). The five
§8.4 fields were created via the Airtable MCP `create_field`; the two `Source`
single-select values were added by the operator in the Airtable UI, because
`update_field` cannot add `choices` to an **existing** single-select (this was
blocker **B4**, now RESOLVED — see `Off-Market Search/_ralph_build/BLOCKERS.md`).

The preflight nonetheless runs on **every** invocation and stays fail-loud: it
guards against a later schema edit, a renamed/deleted choice, or a run against a
different base, and it never auto-creates a field or option. A clean schema
today is not a substitute for the check.
