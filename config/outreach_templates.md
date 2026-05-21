# Broker Outreach Templates

Outreach drafts for the EarnedOut acquisition pipeline. The overnight-search
skill and the submit-url skill both read this file and select a template per
lead. **All outreach is DRAFTED ONLY — the skills never send email.** See
"Storage & Handling" at the end of this file.

This file is canonical against `REVAMP_PLAN.md` Step 5 ("Broker Outreach —
revised template + response-rate improvements"). Template A reproduces the plan
Step 5 "Updated Default Template" email block verbatim.

---

## Template Selection Logic

Applied per lead, in this order — the first match wins:

1. **Aviation leads** (Part 135 / Part 145 / FAA-certificated operations, MRO):
   use **Template C** (Aviation-Specific).
2. **Price-drop re-outreach** (a previously-seen listing whose asking price has
   dropped — see `REVAMP_PLAN.md` Step 2e): use **Template D** (Price-Drop
   Follow-Up).
3. **All other leads:** use **Template A** (Updated Default Template).

**Deferred:** Leads with `Disposition = "Revisit for Roll-up"` get **no
outreach drafted** — outreach is deferred until the disposition changes (per
`REVAMP_PLAN.md` Step 5 "Storage").

---

## A/B Testing — Subject Line Only

A/B testing rotates the **subject line only**. The email **body stays
constant** within each template. Per `REVAMP_PLAN.md` Step 5 suggestion #8, the
old odd/even A/B test that swapped the whole email body is replaced by this:
most response-rate variance comes from the subject line, so only the subject
line is varied.

- **What rotates:** the two subject-line variants listed under each template.
- **Selection method:** alternate per new lead processed in a run — the 1st
  drafted lead uses Variant 1, the 2nd uses Variant 2, the 3rd Variant 1, and
  so on. This is deterministic and works for any Listing ID format (DealStream
  IDs are alphanumeric, so odd/even-on-ID is not used).
- **Tracking:** record which variant was used in the Airtable Notes field
  (e.g. `Outreach: Template A / Subject Variant 2`) so reply rates can be
  attributed later.

---

## Template A — Updated Default Template

*Reproduced verbatim from `REVAMP_PLAN.md` Step 5, "Updated Default Template".*

### Subject Line (A/B rotate — subject only)

**Variant 1** (plan Step 5 literal subject):
```
NDA & CIM request — Listing [LISTING_ID] | Biffrey Braxton Group
```

**Variant 2** (plan Step 5 suggestion #1 — personalized with business name):
```
NDA & CIM request — [BUSINESS_NAME] (Listing [LISTING_ID]) | Biffrey Braxton Group
```

### Body

```
Hi [BROKER_NAME],

I'm Biffrey Braxton, Co-Founder & Chairman of Applied Development and
co-founder of other firms, such as Inno-Native, FlexFly, and Intiendo.

My upcoming liquidity event will free capital that I plan to redeploy
immediately into lower-middle-market acquisitions.

Your listing **[LISTING_ID] / "[BUSINESS_NAME]"** fits my buy-box:

* 10+ yrs operating history
* EBITDA $1+ MM
* < 4× EBITDA pricing
* Team of >10 FTEs

Because timing is critical, I would like to:

1. **Execute an NDA today** (yours or our standard form).
2. **Receive the Confidential Information Memorandum** and any teaser
   deck, data room link, or financial supplement you normally provide.
3. Schedule a 20-minute follow-up call with you within 48 hours.

Please see my website to better understand my motivation:
https://smbsteward.com/

Looking forward to working together.

Best regards,

Biffrey Braxton
📞 443-864-2408 ✉️ bbraxton@applied-dev.com
```

### Placeholders

`[BROKER_NAME]`, `[LISTING_ID]`, `[BUSINESS_NAME]` — fill from the extracted
listing data before the draft is stored. If broker name is unknown, use a
neutral greeting ("Hello,") rather than leaving the bracket in place.

---

## Template C — Aviation-Specific

Used for Part 135 / Part 145 / FAA-certificated and MRO leads.

### Subject Line (A/B rotate — subject only)

**Variant 1:**
```
NDA & CIM request — [BUSINESS_NAME] (FAA [CERT_TYPE]) | Biffrey Braxton Group
```

**Variant 2:**
```
Serious buyer inquiry — [BUSINESS_NAME] ([CERT_TYPE] MRO) | Biffrey Braxton Group
```

### Body

```
Hi [BROKER_NAME],

I'm Biffrey Braxton, Co-Founder & Chairman of Applied Development. Aviation
services is a top-priority acquisition vertical for me — I'm actively building
a portfolio in the MRO / Part 135 / Part 145 space.

Your listing [LISTING_ID] / "[BUSINESS_NAME]" — a [CERT_TYPE] certified
operation in [LOCATION] — fits squarely in my buy box. I'm particularly
interested in the [SPECIFIC_DETAIL, e.g., "engine overhaul capabilities"
or "rotor-wing maintenance focus"].

I have deployable capital from an upcoming liquidity event and am prepared
to move quickly:

1. Execute an NDA today.
2. Review the CIM and any supplemental materials.
3. Schedule a 20-minute call within 48 hours to discuss the opportunity.

Please see my website: https://smbsteward.com/

Best regards,

Biffrey Braxton
📞 443-864-2408 ✉️ bbraxton@applied-dev.com
```

### Placeholders

`[BROKER_NAME]`, `[LISTING_ID]`, `[BUSINESS_NAME]`, `[CERT_TYPE]` (e.g.
"Part 145", "Part 135"), `[LOCATION]`, `[SPECIFIC_DETAIL]`.

---

## Template D — Price-Drop Follow-Up

Used for price-drop re-outreach (a listing already in the pipeline whose asking
price has dropped). Built from `REVAMP_PLAN.md` Step 5 suggestion #7.

### Subject Line

```
Re: [BUSINESS_NAME] (Listing [LISTING_ID]) — Updated pricing
```

Price-drop re-outreach uses a single subject line (no A/B rotation) — it is a
follow-up on a known opportunity, so the subject is anchored to the prior
thread.

### Body

```
Hi [BROKER_NAME],

I noticed the asking price for [BUSINESS_NAME] has been adjusted from
[PREVIOUS_PRICE] to [CURRENT_PRICE]. I'd like to re-engage on this
opportunity.

At the updated valuation, this listing fits even better within my
acquisition criteria. Can we schedule a call this week to discuss
next steps?

If we haven't connected before — I'm Biffrey Braxton, Co-Founder &
Chairman of Applied Development, actively acquiring lower-middle-market
businesses. More at https://smbsteward.com/

Best regards,

Biffrey Braxton
📞 443-864-2408 ✉️ bbraxton@applied-dev.com
```

### Placeholders

`[BROKER_NAME]`, `[BUSINESS_NAME]`, `[LISTING_ID]`, `[PREVIOUS_PRICE]`,
`[CURRENT_PRICE]` — `[PREVIOUS_PRICE]` is the value stored in the Airtable
`Previous Asking Price` field; `[CURRENT_PRICE]` is the new lower `Asking
Price`.

---

## Response-Rate Guidance

Reproduced from `REVAMP_PLAN.md` Step 5, "Suggestions to Increase Response
Rate". These eight points are the rationale behind the templates above and
guide future template edits:

1. **Personalize the subject line.** Include the business name or industry, not
   just the listing ID — brokers get dozens of generic inquiries. (Implemented:
   Template A Subject Variant 2.)

2. **Lead with proof of funds / closing ability.** Brokers prioritize buyers
   who can close. Make the liquidity event concrete — e.g. "I'm closing a
   liquidity event in [month] that provides $[X]M in deployable capital" — even
   a range signals seriousness vs. a vague "upcoming."

3. **Reference the specific listing details.** Show you actually read the
   listing — add a line such as "The [INDUSTRY] focus, [CITY] location, and
   [YEARS]-year operating history make this a strong fit." It separates you
   from spray-and-pray buyers.

4. **Drop the bullet list (or make it conversational).** The buy-box bullet
   list can read like an automated filter. A conversational alternative:
   "Your listing fits what I'm looking for — an established business with a
   decade-plus track record, strong cash flow, and a team I can build on."

5. **Add a social proof sentence.** E.g. "I've completed [N] acquisitions in
   the [industry] space" or "I'm currently operating [X] portfolio companies" —
   it shows you're not a first-time buyer kicking tires.

6. **Make the CTA even easier.** Offer to send YOUR NDA proactively: "I've
   attached our standard NDA — happy to sign yours instead if you prefer."
   Removing friction increases reply rate.

7. **For price-drop re-outreach,** send a follow-up when a listing's price
   drops: "I noticed the asking price for [BUSINESS_NAME] has been adjusted.
   I'd like to re-engage on this opportunity. Can we schedule a call this
   week?" (Implemented: Template D.)

8. **A/B test subject lines specifically.** The old odd/even A/B test changed
   the whole email body. Keep the body consistent and A/B test only the subject
   line — that is where most response-rate variance comes from. (Implemented:
   the "A/B Testing — Subject Line Only" section above.)

Template A reproduces the plan's canonical "Updated Default Template" verbatim.
Suggestions 2–6 are refinements a human can apply per lead (with concrete,
listing-specific facts) — they are intentionally kept as guidance rather than
hard-coded into Template A so the default stays faithful to the plan and any
personalization is grounded in real listing data, never invented.

---

## Storage & Handling

Per `REVAMP_PLAN.md` Step 5 "Storage" and the project's no-send rule:

- **Draft only — never send.** The overnight-search and submit-url skills draft
  outreach; they must never send email. Sending is always a manual step done by
  Biffrey.
- **Airtable Notes field.** The drafted outreach (template used, subject
  variant, and the filled body) is appended to the lead's Airtable record Notes
  field.
- **Daily drafts file.** All drafts from a run are also compiled into
  `search_reports/outreach_drafts_YYYY-MM-DD.md` — one dated file per run,
  containing every draft produced that run.
- **Revisit for Roll-up — deferred.** Leads with `Disposition = "Revisit for
  Roll-up"` get no outreach drafted; outreach is deferred until the disposition
  changes (e.g. to `Active`).
- **Variant tracking.** Record the template and subject variant used in the
  Airtable Notes field so reply rates can be attributed during A/B analysis.
