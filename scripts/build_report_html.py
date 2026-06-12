#!/usr/bin/env python3
"""
build_report_html.py -- deterministic renderer for prospect-evaluation reports.

Converts every {slug}-report.md under a directory into a dark-themed
{slug}-report.html: header banner, value-colored score badge, a contents
sidebar, properly rendered tables.

This file is the SINGLE SOURCE OF TRUTH for report styling. The pipelines
write the markdown (.md); this script produces the .html. Report styling is
therefore deterministic code, not something an LLM run formats by hand. To
change report styling, edit CSS / TEMPLATE here and re-run.

Two callers, two modes:
  - run-offmarket-search.sh (no flag): renders ONLY off-market reports and
    skips the rest -- the original behavior, unchanged.
  - overnight-search pipeline (--any): renders any report .md regardless of
    source; off-market reports get the OFF-MARKET chip, others get none.

Usage:  python3 scripts/build_report_html.py [--any] [path]
        path defaults to output/reports; may be a directory or a single .md file
"""
import sys, os, re, glob, html

try:
    import markdown
except ImportError:
    sys.exit("ERROR: the 'markdown' package is required -- pip install markdown")

CSS = """
:root{color-scheme:dark;--bg:#0f1419;--panel:#171d26;--panel2:#1f2733;--text:#e7ecf3;
  --muted:#8a97ab;--border:#2a3342;--accent:#5aa7ff;--pass:#2fbf71;--fail:#e74c3c;--warn:#f5a623}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--text);line-height:1.55;
  font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;font-size:14px}
.wrap{max-width:1080px;margin:0 auto;padding:22px}
.banner{background:linear-gradient(180deg,#1a2332 0%,#0f1419 100%);
  border:1px solid var(--border);border-radius:14px;padding:20px 24px}
.bhead{display:flex;justify-content:space-between;align-items:flex-start;gap:20px;flex-wrap:wrap}
.btitle h1{margin:0 0 6px;font-size:21px;font-weight:700}
.btitle .meta{margin:0;color:var(--muted);font-size:12.5px}
.chip{display:inline-block;font-size:10px;font-weight:800;letter-spacing:.05em;
  padding:3px 7px;border-radius:5px;vertical-align:middle}
.chip.offmarket{color:#46d18a;background:rgba(47,191,113,.16);border:1px solid rgba(47,191,113,.4)}
.scorebox{flex:none;text-align:center;background:#0b1019;border:1px solid var(--border);
  border-radius:12px;padding:10px 18px;min-width:124px}
.scorebox .sv{font-size:34px;font-weight:800;line-height:1}
.scorebox .sl{font-size:9.5px;color:var(--muted);letter-spacing:.09em;margin-top:5px}
.scorebox.high .sv{color:var(--pass)}
.scorebox.mid .sv{color:var(--accent)}
.scorebox.low .sv{color:var(--fail)}
.cols{display:flex;gap:20px;margin-top:18px;align-items:flex-start}
.toc{flex:none;width:210px;position:sticky;top:18px;background:var(--panel);
  border:1px solid var(--border);border-radius:12px;padding:14px 8px}
.toc .toch{font-size:11px;text-transform:uppercase;letter-spacing:.08em;color:var(--muted);padding:0 10px 8px}
.toc nav{display:flex;flex-direction:column}
.toc nav a{color:#b9c2d0;text-decoration:none;font-size:12.5px;padding:5px 10px;
  border-radius:6px;border-left:2px solid transparent}
.toc nav a:hover{background:var(--panel2);color:var(--text);border-left-color:var(--accent)}
.toc .toc-empty{color:var(--muted);padding:0 10px;font-size:12px}
.doc{flex:1;min-width:0;background:var(--panel);border:1px solid var(--border);
  border-radius:12px;padding:6px 26px 22px}
.doc h2{font-size:17px;margin:24px 0 10px;padding-bottom:8px;border-bottom:1px solid var(--border);color:var(--text)}
.doc h3{font-size:14.5px;margin:18px 0 6px;color:#cdd6e3}
.doc p{margin:9px 0}
.doc a{color:var(--accent)}
.doc code{background:#0b1019;border:1px solid var(--border);border-radius:4px;padding:1px 5px;font-size:12.5px}
.doc hr{border:0;border-top:1px solid var(--border);margin:18px 0}
.doc blockquote{margin:12px 0;padding:10px 14px;background:var(--panel2);
  border-left:3px solid var(--accent);border-radius:0 8px 8px 0;color:#cdd6e3}
.doc blockquote p{margin:5px 0}
.doc table{border-collapse:collapse;width:100%;margin:12px 0;font-size:13px}
.doc th,.doc td{border:1px solid var(--border);padding:7px 10px;text-align:left;vertical-align:top}
.doc th{background:var(--panel2);color:var(--muted);font-size:11px;text-transform:uppercase;letter-spacing:.03em}
.doc ul,.doc ol{padding-left:22px}
.doc li{margin:4px 0}
footer{margin:16px 4px;color:#5c6675;font-size:11px}
@media(max-width:760px){.cols{flex-direction:column}.toc{width:100%;position:static}}
"""

