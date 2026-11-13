# BELOW6-PERCH-COURT: High Perches court floor sometimes draws as bare grass (bug fix)

Rows held: F40#0, F40#21 and every F40 capture through stands 07 and 08 (G-things-cloudrain-r2: night rain -0.38, F40#21 -0.13, "placeholder geometry" 3/3).

## Cause

Not a load order, LOD or streaming fallback. The court's stone apron (`LandingApron` in `scripts/world/cloudreach_high_perches_presentation.gd`) was a 0.13 m slab, so its top stood 3 cm above the landmark crown's turf (crown top +0.10). At that gap the turf wins the depth test in some views and the apron vanishes, leaving the compass ring and rays on grass.

- In the GPU frames it changes by view inside one boot and on both sides: base shows cobbles in gameplay and detail but grass in reverse and approach-night; the arm shows cobbles in gameplay-day and grass in gameplay-night.
- On CPU the apron never showed at all (my earlier High Perches captures have only the thin gold ring on grass).

## Fix

`data/config/cloudreach_high_perches_visual.json` `landing_apron_top_m: 0.22` (code default stays 0.13 when the key is absent). The compass rings and rays ride on the apron top. Visual only; no collision or traversal change. The trainer's soles sit a few centimetres into the stone, as they did when the apron showed.

## Proof

`_sheet_bug_top_fix_bottom.jpg`: top row, two GPU frames from G-things-cloudrain-r2 with the grass disc (arm gameplay night, base reverse day); bottom row, CPU with the fix (court from its south edge at 0.24, and standing on it at the shipped 0.22). The cobbled court draws in both CPU views, where it never drew before.
`tests/test_high_perches_apron_clears_turf.gd` plus the existing High Perches tests: 5 tests, 0 failed.

Not checked on the GPU: please confirm with one High Perches piece (reverse and approach views) before trusting F40 captures through stands 07 and 08.
