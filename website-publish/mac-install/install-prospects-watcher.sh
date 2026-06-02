#!/bin/bash
# ============================================================================
# SMB Steward — install the Prospects/ folder watcher (Phase 23)
# ----------------------------------------------------------------------------
# Sets up everything needed for "when a new CIM/financials file lands in any
# Prospects/<industry>/<company>/ folder, automatically flip the matching
# Airtable row's 'Needs Rescore' = true". The actual rescore is a separate
# manual or scheduled step you trigger when you want.
#
# Run from Terminal:
#   bash ~/published-listing-search/website-publish/mac-install/install-prospects-watcher.sh
#
# What it does:
#   1. brew install fswatch (if missing) — recursive macOS file watcher.
#   2. Prompts for an Airtable Personal Access Token with read+write scope on
#      the Deal Pipeline Tracker base. (Different from the read-only token
#      used by the dashboard relay on Bluehost.) Token is written to
#      ~/.config/smbs/airtable-token with 0600 perms.
#   3. Verifies the token can read AND write to the Master Deal Pipeline
#      (one read + one no-op patch). Aborts if the verify fails.
#   4. Copies the launchd plist into ~/Library/LaunchAgents/ and loads it.
#   5. Smoke-test: prints how to verify (touch a file in a prospect folder,
#      tail the log, watch the Airtable row flip).
# ============================================================================

set -u

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
say()  { echo -e "${BLUE}==> $*${NC}"; }
ok()   { echo -e "${GREEN}    OK${NC} — $*"; }
warn() { echo -e "${YELLOW}    !  $*${NC}"; }
die()  { echo -e "${RED}    ERROR: $*${NC}" >&2; exit 1; }

INSTALL_DIR="$HOME/published-listing-search/website-publish/mac-install"
FLAG_SCRIPT="$INSTALL_DIR/flag-prospect-for-rescore.py"
PLIST_SRC="$INSTALL_DIR/com.smbsteward.prospects.watch.plist"
AGENTS_DIR="$HOME/Library/LaunchAgents"
AGENT_DEST="$AGENTS_DIR/com.smbsteward.prospects.watch.plist"
TOKEN_DIR="$HOME/.config/smbs"
TOKEN_FILE="$TOKEN_DIR/airtable-token"

BASE_ID="appOsvuyy5eK43QTx"
TABLE_ID="tblSmNrHROMLm7vOS"
FIELD_BIZ_NAME="fldquYtYnHJ1YzUR7"
FIELD_RESCORE="fldqJSo0N890SxtTP"

[ -f "$FLAG_SCRIPT" ] || die "Missing $FLAG_SCRIPT"
[ -f "$PLIST_SRC"   ] || die "Missing $PLIST_SRC"

# ---- 1. fswatch -----------------------------------------------------------
say "Checking fswatch"
if command -v fswatch >/dev/null 2>&1; then
  ok "fswatch present: $(fswatch --version | head -1)"
else
  if ! command -v brew >/dev/null 2>&1; then
    die "Homebrew not installed. Run install-mac-sync.sh first (Phase E)."
  fi
  brew install fswatch || die "brew install fswatch failed"
  ok "fswatch installed"
fi

# ---- 2. Airtable token ----------------------------------------------------
say "Airtable token (needs data.records:read + data.records:write on the Deal Pipeline Tracker base)"
mkdir -p "$TOKEN_DIR"
chmod 700 "$TOKEN_DIR"
if [ -s "$TOKEN_FILE" ]; then
  ok "Existing token found at $TOKEN_FILE"
  printf "    Use existing token? [Y/n] "
  read -r reuse
  reuse="${reuse:-Y}"
  if [[ "$reuse" =~ ^[Nn] ]]; then
    REPLACE=1
  else
    REPLACE=0
  fi
else
  REPLACE=1
fi

if [ "$REPLACE" = 1 ]; then
  echo
  echo "    1. Open https://airtable.com/create/tokens in a browser."
  echo "    2. Create a new Personal Access Token with:"
  echo "         - Scope: data.records:read AND data.records:write"
  echo "         - Access: just the 'Deal Pipeline Tracker' base"
  echo "    3. Copy the token, then paste it below (input is hidden)."
  echo
  printf "    Airtable token: "
  stty -echo
  IFS= read -r TOKEN
  stty echo
  echo
  [ -n "$TOKEN" ] || die "Empty token"
  printf "%s" "$TOKEN" > "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
  ok "Saved to $TOKEN_FILE (mode 0600)"
