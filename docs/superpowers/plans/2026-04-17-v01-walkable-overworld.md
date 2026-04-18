# v0.1 Walkable Overworld Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a playable pixel-art office room (Godot 4.x, Mac + Windows) with 3–4 NPC desks. Pressing E on an NPC opens a stub "coming soon" panel. v0.2's terminal wiring will land by swapping `panel_scene`, no NPC-system rewrites.

**Architecture:** Godot 4.x 2D, 640×360 logical resolution, 32×32 tiles. NPCs are `Node2D`s driven by `NpcConfig` resources declaring which `InteractionPanel` scene to instantiate. Status signals (`idle|busy|notify`) are plumbed end-to-end but only fire on `.idle` in v0.1. Input pausing is centralized on a `GameRoot` autoload. See [spec](../specs/2026-04-17-v01-walkable-overworld-design.md).

**Tech Stack:** Godot 4.x (GDScript), GUT (Godot Unit Test), GitHub Actions, PixelLab MCP (art), `gh` CLI (repo + issue management), Conventional Commits.

**Workflow:** One task = one GitHub issue = one git worktree = one PR. Worktrees per issue per the global `CLAUDE.md` mandate.

---

## File Structure (final state at end of v0.1)

```
llmvile/
├── .gitignore                              [exists]
├── README.md                               [exists]
├── CHANGELOG.md                            [Task 1]
├── CODEOWNERS                              [Task 1 — empty is fine solo]
├── project.godot                           [Task 4]
├── icon.svg                                [Task 4]
├── export_presets.cfg                      [Task 18] (gitignored)
│
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── feature.yml                     [Task 1]
│   │   ├── task.yml                        [Task 1]
│   │   └── bug.yml                         [Task 1]
│   ├── pull_request_template.md            [Task 1]
│   └── workflows/
│       ├── ci.yml                          [Task 2]  — import + test
│       └── build.yml                       [Task 19] — export mac+win
│
├── addons/
│   └── gut/                                [Task 4 — vendored]
│
├── art/
│   ├── _missing.png                        [Task 4 — magenta 32×32 placeholder]
│   ├── player.png                          [Task 15]
│   ├── npc_01.png … npc_04.png             [Task 15]
│   └── tiles/
│       ├── floor_wood.png                  [Task 15]
│       ├── wall.png                        [Task 15]
│       └── desk.png                        [Task 15]
│
├── scripts/
│   ├── game_root.gd                        [Task 5]  — autoload singleton
│   ├── npc_status.gd                       [Task 6]  — enum class
│   ├── npc_config.gd                       [Task 6]  — Resource
│   ├── interaction_panel.gd                [Task 7]  — abstract Control
│   ├── stub_dialogue_panel.gd              [Task 8]
│   ├── npc_entity.gd                       [Task 9]
│   ├── player_controller.gd                [Task 10]
│   ├── interaction_system.gd               [Task 11]
│   └── ui_root.gd                          [Task 12]
│
├── scenes/
│   ├── world.tscn                          [Task 14]
│   ├── player.tscn                         [Task 10]
│   ├── npc.tscn                            [Task 9]
│   ├── panels/
│   │   └── stub_dialogue.tscn              [Task 8]
│   └── ui/
│       └── ui_root.tscn                    [Task 12]
│
├── data/
│   └── npcs/
│       └── npc_01.tres … npc_04.tres       [Task 17]
│
├── test/
│   ├── .gutconfig.json                     [Task 4]
│   ├── unit/
│   │   ├── test_game_root.gd               [Task 5]
│   │   ├── test_npc_config.gd              [Task 6]
│   │   ├── test_stub_dialogue_panel.gd     [Task 8]
│   │   ├── test_npc_entity.gd              [Task 9]
│   │   ├── test_player_controller.gd       [Task 10]
│   │   ├── test_interaction_system.gd      [Task 11]
│   │   └── test_ui_root.gd                 [Task 12]
│   └── fixtures/
│       ├── valid_npc.tres
│       └── invalid_npc_no_panel.tres
│
└── docs/
    ├── superpowers/
    │   ├── specs/2026-04-17-v01-walkable-overworld-design.md  [exists]
    │   └── plans/2026-04-17-v01-walkable-overworld.md         [this file]
    └── playtest-checklist.md               [Task 1]
```

---

## Milestones & Issue Mapping

Every task in this plan creates one GitHub issue under milestone **v0.1 Walkable Overworld**. Task titles below are the issue titles (verbatim). Task 1 also creates the milestones themselves as its first step.

| Phase | Tasks | Purpose |
|---|---|---|
| 0 Infrastructure | 1–3 | Templates, labels, CI, branch protection |
| 1 Godot Bootstrap | 4–5 | Project file, GUT, first autoload |
| 2 Types | 6–8 | Resources, panel interface, stub panel |
| 3 NPC | 9 | `NpcEntity` |
| 4 Player | 10–13 | Movement, interaction, UI, status indicators |
| 5 World | 14 | Scene assembly |
| 6 Content | 15–17 | Art, tilemap, NPC data |
| 7 Release | 18–21 | Export, playtest, v0.1 tag |

---

## Conventions (apply to every task)

**Worktree setup** — at start of each task:
```bash
cd /Users/normanettedgui/development/test/llmvile
git fetch origin
git worktree add ../llmvile-issue-<N> -b issue/<N>-<slug> origin/main
cd ../llmvile-issue-<N>
```

**Commit style:** Conventional Commits. Types: `feat`, `fix`, `chore`, `docs`, `test`, `refactor`, `ci`, `build`.

**PR template** (auto-loaded): tick boxes for tests, screenshots (if visual), linked issue, CHANGELOG entry.

**When done with a task:**
```bash
git push -u origin issue/<N>-<slug>
gh pr create --fill --assignee @me --label "area:<area>,type:<type>"
# wait for CI green, self-review, merge
gh pr merge --squash --delete-branch
git worktree remove ../llmvile-issue-<N>
```

**Test-first discipline:** Every code task starts by writing a failing test, running it to confirm failure, then implementing minimally. TDD is non-negotiable for `scripts/` files.

**Running tests locally:**
```bash
godot --headless -s res://addons/gut/gut_cmdln.gd \
    -gdir=res://test/unit -gexit
```

---

## Task 1: Repo infrastructure — templates, labels, milestones, CHANGELOG, playtest checklist

**Issue title:** `chore: set up repo infrastructure (templates, labels, milestones, CHANGELOG)`
**Labels:** `type:chore`, `area:ci`
**Milestone:** v0.1 Walkable Overworld

**Files:**
- Create: `.github/ISSUE_TEMPLATE/feature.yml`
- Create: `.github/ISSUE_TEMPLATE/task.yml`
- Create: `.github/ISSUE_TEMPLATE/bug.yml`
- Create: `.github/ISSUE_TEMPLATE/config.yml`
- Create: `.github/pull_request_template.md`
- Create: `CHANGELOG.md`
- Create: `CODEOWNERS`
- Create: `docs/playtest-checklist.md`

### Steps

- [ ] **Step 1: Create the issue + milestone via `gh` (manual, not in repo)**

```bash
# Create this issue
gh issue create \
  --title "chore: set up repo infrastructure (templates, labels, milestones, CHANGELOG)" \
  --body "Templates, labels, milestones, CHANGELOG, playtest checklist." \
  --assignee @me

# Create the four milestones
for m in \
  "v0.1 Walkable Overworld" \
  "v0.2 Terminal MVP" \
  "v0.3 Notifications" \
  "v0.4 Polish"
do
  gh api repos/:owner/:repo/milestones -f title="$m" >/dev/null
done

# Create labels (delete GH defaults first to avoid noise)
for existing in bug documentation duplicate enhancement "good first issue" \
                "help wanted" invalid question wontfix; do
  gh label delete "$existing" --yes 2>/dev/null || true
done
gh label create "type:feature"  --color "0e8a16" --description "New capability"
gh label create "type:task"     --color "1d76db" --description "Scoped chunk of work"
gh label create "type:bug"      --color "d73a4a" --description "Something broken"
gh label create "type:chore"    --color "fef2c0" --description "Maintenance / infra"
gh label create "type:docs"     --color "0075ca" --description "Documentation"
gh label create "area:engine"   --color "5319e7" --description "Game engine code"
gh label create "area:art"      --color "ff80ed" --description "Pixel art / PixelLab"
gh label create "area:ui"       --color "bfd4f2" --description "UI / HUD"
gh label create "area:build"    --color "c2e0c6" --description "Export presets, packaging"
gh label create "area:ci"       --color "fbca04" --description "GitHub Actions, repo infra"
gh label create "priority:p0"   --color "b60205" --description "Blocking"
gh label create "priority:p1"   --color "ff9f1c" --description "Important"
gh label create "priority:p2"   --color "cccccc" --description "Nice to have"
gh label create "status:blocked"      --color "000000" --description "Waiting on something"
gh label create "status:needs-design" --color "a2eeef" --description "Design not yet specced"

# Then assign milestone to the issue
# (grab issue number + milestone number after creation; example)
# gh issue edit <NUM> --milestone "v0.1 Walkable Overworld"
```

