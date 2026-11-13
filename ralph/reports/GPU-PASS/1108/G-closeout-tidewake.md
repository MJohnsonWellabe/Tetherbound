# G-closeout-tidewake: close call for F39#4 and F39#24 on High and Medium in one batch (GPU)

## Verdict: F39#4 and F39#24 both CLOSE.

| Row | Subject | High | Medium | Per judge, High / Medium (mapped) | Recorded defect |
|---|---|---|---|---|---|
| **F39#4** | shiny creature finish | **7.77** ↑top | **7.77** ↑top | 8.00, 7.77, 7.54 / same | FIXED 3/3 |
| **F39#24** | creature rest poses | **7.65** ↑top | **7.61** ↑top | 7.89, 7.65, 7.42 / 7.89, 7.54, 7.42 | FIXED 3/3 |
| *Control: F38#38 (closed at 8.16 High / 8.30 Medium)* | craft hint contrast | *7.77* | *7.77* | *7.77, 7.89, 7.65* | FIXED 3/3 |

- **Confirming batch.** Every bar score sits above the top anchor (7.53). The anchors reach 7.47/7.53, so this is the confirming batch.
- **Fit:** r 0.98, RMSE 0.20, the tightest fit tonight.
- **The control reads 0.4–0.5 below its closing scores,** so this panel is slightly strict, not inflated. Both rows score at or near the control.
- **Comparison with the re-score.** LANE-PLACES' re-score had F39#4 at 7.81 and F39#24 at 7.77 on High. Here they read 7.77 and 7.65, consistent within 0.1.

## What the judges say
### F39#4, shiny finish
- No hot magenta remains (3/3). The cyan/white drake, the teal-green turtle and the jade-plated walrus each keep their species material and pattern.
- Margin items:
  - the drake's cyan is close to uniform (2/3);
  - the shiny reads as "recolour, not an added finish" (1/3);
  - the turtle's shell barrels look mechanical (1/3);
  - heads crane skyward (2/3).

### F39#24, rest poses
- Neither creature is on its back any more (3/3). Riptusk sits upright on its belly and Torrentoad crouches.
- Margin items:
  - the poses read "alert rather than restful" (2/3);
  - Riptusk's rear sinks into the sand (2/3);
  - a hard-edged dark shadow quad sits under Torrentoad (1/3).
- True lying or curled rest clips are new art.

## Frames
- **High:** LANE-PLACES' `G-rescore-stale-ext-tidewake` (tb/places 0a289b57), main 90ffeb663, job.json frames.
- **Medium:** `G-closeout-tidewake-medium` (a8c8a85f1), main 90ffeb663, the same five frames. The world-scene creatures tool ran with `--preset=Medium`.
  - F39#4: aquaryn, cannonback and riptusk shiny idle.
  - F39#24: riptusk and torrentoad resting.
- **Control:** F38#38's closing frames (`gpu-frames-1108/F38-38/live/`).
- **Sets:** High on one side and Medium on the other (shuffled), stacked at 960×540 per frame. Brief: "one catalogue subject in the tidewake biome: <subject>". The recorded defect is the job.json defect.
- **Render check:** mean High-vs-Medium difference 3.2 on both rows, 1.4 on the control.

## Batch `G-twm`
- Three code-blind judges, standard prompt, three candidate sets.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22. This is a confirming batch.
- **Fit:** linear, slope 1.1685, intercept −0.6443, r 0.981, anchor RMSE 0.20.

**Raw Bar A (judges a, b, c):**

| Row | Raw |
|---|---|
| F39#4 | 7.4, 7.2, 7.0 (both presets) |
| F39#24 | High 7.3, 7.1, 6.9; Medium 7.3, 7.0, 6.9 |
| F38#38 | 7.2, 7.3, 7.1 |