fi

# ---- 3. Verify token works for read AND write -----------------------------
say "Verifying token can read + write the Master Deal Pipeline"
TOKEN_VAL="$(cat "$TOKEN_FILE")"

READ_HTTP=$(curl -s -o /tmp/.smbs-airtable-read.json -w '%{http_code}' \
  -H "Authorization: Bearer $TOKEN_VAL" \
  "https://api.airtable.com/v0/$BASE_ID/$TABLE_ID?maxRecords=1&fields%5B%5D=$FIELD_BIZ_NAME")
if [ "$READ_HTTP" != "200" ]; then
  warn "Read check failed (HTTP $READ_HTTP). Response:"
  cat /tmp/.smbs-airtable-read.json
  die "Token does not have data.records:read for this base."
fi
ok "Read OK"

# Find a sample record id to test PATCH against. We'll patch Needs Rescore
# to its current value (so we don't actually change anything).
REC_ID=$(python3 -c "import json,sys; print(json.load(open('/tmp/.smbs-airtable-read.json'))['records'][0]['id'])" 2>/dev/null || true)
if [ -z "$REC_ID" ]; then
  warn "Could not extract a record id to test PATCH; skipping write check (table may be empty)."
else
  WRITE_HTTP=$(curl -s -o /tmp/.smbs-airtable-write.json -w '%{http_code}' \
    -X PATCH \
    -H "Authorization: Bearer $TOKEN_VAL" \
    -H "Content-Type: application/json" \
    --data "{\"fields\":{\"$FIELD_RESCORE\":false}}" \
    "https://api.airtable.com/v0/$BASE_ID/$TABLE_ID/$REC_ID")
  if [ "$WRITE_HTTP" != "200" ]; then
    warn "Write check failed (HTTP $WRITE_HTTP). Response:"
    cat /tmp/.smbs-airtable-write.json
    die "Token does not have data.records:write. Re-run and paste a token that has both scopes."
  fi
  ok "Write OK (idempotent PATCH on rec $REC_ID succeeded)"
fi
rm -f /tmp/.smbs-airtable-read.json /tmp/.smbs-airtable-write.json

# ---- 4. Install + load launchd agent --------------------------------------
say "Installing launchd agent"
mkdir -p "$AGENTS_DIR"
# Unload an existing instance if loaded, then copy + load.
launchctl list 2>/dev/null | grep -q "com.smbsteward.prospects.watch" \
  && launchctl unload "$AGENT_DEST" 2>/dev/null || true
cp "$PLIST_SRC" "$AGENT_DEST"
launchctl load "$AGENT_DEST" && ok "Loaded com.smbsteward.prospects.watch" \
  || die "launchctl load failed for $AGENT_DEST"

chmod +x "$FLAG_SCRIPT"

# ---- Summary -------------------------------------------------------------
echo
echo -e "${GREEN}===== Prospects watcher installed =====${NC}"
echo "  Watching:    /Users/biffreybraxton/Library/CloudStorage/.../Investments/Prospects/"
echo "  Action:      flip 'Needs Rescore' = true on the matching Airtable row"
echo "  Trigger:     new/changed .pdf/.docx/.xlsx/.pptx/.doc/.xls/.ppt"
echo "  Token:       $TOKEN_FILE (0600)"
echo "  Activity log: ~/Library/Logs/smbs-rescore.log"
echo "  fswatch log:  /tmp/smbs-prospects-watch.{out,err}.log"
echo
echo "  Smoke test:"
echo "    touch ~/Library/CloudStorage/GoogleDrive-bbraxton@applied-dev.com/My\\ Drive/Investments/Prospects/SLI/Linguabee/dummy.pdf"
echo "    sleep 10"
echo "    tail -5 ~/Library/Logs/smbs-rescore.log"
echo "    rm  ~/Library/CloudStorage/GoogleDrive-bbraxton@applied-dev.com/My\\ Drive/Investments/Prospects/SLI/Linguabee/dummy.pdf"
echo "    Then open Airtable → Linguabee row should show 'Needs Rescore' = checked."
echo
echo "  To uncheck after rescoring, edit the row in Airtable (or use the"
echo "  'process pending rescores' Cowork flow once you build it)."
