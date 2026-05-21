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

