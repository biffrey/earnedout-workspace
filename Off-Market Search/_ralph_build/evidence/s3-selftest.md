# s3 Source Adapters — SELF-TEST evidence (iter 6, 2026-05-22)

Exercising the s3 adapters against live endpoints and recorded fixtures, and
showing the normalized `RawRecord` each produces (per `references/source_adapters.md`).

## Live endpoint checks

- **S1 — USAspending.gov.** `POST /api/v2/search/spending_by_award/` with
  `naics_codes:["541930"]`, contract award types, trailing-5-FY window →
  HTTP 200, 5 result rows, `hasNext: true`. Real recipients incl. THE MISSION
  ESSENTIAL GROUP LLC, WORLDWIDE LANGUAGE RESOURCES LLC, SOS INTERNATIONAL LLC.
  Recorded to `s3-fixtures/S1.json`.
- **Code validation.** `autocomplete/naics` → `541930` "Translation and
  Interpretation Services", `year_retired: null` (active). `autocomplete/psc` →
  `R608` "SUPPORT- ADMINISTRATIVE: TRANSLATION AND INTERPRETING". Both verified
  codes resolve live.
- **S4 — SBA SBIC directory.** `GET sba.gov/export/contacts/sbic` → CSV, 13
  columns, real licensee rows. Recorded to `s3-fixtures/S4.json`.

## Normalized RawRecord output (mapping exercised)

### S1 (live) — one grouped recipient
```
{ source_id:"S1", target_class:1,
  legal_name:"THE MISSION ESSENTIAL GROUP, LLC", dba_name:null,
  uei:null,            // not in spending_by_award fields — see IMPROVE-s3-1
  cage_code:null, duns:null, sbic_license_no:null, address:null,
  naics:["541930"], psc:[], award_total:1109510733.69, award_count:1,
  socioeconomic_flags:[], poc:null, website:null,
  keyword_hits:[], keyword_tier:null,
  source_url:"https://www.usaspending.gov/award/CONT_AWD_0001_9700_W911W411D0007_9700",
  raw_pulled_at:"2026-05-22", source_payload:{...} }
```

### S4 (live) — one SBIC management entity
```
{ source_id:"S4", target_class:2,
  legal_name:"1st Source Capital Corporation",   // CSV "Manager" column — see NIT-s3-1
  uei:null, sbic_license_no:null,
  address:{city:"South Bend", state:"IN"},
  award_total:null, poc:{name:"Ryan Fenstermaker", email:"fenstermakerr@1stsource.com",
  phone:"574-235-2180"},
  source_payload:{fund_name:"1st Source Capital Corporation", vintage:1983,
  fund_size:2850000, strategy:"Direct Lending", style:"Venture",
  making_new_investments:"No",
  govt_fact:"Acquiring a licensed SBIC requires SBA prior approval of the change of control."},
  source_url:"https://www.sba.gov/document/support-sbic-directory" }
```

### S2 (fixture mode) — SAM.gov Entity Management
`s3-fixtures/S2.json` mapped → `legal_name:"EXAMPLE INTERPRETING FIXTURE LLC"`,
`uei:"ZZTEST00FIX1"`, `cage_code:"0ZZ11"`, `address:{...VA...}`,
`naics:["541930"]`, `poc:{name:"Pat Sample", title:"Owner"}`,
`meta.status:"blocked", blocker_id:"B3", notes:"fixture"`. Mapping runs clean.

### S3 (fixture mode) — SAM.gov Contract Awards
`s3-fixtures/S3.json` mapped → `legal_name:"EXAMPLE INTERPRETING FIXTURE LLC"`,
`uei:"ZZTEST00FIX1"`, `naics:["541930"]`, `psc:["R608"]`, `award_total:480000`,
`socioeconomic_flags:["Small Business"]`, `meta.status:"blocked",
blocker_id:"B3", notes:"fixture"`. Mapping runs clean.

### S8 (B1) — priority-state portals
Returns `records:[]`, `meta.status:"blocked", blocker_id:"B1"` — shell only,
does not halt the run. Correct by design.

## Findings carried to the critic
- **NIT-s3-1** — S4 adapter prose says map the `"Managed by"` column; the live
  CSV column is actually named `Manager`. Mapping intent is correct; the column
  label cited in `source_adapters.md` S4 should match the live header.
- **IMPROVE-s3-1** — S1: `uei` (the primary s4 resolution key) is not returned
  by `spending_by_award`. The adapter must add a recipient-detail follow-up
  (`/api/v2/recipient/{recipient_id}/`) or request UEI in the `fields` list to
  populate `uei`; otherwise S1 records resolve only on name+address.
