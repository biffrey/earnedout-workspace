#!/usr/bin/env python3
"""s8_dashboard SELF-TEST — structural validation + Jinja2 render.

Checks templates/daily-dashboard.html against REVAMP_PLAN.md Step 7:
 1. Template parses + renders with Jinja2 (no template syntax errors).
 2. All four sections present (A New Finds, B Running Queue, C Revisit,
    D Run Summary) with their placeholders.
 3. Rendered HTML is well-formed (tag balance via html.parser).
Writes the rendered HTML to outputs/dashboard_render.html for the
headless-Chromium render check.
"""
import sys, html.parser

TEMPLATE = "/sessions/great-friendly-shannon/mnt/published-listing-search/templates/daily-dashboard.html"
OUT = "/sessions/great-friendly-shannon/mnt/outputs/dashboard_render.html"

results = []
def check(name, ok, detail=""):
    results.append((name, ok, detail))
    print(("PASS " if ok else "FAIL ") + name + ((" :: " + detail) if detail else ""))

src = open(TEMPLATE, encoding="utf-8").read()
print(f"template bytes: {len(src)}  lines: {src.count(chr(10))+1}")

# --- 1. template placeholders present (raw template) ---
for sec, label in [("section-a", "A New Finds"), ("section-b", "B Running Queue"),
                    ("section-c", "C Revisit Bucket"), ("section-d", "D Run Summary")]:
    check(f"template has id={sec} ({label})", f'id="{sec}"' in src)
for ph in ["{{ date }}", "{% for lead in new_finds %}", "{% for lead in running_queue %}",
           "{% for lead in revisit_bucket %}", "{{ stats.total_searched }}",
           "{% for p in platform_breakdown %}", "{% for i in industry_breakdown %}",
           "{% for e in errors %}", "lead.price_drop", "lead.date_added"]:
    check(f"template placeholder present: {ph}", ph in src)

# --- 2. Jinja2 render with comprehensive sample context ---
from jinja2 import Environment, FileSystemLoader, StrictUndefined
env = Environment(loader=FileSystemLoader("/sessions/great-friendly-shannon/mnt/published-listing-search/templates"),
                  undefined=StrictUndefined)
def lead(score, name, ind, st, ask, ebitda, src_, rep, prev=None, da="2026-05-19"):
    return dict(score=score, business_name=name, industry=ind, state=st,
                asking_price=ask, ebitda=ebitda, source=src_, report_link=rep,
                previous_price=prev, price_drop=bool(prev), date_added=da)
ctx = dict(
    date="2026-05-20",
    generated_at="2026-05-20T03:05:00Z",
    stats=dict(total_searched=142, new_leads=6, duplicates_skipped=29,
               dead_links=4, price_drops=2, manual_submissions=1),
    new_finds=[
        lead(88, "Acme Aviation MRO", "Aviation", "TX", "$8,500,000", "$1,900,000",
             "Overnight Search", "../reports/6a89ka/acme-aviation-mro-report.html"),
        lead(72, "Gulf Coast Waste Hauling", "Waste", "FL", "$4,200,000", "$950,000",
             "Overnight Search", "../reports/zz12/gcwh-report.html", prev="$4,900,000"),
        lead(64, "Metro CART Services", "CART/Captioning", "OH", "$1,100,000", "$320,000",
             "Manual Submission", "../reports/mn44/metro-cart-report.html"),
        lead(41, "Tiny Sign Shop", "Sign Language", "NV", "$300,000", "$70,000",
             "Overnight Search", "../reports/ts01/tiny-report.html"),
    ],
    running_queue=[
        lead(88, "Acme Aviation MRO", "Aviation", "TX", "$8,500,000", "$1,900,000",
             "Overnight Search", "../reports/6a89ka/acme-aviation-mro-report.html", da="2026-05-19"),
        lead(55, "Older Active Lead", "Waste", "GA", "$2,000,000", "$500,000",
             "Overnight Search", "../reports/old1/report.html", da="2026-04-30"),
    ],
    revisit_bucket=[
        lead(38, "Small Roll-up Add-on", "CART/Captioning", "PA", "$600,000", "$140,000",
             "Overnight Search", "../reports/ru1/report.html", da="2026-05-10"),
    ],
    platform_breakdown=[dict(name="DealStream", found=120, new=5),
                        dict(name="BizBuySell", found=22, new=1)],
    industry_breakdown=[dict(name="Aviation", new=2), dict(name="Waste", new=3),
                        dict(name="CART/Captioning", new=1)],
    errors=["BizBuySell: 1 page returned 403 (rate-limited), retried OK"],
)
try:
    rendered = env.get_template("daily-dashboard.html").render(**ctx)
    check("Jinja2 render (populated context)", True, f"{len(rendered)} bytes")
