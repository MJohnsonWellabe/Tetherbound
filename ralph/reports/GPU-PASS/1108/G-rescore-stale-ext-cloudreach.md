# G-rescore-stale-ext-cloudreach: 7 rows re-scored on main (GPU High, one-sided)

LANE-PLACES (re-scoring lane), 12 Nov 2026.

**Frames:** `tb/gpu-frames-1108` section `G-rescore-stale-ext-cloudreach` @ d5a3a57b2: main 90ffeb663 as it is, High, each row's own job.json frames (15 frame slots across 7 rows).

**Batch:** three code-blind judges, the standard prompt, each row as a one-sided sheet of its own frames (640×360 tiles) against its job.json brief and recorded defect. Anchors pinned to craft, f10_2_r3_capacitor and f04_6_r22 (three pairs, six points).

**Fit:** linear, slope 1.3816, intercept -1.6327, r 0.859, anchor RMSE 0.592; confirming batch: True; warnings: none.

**Read the change column as indicative (about ±0.3):** board scores come from other batches and judge pools.


## Results

| Row | Subject | Board | Main now (mapped) | Change | Raw a, b, c | Recorded defect (a / b / c) |
|---|---|---|---|---|---|---|
| F40#2 | summit aviary | 6.15 | **6.93** | +0.78 | 6.1, 6.2, 6.3 | PARTIAL / PARTIAL / PARTIAL |
| F40#4 | exposed landform edges | 6.12 | **6.47** | +0.35 | 5.7, 5.9, 6.0 | PRESENT / PARTIAL / PARTIAL |
| F40#7 | grass and stone finish | 6.26 | **6.80** | +0.54 | 6.2, 6.0, 6.1 | PARTIAL / PARTIAL / PARTIAL |
| F40#11 | terrace edge clouds | 6.97 | **6.52** | -0.45 | 6.0, 5.7, 6.0 | PARTIAL / PARTIAL / PARTIAL |
| F40#14 | Cloudreach map region label | 6.99 | **7.21** | +0.22 | 6.7, 6.3, 6.2 | FIXED / FIXED / FIXED |
| F40#16 | mushroom pickup variants | 6.19 | **6.93** | +0.74 | 6.3, 6.0, 6.3 | FIXED / PARTIAL / PARTIAL |
| F40#18 | full-party catch choice legibility | 7.1 | **7.49** | +0.39 | 6.8, 6.6, 6.4 | FIXED / FIXED / PARTIAL |

## Read this before using the numbers
- Fit r 0.859, anchor RMSE 0.59: the loosest of the four batches. No row maps above the top anchor.
- **F40#11 is partial (2 of 3 frames).** The ride tool on main 90ffeb663 ends the terrace segment after 1.0 s, so the row's `phase2_18_terrace_02.0s` still no longer exists (the ride itself is normal). The row's job.json frame list needs updating to a still the tool produces (`phase2_18_terrace_after` is the nearest); until then its score is on two frames. Its −0.45 should not be read as a regression.
- **F40#18 is 7.49**, one hundredth under the bar, with its defect FIXED / FIXED / PARTIAL. A second panel could put it either side; it is a close-out candidate.

## Flags

- none at 7.5 or above and none below 6. Nearest the bar: F40#18 7.49, F40#14 7.21.

## Coverage notes

- F40#11: 2 of 3 job frames (missing cloudreach__riding__phase2_18_terrace_02.0s)

## What the judges named (3/3)
- **Ground and edges, every world row (F40#2, #4, #7, #11):** flat single-tone lawn with lone blades; "faceted brown cliff" masses, "extruded disc shelves" and "knife-straight" terrace and lawn edges that read as blockout. The distant pale stratified mesas are on-board.
- **Summit aviary (F40#2):** the building is on-board and well lit at night, but "stands alone on a bare flat lawn with blocky trees"; all three ask for a layered base (plinth, steps, terraces, planting) and a paved approach.
- **Recorded defects FIXED 3/3:** F40#14 (map region label). F40#18 and F40#16 are fixed for one or two judges.
