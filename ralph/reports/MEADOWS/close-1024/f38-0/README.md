# F38#0 Meadows recapture and catalog rescore (in progress)

**Recapture:** `tools/capture_f38_matrix.gd --seed=2042 --f38-preset=Low --f38-baseline --times=day,night`, 1280x800, CPU llvmpipe Low/Compatibility, at tb/meadows 592a6dea6 (main after #716 merged in). It started 03:33 UTC 24 Oct. Frames stay local.

## Pass 1: the six landscape rows (24 Oct 07:40 UTC)

- Each row is a sheet of up to 12 matrix frames from that row's sites; the site list follows close-1020 `landscape-rows.json`.
- One-sided sets (the same sheet on both sides), because the original catalog frames are archived off main.
- Three fresh code-blind judges, standard prompt. Anchors: craft (confirming), f04_6_r22 and f36_0_npc:C6.
- Calibration: linear, slope 0.71, r 0.61, RMSE 0.63, no warnings.
- Files: `pass1-*`.

| Row | Subject | Raw j1/j2/j3 | Mapped | Defect (j1/j2/j3) |
|---|---|---|---|---|
| P2-003 | Team Tether stronghold | 5.0/5.3/4.9 | 5.48 | PRESENT x3 |
| P2-006 | mill and settlements | 5.6/5.5/5.4 | 5.79 | PARTIAL/PARTIAL/PRESENT |
| P2-014 | distant mountains | 5.4/5.8/5.4 | 5.81 | PARTIAL x3 |
| P2-013 | Tether Relay yard | 4.6/5.2/4.8 | 5.34 | FIXED x3 |
| P2-005 | ground cover | 5.3/5.7/5.3 | 5.74 | PARTIAL/PARTIAL/PRESENT |
| P2-012 | Burrow hillside | 4.7/5.4/5.0 | 5.46 | PRESENT x3 (shipping; the hill-shell candidate is OFF) |

P2-006 was scored before the village_road frames existed.

**New defects the judges named (input to F38#5):**
- At the relay yard the fixed stands put the camera behind or inside a large dark wall that fills 30–50% of the frame (P2-013/P2-005 sheets).
- Flat yellow hexagonal decals on the relay yard floor.
- Near-black stronghold courtyard and relay nights.
- An opaque white steam pillar at the burrow at night.