except Exception as e:
    check("Jinja2 render (populated context)", False, repr(e))
    print("\n".join(f"{'PASS' if o else 'FAIL'} {n}" for n,o,_ in results))
    sys.exit(1)

# render again with all-empty lists to exercise {% else %} empty states
ctx_empty = dict(ctx)
ctx_empty.update(new_finds=[], running_queue=[], revisit_bucket=[],
                 platform_breakdown=[], industry_breakdown=[], errors=[],
                 stats=dict(total_searched=0, new_leads=0, duplicates_skipped=0,
                            dead_links=0, price_drops=0, manual_submissions=0))
try:
    rendered_empty = env.get_template("daily-dashboard.html").render(**ctx_empty)
    check("Jinja2 render (empty context / {% else %} states)", True, f"{len(rendered_empty)} bytes")
except Exception as e:
    check("Jinja2 render (empty context)", False, repr(e))

# --- 3. rendered HTML well-formedness (tag balance) ---
VOID = {"area","base","br","col","embed","hr","img","input","link","meta",
        "param","source","track","wbr"}
class Balancer(html.parser.HTMLParser):
    def __init__(self): super().__init__(); self.stack=[]; self.errs=[]
    def handle_starttag(self, tag, attrs):
        if tag not in VOID: self.stack.append(tag)
    def handle_startendtag(self, tag, attrs): pass
    def handle_endtag(self, tag):
        if tag in VOID: return
        if not self.stack: self.errs.append(f"close </{tag}> with empty stack"); return
        if self.stack[-1]==tag: self.stack.pop()
        elif tag in self.stack:
            while self.stack and self.stack[-1]!=tag: self.errs.append(f"unclosed <{self.stack.pop()}>")
            if self.stack: self.stack.pop()
        else:
            self.errs.append(f"stray close </{tag}>")
b = Balancer(); b.feed(rendered)
leftover = [t for t in b.stack]
check("rendered HTML tags balanced", not b.errs and not leftover,
      f"errs={b.errs} leftover={leftover}")

# rendered output contains the 4 section headings + key data
for token, label in [("Section A: Last Night", "A heading"),
                     ("Section B: Running Queue", "B heading"),
                     ("Section C: Revisit Bucket", "C heading"),
                     ("Section D: Run Summary", "D heading"),
                     ("PRICE DROP", "price-drop badge rendered"),
                     ("MANUAL", "manual chip rendered"),
                     ("Acme Aviation MRO", "lead row rendered"),
                     ("was $4,900,000", "previous price rendered")]:
    check(f"rendered output: {label}", token in rendered)
# empty-state strings appear in the empty render
for token in ["No new leads found last night.", "No active leads in the running queue.",
              "No roll-up targets flagged for revisit.", "No errors or platform blocks encountered."]:
    check(f"empty-state rendered: {token!r}", token in rendered_empty)
# no unrendered Jinja delimiters left behind
check("no leftover '{{' in rendered output", "{{" not in rendered and "{%" not in rendered)

open(OUT, "w", encoding="utf-8").write(rendered)
print(f"\nwrote rendered HTML -> {OUT} ({len(rendered)} bytes)")

failed = [n for n,o,_ in results if not o]
print(f"\n=== {len(results)-len(failed)}/{len(results)} checks PASS ===")
sys.exit(1 if failed else 0)
