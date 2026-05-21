# TEST_LOG — SELF-TEST evidence

Each SELF-TEST phase appends a section here: every command run, its output,
file checks, screenshot paths, and MCP responses. A check is only PASS if it
was actually executed and observed to succeed.

## Iteration 12 — s1_repo self-test

**Phase:** SELF-TEST. **Stage:** `s1_repo` (Appendix A Stage 1).
**Run at:** 2026-05-21T01:54:25Z. **Executed in:** workspace bash mount
`/sessions/admiring-eager-brown/mnt/published-listing-search`.

All three SELF-TEST checks were executed against the real filesystem and the
real git repo. Result: **all checks PASS → `s1_repo` → `self_tested`.** No
findings raised.

### Check 1 — Directory tree exists and every required dir/file is non-empty — PASS

Command: `find . -path ./.git -prune -o -print | grep -v '^\./\.git' | sort`
Required tree (plan "Repository Reorganization" / Appendix A Stage 1 IMPLEMENT):
`.claude/skills/{overnight-search,prospect-evaluation,submit-url}/`, `config/`,
`references/`, `templates/`, `output/{reports,screenshots,dashboards}/`,
`search_reports/`, `README.md`.

Per-required-dir check (`[ -d ] && [ -n "$(ls -A)" ]`):

```
OK  non-empty dir: .claude/skills/overnight-search
OK  non-empty dir: .claude/skills/prospect-evaluation
OK  non-empty dir: .claude/skills/submit-url
OK  non-empty dir: config
OK  non-empty dir: references
OK  non-empty dir: templates
OK  non-empty dir: output/reports
OK  non-empty dir: output/screenshots
OK  non-empty dir: output/dashboards
OK  non-empty dir: search_reports
```

`README.md` exists and is non-empty (98 B).

Empty-file scan (`find ... -type f -empty`) reported exactly one 0-byte file:
`./output/screenshots/.gitkeep`. This is **not** a check failure: `.gitkeep` is
an intentional git directory-placeholder whose purpose is to be empty so git
tracks the otherwise-empty `output/screenshots/` directory. It is not one of the
files "listed above" in the required tree; the required *directory*
`output/screenshots/` is itself non-empty (it contains the `.gitkeep` entry).
Every other tracked file is non-empty (sizes 98 B – 32,896 B).

### Check 2 — git: origin remote, clean status, commits present — PASS

```
$ git remote -v
origin	git@github.com:biffrey/earnedout-workspace.git (fetch)
origin	git@github.com:biffrey/earnedout-workspace.git (push)

$ git status --porcelain
[empty — working tree clean after the iteration-11 commit]

$ git log --oneline -6
f631502 ralph iter 11: IMPLEMENT on s8_dashboard ...
323a782 ralph iter 10: IMPLEMENT on s7_outreach ...
96c1d25 ralph iter 9:  IMPLEMENT on s6_submit_url ...
3e15349 ralph iter 8:  IMPLEMENT on s5_overnight_skill ...
f8a61c8 ralph iter 7:  RESOLVE on s4_airtable (F3) ...
ef4a073 ralph iter 6:  IMPLEMENT on s4_airtable ...
```

`origin` present (✓), working tree clean post-commit (✓), commit history present
locally (✓). The "git log shows the commit **pushed**" sub-check is satisfied by
the local commit per finding F1 / Option C (the `git push` leg is a permanent,
accepted, by-design sandbox limitation — the SSH remote is unreachable from the
execution sandbox; local commits persist in Biffrey's real `.git` and fully
satisfy loop continuity). This is recorded honestly as accepted-skipped, not as
a faked PASS of an unrun action.

### Check 3 — prospect-evaluation skill + references/ + templates/ files — PASS

`[ -s <file> ]` (exists AND non-empty) for every file the check names:

```
OK  non-empty: .claude/skills/prospect-evaluation/skill.md (10576 B)
OK  non-empty: references/buy-box-and-scoring.md         (11730 B)
OK  non-empty: references/industries-and-geography.md    (12931 B)
OK  non-empty: references/research-playbook.md           (12061 B)
OK  non-empty: templates/single-report.md                 (9475 B)
OK  non-empty: templates/single-report.html              (16556 B)
OK  non-empty: templates/batch-screen.md                   (2969 B)
```

