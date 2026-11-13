# G-below6-f40-3-landmarks: Cloudreach landmark crowns and approach stands (F40#3; GPU High)

## Verdict
**RE-BASELINE:** F40#3 is now **6.33**, up from the board's 5.65, so the row rises above 6. Against base the arm gains +0.33, but only 2/3 judges prefer it, and two of the three stands moved. Per the coordinator's ruling this is a new baseline, not a like-for-like ship call.

## Frames
`tb/gpu-frames-1108` 2efdde92e, High. Both sides were captured on `tb/below6` 0623dcbfe (main through #917, no import) with `phase2_capture_locations.gd --biome=cloudreach`, day, approach view, seed 2042.
- **base:** overlay off, with the old stands and the crowns off.
- **arm:** `BELOW6-F40-3/overlay.json`, which turns on `landmark_crowns_1111` and the `approach_overrides.candidates_1112` stand moves.
- 6 frames, 0 blank, 0 script errors.

What changed between the sides:
- broken_skyroad_arch: identical on both sides; it is the control.
- old_wind_observatory: the stand moves onto the path.
- windscar_beacon: the stand moves in, and the new glass dome crown is visible.

## Set
- The row's three job.json approach frames, in a 2×2 with the fourth tile empty.
- Brief and recorded defect are F40#3's.

**Batch `G-f403`:** three code-blind judges using the standard prompt. Anchors are craft, f36_0_npc:C1 and f10_2_r3_capacitor; it is a confirming batch.

**Fit:** linear, slope 1.117, intercept −0.0321, r 0.877, RMSE 0.664. No warnings.

## Results

| Side | Raw a, b, c | Mapped | Recorded defect (a / b / c) |
|---|---|---|---|
| base | 5.6, 5.4, 5.2 | 6.00 | PRESENT / PRESENT / PRESENT |
| **arm (new baseline)** | 6.0, 5.3, 5.8 | **6.33** | PARTIAL / PRESENT / PARTIAL |
| difference | | +0.33 | prefer arm: a, c (2/3); b prefers base by 0.1 |

**What the arm adds (3/3):** the windscar beacon's "blue-and-gold glass dome over stone columns, with banners", which reads as "a clear step toward the Sky Aviary board's language". The observatory gets "a gold armillary ring at the end of a dirt path".

**Judge b's dissent:** on the arm the observatory path is "a blurry, stretched dirt path texture running down a flat green slab ... the weakest frame across the two sides".

## What still holds F40#3 down (3/3)
1. **The skyroad arch frame shows no landmark.** On both sides it is "an empty field between two blocky stacked-slab cliff faces". This one frame keeps the recorded defect PARTIAL at best.
2. **The ground.** The grass is a uniform carpet with no groves, edges or clearings. The rock pillars are regular stacked slabs, not pale stratified stone. The observatory plateau is "a cylinder dropped on the ground", with a hard circular rim.
3. **The observatory.** On the arm, the path texture is stretched (judge b), the tower top is cut off at the frame edge, and the tower itself is a plain cylinder. Judges ask for a hero mesh in the aviary-board style (new art).

## Recommendation
1. Record F40#3 at **6.33** on the new stands.
2. Fix the next two things:
   - Stage the skyroad arch frame on its actual arch: a stand change, or a landmark at that view.
   - Replace the observatory's stretched path texture and hard plateau rim (scene).
   Together these address every remaining PRESENT and PARTIAL mark.
