# v0.1 Implementation Progress

Single source of truth for where v0.1 execution stands. Updated at the end of every task so any agent resuming work (after context clear, session resume, whatever) can pick up without reading the full transcript.

**Current head of `main`:** see `git log -1 --oneline` — always the latest squash-merge commit.
**Last updated:** 2026-04-17 after Task 1 completion.

---

## Execution status

| Task | Status | PR | Notes |
|---|---|---|---|
| 1. Repo infrastructure | ✅ Complete | [#2](https://github.com/norumander/llmvile/pull/2) merged (SHA `cde4c31`) | Spec + quality review passed. Follow-up [#3](https://github.com/norumander/llmvile/issues/3) filed for CHANGELOG compare link. |
| 2. CI workflow | ⏭ Next | — | Will be red until Task 4 lands Godot project. Expected. |
| 3. Branch protection | ⏸ Blocked by 2 | — | |
| 4. Godot init + GUT | ⏸ Blocked by 3 | — | |
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
gh pr merge <N> --squash --delete-branch
git pull
git worktree remove ../llmvile-issue-<N>
git push origin --delete issue/<N>-<slug> 2>/dev/null || true
```

## Gotchas learned so far

- `gh pr merge` from inside a worktree errors with `fatal: 'main' is already used by worktree`. Always `cd` to the main repo first. (Workaround documented in Conventions.)
- `--delete-branch` flag on `gh pr merge` doesn't always delete the remote branch when run from a worktree. Added explicit `git push origin --delete <branch>` as belt-and-suspenders.
- CI won't exist until Task 2 merges. Task 2's own CI run will fail because there's no Godot project yet; that's fine and expected — the workflow file being in the repo is what matters.

## Resume prompt (paste this after context clear)

```
Continue v0.1 execution of llmvile (https://github.com/norumander/llmvile).

State: Task 1 complete (merged as cde4c31). Task 2 is next.

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

Start with Task 2 (CI workflow). It depends on nothing but repo existing.
Note: Task 2's own CI run will be RED because no Godot project exists until
Task 4. That's expected — merge anyway.
```
