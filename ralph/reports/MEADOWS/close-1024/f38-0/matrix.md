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

## F38#5 rescan after the fixture correction (close-1024, CPU)

**Captured:** `shots/f38_1024_hall` holds 48 Hall frames: nave, shrine room and 8 arches, the arches with the detail view only. `shots/f38_1024_relay` holds 16 relay-yard frames, captured after the relay ground-pad change (cell 1.0, lift 0.08). Both were captured with `capture_f38_matrix.gd` at Low/CPU. Every planned stand was accepted: 0 void frames and 0 black frames.

**Judging:** one-sided sets. Three fresh code-blind judges used the standard prompt with three anchor pairs: craft, f10_2_r3_capacitor, f36_0_gap:C4. Calibration is linear: slope 1.29, r 0.90, RMSE 0.54, with no warnings. Files: `rescan-batch.json`, `rescan-key.json`, `rescan-mapped.json`.

| Area | Raw j1/j2/j3 | Mapped | Before | F38#5 defect (j1/j2/j3) |
|---|---|---|---|---|
| Hall nave, shrine room and 8 arches | 5.8/5.6/5.5 | **6.37** | nave 4.25, arches 2.80 and 2.09 | PARTIAL x3 |
| band3 relay yard | 5.5/5.0/5.2 | **5.85** | 5.19 | PRESENT/PARTIAL/PRESENT |

**Fixed:**
- The blue void, the floating chandeliers and the black frames with the camera inside geometry. No judge saw void or magenta.
- The flat yellow hex decals on the relay floor. No judge named them.

**Still open (F38#5 not clean):**
1. The relay gameplay stand is #03, 07, 11 and 15: `band3_the_river_lock_0__*__gameplay`. The trainer stands in the gate arch with a wall pier filling half the frame, and the detail frames #06 and #14 have a timber corner.
   - The production camera is not inside geometry here, because it sees the trainer through the arch. It is the framing the player gets standing on that spot.
   - Fix candidate: the camera's occluder handling for thin piers. That is shared camera code, outside this lane's paths, so it is reported, not changed.
2. The Hall arch rims (#17-20, 25-30) read as "neon placeholder glows" to all three judges. On Compatibility the rims are full weight. Forward+ already takes 0.35 (land2). Dimming the Compatibility rims would change the F17#6 scene, which the coordinator asked to keep identical on Low/Compatibility. This waits on the GPU F17#6 verdict.
3. Arch detail frames #05-08 and #31-32 have a near wall or pillar at the frame edge, because the nave is about 12 m wide. Shrine room night #47-48 is washed near-white.
4. Not F38#5 classes: repetitive wall modules, and indoor day/night/rain that barely differ. These are Bar A asks.
