# BEINGS-VERIDIAN-ANTLER: antlers follow the head (F36#85)

**Row:** F36#85 Veridian poses, GPU High 6.33 (G-rescore-tier2-batch-1). Also seen wherever a Veridian is hit or faints (F38#1, F38#2).

**Defect, quoted (3/3):** the antler slab "shoots up and back in a twisted spike" and "reads as broken geometry"; recorded defect "contorted faint neck" PRESENT 3/3.

## Cause, and how it was confirmed
The antlers are not posed wrong. They are skinned wrong.
- Weight probe on the live model (top 15% of the mesh by height, which is only antler): 52% head, 31% neck, 13% spine, 4% pelvis. So when the head turns away from the trunk in the hit and the faint, each antler is pulled between four bones and shears into a sheet.
- `tools/art_pipeline/relax_stretched_weights.py --dry-run --clips=hit,faint` on the live GLB: 1786 of 27998 triangles stretch more than 0.15 m (worst 0.72 m).
- Switching the suspected element off: with the antler vertices bound to the head alone, the slab is gone in every hit and faint frame (sheet).

## Change
`data/config/creature_model_flags.json` `beings_veridian_rigid_antlers` (OFF). It swaps Veridian's model for `creature_veridian_nat1024_rigidantler.glb`, a copy of the live `faint_headdown` GLB made with the two existing tools:
1. `rigid_bind_region.py <glb> head "0,1,0.66,1,0,1"`: 7182 vertices above 66% of the mesh height bound to the head.
2. `relax_stretched_weights.py <glb> --clips=hit,faint`: 2012 more vertices relaxed.

Result: triangles stretching over 0.15 m, 1786 to 107; worst 0.72 m to 0.24 m. Mesh, UVs, textures and every clip are the live model's. No Meshy, no new art.

## CPU before and after
`_sheet_cpu_base_top_arm_bottom.jpg`, the judges' crop and tiles (hit 000, hit 050, faint 050, faint 100). Base: antlers swell in the hit and become a long striped blade over the body in both faint frames. Arm: antlers keep their standing shape in all four. No CPU score taken (a CPU score closes nothing).

## By-eye line for the GPU lane
On `veridian-faint-050` and `veridian-faint-100`: the base shows a long pale-and-green blade rising from the head across the frame; the arm shows a normal branched antler at the head. If the blade is still there, hold the arm.

## Risks and no-loss frames
- Standing (`hit-000`) must be identical: the rest pose does not depend on weights.
- The ears sit just under the 66% line and still follow the head and neck as before.
- Still open on the row after this: the rider reads "doll-sized" in the ride frames (3/3), and moss noise (PARTIAL).

## Tried in the same pass, not sent
The same roster scan flagged Glimmermoth (369 stretched triangles), Tempestwing (737) and Mosshock (477). Relaxed copies cut the counts by 85 to 96 percent but showed no visible change on the pose stage (their wings and spikes have no bones of their own, so they stay upright with the trunk). Removed. Solmane is the worst in the roster (4430 of 27992, worst 2.73 m) and not a row of mine below 7: worth one look by whoever takes its Medium close-out.

## Landing notes
Add the ON pin by turning `test_flag_is_off_and_declares_scope` into an ON assertion with `_why_on`, and remove the flag from `HELD` in `tests/test_creature_model_flags.gd`.
