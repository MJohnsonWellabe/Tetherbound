# CREATURES-F36 lane result (running summary)

Lane branch `tb/creatures-f36`. CPU capture on Mesa llvmpipe (Compatibility, 1280x720) with the `visual-judge` yardstick: three blind judges, anchors, `calibrate.py`. CPU scores only rank candidates; the GPU verdict is the score of record.

## Arms pushed

| Arm | Branch / SHA | Control | Species | CPU mapped main -> arm | Status |
|---|---|---|---|---|---|
| CO-F36-1 | `tb/co-f36-1-on` e5667aecd | main 3a0e1fa0d | Cragclaw, water_cragclaw, Skyrill (side-lie faint) | 5.71 -> 6.24, 5.71 -> 6.24, 6.00 -> 6.53 (+0.53 each) | GPU READY (`r2/VERDICT.md`) |
| CO-F36-2 | `tb/co-f36-2-on` 505bc2e5f | main a41e1b30 | Sirenseal grounded hit (flag `creatures_f36_sirenseal_grounded_hit`, off by default) | 5.90 -> 7.14 (+1.24) | GPU READY (`r4/VERDICT.md`) |
| CO-F36-3 | `tb/co-f36-3-on` d13f2db33 | main a41e1b30 | Duskhush x1.35, Brooktail x1.4 (flag `creatures_f36_taller_than_trainer`, off by default) | 5.81 -> 6.31, 5.81 -> 6.56 | GPU READY (`r5/VERDICT.md`) |
| CO-F36-4 | `tb/co-f36-4-on` 529829e88 | main a41e1b30 | Coat value lift: Cindercub, Duskhush, Ashtusk, Thundertunnel (flag `creatures_f36_coat_lift`, off by default; 4 new textures to import) | 5.83 -> 6.93, 5.42 -> 6.56, 5.74 -> 6.79, 6.01 -> 6.70 | GPU READY (`r6/VERDICT.md`) |
| CO-F36-5 | `tb/co-f36-5-on` c2b5851b4 (on CO-F36-4) | main a41e1b30 | Coat value lift batch 2: Stormtrail, Shadelet, Nightburrow (flag `creatures_f36_coat_lift_2`, off by default; 3 new textures to import) | 5.63 -> 6.88, 5.59 -> 6.63, 5.72 -> 6.30 | GPU READY (`r7/VERDICT.md`) |

## Rounds

- **r1** (`r1/VERDICT.md`), no gain, not sent:
  - Ripplet grey-white belly: 6.30 -> 6.30.
  - Aquaryn grounded rear-up: 7.01 -> 7.01.
  - Breezetail calm harness: 6.58 -> 6.58.
  - At the roster crop, texture and small pitch changes are invisible to the judges.
- **r2** (`r2/VERDICT.md`): CO-F36-1 above.
- **r3** (`r3/VERDICT.md`), on CO12 (coordinator, 31 Oct), regressed, not sent:
  - Cliffspike faint roll −70°: 6.92 -> 6.58.
  - Thundertunnel faint roll +70°: 6.64 -> 6.20.
  - On domed or quilled bodies the whole-body roll lifts them off the stage.
- **r4** (`r4/VERDICT.md`), ROSTER-1 targets:
  - Sirenseal grounded hit 5.90 -> 7.14: CO-F36-2.
  - Torrentoad flinch and slump 6.95 -> 6.86: dropped.
- **r5** (`r5/VERDICT.md`), height above the trainer:
  - Brooktail 5.81 -> 6.56 and Duskhush 5.81 -> 6.31: CO-F36-3.
  - Bramblebun +0.15 and Trailpup +0.10: within noise, left out.
- **r6** (`r6/VERDICT.md`), coat value lift: CO-F36-4.
  - Cindercub +1.10, Duskhush +1.14, Ashtusk +1.05, Thundertunnel +0.69.
  - Whole-coat value changes register at the roster crop; a belly-only change (r1 Ripplet) did not.
- **r7** (`r7/VERDICT.md`), coat lift batch 2: CO-F36-5.
  - Stormtrail +1.25, Shadelet +1.04, Nightburrow +0.58.

## Species parked or needing the coordinator

- **Solmane:** its wings are static mesh with no bones, so every faint keeps them up. It needs wing bones or a new mesh (Meshy, coordinator).
- **Fulgocobra:** the hood stays raised because the raised neck is not on the recipe's neck bone. It needs a rig or clip fix.
- **Glimmermoth and Tempestwing:** a side-lie stands their wings vertical. They need wing bones (Tempestwing's rig has none) or authored clips.
- **Cliffspike, Thundertunnel (faint):** the pivot roll regresses. A grounded collapse needs authored leg and flank bones or clips. Their next swing is a value and face lift, not a pose change.
- **Nightburrow:** plays its own remake clips (not a recipe species), so the recipe roll cannot touch its faint. Its crouch faint needs the remake's clip re-authored, which needs Blender (not in this container).
- **Bramblebun, Cindercub, Trailpup (ROSTER-1 hit PARTIAL):** they play their remake GLB clips; no recipe matches their models. A grounded hit means re-authoring the clips with each remake's `author_native_clips.py`. `bpy` 5.2 installs here (pip, Python 3.13), but a re-export risks changing materials, so it is not attempted yet.
- **Stop-rule count, round 1 under 0.5:** Ripplet, Aquaryn, Breezetail, Cliffspike faint, Thundertunnel faint, Torrentoad flinch and faint. Not parked yet; the next try needs a silhouette-level change.

## Process (coordinator, 31 Oct)

- From the next arm on, every change ships as data or config JSON flags over flag-off code. A new texture or mesh ships with a flag that selects it.
- GPU arm requests say "High first".

## Lessons

- At the standard roster crop only silhouette changes score: faint shape, and pose contact with the ground.
- A whole-body pivot roll is a cheap faint fix where the body has no appendage standing off the back, as Cragclaw and Skyrill show. It fails on winged, coiled and domed or quilled bodies (r3).
- The pivot axis sign matters: −80° shows the belly, which an earlier lane found reads as belly-up.
