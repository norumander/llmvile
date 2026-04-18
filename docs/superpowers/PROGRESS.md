# v0.1 Implementation Progress

Single source of truth for where v0.1 execution stands. Updated at the end of every task so any agent resuming work (after context clear, session resume, whatever) can pick up without reading the full transcript.

**Current head of `main`:** see `git log -1 --oneline` — always the latest squash-merge commit.
**Last updated:** 2026-04-18 — **v0.1.0 shipped.** PR [#48](https://github.com/norumander/llmvile/pull/48) squash-merged (SHA `a7ebc16`), tag `v0.1.0` pushed, tagged Build run 24613670255 ✅ both platforms, [release](https://github.com/norumander/llmvile/releases/tag/v0.1.0) created with macOS `.app` + Windows `.exe` zips attached, milestone [v0.1 Walkable Overworld](https://github.com/norumander/llmvile/milestone/1) closed. Next up: v0.2 art pass.

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
| 8. StubDialoguePanel | ✅ Complete | [#17](https://github.com/norumander/llmvile/pull/17) merged (SHA `54666f5`) | Issue [#16](https://github.com/norumander/llmvile/issues/16). Hand-wrote the `.tscn`. 2 CI iterations: first attempt failed because the plan's `Node.set("config", ...)` in the test helper doesn't work under Godot 4's typed Nodes — implementer fixed by attaching an inline GDScript with `var config: NpcConfig` on the fake NPC. Second CI went green. Code quality review caught `var name` shadowing `Node.name` — fixed (renamed to `display_name`) in a follow-up commit on the same PR. Three deferred 🟢 nits: test helper's runtime-compiled GDScript could be replaced with a named inner-class `FakeNpc extends Node` (cleaner pattern for future panel tests); `show_for` doesn't guard against empty `display_name`; `project.godot` input action uses `keycode` not `physical_keycode` (may surprise non-QWERTY users). |
| 9. NpcEntity | ✅ Complete | [#19](https://github.com/norumander/llmvile/pull/19) merged (SHA `6ea37d0`) | Issue [#18](https://github.com/norumander/llmvile/issues/18). CI GREEN first attempt. Spec ✅ + quality ✅. Two non-blocking quality flags deferred: `$Sprite2D.texture` hard-codes child-node name (fragile if Task 17 renames) — could switch to `@onready var _sprite: Sprite2D = $Sprite2D`; test `test_interact_instantiates_panel_and_emits_signal` leaks the instantiated panel (not `autofree`d) — cheap fix. Also the obvious structural concern: no guard against double-interact — Task 11 (`InteractionSystem`) MUST own that or we push it downstream. |
| 10. PlayerController | ✅ Complete | [#21](https://github.com/norumander/llmvile/pull/21) merged (SHA `f5b8d2a`) | Issue [#20](https://github.com/norumander/llmvile/issues/20). CI GREEN first attempt (18s). Spec+quality combined review ✅. Inline comment + InputEventKey serialization gotchas (previously documented) were both pre-emptively sidestepped. No new nits beyond the standing `uid=` tech-debt. |
| 11. InteractionSystem | ✅ Complete | [#23](https://github.com/norumander/llmvile/pull/23) merged (SHA `30c1ad1`) | Issue [#22](https://github.com/norumander/llmvile/issues/22). First task to modify previously-shipped files (Task 10's Player scene + script). CI GREEN first attempt. Spec+quality combined ✅. Used plan's "clean approach": PlayerController emits `panel_requested(panel)` signal — no UIRoot coupling. |
| 12. UIRoot | ✅ Complete | [#25](https://github.com/norumander/llmvile/pull/25) merged (SHA `066eedb`) | Issue [#24](https://github.com/norumander/llmvile/issues/24). Used plan's Option B (`show_panel_for(panel, npc)`, cascade: `PlayerController.panel_requested` is now `(panel, npc)`). CI GREEN first attempt. Spec+quality combined ✅, zero findings. UIRoot is NOT an autoload — scene node lives in `world.tscn`. |
| 13. Status indicators | ✅ Complete | [#27](https://github.com/norumander/llmvile/pull/27) merged (SHA `67def66`) | Issue [#26](https://github.com/norumander/llmvile/issues/26). Append-only to Task 12's `ui_root.gd` + one node in `.tscn`. CI GREEN first attempt (17s). Combined review ✅. Nits deferred: labels leak when NPCs freed (no despawn in v0.1 so fine); no `register_npc` duplicate-call guard (would double-fire signals); dead `label.set_meta("npc", npc)` kept for plan fidelity. |
| 14. World scene | ✅ Complete | [#29](https://github.com/norumander/llmvile/pull/29) merged (SHA `c55f673`) | Issue [#28](https://github.com/norumander/llmvile/issues/28). Hand-wrote `world.tscn` with editable-children Camera2D inside Player instance. No tests — scene import is the validation. Uncovered a **silent CI regression** (issue [#30](https://github.com/norumander/llmvile/issues/30)) during the CI-log inspection: `player_controller.gd` and `test_npc_entity.gd` had been parse-erroring for ~3 PRs but CI trusted GUT's exit code and missed it. Pre-existing, not caused by Task 14. |
| Fix parse errors + harden CI | ✅ Complete | [#31](https://github.com/norumander/llmvile/pull/31) merged (SHA `c5439b4`) | Issue [#30](https://github.com/norumander/llmvile/issues/30). Typed the two `var panel := ...` lines explicitly. Hardened `.github/workflows/ci.yml` to `set -o pipefail` + `grep -E "Parse error\|Failed to load script"` after import and GUT runs. Now GUT totals show `Passing 23, Risky/Pending 0`. Pipefail omission was caught in review — followed up same PR. |
| 15. Art generation | ✅ Complete | [#33](https://github.com/norumander/llmvile/pull/33) merged (SHA `559fd80`) | Issue [#32](https://github.com/norumander/llmvile/issues/32). PixelLab MCP ran inline from controller session (subagents can't inherit MCP tools). CI GREEN first attempt (15s). Combined spec+quality review ✅. Only south-facing rotations shipped for v0.1; 4-dir sheets + animations are v0.2+ work. Character canvas is 48×48 (PixelLab pads for future animations). Floor/wall extracted from a `create_topdown_tileset` Wang tileset (all-lower + all-upper bboxes). Desk via `create_map_object`. |
| 16. Office tilemap | ✅ Complete | [#35](https://github.com/norumander/llmvile/pull/35) merged (SHA `11af8e7`) | Issue [#34](https://github.com/norumander/llmvile/issues/34). Hand-authored `data/tilesets/office.tres` + Python-encoded `tile_data` PackedInt32Array (16×10 room, perimeter walls, 4 desks, interior floor). Player spawn at (256, 160) lands on floor. CI GREEN first attempt (17s). Combined review ✅. |
| 17. NPC configs + placement | ✅ Complete | [#37](https://github.com/norumander/llmvile/pull/37) merged (SHA `75a5e81`) | Issue [#36](https://github.com/norumander/llmvile/issues/36). Hand-authored 4 `NpcConfig` .tres files (Claude/Codex/Gemini/Spare) + instanced on desks in `world.tscn` with `groups=["npc"]`. CI GREEN first attempt (15s). Combined review ✅. Standing `uid=` tech-debt continued; file follow-up before v0.2. |
| 18. Export presets | ✅ Complete | [#39](https://github.com/norumander/llmvile/pull/39) merged (SHA `37fb37f`) | Issue [#38](https://github.com/norumander/llmvile/issues/38). Hand-authored `export_presets.cfg` (two presets: `macOS` universal, `Windows Desktop` x86_64, both unsigned, bundle id `com.norumander.llmvile`, version `0.1.0`). Reference skeleton pulled from a public Godot 4.3 project (adaliszk/absorboid-game) and trimmed. Removed `export_presets.cfg` from `.gitignore`. CI GREEN first attempt (15s) — but CI only validates import; actual export execution is Task 19's job. Combined review ✅. Local templates never installed; `godot --headless --export-release` not run locally (editor+4.6 blocker). |
| 19. Export build CI | ✅ Complete | [#41](https://github.com/norumander/llmvile/pull/41) merged (SHA `cfd000d`); ETC2-ASTC fix [#43](https://github.com/norumander/llmvile/pull/43) (SHA `3d12a96`) | Issue [#40](https://github.com/norumander/llmvile/issues/40). Matrix workflow — macOS native on `macos-latest`, Windows cross-export on `ubuntu-latest`. First manual dispatch passed Windows but macOS failed with `Cannot export for universal or arm64 if ETC2 ASTC texture format is disabled`; filed [#42](https://github.com/norumander/llmvile/issues/42) + shipped one-line fix ([#43](https://github.com/norumander/llmvile/pull/43)) adding `textures/vram_compression/import_etc2_astc=true` to `project.godot`. Re-dispatched workflow: both jobs ✅ (`llmvile-macOS` + `llmvile-Windows` artifacts uploaded, 30-day retention). Template dir needed branching on `$RUNNER_OS` (macOS = `~/Library/Application Support/Godot/...`, Linux = `~/.local/share/godot/...`) — plan's snippet was Linux-only. |
| 20. Playtest | 🟡 Partial | Fixes [#46](https://github.com/norumander/llmvile/pull/46) merged (SHA `272da01`) | Issue [#44](https://github.com/norumander/llmvile/issues/44). Normid ran a local playtest against Godot 4.3 (not the CI artifact — faster iterate loop). Four visual bugs surfaced ([#45](https://github.com/norumander/llmvile/issues/45)) and got fixed in one PR: (1) `player.tscn` pointed at `_missing.png` instead of `player.png`, (2) `Player` node ordered before `TileMap` so tiles drew on top of player, (3) tilemap used a single layer with desk tiles replacing floor, (4) NPCs sat on the desk tile itself. Fix split tilemap into `layer_0` (floor everywhere) + `layer_1` (walls+desks) and moved NPCs one tile south. Post-merge Build dispatch ✅ both jobs. Full 10-item checklist sign-off still pending — we pivoted straight into Task 21 + planned v0.2 art pass before that happened. |
| 21. v0.1.0 release | ✅ Complete | [#48](https://github.com/norumander/llmvile/pull/48) merged (SHA `a7ebc16`) | Issue [#47](https://github.com/norumander/llmvile/issues/47). CHANGELOG moved into `[0.1.0] - 2026-04-18`, compare link fixed (closes [#3](https://github.com/norumander/llmvile/issues/3)), `project.godot` version → `0.1.0`. Branch required a rebase onto the post-checkpoint main (PROGRESS.md landed ahead of it) before squash-merge. Tag `v0.1.0` pushed → Build run [24613670255](https://github.com/norumander/llmvile/actions/runs/24613670255) auto-ran on tag and succeeded both platforms. [Release v0.1.0](https://github.com/norumander/llmvile/releases/tag/v0.1.0) created with `llmvile-v0.1.0-macos.zip` + `llmvile-v0.1.0-windows.zip` via `gh release create --generate-notes`. v0.1 milestone closed (13/13 issues done). |

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
- **Plan's fake-node test helper pattern (`Node.set("config", ...)`) does NOT work in Godot 4's typed Nodes** — the plan writes `npc.set("config", NpcConfig.new())` on a plain `Node`, but Godot 4 rejects setting arbitrary properties on a typed node that doesn't declare them. Fix: either attach a runtime GDScript with `var config: NpcConfig` (Task 8 implementer's fix — works but is ugly), or define a named inner class `FakeNpc extends Node: var config: NpcConfig` at the top of the test file (cleaner — recommended for Task 9+). Either way: plan code that does `set("<name>", <value>)` on an untyped Node is a red flag during review.
- **Plan's input-action snippet in `project.godot` uses the minimal `Object(InputEventKey,"keycode":69)` form that Godot 4.3 rejects.** Expand to the full serialization form with `"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":69,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null` — that's what Godot writes when the editor saves. **Also consider `physical_keycode` vs `keycode`** — keycode-only bindings surprise AZERTY/Dvorak players. v0.1 uses `keycode`; revisit for i18n polish.

## Open questions

- **How should controller PROGRESS.md updates reach `main`?** — **Decided 2026-04-18 (Task 4): option 1** — direct-push as admin, trust the GitHub bypass log as audit trail. Each bypass produces a "Bypassed rule violations for refs/heads/main" entry in the repo's bypass log, which gives us the paper trail without the overhead of a PR-per-progress-update. Revisit if audit volume becomes noisy.
- **PixelLab MCP workflow** — **Decided 2026-04-18 (Task 15): controller runs inline.** Subagents spawned via `Task` / `superpowers:subagent-driven-development` don't inherit MCP tools, so art-generation tasks must run in the main controller session (generate, download, crop, commit). Subagents remain the flow for code tasks. Noted for any future PixelLab work.

## Next up: v0.2 art pass

### v0.2 art pass (not in the v0.1 plan, user-requested pivot)

**Goal:** regenerate all character + tile art in Gen 4-ish DS-style chibi, with 4-directional idle + walk animations. Placeholder PixelLab south-rotation sprites from Task 15 get replaced.

**Decisions made (2026-04-18):**
- Ship v0.1.0 as "placeholder art" first (above), then start v0.2 as a separate milestone.
- Scope: characters (player + 4 NPCs) AND tiles (floor/wall/desk) both get regen'd — mixing chibi characters over the current wood-plank floor will look off.
- Animations: 4-directional idle + walk for v0.2. No attack/emote animations yet.
- Style: Gen 4-ish DS (Pokémon Diamond/Pearl/Platinum era) — chibi heads, 32×32ish sprites, clear readability at 2× scale.

**Work outline (rough, not final):**
1. Open a v0.2 milestone + umbrella issue.
2. PixelLab `create_character` with a Gen 4 DS style prompt per character, **4 rotations** (south/north/east/west) this time.
3. PixelLab `animate_character` for walk + idle cycles per character per direction.
4. Wire new sprites as `AnimatedSprite2D` (not plain `Sprite2D`) in `scenes/player.tscn` + `scenes/npc.tscn`; update `PlayerController` to flip `AnimatedSprite2D.animation` based on velocity direction.
5. PixelLab `create_topdown_tileset` with Gen 4 DS vibe for floor/wall/desk; extract, re-author `data/tilesets/office.tres`.
6. Playtest artifact → fix → tag `v0.2.0`.

**Watch-outs:**
- Sprite dimensions will likely change. Current art is 48×48 (padded). If new art comes out 32×32 or 64×64, tilemap scale + NPC positions may need adjustment.
- `AnimatedSprite2D` switch is a non-trivial scene+script diff. Don't start until v0.1.0 is tagged — otherwise a tag-day regression dragging v0.2 work with it gets messy.
- PixelLab MCP is main-session-only (subagents can't inherit it). Same constraint as Task 15.

### Housekeeping also pending
- `docs/dev-setup.md` should grow a "local iterate loop" section (run `/Applications/Godot43.app/Contents/MacOS/Godot --path .` directly instead of downloading CI artifacts). Tiny doc PR, captured from the playtest session.
- `.gitignore` should gain `*.uid` before v0.2 kicks off to prevent Godot 4.3's uid-drift on every local import.

## Resume prompt (paste this after `/clear`)

```
Continue v0.1 execution of llmvile (https://github.com/norumander/llmvile).
Read docs/superpowers/PROGRESS.md — it's the source of truth for current
state, workflow, gotchas, and the next task. Then read that task's spec
in docs/superpowers/plans/2026-04-17-v01-walkable-overworld.md and proceed.
```
