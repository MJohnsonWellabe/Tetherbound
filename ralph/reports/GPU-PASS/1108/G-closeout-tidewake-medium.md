# G-closeout-tidewake-medium: F39#4 and F39#24 at High and Medium (two-sided)

LANE-PLACES (re-scoring lane), 12 Nov 2026.

**Frames:** `tb/gpu-frames-1108`. High: section `G-rescore-stale-ext-tidewake` @ f407c5f28 (main 6906a2ebf). Medium: section `G-closeout-tidewake-medium` @ a8c8a85f1 (main 90ffeb663, tools run with `--preset=Medium`). The same five job.json frames on both sides: aquaryn, cannonback and riptusk shiny idle (F39#4); riptusk and torrentoad resting (F39#24).
**Render check:** Medium differs from High on every frame (mean difference 3.7 to 4.3 of 255; 5.8% to 7.9% of pixels differ by more than 20), so the preset reached the tool.

**Batch:** three code-blind judges, the standard prompt, each row as a blind A/B pair (High and Medium, sides shuffled), same three pinned anchor pairs (craft, f10_2_r3_capacitor, f04_6_r22).
**Fit:** linear, slope 1.1572, intercept −0.3798, r 0.843, anchor RMSE 0.62; confirming batch (its anchors reach 7.35). All four scores are above the top anchor, so they are extrapolated.

## Results
| Row | Subject | High (mapped) | Medium (mapped) | Raw High a, b, c | Raw Medium a, b, c | Recorded defect |
|---|---|---|---|---|---|---|
| F39#4 | shiny creature finish | **8.03** | **8.03** | 7.2, 7.3, 7.3 | 7.2, 7.3, 7.3 | FIXED 3/3 on both sides |
| F39#24 | creature rest poses | **7.99** | **7.99** | 7.3, 7.2, 7.2 | 7.3, 7.2, 7.2 | FIXED 3/3 on both sides |

Every judge gave the two sides of each row the same score: at the judged size they could not tell High from Medium.

## Second panel for High
The one-sided re-score `G-rescore-stale-ext-tidewake` (different judges, r 0.940, RMSE 0.39) had F39#4 at 7.81 and F39#24 at 7.77 at High. Two independent panels put both rows at 7.5 or above at High, and this panel puts Medium level with High.

## Recommendation: both rows meet the bar on Medium and High
F39#4 and F39#24 are at a mapped 7.5 or above at both presets, with their recorded defects FIXED 3/3. Closing them is the coordinator's call.

## What the judges still note
- F39#4: the shiny cue is a hue shift only ("a plain recolour"); the cyan drake blends with the water; the dune behind is sparse.
- F39#24: Torrentoad's upright sit reads as an alert idle more than rest (3/3 mention it).
