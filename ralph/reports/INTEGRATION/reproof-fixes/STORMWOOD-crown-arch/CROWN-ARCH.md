# Stormwood Crown Arch "fall-through": diagnosis and fix

**Verdict: debug-only. The trainer did not fall through anything, and players cannot reach the spot.** Fixed in commit `fix(stormwood): Crown Arch debug spot on the crown floor; debug travel refuses unwalkable ground` on `tb/reproof-fixes`.

Source of the report: the F26 Low capture `stormwood__hollow_crown__07__the_crown_arch__day` (`tb/lookdev-low`, `ralph/reports/LOOKDEV/f26-low/census-low-receipt.json`), which recorded `player_position` y=20.85 against terrain 54.3 after debug travel to (459, 2700). The harness was `tools/capture_renderer_material_census.gd` (`catalogue_survey.gd`).

## What happens there

`probe-old-spot.txt` is a headless probe of production Stormwood. It runs the harness's own steps: `Game.debug_teleport_to`, 20 frames, the re-seat on `resolve_capture_ground`, then frame logging.

- (459, 2700) is on the Hollow Crown's **outer wall**. The terrain normal there is (-0.97, 0.24, 0), a 76-80° slope against the player's 45° `floor_max_angle`. `ground_height_at` around the point reads 74 m 10 m east (the crown floor) and -45 m 20 m west.
- The heightmap collision is present the whole time. A ray from the trainer always hits `Terrain` 1-1.5 m below it.
- The trainer, set down on the face, is never on the floor, so it slides down the wall (y 54.7 → 42.6 by frame 50, which matches the recorded 20.9 at the capture's frame budget). Fall recovery then returns it to the realm entry, at about frame 135.

## Why players cannot get there

- `stormwood_world.json`: "The Crown has only a linked-arch entry". The `hollow_crown` region is `access.mode: arch_only`.
- The Crown Arch `e_crown` (`stormwood_arches.json`) is at (485, 2700), facing yaw 90°. It is linked from the Still Grove footing. Its arrival side and the floor east of it are flat terrain at y=74.
- Arrival, a reload inside the region and respawn therefore all place a player on the crown floor. The spot's comment ("ordinary west-side Crown arrival, 26 m before the arch") describes a western approach that the terrain no longer offers.

## Fix (debug travel only)

- The spot moves to **(511, 2700), heading -90°**: on the crown floor, 26 m east of the occupied arch seat, facing west back through the arch. Probe (`probe-new-spot.txt`): the trainer lands at y=74.0 on 0° ground and stays `floor=true`, `vy=0` through 120 frames.
- `Game.debug_teleport_to` now refuses a destination steeper than the player's `floor_max_angle`, measured from `ground_height_at` samples ±1 m. A built floor is exempt, and no raycast is used, per the function's own contract. A capture of a cliff face now fails ("Game.debug_teleport_to refused destination") instead of recording a slide. (459, 2700) is refused (`probe-new-spot.txt`, first lines).
- `tests/test_four_biome_debug_teleport.gd` now pins the new spot with the same clearance (≥25 m from the arch seat) and facing rules. All 12 test files that use debug travel or the spots file pass.

## Sweep of every curated spot (`spot-slope-sweep.txt`)

All 58 spots across the four biomes were checked against the new guard. 57 are walkable; the steepest is 27.2°. **One other spot is refused: Water, Tidal Cradle Saddle Camp (841.4, 1595.9), at 46.8°.** The F26 judge flagged the same frame ("the trainer stands on an unbroken slope of roughly 45°… tilted as if sliding"). Its anchor in `water_world.json` is marked "analytic base-surface sample, not validated traversable terrain". Whether the camp itself sits on unwalkable ground is a Tidewake placement question for the Water owners. It is not moved here; the capture now fails instead of recording a slide.
