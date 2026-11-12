# G-f41-24-moss-off: cream ovals removed beside the trainer, Fallen Giant grove (F41#24)

Frames: `tb/gpu-frames-1108`, High.
- **Fix section:** G-f41-24-moss-off (20375a407), `giant_calm`. Live already has the root finish.
- **Control section:** G-f41-24-moss-off-giant (954493b45).
- **Arm:** removes the cream ovals beside the trainer. The lilac notched quad stays on both sides.

## Pre-judge render check
- **Fix frame:** the arm changes 15.6% of pixels and luma drops 1.6, so it is in frame.
- **Control:** 0.65% of pixels change and luma is flat, so it is unchanged as expected. It was not judged.

## Judged
Batch `G-moss`:
- Three code-blind judges, the standard prompt and the same cleanliness brief and recorded defect as `G-f41-24-root-finish`.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.2783, intercept −0.8438, r 0.830, anchor RMSE 0.644. No warnings.

| Frame | Live | Arm | Gain | Judges preferring arm | Defect |
|---|---|---|---|---|---|
| giant_calm | 5.16 (raw 5.0, 4.5, 4.6) | 5.08 (raw 4.9, 4.4, 4.6) | **−0.08** | 0/3 (1 tie) | PRESENT 3/3 on both sides |

## What the judges saw
- **No judge noticed the ovals going.** All three called the two sides "almost identical". Two said the only difference is that "the slab is slightly larger and more prominent" on the arm side. Removing the ovals seems to leave the lilac quad more exposed.
- **What still drives PRESENT on both sides** (all three, unchanged from the root-finish batch):
  - The flat white or lilac slab at lower right, plus smaller pale patches near the trainer's feet.
  - Screen-door dither on the near trunk bases ("reads as a rendering bug").
  - Pure-black, untextured ground with a hard edge where it meets the grass.
  - The trainer's shoulders and arms blown out to white.
  - Off-palette pink-mauve bark. These frames predate the grey bark; the lane should confirm whether grey bark is in this fixture.

## Verdict
- **NO SHIP ON ITS OWN.** The change is neutral (−0.08, 0/3).
- **Harmless but invisible.** Removing the ovals is not wrong, but it does not register while the lilac quad, the trunk dither and the trainer bloom remain. Bundle it with those fixes.
- **F41#24 stays open.** The next pass needs all of these together, and the quad is the item every judge points to first:
  1. remove the lilac quad;
  2. fix the trunk dither;
  3. fix the trainer bloom;
  4. texture the black ground.
