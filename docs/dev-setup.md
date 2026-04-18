# Dev Setup

## Prereqs

- Godot 4.3+ (desktop). Project uses `4.3-stable` in CI.
- `gh` CLI authenticated as the repo owner.
- macOS for exporting `.app`, Windows for exporting `.exe` (CI handles both later).

## Working on an issue

1. Pick an issue and assign yourself.
2. Create a worktree from `origin/main`:
   ```bash
   git worktree add ../llmvile-issue-<N> -b issue/<N>-<slug> origin/main
   cd ../llmvile-issue-<N>
   ```
3. TDD: write a failing test, run it, implement minimally, run again, commit.
4. Push the branch and open the PR with `gh pr create --fill`. **Stop there** — do not merge.
5. Spec compliance review and code quality review gate the merge. See `docs/superpowers/PROGRESS.md` for the full reviewer-gated workflow.
6. After the controller merges and removes the remote branch, clean up locally:
   ```bash
   cd /Users/normanettedgui/development/test/llmvile
   git pull
   git worktree remove ../llmvile-issue-<N>
   ```

## Branch protection

`main` requires:
- PR — no direct pushes from non-admins
- Linear history (squash merges)
- The `Import + GUT` CI check passes
- All PR conversations resolved
- No force pushes, no deletions

Admins (repo owner) can bypass the CI check for infrastructure PRs that legitimately cannot run the check yet (e.g., pre-Godot-project tasks). Use `gh pr merge --admin` sparingly and only when the redness is expected.

## Running tests locally

```bash
godot --headless -s res://addons/gut/gut_cmdln.gd \
    -gdir=res://test/unit -gexit
```
