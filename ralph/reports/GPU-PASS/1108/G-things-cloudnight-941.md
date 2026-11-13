# G-things-cloudnight-941: moonlit night fill in place of the cobalt wash (F40#0, F40#19, F40#21; GPU High)

## Verdict: DO NOT SHIP as one arm. The 9-stand night clear sets gain (3/3), but the other three stands lose 3/3, and night rain and the rain sky are level.

| Set | Base | Arm | Gain | Prefer arm | Arm per judge (mapped) |
|---|---|---|---|---|---|
| **F40#0 night clear** (9 places, gameplay) | 6.29 | **6.72** | **+0.43** | 3/3 | 6.76, 6.76, 6.64 |
| **F40#21 night clear** (9 places, approach) | 6.18 | **6.56** | **+0.38** | 3/3 | 6.64, 6.41, 6.64 |
| F40#0 night rain (9 places, gameplay) | 6.25 | 6.29 | +0.04 | 2/3 | 6.41, 6.29, 6.18 |
| F40#19 night rain sky (gate crag, 4 views) | 6.18 | 6.14 | −0.04 | 0/3 (2 ties) | 6.18, 6.18, 6.06 |
| **Night other stands** (Three Bells, Windscar Beacon, Flight Aerie; clear and rain) | **6.48** | 6.18 | **−0.30** | 0/3 | 6.29, 6.06, 6.18 |

## Why
- **On the nine main stands the arm wins on night clear.** All three judges prefer it, and the base's look is the problem: "a murky teal-green / teal-grey cast that muddies the grass" and "flattens everything into one mid-tone" (3/3). The arm reads as "vivid ... readable pale stone and a lit aviary dome" (3/3), though "more dusk than night" (3/3).
- **F40#21 cleanliness also gains.** The base's campfire bloom blows the trainer out to "near-white" at Cliffhold (3/3). The arm "controls the campfire bloom", which is the trainer emission floor 0.5 → 0.15 working. Neither side has magenta rings or slabs (FIXED 2/3, PARTIAL 1/3 for the flat grass-topped plinth sides).
- **On the other three stands the arm loses.** All three judges prefer the base's "cool blue night grade that reads as night"; the arm is "greener and flatter ... reads closer to dim daytime" (3/3). By measurement the arm's grid is greener there (mean G 82 → 92 with B level), so the paler fill lifts already-green grass toward day instead of toward moonlight.
- **Rain barely moves.** Night rain and the gate crag sky read as near-identical on both sides (3/3): bright lime grass under a flat grey slab sky. The ground L 72 → 81 lift does not register.
- **Rule.** A judged set loses 3/3, so the arm does not ship as it stands. The win on the nine stands is real, and the loss is specific, so this is a fix, not a park.

## Next (from the judges, 3/3)
- **Keep the emission floor and rim cut** (they carry the F40#21 bloom fix) and **give the moonlit fill a cool tint and lower grass saturation and value at night**, so the grass "sits under the sky grade" instead of going greener. That targets both the base's teal mud and the arm's daytime green.
- Top asks beyond the grade: break up the flat grass carpet into groves, edges and outcrops (scene, 3/3); give the night and storm skies cloud layers, a moon rim and height fog (scene, 3/3).

## Other shared defects (both sides)
- The High Perches court shows its paving on both sides (the #941 fix holds; the plaza confound from G-things-cloudrain-r2 is gone).
- The creature at the High Perches still differs (a pale winged creature on one side, a dark blue one on the other); the judges note it in the rain set, where the dark one "sinks into the background" (3/3).
- Uniform green grass carpet, blank close wall views, an over-saturated smeared orange path, a blobby blue rock pile at Galefoot (3/3).

## Pooled current-main lines (night, High)
- **F40#0 night clear:** 6.29 (this base, the first night-clear GPU read).
- **F40#0 night rain:** 6.55 (cloudrain), 7.00 (cloudrain-r2) and 6.25 (this base), ≈ 6.60.
- **F40#21 night clear:** 6.18 (this base). The rain line stays ≈ 6.47.
- **F40#19:** this batch's night-rain sky is 6.18. That is a night view, unlike the day-rain set the earlier lines used (≈ 6.54).

## Frames
- **Source:** `tb/gpu-frames-1108` section `G-things-cloudnight-941` (eef5b8efa), High, on both sides a local-only merge 7fef52f5c (`tb/things` 3c242a6a6 + main 317b3372f, with #941's High Perches court fix; creature_coat_flags resolved to main).
  - **base:** no overlay.
  - **arm:** `overlay_night_moonlit_cast.json` (`time_override_arms.night_moonlit_cast_1112`: paler moonlit fill, character emission floor 0.5 → 0.15, playable rim 1.0 → 0.3).
- **Capture:** one 1-96 boot per side, camera spring 5.2 m on every frame, 0 script errors. 96 frames per side.
- **Render check:** 7.8–14.6 mean difference per frame. By eye the arm drops the blue cast for a paler grey-green fill; the court is paved on both sides.
- **Sets:**
  - The nine stands of G-things-cloudrain in 3×3 grids: gameplay night clear and night rain for F40#0, approach night clear for F40#21.
  - realm_gate_crag's four night-rain views for F40#19.
  - The other three stands, gameplay, clear top row and rain bottom row, as the no-loss set.
- I checked the key against the judge tiles' colour means: Yj (night clear) has the arm on the left and Ii (other stands) has the base on the left, as the key says.

## Batch `G-cn`
- Three code-blind judges, standard prompt, five candidate sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.159, intercept −0.196, r 0.874, anchor RMSE 0.67. No warnings.
- Yardstick: `yardstick_g_things_cloudnight_941/`.

**Raw Bar A (judges a, b, c):**

| Set | Base | Arm |
|---|---|---|
| F40#0 night clear | 5.7, 5.5, 5.6 | 6.0, 6.0, 5.9 |
| F40#21 night clear | 5.6, 5.3, 5.6 | 5.9, 5.7, 5.9 |
| F40#0 night rain | 5.6, 5.5, 5.6 | 5.7, 5.6, 5.5 |
| F40#19 night rain sky | 5.5, 5.5, 5.5 | 5.5, 5.5, 5.4 |
| Night other stands | 5.9, 5.8, 5.6 | 5.6, 5.4, 5.5 |

Bar B: no on every set (3/3).
