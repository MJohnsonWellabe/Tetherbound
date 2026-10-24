# b5, b5b, b6 (24 Oct 2026, CPU llvmpipe Compatibility/Low)

## b5 (void) and b5b: Riverdrake water form
- b5 is void as a measurement: the water plane widened the strip crop until the creature was a few pixels tall; all three judges said they could not resolve it (both sides about 4.8 raw). Files not kept. The crop now comes from the on-stage frames (`BBOX_FROM`).
- b5b (pilot with a level, head-up swim vs installed): fit slope 1.432, intercept -2.332, RMSE 0.43, no warnings. Installed 6.36, pilot 6.64 (judges: swim still reads as wading with striding legs). The swim was re-authored with folded legs for b6.

## b6: Meshy batch 1 naturalistic remakes vs shipping, plus water Riverdrake r2
Stage `capture_f36_poses.gd --whole-body --context`; remakes bound locally (own clips). Standard prompt verbatim, three fresh judges, anchors f10_2_r3_capacitor, f36_0_npc:C1, f36_0_gap:C2 (confirming). Fit linear slope 0.867, intercept 1.562, RMSE 0.67. Raw per-judge scores: `raw_scores.json`.

| Species | Shipping | Remake | Gain | Disposition |
|---|---|---|---|---|
| trailpup | 6.50 | **7.49** | +0.99 | ON |
| mudsnout | 5.61 | **7.40** | +1.79 | ON |
| burrowback | 6.97 | **7.23** | +0.26 | passes; rideable seat re-measure first |
| mosshell | 5.84 | **7.08** | +1.24 | passes; faint stays standing (all judges); water swim mount re-measure first |
| water_riverdrake | 6.36 | **7.00** | +0.64 | ON with the land pilot (b1 7.29) |
| paddlenewt | 5.29 | **6.88** | +1.59 | ON |
| veridian | 6.56 | **6.82** | +0.26 | passes; rideable seat re-measure first; faint props the antlers up |
| mirejaw | 6.59 | 6.42 | -0.17 | OFF |
| staticub | 7.72 | 7.11 | -0.61 | OFF: lost its storm veins; red-maroon fur drifts toward oxblood (all judges) |
| sparkit | 7.08 | 5.84 | -1.24 | OFF: flat toy-like material |

Judges' asks: remakes that lost board identity (Trailpup's green mantle, Mudsnout's moss; both follow their drafted references); Mosshell and Veridian faints; Paddlenewt and Mirejaw tails through the ruler (staging); dark bodies need rim light; a horizontal, partly submerged swim for Riverdrake.
