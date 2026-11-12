# G-newapproach-cloud-plane: flat CloudSea box removed (F40#6, F40#11; GPU High)

Frames: `tb/gpu-frames-1108` 3f00e867c, High.
- base = `tb/newapproach` 241780e7f.
- arm = base with the flat CloudSea box not drawn.

Sheets, base against arm (frame lists in `yardstick_g_cp/`):
- F40#6 (mount at the terrace edge and the cloud crossing): frames 17, 18, 27 and 28, 2×2.
- F40#11 (cloud puffs at the terrace edge): frames 16, 17 and 18.

Render check: 7–30% of pixels changed.

Batch `G-cp`:
- three code-blind judges, standard prompt, each row on its own catalogue brief;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.

Fit: linear, slope 1.2038, intercept −0.4963, r 0.894, anchor RMSE 0.619. No warnings.

## Verdict: DO NOT SHIP. Both rows lose.

| Row | Base | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| F40#6 mount/cloud crossing | 6.08 | 5.72 | **−0.36** | **0/3** |
| F40#11 edge cloud puffs | 5.80 | 5.64 | **−0.16** | 1/3 |

Raw Bar A, base → arm (judges a, b, c):
- F40#6: 5.8, 5.1, 5.5 → 5.5, 4.9, 5.1.
- F40#11: 5.4, 5.0, 5.3 → 5.1, 5.2, 5.0.

Neither side passes the recorded defect on either row: all three judges mark it PRESENT on both sides.

## Why the arm loses
- **Warm, beige cloud floor.** Without the box, the floor and sky read as one warm beige mid-tone on the arm. The judges say the drop loses depth and cloud merges with cliff.
- **The base reads better.** Its cooler blue-white floor has more value separation, which judges call closer to the board's "bright sky, pale stratified stone".
- **Judge b's F40#11 preference** (5.2 vs 5.0) came from the arm floor's slightly more streaked texture. The edge puffs are unchanged on both sides.
- **The arm doesn't touch the named defects.** The mount still floats upright over the cloud floor (F40#6), and the polygonal puffs still sit at the cliff edge (F40#11).

## What the judges ask for (both sides)
- **F40#6:** ground the mount at the cliff edge, with clamped pathing or an authored drop, plus a contact shadow. The deer is about trainer height and unreadable from behind.
- **F40#11:** replace the edge puffs with soft volumetric cards that blend into a stratified cloud floor. Grade the sky bright blue so it separates from the pale stone.
- **Keep the floor cool and light.** If the box goes, whatever replaces it must keep a cool, light floor value. Removing it alone is a net loss.