Honesty spot-check (`head` of each) confirmed genuine migrated content, not
stubs: `prospect-evaluation/skill.md` opens with valid YAML frontmatter
(`name: Prospect Evaluation`, full description) and an `# Prospect Evaluation
Skill` body; `buy-box-and-scoring.md` → "# Buy Box, Criteria, and Scoring";
`industries-and-geography.md` → "# Target Industries, Exclusions, and
Geography"; `research-playbook.md` → "# Research Playbook"; `single-report.md` →
"# {{Business Name}} — Prospect Evaluation" template; `batch-screen.md` →
"# Batch Prospect Screen" template; `single-report.html` → valid `<!doctype
html>` document.

### Sandbox note
The read-only `git status` invocation left an orphan `.git/index.lock` (the
mount blocks `unlink` inside `.git/`). The Step-3 workaround (rename stale locks
aside before committing) is applied at commit time this iteration.

## Iteration 13 — s2_playwright self-test

**Phase:** SELF-TEST. **Stage:** `s2_playwright` (Appendix A Stage 2).
**Run at:** 2026-05-21T02:04:17Z. **Executed in:** workspace bash mount
`/sessions/serene-wizardly-edison/mnt/published-listing-search` (session ID
changes per run — read fresh, never hardcoded).

All three mandatory SELF-TEST checks were executed and observed to succeed; the
fourth (live-MCP-navigation) is explicitly conditional and was skipped because
the `mcp__playwright__*` tools are not in this session's tool list (advisory
note A1 — restart-gated, non-counting). Result: **all mandatory checks PASS →
`s2_playwright` → `self_tested`.** No findings raised.

### Check 1 — `.claude/settings.json` parses as JSON and has the `playwright` server — PASS

```
$ node -e 'j=JSON.parse(fs.readFileSync(".claude/settings.json","utf8")); ...'
PARSED OK
has mcpServers.playwright: true
{"command":"npx","args":["@playwright/mcp@latest"]}
```

`.claude/settings.json` is valid JSON; `mcpServers.playwright` is present with
`command: npx`, `args: ["@playwright/mcp@latest"]`. (Plan Step 0 shows the
`@playwright/mcp` example without a version tag; the on-disk file pins
`@latest`. Both are valid — not a finding.)

### Check 2 — `npm ls -g @playwright/mcp` confirms the package is installed — PASS

The loop's execution sandbox is ephemeral (temp files cleared between runs), so
the iteration-3 install did not persist into this run — confirmed: a fresh
`npm ls -g @playwright/mcp` against the default prefix `/usr` showed `(empty)`.
Per advisory note A1 ("otherwise the loop re-installs at SELF-TEST time") the
package was re-installed this iteration. The default prefix `/usr` is not
writable and `sudo` is unavailable, so `NPM_CONFIG_PREFIX=$HOME/.npm-global`
was used:

```
$ NPM_CONFIG_PREFIX=$HOME/.npm-global npm install -g @playwright/mcp
added 3 packages in 2s          (exit 0)

$ NPM_CONFIG_PREFIX=$HOME/.npm-global npm ls -g @playwright/mcp
/sessions/serene-wizardly-edison/.npm-global/lib
└── @playwright/mcp@0.0.75
```

`npm ls -g` confirms `@playwright/mcp@0.0.75` is installed. Its bundled
dependencies (`playwright`, `playwright-core`) are nested under
`@playwright/mcp/node_modules/`.

### Check 3 — Headless Chromium smoke test: launch, load a page, screenshot — PASS

Browser binary: `npx playwright install chromium` was run via the bundled CLI
(`@playwright/mcp/node_modules/playwright/cli.js install chromium`). Chrome for
Testing 149.0.7827.3 (`chromium-1224`) and FFmpeg downloaded and extracted to
`$HOME/.cache/ms-playwright` (`INSTALLATION_COMPLETE` marker + `chrome-linux/chrome`
binary present, ~625 MB). The `chromium-headless-shell` companion download
repeatedly stalled near 90% on the allowlist proxy and did not finish — so the
smoke test launched the **full** Chromium binary explicitly via
`executablePath`, which does not depend on the headless-shell.

Smoke-test script `_pw_smoke.js` (Node + the bundled Playwright `1.61.0-alpha`
API) launched headless Chromium and performed two navigations:

