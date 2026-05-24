# s8 Outreach Drafting — SELF-TEST evidence

**iter 23, 2026-05-22** — drove the s8 procedure
(`.claude/skills/off-market-search/references/outreach_drafting.md`) +
`config/offmarket_outreach_template.md` over the s5/s6 SELF-TEST leads — the
Class-1 fixture **R1** and the Class-2 real SBIC **R2** — plus one constructed
no-contact case. Six checks against the `OFFMARKET_BUILD_PLAN.md` s8 `Done-when`
criteria ("a draft is generated for a candidate with a direct contact; nothing
is auto-sent; the broker templates are untouched").

## Inputs — the s5/s6 leads (as written by the s6 `ScoredLead`)

| id | class | candidate | contact (from s5 `LeadPacket`) |
|---|---|---|---|
| R1 | 1 | EXAMPLE INTERPRETING FIXTURE LLC | `{name: "Pat Sample", title: "Owner", email: null, phone: null}` — partial contact (name, no email) |
| R2 | 2 | 1st Source Capital Corporation, South Bend IN | `{name: "Ryan Fenstermaker", title: "Investor Relations", email: "fenstermakerr@1stsource.com", phone: "574-235-2180"}` — full contact |
| SYN-NC1 | 1 | (constructed in-memory, NOT written anywhere) | `{name: null, title: null, email: null}` — no direct contact |

**B4 note (carried, not a failure).** The s8 §1 input is "the leads s7 just
wrote to `tblSmNrHROMLm7vOS`". s7 SELF-TEST C5 is BLOCKED by B4 — no off-market
row exists in the tracker, so there is no live `tracker_record_id` to append a
`Notes` block to. This SELF-TEST therefore exercises s8 over the s5/s6 leads as
test input and stores the generated drafts to the daily-file path only; the
two-place §4 storage (the `Notes` append) is the designed B4 degradation path —
`outreach_drafting.md` §4 already specifies "a storage failure never silently
drops a draft" → the draft still lands in the daily file. The live `Notes`
append is exercised in s10's end-to-end run once B4 clears.

---

## C1 — a Class-1 OM-1 draft is generated for a candidate with a direct contact; no raw placeholder survives

**R1** has a direct contact (`contact.name = "Pat Sample"`) → §2 step 1 contact
gate **passes** (name present; email `null` is a partial contact, §5 → still
draft). §2 step 2 disposition `Active` (s7 writes off-market rows `Active`) →
eligible. §2 step 3 → Class 1 → **Template OM-1**. §2 step 4 → 1st drafted lead
this run → **Subject Variant 1**.

Placeholder fill (§2 step 5, real data only):

| placeholder | filled from | value |
|---|---|---|
| `[OWNER_NAME]` | `contact.name` | `Pat Sample` |
| `[BUSINESS_NAME]` | `business_name` | `EXAMPLE INTERPRETING FIXTURE LLC` |
| `[LOCATION]` | `location` | `Anytown, VA` |
| `[SPECIFIC_DETAIL]` | `LeadPacket.federal_award_total = 480000` (verified, from s4 `award_total`) | one sentence on the federal interpreting-contract track record |

Generated draft block (also in `evidence/s8-offmarket_outreach_drafts_2026-05-22.md`):

```
--- OFF-MARKET OUTREACH DRAFT (NOT SENT) ---
Date drafted:   2026-05-22
Business:       EXAMPLE INTERPRETING FIXTURE LLC
Target class:   Class 1 — ASL Bolt-on
Recipient:      Pat Sample
                Owner
                needs follow-up: no contact email
Template:       OM-1 (Owner Approach)
Subject variant: 1

Subject: Partnering with EXAMPLE INTERPRETING FIXTURE LLC — a note from Applied Development

Hi Pat Sample,

I'm Biffrey Braxton, Co-Founder & Chairman of Applied Development. We work
in the same space you do — sign language interpreting, CART, and
deaf-services — and I've been following EXAMPLE INTERPRETING FIXTURE LLC's
work in Anytown, VA.

I want to be upfront: I know EXAMPLE INTERPRETING FIXTURE LLC isn't for sale,
and this isn't a listing inquiry. I'm reaching out directly because Applied
Development is building a platform of best-in-class ASL / CART / deaf-services
companies, and EXAMPLE INTERPRETING FIXTURE LLC is exactly the kind of operator
we'd like to grow alongside.

Your firm's record delivering interpreting services on federal contracts —
roughly $480K in awards to date — is exactly the kind of operating discipline
we look for in a partner.

If you've ever thought about what a partnership, growth capital, or an
eventual succession plan could look like, I'd value a low-key conversation —
no obligation, just an exchange of ideas between people who care about this
industry.

Would you be open to a 20-minute call in the next couple of weeks?

Best regards,

Biffrey Braxton
Co-Founder & Chairman, Applied Development
📞 443-864-2408 ✉️ bbraxton@applied-dev.com
https://smbsteward.com/
--- END DRAFT (review and send manually) ---
```

A `grep` of the stored block for a raw `[A-Z_]` placeholder token returns
**zero** hits — every `[OWNER_NAME]` / `[BUSINESS_NAME]` / `[LOCATION]` /
`[SPECIFIC_DETAIL]` was substituted. The partial-contact case behaved per §5:
drafted, with the missing email surfaced as `needs follow-up: no contact email`
in the `Recipient:` block. **PASS.**

## C2 — a Class-2 OM-2 draft is generated; the SBA-prior-approval sentence is present

**R2** has a full direct contact → contact gate passes. Class 2 → **Template
OM-2**. 2nd drafted lead this run → **Subject Variant 2**.

Placeholder fill: `[PRINCIPAL_NAME]` ← `Ryan Fenstermaker`; `[BUSINESS_NAME]` ←
`1st Source Capital Corporation`; `[SPECIFIC_DETAIL]` ← built from the verified
`sbic_gp_economics` packet facts (`vintage: 1983`, `strategy: "Direct Lending"`).

```
--- OFF-MARKET OUTREACH DRAFT (NOT SENT) ---
Date drafted:   2026-05-22
Business:       1st Source Capital Corporation
Target class:   Class 2 — SBIC
Recipient:      Ryan Fenstermaker
                Investor Relations
                fenstermakerr@1stsource.com
Template:       OM-2 (SBIC GP Principal Approach)
Subject variant: 2

Subject: 1st Source Capital Corporation — a confidential conversation on the management company

Hi Ryan Fenstermaker,

I'm Biffrey Braxton — I acquire and operate lower-middle-market businesses,
and I have a specific, long-term interest in SBIC management companies.

I'll be direct: I know 1st Source Capital Corporation isn't on the market. I'm
reaching out to you as a principal because I'd like to understand whether the
management company itself — the team, the license, and the go-forward platform
— is something you would ever consider transitioning, whether through a sale, a
succession plan, or a partnership.

1st Source Capital Corporation has operated as a licensed SBIC pursuing a
direct-lending strategy since 1983 — a long, durable track record in the
program.

I understand that a change of control of a licensed SBIC requires SBA prior
approval, and I would approach any process with that fully in mind and with
the appropriate counsel — this note is simply to open a conversation.

Would you be open to a confidential 20-minute call in the next few weeks?

Best regards,

Biffrey Braxton
📞 443-864-2408 ✉️ bbraxton@applied-dev.com
https://smbsteward.com/
--- END DRAFT (review and send manually) ---
```

The SBA-prior-approval sentence — "I understand that a change of control of a
licensed SBIC requires SBA prior approval…" — appears verbatim as **fixed body
text** (not a placeholder), so every Class-2 draft carries the government
change-of-control fact. No raw `[...]` placeholder survives. **PASS.**

## C3 — the no-contact case yields no draft

**SYN-NC1** (constructed in-memory only — clearly labelled, NOT written to any
file or to Airtable) carries `contact.name = null` and `contact.email = null`.
§2 step 1 contact gate: neither a name nor an email → **no draft generated**.
The run log records `outreach: skipped — no direct contact (needs follow-up:
contact discovery)`. No name/email was fabricated to force a draft. The skipped
lead does **not** consume a subject-variant slot (§2 step 4 — count only drafted
leads). **PASS.**

## C4 — nothing is auto-sent; the NOT SENT markers are present in storage

- Both generated draft blocks open with `--- OFF-MARKET OUTREACH DRAFT (NOT
  SENT) ---` and close with `--- END DRAFT (review and send manually) ---` — the
  two mandatory no-send markers (`outreach_drafting.md` §3).
- The s8 deliverable contains **no send capability**: `outreach_drafting.md` §6
  and `skill.md` Step 7 both state "Never send email — drafts only"; no Gmail /
  SMTP / send call exists anywhere in the s8 reference or the template file. A
  `grep` of `outreach_drafting.md` + `offmarket_outreach_template.md` for
  `send`/`Gmail`/`smtp` finds only the explicit *no-send* prohibitions.
- Storage exercised: the daily-file path
  (`search_reports/offmarket_outreach_drafts_2026-05-22.md`) — written here as
  the evidence artifact `evidence/s8-offmarket_outreach_drafts_2026-05-22.md`
  (banner-marked a build-loop SELF-TEST artifact so it is not mistaken for a
  production run). The Airtable `Notes` append is the B4-blocked half (see the
  B4 note above) — its designed degradation (draft still lands in the daily
  file) is what is exercised. **PASS.**

## C5 — the broker templates are untouched

`config/outreach_templates.md` (broker Templates A / C / D) — `git log` shows it
last modified at commit `323a782` on **2026-05-21** by the on-market revamp loop
(`ralph iter 10`), before this build loop's first commit; **no `offmarket-build`
commit touches it**, and `git status` shows it clean in the working tree. The s8
deliverable is a **new sibling file**, `config/offmarket_outreach_template.md`
(created in iter 22). `outreach_drafting.md` §5/§6 and `skill.md` Step 7 state
the broker file is "not read, selected, or edited" by s8. **PASS.**

## C6 — subject-variant alternation across drafted leads

§2 step 4: variant alternates per **drafted** lead. Run order: R1 (drafted) →
Variant 1; SYN-NC1 (skipped — no draft, no slot consumed); R2 (drafted) →
Variant 2. The two stored draft blocks show `Subject variant: 1` and `Subject
variant: 2` respectively — alternation is correct and the skipped lead did not
shift the count. **PASS.**

---

## Result

All **6** SELF-TEST checks PASS. A Class-1 OM-1 draft and a Class-2 OM-2 draft
were each generated for a candidate with a direct contact, with every
placeholder filled from real data and no raw `[...]` token surviving; the
no-contact case correctly yields no draft; both stored blocks carry the NOT SENT
markers and the deliverable has no send path; the SBA-prior-approval sentence is
fixed body text in the Class-2 draft; and the broker templates are untouched.
**No BLOCKING defect.**

**Carry-notes to the VERIFY critic** (not Done-when failures):

1. **B4 dependency.** The §4 two-place storage cannot be fully exercised while
   B4 is open — no off-market tracker row exists, so the `Notes` append has no
   `tracker_record_id`. The daily-file half is exercised; the `Notes` half is
   the designed degradation path and is deferred to s10's end-to-end run once
   B4 clears. This does not block s8 — the s8 `Done-when` ("a draft is generated
   for a candidate with a direct contact") is satisfied without a live Airtable
   row.
2. **OM-2 recipient vs. "as a principal".** R2's only enriched contact is the
   directory POC Ryan Fenstermaker, titled **Investor Relations** — the s5
   `LeadPacket.enrichment_gaps` already flags "GP managing principal — needs
   follow-up (directory POC is investor-relations, not the deal principal)". The
   §2 step-1 contact gate (name **or** email) accepts this POC, so a draft is
   generated, but the OM-2 fixed body says "reaching out to you as a principal".
   Drafting that line to an IR contact is a mild tone mismatch. The procedure
   does not fabricate — it uses the only real contact it has — but the critic
   should weigh whether s8 should prefer a principal-titled contact for Class 2,
   or soften the body when the contact title is not principal-level. Flagged as
   a candidate IMPROVE finding.

Stage s8 → `self_checked`. Next phase: VERIFY (fresh-context critic).
