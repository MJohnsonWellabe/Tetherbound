# BEINGS-WMONITOR-GROUND: the water monitor's mid-faint touches the floor (F36#92)

**Status: ready; overlay only.** Coordinator offered it a place as the fourth item in the pose batch (same tool, same config file, no code).

**Row:** F36#92 Water Mangrove Monitor, GPU High 7.47 (G-rescore-f36-50-c673, tb/judge ae67d0a5), 0.03 short of the bar. A close-out item: the owner's 12 Nov rule lets a small gain land on its own.

**Defect, quoted (3/3):** in faint-050 "a front leg is lifted or curled and hangs under the raised body"; one judge also sees a detached shadow.

## Cause, and how it was confirmed
The water monitor's own faint row sets `crumple.limb_sink_frac` to 0.15 (12 Nov, to stop the body sinking out of sight at the end). That number is how far limbs may pass below the floor when the body is planted. Mid-clip the legs still hang straight down under the trunk, so at 0.15 the trunk is held up on them: the body floats with its feet dangling and the shadow apart (CPU base, faint-050).

Confirmed by changing only that number: at 0.5 the trunk comes down at faint-050 and the feet meet the floor; faint-075 and faint-100 are the same as base on CPU, because by then the torso is already down. Also tried and rejected: adding the species to `faint_fold` (it rolled the body onto its back).

## Change (overlay only)
`data/config/creature_pose_settle.json` `faint.per_species.water_mangrove_monitor.crumple.limb_sink_frac`: 0.15 to 0.5. The row keeps `min_top_frac` 0.5, which is what stops the end pose sinking away.

## CPU before and after
`_sheet_cpu_base_top_arm_bottom.jpg` (faint 025, 050, 075, 100). Base faint-050: body in the air, legs hanging, shadow detached. Arm faint-050: body lower, front and hind feet on the floor, shadow under the body.

## By-eye line for the GPU lane
`water_mangrove_monitor-faint-050`: the feet touch the floor and the shadow meets the body. If there is still a gap between feet and shadow, hold. `faint-100` should look the same as base.

## Risks
- The front leg is still straight, not folded under: the judges' wording is "fold the leg under the body". This grounds the body; it does not fold the leg.
- Not addressed: the dark dorsal side (1/3) and the tail tip clipping at faint-100 (1/3).

## F36#50 (base Mangrove Monitor), the coordinator's question
Captured on CPU at this head: the base species does **not** have this defect. Its faint sinks straight down with all four feet on the floor in every frame. It still needs its own GPU capture (`--species=mangrove_monitor`) for a score.

## Landing notes
One value in the species row with a `_why`; a pin test on that value. Then High and Medium in a confirming batch to close.
