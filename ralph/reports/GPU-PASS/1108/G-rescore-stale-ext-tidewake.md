# G-rescore-stale-ext-tidewake: 21 rows re-scored on main (GPU High, one-sided)

LANE-PLACES (re-scoring lane), 12 Nov 2026.

**Frames:** `tb/gpu-frames-1108` section `G-rescore-stale-ext-tidewake` @ f407c5f28: main 6906a2ebf as it is, High, each row's own job.json frames (60 frame slots across 21 rows).

**Batch:** three code-blind judges, the standard prompt, each row as a one-sided sheet of its own frames (640×360 tiles) against its job.json brief and recorded defect. Anchors pinned to craft, f10_2_r3_capacitor and f04_6_r22 (three pairs, six points).

**Fit:** linear, slope 1.3905, intercept -2.0599, r 0.940, anchor RMSE 0.393; confirming batch: True; warnings: ["meets the bar only above the top anchor (7.35): F39#24, F39#4; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch"].

**Read the change column as indicative (about ±0.3):** board scores come from other batches and judge pools.


## Results

| Row | Subject | Board | Main now (mapped) | Change | Raw a, b, c | Recorded defect (a / b / c) |
|---|---|---|---|---|---|---|
| F39#1 | shore landforms | 6.42 | **6.14** | -0.28 | 5.8, 6.2, 5.7 | PARTIAL / PARTIAL / PARTIAL |
| F39#2 | Veilfall silhouette | 6.48 | **6.79** | +0.31 | 6.2, 6.6, 6.3 | PARTIAL / PARTIAL / PARTIAL |
| F39#3 | named destination read | 6.1 | **7.26** | +1.16 | 6.6, 6.9, 6.6 | FIXED / PARTIAL / FIXED |
| F39#4 | shiny creature finish | 7.28 | **7.81** | +0.53 | 7.0, 7.3, 7.0 | FIXED / FIXED / FIXED |
| F39#7 | fight actor composition | 6.61 | **7.07** | +0.46 | 6.7, 6.6, 6.4 | FIXED / PARTIAL / PARTIAL |
| F39#8 | Aquaryn mounted-water pose | 5.66 | **5.82** | +0.16 | 5.5, 6.1, 5.4 | PARTIAL / PARTIAL / PARTIAL |
| F39#9 | catch camera distance | 6.65 | **6.42** | -0.23 | 6.1, 6.2, 6.0 | PARTIAL / PARTIAL / PARTIAL |
| F39#10 | water and island depth | 6.3 | **7.02** | +0.72 | 6.6, 6.8, 6.2 | FIXED / FIXED / FIXED |
| F39#12 | authored camp creature bed silhouette | 6.8 | **6.98** | +0.18 | 6.3, 6.6, 6.6 | PARTIAL / PARTIAL / FIXED |
| F39#13 | authored camp workbench identity | 6.23 | **6.14** | -0.09 | 5.6, 6.2, 5.9 | PARTIAL / PARTIAL / PARTIAL |
| F39#14 | swimmer water contact | 6.37 | **6.75** | +0.38 | 6.3, 6.7, 6.0 | PARTIAL / PARTIAL / PARTIAL |
| F39#15 | Veilfall approach shallows | 6.27 | **6.14** | -0.13 | 5.8, 6.2, 5.7 | PARTIAL / PARTIAL / PARTIAL |
| F39#16 | live current streaks | 6.88 | **6.56** | -0.32 | 6.2, 6.5, 5.9 | FIXED / FIXED / FIXED |
| F39#17 | current restoration environment | 6.27 | **5.50** | -0.77 | 5.3, 5.8, 5.2 | PRESENT / PRESENT / PRESENT |
| F39#19 | fight team roster contrast | 6.85 | **6.56** | -0.29 | 6.0, 6.3, 6.3 | PARTIAL / PARTIAL / FIXED |
| F39#20 | fight background creature ground contact | 6.37 | **6.42** | +0.05 | 5.8, 6.3, 6.2 | FIXED / FIXED / FIXED |
| F39#22 | Aquaryn dismount camera obstruction | 6.19 | **6.70** | +0.51 | 6.4, 6.5, 6.0 | FIXED / FIXED / FIXED |
| F39#23 | catch chance HUD contrast | 6.8 | **7.35** | +0.55 | 6.8, 6.8, 6.7 | FIXED / FIXED / FIXED |
| F39#24 | creature rest poses | 7.18 | **7.77** | +0.59 | 7.0, 7.3, 6.9 | FIXED / FIXED / FIXED |
| F39#25 | map active region | 7.28 | **7.07** | -0.21 | 6.7, 6.8, 6.2 | FIXED / FIXED / FIXED |
| F39#28 | fight boss title overlay | 7.33 | **7.30** | -0.03 | 6.8, 6.8, 6.6 | FIXED / FIXED / FIXED |

## Read this before using the numbers
- This is the tightest fit of the three batches so far (r 0.940, anchor RMSE 0.39). Two rows map above the top anchor (7.35): F39#4 and F39#24, both raw 7.0 to 7.3 with their recorded defects FIXED 3/3; they are the strongest Medium candidates so far.
- F39#14 was also judged in G-rescore-stale-tier2 (6.44 there, 6.75 here on the same three frames); F39#5 is not in this section.

## Flags

- F39#4 7.81: at or above 7.5, needs Medium
- F39#8 5.82: below 6 (was 5.66)
- F39#17 5.50: below 6 (was 6.27)
- F39#24 7.77: at or above 7.5, needs Medium

## Coverage notes

- every row was judged on all of its job.json frames

## What the judges named (3/3)
- **Current restoration (F39#17), PRESENT 3/3:** "the three frames are the same picture; restoration has no visible environmental effect". This is the one real drop (6.27 → 5.50) and the row is now below 6.
- **Aquaryn mounted on water (F39#8):** a foam disc was added, but "the mount still stands on top of the surface" with no wake or immersion. Still below 6.
- **Shores and dunes (F39#1, F39#15, F39#13):** the rock domes and skirts are gone, but the shore is "bare smooth sand with no layered ecology" and a flat orange dock; all three ask for a wet-sand band, wrack line, driftwood, rock clusters and clumped dune grass in groves.
- **Water:** a hard navy-to-cyan depth edge where a gradient should be; shallows as rimmed discs.
- **Veilfall (F39#2):** still asks for a tiered, vegetated mountain with several falls and base mist (new art).
- **Fight camera (F39#7, F39#19):** a dark void, a grey slab and a floating olive object enter the high fight camera's frame.
- **Recorded defects now FIXED 3/3:** F39#4, #10, #16, #20, #22, #23, #24, #25, #28.
