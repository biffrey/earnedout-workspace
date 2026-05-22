# s7 — Airtable Write & Dashboard Badge (evidence)

Base `appOsvuyy5eK43QTx` / table `tblSmNrHROMLm7vOS` ("Master Deal Pipeline").
Captured 2026-05-22 (build-loop iter 34, s7 re-IMPLEMENT after B4 resolved).

s7 was built at iter 20 (`references/airtable_write.md` + the dashboard badge)
and was verified `verified`-era before the operator reset it to `not_started`
when B4 cleared — so the loop re-runs it against the now-complete live schema.
This re-IMPLEMENT confirms the deliverable is intact and consistent with the
schema; no schema-dependent value needed correcting.

## Deliverable 1 — `references/airtable_write.md` — DONE

The field-by-field write procedure (PRD §8). Schema-dependent field IDs
cross-checked against `evidence/s2-airtable-schema.md` (re-confirmed live in
iter 32) — **all match byte-for-byte**:

| Field (§3.3 of `airtable_write.md`) | ID cited | `s2-airtable-schema.md` | Match |
|---|---|---|---|
| Gov Entity ID | `fld7Ook8ZoLAjwFTe` | `fld7Ook8ZoLAjwFTe` | ✓ |
| SBIC License # | `fldogicjVNMCBuyJI` | `fldogicjVNMCBuyJI` | ✓ |
| SBIC License Status | `fldscFvXPUFYbSg3F` | `fldscFvXPUFYbSg3F` | ✓ |
| Gov Data Source | `fldM7KoR2gtfvBVWN` | `fldM7KoR2gtfvBVWN` | ✓ |
| Federal Award History $ | `fldZXrqqoBkIdDWJN` | `fldZXrqqoBkIdDWJN` | ✓ |

`Source` field ID `fldiGyXTk6Ybb6J1L` (§3.2) matches the live schema; the two
off-market values it writes — `Off-Market — ASL Bolt-on` (Class 1) and
`Off-Market — SBIC` (Class 2) — both exist as live `Source` choices
(`selezt48WJR6jPv2m` / `seltqCid0e9t6aijI`) since B4 was resolved. The §2
preconditions ("never write blind") are forward-correct: the Step-1 preflight
now passes (the values exist), so s7 writes against a confirmed schema and never
auto-creates. No stale "B4 open / blocked" prose is present in the file.

## Deliverable 2 — dashboard "Off-Market" badge — DONE

`templates/daily-dashboard.html`:
- `.chip.offmarket` style block — line 154–155 (green, `--pass` palette).
- Data-contract comment extended with the two off-market `source` values —
  lines 42–43.
- Render condition `{% if lead.source.startswith('Off-Market') %}<span
  class="chip offmarket">OFF-MARKET</span>{% endif %}` present in all three
  row sections — lines 242 (New Finds), 288 (Running Queue), 330 (Revisit
  Bucket). Additive: `Overnight Search` / `Manual Submission` rows render
  unchanged; no `Source` column added.

## Summary

Both s7 deliverables exist and are consistent with the complete live schema.
No code change was required at iter 34 — the re-IMPLEMENT was a confirmation
pass (mirrors the iter-32 s2 re-IMPLEMENT).

## iter 36 SELF-TEST — live write attempt — C5 FAIL (BLOCKING-s7-1)

With B4 resolved, the iter-36 SELF-TEST drove the §3 write procedure for real
against base `appOsvuyy5eK43QTx` / table `tblSmNrHROMLm7vOS`, attempting a live
`create_records_for_table` for the Class-2 SBIC lead R2 (1st Source Capital
Corporation). Preflight, dedup, and the badge checks passed; the live write was
**rejected atomically**:

```
HTTP 422: Insufficient permissions to create new select option ""SBA SBIC directory""
```

Root cause: `airtable_write.md` §3.1 maps `Lead Source` (`fldI1h3qmNI6vc5rr`)
to a free-text gov-source string, but the field is a **singleSelect** of 14
broker-platform options (live `get_table_schema`: `Direct Outreach`, `Broker`,
`Referral`, `Conference`, `BizBuySell`, `BizQuest`, `Axial`, `Grata`,
`DealStream`, `Trade-A-Plane`, `LinkedIn`, `Other Platform`, `General Web`,
`BusinessBroker.net`). A post-attempt `search_records` confirmed **zero rows
written**. Logged as **BLOCKING-s7-1**; s7 → `not_started` for an IMPLEMENT
fix of the §3.1 `Lead Source` mapping. See `TEST_LOG.md` iter 36 and
`FINDINGS.md` BLOCKING-s7-1.