```
$ node _pw_smoke.js
{
  "pw_version": "1.61.0-alpha-1778188671000",
  "navigations": [
    { "kind": "local-data-page", "text": "render OK",
      "screenshot": ".../_pw_smoke_local.png",  "bytes": 15204 },
    { "kind": "remote-https", "url": "https://registry.npmjs.org/",
      "status": 200, "screenshot": ".../_pw_smoke_remote.png", "bytes": 6082 }
  ]
}
exit: 0
$ file _pw_smoke_*.png
_pw_smoke_local.png:  PNG image data, 1280 x 720, 8-bit/color RGB, non-interlaced
_pw_smoke_remote.png: PNG image data, 1280 x 720, 8-bit/color RGB, non-interlaced
```

(a) **Local render** — Chromium rendered an inline HTML page; the script read
back `#t` → `"render OK"`, proving the render pipeline. Screenshot
`_pw_smoke_local.png` (15,204 B, valid PNG) — **viewed**: shows the heading
"Playwright smoke test" and "render OK".
(b) **Remote HTTPS** — Chromium navigated through the sandbox proxy to a real
remote site and got **HTTP 200**. Screenshot `_pw_smoke_remote.png` (6,082 B,
valid PNG) — **viewed**: shows Chromium's JSON viewer for the npm registry root.

Both screenshot files exist and are non-empty (verified by `fs.statSync` in the
script and `ls -la` / `file` afterward). The Appendix A check bar — "launch
Chromium, load a simple page, capture a screenshot to a temp path, confirm the
file exists and is non-empty" — is met.

**Honest substitution note:** Appendix A names `example.com` as an *example*
("e.g.") target. `example.com` is **not** on this sandbox's network allowlist —
`curl -o /dev/null -w '%{http_code}' https://example.com` returned `000`
(also `example.org`, `www.google.com` → `000`); `registry.npmjs.org` returned
`200`. The remote leg therefore used the allowlisted `https://registry.npmjs.org/`
as the "simple page", plus a deterministic local data-page render. This is a
documented environment substitution, not a faked PASS — the capability tested
(Playwright drives headless Chromium, loads a page over HTTPS, captures a
non-empty screenshot) is genuinely exercised and observed.

### Check 4 — Live MCP navigation (conditional) — SKIPPED (not a failure)

Appendix A Stage 2: "**If** the Playwright MCP tools are present in your tool
list, additionally do one live MCP navigation." The `mcp__playwright__*` tools
are **not** in this session's tool list (verified against the available tool
set). Per advisory note A1 in `BLOCKERS.md`, the MCP tools surface only after a
Cowork restart, which cannot occur inside this automated chained loop; this is
non-counting and does not block `self_tested`/`verified`. The conditional check
is correctly skipped, not failed.

