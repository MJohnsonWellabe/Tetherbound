STATUS: blocked
BRANCH: tb/item-f38-41  HEAD: see origin (work in progress, paused by coordinator order 7 Nov for F38#5 and the Warrens rim)

Lane LANE-MS. Row F38#41 (Old Quarry boulders, raw 6.43). Not judged yet; nothing is ON.

**Built (OFF):**
- `assets/environment/stylized_nature_q41/Rock_Medium_{1,2,3}_q41.glb`: a Blender recombination of the installed `stylized_nature/Rock_Medium_*` meshes. The seam vertices are welded, then the mesh is subdivided, given voronoi fracture plus cloud-grain displacement and decimated, with box UVs at 1.6 m per repeat, wearing the installed Rock030 stone.
  - Footprint and height are the same as the sources.
  - Script: `blender/rock_medium_q41.py`.
  - Preview and scale: `blender/render_preview.py` (1.80 m bar).
- `scripts/world/old_quarry.gd`: optional `worked_cut.natural_face_models` (default unchanged).

**Finding:**
- The two big smooth foreground boulders in the judged quarry frame (`catalogue_survey --subset=quarry`, day) are neither the band2 `quarry_station` nor the `old_quarry_cut_face` props, nor the worked faces.
- `tests/probe_camera_pixel.gd` names them `/root/MeadowsPlayground/@Node3D@64198/@Node3D@64199/Rock_Medium_12/Rock_Medium_1` and `.../@Node3D@64196/.../Rock_Medium_32/Rock_Medium_3`. These are unnamed holders, likely scatter or another placer.
- The swap of those two clusters and the worked faces changed only the background spoil.
- Next: find that placer (grep the owners of unnamed Rock_Medium holders near (406,1799) and (400,1792)), point it at the q41 models, then capture and judge.
