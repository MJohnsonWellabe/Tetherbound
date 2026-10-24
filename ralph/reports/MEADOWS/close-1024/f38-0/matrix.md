# F38 Meadows matrix: Bar A (F38#3) and defect scan (F38#5), CPU close-1024

**Frames:** 236 of 352 planned (`capture_f38_matrix.gd`, Low/CPU, 592a6dea6). The tool's camera-support check rejected 116 stands, the same count as the 20 Oct run.

**Judging:** eight area sheets, each a one-sided set of numbered frames. The recorded defect for each sheet is the F38#5 class: flat magenta rings or slabs, placeholder materials, floating bodies, or clipping.
- Three fresh code-blind judges, standard prompt.
- Anchors: craft (confirming), f36_0_npc:C2 and f36_0_gap:C1.
- Calibration: linear, slope 1.18, r 0.94, RMSE 0.29.
- Warning: "some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)". These are the Hall and arch areas, on the low side.
- Files: `matrix-batch.json`, `matrix-key.json`, `matrix-mapped.json`, `matrix-sheet-index.json` (frame number to file).

| Area | Raw j1/j2/j3 | Mapped | F38#5 defect (j1/j2/j3) |
|---|---|---|---|
| band1-2 lower meadows / stone and root | 5.6/5.7/6.4 | 6.33 | PARTIAL x3 |
| band3 river lock | 4.6/4.8/5.4 | 5.19 | PRESENT x3 |
| band4 upper meadows | 5.0/5.8/6.1 | 6.02 | PARTIAL x3 |
| band5 stronghold approach | 4.7/5.0/5.3 | 5.27 | PARTIAL x3 |
| village road, farm, Hall front | 5.1/5.6/5.8 | 5.86 | PARTIAL/PRESENT/PARTIAL |
| Hall nave and shrine room | 4.0/4.0/4.4 | 4.25 | PRESENT x3 |
| Hall arches 1-4 | 2.5/2.8/3.4 | 2.80 | PRESENT x3 |
| Hall arches 5-8 | 2.0/2.4/2.5 | 2.09 | PRESENT x3 |

**F38#3:** not met. No area reaches 6.7. Bar B is no everywhere except one judge's yes on band1-2.

**F38#5:** not clean.

### Defects found, by cause

**1. Fixture: stands outside the playable room.** This is most of the Hall and arch damage.
- `capture_f38_matrix.gd` places a stand at site − forward × offset. The definition's wall-arch headings pointed outward, so the approach and reverse views (and the gameplay views of most arches) landed beyond the Hall wall. The judges saw blue void, floating props and the trainer, and black frames with the camera inside geometry: arches 1-4 #01-05, 17-23, 33-38, 41, 44; arches 5-8 #01-06, 09, 12-13, 16-17, 20-21, 24-25, 28-30, 32, 34, 36, 38-39, 42, 45, 48.
- The built-floor resolver stood the trainer on the nave's interior ceiling panels: nave #01, 03, 13 show a blue void with floating chandeliers.
- **Fix:** commit "F38#5 fixture correction". The arches face into the room and keep only their gameplay and detail views, and the nave and shrine stand on the floor. The Hall sites are queued for recapture behind the supplementals (`shots/f38_1024_hall`).

**2. Game, possibly a camera issue.**
- band3 relay yard: the production camera is pressed against or inside the relay gate walls (#03, 07, 11, 15; dark slab #02, 06, 14).
- village interiors: the camera clips ceiling beams and walls (#02, 05, 08, 11).
- **To check:** whether a player stand can reach those spots, i.e. whether the stands are in reachable space.

**3. Game: materials.**
- Flat yellow hexagonal decals on the relay yard floor (band3 #04, 08, 16; all three judges call them placeholder).
- A pale flat column at the lower-meadow waterfall (band1-2 #26-27, 29-31).
- A washed-out, cyan Hall interior in some views (village #14, nave #04-06).
- A translucent cyan trainer in the shrine-room rain frame (#14). This is probably the trainer seen through an occluder, the x-ray silhouette.

**4. Not F38#5 classes:** murky nights and rain, the uniform grass carpet, the dark stronghold courtyard. These are Bar A asks for F38#3.
