# PARKED (13 Nov): G-below6-uniforms DO NOT SHIP

F41#18 row 6.05 -> 5.59 (-0.46, 0/3): without the emission floor the coats "blend into the dark mud and purple mist", and the 0.6 rim and shoulder knots do not show at the normal camera. Dialogue gained (+0.41, 3/3) but the row loss blocks it. Second round under the stop rule (G-things-stormuniform +0.04), so lighting-only arms on F41#18 are parked. The flag, its code and its test are removed from tb/below6. Next lever per the judges: the cloth albedo itself (mid-value, with a strong cool rim) and one bright copper or steel rank accent sized for the normal camera.

# BELOW6-UNIFORMS: Stormwood uniform separation (F41#18)

Row: F41#18 (pooled GPU High 5.89). G-things-stormuniform (3/3): the emission floor at 0 removes the "chalky ghost wash", but the cloth then "sinks into the dark green and black ground" and no rank markers read at the inventory distance. The judges asked for the floor kept at 0, a cool pale rim, and a shoulder, collar or rank trim in copper or steel.

## Arm

`data/config/stormwood_character_presentation.json` `uniform_separation_1113` (OFF), read in `scripts/world/stormwood_character_presentation.gd`. For uniformed ranks only (grunt, officer, lieutenant, captain):

- emission floor 0;
- material rim 0.6 with tint 0.3 (was 0.28 / 0.12), so the dark cloth carries a pale edge;
- the existing `rank_marks_1104` shoulder knots and collar ring, in each identity's own copper or brass rim colour, at 62 percent of their authored size.

Civilians are unchanged. Captain Marrow keeps his own floor (`identity_floor_1112`). Presentation only. Nothing is red.

## CPU

`_sheet_cpu_dace_base_left_arm_right.jpg`: Lieutenant Dace, inventory camera (top) and dialogue (bottom), seed 2042. The cloth is darker and loses the grey wash, with a cool sheen on the shoulders, arms and shorts; the collar ring reads in conversation. The shoulder knots are small at this scale and barely read at the inventory distance. Only Dace was captured on CPU (the tool timed out before Varga and Sable).

Honest read: this is the judges' recipe, but on CPU the gain at the inventory camera is small. If the GPU pre-check shows the figure still merging with the road, the next lever is `mark_scale` up (0.62 to 0.9) and rim strength up to 0.75. I tried the knots at full size first; they read as ball joints.

Judge with: the F41#18 row (Varga, Dace, Sable), their dialogue frames, officer dialogue (Sera, Maren, Nysa) and civilian dialogue as no-loss.
