# Credentials Setup — 1Password CLI

The EarnedOut overnight-search skill (and the submit-url skill) retrieve the
DealStream login at runtime via the 1Password CLI (`op`). Credentials are never
stored in the repo, in config files, or in Airtable.

## Prerequisites

1. **Install the 1Password CLI** (`op`):
   ```bash
   # macOS
   brew install --cask 1password-cli
   ```
   For other platforms see https://developer.1password.com/docs/cli/get-started/

2. **Sign in** (first time, and whenever the session expires):
   ```bash
   op signin
   ```
   Enable the desktop-app integration (1Password → Settings → Developer →
   "Integrate with 1Password CLI") so `op` can unlock via biometrics.

3. **Verify the CLI is installed and authenticated:**
   ```bash
   op --version      # prints the CLI version
   op whoami         # prints the signed-in account; errors if not signed in
   ```

## Credential Retrieval

The skill reads the DealStream credentials at runtime using the verified
1Password item path (confirmed by running `op` directly on 2026-05-21):

```bash
op read "op://Personal/dealstream.com/username"
op read "op://Personal/dealstream.com/password"
```

### 1Password Item (verified 2026-05-21)

| Field            | Value                                              |
|------------------|----------------------------------------------------|
| Vault            | `Personal` (ID `4s5nnkrzqk2exofau5mlmv4ocu`)       |
| Item name        | `dealstream.com` (ID `6lidhvmgp7siixuwmse6faooza`) |
| `username` field | DealStream login email                             |
| `password` field | DealStream login password                          |

### ✅ Vault / item-path reconciliation — RESOLVED 2026-05-21

An earlier draft of this file and `REVAMP_PLAN.md` Step 0 specified
`op://Private/DealStream/username` / `.../password`. **That path is wrong** and
was confirmed wrong on 2026-05-21 when Biffrey ran `op` directly:

- `op vault list` shows the account has exactly one vault, `Personal` — there
  is no `Private` vault, so `op://Private/DealStream/...` cannot resolve.
- `op item list` shows the DealStream login item is named `dealstream.com`
  (in `Personal`), not `DealStream`.
- `op read "op://Personal/dealstream.com/username"` returned a real, non-empty
  value with no error.

The canonical path is therefore `op://Personal/dealstream.com/...`. This has
been propagated to `REVAMP_PLAN.md` Step 0 and `REVAMP_LOOP_PROMPT.md`
(Appendix A Stage 3 and Appendix B). Full evidence:
`_ralph/evidence/s3_op_verification_2026-05-21.md`. Tracked as build-loop
finding **F2** (closed) and blocker **B1** (RESOLVED).

## Failure Behavior — fail loudly, never proceed unauthenticated

If `op` is not installed, not signed in, or the credential item cannot be read,
the overnight-search skill **must fail loudly**: print a clear error that names
the missing or blocked step, exit non-zero, and **stop**. It must never:

- proceed to DealStream unauthenticated — unauthenticated access returns
  incomplete or zero results, silently degrading the search; or
- fall back to cached, blank, or hard-coded credentials.

The skill checks authentication at startup by confirming the runner-provided
`$DEALSTREAM_USERNAME` / `$DEALSTREAM_PASSWORD` are non-empty (Keychain-backed; see
below). It must **never** gate on `op whoami` — under desktop-app integration that
always reports "not signed in" even when credentials are valid. It aborts only if
the credentials themselves are missing/empty.

## Troubleshooting

- **"not signed in" / session expired:** run `op signin` and complete the
  biometric or password prompt.
- **"item not found":** the vault or item name is wrong — see the reconciliation
  section above; list items with `op item list`.
- **`op: command not found`:** the CLI is not installed or not on `PATH`. Install
  it and ensure the Homebrew bin directory is on `PATH` (`/opt/homebrew/bin` on
  Apple Silicon, `/usr/local/bin` on Intel).

## Unattended (scheduled launchd) auth — macOS Keychain  [method as of 2026-06-04]

**Why not `op` for the scheduled run:** the 1Password desktop-app integration only
works while the app is **unlocked and able to surface a biometric prompt**. A
detached launchd/`claude -p` process can't answer that prompt, so `op read` returns
`authorization timeout` (and `op whoami` always reports "not signed in" regardless).
This — combined with the skill formerly gating on `op whoami` — caused the
2026-05-23 → 06-04 dark period where every nightly run aborted at the auth gate.

**Why not a service-account token:** 1Password service accounts (and shared vaults)
are a **Business/Teams** feature. This account is **Individual** (`op account get` →
`Type: INDIVIDUAL`), so service accounts are unavailable.

**Chosen mechanism: the macOS login Keychain.** A launchd LaunchAgent runs as the
user with the login keychain unlocked (whenever the user is logged in), so it reads
secrets **non-interactively — no Touch ID prompt, no 1Password dependency**.

The DealStream credentials are stored as two generic-password items (created with
`-A` so the launchd job reads them without a prompt):

```bash
# one-time install (values sourced from 1Password):
U="$(op read 'op://Personal/dealstream.com/username')"
P="$(op read 'op://Personal/dealstream.com/password')"
security add-generic-password -U -s earnedout-dealstream-username -a dealstream -w "$U" -A -D "EarnedOut DealStream username"
security add-generic-password -U -s earnedout-dealstream-password -a dealstream -w "$P" -A -D "EarnedOut DealStream password"

# read back (this is what the runner does):
security find-generic-password -s earnedout-dealstream-username -w
security find-generic-password -s earnedout-dealstream-password -w
```

`run-overnight-search.sh` resolves these into `$DEALSTREAM_USERNAME` /
`$DEALSTREAM_PASSWORD`, exports them, and the skill authenticates from those env
vars. If the Keychain items are ever missing, the runner falls back to `op read`
(desktop integration, daytime only). **Rotating the DealStream password:** update
1Password, then re-run the two `security add-generic-password -U …` commands above.

1Password (`op`) remains the source of truth and the daytime/manual fallback; the
Keychain is only the headless cache for the scheduled run. (The Keychain items are
unlocked with the login session; if the Mac is fully logged out — not just
screen-locked — the login keychain is locked and the run would fall back to `op`.)
