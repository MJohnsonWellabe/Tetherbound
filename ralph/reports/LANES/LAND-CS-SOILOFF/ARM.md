# LAND-CS-SOILOFF: remove the black cut-out patches from the Stormwood ground

Branch `tb/land-cs`. Flag `stormwood_ground_finish.json forest_layers_1113`, OFF on the branch; `overlay.json` turns it on. Replaces THINGS-STORMPOOL round 2 (same rows, same patches; that arm only made them matte).

## Rows and scores (GPU High, mapped)
- F41#22 and F41#24, 6.46 (the matrix and cleanliness rows).
- Riding, same ground in frame: F41#5 6.53, F41#12 6.90, F41#2 6.19.

## Defect, as the judges put it
- `G-baseline-f41-22-f41-24`: "the black pools read as hard-edged, jagged cut-out holes, not water" (forest, hollows; all judges).
- `G-rescore-f41-22-24` (3/3): "a flat, hard-edged grey rectangular slab at the trainer's feet in the Break frame" (giant, forest) and "flat hard-edged black pools" (giant, forest, rod_line).
- `G-places-stormlight`: "Stormwood ground and road value is the shared ceiling".

## Cause, and how I know
The patches are the `forest_layers` `wet_soil` tier: 1,400 opaque near-black discs about 2.8 m across (`stormwood_ground_cover.gd _wet_soil`, tint `#1e2420`), with a ragged rim cut by alpha scissor (`stormwood_ground_cover.gdshader:668`). Where they overlap they make the big black cut-outs; their wet gloss mirrors the pale Break sky, which is the grey slab.

Confirmed by switching that one layer off and capturing the same stands at the same camera (CPU, `capture_stormwood_f10_matrix.gd`, forest and giant, Calm):
- Base: a jagged dark patch fills the lower half of forest_calm and the ground at the trainer's feet at giant_calm. It has the same shape and place as in the GPU frames (`tb/gpu-frames-1108`, `G-things-stormpool/base-High`).
- Layer off: the patch is gone at both stands. Nothing else in the frame moves. The terrain's own pool zones are still on in that run, so they are not what draws it.
- forest_calm lower half: pixels darker than 40/255 fall from 46% to 26%; mean brightness 57 to 67.

THINGS-STORMPOOL round 1 changed the terrain pool zones and was held on the by-eye check; round 2 named this layer but kept the discs.

## Change
- `stormwood_ground_cover.gd forest_layers()`: the layers are a JSON list, which an overlay cannot address, so the flag patches layers by name. A layer left with `enabled` false is not built. OFF returns the shipped layers unchanged.
- Arm: `layers.wet_soil.enabled` false. What shows instead is already there: the moss floor texture, the soft loam zones in the terrain shader, leaf litter and the understory.
- Presentation only. No terrain, collision, route or scatter-state change.

## CPU before and after
`_sheet_cpu_base_vs_arm.jpg`: forest_calm and giant_calm, base left, arm right. The arm side was captured through the flag (overlay applied). Break and rod_line arm frames were also captured through the flag: no black patches at the road edge either.

Not shown on CPU: the Break slab. The Compatibility renderer draws almost no specular, so the slab does not appear on either side here. With the discs gone there is no glossy surface left there to mirror the sky, but that is reasoning until the GPU frame shows it.

## By-eye line for the GPU lane
- forest_calm: the black jagged patch across the lower half of the frame, in front of and beside the trainer, is gone; mossy ground with litter shows.
- giant_calm: the black patch under the trainer's feet is gone.
- forest_break and giant_break: no pale flat slab left of or behind the trainer.
If the black patches are still there, hold the arm.

## Risks and no-loss frames
- The floor may read as a more uniform green ("one moss carpet" was the defect the layers were added for, 25 Oct). The loam and moss zones and macro variation are still on. If judges name it, the next arm restyles the layer as small soft litter patches through the same flag (`layers.wet_soil` values), rather than putting the black discs back.
- No-loss: glass and stormheart (as in the stormpool capture), rod_line for F41#12.
- `pool_damp_1112` and `wet_gloss` are not in this overlay.

## Tests
`tests/test_stormwood_forest_layers_flag.gd` (OFF keeps both layers unchanged; ON drops wet_soil only; a patch by name applies and does not mutate the config), run with five existing Stormwood ground tests: 29 tests, 0 failed.
