# G-closeout-meadows-ui: close call for seven Meadows rows on High and Medium in one batch (GPU)

## Verdict: F38#9 CLOSES. The other six do not.
LANE-PLACES' re-score had all seven at 7.5 or above on High. In this batch (fresh judges, confirming anchors, and a closed-row control) only F38#9 holds on both presets.

| Row | Subject | High | Medium | Per judge, High / Medium (mapped) | Close? |
|---|---|---|---|---|---|
| **F38#9** | menu shell | **7.70** ↑top | **7.70** ↑top | 7.84, 7.44, 7.84 / same | **CLOSES** |
| F38#3 | fight camera and creature scale | 7.17 | 7.35 | 7.04, 7.04, 7.44 / 7.30, 7.17, 7.57 | no |
| F38#33 | catch result hierarchy | 7.30 | 7.35 | 7.17, 6.90, 7.84 / 7.44, 7.17, 7.44 | no |
| F38#7 | catch aim readability | 6.77 | 7.26 | 7.04, 6.37, 6.90 / 7.44, 6.90, 7.44 | no |
| F38#19 | exploration HUD | 7.17 | 7.17 | 7.04, 7.17, 7.30 | no |
| F38#34 | placed wall | 7.08 | 7.08 | 7.44, 6.37, 7.44 | no |
| F38#4 | map | 6.99 | 6.99 | 7.17, 6.63, 7.17 | no |
| *Control: F38#38 (closed at 8.16 High / 8.30 Medium)* | craft hint contrast | *7.70* ↑top | *7.70* ↑top | *7.97, 7.17, 7.97* | stays closed |

- **The control reads 0.5–0.6 below its closing scores.** This batch is a stricter panel, not an inflated one. The re-score batch read high: LANE-PLACES' own caveat says about +0.6 against tier2.
  - The two panels bracket these rows.
  - On this one, only F38#9 clears the bar, and it does so as clearly as the closed control.
- **F38#9 meets the bar only above the top anchor (7.53).** This batch's anchors reach 7.47/7.53, so it is the confirming batch.
  - Its lowest judge is 7.44 on both presets. The control's lowest judge is 7.17.
- **Fit caveat.** The fit is weaker than usual (r 0.90, RMSE 0.60), so per-row scores are ±0.3 here. F38#3 and F38#33 (about 7.2–7.35) are near-bar and could pass on a fresh panel. They are the best candidates for a sub-0.5 close-out fix.

## What holds each open row (named by 2/3 or 3/3)
- **F38#3 fight camera:**
  - The Tether grunt stands half behind Terrapup's legs in frames 1–2.
  - A foreground wooden structure intrudes at bottom right.
  - White dotted dust loops read as "debug splines".
  - The recorded defect is PARTIAL 3/3.
- **F38#33 catch result:**
  - A second, same-species Bramblebun sits in the background.
  - The payoff frame shows the orb on grass with no captured creature.
  - Terrapup is cropped at the edge.
  - PARTIAL 3/3.
- **F38#7 catch aim:**
  - The reticle is "a small cyan sliver lost against the hare".
  - A tall cyan sky beam cuts through the target.
  - The High frame 3 camera sits inside a bush that hides both creatures (3/3); Medium does not. That frame is why High scores 6.77 against Medium 7.26.
  - The capture-chance panel itself now separates well. PARTIAL 3/3.
- **F38#19 exploration HUD:** the HUD is now moderate. What holds it is the bedroom scene: "oversaturated orange ceiling and floor" and blown windows. PARTIAL 3/3.
- **F38#34 placed wall:**
  - The featureless rectangle is FIXED 2/3 (now half-timbered).
  - What remains: flat clean plaster, an orange base slab "pasted onto the grass", and a blobby low-detail boulder beside it.
- **F38#4 map:** roads and groves show only inside the surveyed circle. The rest is "grey fog over a grid" and the legend is small. PARTIAL 3/3.

## Frames
- **High:** LANE-PLACES' `G-rescore-stale-ext-meadows`, main c73dcc80f, each row's job.json frames.
- **Medium:** `G-closeout-meadows-ui-medium` (e92acfdc9), main 90ffeb663, the same frame ids.
  - The ui, catch and build tools took `--preset=Medium`. The fights tool renders the world scene under the run's Medium `graphics_override.cfg`.
- **Control:** F38#38's own closing frames from `gpu-frames-1108/F38-38/live/` (High and Medium).
- **Sets:** one set per row, High on one side and Medium on the other (shuffled), so the same judges score both presets on one scale.
  - Single frames at 1280×720; three-frame rows stacked at 960×540.
  - Brief: "one catalogue subject in the meadows biome: <subject>". The recorded defect is the job.json defect.
- **Render check:** mean High-vs-Medium difference per set:
  - 1.4–4.2 on the menus, map, wall and craft panel;
  - 7.5 on the HUD and 14.6 on the fight;
  - about 30 on the two catch rows, which are different moments of the same catch (timing, not preset).

## Batch `G-mu`
- Three code-blind judges, standard prompt, eight candidate sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.3382, intercept −1.3947, r 0.901, anchor RMSE 0.60.
- **Warning:** F38#9 and F38#38 meet the bar only above the top anchor (7.53). This batch is their confirming batch.

**Raw Bar A (judges a, b, c; High / Medium where they differ):**

| Row | Raw |
|---|---|
| F38#9 | 6.9, 6.6, 6.9 |
| F38#38 | 7.0, 6.4, 7.0 |
| F38#3 | High 6.3, 6.3, 6.6; Medium 6.5, 6.4, 6.7 |
| F38#33 | High 6.4, 6.2, 6.9; Medium 6.6, 6.4, 6.6 |
| F38#7 | High 6.3, 5.8, 6.2; Medium 6.6, 6.2, 6.6 |
| F38#19 | 6.3, 6.4, 6.5 |
| F38#34 | 6.6, 5.8, 6.6 |
| F38#4 | 6.4, 6.0, 6.4 |
