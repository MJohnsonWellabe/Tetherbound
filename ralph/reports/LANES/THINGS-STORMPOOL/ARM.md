# THINGS-STORMPOOL: the grey slab and the black pools on the Stormwood ground (F41#22, F41#24)

**Rows.** `G-rescore-f41-22-24` (tb/places): F41#22 and F41#24 both 6.46. 3/3: "a flat, hard-edged grey rectangular slab at the trainer's feet in the Break frame" (giant, forest) and "flat hard-edged black pools" (giant, forest, rod_line).

**Cause (read from the GPU frames and the shader).** They are one thing. `stormwood_ground_zones.gd` paints the lowest loam as "pool" patches: near-black (#22241f) with a satin sheen (roughness 0.62, specular 0.1). In Calm that is a black cut-out; in Break the sheen mirrors the pale flash-lit sky and the same patch turns into a flat pale slab. Its edge is hard where the patch meets the path.

**Change** (flag `stormwood_ground_finish.json pool_damp_1112`, OFF; one name added to the finish candidate list in `stormwood_ground_zones.gd`). Rides last over `wet_earth_1110`: pool colour #22241f -> #33362c, roughness 0.62 -> 0.96, specular 0.1 -> 0.02. Damp matte earth a step above the soil: nothing to mirror the sky, and close enough in value to the loam that the edge stops reading.

**CPU, and its limit** (`_sheet_pool_off_vs_on_cpu.jpg`; left main, right arm; top Calm, bottom Break; `phase2_capture_storm_phases.gd` at the Fallen Giant). The flag applies: the lower half of the frame is a little lighter (mean brightness 48.5 -> 53.1 in Calm, 25.8 -> 27.6 in Break) and nothing else moves. **This stand does not show the slab**, and the CPU renderer has no flash-lit sky reflection, so the fix for the slab itself is not demonstrated here. It needs the GPU's own giant and forest frames.

**Ask.** The G-rescore-f41-22-24 stands (giant, forest, rod_line; Calm, Break, aftermath), base vs arm, High; glass and stormheart as no-loss.

## Round 2 (13 Nov): the sheen is the wet-soil patches, not the pool zones

**Round 1 was held by the GPU lane's by-eye check** (`tb/gpu-frames-1108` 47d9ba2c7): the pale slab left of the trainer went dark at giant_break, but a new pale sheen showed behind the trainer and on forest_break's right-hand patch; Calm barely changed.

**What draws it.** The dark ragged-edged patches in those frames are a second layer, not the terrain's pool zones: `stormwood_ground_finish.json forest_layers.wet_soil`, 1,400 flat `stormwood_wet_soil` meshes about 2.8 m across (`stormwood_ground_cover.gd _wet_soil`). Their finish comes from `wet_gloss` (roughness 0.55, specular 0.2), which `pool_damp_1112` never touched. At a grazing camera angle that is glossy enough to mirror the pale Break sky.

**Change** (`overlay_pool_damp_r2.json`, overlay only, no code): round 1's `pool_damp_1112` ON, plus `wet_gloss` roughness 0.92 and specular 0.03, so the wet-soil patches are matte like the damp pools.

**Not on CPU.** The Compatibility renderer shows almost no specular on these patches, so I have not captured it; the two values are read at `stormwood_ground_cover.gd:53-55`.

**Not changed.** The patches stay near-black in Calm (tint `#1e2420`). If the judges still name black cut-outs, the next step is a lighter wet-soil tint.

**Ask.** The same five stands x Calm, Break, aftermath Calm, base vs arm, High. By-eye check first: the sheen behind the trainer at giant_break and on the right at forest_break should be gone.
