# THINGS-SOLENE: Warder Solene and Keeper Hald stop washing out (F38#17)

**Row.** F38#17 (6.85 after CONVTIGHT). 3/3 in three batches: "Warder Solene's face is overexposed / blown out white".

**What I ruled out first (CPU).**
- The conversation key and rim lights: at a fifth of their energy her face is still white.
- Her appearance variant on its own: with it off, the plain grunt in her place washes out too.
- So it is the stronghold courtyard light on pale texels. A courtyard exposure change would touch every frame there; this arm is the per-character route instead (the Captain Marrow recipe, +1.40 on the GPU).

**Change** (two flags, both OFF; the overlay turns both on):
1. `character_body_flags.json things_self_lit_off_1112` (from 12 Nov): the two variants' bodies stop emitting their own albedo.
2. `character_appearance_variants.json` `lanekit_f38_17_solene` and `lanekit_f38_17_hald`, new block `body_model_floor_1113`: when on, the variant loads a second copy of its model whose embedded atlas is graded. `appearance_variants.gd with_floor_model` (12 lines) swaps the path; everything else about the variant is unchanged.

**The copies.** `solene_floor1_lod0.glb` and `hald_floor1_lod0.glb`, beside the originals, which are untouched. Each is the variant's own source model (`officer_b_lod0.glb`, `captain_b_lod0.glb`) with a graded copy of the same `vis1` atlas embedded by the existing `ralph/reports/LANES/ITEM-F38-17/embed_atlas_glb.py`; geometry, rig and clips are byte-identical. Grade: texels above 0.38 luma keep their hue and move half-way down to 0.38; darker texels and alpha unchanged. That is 2.6% of Solene's atlas and 5.0% of Hald's (skin, collar, highlights), so the plum hair, the tan skin and the dark uniform are the same colours, only less bright at the top. Sources, hashes and the grade are in `provenance_floor1.json` in each folder. `texture_import_policy.py --check` passes (1544 sidecars).

**CPU** (`_sheet_solene_floor_cpu.jpg`; left main, right arm; rows: conversation, face crop, at her post): **the change is small on CPU.** Her right cheek and jaw come out of clip and show skin tone; the forehead and left cheek are still white, and the hair still reads pink, not plum. The Compatibility renderer has no tone mapping, so it clips harder than the GPU does; Marrow looked much the same on CPU before his +1.40.

**What is probably left if the GPU agrees with the CPU.** The hair going from plum to pink means the courtyard is adding a lot of light to her mid-tones, not only her pale texels. That is the exposure question again, or a stronger grade (pulling everything above about 0.25 down), which starts to change how she looks. I have not done either.

**Identity.** Same mesh, same atlas layout, same portrait; nothing is repainted.

**Ask.** The Meadows dialogue set's Solene and Hald rows, base vs arm, High. Ship per the usual rule; a no-loss look at any other frame where either stands.
