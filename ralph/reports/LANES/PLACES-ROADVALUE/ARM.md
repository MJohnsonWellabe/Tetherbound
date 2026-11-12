# ARM: road_value_1112 (Stormwood ground and road value), LANE-PLACES, 12 Nov 2026

Branch `tb/places`. Ships OFF. Two overlays, to be captured in one run against one base:
- `overlay.json`: the full arm (lifted road, satin puddles, softer blend, lifted pools).
- `overlay_no_puddles.json`: the same without puddles.

## Why
`G-places-stormlight`, all three judges, the shared ceiling on the Stormwood rows: "near-black mud and road with hard cut-out edges", "flat green carpet with black blotch decals". They ask for a wet dark-umber road with puddle highlights and blended edges.

## Change (`stormwood_ground_finish.json road_value_1112`, `stormwood_ground_zones.gd`)
- Road and damp slots rise from near-black to a cool dark umber (`#8f9280`, `#9a9a86`; green at or above red, so nothing reads salmon under the lilac light). The lighter warm path of swing-1 lost; this is cooler and darker than that.
- Terrain texture blend softened (`blend_sharpness` 0.5 → 0.12), so the road feathers into the moss.
- Zone pools lift toward the loam (`#31342b`) with a wider feather, so they stop reading as black decals.
- Puddles (full overlay only): small wet patches on bare earth and road within 70–130 m of the camera, satin (roughness 0.42, specular 0.3), 28% darker.

No geometry, route, collision or bake input. Works with `storm_phase_1111` (the bolt light gives the wet road its highlights).

## CPU proof and what it showed
`_sheet_cpu_base_vs_arm_r1.jpg`: F41#12 lantern_hollow day, glass_field, lantern_hollow night; base row, then arm row. The road has value and softer edges in the arm.
**Round 1 puddles were wrong:** large mirror puddles reflected the sky as lilac slabs (a defect judges named before). I cut them to small satin patches (the values above) and did not re-capture on CPU, so the puddles in `overlay.json` are unverified in frames. That is why the no-puddle overlay is sent beside it.

## Reject if
Lilac or white puddle slabs; a salmon or pink road; the road reading as dry sand.
