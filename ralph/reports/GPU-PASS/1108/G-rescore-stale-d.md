# G-rescore-stale-d: 2 rows re-scored on main (GPU High, one-sided)

LANE-PLACES (re-scoring lane), 12 Nov 2026.

**Frames:** `tb/gpu-frames-1108` section `G-rescore-stale-d` @ 8f46d9e73: main 90ffeb663 as it is, High, each row's own job.json frames (4 frame slots across 2 rows).

**Batch:** three code-blind judges, the standard prompt, each row as a one-sided sheet of its own frames (640×360 tiles) against its job.json brief and recorded defect. Anchors pinned to craft, f10_2_r3_capacitor and f04_6_r22 plus two drawn pairs (five pairs, ten points).

**Fit:** linear, slope 1.0197, intercept 0.2953, r 0.785, anchor RMSE 0.715; confirming batch: True; warnings: none.

**Read the change column as indicative (about ±0.7, the anchor RMSE):** board scores come from other batches and judge pools.


## Results

| Row | Subject | Board | Main now (mapped) | Change | Raw a, b, c | Recorded defect (a / b / c) |
|---|---|---|---|---|---|---|
| F38#8 | Fly carrier grip pose | 7.14 | **6.18** | -0.96 | 5.7, 5.8, 5.8 | PRESENT / PRESENT / PRESENT |
| F41#13 | electric creature finish | 6.66 | **5.97** | -0.69 | 5.5, 5.6, 5.6 | PARTIAL / PARTIAL / PARTIAL |

## What the judges named (3/3)

- **F38#8:** Galecrest itself is at the creature bar; the trainer hangs rigidly beneath it with no grip, weight or motion cue, so the recorded defect is still present. The launch frame is nearly the same as the glide (the tool takes it just after take-off).
- **F41#13:** Fulgocobra reads (glowing eye, gold hood bands); Stormraven is a flat cobalt shape with no visible face, eye or charge contrast. The fall is the raven.

## Flags

- F41#13 5.97: below 6 (was 6.66)

## Coverage notes

- every row was judged on all of its job.json frames
