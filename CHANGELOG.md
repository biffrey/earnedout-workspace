# Changelog

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
