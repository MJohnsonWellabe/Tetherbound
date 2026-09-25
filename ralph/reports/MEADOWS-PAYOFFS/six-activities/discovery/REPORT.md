# F03 item 3: unstaged real-save lure discovery

Witness: `tests/capture_activity_lures.gd` (standalone; rendered under xvfb/opengl3, 1280x720, writer lock). It copies a real Gate F exit save byte-for-byte into a scratch slot and calls `Game.load_game`, then drives **ordinary input only**:
- movement and camera: `move_forward`, `sprint`, camera yaw through the rig;
- companion controls: `creature_recall`, `party_cycle`;
- unsticking: jump or strafe;
- fights the world starts: `combat_run`, and the input pilot for the fight itself.

It never writes flags, position, party or clock, and never presses the activity prompt. The route is the shortest path on the authored road graph, going cross-country where the road ends; the camera glances once at the activity when the route leaves the road. "Lure first seen" is geometric: on screen, within 160 m, clear line of sight. Budget: 360 game-seconds per activity. Receipts: `lure-walk-receipts.log`. Frames: `*_NN_*.jpg` and `contact_sheet.jpg`.

## Saves (on origin/main under ralph/reports/)

| Activity | Save | Save version | Saved position |
|---|---|---|---|
| Bram, herd | `gate-f-leg-s05/saves/S04-exit.json` (sha256 8c45346073f1…) | 15 | village (19, 13) |
| Warrens vault | `G3-BAND3-0903/gate-f-s07-v4/S06/saves/S06-exit.json` (191ed4d0df79…) | 16 | (-356, 2609) |
| Doss | `G3-BAND3-0903/gate-f-s07-v4/S07/saves/S07-exit.json` (90edf5b9d06f…) | 16 | (345, 3759) |
| Juno | `G3-BAND4-0903/gate-f-s08-run/saves/S07-exit.json` (c4e73d53b697…) | 16 | (-152, 4238) |
| Hall alpha | `G3-BAND4-0903/gate-f-s08-run/S08_fixed/saves/S08-exit.json` (8c9248790d5d…) | 16 | (-242, 6469) |

- All five load on save format 27. The loaded position matched the saved one within 0.02–0.29 m.
- `warrens_cleared` in the vault save was earned in play.
- Rejected: `gate-f-run-G3-BAND5-0903-S09/saves/S08-exit.json`. It is a synthetic seed at (0, 7000) with an empty map.

## Results (game seconds; metres actually walked)

| Activity | Result | Lure first seen | Prompt |
|---|---|---|---|
| Bram | PASS | 17.5 m, 164 s / 946 m, only after the route left the road (trees hide him from the haul road) | "Challenge Old Bram", 167 s / 960 m |
| Herd | PASS | 57 m, 235 s / 1397 m, after leaving the road (≈295 m cross-country) | "Watch the Meadowhart herd", 244 s / 1443 m |
| Warrens vault | PASS (rerun) | Elder at 9 m through the den arches, 31 s / 69 m; one Burrowback fight won on the way | "Engage Elder Trailpup", 32 s / 73 m (camera inside the Elder in that frame) |
| Doss | PASS | 153 m after leaving the road (a speck at that size), 69 s / 434 m | "Help Doss repair the bank perch", 94 s / 585 m |
| Juno | PASS | 122 m, seen from the road, 253 s / 1506 m | "Challenge Juno", 275 s / 1634 m |
| Hall alpha | **GAP** | 136 m, seen from the road, 153 s / 920 m (small, at the frame edge) | Not reached. Run 2: the save's lead creature is at 0 HP with no companion out, so the alpha gave no prompt and no aggression. Run 3, with a standing companion: won four road-side Galecrest fights (4102, 4916, 4005, 4917), then a pack pinned the player in woods at (-130.8, 6669.3), 750 m short. |

The script made no state writes. The only flag the game set itself during the walks was `alpha_pin_intro_seen`.

## Gaps

1. **Hall alpha:** its prompt was not reached from the real S08 save. Two open questions:
   - With the lead creature fainted and no companion out, the alpha gives no prompt and no aggression. Is that intended?
   - Should the band-5 road packs be able to pin a player off the approach?
2. **Lures not visible from the road:** Bram, Doss and the herd were on screen only after the route left the road. Juno and the Hall alpha were visible from the road itself.
3. **Tiny at first sight:** Doss at 153 m and the alpha at 136 m. "Seen" here is geometric only.
4. **Poor prompt frames:** the player hides Juno and Bram, and the vault frame's camera is inside the Elder.
5. **Load position:** the S04 saved position is now inside a village market stall. On load the player spins until the unstick jump frees them.

## Code-blind judge verdict

(appended below)
