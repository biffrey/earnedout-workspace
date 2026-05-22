# s3 Source-Adapter Fixtures

Recorded sample payloads used by `references/source_adapters.md` **fixture mode**
(adapter section "Fixture mode"). An adapter in fixture mode reads the file here
named `<source_id>.json` instead of calling the network, maps it through the
**identical** normalization, and sets `meta.notes: "fixture"`.

Purpose: let s3 SELF-TEST and the downstream stages (s4–s10) exercise the full
pipeline without depending on a blocked credential (B3) or an unset operator
decision (B1).

| File | Provenance |
|---|---|
| `S1.json` | **Live recording** — actual `POST /api/v2/search/spending_by_award/` response from `api.usaspending.gov`, captured 2026-05-22 during s3 SELF-TEST. Real award rows. |
| `S4.json` | **Live recording** — actual rows from the SBA SBIC directory CSV (`sba.gov/export/contacts/sbic`), captured 2026-05-22. Real licensees. |
| `S2.json` | **Structural fixture** — shape of a SAM.gov Entity Management API entity record, per the public API field schema. Identifiers are placeholder/illustrative, NOT a real entity. Used only to prove the S2 normalization mapping; must never be written to the tracker as a discovered prospect outside a test context. |
| `S3.json` | **Structural fixture** — shape of a SAM.gov Contract Awards API award record. Same caveat as `S2.json`. |

Live-recorded fixtures (S1, S4) carry real data and may flow downstream.
Structural fixtures (S2, S3) exist only to test the mapping; the s10 dry run
flags any record whose sole provenance is a structural fixture.
