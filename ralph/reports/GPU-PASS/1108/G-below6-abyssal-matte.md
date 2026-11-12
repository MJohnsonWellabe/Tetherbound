# G-below6-abyssal-matte: matte hide for both Abyssal Guardians (F36#30, F36#88; GPU High)

**Frames:** `tb/gpu-frames-1108` 420ed4abc, High, tree `tb/below6` bc8623efc.
- **base:** flags off.
- **arm:** `BELOW6-ABYSSAL/overlay.json`, with `remakes_floor_abyssal_guardian` on: matte slate hide, grey-cream belly, roughness 0.86.
- Hit and faint only; main's stage, without `--game-clips`. Blank frames: 0 of 20 per side.

**Sets:** one per form, base vs arm.
- Crop 560,200 1000×640. Tiles: standing, hit 050, faint 050, faint 100.
- Brief: F36 (1). Recorded defect: "glossy vinyl, toy-like".

**Render check:** pixels changed: land 1.6%, water 0.4%.

**Batch `G-am`:**
- Three code-blind judges, standard prompt.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22. This is a confirming batch.
- **Fit:** slope 1.3669, intercept −1.658, r 0.967, RMSE 0.254. No warnings.
- **Process note:** judge b used Bash once to crop images, which the prompt does not allow. It states it never opened the crops and scored from the original set images. The crops were deleted, and the scores are kept.

## Verdict: the land form SHIPS; the water form is LEVEL (no change, does not lose), so split the landing

| Row | Base | Arm | Gain | Prefer arm | Raw base → arm (a, b, c) | "glossy vinyl" (base → arm) |
|---|---|---|---|---|---|---|
| **F36#30 Abyssal Guardian (land)** | 5.22 | **5.77** | **+0.55** | 3/3 | 5.0, 5.1, 5.0 → 5.3, 5.6, 5.4 | PRESENT 3/3 → PARTIAL 3/3 |
| F36#88 Water Abyssal Guardian | 4.81 | 4.81 | 0.00 | 0/3 (3 level) | 4.6, 4.8, 4.8 → identical | PRESENT 3/3 → PRESENT 3/3 |

**Land form:**
- The arm is "lighter, more matte slate-blue with softer highlights", and the vinyl look is reduced (3/3). Base is "deeper saturated cobalt with strong specular gloss".
- The gain clears 0.5, so it can land on its own.
- The row stays below 6, so it stays with LANE-BELOW6.

**Water form:**
- Base and arm are "practically identical" (3/3), matching the 0.4% pixel change.
- It neither gains nor loses, so it can land with the land form or be dropped. It does nothing for #88.
- Its base here (4.81) is below the game-clip re-score (6.32 in `G-things-faint.md`). This capture uses main's stage without `--game-clips`.

## What still holds both forms down (3/3)
**Faint does not read:**
- Land: "the body never goes down"; the head droops but it stays standing on its legs.
- Water: faint end "sits bolt upright on its tail with its neck raised".
- The THINGS-FAINT overlay grounded the land form's faint (`G-things-faint.md`, +0.94). Combining the two arms should stack.

**Hit reaction:** almost identical to standing.

**Material and identity:**
- Smooth skin with no scale or hide detail. The water form still reads as "an inflatable toy".
- The model does not match the board's dark, armoured Abyssal Guardian.
- All three judges ask for a Meshy remake as one naturalistic armoured sea serpent with matte scaled skin and restrained aqua markings (new_art).

**Land form's legs:** blade or flipper legs read odd for a walking animal (2/3).

**Owner rules:**
- No red.
- Both forms are taller than the trainer.
- Cyan veins on the land form read as a fitting single elemental trait (3/3).

## Recommendation
1. **Land the matte arm for #30 together with THINGS-FAINT,** and re-judge the combined state.
2. **For #88 the material lever is spent.** Water form at 0.00 is the first attempt that made no visible difference. Move it to a remake (LANE-MESHY), plus the faint fix.
