# Tidewake close-1024 round r3: F13#5 currents, PARKED (24 Oct 2026, CT)

- **Change:** every anchored channel stake leans 13 degrees downstream and trails a 7 m tapered foam wake from its waterline (`water_current_drift_markers.gd`, `lean_deg` / `wake_length_m`). This was the b7 judges' own ask: "the stakes mark a position, the water between them does not move".
- **Sides in one batch:** control (main 5f1f388cc), b6 (81f8f630e) and r3, so all three are on one scale. Same fixed views, CPU llvmpipe, Low, 1920x1080.
- **Yardstick:** standard prompt verbatim, three fresh code-blind judges; `anchor_tiles.py --seed 313 --pairs 4 --include craft --include f36_0_npc:C1`; `calibrate.py` fitted a line (slope 0.672, r 0.674), anchor RMSE 0.71, top anchor 7.53, `confirming_batch: true`.

## Mapped Bar A

| Side | Raw (j1/j2/j3) | Mapped mean |
|---|---|---|
| Control (set Mp-B) | 4.8 / 4.6 / 3.5 | 5.75 |
| b6 (set Cq-A) | 5.5 / 5.0 / 4.2 | 6.16 |
| **r3 (set Cq-B)** | 5.4 / 5.1 / 4.4 | **6.20** |
| r3 (set Mp-A) | 5.4 / 5.0 / 4.0 | 6.09 |

r3 gains +0.04 on b6 in the same batch.

## Disposition: PARKED

| Round | Approach | Best mapped | Gain on best |
|---|---|---|---|
| close-1022 b1-b3 | painted streaks, then ribbons | 4.96 | — |
| b5 | tide-line seams | 6.11 | +1.15 |
| b6 | tapered foam tongues, soft lane tint | 6.16 | under +0.5 (first) |
| r3 | leaning stakes with wakes | 6.20 | under +0.5 (second) |

Two consecutive rounds under +0.5, so the gain rule parks the row at **mapped CPU 6.20**. That is below the 6.7 CPU-provisional bar and below 7.5, so **F13#5 stays failing**, parked with its evidence. Every candidate stays OFF.

What the row did win: the painted road-marking read and the box-like floaters, PRESENT on the control for every judge in every batch, are FIXED or PARTIAL on all three candidates. What it did not win: direction. Two judges still call it PRESENT on r3, and the wake is too small at the fixed camera distance to carry it.

## What the row needs next (all three judges, consistent across four batches)

The cue has to come out of the water surface, not out of furniture on it: flow-aligned surface normals that shear along the lane, foam streaks that travel it from dock to horizon, and drifting flotsam carried with them, with the stake markers reduced to a faint confirmation at the dock. That is an animated-surface change to `water.gdshader`'s flow path rather than another presentation pass, and it is the recommended reopening condition for this row.