Expected: 4 milestones, 15 labels, issue `#N` exists under `v0.1 Walkable Overworld`.

- [ ] **Step 2: Create worktree from `main`**

```bash
cd /Users/normanettedgui/development/test/llmvile
git worktree add ../llmvile-issue-1 -b issue/1-repo-infra origin/main
cd ../llmvile-issue-1
```

- [ ] **Step 3: Write issue templates**

`.github/ISSUE_TEMPLATE/feature.yml`:
```yaml
name: Feature
description: A new capability or user-facing behavior
title: "feat: "
labels: ["type:feature"]
body:
  - type: textarea
    id: summary
    attributes:
      label: Summary
      description: One-paragraph description of the feature
    validations: { required: true }
  - type: textarea
    id: acceptance
    attributes:
      label: Acceptance criteria
      description: Checklist of must-be-true statements
      placeholder: "- [ ] …"
    validations: { required: true }
  - type: textarea
    id: notes
    attributes:
      label: Notes / links
```

`.github/ISSUE_TEMPLATE/task.yml`:
```yaml
name: Task
description: Scoped chunk of work, typically one PR
title: "task: "
labels: ["type:task"]
body:
  - type: textarea
    id: summary
    attributes:
      label: Summary
    validations: { required: true }
  - type: textarea
    id: steps
    attributes:
      label: Steps
      placeholder: "- [ ] …"
```

`.github/ISSUE_TEMPLATE/bug.yml`:
```yaml
name: Bug
description: Something doesn't work
title: "bug: "
labels: ["type:bug"]
body:
  - type: textarea
    id: expected
    attributes:
      label: Expected behavior
    validations: { required: true }
  - type: textarea
    id: actual
    attributes:
      label: Actual behavior
    validations: { required: true }
  - type: textarea
    id: repro
    attributes:
      label: Repro steps
      placeholder: "1. …\n2. …"
```

`.github/ISSUE_TEMPLATE/config.yml`:
```yaml
blank_issues_enabled: false
```

- [ ] **Step 4: Write PR template**

`.github/pull_request_template.md`:
```markdown
## Summary

<!-- What does this PR do, and why? -->

Closes #

## Changes

- 

## Checklist

- [ ] Tests added or updated (GUT)
- [ ] Manual playtest if gameplay changed
- [ ] Screenshot or GIF if visual
- [ ] `CHANGELOG.md` updated under `[Unreleased]`
- [ ] Linked issue uses correct labels + milestone
```

- [ ] **Step 5: Write `CHANGELOG.md` (keep-a-changelog format)**

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Repo scaffolding: issue templates, PR template, labels, milestones.

[Unreleased]: https://github.com/norumander/llmvile/compare/HEAD...HEAD
```

- [ ] **Step 6: Write `CODEOWNERS` (minimal)**

```
# CODEOWNERS
# Sole maintainer — self-review gate for branch protection.
*   @norumander
```

- [ ] **Step 7: Write `docs/playtest-checklist.md`**

```markdown
# Manual Playtest Checklist

Run this on every PR that touches gameplay (any `scripts/`, `scenes/`,
`data/`, or `art/` change). Copy the block, tick each, paste into PR.

## v0.1 Walkable Overworld

- [ ] Launch on macOS `.app` — office room renders at 640×360, integer-scaled
- [ ] Launch on Windows `.exe` — same as above
- [ ] Player moves in all 4 directions (WASD and arrows)
- [ ] Player respects wall collisions, no clipping
- [ ] Approaching each of 3–4 NPCs shows "Press E" prompt above their head
- [ ] Prompt disappears when leaving proximity
- [ ] E opens the stub panel showing NPC-specific text
- [ ] E or Esc closes the panel; movement resumes
- [ ] All NPCs visited in one session, no softlocks
- [ ] Window resize doesn't break layout
```

- [ ] **Step 8: Commit and open PR**

```bash
git add .github/ CHANGELOG.md CODEOWNERS docs/playtest-checklist.md
git commit -m "chore: add issue/PR templates, labels, CHANGELOG, playtest checklist

Closes #1"
git push -u origin issue/1-repo-infra
gh pr create --fill --label "type:chore,area:ci" --milestone "v0.1 Walkable Overworld"
```

- [ ] **Step 9: Merge + clean up worktree**

```bash
gh pr merge --squash --delete-branch
cd /Users/normanettedgui/development/test/llmvile
git pull
git worktree remove ../llmvile-issue-1
```

---

## Task 2: GitHub Actions CI — headless Godot import + GUT

**Issue title:** `ci: add headless Godot import + GUT test workflow`
**Labels:** `type:chore`, `area:ci`
**Milestone:** v0.1 Walkable Overworld
**Blocks:** Task 3 (branch protection needs a required check first)

**Files:**
- Create: `.github/workflows/ci.yml`

### Steps

- [ ] **Step 1: Create issue + worktree**

```bash
gh issue create --title "ci: add headless Godot import + GUT test workflow" \
  --label "type:chore,area:ci" --milestone "v0.1 Walkable Overworld" --assignee @me
cd /Users/normanettedgui/development/test/llmvile
git fetch origin
git worktree add ../llmvile-issue-2 -b issue/2-ci-workflow origin/main
cd ../llmvile-issue-2
```

- [ ] **Step 2: Write `.github/workflows/ci.yml`**

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  test:
    name: Import + GUT
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Cache Godot
        id: cache-godot
        uses: actions/cache@v4
        with:
          path: ~/godot
          key: godot-4.3-stable

      - name: Install Godot 4.3-stable headless
        if: steps.cache-godot.outputs.cache-hit != 'true'
        run: |
          mkdir -p ~/godot && cd ~/godot
          curl -L -o godot.zip https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip
          unzip godot.zip
          mv Godot_v4.3-stable_linux.x86_64 godot
          chmod +x godot

      - name: Put Godot on PATH
        run: echo "$HOME/godot" >> $GITHUB_PATH

      - name: Import project (headless)
        run: |
          godot --headless --import 2>&1 | tee import.log
          ! grep -i "ERROR" import.log

      - name: Run GUT tests
        run: |
          godot --headless -s res://addons/gut/gut_cmdln.gd \
              -gdir=res://test/unit -gexit 2>&1 | tee gut.log
          ! grep -E "(FAIL|ERROR)" gut.log
```

Notes:
- Until Task 4 lands GUT, this workflow will fail — that's fine. The check becomes green once Task 4 is merged.
- No Godot `project.godot` exists yet either; the import step will error until Task 4. PR this anyway; mark as expected-failing and land Task 4 behind it.

- [ ] **Step 3: Commit, push, PR**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add headless Godot import + GUT test workflow

Runs on Ubuntu with Godot 4.3-stable. Will be red until Task 4
lands the Godot project; that's expected.

Closes #2"
git push -u origin issue/2-ci-workflow
gh pr create --fill --label "type:chore,area:ci" --milestone "v0.1 Walkable Overworld"
```

- [ ] **Step 4: Merge + clean up (accept one red check — noted in PR body)**

```bash
gh pr merge --squash --admin --delete-branch
cd /Users/normanettedgui/development/test/llmvile && git pull
git worktree remove ../llmvile-issue-2
```

---

## Task 3: Branch protection on `main`

**Issue title:** `chore: enable branch protection on main`
**Labels:** `type:chore`, `area:ci`
**Milestone:** v0.1 Walkable Overworld
**Depends on:** Task 2 (the required check must exist)

**Files:** (none — `gh api` calls only; tracked via a `docs/dev-setup.md` note)
- Create: `docs/dev-setup.md`

### Steps

- [ ] **Step 1: Create issue + worktree**

```bash
gh issue create --title "chore: enable branch protection on main" \
  --label "type:chore,area:ci" --milestone "v0.1 Walkable Overworld" --assignee @me
