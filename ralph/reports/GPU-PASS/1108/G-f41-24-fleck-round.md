# G-f41-24-fleck-round: round glint flecks, so the notched lilac quad is gone (F41#24)

Frames: `tb/gpu-frames-1108`, High.
- **Fix section:** G-f41-24-fleck-round (cf2f3f6ee), `giant_calm`.
- **Control section:** G-f41-24-fleck-round-giant (4e3d2d8a0).
- **Live:** main with the root finish.
- **Arm:** live plus round glint flecks. The GPU lane confirms the notched lilac quad is gone and the small patch has shrunk to a dot. The cream ovals remain.

## Pre-judge render check
- **Fix frame:** 11.3% of pixels changed and luma moved −0.9, so the change is in frame.
- **Control:** 0.30% of pixels changed, so it is unchanged. It was not judged.

## Judged
Batch `G-fleck`:
- Three code-blind judges, the standard prompt and the F41#24 cleanliness brief and recorded defect.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.1697, intercept −0.1099, r 0.846, anchor RMSE 0.615. No warnings.

| Frame | Live | Arm | Gain | Judges preferring arm | Defect (live → arm) |
|---|---|---|---|---|---|
| giant_calm | 5.08 (raw 4.5, 4.4, 4.4) | **5.82** (raw 5.0, 5.2, 5.0) | **+0.74** | **3/3** | PRESENT 3/3 → PARTIAL 3/3 |

## What the judges saw
- **The quad fix registers.** All three name the live side's "flat white-lavender polygon with a hole lying on the ground at lower right" and "smaller pale slab near the lily pads" as placeholder geometry, and all three see it gone on the arm.
- **The cream ovals are not mentioned** on either side. They no longer read as a defect once the quad is gone, which is consistent with `G-f41-24-moss-off`.
- **What keeps F41#24 at PARTIAL** (all three, both sides):
  1. **Screen-door dither** at the bases of the large trunks ("reads as a rendering bug"). This is now the top cleanliness item.
  2. **Trainer bloom:** shoulders and arms blown to white.
  3. **Ground:** a near-black flat plane with flat card foliage.
  4. One judge also sees the fallen log clipping the centre trunk.
- **Bark is lilac-grey in these frames,** so the grey bark appears to be in this fixture.

## Verdict
**SHIP the round flecks.** +0.82 for the root fix earlier, and now +0.74 here with 3/3.

**F41#24 stays open** at 5.82, PARTIAL. The next cleanup in priority order, each named by all three judges:
1. Fix the trunk-base dither fade.
2. Fix the trainer bloom.
3. Give the ground moss and litter.
4. Fix the log/trunk clip.
