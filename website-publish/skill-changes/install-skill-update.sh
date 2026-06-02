#!/bin/bash
# Apply the Prospect Evaluation Skill auto-publish + disposition-prompt update
# to biffrey/Prospect-Evaluation-Skill and push.
#
# Run from Terminal:
#   bash ~/published-listing-search/website-publish/skill-changes/install-skill-update.sh
#
# What it does:
#   1. Clones the skill repo to ~/Code/Prospect-Evaluation-Skill (or pulls if it exists).
#   2. Checks out the active branch (claude/plan-business-evaluation-skill-tY1Us — the
#      repo's effective default; main is empty).
#   3. Copies the two updated/new files in (SKILL.md, references/publish-to-pipeline.md).
#   4. Commits and pushes to GitHub.

set -euo pipefail

REPO_URL="git@github.com:biffrey/Prospect-Evaluation-Skill.git"
LOCAL_DIR="$HOME/Code/Prospect-Evaluation-Skill"
BRANCH="claude/plan-business-evaluation-skill-tY1Us"
SRC="$HOME/published-listing-search/website-publish/skill-changes"

# 1. Clone or update local copy
if [ -d "$LOCAL_DIR/.git" ]; then
  echo "==> Pulling existing local clone at $LOCAL_DIR"
  cd "$LOCAL_DIR"
  git fetch origin
  git checkout "$BRANCH"
  git pull origin "$BRANCH"
else
  echo "==> Cloning fresh into $LOCAL_DIR"
  mkdir -p "$(dirname "$LOCAL_DIR")"
  git clone -b "$BRANCH" "$REPO_URL" "$LOCAL_DIR"
  cd "$LOCAL_DIR"
fi

# 2. Copy the updated files in
echo "==> Copying updated SKILL.md + new publish-to-pipeline.md reference"
cp "$SRC/SKILL.md" .claude/skills/prospect-evaluation/SKILL.md
mkdir -p .claude/skills/prospect-evaluation/references
cp "$SRC/references/publish-to-pipeline.md" .claude/skills/prospect-evaluation/references/publish-to-pipeline.md

# 3. Stage & commit (only commit if there's actually a change)
git add .claude/skills/prospect-evaluation/SKILL.md \
        .claude/skills/prospect-evaluation/references/publish-to-pipeline.md

if git diff --cached --quiet; then
  echo "==> No changes to commit (files already up to date)."
  exit 0
fi

git commit -m "prospect-evaluation: add Step 9 auto-publish to EarnedOut pipeline

Adds an EarnedOut-specific publish step that runs after the Step 8
self-check, only when single-mode AND the dashboard infrastructure
is present on this machine.

Workflow:
  A. Copy <slug>-report.html → ~/published-listing-search/output/reports/name-<slug>[-<state>]/
     (launchd file-watcher then auto-syncs to smbsteward.com via FTPS)
  B. Prompt the user to pick a Disposition (Active/Contacted/Maybe Later/
     Revisit for Roll-up/Passed/Dead Link) — deliberate gate so post-review
     'no go' decisions still land in Airtable as Passed/Dead Link.
  C. Search Airtable Master Deal Pipeline (base appOsvuyy5eK43QTx, table
     tblSmNrHROMLm7vOS) for an existing matching row. Create new or update
     existing — never duplicate.
  D. On update: leave Disposition alone unless told otherwise; APPEND to
     Notes; refresh Lead Score and Prospect Eval Report path.
  E. Confirm to user: Airtable record id, local path, public dashboard URL.

Step is fully skipped (silently) when prerequisites aren't met: the
~/published-listing-search/output/reports/ folder is absent, the Airtable
MCP tools aren't available in the session, the user opts out, or batch
mode. Keeps the skill safe for other users while baking in EarnedOut's
specific destination paths and field IDs.

Full procedure lives in references/publish-to-pipeline.md so SKILL.md
stays scannable."

# 4. Push
echo "==> Pushing to GitHub..."
git push origin "$BRANCH"

echo
echo "===== Done ====="
echo "Updated SKILL.md and added references/publish-to-pipeline.md on $BRANCH."
echo "Live in your local repo: $LOCAL_DIR"
echo "GitHub: https://github.com/biffrey/Prospect-Evaluation-Skill/tree/$BRANCH"
echo
echo "Next time you run the Prospect Evaluation skill in single mode,"
echo "Step 9 will trigger automatically if the prerequisites are met."
