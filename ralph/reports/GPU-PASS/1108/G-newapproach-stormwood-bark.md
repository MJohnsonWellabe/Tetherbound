# G-newapproach-stormwood-bark: giant-trunk bark detail (F41#22 matrix, F41#24 cleanliness; GPU High)

Frames: `tb/gpu-frames-1108` 05637ec3f, High.
- base = `tb/newapproach` 34bed949f.
- arm = base + `overlay_bark`: world-space tiling bark on storm_canopy `Bark_TwistedTree`, kept matte through light_pass_1101.
- 15 frames per side: forest, giant, glass, rod_line and stormheart, each in calm, break and the aftermath.

Render check (pixels changed by more than 30): forest 43–46%, giant 61–65%, glass 7–9%, rod_line 20%, stormheart 14–18%.

Batch `G-bk`:
- three code-blind judges, standard prompt;
- 3 sheets (forest+giant, glass+rod_line, stormheart), each judged base against arm on the F41#22 matrix brief and on the F41#24 cleanliness brief;
- both briefs ask neutrally whether any surface reads red, salmon or oxblood;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.

Fit: linear, slope 1.4393, intercept −2.3989, r 0.913, anchor RMSE 0.565. No warnings. above_top_anchor false throughout. The judges noticed that each sheet appears under both briefs; that is by design.

## Verdict: SHIP. Every sheet gains on both briefs, 3/3 prefer the arm on all six sets, and no sheet loses.

| Sheet | F41#22 base | F41#22 arm | Gain | F41#24 base | F41#24 arm | Gain | Judges preferring arm |
|---|---|---|---|---|---|---|---|
| forest + giant | 5.57 | **6.76** | **+1.19** | 5.61 | **6.81** | **+1.20** | 3/3, 3/3 |
| glass + rod_line | 6.24 | **6.91** | **+0.67** | 6.33 | **7.05** | **+0.72** | 3/3, 3/3 |
| stormheart | 6.43 | **7.20** | **+0.77** | 6.52 | **7.39** | **+0.87** | 3/3, 3/3 |
| **Mean (these 5 stands)** | 6.08 | **6.96** | **+0.88** | 6.15 | **7.08** | **+0.93** | |

The best result is F41#24 stormheart at **7.39**, the same on all three judges. It is near-bar under the close-out exception, but below 7.5, so there is no Medium yet.

**Scope.** These are 5 of the 10 F41-look stands, without the fight. Against the baseline's same-stand sheets, F41#22 forest + giant moves from about 4.82 (giant) to 6.76, and the matrix-wide row mean should rise accordingly. A full-row re-score needs the arm on forest_r, giant_r, heart_near, hollows and reverse, plus the fight.

**F41#4, F41#5 and F41#17 are not judged here.** Their catalogue frames (lantern_pools, crown_overlook and the fallen_giant close views; the struck_sentinel approach and crown_heartstone; crown_arch) are not in this capture. To credit them, capture those frames on the arm.

## What the judges saw
- **All three:** the base's pale lavender-grey trunks read as "clay", "plaster", "unpainted" or "placeholder material". The arm's brown bark "reads authored" and "sits naturally".
- **Reserved colour: no judge reads the new bark as red, salmon or oxblood.** They call it "brown bark", "dark", and in one judge's words "dark and muddy against the green". That judge suggests lifting the bark value so it separates from the canopy.
- **Reserved-colour flags present on both sides, so not caused by the arm:**
  - a **salmon-pink bear-like creature** at the far left of the forest stand (3/3);
  - the **orange glowing cracks** in the rod_line black pool (1/3, borderline).

## What still keeps the stands short of 7.5
- the storm phases barely differ: no lightning and no shafts, the sky never darkens at break (3/3);
- a uniform cyan-green grass carpet, and a flat grey path strip at stormheart;
- black ground patches read as holes or cut-outs rather than pools;
- background trunks are still pale lavender in some views (another trunk variant without the bark).
