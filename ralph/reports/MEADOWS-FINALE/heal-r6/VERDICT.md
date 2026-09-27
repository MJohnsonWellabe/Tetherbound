# F05#7 "the land heals": blind verdict, round 6

**Staged capture, disclosed under the 06:55 owner ruling (2026-09-27).** The capture sets flags directly and places the player at each viewpoint. The ruling makes that a disclosed shortcut, not a reason to hold the claim, and the earned end-to-end walk was not made. The code-blind judge is still required for this visual row, and it passed. F05#7's READY is `tb/meadows-route` 35a547bb (#356).

**Result: the code-blind judge answered YES** to "does the land visibly heal, readable without being told?" on both passes. The verbatim verdicts are in `JUDGE-VERDICT.txt` (pass 2, final frames) and `JUDGE-VERDICT-pass1.txt`. Pass 2 said: "YES — in three of four pairs the land itself reads as healed; in the fourth (h04) what reads is 'life came back', not 'the land changed'." The fall "readable as an event: YES."

## Frames
The frames are in this directory, rendered in engine through the production camera rig with the HUD on and the clock pinned to 13:00. The -a frames are before the freeing; the -b frames are after it, at the same vantage.
- **Tool:** `tools/capture_f05_heal.gd`. It was rendered locally with `xvfb` + opengl3 at 1280x720 with `--fixed-fps 12`, so every frame is exactly 1/12 s of game time (`capture.log`).
- **Sheets:** `_sheet_pairs.jpg` (h01 quarry, h02 approach, h03 works, h04 highfield) and `_sheet_fall.jpg` (f00–f24).
- **Fall:** frames f00–f24 show `ApproachConduits/Pylon_6` side-on to its authored fall azimuth, from 22 m. The samples are t = 0, 1 and 2 s, then every 0.25 s from 3 s to 8 s, then 12 s.
- **Heal report:** regrown 886, regreened 7136 quads (2 m cell), lights killed 137, pylons toppled 29 (0 left standing), cables hidden 168, herd returned 7, bloomed 1044.

## Disclosed staging
- The main chain up to the Warden and `legendary_freed` are set directly, and the player is placed at each vantage with the rig's yaw and pitch set (pitch −10° to −22°).
- For the fall frames only, wild creatures within 70 m of the fall stand are hidden. In the first pass a wild Galecrest walked into the lens and hid the fall.
- Before the fall's first frame, the capture waits 4 s for the team panel to hide.

## What changed (round 6)
- **Before state visible.** Measured in engine first (diag A/B/C frames, not committed): the round-5 drain was a faint olive wash, and every round-5 vantage stood on the rim of its disc, where the authored falloff is about 0. The pale, hard-edged works polygon was the bake's own soil splat, seen through the regreen at alpha 0.7. The drain now reads as desaturated straw, reaches 1.35× past each station with a wider core, and has wider pylon discs. The grass field's blades thin in the same discs. The vantages now stand inside the drained ground.
- **Soft edges.** Both overlays use their own shader. The contour is thresholded against world-space value noise, so there is no polygon stencil. A view-space decal bias stops slopes clipping the overlay. The regreen fully covers the baked scar and feathers onto the grass beyond it.
- **Wildflowers.** The installed stylized-nature flower groups grow in seeded drifts over the healed stations. They are hard to see in these frames; the judge did not mention them.
- **Herd.** The herd is placed from a seed (`herd_return.scatter`) as three grazing clusters with mixed facing. It still meets F05#3: everyone within 14 m of the stag, on three or more sides, with the arc toward the hero stand left open.
- **Fall and dust.** The fall is captured, and the landing dust is darker and denser.
- **Multiplayer.** Everything above is derived from `legendary_freed` and seeded config. It is identical on every peer and every load, and nothing new is saved (smoke: live, reload and reload+30 all agree).

## Judge's remaining defects (pass 2, ranked) and who can fix them
1. **The fall is a rigid rotation.** There is no break-up, shatter, sparks or ground reaction (f03–f16). Scene work (this file) could add discharge particles and a camera shake. A convincing break-up may need a wreck variant of the pylon, which is art.
2. **The dust is a flat, low-opacity card** (f15–f19). This is tunable here (`pylons.dust`).
3. **The heal does not spread from the fallen pylon** in the fall sequence (the fall vantage is on healthy ground), and it is near-field only in h02 and h03. This is fixable here with wider regreen/drain reach or a vantage on the drained run.
4. **h02-b leaves a dark dome remnant and a surviving short pylon with its cable.** These are not in `pylons.holders` (spokes or relay apparatus left standing by design) or belong to the stronghold. The owner is Meadows core/stronghold. Not changed here.
5. **h03-b: the beige ramp is the stronghold's own untextured geometry**, and the Hall keeps its oxblood banners and cyan strips. The owner is the stronghold/Meadows core.
6. **The cart and fences are flat white** (h01, h04). This is scene content outside this lane (Meadows core).
7. **The deer are identical clones** (h04-b). The judge found no scale defect this pass. Pass 1 said the deer read as spawned and overlapped the cart and fence visually; the members are 5 m or more inside the fence line, so this is perspective. Creature fidelity is art.
8. **The badger creature and Hall textures look crunchy.** This is art.
9. **h01-b: the dead trees on the right stay dead.** This is the deadfall scatter layer, which the heal does not touch.
10. **The heal reads as a near-field colour grade.** It needs flowers that are more visible and a heal that reaches farther.
11. **HUD state differs between -a and -b** (team panel, toasts). This is a capture defect; a later round should hide the transient panels identically.
12. **The fall passes behind the trainer with no reaction.**
13. **The horizon is a pale mountain card.** This is outside this lane.

## Bar questions (pass 2)
- **(A) Key-art world:** **Yes.** The judge had the key art this round.
- **(B) Same kind of game as Palworld:** **Yes** on genre; **not at the bar** on execution (event spectacle, prop materials, ground and depth structure).

## Shared-file requests
- `SHARED-FILE-REQUEST-cover-tier-drain.patch` (`shaders/cover_tier.gdshader`, `scripts/world/grass_field.gd`): flowers and bushes thin inside the same drain discs the blades already do, so drained ground carries no wildflowers until the heal. Before the heal, the cover-tier flowers currently stand on drained ground in every -a frame. Not applied; this file is outside this lane.

## Tests (this round)
- `tests/test_meadow_healing_land_heals.gd`: 28 tests, 0 failed. New tests cover the herd clusters, the herd seed, the overlay feather/bias shader, and bloom determinism.
- `tests/test_meadow_healing_grass_drain.gd`: 5 tests, 0 failed.
- `tests/smoke_meadow_healing_land_heals.gd` (headless): passed (before, live, reload, reload+30).
