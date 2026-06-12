#!/usr/bin/env python3
"""
build_dashboard_html.py -- deterministic renderer for the daily dashboard.

Renders templates/daily-dashboard.html (a Jinja2 template; its header comment
documents the full context contract) from a JSON context file, writing
output/dashboards/dashboard_<date>.html.

The overnight-search and submit-url skills write the small JSON context file
(output/run_state/dashboard_data_<date>.json) and run this script -- the model
never emits dashboard HTML. To change dashboard styling or layout, edit the
template and re-run.

Usage:  python3 scripts/build_dashboard_html.py output/run_state/dashboard_data_2026-06-11.json
        python3 scripts/build_dashboard_html.py ctx.json -o some/other/path.html
"""
import sys, os, json

try:
    from jinja2 import Template
except ImportError:
    sys.exit("ERROR: the 'jinja2' package is required -- pip install jinja2")

TEMPLATE_PATH = os.path.join(os.path.dirname(__file__), '..',
                             'templates', 'daily-dashboard.html')

REQUIRED_KEYS = ['date', 'generated_at', 'stats', 'new_finds', 'running_queue',
                 'revisit_bucket', 'platform_breakdown', 'industry_breakdown',
                 'errors']
STAT_KEYS = ['total_searched', 'new_leads', 'duplicates_skipped', 'dead_links',
             'price_drops', 'manual_submissions']
LEAD_DEFAULTS = {'score': 0, 'business_name': '', 'industry': '', 'state': '',
                 'asking_price': '', 'previous_price': '', 'ebitda': '',
                 'source': '', 'report_link': '', 'date_added': '',
                 'price_drop': False}


def main():
    args = sys.argv[1:]
    out_path = None
    if '-o' in args:
        i = args.index('-o')
        out_path = args[i + 1]
        del args[i:i + 2]
    if len(args) != 1:
        sys.exit('usage: build_dashboard_html.py <context.json> [-o out.html]')

    ctx = json.load(open(args[0], encoding='utf-8'))

    missing = [k for k in REQUIRED_KEYS if k not in ctx]
    if missing:
        sys.exit('ERROR: context missing required key(s): %s' % ', '.join(missing))
    for k in STAT_KEYS:
        ctx['stats'].setdefault(k, 0)
    # Fill per-lead defaults so the template never hits an undefined attribute,
    # and sort every lead list by score descending (the template assumes it).
    for section in ('new_finds', 'running_queue', 'revisit_bucket'):
        ctx[section] = sorted(
            [{**LEAD_DEFAULTS, **lead} for lead in ctx[section]],
            key=lambda l: l['score'], reverse=True)

    html = Template(open(TEMPLATE_PATH, encoding='utf-8').read()).render(ctx)

    if out_path is None:
        out_path = os.path.join('output', 'dashboards',
                                'dashboard_%s.html' % ctx['date'])
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    open(out_path, 'w', encoding='utf-8').write(html)
    print('build_dashboard_html: wrote %s (%d new finds, %d active, %d revisit)'
          % (out_path, len(ctx['new_finds']), len(ctx['running_queue']),
             len(ctx['revisit_bucket'])))


if __name__ == '__main__':
    main()