TEMPLATE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>{{TITLE}}</title>
<style>{{CSS}}</style>
</head>
<body>
<div class="wrap">
<header class="banner"><div class="bhead">
<div class="btitle"><h1>{{TITLE}}{{CHIP}}</h1><p class="meta">{{META}}</p></div>
{{SCOREBOX}}
</div></header>
<div class="cols">
<aside class="toc"><div class="toch">Contents</div><nav>{{NAV}}</nav></aside>
<main class="doc">{{BODY}}</main>
</div>
<footer>{{FOOT}}</footer>
</div>
</body>
</html>
"""


def score_class(s):
    return 'high' if s >= 75 else ('mid' if s >= 50 else 'low')


def render_md(md_path, any_source=False):
    text = open(md_path, encoding='utf-8').read()
    is_offmarket = 'off-market' in text.lower()
    if not is_offmarket and not any_source:
        return 'skip'
    lines = text.split('\n')
    title = os.path.basename(md_path)
    ti = 0
    for idx, ln in enumerate(lines):
        if ln.startswith('# '):
            title = ln[2:].strip()
            ti = idx
            break
    meta = []
    i = ti + 1
    while i < len(lines):
        s = lines[i].strip()
        if s == '':
            i += 1
            continue
        m = re.match(r'\*\*(.+?):\*\*\s*(.+)', s)
        if m:
            meta.append((m.group(1).strip(), m.group(2).strip()))
            i += 1
        else:
            break
    body_md = '\n'.join(lines[i:])

    sm = (re.search(r'(?:Lead Score|Score)[^\n]{0,40}?(\d{1,3})\s*/\s*(100|110)', text)
          or re.search(r'\b(\d{1,3})\s*/\s*(100|110)\b', text))

    md = markdown.Markdown(extensions=['tables', 'toc', 'sane_lists'])
    body_html = md.convert(body_md)
    nav = ''.join('<a href="#%s">%s</a>' % (t['id'], html.escape(t['name']))
                  for t in md.toc_tokens)

    metaline = ' &nbsp;&middot;&nbsp; '.join(
        html.escape(v) for (k, v) in meta
        if k.lower() in ('prepared for', 'report date', 'lead source'))

    if sm:
        sc, den = int(sm.group(1)), sm.group(2)
        scorebox = ('<div class="scorebox %s"><div class="sv">%d</div>'
                    '<div class="sl">LEAD SCORE / %s</div></div>'
                    % (score_class(sc), sc, den))
    else:
        scorebox = ''

    chip = (' <span class="chip offmarket">OFF-MARKET</span>'
            if is_offmarket else '')
    foot = ('EarnedOut &mdash; %sprospect evaluation '
            '&middot; rendered by scripts/build_report_html.py'
            % ('off-market ' if is_offmarket else ''))
    out = TEMPLATE
    for tok, val in [('{{CSS}}', CSS),
                     ('{{TITLE}}', html.escape(title)),
                     ('{{CHIP}}', chip),
                     ('{{META}}', metaline),
                     ('{{SCOREBOX}}', scorebox),
                     ('{{NAV}}', nav or '<span class="toc-empty">&mdash;</span>'),
                     ('{{FOOT}}', foot),
                     ('{{BODY}}', body_html)]:
        out = out.replace(tok, val)

    out_path = re.sub(r'\.md$', '.html', md_path)
    open(out_path, 'w', encoding='utf-8').write(out)
    return 'ok'


def main():
    args = sys.argv[1:]
    any_source = '--any' in args
    args = [a for a in args if a != '--any']
    path = args[0] if args else 'output/reports'
    if os.path.isfile(path) and path.endswith('.md'):
        mds = [path]
    else:
        mds = glob.glob(os.path.join(path, '**', '*-report.md'), recursive=True)
    ok = skip = err = 0
    for p in sorted(mds):
        try:
            r = render_md(p, any_source=any_source)
        except Exception as e:
            print('  ERROR %s: %s' % (p, e))
            err += 1
            continue
        if r == 'ok':
            ok += 1
        else:
            skip += 1
    print('build_report_html: rendered %d report(s); '
          'skipped %d non-off-market; %d error(s); %d .md file(s) seen'
          % (ok, skip, err, len(mds)))


if __name__ == '__main__':
    main()
