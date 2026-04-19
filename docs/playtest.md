# Playtest checklists

Release-gating manual checks. Run against the tagged build on macOS (primary) and Windows (spot-check) before cutting a release.

## v0.2 Terminal MVP

1. [ ] Game launches, single NPC visible at the top-left desk.
2. [ ] Approach NPC: "Press E" prompt appears over head.
3. [ ] Press E: a native OS window opens, centered at ~85% of game window. Terminal is semi-transparent (game visible behind text).
4. [ ] Click inside the terminal and type `echo hi` → visible output at a readable font.
5. [ ] Run `claude -p "2+2"` if the claude CLI is installed → expected reply renders.
6. [ ] Click the X close button → panel closes, WASD resumes moving the player.
7. [ ] Re-open the same NPC → same shell, scrollback preserved.
8. [ ] In the panel, run `sleep 3; echo done`; click the game window to auto-close. Indicator shows `..` during sleep, flips to `!` within ~1–2s after "done" prints.
9. [ ] Re-open the NPC → indicator clears, scrollback shows the sleep/done lines.
10. [ ] Type `exit` → panel closes, NPC disappears, no errors in Output log.
11. [ ] Click `+ new terminal` HUD button: new NPC spawns at next free desk.
12. [ ] Press `N` keyboard shortcut: same behavior.
13. [ ] Spawn 4 NPCs; 5th attempt shows "All desks full" toast for ~2 seconds.
14. [ ] Relaunch the game → starts clean with one NPC again, no persistence.