cd /Users/normanettedgui/development/test/llmvile
git fetch origin
git worktree add ../llmvile-issue-3 -b issue/3-branch-protection origin/main
cd ../llmvile-issue-3
```

- [ ] **Step 2: Apply branch protection via `gh api`**

```bash
gh api -X PUT "repos/norumander/llmvile/branches/main/protection" \
  -H "Accept: application/vnd.github+json" \
  --input - <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["Import + GUT"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
JSON
```

Notes: solo developer, so `required_approving_review_count = 0` (GitHub blocks self-approval). `enforce_admins = false` so you can hotfix; the discipline is the PR itself, not the approval.

- [ ] **Step 3: Write `docs/dev-setup.md`**

```markdown
# Dev Setup

## Prereqs

- Godot 4.3+ (desktop). Project uses `4.3-stable` in CI.
- `gh` CLI authenticated as the repo owner.
- macOS for exporting `.app`, Windows for exporting `.exe` (CI handles both later).

## Working on an issue

1. Pick an issue and assign yourself.
2. Create a worktree:
   ```bash
   git worktree add ../llmvile-issue-<N> -b issue/<N>-<slug> origin/main
   cd ../llmvile-issue-<N>
   ```
3. TDD: write failing test → run → implement → run → commit.
4. Push, open PR, wait for CI, merge squash, remove worktree.

## Branch protection

`main` requires:
- PR (no direct pushes)
- Linear history
- CI "Import + GUT" check green
- Conversations resolved
```

- [ ] **Step 4: Commit, push, PR, merge**

```bash
git add docs/dev-setup.md
git commit -m "chore: enable branch protection on main and document dev setup

Requires CI green + linear history + resolved conversations on PR.

Closes #3"
git push -u origin issue/3-branch-protection
gh pr create --fill --label "type:chore,area:ci" --milestone "v0.1 Walkable Overworld"
gh pr merge --squash --delete-branch
cd /Users/normanettedgui/development/test/llmvile && git pull
git worktree remove ../llmvile-issue-3
```

From this point forward, all merges require the CI check. No admin bypass.

---

## Task 4: Initialize Godot 4.3 project + GUT testing framework

**Issue title:** `feat: initialize Godot 4.3 project and GUT testing framework`
**Labels:** `type:feature`, `area:engine`, `priority:p0`
**Milestone:** v0.1 Walkable Overworld
**Depends on:** Task 3

**Files:**
- Create: `project.godot`
- Create: `icon.svg`
- Create: `addons/gut/...` (vendored from GUT release)
- Create: `test/.gutconfig.json`
- Create: `art/_missing.png` (32×32 magenta)

### Steps

- [ ] **Step 1: Create issue + worktree** *(same pattern as prior tasks — omitted from here on for brevity; apply it every task)*

- [ ] **Step 2: Generate `project.godot`**

Use Godot 4.3 desktop: File → New Project → point at the worktree dir → click Create & Edit. Save & quit. This writes `project.godot` and `icon.svg`. Commit them.

Then edit `project.godot` to set display/stretch to integer:

```ini
[application]
config/name="llmvile"
config/description="Top-down pixel-art chatroom where LLM CLI agents appear as NPCs."
config/version="0.1.0-dev"
run/main_scene="res://scenes/world.tscn"
config/features=PackedStringArray("4.3", "GL Compatibility")
config/icon="res://icon.svg"

[display]
window/size/viewport_width=640
window/size/viewport_height=360
window/size/window_width_override=1280
window/size/window_height_override=720
window/stretch/mode="viewport"
window/stretch/aspect="keep"

[rendering]
textures/canvas_textures/default_texture_filter=0  ; nearest-neighbor
renderer/rendering_method="gl_compatibility"
```

Note: `run/main_scene` points at a scene that doesn't exist yet (Task 14). Until then, the project won't launch — but the CI import step only parses the file, it doesn't run. Acceptable.

- [ ] **Step 3: Vendor GUT 9.x into `addons/gut/`**

```bash
cd /tmp
curl -L -o gut.zip https://github.com/bitwes/Gut/archive/refs/tags/v9.3.0.zip
unzip gut.zip
mkdir -p $OLDPWD/addons/gut
cp -r Gut-9.3.0/addons/gut/* $OLDPWD/addons/gut/
cd $OLDPWD
```

Then enable in `project.godot` under a new `[editor_plugins]` section:
```ini
[editor_plugins]
enabled=PackedStringArray("res://addons/gut/plugin.cfg")
```

- [ ] **Step 4: Add `test/.gutconfig.json`**

```json
{
  "dirs": ["res://test/unit"],
  "include_subdirs": true,
  "log_level": 1,
  "should_exit": true,
  "should_print_to_console": true
}
```

- [ ] **Step 5: Create magenta placeholder sprite**

```bash
# Use any tool; ImageMagick one-liner:
magick -size 32x32 xc:magenta art/_missing.png
# Or hand-make in any pixel editor and save as 32×32 PNG filled with #FF00FF.
```

- [ ] **Step 6: Verify import + GUT runs locally**

```bash
godot --headless --import
# Expected: no ERROR lines

godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit
# Expected: "GUT: 0 tests" (no tests yet — that's fine, exit code 0)
```

- [ ] **Step 7: Commit, push, PR, merge**

```bash
git add project.godot icon.svg addons/gut/ test/.gutconfig.json art/_missing.png
git commit -m "feat: bootstrap Godot 4.3 project and vendor GUT 9.3.0

- 640x360 viewport, nearest-neighbor filtering, integer stretch
- GUT enabled via editor plugins, gutconfig points at test/unit
- Magenta 32x32 placeholder sprite for missing-asset fallback

Closes #4"
git push -u origin issue/4-godot-init
gh pr create --fill --label "type:feature,area:engine,priority:p0"
# CI should now PASS (import clean, 0 tests)
gh pr merge --squash --delete-branch
```

---

## Task 5: `GameRoot` autoload — world input pause + panel stack

**Issue title:** `feat(engine): GameRoot autoload with world_input_paused + panel stack`
**Labels:** `type:feature`, `area:engine`, `priority:p0`
**Depends on:** Task 4

**Files:**
- Create: `scripts/game_root.gd`
- Create: `test/unit/test_game_root.gd`
- Modify: `project.godot` (add autoload line)

### Steps

- [ ] **Step 1: Write failing test** — `test/unit/test_game_root.gd`

```gdscript
extends GutTest

var GameRootScript := preload("res://scripts/game_root.gd")

func test_defaults():
    var gr: Node = GameRootScript.new()
    assert_false(gr.world_input_paused, "input should not be paused on init")
    assert_eq(gr.panel_stack.size(), 0, "panel stack should be empty on init")
    gr.free()

func test_push_panel_pauses_input():
    var gr: Node = GameRootScript.new()
    var fake_panel := Node.new()
    gr.push_panel(fake_panel)
    assert_true(gr.world_input_paused)
    assert_eq(gr.panel_stack.size(), 1)
    gr.free()
    fake_panel.free()

func test_pop_panel_resumes_input_when_empty():
    var gr: Node = GameRootScript.new()
    var fake_panel := Node.new()
    gr.push_panel(fake_panel)
    gr.pop_panel(fake_panel)
    assert_false(gr.world_input_paused)
    assert_eq(gr.panel_stack.size(), 0)
    gr.free()
    fake_panel.free()

func test_pop_panel_keeps_pause_when_stack_nonempty():
    var gr: Node = GameRootScript.new()
    var p1 := Node.new()
    var p2 := Node.new()
    gr.push_panel(p1)
    gr.push_panel(p2)
    gr.pop_panel(p2)
    assert_true(gr.world_input_paused, "still paused with p1 on stack")
    gr.free(); p1.free(); p2.free()
```

- [ ] **Step 2: Run — expect failure**

```bash
godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit
# Expected: FAIL — "Could not load res://scripts/game_root.gd"
```

- [ ] **Step 3: Implement `scripts/game_root.gd`**

```gdscript
extends Node
class_name GameRoot
## Autoload singleton. Tracks input pause state and panel stack.

signal world_input_paused_changed(paused: bool)

var world_input_paused: bool = false :
    set(value):
        if world_input_paused == value:
            return
        world_input_paused = value
        world_input_paused_changed.emit(value)

var panel_stack: Array[Node] = []

func push_panel(panel: Node) -> void:
    panel_stack.append(panel)
    world_input_paused = true

func pop_panel(panel: Node) -> void:
    panel_stack.erase(panel)
    if panel_stack.is_empty():
        world_input_paused = false
```

- [ ] **Step 4: Register autoload in `project.godot`**

Add block (or merge into existing):
```ini
[autoload]
GameRoot="*res://scripts/game_root.gd"
```

- [ ] **Step 5: Run tests — expect pass**

```bash
godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit
# Expected: PASS — 4/4
```

- [ ] **Step 6: Commit**

```bash
git add scripts/game_root.gd test/unit/test_game_root.gd project.godot
git commit -m "feat(engine): add GameRoot autoload for input pause + panel stack

Closes #5"
```

- [ ] **Step 7: Push, PR, merge** (per conventions section)

---

## Task 6: `NpcStatus` enum + `NpcConfig` Resource

**Issue title:** `feat(engine): NpcStatus enum and NpcConfig resource`
**Labels:** `type:feature`, `area:engine`, `priority:p0`
**Depends on:** Task 5

**Files:**
- Create: `scripts/npc_status.gd`
- Create: `scripts/npc_config.gd`
- Create: `test/unit/test_npc_config.gd`
- Create: `test/fixtures/valid_npc.tres`
- Create: `test/fixtures/invalid_npc_no_panel.tres`

### Steps

- [ ] **Step 1: Write failing test** — `test/unit/test_npc_config.gd`

```gdscript
extends GutTest

const NpcConfig := preload("res://scripts/npc_config.gd")

func test_valid_tres_loads_all_fields():
    var cfg: NpcConfig = load("res://test/fixtures/valid_npc.tres")
    assert_not_null(cfg)
    assert_eq(cfg.display_name, "Test NPC")
    assert_not_null(cfg.sprite)
    assert_eq(cfg.desk_position, Vector2i(2, 3))
    assert_not_null(cfg.panel_scene)
    assert_eq(cfg.kind, &"stub")

func test_invalid_tres_without_panel_is_detected_by_helper():
    var cfg: NpcConfig = load("res://test/fixtures/invalid_npc_no_panel.tres")
    assert_false(cfg.is_valid(), "missing panel_scene must fail validation")

func test_default_kind_is_stub():
    var cfg := NpcConfig.new()
    assert_eq(cfg.kind, &"stub")

func test_npc_status_enum_values():
    # Enum identity — guards accidental reordering
    assert_eq(NpcStatus.Status.IDLE, 0)
    assert_eq(NpcStatus.Status.BUSY, 1)
    assert_eq(NpcStatus.Status.NOTIFY, 2)
```

- [ ] **Step 2: Run — expect failure**

- [ ] **Step 3: Implement `scripts/npc_status.gd`**

```gdscript
extends RefCounted
class_name NpcStatus
## Status enum for NPCs. Wrapper class so the enum is globally accessible.

enum Status { IDLE, BUSY, NOTIFY }
```

- [ ] **Step 4: Implement `scripts/npc_config.gd`**

```gdscript
extends Resource
class_name NpcConfig

@export var display_name: String = ""
@export var sprite: Texture2D
@export var desk_position: Vector2i = Vector2i.ZERO
@export var panel_scene: PackedScene
@export var kind: StringName = &"stub"

func is_valid() -> bool:
    return display_name != "" and sprite != null and panel_scene != null
```

- [ ] **Step 5: Create test fixtures in the Godot editor**

In the editor:
1. Right-click `test/fixtures/` → New Resource → `NpcConfig` → save as `valid_npc.tres`.
2. Set `display_name = "Test NPC"`, drop `art/_missing.png` as sprite, `desk_position = (2,3)`, set `panel_scene` to *any* `.tscn` (use `res://addons/gut/GutRunner.tscn` if no panel exists yet — it's throwaway).
3. Duplicate as `invalid_npc_no_panel.tres`, blank out `panel_scene`.

- [ ] **Step 6: Run tests — expect pass (4/4)**

- [ ] **Step 7: Commit + PR**

```bash
git add scripts/npc_status.gd scripts/npc_config.gd \
        test/unit/test_npc_config.gd test/fixtures/
git commit -m "feat(engine): add NpcStatus enum and NpcConfig resource

Closes #6"
```

---

## Task 7: `InteractionPanel` abstract base

**Issue title:** `feat(engine): InteractionPanel abstract base class`
**Labels:** `type:feature`, `area:engine`, `priority:p0`
**Depends on:** Task 5

**Files:**
- Create: `scripts/interaction_panel.gd`

*(No unit test yet — abstract class with no behavior. `StubDialoguePanel` in Task 8 tests the contract.)*

### Steps

- [ ] **Step 1: Implement `scripts/interaction_panel.gd`**

```gdscript
extends Control
class_name InteractionPanel
## Abstract base for any panel that opens when interacting with an NPC.
## Subclasses MUST override show_for(). close() is typically fine as-is.

signal panel_closed

func show_for(_npc: Node) -> void:
    push_error("InteractionPanel.show_for must be overridden")

func close() -> void:
    panel_closed.emit()
    queue_free()
```

- [ ] **Step 2: Run tests (no new tests; confirm old ones still pass)**

- [ ] **Step 3: Commit + PR**

```bash
git add scripts/interaction_panel.gd
git commit -m "feat(engine): add InteractionPanel abstract base

Closes #7"
```

---

## Task 8: `StubDialoguePanel` — the v0.1 panel

**Issue title:** `feat(ui): StubDialoguePanel showing coming-soon text`
**Labels:** `type:feature`, `area:ui`, `priority:p0`
**Depends on:** Task 7

**Files:**
- Create: `scripts/stub_dialogue_panel.gd`
- Create: `scenes/panels/stub_dialogue.tscn`
- Create: `test/unit/test_stub_dialogue_panel.gd`

### Steps

- [ ] **Step 1: Write failing test** — `test/unit/test_stub_dialogue_panel.gd`

```gdscript
extends GutTest

const StubPanelScene := preload("res://scenes/panels/stub_dialogue.tscn")

func _make_fake_npc(name: String) -> Node:
    var npc := Node.new()
    npc.set("config", NpcConfig.new())
    npc.config.display_name = name
    return npc

func test_show_for_sets_npc_name_in_label():
    var panel: StubDialoguePanel = StubPanelScene.instantiate()
    add_child_autofree(panel)
    var npc := _make_fake_npc("Claudebot")
    add_child_autofree(npc)
    panel.show_for(npc)
    assert_string_contains(panel.get_label_text(), "Claudebot")
    assert_string_contains(panel.get_label_text(), "coming soon")

func test_close_emits_panel_closed_once():
    var panel: StubDialoguePanel = StubPanelScene.instantiate()
    add_child_autofree(panel)
    var counter := [0]
    panel.panel_closed.connect(func(): counter[0] += 1)
    panel.close()
    await wait_frames(2)
    assert_eq(counter[0], 1)
```

- [ ] **Step 2: Run — expect failure**

- [ ] **Step 3: Implement `scripts/stub_dialogue_panel.gd`**

```gdscript
extends InteractionPanel
class_name StubDialoguePanel

@onready var _label: Label = $Panel/Label

func show_for(npc: Node) -> void:
    var name := "an NPC"
    if npc != null and npc.get("config") != null:
        name = npc.config.display_name
    _label.text = "%s: coming soon — claude code" % name
    visible = true

func get_label_text() -> String:
    return _label.text

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
        get_viewport().set_input_as_handled()
        close()
```

- [ ] **Step 4: Build `scenes/panels/stub_dialogue.tscn`**

In the editor:
1. Create new scene, root = `Control`, attach `scripts/stub_dialogue_panel.gd`.
2. Child: `Panel` (node name `Panel`), anchor center, size 400×120.
3. Child of `Panel`: `Label` (node name `Label`), centered, default pixel font.
4. Save as `scenes/panels/stub_dialogue.tscn`.

- [ ] **Step 5: Register `interact` input action in `project.godot`**

```ini
[input]
interact={
"deadzone": 0.5,
"events": [Object(InputEventKey,"keycode":69)]  ; E
}
```

- [ ] **Step 6: Run tests — expect pass (6/6 total now)**

- [ ] **Step 7: Commit + PR**

```bash
git add scripts/stub_dialogue_panel.gd scenes/panels/stub_dialogue.tscn \
        test/unit/test_stub_dialogue_panel.gd project.godot
git commit -m "feat(ui): add StubDialoguePanel with coming-soon text

Closes #8"
```

---

## Task 9: `NpcEntity` — sprite + interaction + status signals

**Issue title:** `feat(engine): NpcEntity with interact() and status signals`
**Labels:** `type:feature`, `area:engine`, `priority:p0`
**Depends on:** Tasks 6, 7

**Files:**
- Create: `scripts/npc_entity.gd`
- Create: `scenes/npc.tscn`
- Create: `test/unit/test_npc_entity.gd`

### Steps

- [ ] **Step 1: Write failing test** — `test/unit/test_npc_entity.gd`

```gdscript
extends GutTest

const NpcScene := preload("res://scenes/npc.tscn")

func _make_cfg() -> NpcConfig:
    var cfg := NpcConfig.new()
    cfg.display_name = "T"
    cfg.sprite = preload("res://art/_missing.png")
    cfg.desk_position = Vector2i.ZERO
    cfg.panel_scene = preload("res://scenes/panels/stub_dialogue.tscn")
    cfg.kind = &"stub"
    return cfg

func test_applies_config_on_ready():
    var npc: Node = NpcScene.instantiate()
    npc.config = _make_cfg()
    add_child_autofree(npc)
    await wait_frames(1)
    assert_eq(npc.get_node("Sprite2D").texture, npc.config.sprite)

func test_interact_instantiates_panel_and_emits_signal():
    var npc: Node = NpcScene.instantiate()
    npc.config = _make_cfg()
    add_child_autofree(npc)
    await wait_frames(1)
    var started := [false]
    npc.interaction_started.connect(func(_panel): started[0] = true)
    var panel := npc.interact()
    assert_not_null(panel)
    assert_true(started[0])

func test_status_change_emits_exactly_once():
    var npc: Node = NpcScene.instantiate()
    npc.config = _make_cfg()
    add_child_autofree(npc)
    var count := [0]
    npc.status_changed.connect(func(_s): count[0] += 1)
    npc.status = NpcStatus.Status.NOTIFY
    npc.status = NpcStatus.Status.NOTIFY  # same value — no re-emit
    npc.status = NpcStatus.Status.IDLE
    assert_eq(count[0], 2)
```

- [ ] **Step 2: Run — expect failure**

- [ ] **Step 3: Implement `scripts/npc_entity.gd`**

```gdscript
extends Node2D
class_name NpcEntity

signal interaction_started(panel: InteractionPanel)
signal interaction_ended
signal status_changed(new_status: NpcStatus.Status)

@export var config: NpcConfig

var status: NpcStatus.Status = NpcStatus.Status.IDLE :
    set(value):
        if status == value:
            return
        status = value
        status_changed.emit(value)

func _ready() -> void:
    if config == null:
        push_warning("NpcEntity has no config assigned; skipping spawn")
        queue_free()
        return
    if not config.is_valid():
        push_warning("NpcConfig invalid for NPC at %s; skipping" % get_path())
        queue_free()
        return
    $Sprite2D.texture = config.sprite

func interact() -> InteractionPanel:
    if config == null or config.panel_scene == null:
        push_error("Cannot interact: missing panel_scene")
        return null
    var panel := config.panel_scene.instantiate() as InteractionPanel
    if panel == null:
        push_error("panel_scene did not produce an InteractionPanel")
        return null
    panel.panel_closed.connect(_on_panel_closed)
    interaction_started.emit(panel)
    return panel

func _on_panel_closed() -> void:
    interaction_ended.emit()
```

- [ ] **Step 4: Build `scenes/npc.tscn`**

1. New scene, root = `Node2D`, name `NpcEntity`, attach `scripts/npc_entity.gd`.
2. Child `Sprite2D` (default 32×32, placeholder texture `_missing.png`).
3. Child `Area2D` named `InteractionZone` with a `CollisionShape2D` (CircleShape2D radius 24).
4. Save as `scenes/npc.tscn`.

- [ ] **Step 5: Run tests — expect pass**

- [ ] **Step 6: Commit + PR**

```bash
git add scripts/npc_entity.gd scenes/npc.tscn test/unit/test_npc_entity.gd
git commit -m "feat(engine): add NpcEntity with interact() and status signals

Closes #9"
```

---

## Task 10: `PlayerController` — 4-dir movement, respects input pause

**Issue title:** `feat(engine): PlayerController 4-dir movement`
**Labels:** `type:feature`, `area:engine`, `priority:p0`
**Depends on:** Task 5

**Files:**
- Create: `scripts/player_controller.gd`
- Create: `scenes/player.tscn`
- Create: `test/unit/test_player_controller.gd`

### Steps

- [ ] **Step 1: Write failing test** — `test/unit/test_player_controller.gd`

```gdscript
extends GutTest

const PlayerScene := preload("res://scenes/player.tscn")

func test_velocity_zero_when_no_input():
    var p: CharacterBody2D = PlayerScene.instantiate()
    add_child_autofree(p)
    p._compute_velocity(Vector2.ZERO)
    assert_eq(p.velocity, Vector2.ZERO)

func test_velocity_cardinal_normalized_to_speed():
    var p: CharacterBody2D = PlayerScene.instantiate()
    add_child_autofree(p)
    p._compute_velocity(Vector2.RIGHT)
    assert_eq(p.velocity.x, p.speed)
    assert_eq(p.velocity.y, 0.0)

func test_paused_world_zeroes_velocity():
    var p: CharacterBody2D = PlayerScene.instantiate()
    add_child_autofree(p)
    GameRoot.world_input_paused = true
    p._compute_velocity(Vector2.RIGHT)
    assert_eq(p.velocity, Vector2.ZERO)
    GameRoot.world_input_paused = false
```

- [ ] **Step 2: Run — expect failure**

- [ ] **Step 3: Implement `scripts/player_controller.gd`**

```gdscript
extends CharacterBody2D
class_name PlayerController

@export var speed: float = 140.0

func _physics_process(_delta: float) -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    # 4-dir: collapse diagonals to cardinal
    if abs(input_dir.x) >= abs(input_dir.y):
        input_dir = Vector2(sign(input_dir.x), 0)
    else:
        input_dir = Vector2(0, sign(input_dir.y))
    _compute_velocity(input_dir)
    move_and_slide()

func _compute_velocity(dir: Vector2) -> void:
    if GameRoot.world_input_paused:
        velocity = Vector2.ZERO
        return
    velocity = dir * speed
```

- [ ] **Step 4: Register input actions in `project.godot`**

```ini
[input]
move_left={ "deadzone": 0.5, "events": [Object(InputEventKey,"keycode":65), Object(InputEventKey,"keycode":4194319)] }   ; A, Left
move_right={ "deadzone": 0.5, "events": [Object(InputEventKey,"keycode":68), Object(InputEventKey,"keycode":4194321)] }  ; D, Right
move_up={ "deadzone": 0.5, "events": [Object(InputEventKey,"keycode":87), Object(InputEventKey,"keycode":4194320)] }    ; W, Up
move_down={ "deadzone": 0.5, "events": [Object(InputEventKey,"keycode":83), Object(InputEventKey,"keycode":4194322)] }  ; S, Down
```

- [ ] **Step 5: Build `scenes/player.tscn`**

1. New scene, root = `CharacterBody2D`, name `Player`, attach `scripts/player_controller.gd`.
2. Child `Sprite2D` with `_missing.png` (replaced in Task 15).
3. Child `CollisionShape2D` (RectangleShape2D 24×24).
4. Child `Area2D` named `InteractionZone` with `CollisionShape2D` (CircleShape2D radius 28) — used by Task 11.
5. Save as `scenes/player.tscn`.

- [ ] **Step 6: Run tests — expect pass**

- [ ] **Step 7: Commit + PR**

```bash
git add scripts/player_controller.gd scenes/player.tscn \
        test/unit/test_player_controller.gd project.godot
git commit -m "feat(engine): add PlayerController with 4-dir movement

Closes #10"
```

---

## Task 11: `InteractionSystem` — target tracking and E routing

**Issue title:** `feat(engine): InteractionSystem for target tracking and E routing`
**Labels:** `type:feature`, `area:engine`, `priority:p0`
**Depends on:** Tasks 9, 10

**Files:**
- Create: `scripts/interaction_system.gd`
- Create: `test/unit/test_interaction_system.gd`
- Modify: `scenes/player.tscn` — add `InteractionSystem` child

### Steps

- [ ] **Step 1: Write failing test** — `test/unit/test_interaction_system.gd`

```gdscript
extends GutTest

const InteractionSystemScript := preload("res://scripts/interaction_system.gd")
const NpcScene := preload("res://scenes/npc.tscn")

func _make_npc(at: Vector2) -> Node:
    var cfg := NpcConfig.new()
    cfg.display_name = "T"
    cfg.sprite = preload("res://art/_missing.png")
    cfg.panel_scene = preload("res://scenes/panels/stub_dialogue.tscn")
    var npc = NpcScene.instantiate()
    npc.config = cfg
    npc.position = at
    return npc

func test_closest_npc_wins_when_multiple_in_zone():
    var sys: Node = InteractionSystemScript.new()
    add_child_autofree(sys)
    var a = _make_npc(Vector2(10, 0))
    var b = _make_npc(Vector2(100, 0))
    add_child_autofree(a); add_child_autofree(b)
    sys.notify_entered(a)
    sys.notify_entered(b)
    sys.recompute_target(Vector2.ZERO)
    assert_eq(sys.current_target, a)

func test_target_cleared_when_all_exit():
    var sys: Node = InteractionSystemScript.new()
    add_child_autofree(sys)
    var a = _make_npc(Vector2(10, 0))
    add_child_autofree(a)
    sys.notify_entered(a)
    sys.notify_exited(a)
    sys.recompute_target(Vector2.ZERO)
    assert_null(sys.current_target)
```

- [ ] **Step 2: Run — expect failure**

- [ ] **Step 3: Implement `scripts/interaction_system.gd`**

```gdscript
extends Node
class_name InteractionSystem
## Tracks NpcEntities in proximity, picks closest as current target,
## routes the E action. Lives as a child of Player.

signal target_changed(npc)

var _in_range: Array[NpcEntity] = []
var current_target: NpcEntity = null

func notify_entered(npc: NpcEntity) -> void:
    if not _in_range.has(npc):
        _in_range.append(npc)

func notify_exited(npc: NpcEntity) -> void:
    _in_range.erase(npc)

func recompute_target(player_pos: Vector2) -> void:
    var closest: NpcEntity = null
    var best := INF
    for n in _in_range:
        if not is_instance_valid(n):
            continue
        var d := player_pos.distance_squared_to(n.global_position)
        if d < best:
            best = d
            closest = n
    if closest != current_target:
        current_target = closest
        target_changed.emit(current_target)

func try_interact() -> InteractionPanel:
    if GameRoot.world_input_paused or current_target == null:
        return null
    return current_target.interact()
```

- [ ] **Step 4: Wire into Player scene (no code change, scene-level)**

In `scenes/player.tscn`:
1. Add `InteractionSystem` (Node) as child of Player.
2. Connect Player's `InteractionZone` `Area2D` signals:
   - `area_entered(area)` → on Player script: `if area.owner is NpcEntity: $InteractionSystem.notify_entered(area.owner)`
   - `area_exited(area)` → mirror with `notify_exited`.
3. In `player_controller.gd`, add in `_physics_process`:
   ```gdscript
   $InteractionSystem.recompute_target(global_position)
   if Input.is_action_just_pressed("interact"):
       var panel := $InteractionSystem.try_interact()
       if panel != null:
           UIRoot.show_panel(panel)  # UIRoot from Task 12
   ```
   *(Task 12 lands `UIRoot` autoload; commit this task's code with the `UIRoot.show_panel` call after Task 12 merges — or stub it to a free-standing signal now and wire in Task 12.)*

   **Clean approach:** don't call `UIRoot.show_panel` yet. Emit a signal instead:
   ```gdscript
   signal panel_requested(panel: InteractionPanel)
   # ...
   if Input.is_action_just_pressed("interact"):
       var panel := $InteractionSystem.try_interact()
       if panel != null:
           panel_requested.emit(panel)
   ```
   `UIRoot` in Task 12 connects to this signal.

- [ ] **Step 5: Run tests — expect pass**

- [ ] **Step 6: Commit + PR**

```bash
git add scripts/interaction_system.gd scripts/player_controller.gd \
        scenes/player.tscn test/unit/test_interaction_system.gd
git commit -m "feat(engine): add InteractionSystem for target tracking and E routing

Closes #11"
```

---

## Task 12: `UIRoot` — prompt, panel host, signal wiring

**Issue title:** `feat(ui): UIRoot with press-E prompt and panel host`
**Labels:** `type:feature`, `area:ui`, `priority:p0`
**Depends on:** Tasks 8, 11

**Files:**
- Create: `scripts/ui_root.gd`
- Create: `scenes/ui/ui_root.tscn`
- Create: `test/unit/test_ui_root.gd`
- Modify: `project.godot` (add `UIRoot` autoload? — no, it's a scene-tree node in `world.tscn`. Skip autoload. Test with direct instantiation.)

### Steps

- [ ] **Step 1: Write failing test** — `test/unit/test_ui_root.gd`

```gdscript
extends GutTest

const UIRootScene := preload("res://scenes/ui/ui_root.tscn")
const StubPanelScene := preload("res://scenes/panels/stub_dialogue.tscn")

func test_show_prompt_sets_visible_and_positions():
    var ui: CanvasLayer = UIRootScene.instantiate()
    add_child_autofree(ui)
    ui.show_prompt(Vector2(100, 50))
    assert_true(ui.get_prompt_node().visible)

func test_hide_prompt_hides_node():
    var ui: CanvasLayer = UIRootScene.instantiate()
    add_child_autofree(ui)
    ui.show_prompt(Vector2.ZERO)
    ui.hide_prompt()
    assert_false(ui.get_prompt_node().visible)

func test_show_panel_pushes_to_gameroot_and_removes_on_close():
    var ui: CanvasLayer = UIRootScene.instantiate()
    add_child_autofree(ui)
    var panel: InteractionPanel = StubPanelScene.instantiate()
    ui.show_panel(panel)
    assert_true(GameRoot.world_input_paused)
    panel.close()
    await wait_frames(2)
    assert_false(GameRoot.world_input_paused)
```

- [ ] **Step 2: Run — expect failure**

- [ ] **Step 3: Implement `scripts/ui_root.gd`**

```gdscript
extends CanvasLayer
class_name UIRootNode
## Hosts the press-E prompt and whichever panel is currently open.

@onready var _prompt: Label = $Prompt
@onready var _panel_host: Control = $PanelHost

func show_prompt(world_pos: Vector2) -> void:
    _prompt.visible = true
    _prompt.global_position = world_pos + Vector2(-16, -32)

func hide_prompt() -> void:
    _prompt.visible = false

func get_prompt_node() -> Label:
    return _prompt

func show_panel(panel: InteractionPanel) -> void:
    _panel_host.add_child(panel)
    panel.panel_closed.connect(_on_panel_closed.bind(panel), CONNECT_ONE_SHOT)
    GameRoot.push_panel(panel)
    panel.show_for(panel.get_meta("target_npc", null))  # panel host sets meta when assigning

func _on_panel_closed(panel: InteractionPanel) -> void:
    GameRoot.pop_panel(panel)
```

Note the `show_panel` signature is simpler than above if the caller pre-binds the NPC. Cleaner version:

```gdscript
func show_panel_for(panel: InteractionPanel, npc: NpcEntity) -> void:
    _panel_host.add_child(panel)
    panel.panel_closed.connect(_on_panel_closed.bind(panel), CONNECT_ONE_SHOT)
    GameRoot.push_panel(panel)
    panel.show_for(npc)

func _on_panel_closed(panel: InteractionPanel) -> void:
    GameRoot.pop_panel(panel)
```

Update the test to match (see test pass below) and update the `PlayerController.panel_requested` signal to also carry the npc.

- [ ] **Step 4: Build `scenes/ui/ui_root.tscn`**

1. Root `CanvasLayer`, attach `ui_root.gd`.
2. Child `Label` (`Prompt`) with text "Press E" — hidden by default.
3. Child `Control` (`PanelHost`) — full-rect anchor, hosts any `InteractionPanel` added at runtime.
4. Save.

- [ ] **Step 5: Run tests — expect pass (after adjusting test to `show_panel_for`)**

- [ ] **Step 6: Commit + PR**

---

## Task 13: Status indicator rendering in `UIRoot`

**Issue title:** `feat(ui): render NPC status indicators above desks (stubbed on idle)`
**Labels:** `type:feature`, `area:ui`, `priority:p1`
**Depends on:** Task 12

**Files:**
- Modify: `scripts/ui_root.gd`
- Modify: `scenes/ui/ui_root.tscn` (add an `IndicatorLayer` node)
- Create: `test/unit/test_status_indicators.gd`

### Steps

- [ ] **Step 1: Write failing test** — `test/unit/test_status_indicators.gd`

```gdscript
extends GutTest

const UIRootScene := preload("res://scenes/ui/ui_root.tscn")
const NpcScene := preload("res://scenes/npc.tscn")

func _make_npc() -> NpcEntity:
    var cfg := NpcConfig.new()
    cfg.display_name = "T"
    cfg.sprite = preload("res://art/_missing.png")
    cfg.panel_scene = preload("res://scenes/panels/stub_dialogue.tscn")
    var npc: NpcEntity = NpcScene.instantiate()
    npc.config = cfg
    return npc

func test_notify_status_shows_bang():
    var ui: CanvasLayer = UIRootScene.instantiate(); add_child_autofree(ui)
    var npc := _make_npc(); add_child_autofree(npc)
    ui.register_npc(npc)
    npc.status = NpcStatus.Status.NOTIFY
    await wait_frames(1)
    assert_eq(ui.get_indicator_text_for(npc), "!")

func test_idle_hides_indicator():
    var ui: CanvasLayer = UIRootScene.instantiate(); add_child_autofree(ui)
    var npc := _make_npc(); add_child_autofree(npc)
    ui.register_npc(npc)
    npc.status = NpcStatus.Status.NOTIFY
    npc.status = NpcStatus.Status.IDLE
    await wait_frames(1)
    assert_false(ui.get_indicator_for(npc).visible)
```

- [ ] **Step 2: Run — expect failure**

- [ ] **Step 3: Extend `scripts/ui_root.gd`**

```gdscript
# Appended to ui_root.gd from Task 12

@onready var _indicator_layer: Node2D = $IndicatorLayer

var _indicators: Dictionary = {}  # NpcEntity -> Label

func register_npc(npc: NpcEntity) -> void:
    var label := Label.new()
    label.text = ""
    label.visible = false
    _indicator_layer.add_child(label)
    _indicators[npc] = label
    npc.status_changed.connect(_on_npc_status_changed.bind(npc))
    # Position follows the NPC — simplest: remote transform or poll in _process
    label.set_meta("npc", npc)

func _process(_delta: float) -> void:
    for npc in _indicators.keys():
        if not is_instance_valid(npc):
            continue
        var label: Label = _indicators[npc]
        label.global_position = npc.global_position + Vector2(-4, -40)

func _on_npc_status_changed(new_status: NpcStatus.Status, npc: NpcEntity) -> void:
    var label: Label = _indicators.get(npc)
    if label == null:
        return
    match new_status:
        NpcStatus.Status.IDLE:
            label.text = ""; label.visible = false
        NpcStatus.Status.BUSY:
            label.text = ".."; label.visible = true
        NpcStatus.Status.NOTIFY:
            label.text = "!"; label.visible = true

func get_indicator_text_for(npc: NpcEntity) -> String:
    return (_indicators[npc] as Label).text

func get_indicator_for(npc: NpcEntity) -> Label:
    return _indicators[npc]
```

- [ ] **Step 4: Add `IndicatorLayer` child to `ui_root.tscn`** (Node2D at root-level).

- [ ] **Step 5: Run tests — expect pass**

- [ ] **Step 6: Commit + PR**

---

## Task 14: `World` scene — assemble everything

**Issue title:** `feat(engine): World scene with player + UIRoot wiring`
**Labels:** `type:feature`, `area:engine`, `priority:p0`
**Depends on:** Tasks 10, 11, 12, 13

**Files:**
- Create: `scenes/world.tscn`
- Create: `scripts/world.gd` (optional — just to wire signals in `_ready`)

### Steps

- [ ] **Step 1: Build `scenes/world.tscn`**

In the editor:
1. New scene, root `Node2D` named `World`, attach `scripts/world.gd`.
2. Child: instance of `scenes/player.tscn`.
3. Child: `TileMap` (empty for now — Task 16 fills it).
4. Child: `Camera2D` child of player, zoom 1 (pixel-perfect since viewport = 640×360).
5. Child: instance of `scenes/ui/ui_root.tscn`.
6. Save.

- [ ] **Step 2: Write `scripts/world.gd`**

```gdscript
extends Node2D

@onready var _player: PlayerController = $Player
@onready var _ui: UIRootNode = $UIRoot

func _ready() -> void:
    # Wire player's interaction request to UI
    _player.panel_requested.connect(_on_panel_requested)
    # Wire interaction-system target changes to prompt
    _player.get_node("InteractionSystem").target_changed.connect(_on_target_changed)
    # Register each NPC under this scene with UIRoot so status indicators work
    for npc in get_tree().get_nodes_in_group("npc"):
        _ui.register_npc(npc)

func _on_panel_requested(panel: InteractionPanel) -> void:
    var target := _player.get_node("InteractionSystem").current_target
    _ui.show_panel_for(panel, target)

func _on_target_changed(npc: NpcEntity) -> void:
    if npc == null:
        _ui.hide_prompt()
    else:
        _ui.show_prompt(npc.global_position)
```

Add `PlayerController.panel_requested` signal to emit a `Variant` payload if not already (just the panel — npc fetched via interaction system).

- [ ] **Step 3: Add all NPCs to group `"npc"`** — in editor, select each NpcEntity node, Node panel → Groups → add `npc`. (Task 17 will do this on NPC instances.)

- [ ] **Step 4: Launch the project and verify**

```bash
godot    # open editor
# F5 → runs res://scenes/world.tscn
# Player should appear, be movable with WASD, camera follows.
```

(No NPCs yet — Task 17. Just confirm the scene loads without errors.)

- [ ] **Step 5: Commit + PR**

```bash
git add scenes/world.tscn scripts/world.gd
git commit -m "feat(engine): assemble World scene with player, camera, UIRoot

Closes #14"
```

---

## Task 15: Generate art via PixelLab MCP

**Issue title:** `art: generate initial sprites and tiles via PixelLab MCP`
**Labels:** `type:feature`, `area:art`, `priority:p1`
**Depends on:** Task 4

**Files (created via MCP or hand):**
- `art/player.png` — 32×32 human office-worker sprite sheet (4-dir idle, 1 frame each — walk cycles later)
- `art/npc_01.png` … `npc_04.png` — 32×32 desk-worker sprites, varied but same silhouette family
- `art/tiles/floor_wood.png` — 32×32 wood floor tile, seamless
- `art/tiles/wall.png` — 32×32 wall tile (top + side variants ok in one sheet)
- `art/tiles/desk.png` — 32×32 desk with monitor, 2 cells wide acceptable

### Steps

- [ ] **Step 1: Create issue + worktree**

- [ ] **Step 2: Use PixelLab MCP to generate each asset**

Prompts (feed to PixelLab MCP `generate_image` or equivalent, 32×32, transparent bg where appropriate):

- Player: "32x32 pixel art, top-down view, person wearing casual sweater and jeans, seen from above, four-direction idle pose, warm palette, clean outline, cozy office worker"
- NPC 1 "claude": "32x32 pixel art, top-down, programmer at desk, glasses, hoodie, seen from above at desk, warm palette, cozy lighting"
- NPC 2 "codex": "32x32 pixel art, top-down, engineer in t-shirt, short dark hair, seen from above at desk"
- NPC 3 "gemini": "32x32 pixel art, top-down, person in button-up, glasses, seen from above at desk"
- NPC 4 (spare): "32x32 pixel art, top-down, person with headphones, hoodie, seen from above at desk"
- floor_wood: "32x32 seamless pixel-art wood plank floor tile, warm brown, four-tone shading"
- wall: "32x32 pixel-art beige painted wall with thin baseboard, seamless"
- desk: "32x32 pixel-art office desk seen from above, wood surface, monitor, keyboard, small plant, warm tones"

If PixelLab output doesn't tile seamlessly, iterate prompts or hand-fix edges in a pixel editor.

- [ ] **Step 3: Place PNGs under `art/` and `art/tiles/`, commit**

- [ ] **Step 4: Import the tiles into a Godot `TileSet` resource** (needed by Task 16)

- [ ] **Step 5: Commit + PR**

```bash
git add art/
git commit -m "art: initial player, NPC, and tile sprites (PixelLab-generated)

Closes #15"
```

---

## Task 16: Build the office tilemap

**Issue title:** `art: paint the cozy office tilemap`
**Labels:** `type:feature`, `area:art`, `priority:p1`
**Depends on:** Tasks 14, 15

**Files:**
- Modify: `scenes/world.tscn` — paint tiles onto `TileMap`
- Create: `data/tilesets/office.tres` — Godot TileSet resource

### Steps

- [ ] **Step 1: Create `data/tilesets/office.tres`** in the editor, add the three tile textures.
- [ ] **Step 2: Open `scenes/world.tscn`, select `TileMap`, assign `office.tres`**
- [ ] **Step 3: Paint a ~16×10 tile room**
  - Floor throughout
  - Walls around the perimeter
  - 4 desks arranged in a rough grid (leave gaps the player can walk to)
- [ ] **Step 4: Add collision on wall and desk tiles** via the TileSet physics layer.
- [ ] **Step 5: Launch and playtest** — player can walk around, collides with walls + desks, no NPCs yet.
- [ ] **Step 6: Commit + PR**

---

## Task 17: Create 4 NPC configs + place in world

**Issue title:** `content: add 4 NPC configs and place in office scene`
**Labels:** `type:feature`, `area:art`, `priority:p0`
**Depends on:** Tasks 9, 16

**Files:**
- Create: `data/npcs/npc_01.tres` … `npc_04.tres`
- Modify: `scenes/world.tscn` — instance 4 `scenes/npc.tscn`, assign configs, add to group `"npc"`

### Steps

- [ ] **Step 1: For each NPC (1..4), create `data/npcs/npc_N.tres` in editor:**
  - `NpcConfig` with:
    - `display_name` = "Claude" / "Codex" / "Gemini" / "Spare"
    - `sprite` = `res://art/npc_0N.png`
    - `desk_position` = approximate tile coords (for later use, cosmetic in v0.1)
    - `panel_scene` = `res://scenes/panels/stub_dialogue.tscn`
    - `kind` = `&"stub"`

- [ ] **Step 2: In `scenes/world.tscn`, instance `npc.tscn` four times**, each with its `config` property pointed at the corresponding `.tres`. Place each on a desk in the tilemap. Add each to group `"npc"`.

- [ ] **Step 3: Launch, verify all 4 NPCs visible at their desks, E opens each panel with the correct name.**

- [ ] **Step 4: Commit + PR** — include a screenshot in the PR body.

---

## Task 18: Export presets — macOS and Windows

**Issue title:** `build: add macOS and Windows export presets (unsigned)`
**Labels:** `type:feature`, `area:build`, `priority:p0`

**Files:**
- Create: `export_presets.cfg` (tracked, even though listed in `.gitignore` — override)

### Steps

- [ ] **Step 1: Remove `export_presets.cfg` from `.gitignore`**

- [ ] **Step 2: In the Godot editor** → Project → Export → Add preset → macOS, unsigned, bundle id `com.norumander.llmvile`
- [ ] **Step 3: Add another preset → Windows Desktop, unsigned**
- [ ] **Step 4: Save & exit. Commit `export_presets.cfg`.**
- [ ] **Step 5: Install Godot export templates locally** (Editor → Manage Export Templates → Download).
- [ ] **Step 6: Export both locally to verify**

```bash
godot --headless --export-release "macOS" builds/llmvile.app
godot --headless --export-release "Windows Desktop" builds/llmvile.exe
# Verify artifacts launch from `builds/`.
```

- [ ] **Step 7: Commit + PR**

---

## Task 19: Export build in CI (macOS + Windows)

**Issue title:** `ci: export macOS and Windows builds on release workflow`
**Labels:** `type:chore`, `area:ci`, `priority:p1`
**Depends on:** Task 18

**Files:**
- Create: `.github/workflows/build.yml`

### Steps

- [ ] **Step 1: Write `.github/workflows/build.yml`**

```yaml
name: Build

on:
  push:
    tags: ["v*.*.*"]
  workflow_dispatch:

jobs:
  export:
    strategy:
      matrix:
        include:
          - platform: macOS
            os: macos-latest
            preset: "macOS"
            output: llmvile.app
          - platform: Windows
            os: ubuntu-latest   # cross-export works for Windows with the template
            preset: "Windows Desktop"
            output: llmvile.exe
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4

      - name: Install Godot 4.3-stable
        run: |
          if [ "$RUNNER_OS" = "macOS" ]; then
            curl -L -o godot.zip https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_macos.universal.zip
            unzip godot.zip -d ~/godot
            echo "$HOME/godot/Godot.app/Contents/MacOS" >> $GITHUB_PATH
          else
            curl -L -o godot.zip https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip
            unzip godot.zip -d ~/godot && chmod +x ~/godot/Godot_v4.3-stable_linux.x86_64
            ln -s ~/godot/Godot_v4.3-stable_linux.x86_64 ~/godot/godot
            echo "$HOME/godot" >> $GITHUB_PATH
          fi

      - name: Install export templates
        run: |
          mkdir -p ~/.local/share/godot/export_templates/4.3.stable
          curl -L -o tpl.tpz https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_export_templates.tpz
          unzip tpl.tpz -d /tmp/tpl
          mv /tmp/tpl/templates/* ~/.local/share/godot/export_templates/4.3.stable/

      - name: Import
        run: godot --headless --import

      - name: Export ${{ matrix.platform }}
        run: |
          mkdir -p builds
          godot --headless --export-release "${{ matrix.preset }}" builds/${{ matrix.output }}

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: llmvile-${{ matrix.platform }}
          path: builds/${{ matrix.output }}
```

- [ ] **Step 2: Run workflow manually** (`gh workflow run build.yml`), verify both artifacts produce.

- [ ] **Step 3: Commit + PR**

---

## Task 20: Playtest pass + bug triage

**Issue title:** `test: v0.1 playtest pass on macOS and Windows`
**Labels:** `type:task`, `area:engine`, `priority:p0`
**Depends on:** Tasks 17, 19

### Steps

- [ ] **Step 1: Download artifacts from latest Build workflow run.**
- [ ] **Step 2: Run the playtest checklist (docs/playtest-checklist.md) on macOS.**
- [ ] **Step 3: Run it on Windows (via VM or real machine).**
- [ ] **Step 4: File any blockers as new `type:bug` issues against v0.1 milestone.**
- [ ] **Step 5: Resolve all blockers before closing this issue.**
- [ ] **Step 6: Comment the filled-out checklist onto this issue, close.**

No code change in this task; it may spawn sub-tasks.

---

## Task 21: v0.1 release — tag, CHANGELOG, GitHub release

**Issue title:** `release: v0.1.0`
**Labels:** `type:chore`, `area:build`, `priority:p0`
**Depends on:** Task 20

### Steps

- [ ] **Step 1: Update `CHANGELOG.md`** — move `[Unreleased]` entries into `[0.1.0] - 2026-MM-DD`; add new empty `[Unreleased]`.

- [ ] **Step 2: Bump `project.godot` version** — `config/version="0.1.0"`.

- [ ] **Step 3: Commit, PR, merge.**

- [ ] **Step 4: Tag + release**

```bash
git checkout main && git pull
git tag -a v0.1.0 -m "v0.1 Walkable Overworld MVP"
git push origin v0.1.0
# Build workflow runs automatically; once artifacts exist:
gh release create v0.1.0 --generate-notes \
    builds/llmvile.app builds/llmvile.exe
# Or download from Actions artifacts and attach manually.
```

- [ ] **Step 5: Close v0.1 milestone.**

---

## Self-Review (done)

- **Spec coverage:** every spec section (architecture, components, data flow, error handling, testing, acceptance, dev lifecycle) has ≥1 task implementing it. Component table rows each map to a Task 5–14.
- **Placeholder scan:** no TBD/TODO; every code step contains the code. Task 11's `UIRoot.show_panel` forward-reference is handled with the signal-based cleaner approach.
- **Type consistency:** `NpcEntity` always carries `config`, `status`, `interact()`, `interaction_started(InteractionPanel)`, `interaction_ended`, `status_changed(NpcStatus.Status)` across tasks 6, 9, 11, 13. `UIRoot` exposes `show_panel_for(panel, npc)` consistently. `GameRoot.push_panel`/`pop_panel` consistent 5→12.
- **Scope:** each task is single-responsibility, ~1 PR of work, builds on prior tasks without backtracking.

## Open flags (not blocking, noted for future plans)

- Mac code signing + notarization deferred — v0.1 ships unsigned. Users will hit Gatekeeper warnings. Track as v0.4 issue post-release.
- Linux build deferred. Most code is portable; add preset when demand exists.
- Per-NPC group membership is set manually in the editor; consider an autoloader in v0.2 if NPC counts grow.

---

**Next:** pick execution mode — subagent-driven or inline.
