# LAND-MT-CRAGBACK: light the inner side of the Veilfall crag shells

**Rows.** F39#19 fight team roster contrast 7.47 (0.03 short of 7.5; LANE-SCENE's ROSTERNAMES works the roster side), F39#7 fight actor composition 7.11. Both are judged on the Tidewake Venn fight frames.

**Defect.** GPU 1108 A.md, 3/3: "a hard black cliff wedge or void in the top-right corner of the Venn frames". LANE-SCENE relayed it as a black void past the dune.

**Cause, and how I know (four probes on the Venn fight, CPU, `phase2_capture_tidewake_fights.gd --trainer=water_trainer_venn --seed=2042`).**
1. Not sky or sea. The fight camera looks down, and the mass reads RGB about (2, 18, 26), against deep water at (0, 82, 122).
2. A camera ray through the corner puts the fight camera inside the bounds of the Veilfall crag kitbash meshes (`WaterVeilfall/VeilfallCragKitbash`: Crag_boulder_1 to 3 and CragCore, 700 to 1,100 m, no collider).
3. The look profile's crag colour override (`tidewake_look.json` `veilfall_family_candidate.crag_kitbash.crag_shader`) painted magenta for the wet band: the corner turned magenta and nothing else did. An earlier probe edited `water_veilfall_crag_kitbash.json` directly, which that override replaces, so it showed nothing.
4. In the crag shader, back faces painted green and front faces magenta: the corner turned green. So the mass is the **inner side** of a crag shell that dips around the arena.
- The shader is `cull_disabled` but never flips the normal for a back face, so the inner side is lit with the outer side's normal, which points away from the viewer. That is why it renders near-black.

**Change.** New uniform `back_face_lit` in `shaders/water_veilfall_crag.gdshader`: at 1 a back face takes the flipped normal and is lit as rock facing the viewer. Config key `crag_shader.back_face_lit` in `water_veilfall_crag_kitbash.json`, shipped 0.0. The overlay sets it to 1.0. Shader value only: no geometry, collision or camera change.

**CPU before / after.** `_sheet_cragback_off_vs_on_cpu.jpg`: left base, right arm, Venn fight t=4, 16 and 28 s. The top-right corner pixel goes from about (2, 18, 26) to (107, 125, 108): mid-grey lit rock. The fight is not deterministic run to run, so creature positions differ between the columns; compare the corner. 0 script errors.

**By-eye line for the GPU lane.** Venn fight frames: the top-right corner shows grey rock, not a black wedge. If it is still black, the overlay did not apply (check the merged `crag_shader` has `back_face_lit` 1.0): hold. Camera pairing per the GPU runbook (`pair_frames.py`), since fight framing varies.

**Risks and no-loss frames.**
- The lit inner side reads as a smooth grey rock wall. A judge may call it a grey slab; that is still a step up from a black void.
- The same crag shells make up the far Veilfall mountain (F39#2 6.79, F39#31 6.02, F13#5). From outside, the faces seen are front faces, so the far view should be unchanged. No-loss: the F39#2 job frames and one Veilfall vista.
- F39#7 and F39#19 also depend on the roster and creature framing, which this arm does not touch.
