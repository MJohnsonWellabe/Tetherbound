# G-storm-light-a3: Stormwood key light a3 (F41#2, #4, #5, #12, #17)

Frames: `tb/gpu-frames-1108` bbd41bdc, High.
- **Live:** main 90886c306.
- **Arm:** live plus `ITEM-STORM-LIGHT/overlay_storm_key_a3.json` at 87e3e6695. It writes into `light_pass_1101`: sun #cfc0ff 2.05, exposure 1.5, ambient 2.2, contrast 1.1, rim #c3b6ff 1.25. Unlike a/a2, this targets the pass that actually runs.

## Pre-judge render check
Luma rises 3–6 levels on every arm frame except the Break still (−2). The arm is in frame.

## Judged
Batch `G-a3lip`, shared with G-glass-sink-lip-rim:
- Three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.3601, intercept −1.5157, r 0.918, anchor RMSE 0.458. No warnings.
- Pairing is per row (live vs arm).

| Row | Live | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| F41#2 Surge phases | 5.42 (raw 5.3, 5.0, 5.0) | 6.15 (raw 5.8, 5.6, 5.5) | **+0.73** | 3/3 |
| F41#17 Crown Arch | 6.55 (raw 6.1, 5.9, 5.8) | 6.64 (raw 6.2, 6.0, 5.8) | +0.09 | 2/3 (1 tie) |
| F41#12 charged road | 5.87 (raw 5.6, 5.3, 5.4) | 5.92 (raw 5.6, 5.4, 5.4) | +0.05 | 1/3 (2 ties) |
| F41#4 destinations | 5.96 (raw 5.6, 5.5, 5.4) | 6.01 (raw 5.6, 5.6, 5.4) | +0.05 | 1/3 (2 ties) |
| F41#5 forest ground | 5.65 (raw 5.2, 5.3, 5.3) | 5.65 (raw 5.3, 5.2, 5.3) | 0.00 | 1/3 (1 tie) |

## What the judges saw
- **F41#2:** all three name the arm's first still: visible violet sky lightning and a brighter cloud layer, so one phase now reads distinctly. The recorded defect moves from PRESENT on live to PARTIAL on the arm (3/3). The other two stills still differ mainly in rain density.
- **#17, #12, #4, #5:** the judges called the two sides near-identical. No row regresses.

## Verdict
- **SHIP (one config arm).** F41#2 clears the ship rule (+0.73, 3/3), F41#17 clears it marginally (+0.09, 2/3), and the other three rows are flat with no drop.
- **Closes:** none. Best row is F41#17 at 6.64.
- **Shared judge ideas for the next big swing:**
  - Break the flat grass carpet and the single purple treeline card into groves and layered fog silhouettes.
  - Replace the flat black glossy ground planes with banked wet earth.
  - Make the opaque foreground rain rods smaller or translucent.
  - Move pink trunks and the salmon bears off the reserved red family.
