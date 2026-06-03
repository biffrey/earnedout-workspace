#!/usr/bin/env python3
"""
Resolve an Airtable Business Name to its working folder under Prospects/.

Used by the `process-pending-rescores` runner as a FALLBACK when a row's
"Working Folder Path" field is empty, and by the one-time backfill to propose
mappings for confirmation. The Working Folder Path field is the authoritative
source once populated — this is only a best-effort name matcher.

Usage:
    python3 resolve-working-folder.py "Linguabee LLC"

Output (stdout):
    - exactly one line (an absolute path)  -> a single confident match
    - several lines (absolute paths)       -> ambiguous; caller must disambiguate
    - no output                            -> no match; caller must resolve by hand

Always exits 0. Matching is deliberately conservative: it only reports a folder
that actually contains evaluable documents, and it never invents a path.
"""
from __future__ import annotations
import re
import sys
from pathlib import Path

PROSPECTS_ROOT = Path(
    "/Users/biffreybraxton/Library/CloudStorage/"
    "GoogleDrive-bbraxton@applied-dev.com/My Drive/Investments/Prospects"
)

ALLOWED_EXTS = {".pdf", ".docx", ".doc", ".xlsx", ".xls", ".pptx", ".ppt"}

# Folder names that are organizational, not a company.
NON_COMPANY_FOLDERS = {
    "Prospects", "DRAFTS to share", "Skill sample", "_archive", "_old",
    "Templates", "templates",
}

# Legal suffixes / noise to strip before comparing names.
LEGAL_SUFFIXES = {
    "inc", "llc", "llp", "lp", "ltd", "co", "corp", "corporation", "company",
    "incorporated", "plc", "pllc", "the", "group", "holdings", "partners",
}

MAX_DEPTH = 3  # how deep under Prospects/ a company folder may sit


def normalize(name: str) -> set[str]:
    """Lowercase, strip punctuation and legal suffixes -> set of tokens."""
    cleaned = re.sub(r"[^a-z0-9 ]", " ", name.lower())
    tokens = [t for t in cleaned.split() if t and t not in LEGAL_SUFFIXES]
    return set(tokens)


def has_documents(folder: Path) -> bool:
    for p in folder.rglob("*"):
        if p.is_file() and p.suffix.lower() in ALLOWED_EXTS:
            return True
    return False


def candidate_folders() -> list[Path]:
    out: list[Path] = []
    if not PROSPECTS_ROOT.exists():
        return out
    for path in PROSPECTS_ROOT.rglob("*"):
        if not path.is_dir():
            continue
        rel_depth = len(path.relative_to(PROSPECTS_ROOT).parts)
        if rel_depth > MAX_DEPTH:
            continue
        name = path.name
        if name in NON_COMPANY_FOLDERS or name.startswith(".") or name.startswith("_"):
            continue
        out.append(path)
    return out


def main(argv: list[str]) -> int:
    if len(argv) < 2 or not argv[1].strip():
        return 0
    biz_tokens = normalize(argv[1])
    if not biz_tokens:
        return 0

    matches: list[tuple[int, Path]] = []
    for folder in candidate_folders():
        folder_tokens = normalize(folder.name)
        if not folder_tokens:
            continue
        # Score: how strongly the folder name and business name overlap.
        overlap = biz_tokens & folder_tokens
        if not overlap:
            continue
        # A confident match: one name's tokens are a subset of the other's
        # (e.g. {linguabee} ⊆ {linguabee}), i.e. no contradicting extra tokens.
        subset = folder_tokens <= biz_tokens or biz_tokens <= folder_tokens
        if not subset:
            continue
        if not has_documents(folder):
            continue
        # Prefer deeper (more specific) folders; longer overlap is stronger.
        depth = len(folder.relative_to(PROSPECTS_ROOT).parts)
        matches.append((len(overlap) * 10 + depth, folder))

    if not matches:
        return 0

    matches.sort(key=lambda m: m[0], reverse=True)
    top_score = matches[0][0]
    top = [f for s, f in matches if s == top_score]

    if len(top) == 1:
        print(str(top[0]))
    else:
        for f in top:
            print(str(f))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
