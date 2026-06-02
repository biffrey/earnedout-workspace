#!/bin/bash
# ============================================================================
# SMB Steward — one-shot Phase E installer (Mac sync)
# ----------------------------------------------------------------------------
# Run from Terminal:
#   bash ~/published-listing-search/website-publish/mac-install/install-mac-sync.sh
#
# What it does (in order):
#   1) Installs Homebrew if missing (you'll be prompted for your Mac password).
#   2) brew installs lftp (the encrypted FTP client).
#   3) Asks for your FTP password and writes it into sync-reports.sh (host and
#      username are pre-filled from what we set up in Bluehost).
#   4) Runs the first sync to backfill all current reports.
#   5) Copies both launchd agents into ~/Library/LaunchAgents and loads them
#      so reports auto-sync on any change, plus a nightly catch-up at 3 AM.
# ============================================================================

set -u

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
say()  { echo -e "${BLUE}==> $*${NC}"; }
ok()   { echo -e "${GREEN}    OK${NC} — $*"; }
warn() { echo -e "${YELLOW}    !  $*${NC}"; }
die()  { echo -e "${RED}    ERROR: $*${NC}" >&2; exit 1; }

INSTALL_DIR="$HOME/published-listing-search/website-publish/mac-install"
SYNC_SCRIPT="$INSTALL_DIR/sync-reports.sh"
WATCH_PLIST="$INSTALL_DIR/com.smbsteward.sync.watch.plist"
NIGHT_PLIST="$INSTALL_DIR/com.smbsteward.sync.nightly.plist"
AGENTS_DIR="$HOME/Library/LaunchAgents"

# Pre-known values from Phase B (FTP account creation)
SFTP_HOST_VAL="ftp.tzt.mlg.mybluehost.me"
SFTP_USER_VAL="reportsync@tzt.mlg.mybluehost.me"
PROTOCOL_VAL="ftp"   # explicit FTPS via port 21; sync-reports.sh negotiates TLS

# On a fresh clone only the .example template is checked in (sync-reports.sh
# is gitignored because it ends up holding the FTP password). Bootstrap by
# copying the template into place if the live file doesn't exist yet.
if [ ! -f "$SYNC_SCRIPT" ]; then
  if [ -f "${SYNC_SCRIPT}.example" ]; then
    cp "${SYNC_SCRIPT}.example" "$SYNC_SCRIPT"
  else
    die "Neither sync-reports.sh nor sync-reports.sh.example found in $INSTALL_DIR"
  fi
fi

# ---- 1. Homebrew ------------------------------------------------------------
say "Checking for Homebrew"
if command -v brew >/dev/null 2>&1; then
  ok "Homebrew already installed: $(brew --prefix)"
else
  warn "Homebrew not installed — installing now (you'll be prompted for your Mac password)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    || die "Homebrew install failed"
  # Add brew to PATH for the rest of this script (Apple Silicon vs Intel)
  if   [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew   ]; then eval "$(/usr/local/bin/brew shellenv)"
  fi
  command -v brew >/dev/null 2>&1 || die "brew still not on PATH after install"
  ok "Homebrew installed"

  # Persist the PATH fix in your shell profile so future Terminal sessions see brew.
  BREW_PREFIX="$(brew --prefix)"
  PROFILE="$HOME/.zprofile"
  if ! grep -qs "brew shellenv" "$PROFILE" 2>/dev/null; then
    echo "eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\"" >> "$PROFILE"
    ok "Added brew to ~/.zprofile for future terminal sessions"
  fi
fi

# ---- 2. lftp ----------------------------------------------------------------
say "Installing lftp"
if command -v lftp >/dev/null 2>&1; then
  ok "lftp already installed: $(lftp --version | head -1)"
else
  brew install lftp || die "brew install lftp failed"
  ok "lftp installed"
fi

# ---- 3. FTP credentials -----------------------------------------------------
say "Filling FTP credentials into sync-reports.sh"
echo
echo "    Host:     $SFTP_HOST_VAL"
echo "    Username: $SFTP_USER_VAL"
printf "    Password: "
stty -echo
IFS= read -r SFTP_PASS_VAL
stty echo
echo
[ -n "$SFTP_PASS_VAL" ] || die "Empty password — aborting"

# sed-replace each placeholder. Use a delimiter unlikely to appear in values.
python3 - "$SYNC_SCRIPT" "$SFTP_HOST_VAL" "$SFTP_USER_VAL" "$SFTP_PASS_VAL" "$PROTOCOL_VAL" <<'PY'
import sys, re
path, host, user, pw, proto = sys.argv[1:6]
with open(path) as f: s = f.read()
def repl(line_re, replacement):
    global s
    s2, n = re.subn(line_re, replacement, s, count=1, flags=re.M)
    if n == 0: raise SystemExit(f"Could not find line matching: {line_re}")
    s = s2
repl(r'^SFTP_HOST=.*$',  f'SFTP_HOST="{host}"')
repl(r'^SFTP_PORT=.*$',  'SFTP_PORT="21"')
repl(r'^SFTP_USER=.*$',  f'SFTP_USER="{user}"')
repl(r'^SFTP_PASS=.*$',  f'SFTP_PASS="{pw}"')
repl(r'^PROTOCOL=.*$',   f'PROTOCOL="{proto}"')
with open(path, 'w') as f: f.write(s)
print("    OK — sync-reports.sh updated")
PY
[ $? -eq 0 ] || die "Failed to update sync-reports.sh"
chmod 700 "$SYNC_SCRIPT"   # tighten perms since it now contains a password

# ---- 4. First sync (backfill) ----------------------------------------------
say "Running the first sync (backfill of all current reports)"
echo "    This may take a few minutes for ~274 files."
echo "    Live log: tail -f ~/Library/Logs/smbs-sync.log"
echo
bash "$SYNC_SCRIPT"
SYNC_RC=$?
if [ $SYNC_RC -eq 0 ]; then
  ok "Backfill sync completed"
else
  warn "Sync exited with code $SYNC_RC — check ~/Library/Logs/smbs-sync.log"
  warn "If it's an FTPS/TLS issue, edit sync-reports.sh and add inside the lftp <<LFTP_EOF block:"
  warn "  set ftp:ssl-allow yes"
  warn "  set ftp:ssl-force true"
  warn "  set ftp:ssl-protect-data true"
fi

# ---- 5. launchd agents ------------------------------------------------------
say "Installing launchd agents (auto-sync on change + nightly catch-up)"
mkdir -p "$AGENTS_DIR"
for plist in "$WATCH_PLIST" "$NIGHT_PLIST"; do
  [ -f "$plist" ] || die "Missing plist: $plist"
  base="$(basename "$plist")"
  dest="$AGENTS_DIR/$base"
  cp "$plist" "$dest"
  # If already loaded, unload first
  launchctl list 2>/dev/null | grep -q "${base%.plist}" && launchctl unload "$dest" 2>/dev/null || true
  launchctl load "$dest" && ok "Loaded $base" || warn "Failed to load $base"
done

# ---- Summary ----------------------------------------------------------------
echo
echo -e "${GREEN}===== Phase E complete =====${NC}"
echo "  Dashboard:  https://smbsteward.com/SMBSSearch001/"
echo "  Reports:    https://smbsteward.com/SMBSSearch001/reports/..."
echo "  Sync log:   tail -f ~/Library/Logs/smbs-sync.log"
echo "  Manual run: bash $SYNC_SCRIPT"
echo
echo "  The watcher will fire whenever anything changes under:"
echo "    ~/published-listing-search/output/reports/"
echo "  Nightly catch-up runs at 3 AM."
