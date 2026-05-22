# s2 — Airtable Schema Change (evidence)

Base `appOsvuyy5eK43QTx` / table `tblSmNrHROMLm7vOS` ("Master Deal Pipeline").
Originally captured 2026-05-22 (build-loop iter 4, s2 IMPLEMENT); **re-confirmed
against the live schema 2026-05-22 (iter 32, s2 re-IMPLEMENT after B4 resolved).**

## Fields created via Airtable MCP `create_field` — DONE

All five §8.4 fields were created live and re-confirmed by a live
`get_table_schema` read this iteration:

| Field name | Type | Field ID |
|---|---|---|
| `Gov Entity ID` | singleLineText | `fld7Ook8ZoLAjwFTe` |
| `SBIC License #` | singleLineText | `fldogicjVNMCBuyJI` |
| `SBIC License Status` | singleSelect (Good Standing / Under Review / Surrendered / Revoked / Unknown) | `fldscFvXPUFYbSg3F` |
| `Gov Data Source` | multipleSelects (USAspending / SAM.gov / SAM.gov Contract Awards / SBA SBIC / SBS / GSA eLibrary / State / RID) | `fldM7KoR2gtfvBVWN` |
| `Federal Award History $` | currency ($, precision 0) | `fldZXrqqoBkIdDWJN` |

Live read confirms `SBIC License Status` choice IDs `selmeIWvIAUqVwV9h`
(Good Standing), `selJ98t6VBkefHlqW` (Under Review), `seluC5rptztaE1dN8`
(Surrendered), `selZN2rJBlq9dNfn8` (Revoked), `selCZXysymLzV1plJ` (Unknown);
`Gov Data Source` carries all eight choices; `Federal Award History $` is
`currency`, symbol `$`, precision `0`.

Note on `Gov Data Source` choices: the PRD §8.4 list named `FPDS-NG` and `DSBS`.
Per the §13 resolution doc (which overrides the PRD), FPDS-NG is decommissioned
and DSBS is renamed "Small Business Search (SBS)". The choice set above reflects
that: `SAM.gov Contract Awards` replaces `FPDS-NG`, `SBS` replaces `DSBS`, and
`RID` (a retained Class-1 source) is added. Multi-select choices auto-grow on
write, so this set is a starting point, not a hard limit.

## `Source` single-select values — DONE (B4 resolved)

Live schema of the `Source` field (`fldiGyXTk6Ybb6J1L`), read this iteration:

```
choices:
  selyLFV5Ijdy2Pw3C  "Overnight Search"
  selIVfP3310iw6Nmn  "Manual Submission"
  selezt48WJR6jPv2m  "Off-Market — ASL Bolt-on"
  seltqCid0e9t6aijI  "Off-Market — SBIC"
```

Both required off-market values (PRD §8.3) are present, verified byte-for-byte
against `OFFMARKET_BUILD_PLAN.md` — em dash `—` (U+2014), single spaces around
it, exact casing. They were added by the operator in the Airtable UI (the
Airtable MCP `update_field` cannot add `choices` to an existing single-select).
Blocker **B4 is RESOLVED**; s2 is no longer blocked.

## Preflight check — DONE

`.claude/skills/off-market-search/references/airtable_schema_preflight.md` —
the fail-loud Step-1 check that verifies all six fields + both `Source` values +
the `SBIC License Status` options before any record write, halting with an
operator message (never auto-creating) on any miss. Its closing prose was
updated this iteration to record B4 as resolved and to state the preflight
still runs every invocation as a guard against later schema drift.

## Summary

All s2 deliverables exist in the live schema with the correct types and
choices, and the fail-loud preflight is in place. s2 is complete pending
SELF-TEST and VERIFY.
