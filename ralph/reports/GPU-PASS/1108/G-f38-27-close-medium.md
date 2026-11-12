# G-f38-27-close-medium: F38#27 Medium close-out, plus the superseded F38#3 subset

Frames: `tb/gpu-frames-1108` 261d1d1e.
- **F38#27 Medium** (`G-f38-27-close-medium`): live is main 52a633598; the arm is the same as the High close-out at ed4eb76d4 (`keyboard_chip_only` on, `readability_1110` off). Keyboard prompts on both sides.
- **Blank-frame receipts:** 0 of 12 on both sides.

**Render check:** 0.9–1.2% of pixels differ by more than 30 levels. A visual check confirms the arm in frame: chip-only key labels, and keycap icons for Previous and Next tab in the footer.

**Blinding:** each side's two screens were stacked full width at 1280 px. `anchor_tiles.py` then gave them a random code and side order.

Batch `G-cl`:
- Three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a **confirming batch**.
- Fit: linear, slope 1.8123, intercept −4.6199, r 0.932, anchor RMSE 0.418.
- Warning: the arm meets the bar above the top anchor (7.35). This batch's anchors reach 7.35, so it is the confirming batch.

## F38#27: CLOSES

| Preset | Live | Arm | Gain | Judges preferring arm | Mapped arm per judge |
|---|---|---|---|---|---|
| **Medium** (this batch) | 7.04 (raw 6.4, 6.5, 6.4) | **8.25** (raw 7.0, 7.2, 7.1) | +1.21 | 3/3 | 8.07, 8.43, 8.25 |
| **High** (`G-f38-27-close`) | 6.89 | **7.84** | +0.95 | 3/3 | 7.84, 8.12, 7.56 |

**F38#27 meets the 7.5 bar on both presets in confirming batches: High 7.84, Medium 8.25. Every judge is at 7.56 or above on both. The row closes on the arm at ed4eb76d4.**

The recorded defect ("dense gray-on-navy control instructions and literal key labels make settings and quick binding text hard to scan"):
- **Live:** PRESENT (3/3).
- **Arm:** PARTIAL (3/3).

All three judges cite the single key label per cell, the glyph footer and the shorter reset line.

**What the judges would add next (not needed to close):**
- Brighter grey-on-navy body text.
- Larger key glyphs.
- Stronger cell separation.
- Fill or drop the empty Reset column.

## F38#3 standoff confirm (subset): superseded, not scored
This batch also carried the like-for-like **subset** of `G-f38-3-standoff-confirm` (High: grunt-02 and grunt-03) and `-medium` (grunt-03). Each was judged as live vs arm2 and live2 vs arm2.

**Per the coordinator (10 Nov), those numbers are not a verdict on F38#3.** The arm itself sends the camera to the wide bridge view in 8 of 12 arm frames, so the subset leaves out the change's main effect. They are recorded here only for completeness:

| Pair | Live | Arm2 | Gain |
|---|---|---|---|
| High r1 | 6.44 | 6.98 | +0.54 |
| High r2 | 6.74 | 6.98 | +0.24 |
| Medium r1 | 7.52 | 7.04 | −0.48 |
| Medium r2 | 6.50 | 7.40 | +0.90 |

**Two caveats on these numbers:**
- The arm2 side is the same frames in each run's pair, so the pairs are not independent.
- The scatter (−0.48 to +0.90) is consistent with fight-staging noise on a single frame.

F38#3 will be scored on the full set, wide arm frames included, when the GPU lane re-pushes it.
