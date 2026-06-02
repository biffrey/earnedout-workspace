#!/usr/bin/env python3
"""
SMB Steward — flag a prospect for rescore.

Called by the launchd `fswatch` agent (com.smbsteward.prospects.watch) once per
file event under the Investments/Prospects/ folder. The single argument is the
absolute file path that changed.

What it does:
  1. Filters out irrelevant changes (non-document file types, hidden files,
     temp files, system junk).
  2. Walks UP the path looking for a folder whose name matches an existing
     Business Name in the Master Deal Pipeline Airtable. The deepest match
     wins, so e.g. .../Prospects/SLI/Linguabee/VDR/foo.pdf still flags
     Linguabee even if the file landed in a nested VDR subfolder.
  3. Sets the `Needs Rescore` checkbox on that Airtable row.

Logs everything to ~/Library/Logs/smbs-rescore.log. Exits 0 on every path so
launchd doesn't restart the parent fswatch loop on benign mismatches.

Dependencies: nothing beyond Python 3 (stdlib only). Requires the Airtable PAT
at ~/.config/smbs/airtable-token (chmod 600).
"""
from __future__ import annotations
import datetime
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
LOG_PATH        = Path.home() / "Library" / "Logs" / "smbs-rescore.log"
TOKEN_PATH      = Path.home() / ".config" / "smbs" / "airtable-token"

BASE_ID         = "appOsvuyy5eK43QTx"
TABLE_ID        = "tblSmNrHROMLm7vOS"
FIELD_BIZ_NAME  = "fldquYtYnHJ1YzUR7"   # Business Name
FIELD_RESCORE   = "fldqJSo0N890SxtTP"   # Needs Rescore (checkbox)

# Only files of these types count as "new working material" worth rescoring.
ALLOWED_EXTS = {".pdf", ".docx", ".doc", ".xlsx", ".xls", ".pptx", ".ppt"}

# Folder names that should never be treated as a "company" candidate.
NON_COMPANY_FOLDERS = {
    "Prospects", "DRAFTS to share", "Skill sample", "_archive", "_old",
    "Templates", "templates",
}

# Walk at most this far up looking for a matching company folder.
MAX_PARENT_DEPTH = 4

# ---------------------------------------------------------------------------

def log(msg: str) -> None:
    LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    with LOG_PATH.open("a") as f:
        f.write(f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S}  {msg}\n")


def airtable_get_token() -> str | None:
    if not TOKEN_PATH.exists():
        log(f"ERROR: token file missing at {TOKEN_PATH}; skipping")
        return None
    token = TOKEN_PATH.read_text().strip()
    if not token:
        log("ERROR: token file is empty; skipping")
        return None
    return token


def airtable_search(token: str, company: str) -> list[dict]:
    """Return matching Airtable records (max 5) for a company name."""
    # Use SEARCH() rather than = so partial matches work ("Linguabee" → "Linguabee LLC").
    # Escape double quotes in the query string.
    safe = company.replace('"', '\\"')
    formula = f'SEARCH(LOWER("{safe.lower()}"),LOWER({{Business Name}}))'
    params = urllib.parse.urlencode({
        "filterByFormula": formula,
        "maxRecords": "5",
        "fields[]": FIELD_BIZ_NAME,
    }, doseq=True)
    url = f"https://api.airtable.com/v0/{BASE_ID}/{TABLE_ID}?{params}"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            data = json.loads(r.read())
        return data.get("records", [])
    except urllib.error.HTTPError as e:
        log(f"ERROR: Airtable search HTTP {e.code} for '{company}': {e.read()[:200]!r}")
        return []
    except Exception as e:
        log(f"ERROR: Airtable search failed for '{company}': {e}")
        return []


def airtable_flag(token: str, rec_id: str) -> bool:
    body = json.dumps({"fields": {FIELD_RESCORE: True}}).encode()
    url = f"https://api.airtable.com/v0/{BASE_ID}/{TABLE_ID}/{rec_id}"
    req = urllib.request.Request(url, data=body, method="PATCH", headers={
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    })
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            json.loads(r.read())
        return True
    except urllib.error.HTTPError as e:
        log(f"ERROR: Airtable PATCH HTTP {e.code} for {rec_id}: {e.read()[:200]!r}")
        return False
    except Exception as e:
        log(f"ERROR: Airtable PATCH failed for {rec_id}: {e}")
        return False


def candidate_folders(fpath: Path) -> list[str]:
    """Walk up from the file, returning ancestor folder names worth testing."""
    out: list[str] = []
    p = fpath.parent
    for _ in range(MAX_PARENT_DEPTH):
        if p.parent == p:           # hit /
            break
        name = p.name
        if name in NON_COMPANY_FOLDERS or name.startswith("."):
            p = p.parent
            continue
        out.append(name)
        if name == "Prospects":     # don't walk above Prospects/
            break
        p = p.parent
    return out


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        return 0
    fpath = Path(argv[1])

    # Filter on file type.
    if fpath.suffix.lower() not in ALLOWED_EXTS:
        return 0
    if fpath.name.startswith("."):
        return 0
    if fpath.name.startswith("~$"):  # MS Office lockfile
        return 0
    if "/.~lock." in str(fpath):     # LibreOffice lockfile
        return 0

    token = airtable_get_token()
    if not token:
        return 0

    candidates = candidate_folders(fpath)
    if not candidates:
        log(f"no candidate company folder for {fpath}")
        return 0

    # Try deepest folder first (most specific). First match wins.
    for company in candidates:
        records = airtable_search(token, company)
        if not records:
            continue
        if len(records) > 1:
            names = [r.get("fields", {}).get("Business Name", "?") for r in records]
            log(f"multiple matches for '{company}': {names}; picking first ({records[0]['id']})")
        rec = records[0]
        rec_id = rec["id"]
        biz_name = rec.get("fields", {}).get("Business Name", "?")
        if airtable_flag(token, rec_id):
            log(f"flagged '{biz_name}' ({rec_id}) — trigger: {fpath.name} (matched folder '{company}')")
        return 0

    log(f"no Airtable match for any of {candidates} — file: {fpath}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
