#!/usr/bin/env python3
"""Render the EarnedOut daily dashboard for the s9 end-to-end test run (2026-05-21)."""
import datetime, pathlib
from jinja2 import Template

ROOT = pathlib.Path("/Users/biffreybraxton/published-listing-search")

def lead(score, name, industry, state, price, ebitda, source, report, date_added,
         price_drop=False, previous=""):
    return dict(score=score, business_name=name, industry=industry, state=state,
                asking_price=price, ebitda=ebitda, source=source, report_link=report,
                date_added=date_added, price_drop=price_drop, previous_price=previous)

# Section A — found / updated this run, sorted score desc
new_finds = [
    lead(50, "HVAC Business, Very Profitable, Recurring Clients [RALPH TEST]",
         "HVAC / Home Services", "SC", "$1,500,000", "$403,000", "Overnight Search",
         "../reports/cvkfxz/hvac-business-sc-report.html", "2026-05-21"),
    lead(35, "Thriving HVAC Business (Southwestern South Dakota) [RALPH TEST]",
         "HVAC / Home Services", "SD", "$1,495,000", "$41,515", "Overnight Search",
         "../reports/maya0n/thriving-hvac-sd-report.html", "2026-05-21",
         price_drop=True, previous="$1,800,000"),
    lead(20, "Profitable HVAC & Plumbing Contractor With Land [RALPH TEST]",
         "HVAC + Plumbing / Home Services", "CAN", "$1,962,686", "$327,114",
         "Manual Submission", "../reports/so8acs/hvac-plumbing-contractor-report.html",
         "2026-05-21"),
]

# Section B — every Disposition=Active lead (live Airtable query 2026-05-21), score desc
running_queue = [
    lead(50, "HVAC Business, Very Profitable, Recurring Clients [RALPH TEST]", "HVAC / Home Services", "SC", "$1,500,000", "$403,000", "Overnight Search", "../reports/cvkfxz/hvac-business-sc-report.html", "2026-05-21"),
    lead(47, "High Growth Oilfield Equipment Rental — Bakken", "Oilfield Services", "ND", "$17,000,000", "—", "Overnight Search", "#", "2026-04-16"),
    lead(45, "FAA Certified Repair Station — Florida (BizBuySell)", "Aerospace / MRO", "FL", "$26,000,000", "—", "Overnight Search", "#", "2026-04-16"),
    lead(35, "Powder Coating & Cerakote Oven Manufacturer", "Manufacturing", "IL", "$10,950,000", "—", "Overnight Search", "#", "2026-04-16"),
    lead(35, "Metal Fabrication Business — Harris County TX", "Manufacturing", "TX", "$17,990,000", "—", "Overnight Search", "#", "2026-04-16"),
    lead(30, "Aviation Maintenance Facility — Fort Lauderdale", "Aerospace / MRO", "FL", "$1,800,000", "—", "Overnight Search", "#", "2026-04-16"),
    lead(25, "$1.48M EBITDA Boutique Digital Marketing Agency — Charlotte, NC", "Marketing", "NC", "—", "—", "Overnight Search", "#", "2026-04-16"),
    lead(20, "SBA Pre-Qual Digital Marketing Agency — Tampa, FL", "Marketing", "FL", "$1,400,000", "—", "Overnight Search", "#", "2026-04-16"),
    lead(20, "Digital Marketing Agency — Healthcare Sector Focus", "Marketing", "US", "$900,000", "—", "Overnight Search", "#", "2026-04-16"),
    lead(20, "Disaster Response & Emergency Base Camp Provider", "Emergency Management", "US", "—", "—", "Overnight Search", "#", "2026-04-16"),
    lead(20, "Profitable Locksmith Business + Property — SBA Pre-Qual", "Home Services", "US", "—", "—", "Overnight Search", "#", "2026-04-16"),
    lead(20, "HVAC & Plumbing Company", "HVAC / Home Services", "US", "—", "—", "Overnight Search", "#", "2026-04-16"),
    lead(20, "Thriving Garage Door & Gate Business", "Home Services", "US", "—", "—", "Overnight Search", "#", "2026-04-16"),
    lead(20, "Profitable Interventional Cardiology Practice", "Cardiac / Medical", "US", "—", "—", "Overnight Search", "#", "2026-04-16"),
    lead(20, "High-End Architecture & Interior Design Firm", "Architectural Design", "US", "—", "—", "Overnight Search", "#", "2026-04-16"),
    lead(20, "$1.72M Revenue Digital Marketing Agency — Austin, TX", "Marketing", "TX", "—", "—", "Overnight Search", "#", "2026-04-16"),
    lead(20, "Aircraft Repair & Paint Facility — Mena, Arkansas (Hampton Aviation)", "Aerospace / MRO", "AR", "—", "—", "Overnight Search", "#", "2026-04-16"),
    lead(20, "FAA 141 & 142 SEVP Certified Flight Training School", "Aerospace", "US", "—", "—", "Overnight Search", "#", "2026-04-16"),
]

# Section C — every Disposition=Revisit for Roll-up lead, score desc
revisit_bucket = [
    lead(35, "Thriving HVAC Business (Southwestern South Dakota) [RALPH TEST]", "HVAC / Home Services", "SD", "$1,495,000", "$41,515", "Overnight Search", "../reports/maya0n/thriving-hvac-sd-report.html", "2026-05-21"),
    lead(25, "Part 145 Avionics Repair Station — Arkansas", "Aerospace / MRO", "AR", "$1,000,000", "—", "Overnight Search", "#", "2026-04-16"),
    lead(20, "FAA Part 135 Charter Certificate — Florida", "Aerospace", "FL", "$249,000", "—", "Overnight Search", "#", "2026-04-16"),
]

ctx = dict(
    date="2026-05-21",
    generated_at=datetime.datetime.now().isoformat(timespec="seconds"),
    stats=dict(total_searched=243, new_leads=2, duplicates_skipped=0,
               dead_links=1, price_drops=1, manual_submissions=1),
    new_finds=new_finds,
    running_queue=running_queue,
    revisit_bucket=revisit_bucket,
    platform_breakdown=[
        dict(name="DealStream", found=243, new=3),
        dict(name="BizBuySell", found=0, new=0),
        dict(name="BizQuest", found=0, new=0),
    ],
    industry_breakdown=[dict(name="HVAC / Home Services", new=3)],
    errors=["s9 test run — deliberately small scope: 1 industry (HVAC), DealStream only, "
            "limited pagination. 1 dead URL (hvac/zzzz99) correctly flagged + skipped."],
)

tpl = Template((ROOT / "templates/daily-dashboard.html").read_text())
out = ROOT / "output/dashboards/dashboard_2026-05-21.html"
out.write_text(tpl.render(**ctx))
print("rendered", out, out.stat().st_size, "bytes")
