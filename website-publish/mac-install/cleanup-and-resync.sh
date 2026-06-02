#!/bin/bash
# One-shot cleanup: remove the nested /reports/public_html/... mess from the
# previous sync, then run the corrected sync so all 274 reports land at the
# right URL (/SMBSSearch001/reports/...).
#
# Usage:  bash ~/published-listing-search/website-publish/mac-install/cleanup-and-resync.sh
set -u

SS="$HOME/published-listing-search/website-publish/mac-install/sync-reports.sh"
[ -f "$SS" ] || { echo "ERROR: $SS not found"; exit 1; }

# Pull credentials directly out of the already-configured sync script so we
# don't ask for them again.
H=$(awk -F'"' '/^SFTP_HOST=/{print $2}' "$SS")
U=$(awk -F'"' '/^SFTP_USER=/{print $2}' "$SS")
P=$(awk -F'"' '/^SFTP_PASS=/{print $2}' "$SS")
[ -n "$H" ] && [ -n "$U" ] && [ -n "$P" ] || { echo "ERROR: could not read FTP creds from $SS"; exit 1; }

echo "==> Removing stale nested upload from previous run (reports/public_html/...)"
lftp -u "$U,$P" -p 21 "ftp://$H" <<LFTP_EOF
set ftp:ssl-allow yes
set ftp:ssl-force false
rm -r -f public_html
bye
LFTP_EOF
echo "    cleanup done (errors are OK if there was nothing to delete)"
echo

echo "==> Running corrected sync"
bash "$SS"
RC=$?

echo
echo "==> Done with exit code $RC"
echo "    A report URL to test in the browser:"
echo "    https://smbsteward.com/SMBSSearch001/reports/name-ridgeline-capital-management-llc-tn/ridgeline-capital-management-llc-report.html"
