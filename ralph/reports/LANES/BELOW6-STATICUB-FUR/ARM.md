# BELOW6-STATICUB-FUR: the salmon-pink background bears (F41#8, F41#18, and the Staticub rows)

Rows it should help: F41#8 named silhouettes (5.80) and F41#18 uniforms (5.89), where the bears stand behind the cast; plus Staticub's own creature rows.

Named 3/3 on three panels (G-places-stormlight, G-things-stormuniform, G-below6-namedfaces): the bears behind the Stormwood cast are "flat salmon pink" and "read as placeholders". Nobody had worked on it.

## What they are

Wild Staticub on the r10 model, not the owner style-bar Stormursa. The fur texture is warm brown (mean RGB 113, 79, 60). Two things turn it salmon:
1. the shipped value-lift coat (`creatures_ralph_staticub_value_lift`, ON) is paler (138, 101, 79);
2. Stormwood's violet light adds blue to a warm brown.

CPU crop of the body: 196, 164, 158 with the lift; 175, 134, 130 with the lift off (still pink). The night emission floor is not the cause: it is scaled to near zero on the GPU renderer and the GPU frames show the same pink.

## Arm

`data/config/creature_coat_flags.json` `below6_staticub_storm_fur` (OFF): albedo `creature_staticub_r10_Image_0_storm.png`, derived by `make_storm_fur.py` from the model's own albedo: fur darker with blue pulled down (x 0.86, 0.80, 0.62) and the fur detail put back; arcs, eyes and muzzle untouched. When ON it replaces the value-lift copy for this model. Overlay: `overlay.json`. No Meshy generation.

## CPU

`_sheet_cpu_base_left_arm_right.jpg`: `phase2_capture_creatures.gd --biome=stormwood --only=staticub`, idle, cropped. Body crop mean 196, 164, 158 to 159, 111, 94. The bear reads as a brown bear with visible fur, blue eyes and the violet arc on its flank.

## For the GPU run

- Judge F41#8 and F41#18 (same frames as G-things-stormuniform: the bears are in Maud's, Bryn's and Nysa's frames) and Staticub's creature rows.
- No-loss: Staticub outside Stormwood (Meadows or stage light), since the coat is per model, not per biome. In daylight it will be a darker brown than the lifted coat; the lift was judged ON at 6.80 (`test_dark_value_lift_flags.gd`), so if it loses in daylight the coat needs a Stormwood-only switch.
- The landing must add this flag to `LATER_COATS` in `tests/test_dark_value_lift_flags.gd`, as Stormraven's did.

Also seen in these frames: the cobalt ravens beside the bears are the pre-night-coat Stormraven; main now has the night coat (#938).
