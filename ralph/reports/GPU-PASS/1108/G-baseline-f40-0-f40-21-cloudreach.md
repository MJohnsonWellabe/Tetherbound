# GPU baselines: F40#0 Cloudreach re-capture and F40#21 Cloudreach cleanliness (matrix scope, High)

Frames: `tb/gpu-frames-1108`, 8 sections (bf80caeb8, ad51604e3, 936ebfc1e, d63827595, 51300355c, 086d53fde, 516d532a8, d42d0b457).
- main 2ffc97db0, High, `capture_cloudreach_f40_matrix.gd --ground-cover-cache`.
- **352 of 384 frames: 11 stands × 4 views × 4 times (dawn, day, golden, night) × 2 weathers.** The ≥200-frame floor is met.
- **Missing: the broken_causeways_04 broken_skyroad_arch stand (32 frames).** The tool fails on main with "no grounded, open approach/detail point" (approach, detail) and "debug_teleport_to refused destination" (gameplay, reverse). LANE-MESHY is investigating.

Method: seven one-sided 3×3 sheets, 63 frames in all (list in `yardstick_g_f40m/f40_frames.json`).
- Day, clear: three sheets (approach; gameplay; reverse + detail).
- Dawn, golden hour and night, clear: one sheet each.
- Rain at mixed times: one sheet.
- Each sheet covers 9 of the 11 stands.

Judged twice, with separate judges:
- `G-f40m` on the biome-look brief;
- `G-f40c` on the cleanliness brief, recording the defect "Flat magenta rings or slabs, placeholder materials, floating bodies or clipping remain in the frame".

Both batches: three code-blind judges, standard prompt, anchors craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so both are confirming batches.

| Batch | Fit | Warnings |
|---|---|---|
| F40#0 | slope 1.617, intercept −2.995, r 0.940, RMSE 0.471 | none |
| F40#21 | slope 1.2115, intercept −0.7148, r 0.894, RMSE 0.621 | none |

## Results

| Sheet | F40#0 look | F40#21 cleanliness |
|---|---|---|
| day, approach | **7.14** | **7.16** |
| night, clear | 6.98 | 6.80 |
| day, gameplay | 6.92 | 6.92 |
| day, reverse + detail | 6.92 | 6.76 |
| dawn, clear | 6.38 | 6.47 |
| golden hour, clear | 6.01 | 6.43 |
| rain | **5.74** | 6.23 |
| **Mean** | **6.58** | **6.68** |

- **F40#0 baseline: 6.58.** Every sheet except rain is above 6.
- **F40#21 in matrix scope: 6.68.** The earlier provisional 7.03 was a catalogue-frame sample; this replaces it. The cleanliness defect is PRESENT or PARTIAL on every world sheet from every judge, and no judge marked it FIXED.
- **Red check:** no oxblood leak seen (3/3 on the look batch).

## Defects, worst first (for the floor lane)
1. **Rain grade** (5.74 look):
   - the rain is drawn as long white overlay bars or a "white screen";
   - the overcast is flat grey with no wet sheen or depth fog;
   - the far cliffs fade into the sky;
   - the cobble mound turns a flat grey-blue speckle that reads as a placeholder material.
2. **Golden hour** (6.01 look): a heavy sepia or beige haze flattens the value range, so the sky and cliffs merge and it reads "like a dust storm" (3/3). Keep the sky bright and cut the haze.
3. **Dawn** (6.38): the pink sky is good, but the ground crushes to near-black green with no form (3/3). Lift the ground values or add bounce light.
4. **Placeholder geometry and camera clipping** (named by all three cleanliness judges, across sheets):
   - **flat, untextured dark brown slabs** (a door or wall board) fill the frame centre at the old_wind_observatory stand, close up in its detail view;
   - the **"Rest at cliffhold commons" bed** is a flat cyan and white block clipping the bottom of the frame at cliffhold;
   - **a pink-magenta glow at the left edge** of the first frame in several sheets (and one dawn frame) reads as a stray effect or debug emitter;
   - a flat brown dirt rectangle on the ground;
   - **cameras inside rock, hut edges, or against walls and poles** (reverse/detail sheet), plus trunks pressed against the camera;
   - the cliffhold approach camera at the trainer's shoulder (the GPU lane also noted this);
   - a dark hedge cube;
   - a floating plank prop.
5. **Cobble-boulder mounds** (all sheets): they read as procedural heaps sitting on the grass, not a laid path. They turn **flat lavender or lilac at night**, read as a material bug (3/3).
6. **Missing Cloudreach identity** (look batch, 3/3):
   - no cloud sea below the cliffs, no floating islands or waterfalls, so the biome "reads as Meadows on a plateau";
   - a uniform grass carpet with no groves, edges or clearings;
   - repeated rock stacks and cut-out distant spires.
   This is the biggest single lift across all sheets.

What carries it:
- pale stratified spires;
- the domed aviary landmark;
- blue banners;
- a bright, readable day (approach 7.14);
- the blue night grade with warm window and fire light (6.98).
