# s8 — Off-Market Outreach Drafting

The procedure the `off-market-search` skill runs at **Step 7 — Draft
outreach**. It turns each off-market lead written by s7 into a
proprietary-approach outreach **draft** — and never sends anything.

> Built by build-loop stage **s8**. Canonical "what":
> `OFFMARKET_BUILD_PLAN.md` s8. Templates: `config/offmarket_outreach_template.md`.

---

## 1. Stage I/O

**Input** — the leads s7 just wrote to `tblSmNrHROMLm7vOS` this run. Each
carries (from the s6 `ScoredLead` and s7 write):

- `target_class` (1 or 2) and `source` (`Off-Market — ASL Bolt-on` /
  `Off-Market — SBIC`)
- `business_name`, `location` (city + state, may be `null`)
- `contact` — owner / SBIC GP principal: `{ name, title, email }`, any field
  may be `null` (s5 marks unknowns "needs follow-up")
- `tracker_record_id` — the Airtable row id to append `Notes` to
- the enrichment gaps and any verified specific detail from the `LeadPacket`

**Output** — for each lead with a direct contact: one outreach **draft**,
stored in two places (§4). For each lead **without** a direct contact: no
draft, a logged skip. Nothing is ever sent.

This step runs for both newly-created and `existing`-updated off-market rows.
On-market rows are not touched here — they were already handled by
`overnight-search` Step 8 with the broker templates.

---

## 2. Procedure

For each off-market lead from s7, in order:

1. **Contact gate.** If the lead has **no** direct contact — neither a
   `contact.name` nor a `contact.email` — **do not draft**. Record in the run
   log: `outreach: skipped — no direct contact (needs follow-up: contact
   discovery)`. Move to the next lead. A missing contact is never fabricated.

2. **Disposition gate.** s7 writes off-market rows as `Disposition = Active`,
   so they are eligible. If a re-run encounters an off-market row whose
   disposition has since moved to `Revisit for Roll-up`, defer outreach
   exactly as the on-market rule does — no draft until the disposition
   changes. Any other disposition (`Contacted`, `Passed`, `Dead Link`, …)
   also gets no fresh draft.

3. **Select the template** from `config/offmarket_outreach_template.md` by
   target class:
   - Class 1 → **Template OM-1** (Owner Approach).
   - Class 2 → **Template OM-2** (SBIC GP Principal Approach).

4. **Select the subject variant.** Alternate per drafted off-market lead in
   this run — 1st drafted lead → Variant 1, 2nd → Variant 2, 3rd → Variant 1,
   and so on. (Count only leads that actually get a draft, i.e. that passed
   the gates in steps 1–2.)

5. **Fill placeholders — from real data only:**
   - `[OWNER_NAME]` / `[PRINCIPAL_NAME]` ← `contact.name`. If `null`, use the
     neutral greeting `Hello,` — never invent a name.
   - `[BUSINESS_NAME]` ← `business_name`.
   - `[LOCATION]` (OM-1) ← `location`. If `null`, remove the "in [LOCATION]"
     clause rather than guessing.
   - `[SPECIFIC_DETAIL]` ← **one** sentence built from a single verified fact
     in the lead packet (a service line, federal-contract history, SBIC
     license status, investment strategy). **If no verified detail exists,
     omit the entire `[SPECIFIC_DETAIL]` paragraph** — never fabricate one to
     fill the slot. **The packet's `sbic_gp_economics.vintage` is the SBIC
     *fund's* vintage year, not the management company's formation date —
     never render it as a company operating history ("operating since YYYY",
     "since YYYY", years in business, or a track-record-length claim). State
     years operating only from a non-null `formation_date` /
     `years_in_business`; when those are a `null` enrichment gap, the draft
     asserts no start year.**
   - No bracketed placeholder may survive into the stored draft. If a required
     placeholder cannot be filled and has no documented fallback, that is a
     drafting defect — log it, do not store a draft with a raw `[...]` token.

6. **Build the draft block** (§3) and **store it** (§4).

---

## 3. Draft block format

Each stored draft is a self-contained block:

