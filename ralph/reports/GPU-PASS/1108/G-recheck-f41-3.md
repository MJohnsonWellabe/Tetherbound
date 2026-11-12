# G-recheck-f41-3: one-sided re-score of F41#3 on main (GPU High)

Frames: `tb/gpu-frames-1108` 30df95d22, main e1c941cbd, High, `--fixed-fps 20`.
- Voltarach is the native eight-leg model.
- The giant-tree fight fade has landed.
- Blank frames: 0 of 60.

Sheets (one-sided, the same image on both sides):

| Fight | Frames | Layout |
|---|---|---|
| Capacitor Alpha | i01, tell1 a-start, d-strike, e-impact | 2×2 |
| Hollows Alpha (as in `G-hollows-giant-trees.md`) | i00, i02, i04, tell1 a/d/e, tell3-b-mid, tell4-a-start, 99-after | 3×3 |

Batch `G-rf3`:
- three code-blind judges, standard prompt, F41#3 brief and recorded defect;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22, so this is a confirming batch.

Fit: linear, slope 1.3986, intercept −1.9749, r 0.983, anchor RMSE 0.182. No warnings.

## Verdict: F41#3 = 6.23. Above 6; spacing defect PRESENT 3/3.

| Fight | Raw (a, b, c) | Mapped (a, b, c) | Mapped mean |
|---|---|---|---|
| Hollows Alpha | 5.8, 6.0, 5.8 | 6.14, 6.42, 6.14 | 6.23 |
| Capacitor Alpha | 6.1, 5.8, 5.7 | 6.56, 6.14, 6.00 | 6.23 |
| **F41#3 row** | | | **6.23** |

- **Above 6: yes.** The row leaves the below-6 list. The previous latest score was 5.89 (`G-hollows-giant-trees.md`, before the native model and fade on main); the best was 6.86 (`G-voltarach-value.md`). The fights diverge from run to run, so expect about ±0.3 between runs.
- **Not near 7.5.**
- **Spacing defect: PRESENT on both fights, from every judge (3/3).**

## What the judges see
- **Capacitor:**
  - In i01 and tell1 a and d, Sparkit stands behind or among Voltarach's front-left legs, and the two bodies merge into one gold mass.
  - At tell1 e-impact the trainer and Sparkit sit under the spread legs inside the white burst. Judge b: "geometry passing through the white impact burst".
  - This matches the GPU lane's own note.
- **Hollows:** Sparkit sits tucked between or behind the forelegs in most frames (row 2 frames 1–3, row 3 frames 1–2). In one frame the legs also cross the trainer.
- **No trunk blocks the fight** in the judged frames. The exception is judge a's note that in 99-after the spider is far off and half behind a trunk.
- **What helps:**
  - Voltarach reads as the brightest subject.
  - The Capacitor impact (copper ground cracks, cyan arc, strike flash) reads as a real hit.
  - The Hollows moss and mushrooms match the board.
- **Other drags:**
  - Judge c: Voltarach's gold emission blows the legs out to near-white, hiding the ridged material and blue eyes.
  - Sparkit and the trainer are tiny and partly under the HUD.
  - The purple storm sky shows only at the Capacitor impact; Hollows reads green-teal.

## What the judges ask for (all scene)
1. **Hold Sparkit and the trainer outside Voltarach's leg radius** on the camera-facing flank, through telegraph and impact. Two judges also ask to pull the camera back to a three-quarter view. All three judges rank this first.
2. **Pull back Voltarach's gold emission** so its material and eyes read and the ally separates.
3. **Grade Stormwood toward the purple storm sky**, with fewer competing glowing mushrooms.
