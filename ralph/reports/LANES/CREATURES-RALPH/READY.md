# CREATURES-RALPH: running status

Branch `tb/creatures-ralph`. Capture and judging run in this container on CPU (coordinator, 2 Nov): import works with a partial import set (untracked temporary `.gdignore` files), and `capture_f36_poses.gd` renders on llvmpipe. Disk is about 300 MB free, so each set is imported, captured and dropped in turn.

## Done (CPU-provisional; batch these into the GPU confirmation pass)

- **Cliffspike** r1: 5.53 → 6.49 mapped (+0.96; target ≥ 5.80). GLB weight relax plus the coat flag `creatures_ralph_cliffspike_bands`. Ships as is.
- **Ashtusk** r1: 5.94 → 6.71 mapped (+0.77; target ≥ 6.60). Remake aspect textures plus rigid tusks in the Tuskroot GLB.
- **Tuskroot remake ON** r4 (takes Ashtusk live). Installed → remake mapped: Tuskroot 6.85 → 7.06; Ashtusk 5.36 → 7.27. The Tuskroot GLB weights are relaxed. Commit "r4".
- **Craghorn** r2: 5.75 → 6.45 mapped (+0.70; target ≥ 6.12). Weight relax in the GLB (horn stretch 1.38 m → 0.17 m). Ships as is.
- **Cannonback** r6: 5.33 → 6.22 mapped (+0.89; target ≥ 5.88). Coat flag `creatures_ralph_cannonback_moss` (ON).
- GPU form: `capture_f36_poses.gd -- --species=cliffspike,ashtusk,craghorn,cannonback,tuskroot --whole-body --context` with `remake_owner1101_tuskroot` enabled for Ashtusk; Forward+ 1920x1080, High first.

## Task 2 unholds that need CI (separate commit, "Task 2: turn ON ... CI to verify")

- Torrentoad, Meadowhart, Terrapup, Riptusk and Bramblebun are ON and removed from HELD. The CAUSE-REMAKES lane fixed each contract ("fixed, not run", `ralph/reports/LANES/CAUSE-REMAKES/READY.md`).
- Their contracts are gameplay smokes that need a full world import, and this container cannot run them. If CI fails any one, drop that species' two lines (flag `enabled` back to false, HELD line restored) and land the rest. That commit is independent of r1–r4.
- Still HELD:
  - Ripplet (parked by CAUSE-REMAKES: the combat camera anchor);
  - Burrowback, Trailpup and Paddlenewt (variant aspect textures not yet repainted for the remakes);
  - Mudsnout (Warrens seat);
  - Frostclaw (pose library).

## Parked / needs the coordinator

- **Aquaryn and Duskhush:** two approaches each with no gain (r1, r3). The judges ask for new models, which means Meshy, and the key is not in this container.
- **Mangrove Monitor:** two failed approaches (r2, r6). It needs new art via Meshy.
- **Cragclaw:** +0.47 in r6, short of its target. Next: a mid-value body in the shell's hue family plus a scale-up (`r6/VERDICT.md`).
- **Burrowback, Trailpup and Paddlenewt remakes** (r5): each scores below its installed model, so they stay HELD. The next approach for each is in `r5/VERDICT.md`.

## Next

- Cragclaw attempt 3; Burrowback/Nightburrow plate grade (gap −0.09); Trailpup/Stormtrail regrade.

## Local checks

Not run yet. The required suite needs every remake imported, which does not fit this container's disk. Until I can run a scoped set, CI decides.

## Tools added (all without Blender)

- `tools/art_pipeline/relax_stretched_weights.py`: CPU skinning over gameplay clips, then a harmonic weight solve where triangles stretch.
- `tools/art_pipeline/rigid_bind_region.py`: binds a box region rigidly to one joint.
- `tools/art_pipeline/amplify_clip.py`: exaggerates a clip's rotations.
- `tools/art_pipeline/grade_regions.py` with `data/creatures/remake_grades.json`: regional coat grade by anatomy map.
- `tools/art_pipeline/grade_quill_bands.py`: banded quills.
