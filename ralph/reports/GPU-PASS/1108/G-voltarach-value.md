# G-voltarach-value: Voltarach bloom clamp (F41#3)

Frames: `tb/gpu-frames-1108` f0cbdb5e, High.
- **Arm and arm2:** main 52a633598 plus `ITEM-VOLTARACH-BLOOM/overlay_voltarach_value.json` at 65e347fd6 (`species.voltarach.placeholder` `field_emission` 1.5 → 0.35, `field_rim` 0.25 → 0.12).
- **Live:** live and live2 from `G-pilot-mark`, on the same main tree.
- **Blank-frame receipts:** 0 of 114 and 0 of 108.

**Pairing:**
- r1 = live vs arm
- r2 = live2 vs arm2

Not judged:
- **F41#6:** duplicate frame.
- **F41#21:** not like-for-like.

## Pre-judge render check
The share of near-white pixels (luma ≥ 235) drops on every arm frame:

| Frame | live → arm | live2 → arm2 |
|---|---|---|
| i01 | 1.38% → 1.17% | 1.41% → 1.16% |
| tell1-a | 1.72% → 1.29% | 1.94% → 1.29% |
| tell1-e | 3.59% → 1.64% | 3.02% → 1.65% |

The clamp is in frame.

**Caveat found during the check: the two arm runs are effectively one run.** arm and arm2 differ by only 0.4–1.2% of pixels, while live and live2 differ by about 50%. The two pairs therefore share the same arm frames and are **not independent** on the arm side. Effectively this is one arm run against two different live runs.

## Judged

Batch `G-volt`:
- Three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.8355, intercept −4.7031, r 0.901, anchor RMSE 0.499. No warnings.

| Pair | Live | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| F41#3 r1 | 5.82 (raw 5.7, 5.6, 5.9) | 6.86 (raw 6.2, 6.4, 6.3) | **+1.04** | 3/3 |
| F41#3 r2 | 5.70 (raw 5.5, 5.8, 5.7) | 6.86 (raw 6.2, 6.4, 6.3) | **+1.16** | 3/3 |

**The ship rule is met on both pairs (3/3 each).** All three judges credit the bloom directly:
- **Live side:** Voltarach is "blown out to near-white glow, so leg form and the blue eyes are lost" or "over-blooms the spider into a white-gold blur" (3/3, on both live runs).
- **Arm side:** "readable gold-on-dark plating with blue eye glow, close to the roster board" (judge b); "rim-lit gold spider against saturated moss" (judge c).

This is the first fight arm in this pass whose gain the judges attribute to the change itself.

**Part of the gain is staging.** In the arm run's frame 3, Sparkit and the trainer stand clear of the boss. Both live runs have the boss over them. The spacing defect reads PARTIAL on the arm and PRESENT on live (3/3). Because there is only one effective arm run, the gain's **size** (about +1.1) mixes the clamp with that luckier staging. The **direction** for the bloom is explicit and unanimous.

**Recommendation: ship the clamp.** The ship rule is met, and the judges name the bloom fix itself. To pin the size, a second arm run that actually differs (a different seed or timing) would separate the clamp from staging. The row stays well under the bar: arm 6.86 mapped.

## Still holding F41#3 down (3/3)
- Flat magenta telegraph rings and slabs.
- The player's creature is small and low-contrast; it is "a speck" at frame size.
- Spacing is still inconsistent: Sparkit is inside the leg span in frames 1–2 on every side.
- A dark, single-mid-tone grade.
- A dense HUD.
- Judge b notes the salmon "have 0" craft text as near the reserved red; that is the anchor, not this row.
