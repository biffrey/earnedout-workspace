# Off-Market Outreach Templates

Proprietary-approach outreach drafts for the **off-market** acquisition
pipeline. The `off-market-search` skill (and its manual single-entity path)
reads this file at Step 7 and selects a template per off-market lead.

**This file is a sibling of `config/outreach_templates.md` — it does not
modify it.** The broker templates (A / C / D) in that file stay exactly as
they are and remain in use for on-market leads. Off-market and on-market
outreach are deliberately kept in separate files because the two messages
read very differently:

| | On-market (`outreach_templates.md`) | Off-market (this file) |
|---|---|---|
| Recipient | A **broker** representing a listed business | The **business owner / SBIC GP principal directly** |
| Premise | The business **is for sale** | The business is **not for sale** — a proprietary approach |
| Ask | NDA + CIM + a closing-focused call | An exploratory, no-obligation conversation |
| Artifacts | Listing ID, asking price, CIM | None — there is no listing |

Approved by the operator in §13 Q7 of
`PRD_OFF_MARKET_SEARCH_Section13_Resolution.md` ("Approve a dedicated
proprietary-approach template — keep broker templates for on-market"). The
mis-tone risk this mitigates is PRD §12 risk **R11**.

**All outreach is DRAFTED ONLY — the skill never sends email.** See
"Storage & Handling" at the end of this file. This mirrors the on-market
no-send rule exactly.

---

## Template Selection Logic

Applied per off-market lead, by target class — there is exactly one template
per class:

1. **Class 1 — ASL / CART / deaf-services company** (`Source = "Off-Market —
   ASL Bolt-on"`): use **Template OM-1** (Owner Approach — Applied
   Development roll-up).
2. **Class 2 — licensed SBIC management firm** (`Source = "Off-Market —
   SBIC"`): use **Template OM-2** (SBIC GP Principal Approach).

**No draft is generated** when the lead has **no direct contact** (no owner /
principal name *and* no contact email). A proprietary approach with nobody to
address it to is not drafted — instead the run log records `outreach: skipped
— no direct contact (needs follow-up: contact discovery)`. A missing contact
is never fabricated to force a draft.

---

## A/B Testing — Subject Line Only

As with the broker templates, A/B testing rotates the **subject line only**;
the body stays constant within each template. Two subject variants are listed
per template. Selection alternates per off-market lead drafted in a run (1st
lead → Variant 1, 2nd → Variant 2, 3rd → Variant 1, …) — deterministic and
independent of any ID format. Record the variant used in the Airtable `Notes`
field (e.g. `Outreach: Template OM-1 / Subject Variant 2`) so reply rates can
be attributed later.

---

## Template OM-1 — Owner Approach (ASL / CART / Deaf-Services Roll-up)

For Class-1 targets — a sign-language / CART / deaf-services operating company
that Applied Development would acquire as a roll-up add-on. The recipient is
the **business owner / principal**, and the message must read as a peer
reaching out within the same industry, not a buyer working a listing.

### Subject Line (A/B rotate — subject only)

**Variant 1:**
```
Partnering with [BUSINESS_NAME] — a note from Applied Development
```

**Variant 2:**
```
[BUSINESS_NAME] + Applied Development — exploring a conversation
```

### Body

```
Hi [OWNER_NAME],

I'm Biffrey Braxton, Co-Founder & Chairman of Applied Development. We work
in the same space you do — sign language interpreting, CART, and
deaf-services — and I've been following [BUSINESS_NAME]'s work in
[LOCATION].

I want to be upfront: I know [BUSINESS_NAME] isn't for sale, and this isn't
a listing inquiry. I'm reaching out directly because Applied Development is
building a platform of best-in-class ASL / CART / deaf-services companies,
and [BUSINESS_NAME] is exactly the kind of operator we'd like to grow
alongside.

[SPECIFIC_DETAIL]

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
```

### Placeholders

- `[OWNER_NAME]` — the owner / principal's name from enrichment. If unknown,
  use the neutral greeting `Hello,` — never leave the bracket and never
  invent a name.
- `[BUSINESS_NAME]` — the canonical entity name.
- `[LOCATION]` — city + state from the resolved record. If unknown, drop the
  clause "in [LOCATION]" entirely rather than guessing.
- `[SPECIFIC_DETAIL]` — **one** sentence stating a single concrete, real fact
  about the business (a service line, a federal-contract track record, years
  operating). It must be drawn from enrichment data only. **If no real,
  verified detail is available, omit this paragraph entirely** — never
  fabricate a detail to fill it.

---

## Template OM-2 — SBIC GP Principal Approach

For Class-2 targets — a licensed SBIC management firm acquired for the
license and platform itself. The recipient is a **GP principal**. The message
opens a confidential conversation and states the SBA-prior-approval fact
plainly so the recipient knows the sender understands the regulatory path.

### Subject Line (A/B rotate — subject only)

**Variant 1:**
```
A direct note to [BUSINESS_NAME]'s leadership
```

**Variant 2:**
```
[BUSINESS_NAME] — a confidential conversation on the management company
```

### Body

```
Hi [PRINCIPAL_NAME],

I'm Biffrey Braxton — I acquire and operate lower-middle-market businesses,
and I have a specific, long-term interest in SBIC management companies.

I'll be direct: I know [BUSINESS_NAME] isn't on the market. I'm reaching out
to you as a principal because I'd like to understand whether the management
company itself — the team, the license, and the go-forward platform — is
something you would ever consider transitioning, whether through a sale, a
succession plan, or a partnership.

[SPECIFIC_DETAIL]

I understand that a change of control of a licensed SBIC requires SBA prior
approval, and I would approach any process with that fully in mind and with
the appropriate counsel — this note is simply to open a conversation.

Would you be open to a confidential 20-minute call in the next few weeks?

Best regards,

Biffrey Braxton
📞 443-864-2408 ✉️ bbraxton@applied-dev.com
https://smbsteward.com/
```

### Placeholders

- `[PRINCIPAL_NAME]` — the GP principal's name from enrichment. If unknown,
  use the neutral greeting `Hello,` — never invent a name.
- `[BUSINESS_NAME]` — the canonical management-firm name.
- `[SPECIFIC_DETAIL]` — **one** sentence stating a single concrete, real fact
  drawn from the lead packet's enrichment data only: the SBIC license status
  (e.g. "in good standing"), the investment strategy / focus, or the SBIC
  license type. **If no real, verified detail is available, omit this
  paragraph entirely** — never fabricate.

  **Never render the SBIC fund vintage as a company operating history.** The
  lead packet's `sbic_gp_economics.vintage` is the *fund's* vintage year — it
  is **not** the management company's formation date, incorporation year, or
  years in business. The detail sentence must never say the firm "has operated
  since [vintage]", is a "[vintage]-vintage firm", or carry any company
  operating-start or track-record-length claim derived from it. Company
  operating history may be stated **only** from a non-null `formation_date` /
  `years_in_business` in the packet; when those are an enrichment gap (`null`),
  the draft asserts no start year and no track-record-length claim at all.

> The SBA-prior-approval-of-change-of-control sentence is a **fixed part of
> the body**, not a placeholder — every Class-2 draft carries it. This is the
> same government change-of-control fact carried on every Class-2 Airtable
> record (`references/airtable_write.md` §3.4).

---

## Tone Guidance (off-market only)

Why this template differs from the broker templates — the rationale that
guides any future edits:

1. **Acknowledge the business is not for sale, explicitly.** The owner has
   not listed; pretending otherwise reads as a mass-mailer. Naming it builds
   trust.
2. **No NDA / CIM / data-room language.** Those artifacts exist only for
   listed businesses. An off-market draft that asks for a CIM is the R11
   mis-tone failure.
3. **Lead with shared industry / shared purpose,** not with the buy box. The
   buy-box bullet list belongs in broker outreach; here it reads as a filter.
4. **The ask is a conversation, not a transaction.** "Would you be open to a
   call" — low-commitment, no deadline pressure ("48 hours" language is for
   brokers working a live listing).
