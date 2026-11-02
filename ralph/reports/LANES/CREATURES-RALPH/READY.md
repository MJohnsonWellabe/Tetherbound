# CREATURES-RALPH: running status

Branch `tb/creatures-ralph`. Capture and judging run in this container on CPU (coordinator, 2 Nov): import works with a partial import set (untracked temporary `.gdignore` files), and `capture_f36_poses.gd` renders on llvmpipe. Disk is about 300 MB free, so each set is imported, captured and dropped in turn.

## Done (CPU-provisional; batch these into the GPU confirmation pass)

- **Cliffspike** r1: 5.53 → 6.49 mapped (+0.96; target ≥ 5.80). GLB weight relax plus the coat flag `creatures_ralph_cliffspike_bands`. Ships as is.
- **Ashtusk** r1: 5.94 → 6.71 mapped (+0.77; target ≥ 6.60). Remake aspect textures plus rigid tusks in the Tuskroot GLB. Live only once `remake_owner1101_tuskroot` leaves HELD (Task 2).
- GPU form: `capture_f36_poses.gd -- --species=cliffspike,ashtusk --whole-body --context` with `remake_owner1101_tuskroot` enabled for Ashtusk; Forward+ 1920x1080, High first.

## In progress

- Set 3: Cragclaw, Craghorn, Mangrove Monitor, Cannonback. The shipped arms are captured. Fixes are ready:
  - weight relax on Craghorn (horn stretch 1.38 m → 0.17 m), Cragclaw (0.68 → 0.18) and Cannonback (0.69 → 0.26);
  - regional grades for the Monitor (countershading, scale detail) and Cannonback (weathered shell).
- Aquaryn and Duskhush: attempt 2 needs a silhouette-level change (see `r1/VERDICT.md`).

## Local checks

Not run yet. The required suite needs every remake imported, which does not fit this container's disk. Until I can run a scoped set, CI decides.

## Tools added (all without Blender)

- `tools/art_pipeline/relax_stretched_weights.py`: CPU skinning over gameplay clips, then a harmonic weight solve where triangles stretch.
- `tools/art_pipeline/rigid_bind_region.py`: binds a box region rigidly to one joint.
- `tools/art_pipeline/amplify_clip.py`: exaggerates a clip's rotations.
- `tools/art_pipeline/grade_regions.py` with `data/creatures/remake_grades.json`: regional coat grade by anatomy map.
- `tools/art_pipeline/grade_quill_bands.py`: banded quills.
