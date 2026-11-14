# BEINGS-RIPPLET-DEEP: Ripplet's fur reads as fur and separates from the sand (F39#19)

**Status: CPU-ready, not queued.**

**Row:** F39#19 Venn fight, 6.92 at High and Medium (G-land-mt-cragcut, a normal panel, control 8.08). Its biggest lever (3/3 top ask): Ripplet is "flat, glossy cyan with a toy-like plastic finish", little fur or scale detail, and "its pale value nearly merges with the pale sand".

## Cause, and how it was confirmed
- The live albedo (`creature_ripplet_owner1101_Image_0.jpg`, no coat flag on it) is a light teal with cream: mean texel value 0.58, close to the pale dune.
- The fur strokes in the texture are low-contrast, so at fight distance the body reads as smooth.
- Emission is not the cause: the glow map lights 0.5% of the texture.
- The live finish is roughness 1.0, specular 0.5 (probe).

## Change
`data/config/creature_coat_flags.json beings_ripplet_deep_teal` (OFF): the teal fur only (hue 160-205, saturation 0.18-0.55) goes a deeper sea-teal (value x0.72, saturation x1.12), the fur grain is sharpened over the whole coat, and the finish is matte (roughness 0.95, specular 0.2). Cream belly, eyes, claws and the cyan glow marks keep their pixels. Same species, silhouette and colours; one elemental trait unchanged. Made by `derive_deep_teal.py`. The earlier natural-otter recolour (`creatures_ralph_ripplet_otter`) lost on CPU and stays OFF; this keeps Ripplet's own palette.

## CPU
`_sheet_cpu_stage_base_top_arm_bottom.jpg` (stage; hit 000, hit 050, faint 100). Arm: a deeper teal coat with visible fur strokes against the cream; base: light flat cyan.

## By-eye line for the GPU lane
On `tidewake__fight__venn__t-000_00`, Ripplet is a clearly darker teal than the dune with visible fur texture. If it still reads as a pale cyan shape on the sand, hold.

## Not this arm, but recorded
- The "WIND" label judge b read as Ripplet's element is the ally's Wind resource bar label (`combat_hud.gd _build_wind_bar`), not an element tag. Ripplet is water in `species.json`. A UI readability note for whoever owns the fight HUD, not a data bug.
- Cannonback's shell gold "smeared decals" (same verdict) is not addressed here.
- The stage faint ends belly-up with the dorsal stones down (seen on CPU); not judged on this row.

## Tests
`tests/test_beings_ripplet_deep_teal_flag.gd` plus the coat tests: 10 tests, 0 failed.

## Landing notes
Flag ON with `_why_on`; turn `test_flag_is_off_scoped_and_keys_ripplet_only` into an ON pin.