5. **One real, specific detail beats five generic ones.** A single verified
   fact about the business shows genuine attention; an invented one destroys
   credibility. When in doubt, omit it.
6. **Class 2 states the regulatory reality up front.** A GP principal will
   immediately think of SBA approval; saying it first signals competence.

---

## Storage & Handling

Consistent with the on-market no-send rule and `references/outreach_drafting.md`:

- **Draft only — never send.** The `off-market-search` skill drafts off-market
  outreach; it must never send email. Sending is always a manual step done by
  Biffrey.
- **Airtable `Notes` field.** The drafted outreach (template + subject variant
  used, and the filled body) is appended to the lead's Airtable record `Notes`
  field — the same field and convention as on-market.
- **Daily drafts file.** All off-market drafts from a run are also compiled
  into `search_reports/offmarket_outreach_drafts_YYYY-MM-DD.md` — one dated
  file per run, a distinct filename from the on-market
  `outreach_drafts_YYYY-MM-DD.md` so the two pipelines never collide in the
  shared `search_reports/` folder.
- **No direct contact — no draft.** A lead with no owner / principal name and
  no contact email gets no draft; the run log notes it as a contact-discovery
  follow-up.
- **Variant tracking.** Record the template and subject variant used in
  `Notes` so reply rates can be attributed during A/B analysis.
