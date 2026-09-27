# F05#7 "the land heals": blind verdict, round 7

**Result.** The code-blind judge's verbatim answers were:
- **"Does the healed ground read as green grass?" — YES.**
- **"Does the land visibly heal, readable without being told?" — "YES in the before/after pairs, NO in the fall sequence."**

The full verdict is in `JUDGE-VERDICT.txt`, committed before this file.

## Frames and staging
The frames are in this directory. They were rendered in engine through the production camera rig with the clock pinned to 13:00. The capture ran locally with `xvfb`, opengl3, 1280x720 and `--fixed-fps 12`, using `tools/capture_f05_heal.gd` at `c3078013`.
- **Sheets:** `_sheet_pairs.jpg` has one row per place: h01 quarry, h02 approach, h03 works, h04 highfield. The -a frame is before the freeing; the -b frame is after it. `_sheet_fall.jpg` holds frames f00–f24, which show `ApproachConduits/Pylon_6` side-on from 22 m at 0/1/2 s, then every 0.25 s from 3 s to 8 s, then at 12 s.
- **Staging, disclosed under the 06:55 owner ruling:**
  - The main chain up to the Warden and `legendary_freed` are set directly.
  - The player is placed at each vantage, with the rig's yaw and pitch set.
  - For the fall frames only, wild creatures within 70 m of the fall stand are hidden.
  - The transient HUD (the team panel, the toast strip, the objective hint card and the region title card) is hidden the same way in every frame. The persistent HUD (objective, minimap, hotbar and bars) is shown.

## What changed (round 7)
- **Green healed ground.** The regreen overlay is now a saturated spring green (tint `#a8d890`, value 1.12, saturation +12%) over the installed meadow grass texture. No new texture was needed, so there is no V-MR request.
- **Reach to the far field.** New regreen-only `reach` discs carry the green out over the field each healed place looks across. The discs are 150 m at the approach, 95 m at the works, 55 m at the quarry and 110 m at the Highfield. The drained -a state still keeps to the stations.
- **Grass blades.** Once the drain lifts, the grass field's live blades inside every regreen disc lean toward `#5f9e3c` at full density. This works through the field's own drain channel with `drain_thin` set to 0.
- **Highfield.** The terrain bake never drained the Highfield, so it now has an authored inline drain/regreen disc, `highfield_pasture`, centred at (398, 5872), 62 m across. It is straw before the freeing and green after it.
- **Consistency.** Everything is derived from `legendary_freed` and config, identical on every peer and every load, and nothing new is saved. The smoke test covers live play, reload, and 30 s after reload.

## Judge's remaining defects, ranked, and who can fix them
1. **The green is one saturated lime value over whole quadrants** (h02-b, h03-b), so it reads as lawn more than meadow. This can be fixed here with patch or noise variation in the overlay tint and some dry tufts.
2. **h02-b: the distant hill band stays straw with a hard edge.** It lies outside the approach `reach` disc. This can be fixed here with a wider reach or a softer falloff, or by leaving that hill out of any drained reading.
3. **The fall sequence shows no ground change.** The fall vantage is on ground that was never drained. This can be fixed here with a vantage on the drained run, or a green sweep timed with the fall.
4. **Pale untextured ramp (h03-b) and pale slab in the wreck (f24).** These belong to the stronghold/Meadows core.
5. **The pylon wreck reads as a blob and the dust as flat cards.** The dust can be tuned here. A convincing wreck needs art.
6. **A leftover tether filament in the sky (h02-b) and a band around the tree (h04).** These belong to the stronghold/Meadows core.
7. **White fences and cart.** These belong to Meadows core.
8. **The deer herd is uniform.** Placement is done; appearance is art.
9. **The badger is shorter than the trainer's head.** This is a creature-scale hard-rule item owned by another lane; I did not change it here.

## Bar questions
- **(A) Belongs to the key-art world:** **YES** (the -b frames).
- **(B) Same kind of game as Palworld:** **YES** on genre; not at the bar on prop finish, ground variation, creature appeal or event effects.

## Tests
- `tests/test_meadow_healing_land_heals.gd`: 30 tests, 0 failed. New tests cover inline discs, the four groups plus `reach`, and the field green.
- `tests/test_meadow_healing_grass_drain.gd`: 5 tests, 0 failed.
- `tests/smoke_meadow_healing_land_heals.gd` (headless): passed. Its regreen mesh count now follows the configured groups.

## Shared-file request
`../heal-r6/SHARED-FILE-REQUEST-cover-tier-drain.patch` is still open. It would make the cover-tier flowers and bushes thin on the drained ground.
