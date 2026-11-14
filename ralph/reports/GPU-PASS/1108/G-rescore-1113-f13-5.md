# G-rescore-1113-f13-5: 1 rows re-scored on main (GPU High, one-sided)

LANE-PLACES (re-scoring lane), 13 Nov 2026.

**Frames:** `tb/gpu-frames-1113` section `G-rescore-1113-f13-5` @ cad43fd99: main b8622117 as it is, High, the T2 swim views from `tools/capture_tidewake_f13_5.gd` with `tools/visual_judge/camera_sets/T2-current.json` (F13#5 has no job.json item) (4 frame slots across 1 rows).

**Batch:** three code-blind judges, the standard prompt, each row as a one-sided sheet of its own frames (640×360 tiles) against its job.json brief and recorded defect. Anchors pinned to craft, f10_2_r3_capacitor and f04_6_r22 plus two drawn pairs (five pairs, ten points).

**Fit:** linear, slope 1.5578, intercept -2.5110, r 0.958, anchor RMSE 0.401; confirming batch: True; warnings: none.

**Read the change column as indicative (about ±0.3):** board scores come from other batches and judge pools.


## Results

| Row | Subject | Board | Main now (mapped) | Change | Raw a, b, c | Recorded defect (a / b / c) |
|---|---|---|---|---|---|---|
| F13#5 | swimmer-relative current cue (T2) | 6.28 | **5.38** | -0.90 | 4.8, 5.4, 5.0 | PRESENT / PRESENT / PRESENT |

## What the judges named (3/3)

- The water colour is on target.
- The current cue is the problem. The scattered white crescent arcs read as decals or a debug overlay, not authored water flow, and the recorded defect is PRESENT 3/3. One judge also names a vertical beacon line.
- Shared ask (3/3): replace the crescents with one aligned flow field of soft, elongated, animated foam streaks running downstream past the swimmer and bending around it. Crest-shape work was parked after four rounds (G-newapproach-wave-crests-v3-fixed); this ask is a new idea at the cue level.

## Flags

- F13#5 5.38: below 6 (was 6.28)

## Coverage notes

- All four T2 views were captured (0 blank): swim-away-day, swim-across-day, swim-away-night and swim-brine-day. The 10 Nov 6.28 was the mean of three separately judged views, without Brine Steps. Here the four views were judged as one set, so there is no separate three-view number. The brief and recorded defect come from G-newapproach-t2-cleanup's remaining-gap section.
