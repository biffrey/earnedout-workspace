# Credentials Setup — 1Password CLI

## Prerequisites

1. **Install 1Password CLI** (`op`):
   ```bash
   brew install --cask 1password-cli
   ```

2. **Sign in** (first time):
   ```bash
   op signin
   ```
   Follow the prompts to authenticate with your 1Password account.

3. **Verify installation:**
   ```bash
   op --version
   op whoami
   ```

## Credential Retrieval

The overnight-search skill retrieves DealStream credentials at runtime using:

```bash
op read "op://Personal/dealstream.com/username"
op read "op://Personal/dealstream.com/password"
```

### Expected 1Password Item

| Field | Value |
|-------|-------|
| Vault | `Personal` |
| Item name | `dealstream.com` |
| Username field | DealStream login email |
| Password field | DealStream login password |

## Failure Behavior

If `op` is not installed or not signed in, the skill will **fail loudly** with a clear error message rather than proceeding without authentication. DealStream searches require valid credentials — unauthenticated access returns incomplete results.

## Troubleshooting

- **"not signed in" error:** Run `op signin` and follow the biometric/password prompt.
- **"item not found" error:** Verify the item exists at the expected vault/path: `op item get dealstream.com --vault Personal`
- **CLI not found:** Ensure `brew install --cask 1password-cli` completed and your shell PATH includes `/usr/local/bin` or the Homebrew equivalent.