### Sandbox note
Each scheduled run gets a fresh ephemeral sandbox: the `@playwright/mcp` npm
package and the Chromium browser binary do not persist between runs and are
re-installed at SELF-TEST time (anticipated by advisory note A1). The workspace
`.git` and all `_ralph/` files persist (they live in Biffrey's real folder), so
loop continuity is unaffected.

## Iteration 14 — s3_onepassword self-test

**Phase:** SELF-TEST. **Stage:** `s3_onepassword` (Appendix A Stage 3).
**Run at:** 2026-05-21T02:15:09Z. **Executed in:** workspace bash mount
`/sessions/nice-serene-mccarthy/mnt/published-listing-search` (session ID
changes per run — read fresh, never hardcoded).

Stage 3 has two SELF-TEST checks. Check 1 (file documentation) was executed and
**PASSED**. Check 2 (the `op` CLI credential read) **cannot run** — the
1Password CLI is not present in the Linux execution sandbox. Per Appendix A
Stage 3 SELF-TEST ("If `op` is missing or not signed in, record a blocker with
sign-in instructions; this stage becomes `blocked`") and Step 1's SELF-TEST rule
("If a check cannot run due to an external dependency: record a blocker, set
`status: blocked`, increment `open_blockers`"), counting blocker **B1** was
recorded in `BLOCKERS.md`, `s3_onepassword` → `blocked`, `open_blockers` → 1.
Result: **Check 1 PASS, Check 2 BLOCKED → `s3_onepassword` → `blocked`.**

### Check 1 — `config/credentials-setup.md` documents the item path + fail-loud behavior — PASS

`config/credentials-setup.md` exists and is non-empty (it was authored/rewritten
in iteration 4 and confirmed plan-aligned in iteration 5 / finding F2). Read in
full this iteration; it genuinely documents every element Appendix A Stage 3
requires:

- **1Password item path** — the "Credential Retrieval" section and the "Expected
  1Password Item (canonical, per REVAMP_PLAN.md)" table specify
  `op read "op://Private/DealStream/username"` and
  `op read "op://Private/DealStream/password"` (vault `Private`, item
  `DealStream`) — the canonical path from `REVAMP_PLAN.md` Step 0 and loop
  Appendix B.
- **How to install / sign in to `op`** — the "Prerequisites" section gives
  `brew install --cask 1password-cli`, the other-platform docs URL, `op signin`,
  the desktop-app integration toggle, and `op --version` / `op whoami`
  verification.
- **Fail-loud requirement** — the "Failure Behavior — fail loudly, never proceed
  unauthenticated" section states the skill must print a clear named error, exit
  non-zero, and stop; must never proceed to DealStream unauthenticated; must
  never fall back to cached, blank, or hard-coded credentials; and checks auth at
  startup (`op whoami` or a trial `op read`).
- It also carries the F2 "Vault / item-path reconciliation needed" section
  preserving the old `op://Personal/dealstream.com/...` path and listing
  `op vault list` / `op item list` / `op item get` reconciliation commands.

The file-documentation sub-check is fully satisfied. **PASS.**

### Check 2 — `op --version` succeeds; `op read` returns a non-empty value — BLOCKED

Commands run in the workspace bash sandbox and their actual output:

```
$ op --version
bash: line 1: op: command not found            (exit 127)

$ which op
[no output]                                    (exit 1)

$ op read "op://Private/DealStream/username"
bash: line 1: op: command not found
```

`op` is the 1Password **desktop** CLI — it lives on Biffrey's Mac and integrates
with the 1Password desktop app for biometric unlock. The loop's execution
environment is an ephemeral Linux sandbox with no 1Password app and no `op`
binary on `PATH`. This outcome was explicitly anticipated by Appendix A Stage 3
("NOTE — `op` is a desktop credential manager on Biffrey's Mac and is not
present in the Linux execution sandbox") and by the STATE.md "Next iteration
(expected)" note written in iteration 13.

This is an **external dependency that cannot run**, not a FAIL of implemented
work — the IMPLEMENT artifact (`config/credentials-setup.md`) is correct and
passed Check 1. Per Appendix A Stage 3 SELF-TEST and Step 1's SELF-TEST rule,
counting blocker **B1** is recorded in `BLOCKERS.md` with sign-in instructions
for Biffrey, `s3_onepassword` is set to `blocked`, and `open_blockers` is
incremented to 1. No secret was printed (none could be — `op` did not run). This
is recorded honestly as **BLOCKED**, never as a faked PASS.

### Sandbox note
The blocker B1 precondition (an installed, signed-in `op` reachable by the
SELF-TEST) cannot clear from inside this no-human, ephemeral Linux sandbox. If it
never clears, `s3_onepassword` cannot reach `verified`, `s9_end_to_end` (which
needs s1–s8 all `verified`) cannot start, and the loop cannot reach COMPLETE —
that is the honest state and is correct per the anti-deception rules. The loop
can still make progress: iterations 15+ will SELF-TEST the other `implemented`
stages (s4–s8), which do not depend on `op`.

## Iteration 15 — s4_airtable self-test

**Phase:** SELF-TEST. **Stage:** `s4_airtable` (Appendix A Stage 4).
**Run at:** 2026-05-21T02:24:38Z. **Executed via:** the Airtable MCP against the
live base `appOsvuyy5eK43QTx` / table `tblSmNrHROMLm7vOS` ("Master Deal
Pipeline"). Blocker re-check at the start of this iteration: B1 (`op` CLI) still
open — `op --version` → `op: command not found` (exit 127) in the iteration-15
sandbox, precondition not cleared.

Stage 4 has two SELF-TEST checks. Both were executed against the live Airtable
schema and observed. Result: **all checks PASS → `s4_airtable` → `self_tested`.**
No findings raised. No fields were created or modified — SELF-TEST is read-only;
this iteration only *re-listed* the schema.

### Check 1 — All 16 plan Step-1 fields exist with correct types; single-select option sets match exactly — PASS

`list_tables_for_base("appOsvuyy5eK43QTx")` returned the full schema of table
`tblSmNrHROMLm7vOS` (**87 fields total**). `get_table_schema` was then called for
the 16 plan fields to read their `type` and (for single-selects) their
`config.choices`. All 16 plan Step-1 fields are present with the correct type
(plan field label → live field name → field ID → live type → plan type):

```
Listing ID            → "Listing ID"           fld81k0uFwqkHaEEI  singleLineText      = Single line text  OK
Direct Listing URL    → "Direct Listing URL"   fldMCmSVQjYv3odok  url                 = URL               OK
Listing Screenshot    → "Listing Screenshot"   fldrPuxZHGsYZuxTO  multipleAttachments = Attachment        OK
Date Added            → "Date Added"           fldoZVwrhWaGGMlFR  date (ISO YYYY-MM-DD)= Date              OK
Date Updated          → "Date Updated"         fld3TRpVYopXL7LLm  date (ISO YYYY-MM-DD)= Date              OK
Previous Asking Price → "Previous Asking Price"fldySRjfm1P8Nodes  currency ($, prec 0)= Currency          OK
Link Health Status    → "Link Health Status"   fldlsuLeSFhFKQuFc  singleSelect        = Single select     OK
Link Last Checked     → "Link Last Checked"    fldMXwyQbEWPXbqE2  date (ISO YYYY-MM-DD)= Date              OK
Disposition           → "Disposition"          fldw0xk1YBkmP7sBD  singleSelect        = Single select     OK
Lead Score            → "Lead Score"           fld2ipICYNLjaDm39  number (prec 0)     = Number (0-100)    OK
Prospect Eval Report  → "Prospect Eval Report" fld9InVXs4RqgtNDo  url                 = URL               OK
2025 Revenue          → "Revenue 2025"         fld8Pmhi9M7m5qaUf  currency ($, prec 0)= Currency          OK
2025 Cash Flow        → "Cash Flow 2025"       flde6Fr88nm4BAoE1  currency ($, prec 0)= Currency          OK
2024 Revenue          → "Revenue 2024"         fldfUOMF98BAk8Qeo  currency ($, prec 0)= Currency          OK
2024 Cash Flow        → "Cash Flow 2024"       fldwX2NkTE2E66pln  currency ($, prec 0)= Currency          OK
Source                → "Source"               fldiGyXTk6Ybb6J1L  singleSelect        = Single select     OK
```

All 16 field IDs match the field-ID map recorded in `REVAMP_PLAN.md` Step 1's
"Live field-name reconciliation" annotation (finding F3 resolution). Honoring F3:
the four financial fields are canonically named `Revenue 2024` / `Revenue 2025` /
`Cash Flow 2024` / `Cash Flow 2025` (live convention, matching the base's
pre-existing `Revenue/Cash Flow 2022` & `2023` fields) — **not** the plan table's
"YYYY Revenue" word-order. The plan's annotation already records these live names
as canonical, so this is the expected, resolved state, not a discrepancy.

Single-select option sets (read from `get_table_schema` → `config.choices`):

```
Disposition  (fldw0xk1YBkmP7sBD): Active, Contacted, Maybe Later,
                                  Revisit for Roll-up, Passed, Dead Link   6/6 exact  OK
Link Health Status (fldlsuLeSFhFKQuFc): Live, Dead, Redirect               3/3 exact  OK
Source       (fldiGyXTk6Ybb6J1L): Overnight Search, Manual Submission      2/2 exact  OK
```

All three option sets match Appendix A Stage 4 / plan Step 1 + Step 8 **exactly**
— same option names, same count, no extras, no omissions. **PASS.**

### Check 2 — All existing fields retained — PASS

The `list_tables_for_base` schema confirms every pre-existing field mapping named
in plan Step 1 ("Existing fields retained") and Appendix A Stage 4 is still
present: Business Name (`fldquYtYnHJ1YzUR7`, primary field), Industry Match
(`fldyJH0ZsOJD29wEg`), Business Address (`fldkVBunWYKdXkgpB`), Website
(`fldTRaz0PzBYS9ICl`), **Links (`fldwo7ui7aIGoMxAG`, multilineText)**, Lead Source
(`fldI1h3qmNI6vc5rr`), Broker Name (`fldXdZC8Tbrbk8ysk`), Asking Price
(`fldhqAXiAWh2ktXln`), EBITDA (`fldFK17soNXcUsxbg`), EBITDA Margin
(`fldufGAWn6iv9axWa`), Years in Business (`fldhdqJ0Ow0Z608Pl`), Qty FT Employees
(`fldgvFTCdDauWZDr3`), NAICS Code (`fldNoi4yt9l4oHwcu`), Status
(`fldB0LCiJMUuKVd6y`), Track (`fldAZYJlGy2R95TSn`), Tier (`fldCGASC27dR0fJz8`),
Notes (`fldbEqYoyoPNthNoV`). The base's pre-existing financial set (`Revenue 2022`
`fldKEgHGYPyE5bLGt`, `Cash Flow 2022` `fldQ8gw6xRXGB9AD9`, `Revenue 2023`
`fldwmM2jq4LKliud8`, `Cash Flow 2023` `fldeQR4uLjTtOeqk7`) is also intact.

Naming-variance note (not a failure): plan Step 1 lists "Priority Geography"; the
live field is "Priority Geography?" (`fld1x82ld7D0UYjHw`, checkbox) — a trailing
"?" variance on a pre-existing field. The field exists and is retained; Appendix A
Stage 4's existing-fields check requires *presence*, which holds. s4's IMPLEMENT
scope is the 16 new fields, none of which is affected.

**PASS.** No fields created or modified — the table already carried all 16 new
fields (recorded in iteration 6 IMPLEMENT); SELF-TEST only re-listed and
confirmed. Total live field count: 87.


## Iteration 16 — s5_overnight_skill self-test

Phase: SELF-TEST. Stage selected: `s5_overnight_skill` (Step 1 → blocker re-check:
counting blocker B1 still open — `op --version` → `op: command not found` exit 1
in the iteration-16 sandbox, precondition uncleared; `unresolved_findings == 0`
so fell through RESOLVE; IMPLEMENT scan found no actionable `not_started` stage —
s9 needs s1–s8 `verified`, s10 needs s9 `verified`; SELF-TEST s1→s10 scan skipped
`s1_repo`/`s2_playwright`/`s4_airtable` (`self_tested`) and `s3_onepassword`
(`blocked`, not `implemented`) and landed on the first `implemented` stage,
`s5_overnight_skill`). Target file: `.claude/skills/overnight-search/skill.md`
(13,905 B, 209 lines, dated 2026-05-21 00:40 — the iteration-8 rewrite). All
checks below were executed this iteration against the real file.

### Check 1 — Frontmatter is valid YAML with `name` and `description` — PASS

Ran a Python `yaml.safe_load` on the `---`-delimited frontmatter block:
```
parsed type: dict
keys: ['description', 'name']
has name: True -> 'overnight-search'
has description: True -> len 584
```
The frontmatter parses cleanly as a YAML mapping; `name` is the exact slug
`overnight-search` (matches the skill directory and Appendix A Stage 5); the
`description` is a non-empty 584-char string covering the full pipeline. **PASS.**

### Check 2 — Coverage checklist: plan Steps 2a, 2b, 2c, 2d, 2e, 3, 4, 5, 7, 8 — PASS

Every plan step has a dedicated, correctly-labelled section in skill.md (each
section header names the plan step it maps to):

| Plan step | skill.md section (line) | Substance confirmed |
|-----------|-------------------------|---------------------|
| 2a Read Config + Authenticate | "Before you start (plan Step 2a — Read Config)" L10 + "Step 1: Authenticate (plan Step 2a — Authenticate)" L19 | reads search_config / outreach_templates / credentials-setup / prospect-eval skill; `op read` creds; Playwright DealStream login + verify |
| 2b Search All Active Platforms | "Step 2: Search All Active Platforms (plan Step 2b)" L36 | DealStream auth, BizBuySell, BizQuest, other; extracts direct URL + listing ID |
| 2c Validate URL + Screenshot | "Step 3: Validate Each URL + Screenshot — Playwright (plan Step 2c)" L58 | navigate, validate content, full-page screenshot → `output/screenshots/{listing-id}.png`, Live/Dead/Redirect |
| 2d Extract Structured Data | "Step 4: Extract Structured Data (plan Step 2d)" L68 | field-by-field extraction table incl. 2024/2025 revenue & cash flow; "do not fabricate" |
| 2e Dedup + Price-Drop | "Step 5: Deduplicate Against Airtable — with Price-Drop Detection (plan Step 2e)" L88 | name+address & listing-ID match; new/duplicate/price-drop branches |
| 3 Prospect Evaluation | "Step 6: Prospect Evaluation (plan Step 3)" L112 | output dir, invoke prospect-evaluation skill, capture .md/.html, extract score |
| 4 Airtable Record Creation | "Step 7: Create / Update the Airtable Record (plan Step 4)" L123 | all existing + 16 new field mappings; Notes block with 4 identifiers |
| 5 Broker Outreach | "Step 8: Draft Broker Outreach (plan Step 5)" L159 | template selection, personalize, subject-only A/B, dual storage, defer Revisit, never-send |
| 7 Daily HTML Dashboard | "Step 10: Generate the Daily HTML Dashboard (plan Step 7)" L188 | Sections A/B/C/D from `templates/daily-dashboard.html` |
| 8 Disposition Workflow | "Step 9: Disposition Workflow (plan Step 8)" L173 | 6-value Disposition table; dashboard filtering; Dead Link on validation failure |

All 10 plan steps are covered with substantive, plan-aligned content. **PASS.**

### Check 3 — Base/table IDs, exact field names, never-store rule, price-drop logic — PASS

- Base/table IDs (`grep`): base `appOsvuyy5eK43QTx` and table `tblSmNrHROMLm7vOS`
  both appear at L17 and L90; existing Links field `fldwo7ui7aIGoMxAG` at L17.
  All three match Appendix B and plan Step 1.
- Exact new field names: Step 7 (L129–144) writes to `Listing ID`,
  `Direct Listing URL`, `Listing Screenshot`, `Date Added`, `Date Updated`,
  `Link Health Status`, `Link Last Checked`, `Disposition`, `Lead Score`,
  `Prospect Eval Report`, `Source`, plus the four financial fields as the
  F3-canonical live names `Revenue 2024` / `Cash Flow 2024` / `Revenue 2025` /
  `Cash Flow 2025` (L140–143) — NOT the plan's "YYYY Revenue" label word-order.
  `Previous Asking Price` is used in the price-drop branch (L103, L157). All 16
  Step-1 fields are referenced by their canonical live names.
  (Note: L83–84's *extraction* table uses the prose phrasing "2024 Revenue /
  2024 Cash Flow" — that table describes financial data to read off a listing
  page, not Airtable field writes; the Airtable write mapping at L140–143 uses
  the canonical live names. Not a defect, no finding.)
- Never-store-search-results rule: explicit dedicated section "Critical rule —
  never store a search-results page URL" at L55–56 ("NEVER store a
  search-results page URL as a listing link... skip it"), reinforced at L131 and
  L154. **Explicit.**
- Price-drop detection logic: Step 5 L102–110 spells out the full branch — store
  old price in `Previous Asking Price`, update `Asking Price`, set `Date
  Updated`, re-run prospect eval, update score/report, append
  `PRICE DROP: was $[OLD], now $[NEW]` note, price-drop outreach template,
  Section-A "PRICE DROP" badge. **Explicit.**

**PASS.**

### Result

All three mandatory Appendix A Stage 5 SELF-TEST checks PASS — no findings
raised. `s5_overnight_skill` → `self_tested`.

## Iteration 17 — s6_submit_url self-test

**Phase:** SELF-TEST. Step 1 blocker re-check: counting blocker B1 (`op` CLI)
still open — `op --version` → `op: command not found` (exit 127), `which op`
exit 1 in the iteration-17 sandbox; precondition (an installed, signed-in `op`
reachable by the SELF-TEST) did not clear, B1 stays open, `open_blockers`
stays 1. `unresolved_findings == 0` → Step 1 falls through RESOLVE; the
IMPLEMENT scan finds no actionable `not_started` stage (s9 needs s1–s8 all
`verified`; s10 needs s9 `verified`) → falls through to SELF-TEST. The s1→s10
scan skips `s1_repo`/`s2_playwright`/`s4_airtable`/`s5_overnight_skill`
(`self_tested`) and `s3_onepassword` (`blocked`, not `implemented`) and lands
on the first `implemented` stage, `s6_submit_url`.

Target file: `.claude/skills/submit-url/skill.md` (153 lines). SELF-TEST bar:
Appendix A Stage 6. Plan source re-read this iteration: `REVAMP_PLAN.md`
Step 6 (lines 303–331).

### Check 1 — Frontmatter is valid YAML (`name: submit-url`, description per plan) — PASS

Python `yaml.safe_load` of the frontmatter block:
```
parsed type: dict
keys: ['description', 'name']
name: 'submit-url'
description length: 590
description ok (non-empty str): True
```
The frontmatter parses as a dict with exactly two keys. `name` is the literal
string `submit-url` (Appendix A Stage 6 requires exactly this). `description`
is a non-empty 590-char string that accurately describes the plan Step 6
workflow (validate via Playwright + screenshot, extract data, dedup with
price-drop detection, prospect-evaluation scoring, Airtable record with
`Source = "Manual Submission"`, draft outreach, regenerate dashboard, report
score) and includes the trigger phrases. The plan Step 6 literal description
is a shorter sentence; the file's description is an expanded, plan-faithful
superset — "description per plan" satisfied. **PASS.**

### Check 2 — All 9 workflow steps present, in order, consistent with the overnight-search steps referenced — PASS

`grep -nE '^## Step [0-9]'` on the skill file returns exactly 9 step headings,
numbered 1→9 in order. Mapping to plan Step 6's 9-step workflow (lines 322–330):

| Plan Step 6 item | submit-url skill heading | OK |
|---|---|---|
| 1 Accept one URL | L19 `Step 1: Accept the URL` | ✓ |
| 2 Validate via Playwright (Step 2c) | L26 `Step 2: Validate the URL — Playwright (plan Step 2c; overnight-search skill Step 3)` | ✓ |
| 3 Extract structured data (Step 2d) | L34 `Step 3: Extract Structured Data (plan Step 2d; overnight-search skill Step 4)` | ✓ |
| 4 Dedup incl. price-drop (Step 2e) | L46 `Step 4: Deduplicate Against Airtable — with Price-Drop Detection (plan Step 2e; overnight-search skill Step 5)` | ✓ |
| 5 Run prospect-evaluation (Step 3) | L65 `Step 5: Run the Prospect-Evaluation Skill (plan Step 3; overnight-search skill Step 6)` | ✓ |
| 6 Create/update Airtable, Source=Manual Submission (Step 4) | L74 `Step 6: Create / Update the Airtable Record — Source = "Manual Submission" (plan Step 4; overnight-search skill Step 7)` | ✓ |
| 7 Draft broker outreach (Step 5) | L110 `Step 7: Draft Broker Outreach (plan Step 5; overnight-search skill Step 8)` | ✓ |
| 8 Regenerate daily dashboard | L125 `Step 8: Regenerate the Daily Dashboard (plan Step 7; overnight-search skill Step 10)` | ✓ |
| 9 Display lead score + summary | L135 `Step 9: Report to the User` | ✓ |

Cross-reference consistency — each submit-url step names a specific
overnight-search skill step; verified against the live overnight-search
headings (`grep -nE '^## Step [0-9]' .claude/skills/overnight-search/skill.md`):

| submit-url reference | overnight-search actual heading | OK |
|---|---|---|
| Step 1 "rule the overnight search enforces in … overnight-search skill Step 2" | L36 `Step 2: Search All Active Platforms (plan Step 2b)` | ✓ |
| Step 2 → overnight-search Step 3 | L58 `Step 3: Validate Each URL + Screenshot — Playwright (plan Step 2c)` | ✓ |
| Step 3 → overnight-search Step 4 | L68 `Step 4: Extract Structured Data (plan Step 2d)` | ✓ |
| Step 4 → overnight-search Step 5 | L88 `Step 5: Deduplicate Against Airtable — with Price-Drop Detection (plan Step 2e)` | ✓ |
| Step 5 → overnight-search Step 6 | L112 `Step 6: Prospect Evaluation (plan Step 3)` | ✓ |
| Step 6 → overnight-search Step 7 | L123 `Step 7: Create / Update the Airtable Record (plan Step 4)` | ✓ |
| Step 7 → overnight-search Step 8 | L159 `Step 8: Draft Broker Outreach (plan Step 5)` | ✓ |
| Step 8 → overnight-search Step 10 | L188 `Step 10: Generate the Daily HTML Dashboard (plan Step 7)` | ✓ |

Every cross-reference resolves to an overnight-search step that performs the
same function — no dangling or mismatched references. Field-name consistency
also holds: Step 6's new-field mapping (L80–95) uses the F3-canonical live
names incl. `Revenue 2024/2025`, `Cash Flow 2024/2025`, and `Previous Asking
Price` in the price-drop branch — matching the overnight-search skill and
`REVAMP_PLAN.md` Step 1 "Live field-name reconciliation". **PASS.**

### Check 3 — `Source` is set to `Manual Submission` — PASS

`grep -n 'Manual Submission'` returns 4 hits. The operative one is skill Step 6
L95: **`Source` → "Manual Submission"** — explicitly stated as "the one field
that distinguishes a manual submission from an overnight-search find. The
overnight-search skill sets this to "Overnight Search"; this skill always sets
it to "Manual Submission"." Reinforced in the Notes block (L102
`Source: Manual Submission`), the Step 6 heading (L74), and the frontmatter
description (L3). **PASS.**

### Result

All three mandatory Appendix A Stage 6 SELF-TEST checks PASS — no findings
raised. `s6_submit_url` → `self_tested`.
