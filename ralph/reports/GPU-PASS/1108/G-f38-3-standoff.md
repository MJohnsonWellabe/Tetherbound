# G-f38-3-standoff: Meadows trainer-aside standoff (F38#3)

> **Correction (coordinator, 10 Nov):** the wide bridge-view frames are not capture noise. The GPU lane found that **the arm itself** sends the fight camera to the wide bridge view in 8 of 12 arm frames; live does so in 0 of 12. Excluding grunt-02 and grunt-03 as "not like-for-like" therefore dropped the change's main effect, and the grunt-01-only +0.45 below is **biased and not a verdict on the arm**. F38#3 will be re-scored on the full set, wide arm frames included, once the GPU lane re-pushes them.

Frames: `tb/gpu-frames-1108` da880df9e, High, controller prompts on both sides.
- **Live:** main 52a633598.
- **Arm:** live plus `ITEM-F38-3/overlay_meadows_standoff.json` at e5c7548b4 (`trainer_aside.realm_1104` on, Meadows `side_m` 3.8, `forward_m` −2.2).
- **Blank-frame receipts:** 0 of 72 on both sides.

## Pre-judge render check
A pixel diff cannot isolate the arm: grunt-01 differs by 17.9%, grunt-02 by 48.1% and grunt-03 by 44.4%, and fight timing differs between runs. A visual check of the stacked frames shows:

| Frame | What the check shows | Judged? |
|---|---|---|
| **grunt-01** | Like-for-like. The arm applied: the player trainer now stands aside in the foreground instead of between the two creatures. | **Yes, the only pair judged** |
| **grunt-02** | The arm camera ends on a different, wide angle toward the bridge (GPU lane note). | No |
| **grunt-03** | **Also not like-for-like.** The arm camera likewise ends on a wide view toward the bridge, with a large green foreground blob. This was not in the GPU lane's note. | No |

## Judged

Batch `G-stand`:
- Three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.3522, intercept −1.1875, r 0.838, anchor RMSE 0.630.
- Warning: the arm meets the bar only above the top anchor (7.35). This batch's anchors reach 7.35, so it is the confirming batch.

| Row | Frame | Live | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|---|
| F38#3 | grunt-01 | 7.29 (raw 6.2, 6.3, 6.3) | **7.74** (raw 6.6, 6.6, 6.6) | **+0.45** | **3/3** |

**The ship rule is met (gain > 0, 3/3), and the judges credit what the arm does:**
- **Arm side:** "the player trainer clearly readable in the foreground" (3/3).
- **Live side:** "both trainers are bunched against Terrapup's chest … close to clipping into it" or "squeezed between the two creatures" (3/3).

The recorded defect ("the oversized ally … hides the trainer opponent or player while some frames clip into creature geometry"):
- **Arm:** PARTIAL (3/3).
- **Live:** PRESENT for judges a and c; PARTIAL for judge b.

**F38#3 at High:** the arm side maps **7.74**, with all three judges at 7.74, in a confirming batch. That is above 7.5, but on one frame and one run only. Before it can close:
1. **Re-shoot grunt-02 and grunt-03 like-for-like.** The arm camera must end on the same angle as live; it currently swings to the wide bridge view in two of three frames.
2. **Capture Medium on all three frames.**

This is a near-bar item; it was at 6.17 and 6.41 in G-lens on the same stand.

## Remaining F38#3 asks (3/3)
- **Combat dust:** replace the opaque "cotton-ball" puffs that hide the creatures' hindquarters with thin, translucent dust.
- **Lighting:** the light is flat and green with little rim.
- **Mudsnout:** its root-line trait barely reads (judge b).
