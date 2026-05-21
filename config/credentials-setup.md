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

The skill reads the DealStream credentials at runtime using the canonical
1Password item path from `REVAMP_PLAN.md` (Step 0):

```bash
op read "op://Private/DealStream/username"
op read "op://Private/DealStream/password"
```

### Expected 1Password Item (canonical, per REVAMP_PLAN.md)

| Field            | Value                       |
|------------------|-----------------------------|
| Vault            | `Private`                   |
| Item name        | `DealStream`                |
| `username` field | DealStream login email      |
| `password` field | DealStream login password   |

### ⚠️ Vault / item-path reconciliation needed

An earlier version of this file (created 2026-04-16, before the current build
loop) documented a **different** location — `op://Personal/dealstream.com/username`
and `.../password` (vault `Personal`, item `dealstream.com`). The canonical plan
specifies `op://Private/DealStream/...`. These genuinely differ in both the
vault name and the item name.

Before the skill runs in production, confirm where the DealStream credentials
actually live in 1Password and make this file **and** the skill use the path
that resolves:

```bash
op vault list                            # find the real vault name
op item list --vault <vault>             # find the real item name
op item get DealStream --vault Private   # confirm the canonical path resolves
```

If the real item is at `op://Personal/dealstream.com/...`, either (a) move or
alias the item to `op://Private/DealStream/...` so it matches the plan, or
(b) update `REVAMP_PLAN.md` and this file to the real path. Tracked as build-loop
finding **F2**; the s3 SELF-TEST runs `op read "op://Private/DealStream/username"`
and will surface which path is correct.

## Failure Behavior — fail loudly, never proceed unauthenticated

If `op` is not installed, not signed in, or the credential item cannot be read,
the overnight-search skill **must fail loudly**: print a clear error that names
the missing or blocked step, exit non-zero, and **stop**. It must never:

- proceed to DealStream unauthenticated — unauthenticated access returns
  incomplete or zero results, silently degrading the search; or
- fall back to cached, blank, or hard-coded credentials.

The skill checks authentication at startup (`op whoami`, or a trial `op read`)
and aborts immediately if authentication is unavailable rather than continuing.

## Troubleshooting

- **"not signed in" / session expired:** run `op signin` and complete the
  biometric or password prompt.
- **"item not found":** the vault or item name is wrong — see the reconciliation
  section above; list items with `op item list`.
- **`op: command not found`:** the CLI is not installed or not on `PATH`. Install
  it and ensure the Homebrew bin directory is on `PATH` (`/opt/homebrew/bin` on
  Apple Silicon, `/usr/local/bin` on Intel).
