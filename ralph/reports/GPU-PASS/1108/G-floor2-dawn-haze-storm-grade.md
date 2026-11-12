# G-floor2-dawn-haze-storm-grade: dawn haze + rain storm grade (F39#30, with F39#31; GPU High)

Frames: `tb/gpu-frames-1108` 90d3b0348, High 1920×1080, main e2138671a (#900; sand ripple relief already in).
- Capture: `capture_tidewake_f13_5.gd --camera-set=F39-look.json`, 7 views.
- base = main as is.
- arm = base + `tb/floor2` 5589958a6 `FLOOR2-DAWNRAIN/overlay_dawn_haze_storm.json`:
  - dawn fog 0.0004 → 0.004;
  - rain grade: sun 0.32 → 0.18, grey storm sky, cooler ambient, saturation ×0.72;
  - finer rain streaks.
- Blank frames: 0 of 7 per side.

Render check (pixels changed):

| View | Changed |
|---|---|
| lesson-dawn | 6.0% |
| shore-rain | 45.3% |
| lesson-rain | 20.3% |
| veilfall-rain | 10.1% |
| veilfall-vista-rain | 37.7% |
| shore-day | 1.1% (spawn only) |
| shore-golden | 0.8% (spawn only) |

Sets (each stacked at full size). F39#30's brief comes from `briefs-1104/vis_tidewake.md`, the frame matrix, with the coordinator's two recorded defects:
- "A hard black band sits where the water meets the sand and horizon at dawn";
- "Rain falls under a fully lit noon sky with white cumulus, with no storm grade or fog".

| Set | Brief | Frames |
|---|---|---|
| F39#30 arm frames | F39#30 | lesson-dawn, shore-rain, lesson-rain |
| F39#30 Veilfall rain | F39#30 | veilfall-rain, veilfall-vista-rain |
| F39#30 controls | F39#30 | shore-day, shore-golden |
| F39#31 | F39#31 hero landmark, "Veilfall reads at distance and up close"; no recorded defect | the two Veilfall rain frames |

Batch `G-dh`:
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.

Fit: linear, slope 1.5252, intercept −2.5695, r 0.935, anchor RMSE 0.489. No warnings.

## Verdict: SHIP. All three F39#30 sets gain at 3/3, the controls do not lose, and F39#31 gains.

| Set | Base | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| **F39#30 arm frames** (dawn, shore rain, lesson rain) | 5.82 | **6.63** | **+0.81** | 3/3 |
| F39#30 Veilfall rain | 5.46 | 6.07 | +0.61 | 3/3 |
| F39#30 controls (day, golden) | 7.24 | 7.45 | +0.21 | 3/3 (by 0.1–0.2; spawn difference only, so no loss) |
| **F39#30 row, all seven views** (weighted by frames) | **6.12** | **6.70** | **+0.58** | — |
| **F39#31** Veilfall (rain frames) | 5.56 | **6.02** | +0.46 | 3/3 |

Raw Bar A, base → arm (judges a, b, c):
- Arm frames: 5.6, 5.4, 5.5 → 6.2, 5.9, 6.0.
- Veilfall F39#30: 5.6, 5.0, 5.2 → 6.0, 5.4, 5.6.
- Controls: 6.4, 6.2, 6.7 → 6.5, 6.4, 6.8.
- F39#31: 5.6, 5.0, 5.4 → 6.0, 5.4, 5.5.

**Row figure:** (3 × arm frames + 2 × Veilfall + 2 × controls) / 7.
- base (3 × 5.82 + 2 × 5.46 + 2 × 7.24) / 7 = **6.12**;
- arm = **6.70**.

**Scale note.** The two-frame control set maps at 7.2–7.5 here, against 5.90 for a four-frame control set (day, dune, night, rain) in `G-floor2-sand-ripple-relief.md`. The set content differs (no night or rain), and part of it is batch scatter. Read the paired gains and the row figure within this batch.

**F39#31 gain (+0.46):** under 0.5, and F39#31 (board 5.56) is not near the bar. It rides along with the F39#30 change and does not stand alone. That is allowed, since F39#31 is a no-loss check here.

## The two recorded defects

| Defect | Base | Arm |
|---|---|---|
| Rain under a fully lit noon sky | PRESENT 3/3 on all rain sets | FIXED 3/3 on all rain sets |
| Black horizon band at dawn | PRESENT 3/3 | **PRESENT for judges b and c, PARTIAL for judge a** |

- **Rain: fixed.** The arm's overcast grey storm sky "sits better with the rain and the dark rock". The base puts heavy rain under blue sky and white cumulus.
- **The dawn band is not fixed.** On the arm, judge a calls it "softer" than base. All three still see a dark band along the far waterline beside the sun, plus a dark band at the horizon in the lesson-rain frame. Judge c also sees a milder navy horizon strip in the day frames on both sides. The 10× dawn fog was not enough.

## What the judges still name (both sides)
- **Dawn sun:** a blown-out flat white disc sitting on the sand (3/3).
- **Rain:** the arm's finer streaks still read as thick white sticks (judge a). The overcast grade "eats the colour" (judge c).
- **Veilfall, all judges, called new_art:**
  - faceted, flat-shaded low-poly cliffs;
  - the fall is a single opaque white ribbon "draped like cloth", with no mist at the base;
  - flat sand-disc islets;
  - none of the board's terraces, greenery, arches or bridges.
- **Shore:**
  - the golden hour is a flat pink-orange wash with no light direction;
  - the NPC is cropped at the bottom edge;
  - the sign overlaps the hotbar.

## What would add the most
1. **Veilfall rebuild (new_art):** a terraced, mossy cliff with layered falls, mist and the board's architecture. This is the single largest drag on F39#30 and F39#31 (3/3).
2. **Dawn band (scene):** remove the black waterline and horizon band at dawn and in rain. It is probably a water-edge or horizon-fog seam, not fog density. Also tame the sun bloom.