```
--- OFF-MARKET OUTREACH DRAFT (NOT SENT) ---
Date drafted:   YYYY-MM-DD
Business:       <business_name>
Target class:   Class 1 — ASL Bolt-on   |   Class 2 — SBIC
Recipient:      <contact.name or "unknown — neutral greeting used">
                <contact.title or "">
                <contact.email or "needs follow-up: no contact email">
Template:       OM-1 (Owner Approach)   |   OM-2 (SBIC GP Principal)
Subject variant: 1 | 2

Subject: <filled subject line>

<filled body>
--- END DRAFT (review and send manually) ---
```

The `(NOT SENT)` marker and the closing `review and send manually` line are
mandatory — they make the no-send status unmistakable in both storage
locations.

---

## 4. Storage — two places, mirroring on-market

1. **Airtable `Notes`.** Append the draft block to the lead's `Notes` field
   on `tracker_record_id` (the same `Notes` field on-market drafts use — no
   new field, no parallel tracker). Prefix the appended block with a dated
   line, e.g. `2026-05-22 — Outreach: Template OM-1 / Subject Variant 1` so
   the variant is recorded for later A/B reply-rate attribution.

2. **Daily drafts file.** Append the same draft block to
   `search_reports/offmarket_outreach_drafts_YYYY-MM-DD.md` — one dated file
   per run. The filename is deliberately distinct from the on-market
   `search_reports/outreach_drafts_YYYY-MM-DD.md` so the two pipelines share
   the `search_reports/` folder without colliding. Create the file with a
   short header on the run's first draft; append thereafter.

If the `Notes` append fails (Airtable error), still write the draft to the
daily file and log the lead for manual `Notes` entry — a storage failure
never silently drops a draft, and never blocks the rest of the run.

---

## 5. Edge & failure handling

- **No direct contact** → no draft, logged skip (§2 step 1). The most common
  case for thin gov records; it is expected, not an error.
- **Partial contact** (name but no email, or email but no name) → still
  draft; the missing piece shows in the draft block's `Recipient:` lines as
  `needs follow-up`, so the operator knows what to complete before sending.
- **Non-principal Class-2 contact** → still draft OM-2. The contact gate (§2
  step 1) accepts any direct contact, so enrichment may surface a
  non-principal contact (e.g. an investor-relations contact) rather than a GP
  managing principal. The OM-2 body addresses the recipient directly and does
  not assert their role, so a non-principal contact title is not a mis-tone —
  no special handling is needed beyond filling `[PRINCIPAL_NAME]` from
  `contact.name` as usual. The contact's `title`, principal or not, is shown
  verbatim on the draft block's `Recipient:` line so the operator sees who
  the draft is addressed to before sending.
- **No verified specific detail** → omit the `[SPECIFIC_DETAIL]` paragraph;
  the draft is still valid and still stored.
- **Fund vintage is not a company operating history** → `sbic_gp_economics.
  vintage` is the SBIC fund's vintage year, never the management company's
  formation date or years in business. It must not appear in a draft as
  "operating since YYYY" or any track-record-length claim. When
  `formation_date` / `years_in_business` are a `null` enrichment gap, the
  draft states no operating-start year at all.
- **A single lead's drafting error** degrades that lead only — log it and
  continue; one failed draft is not a failed run.
- **Class 2 always carries the SBA-prior-approval sentence** — it is fixed
  body text in OM-2, not a placeholder, so it can never be dropped.
- **Never send.** This step produces drafts only. Sending is always a manual
  human action by the operator — identical to the on-market convention.
- **Broker templates untouched.** This step reads only
  `config/offmarket_outreach_template.md`; it never reads, selects, or edits
  the broker Templates A / C / D in `config/outreach_templates.md`.

---

## 6. Constraints honored

- **Never auto-send** — drafts only, stored in `Notes` + `search_reports/`.
- **Never fabricate** — unknown contact / detail fields are "needs follow-up"
  or omitted; no invented names, emails, or business facts.
- **No parallel tracker** — drafts append to the existing `Notes` field of
  the existing row; the daily drafts file is a report artifact, not a tracker.
- **Broker templates preserved** — off-market uses its own sibling template
  file; the on-market broker templates and their file are not modified.
- **Government change-of-control fact** travels on every Class-2 draft (the
  fixed SBA-prior-approval sentence in OM-2).
