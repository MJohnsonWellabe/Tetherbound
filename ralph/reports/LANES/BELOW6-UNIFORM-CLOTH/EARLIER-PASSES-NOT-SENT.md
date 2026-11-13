# BELOW6-UNIFORM-CLOTH (F41#18): tried, NOT SENT

Ask (G-below6-uniforms, 3/3): "lit mid-value cloth" for the Stormwood uniforms, in place of the emission floor (ghost wash) or no floor (blends into the mud).

## What I built

`make_uniform_cloth.py`: derives a lifted-cloth copy of the three row bodies' textures (grunt_c for Dace, officer_a for Varga, former_tether_member for Sable), applied through `character_body_flags.json` `body_albedo_override`, with a lower uniform emission floor to match. Three texture passes, CPU-checked on Lieutenant Dace (inventory camera and dialogue).

## Why it is not sent

These textures are baked atlases with no garment masks, so cloth can only be picked by colour:

1. Pass 1 (neutral dark pixels only): the cloth lifts in patches and stays black in others. Blotchy.
2. Pass 2 (all dark pixels): `_sheet_cpu_dace_base_left_pass2_right.jpg`. The figure separates well from the mud, but the hair goes pale blue with the cloth, and the cloth is a noisy denim blue.
3. Pass 3 (warm dark pixels kept, so hair and leather are safe): `_sheet_cpu_dace_base_left_pass3_right.jpg`. Hair is right again, but the cloth is a mottled dark indigo, and at the inventory camera the figure is darker than base, which is the "blends into the mud" side of the defect.

None of the three is a clean mid-value uniform. I removed the textures, the body flag and the floor block from tb/below6; the script stays as the record.

## What would work

A per-garment mask for each uniform body (jacket, trousers, boots, gloves as flat regions), painted once in the UV layout, then a flat mid-value slate under the existing fold shading. That is art work on three atlases, not a colour filter. With it, the rank accent the judges ask for (one bright copper or steel piece per uniform) can be placed in the same mask.
