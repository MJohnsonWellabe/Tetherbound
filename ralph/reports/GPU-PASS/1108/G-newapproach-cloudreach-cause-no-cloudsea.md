# G-newapproach-cloudreach-cause-no-cloudsea: pale_strata + light_grade + meadow_groves, cloud_sea off (F40#1, F40#3, F40#8, F40#9, F40#0; GPU High)

Frames: `tb/gpu-frames-1108` 8bb3ffbfd, High, seed 2042, 117 per side.
- base = `tb/newapproach` 186b3e534.
- arm = base + `cloudreach_cause_no_cloudsea.json`: master off; pale_strata (route_boulders false), light_grade and meadow_groves on; cloud_sea off.

Sheets, base against arm (frame lists in `yardstick_g_cc/frames.json`):

| Row | Sheet |
|---|---|
| F40#1 | 6 destination approach views |
| F40#3 | 3 landmarks, approach and close |
| F40#8 | three_bells_bridge close at day, golden and night |
| F40#9 | 3 NPCs, portrait and dialogue |
| F40#0 | 9 matrix frames (3 stands × day approach/gameplay, plus golden, night and rain) |

Render check: 5–54% of pixels changed (largest on the observatory and realm-gate locations).

Batch `G-cc`:
- three code-blind judges, standard prompt, each row on its own catalogue brief;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.

Fit: linear, slope 0.9756, intercept 0.7024, r 0.865, anchor RMSE 0.693. No warnings.

## Verdict: DO NOT SHIP. Two rows lose 0/3, one row loses 1/3, and no row gains meaningfully.

| Row | Base | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| F40#1 open terrain | 6.04 | 5.91 | **−0.13** | **0/3** |
| F40#3 landmark read | 6.13 | 5.97 | **−0.16** | **0/3** |
| F40#0 matrix sample | 6.75 | 6.65 | −0.10 | 1/3 |
| F40#8 route markers | 6.13 | 6.17 | +0.04 | 1/3 (1 tie) |
| F40#9 NPC posts | 6.30 | 6.36 | +0.06 | 2/3 (1 tie) |

Raw Bar A, base → arm (judges a, b, c):
- F40#1: 5.3, 5.6, 5.5 → 5.2, 5.5, 5.3.
- F40#3: 5.5, 5.7, 5.5 → 5.3, 5.6, 5.3.
- F40#0: 6.2, 6.1, 6.3 → 6.3, 6.0, 6.0.
- F40#8: 5.6, 5.7, 5.4 → 5.5, 5.7, 5.6.
- F40#9: 5.7, 5.8, 5.7 → 5.8, 5.8, 5.8.

**Scale note.** This batch maps the base for these rows near or above 6 (6.04–6.13), against their 8 Nov one-sided scores of 5.65–5.90. Read the paired gain, not the level, as the verdict. The level difference is the scale scatter noted in `ROW-AUDIT-1111.md`.

## Which part is harmful
1. **pale_strata (the soil rims and island cut faces): harmful. Drop it.**
   - On F40#1 and F40#3, all three judges single out the arm's plateau lips and island cut faces as "a smooth, untextured clay-like lip", "flat tan with no strata", or "a placeholder disc".
   - The base's same faces "carry a textured earth material, slightly better".
   - This is the GPU lane's own pre-check note (flat tan soil rims) confirmed, and it drives both 0/3 losses.
2. **light_grade (distance haze): mildly harmful on the matrix.**
   - Judge c on F40#0: the arm's "distant stacks [are] washed toward white, so depth reads less well and contrast is lower".
   - Judges a and b found the arm's aerial perspective slightly stronger.
   - Net −0.10. Keep the warmer key if wanted, but reduce the haze on far shelves.
3. **meadow_groves: no visible effect at judging scale.** No judge mentioned groves on either side. Neither help nor harm.
4. **F40#8 and F40#9 are flat**, as expected: the arm does not touch the cyan beam or the NPC staging.

## What the judges still name on every Cloudreach set (both sides)
- **Terrain:** flat lawn discs and evenly scattered rubble carpets; no stepped ledges. The judges call this new_art or a terrain re-stage.
- **Landmarks:** plain stacked-slab pillars and small gates; nothing of the aviary dome, arcades or bridges.
- **F40#8:** a saturated cyan beam at the bridge, the brightest thing at night, and a foreground trunk filling about a third of each frame. The yellow pointer is not visible in these frames.
- **F40#9:** NPCs tiny or hidden behind the trainer or trunks in the wide shots; the portraits and dialogue are clean.
- **Night:** a flat saturated teal with no moonlit value range.
