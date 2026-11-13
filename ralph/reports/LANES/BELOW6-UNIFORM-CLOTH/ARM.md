# BELOW6-UNIFORM-CLOTH: mid-value uniform cloth and a brass shoulder band (F41#18)

Row: F41#18 Stormwood uniforms (GPU High 5.89; Dace, Varga, Sable). G-below6-uniforms, 3/3: the ask is "lit mid-value cloth" (neither the ghost wash nor blending into the mud) and "one bright copper, glass or steel rank accent per uniform, sized to read at distance".

## How the mask is made

Colour selection on the baked atlases failed three times (`EARLIER-PASSES-NOT-SENT.md`). This arm uses the coordinator's idea: the mask comes from the mesh. `make_uniform_cloth_mesh.py` reads each body's `.glb` (UVs, joints, weights; the file is not modified), finds each triangle's dominant bone, and rasterises into UV space the triangles led by a garment bone (hips, legs, feet, spine, shoulders, upper arms). Head, neck, forearm and hand triangles are left out, which covers hair, face and bare skin. The probe: 8 to 18 percent of triangles have no bone above half weight, and the mask islands line up with the atlas.

## Arm (one overlay, `overlay.json`)

1. `data/config/character_body_flags.json` `below6_uniform_cloth` (OFF): `body_albedo_override` for `grunt_c` (Dace), `officer_a` (Varga) and `former_tether_member` (Sable), each a `_cloth2.png` copy of its live texture. Inside the garment mask the dark cloth is lifted to a cool mid-value slate with its folds kept; bright pixels there (skin at a short sleeve, the emblem, buckles) are kept. Triangles led by a shoulder bone carry a brass band.
2. `data/config/stormwood_character_presentation.json` `uniform_cloth_floor_1113` (OFF): uniformed ranks take an emission floor of 0.04 in place of 0.18, since the floor only washed lit cloth. Not to be enabled without the cloth.

Nothing is red. No Meshy generation.

## CPU

`_sheet_cpu_dace_base_left_arm_right.jpg`: Lieutenant Dace, inventory camera (top) and dialogue (bottom), seed 2042. At the inventory camera the uniform is a mid slate that separates from the brown mud, and the brass shoulders read as two bright accents. Hair and skin are as on base. In dialogue the cloth has some mottle left from the baked texture.

Only Dace was captured (the tool times out before the other two here). Varga and Sable use the same script; their textures were generated and imported, and the pre-check will be their first look. Other characters who share these three bodies also change, in any biome: `grunt_c`, `officer_a` and `former_tether_member` are shared rigs. That needs a no-loss look outside Stormwood.
