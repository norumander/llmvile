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
