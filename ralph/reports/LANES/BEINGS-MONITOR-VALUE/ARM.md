# BEINGS-MONITOR-VALUE: lighter body value on both Mangrove Monitors (F36#50, F36#92)

**Status: CPU-ready, NOT queued.** Three of my arms are with the GPU. Coordinator: take it when a slot frees.

| Row | Score (GPU High) | Defect, quoted |
|---|---|---|
| F36#50 Mangrove Monitor | 6.70 | G-rescore-f36-50-mangrove-species, 3/3: "the body reads near-black" |
| F36#92 Water Mangrove Monitor | 7.03 (strict panel; 7.47 on the earlier one) | G-beings-wmonitor-ground, 3/3: still mid-value against the stage; "lift the dorsal and flank value" |

## Cause, and how it was confirmed
Material probe at this head (the materials each body actually wears in engine):
- the land form wears `creature_mangrove_monitor_r9_Image_0_olive.jpg` (the shipped olive coat), mean texel value **0.325**: a dark coat;
- the water form wears `mangrove_monitor_extracted_base_color_vivid.png`, mean value 0.519.

Neither has a value lift; sixteen other dark creatures got one in v1/b21-b28 and each gained. The land form's 0.325 is in the range of those species' pre-lift coats.

An earlier lane's note (`remake_grades.json`, 2 Nov) says a lighter *countershaded regrade* of the old remake read "more rubbery". That was a different model (owner1101, now off) and a different grade (a countershade that flattened the pattern). This one keeps hue and pattern and only raises midtones.

## Change
`data/config/creature_coat_flags.json` `beings_monitor_value_lift` (OFF): one coat per form, albedo only.
- Land: value gamma 0.66, saturation x1.15 (mean value 0.325 -> 0.464).
- Water: value gamma 0.80, saturation x1.05 (0.519 -> 0.581), gentler because it is already mid-value.
Derived by `derive_value_lift.py` in this folder. Hue kept; roughness, specular and the glow map unchanged. No new art.

## CPU before and after
`_sheet_cpu_land_base_arm_water_base_arm.jpg`, rows: land base, land arm, water base, water arm; tiles hit 000, hit 050, faint 050, faint 100. Land: the near-black olive body becomes a readable mid olive with its banding and the aqua line visible. Water: a smaller lift; cream belly and gold spots stand out more.

## By-eye line for the GPU lane
`mangrove_monitor-hit-000`: the body is clearly mid olive with visible cross-bands, not a near-black shape. If it still reads near-black, hold.

## Risks
- "Rubbery": if the judges call the lighter land coat plastic, the next step is a smaller lift (gamma 0.78) rather than dropping it.
- Not addressed: the land form's tail tip ending at the trainer's feet (F36#50), the water form's faint-end slump.
- No red: hue is unchanged (the test checks the mean hue stays in the green band).

## Landing notes
Flag ON with `_why_on`; turn `test_flag_is_off_and_keys_both_forms` into an ON pin. If only one form ships, drop the other coat key. Run `tests/test_dark_value_lift_flags.gd`; this flag does not override any lift listed there.
