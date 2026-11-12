# G-floor2-aquaryn-faint-fold-medium: F39#6 Medium close-out

Frames: `tb/gpu-frames-1108` 086dbe911, **Medium**, seed 2042, `tb/floor2` 7a2899f56 (creature stage on).
- base and arm are the same as `G-floor2-aquaryn-faint-fold.md` (High 7.79):
  - base = settled rest;
  - arm = + faint fold.
- Frames: aquaryn idle, resting and fainted, stacked at full size, on F39#6's brief and recorded defect.

Render check: fainted 7.7% of pixels changed; idle and resting 0.5%. Blank frames: 0 of 3 per side.

Batch `G-afm`:
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22, so this is a confirming batch.
- There are no Medium-specific anchors; the standard set was used.
- Two of the three judge launches were delayed by a transient permission-check outage. All three judges ran on the same, unchanged folder.

Fit: linear, slope 1.3017, intercept −1.3933, r 0.946, anchor RMSE 0.324. No warnings.

## Verdict: F39#6 Medium = **7.46**: 0.04 under the bar. **Does not close.** The arm still wins 3/3 (+0.44)

| | Base (settled rest) | Arm (+ faint fold) | Gain | Judges preferring arm |
|---|---|---|---|---|
| F39#6, Medium | 7.02 | **7.46** | +0.44 | 3/3 |
| F39#6, High (`G-af`) | 7.06 | 7.79 | +0.73 | 3/3 |

Raw Bar A, base → arm (judges a, b, c): 6.5, 6.3, 6.6 → 6.8, 6.6, 7.0. Mapped arm: 7.46, 7.20, 7.72.

Recorded defect:
- base: PARTIAL 3/3;
- arm: FIXED for judges a and c, PARTIAL for judge b.

**F39#6 stays open:** High 7.79 meets the bar; Medium 7.46 does not. One more near-bar change counts under the close-out exception.

## What the judges see at Medium
- **Fainted, arm:** "the body lies flatter in the sand with the head down. It reads as defeated, though the limbs are still somewhat raised" (judge a); "claws are still raised above the torso at the top" (judge b).
- **Fainted, base:** "claws and limbs stick up into the air ... the head still hovers slightly off the sand" (3/3).
- **The raised claws:** at Medium the remaining raised forelimbs and claws read a little more than at High. That is the gap judge b keeps at PARTIAL.
- **No elemental trait (3/3):** "one saturated cyan with a pale belly ... no glowing fins or spots", "little value range".

## What would take Medium across (judges' top changes)
1. **Fold the last raised forelimbs (scene).** In the faint, fold the remaining raised forelimbs and claws under or against the body so no limb rises above the torso. This is the direct cause of the one PARTIAL.
2. **Add the water trait (new_art or texture).** Bioluminescent fin or frill edges, plus darker dorsal values for range. This is within the owner's creature rule: one elemental trait, natural to the element. All three judges name it, and it would lift every Aquaryn frame.
