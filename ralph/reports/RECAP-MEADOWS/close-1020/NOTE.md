# F38#0 Meadows recapture: PAUSED (not READY)

Paused 21 Oct 2026 ~15:05Z on owner direction relayed by the coordinator ("pause on all that visual until I start remote"). The GPU remote's High/Medium recapture is expected to redo F38#0. **No closure claimed.**

## Done
- Source SHA `1ad35c0cdc3d0e7e72d0d110acbfe7ed322b2c7f` (tb/look head), Godot 4.7, CPU Mesa llvmpipe, Low/Compatibility, 1280x800. Criterion asks High and Medium; Low/CPU is the disclosed substitute (owner 17 Oct), and a GPU pass is still owed.
- Matrix command: `xvfb-run -a -s "-screen 0 1280x800x24" godot --path . --rendering-driver opengl3 --resolution 1280x800 --script res://tools/capture_f38_matrix.gd -- --seed=2042 --f38-preset=Low --f38-baseline --times=day,night --output=<fresh dir>`
- Matrix finished: **236/352 saved**, 116 stands rejected by the tool's strict production-camera support check (listed in `matrix-frame-manifest.json`; Old Quarry `band2_stone_and_root_0` has 0 frames). The tool exits "FAILED" whenever any planned frame is missing. The ≥200 floor is met. Hashes of the frames are in the manifest; the frames themselves stay local.
- Landscape rows (6 of 46) re-scored by three code-blind judges on matrix contact sheets (`judge{1,2,3}-landscape.json`). Bar A means: P2-003 4.8, P2-013 4.6, P2-014 5.6, P2-005 5.0, P2-006 4.9, P2-012 3.5. Matrix Bar A 4.6/4.5/4.5 (mean 4.53); Bar B 3.4/3.6/3.6. None meet 7.5 or the CPU-provisional 6.7.
- Supplemental Phase 2 recaptures for the non-landscape rows (`supplemental-frame-manifest.json`): fights complete (70 frames), UI complete (12), creatures partial (80; killed mid-run).

## Left
- Supplementals not run: catch (killed at start), flight, build, inventory, dialogue, defeated dialogue; creatures must be rerun.
- 40 non-landscape rows not yet re-scored (creature poses/scale, UI, catch, fights, dialogue framing, pickups/props).

## Resume
All existing tools need `--source-commit=<40-hex SHA>` and an output under `res://ralph/reports/VISUAL/phase2/meadows/` (fights: `--out=`). Each output dir must be fresh. Example, from the repo root, one process at a time:
```
S=<sha>; R=res://ralph/reports/VISUAL/phase2/meadows/recap_<name>
xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --resolution 1920x1080 --script tools/phase2_capture_creatures.gd -- --source-commit=$S --preset=Low --biome=meadows --only=bramblebun,brooktail,galecrest,mosshell,nightburrow,pipwing,riftfrill,stormtrail,terrapup,trailpup,veridian --seed=2042 --output=$R
# same pattern: phase2_capture_catch.gd, phase2_capture_realm_flight.gd, phase2_capture_build_systems.gd (--biome=meadows --seed=2042)
# phase2_capture_world_inventory.gd / phase2_capture_dialogue.gd / phase2_capture_defeated_dialogue.gd with one --subset=<catalog sighting prefix> per sighting (23 / 32 / 18 subsets; derive from ralph/reports/R2-F38/catalog-source-audit.json sightings mapped through ralph/reports/VISUAL/phase2/meadows/manifest.csv repro column)
```
Then map each catalog sighting to its new frame, sheet per row, and have three code-blind judges score the 40 remaining rows, plus a blind completeness check. On GPU, rerun the matrix with `--f38-preset=High`/`Medium` (Forward+) per `ralph/reports/R2-F38/capture-definition.json`.
