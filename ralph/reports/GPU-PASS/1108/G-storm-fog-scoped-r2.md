# G-storm-fog-scoped-r2: scoped height fog on top of A3 (F41#2, #4, #5, #12, #17)

Frames: `tb/gpu-frames-1108` 0204d9451, High.
- **Live:** main 90886c306 plus the A3 overlay. These are the values that ship in main e30bd6bb6.
- **Arm:** live plus `stormwood_surge.gd` and `stormwood_surge.json` at tb/item-storm-light 5669f6472 (fog snaps off outside the scope), plus `overlay_height_fog_scoped.json`.

## Pre-judge render check
Fog is in frame where it was scoped:

| Frame | Pixels changed | Luma |
|---|---|---|
| Glass Field | 6% | +12 |
| Lantern Hollow (night) | 4.5% | +11 |
| Crown Arch | 4% | +6 |
| Break phase | 15% | +10 |
| Building phase | 9% | +4 |

The forest stands (#4, #5) and the Calm phase are essentially unchanged, at under 5% of pixels and under 1 level of luma.

## Judged
Batch `G-fograin`, shared with G-f40-19-rain:
- Three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.1894, intercept −0.3626, r 0.869, anchor RMSE 0.572. No warnings.

| Row | Live (A3) | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| F41#17 Crown Arch | 6.26 (raw 6.0, 5.3, 5.4) | 6.42 (raw 6.1, 5.4, 5.6) | +0.16 | 3/3 |
| F41#5 forest ground | 5.43 (raw 5.2, 4.5, 4.9) | 5.54 (raw 5.3, 4.6, 5.0) | +0.11 | 3/3 |
| F41#4 destinations | 5.78 (raw 5.6, 4.9, 5.0) | 5.86 (raw 5.6, 5.0, 5.1) | +0.08 | 2/3 (1 tie) |
| F41#2 Surge phases | 5.62 (raw 5.5, 4.7, 4.9) | 5.66 (raw 5.4, 4.8, 5.0) | +0.04 | 2/3 |
| F41#12 charged road | 5.98 (raw 5.8, 5.0, 5.2) | 5.74 (raw 5.5, 4.9, 5.0) | **−0.24** | 0/3 |

## What the judges saw
- **F41#12:** two judges name a blown-out white fog glow that washes out the right third of the Glass Field frame on the arm side ("bright white lens blob", "white fog glare").
- **Other rows:** the judges call the sides near-identical. The arm is "slightly darker" or has "heavier rain", and none of them names fog as a positive.
- **F41#2:** the phases are still indistinguishable on both sides; all three judges marked the defect PRESENT.

## Verdict
**DO NOT SHIP AS IS.**
- **F41#12 regresses** (−0.24, 0/3) because of fog glare at the Glass Field.
- **The other gains are tiny** (+0.04 to +0.16). The rows at +0.11 and +0.16 pass the per-row ship rule, but every expected gain is far below 0.5, and none takes an item near 7.5.
- **Owner rule (25 Oct, bigger swings):** a change gaining under 0.5 doesn't stand alone, so this one should not land by itself even with the Glass Field removed from scope.
- **What to do with it:** fold the scoped fog into a larger Stormwood atmosphere swing, at most, with the Glass Field glare fixed (lower fog density or emission at that landmark).
- **Closes:** none.
