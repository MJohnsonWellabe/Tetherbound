# F01#2 / F01#3: code-blind judge verdict (rendered walks at 7fe6e703)

**Judge.** A fresh independent subagent that saw images only (no source, config or logs). Agent id: `a92d2c081def251c1`.

**Frames.** The render.yml runs are 36315680911 (day) and 36315682666 (night). Both are `tests/capture_village_walk.gd --route=visits --from-title` at 7fe6e703, and both runs pass (`visited=11 max_off_road_m=0.00`, see `run_log_excerpt.txt`). The judge saw 62 frames: every start, end, reached, at-gate and take frame in both runs, plus 6 travel frames per run.

| Target | Day | Night |
|---|---|---|
| Grandpa | PASS #003 (prompt, face to face) | PASS #003 |
| Bram | PASS #014 (behind the inn bar, "Greet Bram") | PASS #013 |
| Tam | PASS #022 | PASS #021 (blue-tinted, readable) |
| Mira | PASS #027 (across the counter) | PASS #026 |
| Oskar | PASS #033 | PASS #032 |
| Halda | PASS #041 | PASS #040 |
| Old key | PASS #049/#050 ("Take the old key") | PASS on #049; #050 alone is weak (player past the post) |
| RoadGate | PASS #054 (gate open; it was closed in #053) | PASS #054 |
| Practice Meadow camp | PASS #069 (crates, barrel, sack, marker) | PASS #069 |
| TrailGate | PASS on end #081 ("South Bridge" arch); #082 alone is weak (gate post covers ~40%) | PASS #082 |
| PondGate | PASS #096 | PASS #096 (fence in the foreground, arch clear) |

**Night readability.** Night is playable. The paths stay warm against the moonlit grass. Lanterns, windows and signposts are legible, and every NPC and gate is identifiable.

**Defects.** None of these stops a target being identified.
- **Camera.** In day #082 a gate post fills the left of the frame. At Oskar, a roof eave fills the right third. In the inn end frames, a hanging lantern intrudes. No frame puts the camera inside geometry. (The earlier Bram partition defect is gone.)
- **HUD.** The right-hand hotbar and hints cover the camp props, Tam's doorway and the notice board. The day quest beacon draws over the camp creatures.
- **Lighting.** Interiors are lit as day at 23:00. At night, NPC skin reads blue-grey. The eave above Oskar is pure black. Tree canopies show noisy speckling.
- **Art.** Mira's counter is an untextured box.

**OVERALL F01#2 (day): PASS** (TrailGate relies on end frame #081).
**OVERALL F01#3 (night): PASS** (the old key relies on frame #049).

**Disclosed shortcuts** (unchanged from the c392e73d round):
- The walk is controller-input driven from the title.
- Photo frames use a scripted orbit (`_frame_for_photo`).
- The camp stop is at the trainer_camp pack (26.0, -28.1).
- The companion is recalled after the opening.

The companion smokes are committed in `../smokes_7fe6e703/`.
