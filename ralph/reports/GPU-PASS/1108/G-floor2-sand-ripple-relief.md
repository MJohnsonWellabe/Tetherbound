# G-floor2-sand-ripple-relief: softer dune normal, finer ripple (F39#30, with F13#5 and F39#3; GPU High)

Frames: `tb/gpu-frames-1108` 3fcb19b91, High 1920×1080, `capture_tidewake_f13_5.gd --camera-set=F39-look.json`. Six views.
- base = main 9ee887352 (#899) as is.
- arm = base + `tb/floor2` c092a2309 `FLOOR2-SANDSTRIPES/overlay_ripple_relief.json` (`tidewake_look.json` dunes):
  - `normal_strength` 0.14 → 0.035;
  - `ripple_strength` 0.009 → 0.03.
- The wild creature at the shore edge differs between sides from spawning, not from the overlay.
- Blank frames: 0 of 6 per side.

Render check (pixels changed):

| Frame | Changed |
|---|---|
| lesson-dawn | 0.5% |
| shore-golden | 0.9% |
| shore-day | 1.2% |
| lesson-dune | 0.6% |
| shore-night | 1.2% |
| shore-rain | 15.8% (rain streaks) |

Sets:

| Set | Frames | Layout | Brief | Recorded defect |
|---|---|---|---|---|
| F39#30 arm frames | lesson-dawn above shore-golden | full size, stacked | Tidewake frame matrix | "Hard, regularly spaced dark diagonal stripes cross the sand at golden hour and dawn" |
| F39#30 controls | shore-day, lesson-dune, shore-night, shore-rain | 2×2 | same | same |
| F13#5 | lesson-dawn, shore-golden | stacked | currents, inhabited docks and Veilfall distance read | none recorded |
| F39#3 | lesson-dawn, shore-golden | stacked | named destination read | its catalogue defect |

The F39#30 brief comes from `briefs-1104/vis_tidewake.md`, since job.json has no entry for F39#30.

Batch `G-sr`:
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.

Fit: linear, slope 1.4538, intercept −2.2438, r 0.938, anchor RMSE 0.48. No warnings.

## 1. F39#30 first GPU baseline (base, High): 5.85
- Base across all six views, weighted by frame count: (2 × 5.75 + 4 × 5.90) / 6 = **5.85** mapped.
  - arm frames, base side: 5.75;
  - controls, base side: 5.90.
- The board has a CPU-only 5.75.
- **F39#30 is below 6 at High.**
- Medium is not captured.

## 2. Paired arm against base: SHIP

| Set | Base | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| **F39#30 arm frames** (dawn, golden) | 5.75 | **6.29** | **+0.54** | **3/3** |
| F39#30 controls (day, dune, night, rain) | 5.90 | 6.09 | +0.19 | 2/3 (1 tie), no loss |
| **F39#30, all six views** | 5.85 | **6.16** | **+0.31** | — |

Raw Bar A, base → arm (judges a, b, c):
- Arm frames: 5.4, 5.4, 5.7 → 5.9, 5.7, 6.0.
- Controls: 5.5, 5.6, 5.7 → 5.7, 5.6, 5.9.

Recorded stripe defect:
- **Arm frames:** base PRESENT 3/3; arm PARTIAL 3/3. Dawn stripes become "softer ripples that are still regular".
- **Controls:** base PRESENT 3/3; arm PARTIAL for judges a and c, PRESENT for judge b.
  - Judge c names the lesson-dune view, which still has diagonal stripes on both sides.
  - Judge a names the rain view, which has them on both sides.
  - Judge b names the day and dune views, which have them on both sides.
  - The judges therefore also see the overlay soften the control sand slightly. It is global to the dune material, so this is expected. It is a gain, not a loss.

The ship rule is met: gain > 0, 3/3 prefer on the arm frames, and no loss on the controls. With F39#30 at 6.16, the arm takes it above 6.

## 3. The dawn and golden frames on the other briefs

| Row | Base | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| F13#5 currents, docks, Veilfall distance | 5.70 | 6.04 | +0.34 | 3/3 |
| F39#3 named destination read | 5.99 | 5.99 | 0.00 | 0/3 (3 ties) |

- **F39#3 defect:** PRESENT 3/3 on both sides. First Shore reads as "a small dock, a sign and a distant rock spire", with no hall, arch or terrace. The overlay does not touch it.
- **F13#5:** the arm's softer sand helps. All three judges still name the same gaps:
  - no visible current;
  - an empty, uninhabited jetty;
  - Veilfall reads as "a tiny pale spire", far from the board's waterfall mountain.

## What the judges still name (both sides)
- **Black horizon band at dawn (3/3):** a hard black band where the water meets the sand and horizon at dawn, under the sun. It reads as a missing shoreline or depth seam. Judge b also names a blown-out sun disc sitting on the ground line. This is new and scene-fixable.
- **Night:** a flat, saturated royal-blue or navy wash with the dunes grey-white (3/3).
- **Rain:** long, opaque white streaks under a fully lit noon sky, with no storm grade or fog (3/3).
- **Sparse shore:** few trees, no dune grass, driftwood or rock clusters.
- **Tidewake landmarks:** no Veilfall waterfall massif and no inhabited dock or harbour. All three judges call this new_art.

## What would add the most
1. **Sand (scene):**
   - break up the remaining ripple regularity with low-frequency variation and a distance fade;
   - fix the dawn black horizon band and the blown-out sun disc;
   - give night a value range and rain a grey storm grade.
2. **Landmarks (new_art):** a Veilfall waterfall-mountain hero piece and an inhabited dock or hall at First Shore. This moves F13#5 and F39#3.
