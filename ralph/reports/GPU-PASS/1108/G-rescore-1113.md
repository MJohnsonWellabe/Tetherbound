# G-rescore-1113: 5 rows re-scored on main (GPU High, one-sided)

LANE-PLACES (re-scoring lane), 13 Nov 2026.

**Frames:** `tb/gpu-frames-1113`, sections `G-rescore-1113-rows` @ ae87d168f and `G-rescore-1113-f39-21` @ ba6b590f0: main b8622117's content (#953's camp bench absent; no frame here shows a camp), High, each row's own job.json frames (F39#21 on this run's own frames, see coverage).

**Batch:** three code-blind judges, the standard prompt, each row as a one-sided sheet of its own frames (640×360 tiles) against its job.json brief and recorded defect. Anchors pinned to craft, f10_2_r3_capacitor and f04_6_r22 plus two drawn pairs (five pairs, ten points).

**Fit:** linear, slope 1.3948, intercept -1.3666, r 0.855, anchor RMSE 0.575; confirming batch: True; warnings: none.

**Read the change column as indicative (about ±0.6, the anchor RMSE):** board scores come from other batches and judge pools.


## Results

| Row | Subject | Board | Main now (mapped) | Change | Raw a, b, c | Recorded defect (a / b / c) |
|---|---|---|---|---|---|---|
| F38#1 | creature collapse and rest | 6.58 | **6.26** | -0.32 | 5.6, 5.8, 5.0 | PARTIAL / PARTIAL / PARTIAL |
| F39#21 | named fight victory hierarchy | 7.06 | **5.84** | -1.22 | 5.6, 4.9, 5.0 | PARTIAL / PARTIAL / PARTIAL |
| F40#1 | open terrain | 5.9 | **5.84** | -0.06 | 5.3, 5.4, 4.8 | PRESENT / PRESENT / PRESENT |
| F40#4 | exposed landform edges | 6.12 | **6.07** | -0.05 | 5.5, 5.6, 4.9 | PARTIAL / PARTIAL / PARTIAL |
| F40#17 | High Perches rim mushroom | 6.18 | **5.61** | -0.57 | 5.2, 5.2, 4.6 | PARTIAL / FIXED / PARTIAL |

## What the judges named

- **F39#21 (7.06 -> 5.84) falls on one frame.** The Nerissa frames give a clean reward hierarchy (judge 1). In the **Venn win frame, a large flat grey plane covers the lower half of the screen** (3/3), and in Venn aftermath, beach grass sits in the lens. I checked the frame. The plane's far edge is a jagged line that follows the beach grass, and the sand beyond it continues normally. So it reads as a flat surface at one fixed height covering a dip in the dune between the camera and the beach. It looks like a water or fill plane drawing opaque grey, not the camera inside a mesh. The GPU lane confirmed (13 Nov) that it is a regression: its 9-10 Nov Venn win captures show the camera up on the dune with no plane, and both of today's main-content runs show it identically. Finding what changed since 10 Nov should recover most of the loss. The reward panel itself reads as a "plain text box" (judge 2).
- **F40#1 (5.84, PRESENT 3/3):** a flat empty level lawn dominates; a visible terrain-disc edge or hard terrain cut (2/3); the distant stratified stacks are the only on-board element.
- **F40#17 (5.61):** the mushroom reads as toy-like glow blobs on a featureless lawn rim. The night frame's navy-blue grade differs from the day frame (3/3). The suspended mushroom defect is FIXED for one judge and PARTIAL for two.
- **F38#1 (6.26, PARTIAL 3/3):** the meadow carries it. Fainted poses still look stiff, splayed or hovering, most in the third frame (Veridian fainted).
- **F40#4 (cross-check, 6.07):** straight extruded shelf lips and blunt boulders (3/3).

## Flags

- F39#21 5.84: below 6 (was 7.06)
- F40#1 5.84: below 6 (was 5.9)
- F40#17 5.61: below 6 (was 6.18)

## Coverage notes

- F39#21: job.json ids carry the second each fight was won, which varies run to run, so the row was judged on this run's own four frames: Venn win, Venn aftermath, Nerissa win, Nerissa aftermath. That is one more frame than the job (Nerissa aftermath).
- F40#4 rode along on one shared frame; it is a cross-check, not a row score.
- F40#17 was added by the coordinator (High Perches crown rim, day and night).
- F40#4: 1 of 3 job frames (missing cloudreach__high_roost_sky_shrine__07__sky_shrine__day__approach, cloudreach__landmark__three_bells_bridge__day__approach)
