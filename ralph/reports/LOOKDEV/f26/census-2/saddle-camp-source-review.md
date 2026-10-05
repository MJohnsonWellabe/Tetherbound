# Saddle Camp catalogue source review

**PASS — bounded source correction only.** Reviewed commit `b69148d59` and the current relevant source with read-only commands. No engine, native capture, tests, or new harness ran during this review.

The commit changes exactly one file and one row: `data/config/debug_teleport_spots.json:205` replaces `[841.384, 1595.928]` with `[556.092163085938, 1367.17846679688]`. It preserves `Tidal Cradle Saddle Camp`, its `water` biome and `tidal_cradle` band, and all other catalogue data. The destination row occurs once. The `water_camp_tidal_cradle` camp row also occurs once, and its `at` coordinates in `data/config/water_camps.json:68–72` match both corrected components exactly.

The JSON parses successfully and retains the consumed format: a two-number `position` array. `scripts/ui/tab_settings.gd:424–430` reads those components into a `Vector2`; the teleport caller passes them as x and z. The mounted camp consumer, `scripts/world/water_camps.gd:17–21`, reads the camp's same two components into `Vector3(x, 0, z)` and obtains height from the world. The correction therefore points the catalogue at the authored camp anchor rather than the former landmark coordinate.

The commit contains no guard, camp placement, terrain, or F39 landmark changes. The current relevant catalogue, camp, consumer, Game guard, and water-world files have no diff against the reviewed commit. The existing guard at `autoload/game_state.gd:2938–2940` still refuses invalid ground or an unwalkable destination; this review does not weaken or bypass it.

**OPEN:** Native Medium subset capture must establish teleport success, stable walkability, framing, and the visible camp. Matching an authored camp coordinate does not prove the slope guard will accept it or that the resulting view is suitable. No runtime, visual-census, performance, or full art acceptance is granted here.
