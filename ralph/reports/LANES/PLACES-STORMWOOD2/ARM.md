# ARM: Stormwood swing 2 (road value done right + Fading clear), LANE-PLACES, 12 Nov 2026

Branch `tb/places`. All flags ship OFF. Two overlays against one base (main d777b905 or later):
- `overlay.json`: `road_value_1112` + `contrast_1112` + `fading_clear_1112` (Fading's deck gaps closed).
- `overlay_keep_gaps.json`: the same, keeping Fading's deck gaps.

## Why
- `G-places-roadvalue`: the umber road (no puddles) gained on F41#12 +0.43, F41#5 +0.39, F41#2 +0.31, F41#8 +0.24 (3/3 each) but F41#4 lost twice because the gold path line lost contrast on the lighter road. Verdict: don't land alone; restore the gold line and ride it in a bigger pass.
- `G-places-stormlight`: all three judges, "Fading still looks too close to Building"; the render check measured Fading as the darkest phase.

## Change
1. `road_value_1112` (`stormwood_ground_finish.json`), exactly the judged no-puddles road: cool dark-umber road and damp slots, softer texture blend, lifted zone pools. Puddles stay parked (failed CPU and the GPU pre-check).
2. `contrast_1112` (`stormwood_road_current.json`): the gold current's core 1.25 → 2.1, edge 0.48 → 0.9, halo 0.07 → 0.16, hairline web 0.08 → 0.22. Yellow-gold only; flow, phase intensity and warning dimming unchanged.
3. `fading_clear_1112` (`stormwood_surge.json`, merged after `storm_phase_1111`): Fading's key 0.62 → 0.68 and fill 0.80 → 0.92, deck lifted and thinned (no darkening, lit tops, bright band), mist thinned to 0.45, shafts full. No lightning in any phase but Break.

## CPU proof (`_sheet_cpu_base_vs_arm.jpg`; base row, then arm row)
- Top: F41#4 fallen_giant, lantern_pools, crown_overlook. The road has value and the gold line is clearly stronger than base on the umber road.
- Bottom: F41#2 calm, building, break, fading. The road and gold line change shows in every phase.
- **Fading is not verified on CPU.** The CPU phase tool's Fading still repeats a Break frame (same on main before and after storm light, and unchanged by this arm), so I cannot see the Fading row here. That is why two overlays are sent. Please check the GPU Fading frame is brighter than Building and has no lightning.

## Landing note
With the flags ON one older pin needs its expected value updated: `tests/test_stormwood_pool_satin.gd::test_path_loam_ships_on_and_darkens_the_path` asserts the last enabled path tint (it expects wet_earth_1110's). All other Stormwood, surge and road-current tests pass with the flags ON (565 of 566).

## Reject if
The gold line blooms into a wide yellow band; the road reads as dry sand or salmon; Fading shows any bolt.
