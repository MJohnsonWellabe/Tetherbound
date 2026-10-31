# CREATURES-F36 lane result (running summary)

Lane branch `tb/creatures-f36`. CPU capture on Mesa llvmpipe (Compatibility, 1280x720) with the `visual-judge` yardstick: three blind judges, anchors, `calibrate.py`. CPU scores only rank candidates; the GPU verdict is the score of record.

## Arms pushed

| Arm | Branch / SHA | Control | Species | CPU mapped main -> arm | Status |
|---|---|---|---|---|---|
| CO-F36-1 | `tb/co-f36-1-on` e5667aecd | main 3a0e1fa0d | Cragclaw, water_cragclaw, Skyrill (side-lie faint) | 5.71 -> 6.24, 5.71 -> 6.24, 6.00 -> 6.53 (+0.53 each) | GPU READY (`r2/VERDICT.md`) |

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

## Species parked or needing the coordinator

- **Solmane:** its wings are static mesh with no bones, so every faint keeps them up. It needs wing bones or a new mesh (Meshy, coordinator).
- **Fulgocobra:** the hood stays raised because the raised neck is not on the recipe's neck bone. It needs a rig or clip fix.
- **Glimmermoth and Tempestwing:** a side-lie stands their wings vertical. They need wing bones (Tempestwing's rig has none) or authored clips.
- **Cliffspike, Thundertunnel (faint):** the pivot roll regresses. A grounded collapse needs authored leg and flank bones or clips. Their next swing is a value and face lift, not a pose change.
- **Nightburrow:** plays its own remake clips (not a recipe species), so the recipe roll cannot touch its faint. Its crouch faint needs the remake's clip re-authored, which needs Blender (not in this container).
- **Stop-rule count, round 1 under 0.5:** Ripplet, Aquaryn, Breezetail, Cliffspike faint, Thundertunnel faint. Not parked yet; the next try needs a silhouette-level change.

## Lessons

- At the standard roster crop only silhouette changes score: faint shape, and pose contact with the ground.
- A whole-body pivot roll is a cheap faint fix where the body has no appendage standing off the back, as Cragclaw and Skyrill show. It fails on winged, coiled and domed or quilled bodies (r3).
- The pivot axis sign matters: −80° shows the belly, which an earlier lane found reads as belly-up.
