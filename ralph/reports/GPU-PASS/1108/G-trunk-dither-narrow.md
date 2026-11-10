# G-trunk-dither-narrow: near_lens_fade narrowed from 3–7 m to 3–4 m (F41#4, F41#5; grove giant_calm; F41#3 regression)

Frames: `tb/gpu-frames-1108`, High.
- **Job frames:** section 531247ece.
- **Grove matrix:** section 07591e530, `giant_calm`.
- **Live:** main ebabb3c2c.
- **Arm:** live plus LANE-MESHY's `near_lens_fade narrow_band_1110` (tb/item-trunk-dither 26ad2fb1a).

## Pre-judge render check
| Frame | Pixels differing by more than 30 | Notes |
|---|---|---|
| giant_calm | 22.7% | The change lands here, on the trunk behind the trainer. |
| F41#4 fallen_giant, crown_overlook | 0.07%, 0.30% | Essentially unchanged; regression check. |
| F41#5 struck_sentinel, crown_overlook, crown_heartstone | 0.45%, 0.30%, 0.38% | Essentially unchanged; regression check. |
| F41#3 fight capacitor_alpha-i01 | 20.3% | The fight caught at a different moment, not the trees (per the GPU lane). Regression check only. |

## Judged
Batch `G-dith`:
- Three code-blind judges and the standard prompt.
- The grove set uses the F41#24 cleanliness brief, with a see-through or dithered surfaces clause added. The rows use their catalogue briefs and defects.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.3949, intercept −1.8368, r 0.848, anchor RMSE 0.612. No warnings.

| Set | Live | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| **Grove giant_calm** (the change) | 5.00 (raw 5.2, 4.9, 4.6) | **6.30** (raw 6.2, 5.7, 5.6) | **+1.30** | **3/3** |
| F41#4 destinations (regression) | 6.11 | 6.11 | 0.00 | 0/3, all three tied |
| F41#5 forest ground (regression) | 5.84 | 5.84 | 0.00 | 0/3, all three tied |
| F41#3 fight (regression) | 6.39 | 6.39 | 0.00 | 1/3 (1 tie) |

## What the judges saw
- **Grove: the dither is fixed.** All three describe the live side's "screen-door dither on the left trunk and the base of the central trunk … see-through … a rendering bug", and all three say the trunks are **solid** on the arm. The F41#24 defect moves from PRESENT 3/3 to PARTIAL 3/3.
- **What still keeps the grove at PARTIAL** (all three):
  - the flat white quad with a hole at bottom right;
  - the pale lilac slab behind or beside the trainer.

  The quad that `G-f41-24-fleck-round` removed is back in this live, so the fleck fix is not in main ebabb3c2c's fixture, or it regressed. The lane should check whether the fleck-round change has landed.
- **No regressions.** The F41#4 and F41#5 frames scored identically on both sides, with no judge noting any difference. In the fight frame the ally spacing reads the same on both sides (PARTIAL or PRESENT, no trunk over a fighter). Side A of the fight sequence anchor shows canopy occlusion, but that is in the anchor tile, not this arm.

## Verdict
- **SHIP.** Grove +1.30 with 3/3, and no regression on the F41#4, F41#5 or F41#3 frames.
- **F41#4 and F41#5 do not move.** As expected, the arm barely touches their job frames.
- **F41#24:** the grove now reads 6.30.
  - **Remaining:** the white quad and the lilac slab. Check that the fleck-round fix is in main.
  - **Earlier issues:** trainer bloom and the flat black ground were named in previous batches, but not by all three this time. The bark now reads lilac-grey "painted plastic" to one judge.
