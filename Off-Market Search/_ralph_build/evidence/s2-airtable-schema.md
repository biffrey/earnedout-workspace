# s2 — Airtable Schema Change (evidence)

Base `appOsvuyy5eK43QTx` / table `tblSmNrHROMLm7vOS` ("Master Deal Pipeline").
Captured 2026-05-22 (build-loop iter 4, s2 IMPLEMENT).

## Fields created via Airtable MCP `create_field` — DONE

All five §8.4 fields were created live and confirmed by the tool response:

| Field name | Type | New field ID |
|---|---|---|
| `Gov Entity ID` | singleLineText | `fld7Ook8ZoLAjwFTe` |
| `SBIC License #` | singleLineText | `fldogicjVNMCBuyJI` |
| `SBIC License Status` | singleSelect (Good Standing / Under Review / Surrendered / Revoked / Unknown) | `fldscFvXPUFYbSg3F` |
| `Gov Data Source` | multipleSelects (USAspending / SAM.gov / SAM.gov Contract Awards / SBA SBIC / SBS / GSA eLibrary / State / RID) | `fldM7KoR2gtfvBVWN` |
| `Federal Award History $` | currency ($, precision 0) | `fldZXrqqoBkIdDWJN` |

Note on `Gov Data Source` choices: the PRD §8.4 list named `FPDS-NG` and `DSBS`.
Per the §13 resolution doc (which overrides the PRD), FPDS-NG is decommissioned
and DSBS is renamed "Small Business Search (SBS)". The choice set above reflects
that: `SAM.gov Contract Awards` replaces `FPDS-NG`, `SBS` replaces `DSBS`, and
`RID` (a retained Class-1 source) is added. Multi-select choices auto-grow on
write, so this set is a starting point, not a hard limit.

## `Source` single-select values — NOT DONE (operator action required)

Live schema of the `Source` field (`fldiGyXTk6Ybb6J1L`) at capture time:

```
choices: ["Overnight Search", "Manual Submission"]
```

The two required off-market values — `Off-Market — ASL Bolt-on` and
`Off-Market — SBIC` (PRD §8.3) — are **absent**. The Airtable MCP `update_field`
tool cannot add `choices` to an existing single-select (its `options` schema
exposes only `formula`). Adding these two values requires an operator action in
the Airtable UI. This keeps blocker **B4** partially open and **s2 blocked**.

## Preflight check — DONE

`.claude/skills/off-market-search/references/airtable_schema_preflight.md` was
written: the fail-loud Step-1 check that verifies all six fields + both `Source`
values + the `SBIC License Status` options before any record write, and halts
with an operator message (never auto-creating) on any miss.
