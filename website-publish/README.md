# Publishing the EarnedOut pipeline & reports to smbsteward.com

This bundle puts your live Airtable pipeline dashboard and all your business
reports on smbsteward.com — behind a single password, with no links from the
rest of your site, and with reports re-uploaded automatically whenever your
Mac creates or updates them.

## What ends up where

| Thing | URL |
|---|---|
| Live dashboard | `https://smbsteward.com/SMBSSearch001/` |
| Reports | `https://smbsteward.com/SMBSSearch001/reports/...` |
| PHP relay (server-only) | `https://smbsteward.com/SMBSSearch001/airtable.php` |

Both folders are password-protected with HTTP Basic Auth, both carry a
`noindex` directive, both block directory listings, and the Airtable token
never leaves the server (it lives in `config.php`, which executes server-side).

## Files in this bundle

```
website-publish/
├── README.md                              ← you are here
├── bluehost-upload/                       ← these files get uploaded to Bluehost
│   ├── index.html                         (the dashboard)
│   ├── airtable.php                       (PHP relay)
│   ├── config.php                         (token lives here — placeholder for now)
│   └── .htaccess                          (password + noindex + no listings + no cache)
└── mac-install/                           ← these files install on your Mac
    ├── sync-reports.sh                    (the sync script)
    ├── com.smbsteward.sync.watch.plist    (file-watcher: fires on any change)
    └── com.smbsteward.sync.nightly.plist  (3 AM safety-net catch-up)
```

## Three things you need to gather first

These are the only steps that need your logins. We'll do all of them together
on screen, but here's the list so you know what's coming.

1. **An Airtable Personal Access Token** with scope `data.records:read`,
   limited to the EarnedOut Master Deal Pipeline base.
   Created at: `https://airtable.com/create/tokens`.
2. **An FTP account on Bluehost.** Created in the Bluehost panel under
   "FTP Accounts" / "Hosting → Advanced". This is what the Mac sync uses.
3. **A username and password** for the dashboard's Basic Auth login.
   We set these in Bluehost's "Directory Privacy" panel during the walkthrough.

You do not need to share any of these in chat — they go straight into the
relevant files / panels.

## Walkthrough phases

We'll go through these together on-screen, in order:

### Phase A — Airtable Personal Access Token
Goal: a token string like `patABC123...`. We paste it into `config.php`.

### Phase B — Bluehost FTP account
Goal: a hostname (e.g. `smbsteward.com`), a username, and a password.
We paste them into `sync-reports.sh`.

### Phase C — Upload the dashboard files
We use Bluehost File Manager to create `/public_html/SMBSSearch001/` and
upload the four files in `bluehost-upload/`. File Manager's "Show Hidden
Files" toggle has to be on so `.htaccess` is visible.

### Phase D — Password-protect the folder
Bluehost panel → Directory Privacy → password-protect `/SMBSSearch001/`.
This automatically creates `.htpasswd` at the correct server path and
updates the `.htaccess` we uploaded.

### Phase E — Mac sync install
- Install Homebrew if needed (one command).
- `brew install lftp`.
- Copy `sync-reports.sh` config block: FTP host, user, password.
- Run a manual one-off sync to upload the existing 274 reports.
- Copy both `.plist` files to `~/Library/LaunchAgents/` and `launchctl load`
  each one. After this the watcher and the nightly catch-up are running.

## Verifying it works

- Visit `https://smbsteward.com/SMBSSearch001/` — you get a password prompt;
  after entering the credentials, the dashboard loads with live Airtable data.
- Click any row — the report opens in a new tab.
- Touch a file in `output/reports/` (e.g. `touch some-report.html`) — within
  ~30 seconds, the sync log shows a fresh upload (`~/Library/Logs/smbs-sync.log`).

## Common tasks afterwards

- **Rotate the Airtable token.** Create a new token in Airtable; in Bluehost
  File Manager open `/SMBSSearch001/config.php` and replace the
  `AIRTABLE_TOKEN` value. Save. Revoke the old token in Airtable.
- **Change the dashboard password.** Bluehost panel → Directory Privacy →
  modify the user.
- **Run a manual full sync.** In Terminal:
  `bash ~/published-listing-search/website-publish/mac-install/sync-reports.sh`
- **Pause the auto-sync.** `launchctl unload ~/Library/LaunchAgents/com.smbsteward.sync.watch.plist`
- **Read the sync log.** `tail -f ~/Library/Logs/smbs-sync.log`

## What stays unchanged

- Your in-app Cowork dashboard (`Earnedout Pipeline Dashboard` artifact) is
  not touched. It continues to open local `file://` reports as before.
- Your existing search scripts and Cowork scheduled task are not modified —
  the file-watcher catches anything they write to `output/reports/`.

## Honest caveats

- "Unlisted" + Basic Auth is good for an internal tool but not bulletproof.
  Anyone with the URL and the shared password can see everything. Rotate the
  password if it's ever shared too widely.
- The sync only runs while your Mac is awake. Reports generated while it
  sleeps upload on the next change or the next nightly catch-up after wake.
- Bluehost's panel and Airtable's token screens may have moved slightly
  since my knowledge cutoff (May 2025); the walkthrough verifies live.
