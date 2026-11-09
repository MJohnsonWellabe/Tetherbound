# G-lens: lens-ground-clearance regression check

Frames: `tb/gpu-frames-1108` 934389d62, manifest `G-lens-ground-clearance`, High, no script errors.
- **Live:** main 61693b5a3.
- **Arm:** live plus `camera_rig.gd` at 1508bdfae (lens ground clearance) plus `ITEM-VENN-PLANE/overlay_lens_ground.json` (enabled; min_m 1.0, step_m 0.25, min_arm_m 2.0).

This is a **regression check only**, as the coordinator asked: does any row drop by more than noise? The Venn pair (061a2108f) was not judged; per the coordinator, the lens never came near the ground in either run.

Judged rows: F38#3, F39#3, F39#15 and F41#5, the 11 unique frames. The manifest's F38#11, F39#2, F39#10 and F41#4 entries reuse the same images, so they need no separate sets.

## Pixel check (before judging)

| Frames | Pixels differing by more than 30 levels |
|---|---|
| Tidewake route and walk (F39#3, F39#15) | 0.1–1.3% (effectively identical) |
| Stormwood (F41#5) | 0.8–4.5% (rain and animation) |
| Meadows fight (F38#3) | 13–21% (fight timing) |

There is no framing change on any non-fight frame, which agrees with the GPU lane's own read.

## Judged

Batch `G-lens`:
- Three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.0312, intercept 0.4622, r 0.845, anchor RMSE 0.617. No warnings.

| Row | Item | Live | Arm | Change | Judges preferring arm | Regression? |
|---|---|---|---|---|---|---|
| F38#3 | Meadows fight camera and creature scale | 6.17 (raw 5.5, 5.6, 5.5) | 6.41 (raw 5.7, 5.8, 5.8) | +0.24 | 3/3 | no (fight timing; see below) |
| F39#3 | Tidewake named destinations | 6.44 (raw 5.6, 5.6, 6.2) | 6.41 (raw 5.6, 5.6, 6.1) | −0.03 | 0/3 (2 ties, 1 by 0.1) | **no (noise)** |
| F39#15 | Veilfall approach shallows | 6.31 (raw 5.6, 5.4, 6.0) | 6.31 (raw 5.6, 5.4, 6.0) | 0.00 | 0/3 (3 ties) | no |
| F41#5 | Stormwood forest ground and distance | 5.58 (raw 4.9, 5.0, 5.0) | 5.62 (raw 4.9, 5.1, 5.0) | +0.04 | 1/3 (by 0.1) | no |

**No row drops by more than noise.** The largest drop is F39#3 at −0.03: one judge scored 6.2 → 6.1 and called the sides "nearly identical". All three judges described F39#3, F39#15 and F41#5 as near-identical.

The F38#3 rise is not a score claim for the fix. It is the non-deterministic fight: on the arm side the judges cite smaller cotton-ball dust puffs in frame 2, which is effect timing, not the camera.

**Verdict: the lens-ground-clearance rule passes this regression gate.** It can ship as a camera bug fix on its unit tests and the ray-picked cause, with no score claim.

## Notes from the batch (unrelated to the arm, 3/3)
- **Meadows fights:** opaque white "cotton-ball" dust puffs cover the creatures' legs and the opponent trainer.
- **Veilfall (F39#15):** the chain of tan sand discs with white rims still reads as stepping stones.
- **Stormwood (F41#5):** a flat even grass carpet runs to one flat purple treeline band.
- **Of / Wu anchors:** consistent with earlier batches.
