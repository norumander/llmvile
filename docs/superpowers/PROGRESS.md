# v0.1 Implementation Progress

Single source of truth for where v0.1 execution stands. Updated at the end of every task so any agent resuming work (after context clear, session resume, whatever) can pick up without reading the full transcript.

**Current head of `main`:** see `git log -1 --oneline` — always the latest squash-merge commit.
**Last updated:** 2026-04-17 after Task 3 completion.

---

## Execution status

| Task | Status | PR | Notes |
|---|---|---|---|
| 1. Repo infrastructure | ✅ Complete | [#2](https://github.com/norumander/llmvile/pull/2) merged (SHA `cde4c31`) | Spec + quality review passed. Follow-up [#3](https://github.com/norumander/llmvile/issues/3) filed for CHANGELOG compare link. |
| 2. CI workflow | ✅ Complete | [#5](https://github.com/norumander/llmvile/pull/5) merged (SHA `eb7894b`) | Issue [#4](https://github.com/norumander/llmvile/issues/4). Code review caught two latent grep false-positives in plan's YAML (GUT summary line, Godot headless ERROR: warnings) + missing job timeout — fixed on same PR (trust exit codes, added `timeout-minutes: 15`). Check ran RED as expected (no Godot project yet). |
| 3. Branch protection | ✅ Complete | [#7](https://github.com/norumander/llmvile/pull/7) merged (SHA `905b349`) | Issue [#6](https://github.com/norumander/llmvile/issues/6). Branch protection live on `main`: requires `Import + GUT` (strict), linear history, resolved conversations, PR required, no force-push/delete, `enforce_admins: false`. Code review caught hard-coded user path + missing admin-bypass audit tripwire → fixed on same PR. **Admin bypass used** on merge: CI red because no Godot project yet (expected, first infra PR after protection went live). Also: implementer nested the worktree inside main repo; moved with `git worktree move` — gotcha captured below. |
| 4. Godot init + GUT | ⏭ Next | — | First non-infra task. CI should run GREEN once this merges. |
| 5. GameRoot autoload | ⏸ Blocked by 4 | — | |
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

Controller merge sequence (copy-paste):
```bash
cd /Users/normanettedgui/development/test/llmvile
gh pr merge <N> --squash --delete-branch     # add --admin when CI is expected red
git pull
git worktree remove ../llmvile-issue-<N>
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

## Open questions (decide before Task 4)

- **How should controller PROGRESS.md updates reach `main`?** Currently direct-pushed as admin (bypassing branch protection). GitHub logs each bypass ("Bypassed rule violations for refs/heads/main: Changes must be made through a pull request"), so there is an audit trail. Three options: (1) keep direct-push, trust bypass log; (2) open a tiny PR per PROGRESS.md update (overhead but consistent); (3) codify the direct-push exception in `docs/dev-setup.md` and keep direct-pushing. Normid is leaning toward (1); decision pending.

## Resume prompt (paste this after context clear)

```
Continue v0.1 execution of llmvile (https://github.com/norumander/llmvile).

State: Tasks 1–3 complete (cde4c31, eb7894b, 905b349). Task 4 (Godot init + GUT) is next. Branch protection is now live on main — require `--admin` on merge when CI is expected red.

Read docs/superpowers/PROGRESS.md first for current status, then read the
relevant Task N section from docs/superpowers/plans/2026-04-17-v01-walkable-overworld.md.

Workflow (effective Task 2+, see Conventions in plan):
- Implementer pushes + opens PR, then STOPS. Does not merge.
- Controller (you) runs spec compliance reviewer → code quality reviewer.
- After both ✅, controller merges from the main repo directory (not the worktree):
  cd /Users/normanettedgui/development/test/llmvile
  gh pr merge <N> --squash --delete-branch
  git pull
  git worktree remove ../llmvile-issue-<N>
  git push origin --delete issue/<N>-<slug> 2>/dev/null || true

Use subagent-driven-development — dispatch fresh general-purpose agents per
task, paste full task text in the prompt. Use superpowers:code-reviewer
for the code quality review stage.

After each task, update docs/superpowers/PROGRESS.md with:
- Task N → ✅ Complete
- PR number + merge SHA
- Any follow-up issues filed
- Any new gotchas

Start with Task 4 (Godot init + GUT addon). This is the first non-infra
task — lands `project.godot`, the Godot project skeleton, and the GUT
testing addon. CI should turn GREEN on this PR (`Import + GUT` check
will actually execute tests). If it doesn't, treat that as a bug and
fix before merging — do NOT use --admin. The `--admin` path is only
for infra PRs where redness is expected, not for real code regressions.
```
