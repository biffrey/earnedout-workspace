# Changelog

## 2026-06-11 — Token-usage reduction: subagent isolation + model routing + deterministic HTML

### Summary
Restructured the overnight-search pipeline to cut per-run token usage. Three changes,
each tested headless (`claude -p … --dangerously-skip-permissions`) before the next:

1. **Per-listing loop isolated into a Haiku subagent.** New
   `.claude/agents/listing-processor.md` handles overnight Steps 3–4 (navigate,
   validate, screenshot, extract) for one listing per invocation and returns only a
   compact JSON record — Playwright noise and raw page text stay in the child context.
   Invoked **sequentially** (the headed-Chrome Playwright session is shared). Verified
   end-to-end on BizBuySell listing 2480446 (validation, 911×4913 screenshot, full
   field extraction).
2. **Model routing — Opus only where it earns it.** New
   `.claude/agents/prospect-scorer.md` (model: opus, preloads prospect-evaluation)
   scores one lead per invocation and returns compact JSON; the deal memo goes to
   disk. `run-overnight-search.sh` now passes `--model sonnet` so orchestration
   (search, dedup, Airtable, outreach templating) runs on Sonnet; extraction is Haiku.
   Verified by scoring listing 2480446 (35/100, Buy Box FAIL, correct rubric).
3. **Models no longer emit HTML.** `scripts/build_report_html.py` generalized with an
   `--any` flag (default off-market-only behavior unchanged — regression-checked:
   261 rendered / 129 skipped). New `scripts/build_dashboard_html.py` renders
   `templates/daily-dashboard.html` (already a Jinja2 template) from a small context
   JSON (`output/run_state/dashboard_data_<date>.json`). The prospect-scorer writes
   the report **.md only**; overnight Step 6 renders the HTML via script, Step 10 and
   submit-url Step 8 write context JSON and run the dashboard renderer.

### Files
- Added: `.claude/agents/listing-processor.md`, `.claude/agents/prospect-scorer.md`,
  `scripts/build_dashboard_html.py`
- Modified: `.claude/skills/overnight-search/SKILL.md` (Steps 3+4 merged into
  subagent delegation; Step 6 rewired; Step 10 rewired),
  `.claude/skills/submit-url/SKILL.md` (Step 8 rewired),
  `scripts/build_report_html.py` (`--any` flag, source-aware chip/footer),
  `run-overnight-search.sh` (`--model sonnet`)

## 2026-06-04 — Overnight-search auth fix + BizBuySell coverage hardening

### Summary
The published-listing (overnight) search had silently added **nothing for ~12 days**
(2026-05-23 → 06-04), and a buy-box-matching BizBuySell listing forwarded by hand
(an ASL interpretation business, listing `2455028`) never appeared in the dashboard.
Root-caused and fixed both the auth failure and the BizBuySell coverage gap; re-enabled
the off-market search; moved the schedule to a staffed time; ran a catch-up; and added
the forwarded listing to the pipeline.

### Root causes
1. **Auth gate bug (the dark period).** The overnight-search skill gated authentication
   on `op whoami`, which **always** reports "account is not signed in" under the 1Password
   **desktop-app integration** — even when `op read` returns valid credentials. Every
   unattended nightly run aborted at this gate. (The one run that worked, 05-21, happened
   to try the `op read` fallback.)
2. **No viable unattended auth.** The desktop integration needs an interactive biometric
   approval a detached `launchd`/`claude -p` process can't answer (`op read` →
   `authorization timeout`). 1Password **service-account tokens** were assumed as the fix,
   but they require **1Password Business**; this is an **Individual** account, so they're
   unavailable.
3. **Off-market search disabled.** Its `launchd` job had been unloaded
   (`*.plist.disabled`), so that channel had been dark since 05-23.
4. **BizBuySell coverage gap.** The search used BizBuySell's `?q=` keyword endpoint, which
   is **bot-protected (HTTP 403 / "Powered and protected" challenge)** — for headless
   *and* curl. BizBuySell also **mis-files ASL/sign-language interpreting under
   *Manufacturing › Signs*** ("Sign Manufacturers and Businesses"), mixed with sign-*making*
   firms — so naive keyword/category searches returned only signage companies. Blocked
   results were logged as "0 available," masking the gap.

