# G-f38-3-standoff-full: F38#3 standoff overlay, full-set re-score (wide arm frames included)

This supersedes the biased grunt-01-only +0.45 in `G-f38-3-standoff.md` and the unscored subset in `G-f38-27-close-medium.md`.

Frames: `tb/gpu-frames-1108` section `G-f38-3-standoff-confirm`, High.
- **Live and live2:** main 52a633598, two runs.
- **Arm and arm2:** live plus `ITEM-F38-3/overlay_meadows_standoff.json` at 7ff252650 (trainer_aside.realm_1104 on; meadows side_m 3.8, forward_m −2.2; realms.water removed), two runs.
- **Pairing:** r1 = live vs arm, r2 = live2 vs arm2.
- **Every frame judged**, including the arm's wide-camera frames, per the coordinator's correction.

## Pre-judge render check
- **arm r1:** all frames are wide, with 41–46% of pixels changed and luma up about 20 levels.
- **arm2 r2:** grunt-01 is wide; grunt-02 and grunt-03 are near-standard (19–22% changed).

## Judged
Batch `G-dustsd` (fit in `G-newapproach-dust.md`). This is a confirming batch.

| Pair | Live | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| F38#3 r1 | 6.37 (raw 6.1, 5.9, 5.9) | 5.28 (raw 5.0, 5.2, 4.8) | **−1.09** | 0/3 |
| F38#3 r2 | 6.40 (raw 6.2, 5.9, 5.9) | 5.92 (raw 5.7, 5.6, 5.4) | **−0.48** | 0/3 |
| F38#11 r1 | 6.29 (raw 5.9, 5.9, 5.9) | 5.32 (raw 5.0, 5.3, 4.8) | **−0.97** | 0/3 |
| F38#11 r2 | 6.48 (raw 6.3, 5.9, 6.0) | 6.14 (raw 5.9, 5.8, 5.6) | **−0.34** | 0/3 |

## What the judges saw
All three independently describe the arm's wide frames as a camera low inside the grass. The complaints:
- oversized yellow flowers fill the foreground;
- the creatures are small, distant and half hidden behind the stream and fence;
- the trainer can't be read;
- flower petals overlap the HUD in two frames.

One judge called it "the worst framing in the batch". Other arm frames show Terrapup turned away, reading as "a headless plated shell".

## Verdict
**DO NOT SHIP.** Every pair is negative and no judge preferred the arm (0/3 on all four). The aside offset pushes the fight camera to a grass-level wide view that buries the fight. Moving the trainer aside only helps if the camera stays at the standard height. Two approaches have now failed on this overlay, so park it until there is a new idea, such as an aside offset that leaves the camera rig unchanged.
