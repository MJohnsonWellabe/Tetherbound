# GPU baseline: F38#0 Meadows re-capture, full row (day + golden hour, High)

Frames:
- day: `tb/gpu-frames-1108` a1dd4a893, 134 frames;
- golden hour (the plan's dusk): 96bae1525, 134 frames.

**268 frames in total, so the ≥200 re-capture floor is met.** Both pieces are main 2ffc97db0, High, `capture_f38_matrix.gd --seed=2042 --f38-baseline`, 22 sites, clear and rain, and both pass CATALOGUE SURVEY OK 134/134.

Method: two batches with the same 7-sheet layout (42 frames per piece). Each uses three code-blind judges, the standard prompt and anchors craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so both are confirming batches.

| Batch | Fit | Warnings |
|---|---|---|
| day `G-f38d` | slope 1.1786, intercept −0.2434, r 0.875, RMSE 0.669 | none |
| golden `G-f38g` | slope 1.3914, intercept −1.7385, r 0.923, RMSE 0.533 | none |

Day report: `G-baseline-f38-0-meadows-day.md`.

## Result: F38#0 full-row baseline **6.60** (day 6.67, golden hour 6.54). Every sheet is above 6.

| Sheet | Day | Golden | Row |
|---|---|---|---|
| farm_to_hall + band1_lower_meadows_1 | 7.38 | 6.66 | **7.02** |
| village_road + hall_front | 7.06 | 6.80 | **6.93** |
| band4_upper_meadows_ironwood_0 + band5_stronghold_approach_0 | 6.79 | 6.56 | 6.68 |
| rain, gameplay camera | 6.40 | 6.89 | 6.65 |
| detail views | 6.55 | 6.38 | 6.47 |
| hall_nave + shrine_room | 6.40 | 6.47 | 6.44 |
| band2_stone_and_root_0 + band3_the_river_lock_0 | 6.12 | 6.01 | **6.07** |
| **Mean** | **6.67** | **6.54** | **6.60** |

Golden-hour judges (per sheet, mapped): village 6.89/6.61/6.89; farm 6.47/6.61/6.89; rain 7.17/6.75/6.75; detail 6.33/6.33/6.47; hall 6.33/6.19/6.89; band4+5 6.61/6.33/6.75; band2+3 5.91/5.91/6.19.

## Defects, worst first (updated with golden hour)
1. **band2 + band3** (6.07; lowest at both times):
   - the camera is occluded by a rock or trunk filling a third of the frame (both pieces, 3/3);
   - smeared or low-mip ground;
   - grainy, noisy boulders;
   - grey or hexagonal flat slabs under rocks;
   - bare dirt with evenly spaced tufts;
   - a crude orange plank cart that reads as a placeholder (golden, 2/3).
2. **hall_nave + shrine_room** (6.44):
   - the camera hugs a dark blue stone wall, which fills a third to a half of the frame;
   - a plain, repeating stone foundation block fills the reverse view;
   - a stone block floats above the grass with no contact shadow (golden, 1/3);
   - saturated orange interiors with neon cyan, blue or purple portal and door rims read as a collage, not the timber village (both pieces).
3. **Detail views** (6.47):
   - an untextured cyan cylinder or barrel (both pieces, 3/3);
   - a noisy, photo-textured boulder;
   - a teal rope floating in the air;
   - the camera behind a post (day).
   - **New at golden hour:** a dark red curtain in the foreground fills the right third of the `arch_home` detail view (3/3). That is both camera occlusion and possible oxblood: **check whether it is a Team Tether element.**
4. **Golden-hour grade** (named 3/3, across the open sheets):
   - the sky is a flat pink-beige haze with no cool blue distance;
   - the grass is one dark olive mid-tone carpet, so the value range is compressed.
   The key art asks for warm grass with a cool blue distance. Regrade with a warm key, a blue aerial gradient and lifted grass value.
5. **Uniform grass carpet and flat horizon** (both pieces, every judge):
   - no groves, edges or clearings;
   - trees spaced evenly in rows on ridges;
   - blob tree crowns.
6. **Red banner or curtain at the cage caravan** in the rain sheet (`band3_the_river_lock_0`): 2 of 3 golden judges flag it as possible oxblood outside a clear Team Tether context. Day judges took it as a Tether camp. **Worth confirming.**
7. **Near-bar sheets (≥6.9 on the row): cheap wins.**
   - the cyan quest or light-beam pillars over the roofs (read as debug markers, both pieces);
   - wall-filling reverse frames, such as the building edge on the village road at golden hour;
   - cropped creatures (coyote, boar);
   - the bench sitting on a flat quad.

What carries it:
- the village houses and the hall family;
- creatures: the owl, and the bark-plated hare in rain, which is "the best subject in the batch";
- the rain mood (golden rain 6.89).
