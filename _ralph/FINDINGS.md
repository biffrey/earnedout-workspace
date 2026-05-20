# FINDINGS — open findings from self-tests and verifications

Each finding has a stage, a description, a severity, and gets a `RESOLUTION:`
line once fixed.

## F1 — s1_repo — `git push origin main` fails (IMPROVE)

**Iteration raised:** 1 (2026-05-20)
**Observed:** `git push origin main` and `git ls-remote origin` both fail with:
`Host key verification failed. fatal: Could not read from remote repository.`
The `origin` remote is `git@github.com:biffrey/earnedout-workspace.git` (SSH).
The loop's execution sandbox has no GitHub host key in `known_hosts` and almost
certainly lacks Biffrey's GitHub SSH private key, so it cannot authenticate a
push.

**Impact:** LIMITED. The local commit (`780edfe`) succeeded — the workspace
`.git` lives in Biffrey's real, persistent folder, so loop continuity ("commit
your work so the next iteration can see it") is fully satisfied. Only the GitHub
mirror is stale. The plan's s1 SELF-TEST item "`git log` shows the commit
pushed" cannot be satisfied from inside this sandbox.

**Likely classification:** external blocker — not fixable by the loop itself.
The next RESOLVE phase should move this to `BLOCKERS.md` (per Step 1 rule 1) with
these fix options for Biffrey, then decrement `unresolved_findings` and
increment `open_blockers`:
  - Option A: periodically run `git push` from his own machine, or
  - Option B: provide the sandbox with GitHub auth (host key + deploy key /
    token) so the loop can push, or
  - Option C: accept local-commit-only persistence and treat the s1 "commit
    pushed" sub-check as satisfied-by-local-commit (document the decision).
