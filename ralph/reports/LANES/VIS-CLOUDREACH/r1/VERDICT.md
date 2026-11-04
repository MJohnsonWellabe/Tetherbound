# VIS-CLOUDREACH round 1: cloudreach_cause arm (all four parts) vs main, CPU

- **Arm:** `data/config/cloudreach_cause.json:enabled` via `--cloudreach-cause-candidate` (pale_strata + cloud_sea + light_grade + meadow_groves), built by the 1 Nov cause lane and never captured before.
- **Capture:** CPU llvmpipe, Compatibility, 1280x720, `phase2_capture_locations.gd --biome=cloudreach --times=day --views=approach,close --seed=2042` on six stands, base and arm in separate boots on the same tree (b, `tb/vis-cloudreach-1104` at the r1 start, flag-off code only beyond main 98879e2e).
- **Judging:** `tools/visual_judge` standard prompt verbatim, `anchor_tiles.py --pairs 3 --include craft --seed 110401`, three fresh code-blind judges in parallel, `calibrate.py` linear (r 0.66, slope 1.07, anchor RMSE 0.63, confirming batch).

| Item | Board | CPU base | CPU arm | Delta |
|---|---|---|---|---|
| P2-021 open terrain | F40#1 | 5.24 | 5.06 | -0.18 |
| P2-022 summit aviary | F40#2 | 5.59 | 5.52 | -0.07 |
| P2-023 exposed landform edges | F40#4 | 5.41 | 5.16 | -0.25 |
| P2-025 grass and stone finish | F40#7 | 5.88 | 5.27 | -0.61 |

**Verdict: worse on every item; the arm stays OFF.** All three judges named the cause: `pale_strata` turns the shrine and perch pillars into smooth untextured beige cylinders, and the realm-gate foreground lip into a washed-out beige band. The terrace ride sets (P2-105/P2-106) are judged separately (the ride capture was still running).

**What the judges asked for next (all three):** break the grass carpet into clumps, groves, flower patches and edges (scene); aerial-perspective haze and warmer sun/cooler shadow (scene); layered stratified cliffs with eroded undersides and a larger cliff-seated aviary (new art). Next arm: the cause lane's `meadow_groves` + `cloud_sea` parts alone, without `pale_strata` (round 3c).
