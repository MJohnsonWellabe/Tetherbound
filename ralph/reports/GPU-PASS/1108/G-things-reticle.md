# G-things-reticle: bold outlined catch ring (F38#7 close call; F39#23 no-loss; GPU High and Medium)

## Verdict: SHIP. F38#7's arm meets the bar on both presets (7.76 High, 7.76 Medium; confirming batch, neutral control). The row closes once the overlay is on main.

| Set | Base | Arm | Gain | Prefer arm | Arm per judge (mapped) |
|---|---|---|---|---|---|
| **F38#7 Medium** (clean ring comparison) | 7.40 | **7.76** ↑top | +0.36 | 3/3 | 7.76, 7.52, 8.00 |
| **F38#7 High** | 7.40 | **7.76** ↑top | +0.36 | 3/3 | 7.76, 7.52, 8.00 |
| F39#23 High (Tidewake, no-loss) | 6.83 | 7.44 | +0.61 | 3/3 | 7.64, 7.28, 7.40 |
| Control F38#38 (High vs Medium) | 8.28 | 8.28 | — | — | 8.24, 8.24, 8.36 |

- **Control.** F38#38 read 8.28 against its closing 8.16/8.30, so this panel is neutral (not strict, not lenient).
- **Confirming batch.** The arm sits above the top anchor (7.53), and the anchors include craft (7.35) and f36_0_npc:C1 (7.47/7.53), so this batch confirms it. Fit: linear, slope 1.207, intercept −0.565, r 0.954, anchor RMSE 0.30.
- **The lowest judge is still at the bar.** Judge b's 7.52 is the lowest per-judge arm read, on both presets.
- **The Medium pair is clean.** Same framing, and only the ring pixels differ (mean difference 0.2–0.9 on the job frames). It scores exactly like the High pair (identical per judge), so the gain is the ring, not High's camera difference.

## What the judges see (3/3)
- **Base:** "the aim ring is almost invisible ... only a small cyan marker sits on the hare's chest" at 0% and 9%, with "a faint teal arc" at 82%. The recorded defect is PRESENT.
- **Arm:** "a clear orange ring in frames 1 and 2 and a teal ring in frame 3", which "separate well ... above the flowers". The recorded defect is PARTIAL, because the ring still sits on the hare's body and overlaps the chest marker.
- The capture-chance panel's dark backing reads well on both sides.

## What would add margin on F38#7
- **The flat sprite dust cloud in frame 3** that crosses the trainer and Terrapup (3/3). Replace it with soft particle dust that does not cover the actors.
- **The hare against the sky.** Its pale plates sit close to the bright cloud sky, so the head and ears lose separation (1/3). A slight rim or darker edge would help.
- **Ring placement.** Keep the ring off the trainer (1/3).

## F39#23 (no-loss): gains, with a framing confound
- +0.61 (3/3). The capture-chance label is FIXED on both sides: it sits on its own dark panel, clear of the trainer and sand.
- Part of the gain is High's camera. The arm-High frames include "cyan shoreline, a tree and distant creatures", while base is "a bare empty dune" (3/3). The GPU lane measured that framing difference (Tidewake about 14) and reproduced it on a base re-run. The ring itself also reads ("a clear orange and teal ring" against "very faint").
- Not a loss either way.
- **New issue (1/3):** the left status HUD labels (WIND, Energy, Terrapup) sit over pale sand with weak contrast.

## Pooled current-main line
- F38#7 on current main is the base read here, 7.40 (High and Medium), with G-things-beam's 7.49 (High, the beacon fix, since landed).
- The arm's 7.76 on both presets is the close evidence once `overlay_reticle_ring.json` lands. The GPU lane may want one Medium on-main confirm after landing, per the scoring policy.

## Frames
- **Sources:** `tb/gpu-frames-1108`, `--fixed-fps 20`, 0 script errors, 0 blank.
  - `G-things-reticle-meadows` (63520d538): base-High, arm-High, base-Medium and arm-Medium.
  - `G-things-reticle-tidewake` (8fafefacf): base-High and arm-High.
- **Sides:**
  - **base:** main 1c81cdb45, no overlay.
  - **arm:** main plus `THINGS-RETICLE/overlay_reticle_ring.json` from `tb/things` 07dd4a3a5 (ring_style_1104: outline 0 → 1.5 px, width ×0.7 → ×1.15, alpha ×0.55 → ×1.0).
- **Render check:**
  - **Medium job frames:** 0.2–0.9 mean difference, ring pixels only.
  - **High:** about 30 on every frame, because base-High frames the catch camera differently (reproduced by the GPU lane).
  - By eye, the arm ring is visible at both presets.
- **Sets:**
  - F38#7: 01-aiming-full-health, catch_low and catch_high, stacked, once per preset.
  - F39#23: Tidewake catch_low, catch_high and 01-aiming-full-health at High.
  - Control: F38#38's closing High and Medium crafting frames.

## Batch `G-rt`
- Three code-blind judges, standard prompt, four candidate sets.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22.
- Yardstick: `yardstick_g_things_reticle/`.

**Raw Bar A (judges a, b, c):**

| Set | Base | Arm |
|---|---|---|
| F38#7 Medium | 6.6, 6.4, 6.8 | 6.9, 6.7, 7.1 |
| F38#7 High | 6.6, 6.4, 6.8 | 6.9, 6.7, 7.1 |
| F39#23 High | 6.3, 6.0, 6.1 | 6.8, 6.5, 6.6 |
| F38#38 | 7.3, 7.3, 7.4 | (High and Medium identical) |

Bar B: the F38#7 sets get borderline yes from 1/3 (judge c), and no from 2/3 (flat noon light and the dust sprite).
