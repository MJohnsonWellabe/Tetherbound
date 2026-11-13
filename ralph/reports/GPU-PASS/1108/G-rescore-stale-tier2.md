# G-rescore-stale-tier2: 15 rows re-scored on main (GPU High, one-sided)

LANE-PLACES (re-scoring lane), 12 Nov 2026.

**Frames:** `tb/gpu-frames-1108` section `G-rescore-stale-tier2` @ 4ca37c049: main b3dc21395 as it is, High, each row's own job.json frames (41 frames, 0 blank, 0 script errors). F38#13, F38#21 and F39#14 were captured with this section because they share frames with listed rows.

**Batch:** three code-blind judges, the standard prompt, each row as a one-sided sheet of its own frames (640×360 tiles) against its job.json brief and recorded defect. Anchors pinned to craft, f10_2_r3_capacitor and f04_6_r22 (three pairs, six points).

**Fit:** linear, slope 1.2621, intercept -1.0949, r 0.893, anchor RMSE 0.518; confirming batch: True; warnings: none.

**Read the change column as indicative (about ±0.3):** board scores come from other batches and judge pools.


## Results

| Row | Subject | Board (8–9 Nov) | Main now (mapped) | Change | Raw a, b, c | Recorded defect (a / b / c) |
|---|---|---|---|---|---|---|
| F38#2 | creature hurt and movement poses | 6.0 | **6.35** | +0.35 | 6.2, 6.0, 5.5 | PARTIAL / PARTIAL / PARTIAL |
| F38#6 | ground pickup identity | 6.1 | **6.52** | +0.42 | 6.4, 5.8, 5.9 | FIXED / PARTIAL / FIXED |
| F38#12 | harvest reward identity | 6.06 | **5.89** | -0.17 | 5.5, 5.6, 5.5 | PARTIAL / PARTIAL / PARTIAL |
| F38#13 | catch sequence camera framing | 7.16 | **6.94** | -0.22 | 6.5, 6.3, 6.3 | PARTIAL / PARTIAL / PARTIAL |
| F38#14 | catch effect finish | 6.06 | **6.94** | +0.88 | 6.6, 6.2, 6.3 | PARTIAL / PARTIAL / PARTIAL |
| F38#20 | Team Tether stronghold | 6.02 | **5.72** | -0.30 | 5.7, 5.5, 5.0 | PARTIAL / PARTIAL / PARTIAL |
| F38#21 | ground cover | 7.0 | **6.23** | -0.77 | 6.0, 5.8, 5.6 | PARTIAL / PARTIAL / PARTIAL |
| F38#22 | mill and settlements | 6.1 | **6.06** | -0.04 | 5.9, 5.7, 5.4 | PARTIAL / PARTIAL / PARTIAL |
| F38#29 | trainer defeated presentation | 6.05 | **6.35** | +0.30 | 6.0, 6.0, 5.7 | PARTIAL / PARTIAL / PARTIAL |
| F39#5 | surface swimming trainer pose | 6.06 | **5.64** | -0.42 | 5.3, 5.5, 5.2 | PARTIAL / PARTIAL / PARTIAL |
| F39#14 | swimmer water contact | 6.37 | **6.44** | +0.07 | 6.3, 6.0, 5.6 | PARTIAL / PARTIAL / PARTIAL |
| F40#15 | floating dark strips | 6.08 | **5.89** | -0.19 | 5.6, 5.5, 5.5 | FIXED / FIXED / FIXED |
| F40#17 | High Perches rim mushroom | 6.08 | **6.18** | +0.10 | 5.8, 5.9, 5.6 | FIXED / FIXED / FIXED |
| F41#10 | Glass Sink landmark | 6.02 | **6.01** | -0.01 | 5.7, 5.7, 5.5 | PARTIAL / PARTIAL / PARTIAL |
| F41#18 | uniformed character readability | 6.1 | **5.93** | -0.17 | 5.6, 5.8, 5.3 | PARTIAL / PARTIAL / PARTIAL |

## Flags

- F38#12 5.89: below 6 (was 6.06)
- F38#20 5.72: below 6 (was 6.02)
- F39#5 5.64: below 6 (was 6.06)
- F40#15 5.89: below 6 (was 6.08)
- F41#18 5.93: below 6 (was 6.1)

## Coverage notes
- F38#13: 2 of 3 job frames (missing meadows__catching__04-orb-resting)
- F38#21: 2 of 3 job frames (missing meadows__band2_stone_and_root__04__the_burrow_warrens__day__approach)
- F39#5 and F39#14 share the same three swimming frames; each was judged on its own brief.

## What the judges named (3/3 unless said)
- **Scale and staging outliers:** the oversized "TRAIL CAMP" sign slab (F38#22), stretched giant cobbles on the Cloudreach wall (F40#15, F40#17), the toy-like oversized candy pickup (F38#6), the empty oversaturated stronghold interior (F38#20).
- **Ground:** a uniform dark grass carpet with no rock or colour breaks (F38#21), blurry noisy dirt in the village foreground (F38#22), bare flat lawn at Cloudreach (F40#15).
- **Poses and effects (new art):** the swimmer is a floating head with no stroke (F39#5); the wake is a straight banded strip with a dark dot beside the head (F39#14); the catch orb is a flat cream disc and rest and shake look the same (F38#14); the defeated grunt is a small dark crouch that the banner still has to explain (F38#29); hurt and moving are not distinguishable without a label (F38#2).
- **Glass Sink (F41#10):** the copper and glass ring reads as a landmark in one frame, but the rim views still show a streaked void with no sink form.
- **Recorded defects now FIXED 3/3:** F40#15 (black strips gone) and F40#17 (mushrooms grounded); both rows are held down by what is left in frame, not by their recorded defect.
