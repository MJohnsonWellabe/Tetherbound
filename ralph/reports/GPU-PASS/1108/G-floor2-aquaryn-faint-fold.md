# G-floor2-aquaryn-faint-fold: grounded faint with folded limbs (F39#6 close-out; GPU High)

Frames: `tb/gpu-frames-1108` cc9c26af1, High, seed 2042, `tb/floor2` 7a2899f56 (creature stage on).
- Capture: `phase2_capture_creatures.gd --biome=water --only=aquaryn --poses=idle,resting,fainted`.
- base = + `FLOOR2-AQUAPOSE/overlay_aquaryn_rest.json`: the settled rest, landing in #907; scored 7.47 in `G-floor2-aquaryn-settled-rest.md`.
- arm = + `FLOOR2-AQUAFAINT/overlay_faint_fold.json`: rest plus faint_fold, with slack folded limbs and the body on the sand.

Sheet: idle, resting and fainted, stacked at full size, on F39#6's brief and recorded defect as before.

Render check: fainted 7.3% of pixels changed; idle 0.1%; resting 0.2%. Blank frames: 0 of 3 per side.

Batch `G-af`:
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22, so this is a confirming batch.

Fit: linear, slope 1.4597, intercept −2.2857, r 0.985, anchor RMSE 0.175.

Warning, verbatim: "meets the bar only above the top anchor (7.53): F39#6 faint-fold arm; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch".

## Verdict: SHIP. +0.73, 3/3. **F39#6 High = 7.79: 7.5 or above, so it needs a Medium capture to close**

| Row | Base (settled rest) | Arm (+ faint fold) | Gain | Judges preferring arm |
|---|---|---|---|---|
| F39#6 creature faint state (aquaryn) | 7.06 | **7.79** | **+0.73** | **3/3** |

Raw Bar A, base → arm (judges a, b, c): 6.6, 6.4, 6.2 → 7.0, 6.9, 6.8. Mapped arm: 7.93, 7.79, 7.64; every judge is at or above 7.64.

Recorded defect:
- base: FIXED for judge a, PARTIAL for judges b and c;
- arm: **FIXED 3/3**.

**High meets the bar:** 7.79, above the top anchor, in a confirming batch (the fit is the tightest so far: r 0.985, RMSE 0.175). **F39#6 needs the same arm captured and judged at Medium.** It closes at 7.5 or above on both.

The base here maps 7.06, against 7.47 for the same settled-rest arm in `G-ar`. That gap is scatter between batches; the paired gain is the verdict.

## What the judges see
- **Fainted, arm (3/3):** "lies on its side with its head flat on the sand and legs slack. It reads as defeated and grounded", "collapsed on its side with its head on the sand and its body low ... mostly grounded".
  - Judge b: "some forelimbs stick up near the hip, which is a little awkward".
  - Judge c: "some limbs bunch up in the air near the trainer".
- **Fainted, base (3/3):** "rolled onto its back with the legs stiffly in the air ... the body looks lifted off the sand, with a gap between the body and its shadow ... a stiff ragdoll".
- **Idle and resting:** the same on both sides. Resting reads as tired: head drooped, body crouched.
- **Remaining, not blocking (3/3):**
  - no visible water trait (glowing aqua markings, eyes or a bioluminescent frill);
  - pale, barely readable eyes;
  - a hard dark shoreline band behind the creature in every frame.

## Next
**Medium capture of this arm for F39#6.** If it maps 7.5 or above, F39#6 closes.
