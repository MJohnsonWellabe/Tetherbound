# G-land-mt-seadepth: soft shallow-to-deep sea gradient (GPU High, base vs arm, + current-states no-loss)

## Verdict: DO NOT SHIP as is. **F39#17/#16 current states LOSE 6.81 → 5.96 (−0.85, 0/3).** F39#1 also loses slightly, 6.53 → 6.43 (−0.10, 0/3). The gradient itself gains: F39#10 +0.62 and F39#15 +0.43 (both 3/3).

| Set | Base | Arm | Gain | Prefer arm | Raw a / b / c (base → arm) | Defect (base / arm) |
|---|---|---|---|---|---|---|
| **F39#15** (terraces route + walk_01, sluice route) | 6.15 | **6.58** | **+0.43** | 3/3 | 5.7→6.0, 5.5→5.8, 5.6→5.9 | PRESENT / PRESENT 3/3 |
| F39#10 no-loss (terraces route, first shore route) | 6.48 | **7.10** | **+0.62** | 3/3 | 5.9→6.3, 6.0→6.5, 5.6→6.0 | a PARTIAL/PARTIAL; b FIXED/FIXED; c PARTIAL/PARTIAL |
| **F39#1** (brine walk_03, first shore route) | 6.53 | 6.43 | **−0.10** | 0/3 (1 tie) | 5.9→5.9, 5.8→5.7, 5.9→5.8 | PARTIAL / PARTIAL 3/3 |
| **F39#17/#16 states no-loss** (S1 live, S1 restored, S2 live) | 6.81 | **5.96** | **−0.85** | **0/3** | 6.0→5.6, 6.2→5.4, 6.0→5.4 | restored-only-streaks PRESENT 3/3 both; guide lanes a FIXED→PARTIAL, b/c PARTIAL→PARTIAL |

- **Scores:** all mapped. Fit: r 0.900, slope 1.42, anchor RMSE 0.61; the batch is confirming. The SHOREZONES base is pixel-identical to this one and was judged in the same batch (G-land-mt-shorezones).
- **Ship rule:** two judged rows lose, so this does not ship. The F39#17/#16 loss is large and unanimous. The F39#1 loss is small (−0.10, within noise), but no judge prefers the arm there.

## What the judges see
- **Route frames, the good part (3/3):** base deep water is "flat inky navy, a hard two-tone against cyan". The arm gives "a mid-blue deep tone with visible wave texture and a gradual falloff toward the horizon".
  - That is F39#10's gain. Judge b calls F39#10's defect FIXED on both sides.
  - It also lifts F39#15's frames, though the defect itself is unchanged: "the ruler-straight chain of nearly identical tan discs" is PRESENT 3/3 on both sides.
- **Current states, the loss (3/3):** base is "a smooth cyan-to-navy gradient with fine ripple texture". On the arm, "long diagonal darker-blue streaks fan across the whole water surface in all three frames, plus confetti-like white flecks". They read as "projected ray or lane bands" or "painted on". This is exactly the GPU lane's warning. The guide-lane defect comes back (judge a: FIXED → PARTIAL).
- **F39#1:** the shore frames barely change. One judge reads base's "slightly deeper navy far band" as helping depth.

## Next asks (LANE-LAND-MT)
1. **Keep the route-scale gradient, but stop it producing the radiating streak bands in the current-states camera.** The streaks are probably the depth or wave term sampled at that camera's grazing angle or height. Clamp or fade that term with distance and view angle, or apply the gradient without the wave-band texture on open water. Re-capture states S1 live, S1 restored and S2 live, plus F39#1. Ship once states are level or better. F39#10 +0.62 and F39#15 +0.43 are waiting on it.
2. **F39#15's real defect is the disc chain, untouched 3/3.** Replace the straight chain of identical tan discs with irregular sandbars and rock reefs of varied size and spacing. Scene.
3. **Restored state:** the restored current still differs from live only by the streaks (PRESENT 3/3). Give restored a visible water-colour or sandbar change.
