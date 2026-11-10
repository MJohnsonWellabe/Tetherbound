# G-stormwood-swing-2-depink: darker olive wet earth, matte pools, thin near rain (F41#4, #5, #12, #17)

Frames: `tb/gpu-frames-1108` 31530e0d0, High. Live and arm as in the GPU lane's manifest.

**Pre-push check (GPU lane):** no pink, gloss gone, amber vein clear. Two caveats: the loam reads cool slate-grey at crown_arch and heartstone, and some pool blotches are still hard-edged.

## Pre-judge render check
The arm is in frame:

| Views | Pixels changed | Luma change |
|---|---|---|
| crown_heartstone | 20% | +5 |
| crown_arch | 16% | +8 |
| fallen_giant | 10% | +4 |
| Other views | 2–8% | under 2 levels |

This is a much smaller footprint than swing-1.

## Judged
Batch `G-sw2`:
- Three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.112, intercept −0.0923, r 0.858, anchor RMSE 0.593. No warnings.

| Row | Live | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| F41#17 Crown Arch | 6.65 (raw 6.6, 5.8, 5.8) | 6.84 (raw 6.4, 6.2, 6.1) | +0.19 | 2/3 |
| F41#5 forest ground | 6.10 (raw 6.0, 5.3, 5.4) | 6.02 (raw 5.8, 5.5, 5.2) | −0.08 | 1/3 |
| F41#12 charged road | 6.17 (raw 6.0, 5.4, 5.5) | 6.10 (raw 5.7, 5.7, 5.3) | −0.07 | 1/3 |
| F41#4 destinations | 5.91 (raw 5.9, 5.2, 5.1) | 5.88 (raw 5.6, 5.5, 5.0) | −0.03 | 1/3 |

## What the judges saw
- **The pink is gone.** No judge mentions pink or salmon ground on the arm side, and the swing-1 losses (−0.23 to −0.41) are gone.
- **No slate-grey cast was noted on the arm side**, although the GPU lane had flagged one.
- **The live side's rain draws the complaints.** All three criticise its "thick white sticks", "oversized rain streaks" and a blown specular blot around the trainer in the heartstone frame. On the arm side the judges describe no rain artefacts or specular blots. The thin near rain and matte pools are doing their job, but they barely register as a positive.
- **The arm's ground reads as neutral.** Two judges still describe a "flat dark mud" or "bare, flat black mud" surround at Crown Arch on both sides. Nobody credits the olive wet earth as the board's moss and black pools.
- **Oxblood:** two judges noted a small red flag in the distance of the charged-road frame 2, on **both** sides, as a possible oxblood leak. It is not caused by this arm; it is listed for the lane to check.

## Verdict
**DO NOT SHIP ALONE.**
- **Effectively neutral.** Three rows are flat (−0.03 to −0.08, 1/3), and F41#17 is +0.19 with 2/3. That passes the per-row ship rule, but it is far below the 0.5 standalone line.
- **The de-pink fixed swing-1's regression but added no lift.** The direction is safe, not sufficient.
- **Keep it as the base for a bigger Stormwood swing.** The thin rain and matte pools avoid artefacts the judges dislike on live.
- **All three judges name the same lift:**
  - break the flat plain with rises, black pools and layered ancient-tree silhouettes;
  - add a purple storm sky with white-violet lightning and fog layers;
  - tone the salmon trunks toward natural bark.
