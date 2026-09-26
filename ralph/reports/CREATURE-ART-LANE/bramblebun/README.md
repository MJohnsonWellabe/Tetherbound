# Bramblebun: Meshy candidates (WO-X04-BRAMBLEBUN)

Both candidates are **not integrated**. The shipped Bramblebun, `bramblebun_redesign`, is unchanged.

## Candidate 1: handover retexture, rejected (identity)

- **Task:** `01a0d688-9a9b-718d-83c8-d5e4c0ce9abf`, a texture-only retexture of the shipped `bramblebun_redesign` mesh.
  - The Meadows lane submitted it from an agent-drafted style image.
  - Full provenance is in `ralph/reports/MEADOWS-VISUAL-PASS/meshy-bramblebun-01a0d688/`.
- **Trial:** in-engine runtime A/B in the production Meadows world, day and night: `handover_01a0d688_world_ab.jpg`. Left is shipped, right is the candidate. The Meshy preview is in `handover_01a0d688_meshy_preview.jpg`.
- **Reasons for rejection,** against owner sheet `docs/art/reference/creature-expansion-2026-08-30/06_Bramblebun_redesign.png`:
  - The coat is flat orange-russet, and the sheet's leaf green is lost.
  - The green leaf ears are gone.
  - Pink spills onto the ear backs.
  - The brighter albedo also feeds emission on this material, so the body looks self-lit by day and pale and glowing at night.
  - It does separate from the grass better by day, but only through off-canon colour.

## Candidate 2: sheet-06 image-to-3D, blocked on rigging

- **Task:** `01a0d831-767e-7399-a6c6-26d962dd0954`, `/openapi/v1/multi-image-to-3d`, refine tier, quad remesh at 30k.
  - Cost 30 credits (balance went from 13,785 to 13,755).
  - Submission record (no key): `sheet06_01a0d831_submission.json`.
- **Input:**
  - The main view of owner sheet 06, used under the owner's lane-session approval ("cropped views count"; "your patch version of bramblebun is good").
  - Preparation: the label was removed with an edge-aware clone over the left ear, the background flattened, and the thorn red shifted to rust/ochre (red is reserved for Team Tether): `sheet06_01a0d831_meshy_input.jpg`.
  - The tool's built-in Bramblebun prompt describes the *old* design (purple flowers, teal eyes, banned "bushy tail"), so a sheet-06 prompt was used instead.
- **Result:** identity matches sheet 06.
  - Leaf-coat body, cream face and cheeks, pink-brown inner ears, rust thorn vines, bushy leaf tail.
  - One mesh, 65,783 triangles, one albedo, no normal map, no rig. It came back in the sheet's **crouched** pose.
- **In engine:** the rigged candidate was swapped into `species.json` locally and captured.
  - Turntable at the declared 2.05 m beside the 1.80 m trainer: `sheet06_01a0d831_turntable.jpg`. It reads correctly from every side.
- **Rigging attempts**
  1. `tools/art_pipeline/blender/rig_quadruped.py` (bone heat): "Bone Heat Weighting: failed to find solution", 33,454 of 33,454 vertices unweighted. The pipeline's clean-donor route (`cleanup_mesh.py` voxel manifold, then `skin_transfer.py`) failed the same way, also at ×10 scale. Bone heat itself works in this Blender (bpy 5.0.1, a control test weighted 98/98).
  2. The same bone placement with nearest-bone-segment distance weights (two bones, inverse-square): every vertex weighted, then `animate_quadruped.py`.
     - Clip poses: `sheet06_01a0d831_clip_poses.jpg`. Rows are idle, walk, run, attack, hit, faint, each at 25/50/75%.
     - **Idle and hit are clean. Walk, run and attack tear:** stretched geometry smears the chest and face, with white streaks.
     - Cause: the rigger drops each leg bone vertically from the spine above the leg cluster, but the crouched pose extends the forelegs far forward. Leg motion therefore drags chest and face vertices. This fails the ACCEPTANCE §4 deformation/clipping bar.
- **Decision:** not integrated.
  - Two rigging approaches have failed on this pose, so the next step is a changed approach: one more scoped task on the same approved image and prompt, asking for a neutral standing pose. That shape is what `rig_quadruped` handles for the rest of the roster.
  - That is a second credit spend (about 30), and it waits on the owner's approval.
  - The unrigged, rigged and animated candidate files stay in git-ignored `assets_raw/bramblebun_sheet06/` in the lane container.
