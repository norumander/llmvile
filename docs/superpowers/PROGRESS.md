# v0.1 Implementation Progress

Single source of truth for where v0.1 execution stands. Updated at the end of every task so any agent resuming work (after context clear, session resume, whatever) can pick up without reading the full transcript.

**Current head of `main`:** see `git log -1 --oneline` — always the latest squash-merge commit.
**Last updated:** 2026-04-18 after Task 7 completion.

---

## Execution status

| Task | Status | PR | Notes |
|---|---|---|---|
| 1. Repo infrastructure | ✅ Complete | [#2](https://github.com/norumander/llmvile/pull/2) merged (SHA `cde4c31`) | Spec + quality review passed. Follow-up [#3](https://github.com/norumander/llmvile/issues/3) filed for CHANGELOG compare link. |
| 2. CI workflow | ✅ Complete | [#5](https://github.com/norumander/llmvile/pull/5) merged (SHA `eb7894b`) | Issue [#4](https://github.com/norumander/llmvile/issues/4). Code review caught two latent grep false-positives in plan's YAML (GUT summary line, Godot headless ERROR: warnings) + missing job timeout — fixed on same PR (trust exit codes, added `timeout-minutes: 15`). Check ran RED as expected (no Godot project yet). |
| 3. Branch protection | ✅ Complete | [#7](https://github.com/norumander/llmvile/pull/7) merged (SHA `905b349`) | Issue [#6](https://github.com/norumander/llmvile/issues/6). Branch protection live on `main`: requires `Import + GUT` (strict), linear history, resolved conversations, PR required, no force-push/delete, `enforce_admins: false`. Code review caught hard-coded user path + missing admin-bypass audit tripwire → fixed on same PR. **Admin bypass used** on merge: CI red because no Godot project yet (expected, first infra PR after protection went live). Also: implementer nested the worktree inside main repo; moved with `git worktree move` — gotcha captured below. |
| 4. Godot init + GUT | ✅ Complete | [#9](https://github.com/norumander/llmvile/pull/9) merged (SHA `5e9ae10`) | Issue [#8](https://github.com/norumander/llmvile/issues/8). First non-infra task. CI ran GREEN on first attempt (Import + GUT passed in 19s). Both reviewers ✅ with no blocking issues. Three 🟢 nits deferred: blue-square `icon.svg` placeholder (Godot default robot icon would be no extra effort but plan didn't specify), `art/_missing.png.import` sidecar will auto-appear first time anyone opens the editor (harmless), `run/main_scene="res://scenes/world.tscn"` targets a not-yet-existent scene (plan-sanctioned; headless import just parses). |
| 5. GameRoot autoload | ✅ Complete | [#11](https://github.com/norumander/llmvile/pull/11) merged (SHA `43af10c`) | Issue [#10](https://github.com/norumander/llmvile/issues/10). First TDD task. CI GREEN first attempt (19s). Spec ✅. Code quality ✅ with 3 deferred 🟢 nits: `pop_panel` silently no-ops on unknown panel (could add `assert`), `panel_stack` exposed publicly-mutable (could prefix `_`), no test for the signal-dedupe behavior. Plan's `class_name GameRoot` dropped per plan's own documented fallback (Godot 4.6 makes autoload-name/class-name collision a hard error now). |
| 6. NpcStatus + NpcConfig | ✅ Complete | [#13](https://github.com/norumander/llmvile/pull/13) merged (SHA `ec7337a`) | Issue [#12](https://github.com/norumander/llmvile/issues/12). Hand-wrote `.tres` fixtures (editor unusable locally — Godot 4.6 / GUT incompat). CI GREEN first attempt (14s, 4/4 tests). Spec ✅. Code quality ✅ with a deferred follow-up: both fixtures omit `uid="uid://..."` on the `[gd_resource]` header, so first editor import will auto-generate one and dirty the working tree. Task 17 (NPC configs + placement) should set the pattern of including an explicit `uid=` when creating new `.tres` files. |
| 7. InteractionPanel base | ✅ Complete | [#15](https://github.com/norumander/llmvile/pull/15) merged (SHA `325cc31`) | Issue [#14](https://github.com/norumander/llmvile/issues/14). Trivial 13-line file. CI GREEN first attempt (12s). Combined spec+quality review (scope was too small for two). ✅ across the board. |
| 8. StubDialoguePanel | ⏭ Next | — | |
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

See the Conventions section at the top of `docs/superpowers/plans/2026-04-17-v01-walkable-overworld.md`. Key change: **implementer does NOT merge.** The controller runs reviews and merges.

### Dispatch

- Use `superpowers:subagent-driven-development` to execute each task.
- Dispatch a fresh `general-purpose` subagent per task — do NOT reuse between tasks.
- **Paste the full task text** from the plan into the implementer prompt. Do not make the subagent read the plan file (context budget).
- Default to `haiku` for mechanical tasks (clear spec, 1–2 files). Use `sonnet` when the task touches multiple systems, needs judgment calls, or involves debugging.
- Implementer stops at `gh pr create` and reports DONE. They do NOT run `gh pr merge`.

### Review (order matters: spec then quality)

1. **Spec compliance reviewer** (`general-purpose`, `sonnet`): verifies the code matches the plan — missing, extra, or misinterpreted requirements. Not code-quality.
2. **Code quality reviewer** (`superpowers:code-reviewer`): smells, footguns, hygiene. Only run after spec review is ✅.
3. If either reviewer flags issues, dispatch a fix subagent on the SAME PR, then re-review.

### Merge (controller only, after both reviews ✅)

Run from the main repo directory (not the worktree). Run each command independently — do NOT `&&`-chain, because `gh pr merge --delete-branch` returns exit code 1 on a successful merge when the local branch can't be deleted (worktree holds it):

```bash
cd /Users/normanettedgui/development/test/llmvile
gh pr merge <N> --squash --delete-branch     # add --admin only when CI is expected red
git pull
git worktree remove ../llmvile-issue-<N>
git branch -D issue/<N>-<slug>
git push origin --delete issue/<N>-<slug> 2>/dev/null || true
```

Before dispatching reviews, verify `git worktree list` shows the worktree as a SIBLING of the main repo (not nested inside it). If nested, `git worktree move` first.

`--admin` is ONLY for infra PRs where red CI is expected (Tasks 2 and 3 were the cases). For all real code tasks, CI must stay green; treat red CI as a bug and fix on the PR.

### Post-merge (controller checklist)

After every task merges, the controller MUST update this file so the next session can `/clear` and continue without context:

1. Flip Task N row in **Execution status** to ✅ with PR # + merge SHA; add any noteworthy review findings.
2. Add any new gotchas to **Gotchas learned so far**.
3. Replace the **Next up** section with the next task's specifics (TDD? CI expectations? watch-outs?).
4. Direct-push the PROGRESS.md change to `main` as admin (option 1, decided 2026-04-18). GitHub logs each bypass; that's the audit trail.

The **Resume prompt** at the bottom is a stable one-liner — don't edit it per-task. The per-task details live in **Next up**.

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
- **Godot 4.6 locally vs. 4.3 in CI diverges on two things that will keep biting us.** First: GUT 9.x appears incompatible with Godot 4.6 (fails with `SCRIPT ERROR: Parse Error: The member "Logger" shadows a native class` in `addons/gut/utils.gd`). CI uses 4.3 per `.github/workflows/ci.yml` and is fine. **Verdict: do not run GUT locally on this repo with 4.6 — trust CI.** Second: opening/importing the project with 4.6 generates `.uid` sidecar files (new in 4.4+) and re-writes `.import` files, and `.gitignore` doesn't cover them yet. That's why Task 5's worktree cleanup needed `--force remove`. Near-term fix is a `.gitignore` entry for `*.uid`; for now, force-remove worktrees after merges.
- **Autoload name + `class_name` is a hard error in Godot 4.6** (`Class "GameRoot" hides an autoload singleton`). The plan's code samples all include `class_name Foo` on singletons — drop that line for every autoload we add (GameRoot done in Task 5, watch for it in 11, etc.). The autoload name alone is enough to reference the singleton globally.

## Open questions

- **How should controller PROGRESS.md updates reach `main`?** — **Decided 2026-04-18 (Task 4): option 1** — direct-push as admin, trust the GitHub bypass log as audit trail. Each bypass produces a "Bypassed rule violations for refs/heads/main" entry in the repo's bypass log, which gives us the paper trail without the overhead of a PR-per-progress-update. Revisit if audit volume becomes noisy.

## Next up: Task 8 — `StubDialoguePanel`

- **Character:** TDD. Script + hand-written `.tscn` + GUT tests + `[input]` additions in `project.godot`. Medium-complex.
- **Files:** `scripts/stub_dialogue_panel.gd`, `scenes/panels/stub_dialogue.tscn`, `test/unit/test_stub_dialogue_panel.gd`, `project.godot` (add `interact` action).
- **CI:** must stay GREEN. No `--admin`.
- **Watch-outs:**
  - Plan's Step 4 says "In the editor" — cannot use editor locally. Hand-write the `.tscn`. Godot 4.x `.tscn` format: `[gd_scene load_steps=N format=3]`, `[ext_resource type="Script" path="..." id="1_xxx"]`, then `[node name="..." type="Control"]` with `script = ExtResource("1_xxx")`, nested children as `[node name="..." type="Panel" parent="."]`, etc.
  - **Plan's input-action snippet has a known footgun:** the trailing `; E` inline comment on the `events` line will break the Godot INI parser. Put the comment on its own line or drop it.
  - Plan's `Object(InputEventKey,"keycode":69)` syntax needs verification for Godot 4.3 exact shape. In practice Godot serializes as `Object(InputEventKey,"keycode":69,"physical_keycode":0,...)` with many fields. Minimal-viable form in 4.3 will usually be `Object(InputEventKey,"keycode":69)` but CI will reveal if not.
  - `StubDialoguePanel` extends `InteractionPanel` (merged in Task 7) — the `class_name InteractionPanel` global resolves via the plan-added Task 7 file. No autoload involvement; no collision.
  - The test uses `add_child_autofree` (GUT 9.x API) and `wait_frames(2)` (GUT async) — both standard.
  - The `_unhandled_input` handler responds to both `ui_cancel` and `interact` — the `interact` binding must exist in `project.godot` before the test can trigger it, but the test calls `panel.close()` directly, not via input, so it's fine even if input wiring is imperfect at test time.
  - Sonnet recommended — hand-writing `.tscn` benefits from judgment.
- **Plan reference:** Task 8 at `docs/superpowers/plans/2026-04-17-v01-walkable-overworld.md` (line 976).

## Resume prompt (paste this after `/clear`)

```
Continue v0.1 execution of llmvile (https://github.com/norumander/llmvile).
Read docs/superpowers/PROGRESS.md — it's the source of truth for current
state, workflow, gotchas, and the next task. Then read that task's spec
in docs/superpowers/plans/2026-04-17-v01-walkable-overworld.md and proceed.
```
