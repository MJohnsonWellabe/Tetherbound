# G-beings-wmonitor-ground: F36#92 faint limb sink (GPU High, base vs arm)

## Verdict: SHIP (+0.35, 3/3 prefer the arm, no loss). High does NOT map to 7.5, so do not queue Medium.

| Set | Base (main) | Arm (limb_sink_frac 0.5) | Gain | Prefer arm | Raw a / b / c (base → arm) |
|---|---|---|---|---|---|
| **F36#92** standing, hit, faint mid, faint end | 6.68 | **7.03** | **+0.35** | 3/3 | 6.1→6.4, 6.1→6.4, 6.2→6.5 |

**Defects (base → arm):**
- "Faint does not settle": PRESENT → PARTIAL, 3/3.
- "Dark olive body, low contrast": PARTIAL on both sides, 3/3.

**Why High is not at the bar:** this batch ran about 0.6 strict (the F38#38 control read 7.63 against 8.16/8.30). The same base frames read 7.47 in G-rescore-f36-50-c673. On that panel the arm would sit near the bar, but this batch's mapped score is 7.03, so Medium is not queued under the 31 Oct rule.

## What the judges see
- **Faint-050 (3/3):**
  - Base: "both front legs and the forebody are lifted off the ground, so it floats mid-stride", with a detached shadow.
  - Arm: "lower, with the belly closer to the ground", and the legs fold toward the ground.
- **Faint-100 (3/3):** grounded on both sides. Judge c: "the limbs splay rather than settle into a slumped pose", and the head is still slightly raised (judge a).
- **Body (3/3):** the dark green body with a cream belly, orange crest and teal stripe reads better than "dark olive", but it is still mid-value against the grey stage.
- **Face (judge a):** the face and eye are small. **Element (judge c):** the glowing trait does not show at this size.

## Frames and batch
- Section: `tb/gpu-frames-1113` ddaf9cae3, High, pose stage.
- Only faint-050 differs (mean 1.46). hit-000, hit-050 and faint-100 are identical.
- Batch: `yardstick_g_batch5_1113/`. Fit r 0.925, RMSE 0.38. Confirming.

## Next asks (LANE-BEINGS)
1. **Body value:** lift the dorsal and flank value with a lighter olive or a belly band carried up the flank, and add rim light. This is 3/3, and the main lever left. Material.
2. **Faint-100:** let the limbs slump inward and the head rest on the floor. Pose data.
3. **Element:** make the teal stripe or eye glow readable at contact-sheet size. Keep it subtle: one trait only. Material.
4. **Re-judge** at High, with the F38#38 control, once 1 lands. If High maps to 7.5 or above, add Medium.
