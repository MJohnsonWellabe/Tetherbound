# G-things-faint: LANE-THINGS faint-grounding arm (T1), GPU High

**Frames:** `tb/gpu-frames-1108` c7479c87e, High.
- Capture: `capture_f36_poses.gd --game-clips --clear-ruler --roles=hit,faint` on `tb/things` 5cb2084c3, both sides.
- **base:** overlay off.
- **arm:** base plus `THINGS-FAINT/overlay_faint_ground.json`.
- **basenoswitch:** base without the entry's two new switches (water_mirejaw and water_abyssal_guardian only).
- Blank frames: 0 of 100, 0 of 100 and 0 of 20.

**Sets:**
- Crop 560,200 1000×640. Tiles: standing (hit 000), hit 050, faint 050, faint 100.
- Brief: the F36 (1) brief.
- Recorded defects: each row's roster cause, plus "the faint does not reach the ground (body, neck or head stays raised, sits upright or floats)".

**Render check, arm vs base:**
- 2.5–4.9% of pixels changed per sheet on 8 rows.
- **Water abyssal guardian and water mangrove monitor: 0.0%.** The arm equals base, because they are excluded from the overlay. Those two pairs were not judged.
  - Water abyssal guardian is judged as basenoswitch vs base instead.
  - Water mangrove monitor still needs a one-sided re-score; it is queued.

**Batches:** G-fa and G-fb, three fresh code-blind judges each, standard prompt. Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22. Both are confirming batches.
- **G-fa fit:** slope 1.407, intercept −1.9797, r 0.974, RMSE 0.224.
- **G-fb fit:** slope 1.2663, intercept −0.8869, r 0.952, RMSE 0.306.
- No warnings.

## (1) Arm vs base: SHIPS on 7 of 8 judged rows; fulgocobra level

| Row | Base | Arm | Gain | Prefer arm | Faint defect (base → arm) |
|---|---|---|---|---|---|
| **F36#42 Cragclaw** | 6.84 | **7.51** | +0.67 | 3/3 | FIXED → FIXED (the arm's tucked shell reads better than base's "tumbled toy" roll, 3/3) |
| **F36#93 Water Mirejaw** | 6.37 | **7.39** | +1.02 | 3/3 | PRESENT/PARTIAL → FIXED 3/3 |
| F36#91 Water Cragclaw | 5.43 | 6.51 | +1.08 | 3/3 | PRESENT 3/3 → FIXED, FIXED, PARTIAL |
| F36#30 Abyssal Guardian | 5.62 | 6.56 | +0.94 | 3/3 | PRESENT 3/3 → FIXED 3/3 |
| F36#50 Mangrove Monitor | 6.51 | 6.98 | +0.47 | 3/3 | PARTIAL/FIXED → FIXED 3/3; tail clear of the trainer |
| F36#38 Cannonback | 6.74 | 7.07 | +0.33 | 3/3 | FIXED → FIXED (base rolls "as one rigid piece") |
| F36#52 Mirejaw | 6.70 | 6.98 | +0.28 | 2/3 (1 level) | FIXED → FIXED |
| F36#46 Fulgocobra | 5.87 | 5.82 | −0.05 | 0/3 (2 level) | PRESENT/PARTIAL on both: "hood stays raised" |

- **The ship rule passes on every row except fulgocobra.** There the arm does nothing visible: −0.05, two judges level and one preferring base, which is within noise.
- **Recommendation:** land the overlay, and drop fulgocobra from it (or leave it; it neither helps nor hurts) until its hood or neck clip is fixed.
- **Cragclaw at High (7.51) meets the bar.** Capture Medium. It closes if Medium is 7.5 or above.
- **Close-out candidates:** water mirejaw 7.39 and cannonback 7.07.

## (2) Base side as the corrected re-score for the water rows (game-resolved clip)

| Row | Earlier (raw clip) | Base, game clip | Arm |
|---|---|---|---|
| F36#93 Water Mirejaw | 5.52 | **6.37** | 7.39 |
| F36#88 Water Abyssal Guardian | 5.85 | **6.32** | (= base) |
| F36#91 Water Cragclaw | 6.92 | **5.43** | 6.51 |
| F36#92 Water Mangrove Monitor | 6.26 | not judged (arm = base); one-sided re-score queued | (= base) |

- **Water cragclaw falls on the game clip.** Its faint "still stands on raised legs with the shell up" (3/3 on base), so the arm is what lifts it.

## (3) basenoswitch vs base: the stage fix alone

| Row | basenoswitch | base | Stage-fix gain | Prefer base |
|---|---|---|---|---|
| Water Mirejaw | 4.77 | 6.37 | **+1.60** | 3/3; noswitch is a "belly-to-camera, on-edge, floating" faint |
| Water Abyssal Guardian | 5.62 | 6.32 | **+0.70** | 3/3; noswitch "sits bolt upright like a seal" |

## Still named on the arm side
- **Mirejaw, both forms:** a translucent grey smear on the tail or jaw in the hit frame (3/3 in G-fa), which looks like a skinning or material artefact.
- **Fulgocobra:**
  - The hood stays flared and the neck arcs up in the faint (3/3).
  - The near-black body sinks into the stage.
  - The copper-brown neck plates sit near the reserved red (3/3). They read as copper, not oxblood, but are worth moving toward gold.
- **Abyssal guardian:** glossy vinyl-blue skin, toy-like (PRESENT 3/3). This is a material issue, for REMAKES.
- **Cannonback:** the cannons still read as bolted on (PARTIAL 3/3). Its cyan cracks run onto the head and legs and approach "glowing seams" (judge a).
- **Water cragclaw:** the arm's faint end "melts" into a heap with smeared legs (2/3).
