# Officer Venn Graded Approach Repair

Date: 2026-09-08
Scope: the exterior `veilfall_exploration_spine` p3-to-Officer-Venn approach and
production challenge offer. This is a bounded route diagnostic, not fresh-save,
fight-victory or complete Water-chapter evidence.

## Fixture boundary

`tools/probe_water_venn_approach.gd` boots the production Water world, sets the
already-earned combined Sluice-control prerequisite, supplies a healthy level-60
Aquaryn, and places the player at authored graded spine point p3. It deploys Aquaryn
with controller input. Every metre from p3 to Venn and every interaction stance is
then reached using ordinary player-controller movement.

Command: `Godot_v4.7-stable_win64_console.exe --headless --path . --script
tools/probe_water_venn_approach.gd`

## Baseline

Log: `C:/Users/mattj/AppData/Local/Temp/water-venn-approach-baseline.log`

Production reused the `water_venn` NPC placement, not the unused coordinate on the
trainer row. Venn therefore stood at `(200.0, 619.079, 4152.0)`. This supersedes the
earlier source-only `(182, 4100)` estimate.

- Venn's XZ was 45.273 m from the nearest spine segment, but on the ungraded mountain
  crown hundreds of metres above that segment.
- The p3-to-Venn chord measured 517.635 m in 3D. Of 255 approximately one-metre
  samples, 193 exceeded the 24-degree route contract and the largest adjacent height
  step was 5.785 m.
- The real-stick walker stopped at `(177.803, 182.578, 4192.187)`, still 438.909 m
  from Venn. It reported no confinement reset and only Terrain at the player, so this
  was not a movable-object obstruction. No challenge offer was available.

## Repair

Only `water_venn`'s NPC island-local placement changed, from `(0, 0, 12)` to
`(111.779, 0, -245.567)`. Runtime grounds this at world
`(311.779, 141.188, 3894.433)`: exactly on the final graded p3-to-p4 segment and 25 m
before the authored waterfall gate. Venn's identity, role, team, level, flags,
dialogue and every other NPC remain unchanged.

## Validation

Log: `C:/Users/mattj/AppData/Local/Temp/water-venn-approach-final.log`

- Exit 0; clean `ERROR` / `SCRIPT ERROR` scan.
- Candidate route offset: 0.00025 m. The 349.490 m p3 approach had a maximum sampled
  one-metre height step of 0.1265 m and 0/349 samples over 24 degrees.
- The real-stick player reached Venn with zero confinement resets, then reached the
  first grounded production interaction stance.
- The live prompt was enabled and offered actionable `Challenge Officer Venn` at
  2.021 m. Neither actor nor prompt was teleported for this proof.
- `test_water_encounter_runtime_data.gd`: 9 tests, 2,197 assertions, 0 failures.
- JSON parse, probe parser check and `git diff --check`: passed.

The ongoing full Water continuous run remains the required proof that the fight,
waterfall entry and rest of the chapter work after this bounded approach.