### Changes
**Authentication**
- Rewrote the auth gate in `run-overnight-search.sh` and the overnight-search skill to gate
  on the credentials, **never on `op whoami`**.
- Switched unattended auth to the **macOS login Keychain**. The runner resolves
  `$DEALSTREAM_USERNAME` / `$DEALSTREAM_PASSWORD` from Keychain items
  (`earnedout-dealstream-username` / `-password`, stored with `-A` for non-interactive
  read) and passes them to the skill via env vars; falls back to `op read` if absent. A
  `launchd` job runs as the logged-in user with the login keychain unlocked, so the
  scheduled run authenticates with **no Touch ID prompt and no 1Password dependency**.
  (No credential is ever written to the repo.)

**Scheduling**
- Re-enabled the off-market `launchd` job (`ai.earnedout.offmarket-search`).
- Moved the overnight job from `02:37` to **`10:00` America/New_York = `11:00` Atlantic** —
  a staffed daytime slot (Keychain + the headed BizBuySell browser need the logged-in GUI
  session). Documented in `config/schedule.md`.

**BizBuySell coverage**
- Replaced the bot-blocked `?q=` keyword search with **category-page navigation**, and
  documented the **ASL → "Sign Manufacturers and Businesses"** taxonomy trap plus a
  **keep/drop keyword filter** (keep ASL/interpreting/deaf/VRI/CART/translation; drop
  signage/banners/awnings) in `config/search_config.md` and the skill.
- Configured the Playwright MCP (`config/playwright-mcp.json`, wired via
  `.claude/settings.json`) to launch **real headed Google Chrome** (`channel: chrome`,
  `--disable-blink-features=AutomationControlled`, no `--enable-automation`, persistent
  profile). Headless is 403-blocked on category pages; this real-Chrome fingerprint
  returns HTTP 200. **Verified end-to-end:** the category sweep loads cleanly and surfaces
  listing `2455028`, correctly excluding the sign-making listings around it.
- Required that a bot-challenged/unreachable page be logged **"blocked — coverage
  incomplete,"** never "0 available."
- Added **request pacing + backoff-retry** for the anti-bot block (skill + config):
  throttle 3–8 s between category pages / 2–5 s between detail fetches, and on a
  "Powered and protected" 403 back off ~30 s → ~90 s (max 3 attempts) before marking
  blocked. (The block tripped after ~50 listings on 2026-06-06; pacing avoids it and
  backoff recovers from transient throttles.)
- Hardened the "config not found" path with a `.claude/skills/overnight-search/config`
  symlink (the files were always present under `config/`; failed runs guessed a wrong path).

### Operational notes / follow-ups
- The Mac must be **logged in** at 11:00 for Keychain reads and the headed BizBuySell sweep
  (screen-locked is fine; fully logged-out falls back to `op`).
- A Chrome window will briefly open during the BizBuySell sweep — expected (headed browser).
- **TODO (planned):** integrate a paid anti-bot scraper (ScraperAPI / BrightData / Zyte)
  for fully-unattended BizBuySell discovery; the real-Chrome sweep is the interim solution.

### Files changed
- `run-overnight-search.sh` — Keychain auth resolution + env-var hand-off; auth-gate rewrite
- `.claude/skills/overnight-search/skill.md` — auth gate + BizBuySell category-sweep method
- `config/credentials-setup.md` — Keychain method (supersedes the service-account approach)
- `config/schedule.md` — 11:00 Atlantic cadence + rationale
- `config/search_config.md` — BizBuySell category-sweep method, taxonomy trap, disambiguation
- `config/playwright-mcp.json` *(new)* — real-Chrome launch options for the Playwright MCP
- `.claude/settings.json` — point the Playwright MCP at the config
- `.claude/skills/overnight-search/config` *(new symlink)* — robustness for the config path
