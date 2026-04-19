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
6. After the controller merges and removes the remote branch, clean up locally (run from the main repo checkout, not the worktree):
   ```bash
   cd <path-to-main-llmvile-checkout>
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

Admins (repo owner) can bypass the CI check for infrastructure PRs that legitimately cannot run the check yet (e.g., pre-Godot-project tasks). Use `gh pr merge --admin` sparingly and only when the redness is expected. When bypassing, record the reason in the PR description and add a one-line note under the task entry in `docs/superpowers/PROGRESS.md` so the audit trail is scannable.

## Running tests locally

```bash
godot --headless -s res://addons/gut/gut_cmdln.gd \
    -gdir=res://test/unit -gexit
```

## Local iterate loop (playtesting)

Run the game directly from your local checkout instead of waiting on a CI artifact:

```bash
# macOS — adjust path if Godot 4.3 is installed elsewhere
/Applications/Godot43.app/Contents/MacOS/Godot --path .
```

First run after a fresh checkout will need an import pass (GDScript + art + tileset resources). If the window is blank on first launch, quit and run the importer twice:

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . --import
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . --import
# GUT's image cache triggers a "restart Godot" message on the first pass; the second pass finishes clean.
```

Why twice: Godot imports resources lazily on first open, and GUT's image cache triggers a one-time "restart required" message that the second pass clears. After that, regular `--path .` launches work normally.

CI artifacts (from the Build workflow) are only needed for release verification — don't reach for them while iterating.

## Known gotchas

### macOS: godot-xterm dylib quarantine

On first checkout, macOS may quarantine the vendored `.framework` inside `addons/godot_xterm/lib/`, causing `pty.fork()` to fail silently with `posix_spawnp: Permission denied`. Clear it with:

```bash
xattr -dr com.apple.quarantine addons/godot_xterm
```

The cleared state persists in-place.

### macOS: transparent terminal loses title bar

Godot 4.3's native subwindow transparency flag currently drops the OS title bar on macOS when applied. The terminal panel ships with an in-panel X close button (top-right corner) as a fallback. Click-outside dismissal also works.
