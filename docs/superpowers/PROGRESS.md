# v0.1 Implementation Progress

Single source of truth for where v0.1 execution stands. Updated at the end of every task so any agent resuming work (after context clear, session resume, whatever) can pick up without reading the full transcript.

**Current head of `main`:** see `git log -1 --oneline` — always the latest squash-merge commit.
**Last updated:** 2026-04-18 after Task 4 completion.

---

## Execution status

| Task | Status | PR | Notes |
|---|---|---|---|
| 1. Repo infrastructure | ✅ Complete | [#2](https://github.com/norumander/llmvile/pull/2) merged (SHA `cde4c31`) | Spec + quality review passed. Follow-up [#3](https://github.com/norumander/llmvile/issues/3) filed for CHANGELOG compare link. |
| 2. CI workflow | ✅ Complete | [#5](https://github.com/norumander/llmvile/pull/5) merged (SHA `eb7894b`) | Issue [#4](https://github.com/norumander/llmvile/issues/4). Code review caught two latent grep false-positives in plan's YAML (GUT summary line, Godot headless ERROR: warnings) + missing job timeout — fixed on same PR (trust exit codes, added `timeout-minutes: 15`). Check ran RED as expected (no Godot project yet). |
| 3. Branch protection | ✅ Complete | [#7](https://github.com/norumander/llmvile/pull/7) merged (SHA `905b349`) | Issue [#6](https://github.com/norumander/llmvile/issues/6). Branch protection live on `main`: requires `Import + GUT` (strict), linear history, resolved conversations, PR required, no force-push/delete, `enforce_admins: false`. Code review caught hard-coded user path + missing admin-bypass audit tripwire → fixed on same PR. **Admin bypass used** on merge: CI red because no Godot project yet (expected, first infra PR after protection went live). Also: implementer nested the worktree inside main repo; moved with `git worktree move` — gotcha captured below. |
| 4. Godot init + GUT | ✅ Complete | [#9](https://github.com/norumander/llmvile/pull/9) merged (SHA `5e9ae10`) | Issue [#8](https://github.com/norumander/llmvile/issues/8). First non-infra task. CI ran GREEN on first attempt (Import + GUT passed in 19s). Both reviewers ✅ with no blocking issues. Three 🟢 nits deferred: blue-square `icon.svg` placeholder (Godot default robot icon would be no extra effort but plan didn't specify), `art/_missing.png.import` sidecar will auto-appear first time anyone opens the editor (harmless), `run/main_scene="res://scenes/world.tscn"` targets a not-yet-existent scene (plan-sanctioned; headless import just parses). |
| 5. GameRoot autoload | ⏭ Next | — | First TDD task — write failing test → implement → run → commit. |
| 6. NpcStatus + NpcConfig | ⏸ Blocked by 5 | — | |
| 7. InteractionPanel base | ⏸ Blocked by 5 | — | |
| 8. StubDialoguePanel | ⏸ Blocked by 7 | — | |
| 9. NpcEntity | ⏸ Blocked by 6,7 | — | |
| 10. PlayerController | ⏸ Blocked by 5 | — | |
| 11. InteractionSystem | ⏸ Blocked by 9,10 | — | |
| 12. UIRoot | ⏸ Blocked by 8,11 | — | |
| 13. Status indicators | ⏸ Blocked by 12 | — | |
| 14. World scene | ⏸ Blocked by 10–13 | — | |
| 15. Art generation | ⏸ Blocked by 4 | — | Can run parallel to 5–13 once 4 is done. |
| 16. Office tilemap | ⏸ Blocked by 14,15 | — | |
| 17. NPC configs + placement | ⏸ Blocked by 9,16 | — | |
| 18. Export presets | ⏸ Blocked by 17 | — | |
| 19. Export build CI | ⏸ Blocked by 18 | — | |
| 20. Playtest | ⏸ Blocked by 17,19 | — | |
| 21. v0.1.0 release | ⏸ Blocked by 20 | — | Also fixes issue [#3](https://github.com/norumander/llmvile/issues/3). |

## Workflow (revised from original plan, effective Task 2+)

See the Conventions section at the top of `docs/superpowers/plans/2026-04-17-v01-walkable-overworld.md`. Key change from the original plan:

**Implementer does NOT merge.** Implementer stops at `gh pr create` and reports DONE. Controller runs spec compliance review + code quality review (in that order — never quality first). If reviewers find issues, implementer fixes on the open PR, reviewers re-review. Only when both reviews ✅ does the controller merge.

The plan documents each task with a `Step 9: Merge + clean up` block — those are now implementer-stops-at-step-8 + controller-runs-step-9.

Controller merge sequence (copy-paste) — run each command independently, do NOT `&&`-chain, because `gh pr merge --delete-branch` returns exit code 1 on a successful merge when the local branch can't be deleted (worktree holds it):
```bash
cd /Users/normanettedgui/development/test/llmvile
gh pr merge <N> --squash --delete-branch     # add --admin only when CI is expected red; local-delete may fail non-fatally, that's OK
git pull
git worktree remove ../llmvile-issue-<N>
git branch -D issue/<N>-<slug>               # safe now; worktree gone
git push origin --delete issue/<N>-<slug> 2>/dev/null || true
```

## Gotchas learned so far

- `gh pr merge` from inside a worktree errors with `fatal: 'main' is already used by worktree`. Always `cd` to the main repo first. (Workaround documented in Conventions.)
- `--delete-branch` flag on `gh pr merge` doesn't always delete the remote branch when run from a worktree. Added explicit `git push origin --delete <branch>` as belt-and-suspenders.
- CI won't exist until Task 2 merges. Task 2's own CI run will fail because there's no Godot project yet; that's fine and expected — the workflow file being in the repo is what matters.
- **Plan code samples need the same code-quality scrutiny as implementer output.** Task 2's plan YAML contained `! grep -E "(FAIL|ERROR)" gut.log` which would false-positive on GUT's own "Failing tests: 0" summary line, and `! grep -i "ERROR" import.log` which would false-positive on benign Godot headless `ERROR:` warnings. Fix is to trust the tool's own exit code (`-gexit` for GUT, `--import` for Godot). Pattern: when the plan embeds code, the code reviewer reviews *the plan's code too*, not just fidelity to it.
- **Plan docs can carry my local paths into shipped files.** Task 3's plan had `cd /Users/normanettedgui/...` baked into the `docs/dev-setup.md` example. Implementer copied it verbatim. Code review caught it; replaced with `<path-to-main-llmvile-checkout>`. Treat every hard-coded `/Users/...` in plan code blocks as a smell — replace with placeholders before shipping.
- **Implementer nested the worktree inside the main repo** (`llmvile/llmvile-issue-6` instead of `../llmvile-issue-6`), likely from running `git worktree add` in the wrong CWD. Fixed with `git worktree move llmvile-issue-6 ../llmvile-issue-6` before reviews. For future tasks: always verify `git worktree list` shows sibling paths before dispatching review.
- **Merging after branch protection with red CI requires `--admin`.** Task 3's own PR was the first test — `gh pr merge <N> --squash --admin --delete-branch` works. The `--admin` flag bypasses required checks because `enforce_admins: false`. Going forward, only use `--admin` when the red CI is expected (e.g., pre-Godot-project infra PRs) and record the bypass reason per `docs/dev-setup.md`.
- **`gh pr merge --delete-branch` cannot delete the local branch while its worktree still exists.** The remote merge + remote-branch delete succeeds, but the CLI then exits 1 trying to delete the local branch (`error: cannot delete branch 'issue/N-slug' used by worktree at '...'`). The merge itself is fine. Run each cleanup command independently (don't `&&`-chain), remove the worktree, then `git branch -D` explicitly. Merge sequence in the Conventions section is updated to reflect this.
- **Stale local + remote feature branches from prior tasks remain:** `issue/4-ci-workflow` (Task 2), `issue/6-branch-protection` (Task 3). `--delete-branch` didn't fully clean up on those merges either. Housekeeping: `git branch -D issue/4-ci-workflow issue/6-branch-protection` + `git push origin --delete ...` when convenient. Not blocking — they just clutter `git branch -a`.

## Open questions

- **How should controller PROGRESS.md updates reach `main`?** — **Decided 2026-04-18 (Task 4): option 1** — direct-push as admin, trust the GitHub bypass log as audit trail. Each bypass produces a "Bypassed rule violations for refs/heads/main" entry in the repo's bypass log, which gives us the paper trail without the overhead of a PR-per-progress-update. Revisit if audit volume becomes noisy.

## Resume prompt (paste this after context clear)

```
Continue v0.1 execution of llmvile (https://github.com/norumander/llmvile).

State: Tasks 1–4 complete (cde4c31, eb7894b, 905b349, 5e9ae10). Task 5 (GameRoot autoload) is next — first TDD task. Branch protection live on main; CI now runs against a real Godot project and must stay GREEN (no more --admin bypasses).

Read docs/superpowers/PROGRESS.md first for current status, then read the
Conventions section + Task 5 from docs/superpowers/plans/2026-04-17-v01-walkable-overworld.md.

Workflow (reviewer-gated, effective Task 2+):
- Implementer (general-purpose subagent, usually haiku) pushes + opens PR, then STOPS. Does not merge.
- Controller (you) runs spec compliance reviewer → code quality reviewer (superpowers:code-reviewer).
- If reviewers flag issues, dispatch a fix subagent on the same PR, re-review.
- After both ✅, controller merges from the main repo directory (NOT the worktree). Run each step independently (don't && chain — gh pr merge --delete-branch exits 1 on successful merge if worktree still holds the local branch):
  cd /Users/normanettedgui/development/test/llmvile
  gh pr merge <N> --squash --delete-branch
  git pull
  git worktree remove ../llmvile-issue-<N>
  git branch -D issue/<N>-<slug>
  git push origin --delete issue/<N>-<slug> 2>/dev/null || true

Verify `git worktree list` shows sibling paths (not nested) before dispatching reviews.

Use superpowers:subagent-driven-development. Paste full task text into implementer prompts — do not make them read the plan file.

Task 5 specifics:
- Pure GDScript + GUT tests. TDD is non-negotiable: write failing test first, run to confirm RED, implement minimally, run to confirm GREEN, commit.
- Modifies project.godot (adds [autoload] section for GameRoot). Watch for the plan's own INI gotcha — Godot ini lines don't support inline ; comments on value lines.
- CI must stay GREEN. If it goes red, fix the bug; do NOT --admin.
- Files: scripts/game_root.gd (new), test/unit/test_game_root.gd (new), project.godot (modified).

After Task 5 merges:
- Update PROGRESS.md: Task 5 → ✅, PR # + SHA, new gotchas
- Update this resume prompt to point at Task 6
- Direct-push the PROGRESS.md change as admin (decided option 1)
```
