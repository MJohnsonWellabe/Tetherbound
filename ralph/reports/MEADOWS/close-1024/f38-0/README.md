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

## Pass 2: creature and catch rows (24 Oct 18:45 UTC)

**Frames:** close-1024 supplemental captures at Low/CPU, run with the catalog's own repro commands:
- `phase2_capture_creatures.gd --biome=meadows --only=<11 Meadows species> --seed=2042`: 81 frames.
- `phase2_capture_catch.gd --seed=2042`: 12 frames.

Each row is one sheet of that row's Meadows sightings, with frames numbered as in `rows-a-sheet-index.json`. Sets are one-sided. The only missing sighting is `terrapup__resting`, because the creature tool captures no resting state.

**Judging:** three fresh code-blind judges, standard prompt. Anchors: craft (confirming), f36_0_gap:C7 and f36_0_npc:C5. Calibration is linear: slope 1.82, r 0.96, RMSE 0.27, no warnings. Files: `rows-a-*`.

| Row | Impact | Subject | Raw mean | Mapped | Defect (j1/j2/j3) |
|---|---|---|---|---|---|
| P2-015 | 100 | creature collapse and rest | 4.67 | 4.14 | PRESENT x3 |
| P2-016 | 100 | hurt and movement poses | 4.93 | 4.62 | PRESENT x3 |
| P2-017 | 80 | normal creature scale | 5.00 | 4.74 | PRESENT x3 |
| P2-058 | 64 | catch aim readability | 5.17 | 5.05 | PRESENT x3 |
| P2-059 | 48 | catch camera framing | 4.87 | 4.50 | PRESENT x3 |
| P2-060 | 48 | catch effect finish | 4.93 | 4.62 | PARTIAL x3 (the magenta ring is gone; the flat orb and identical rest/shake frames remain) |
| P2-018 | 36 | shiny distinction | 5.00 | 4.74 | PRESENT/PARTIAL/PRESENT |
| P2-020 | 36 | creature ground contact | 5.30 | 5.29 | PARTIAL x3 |
| P2-061 | 27 | catch result hierarchy | 4.67 | 4.14 | PRESENT x3 |
| P2-019 | 27 | alpha rarity read | 5.10 | 4.93 | PRESENT x3 |

**What the judges named, by row:**
- P2-015: Terrapup lies chest-down with its head up facing the camera (#01). Meadowhart keeps its antlers raised (#03). Galecrest's wings are spread above the grass (#05-06).
- P2-016: hurt and moving frames keep the idle stance.
- P2-017: most Meadows creatures stand at or under trainer height.
- P2-058/059/060/061:
  - Frame #02 of the aim sheet has a flat magenta throw wedge.
  - The chance text is small and sits on the creature's body.
  - Catch frame #06 cuts to a tight top-down view.
  - The orb is a flat glow, and the rest and shake frames look identical.
  - The verdict is micro-text under the full HUD.
- P2-018: shiny forms aren't readable at device scale.
- P2-019: alphas are only slightly larger, with no staging.
- P2-020: the dark grass band swallows feet.

Every row in this pass is below 6.7 mapped. The fixes the judges name are the catch presentation (P2-058 to 061, one bounded UI and effects pass) and the creature pose and scale rows (P2-015/016/017). Those creature rows overlap F36#1/F29 in `data/creatures/f36_pose_candidates.json`, which the creatures lane owns.
