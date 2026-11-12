# THINGS-STORMPOOL: the grey slab and the black pools on the Stormwood ground (F41#22, F41#24)

**Rows.** `G-rescore-f41-22-24` (tb/places): F41#22 and F41#24 both 6.46. 3/3: "a flat, hard-edged grey rectangular slab at the trainer's feet in the Break frame" (giant, forest) and "flat hard-edged black pools" (giant, forest, rod_line).

**Cause (read from the GPU frames and the shader).** They are one thing. `stormwood_ground_zones.gd` paints the lowest loam as "pool" patches: near-black (#22241f) with a satin sheen (roughness 0.62, specular 0.1). In Calm that is a black cut-out; in Break the sheen mirrors the pale flash-lit sky and the same patch turns into a flat pale slab. Its edge is hard where the patch meets the path.

**Change** (flag `stormwood_ground_finish.json pool_damp_1112`, OFF; one name added to the finish candidate list in `stormwood_ground_zones.gd`). Rides last over `wet_earth_1110`: pool colour #22241f -> #33362c, roughness 0.62 -> 0.96, specular 0.1 -> 0.02. Damp matte earth a step above the soil: nothing to mirror the sky, and close enough in value to the loam that the edge stops reading.

**CPU, and its limit** (`_sheet_pool_off_vs_on_cpu.jpg`; left main, right arm; top Calm, bottom Break; `phase2_capture_storm_phases.gd` at the Fallen Giant). The flag applies: the lower half of the frame is a little lighter (mean brightness 48.5 -> 53.1 in Calm, 25.8 -> 27.6 in Break) and nothing else moves. **This stand does not show the slab**, and the CPU renderer has no flash-lit sky reflection, so the fix for the slab itself is not demonstrated here. It needs the GPU's own giant and forest frames.

**Ask.** The G-rescore-f41-22-24 stands (giant, forest, rod_line; Calm, Break, aftermath), base vs arm, High; glass and stormheart as no-loss.
