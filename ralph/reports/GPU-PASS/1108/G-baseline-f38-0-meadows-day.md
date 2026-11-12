# GPU baseline: F38#0 Meadows re-capture, day part (High)

Frames: `tb/gpu-frames-1108` a1dd4a89, `G-baseline-f38-0-meadows-day`.
- main 2ffc97db0, one side, High.
- `capture_f38_matrix.gd --seed=2042 --f38-preset=High --f38-baseline --times=day`, clear and rain.
- 134/134 frames: 22 sites; approach, gameplay, reverse and detail views.

**Scope.** F38#0 asks for at least 200 frames. This is the day part only (134). The dusk and night parts are still to come, so this is a **partial baseline**.

Method: batch `G-f38d`, seven one-sided 3×2 sheets built from 42 of the 134 frames (list in `yardstick_g_f38d/f38d_frames.json`).
- Five clear-weather sheets: two places each, approach / gameplay / reverse.
- One rain sheet: six places, gameplay camera.
- One detail sheet: six close views.
- Three code-blind judges, standard prompt.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.
- Fit: linear, slope 1.1786, intercept −0.2434, r 0.875, anchor RMSE 0.669. No warnings. above_top_anchor false throughout.

## Result: Meadows day baseline **6.67**. Every sheet is above the 6 floor; one is near the bar.

| Sheet | Mapped (judges) |
|---|---|
| farm_to_hall + band1_lower_meadows_1 | **7.38** (7.54, 7.30, 7.30) |
| village_road + hall_front | **7.06** (7.18, 7.06, 6.95) |
| band4_upper_meadows_ironwood_0 + band5_stronghold_approach_0 | 6.79 |
| detail views (6 places) | 6.55 |
| hall_nave + shrine_room | 6.40 |
| rain, gameplay camera (6 places) | 6.40 |
| band2_stone_and_root_0 + band3_the_river_lock_0 | 6.12 |
| **Mean** | **6.67** |

## Defects, worst first (for the floor lane)
1. **band2 + band3** (6.12; the stone/root band and the river lock):
   - smeared, low-mip ground texture;
   - the camera pressed against a rock face, which fills the right third (3/3);
   - grainy, blurry boulders;
   - pale flat hexagon or grey slabs under boulders that read as placeholders;
   - a bare dirt plain with evenly spaced tufts (generator look);
   - teal tether lines floating between posts;
   - an NPC cropped at the frame edge.
2. **hall_nave + shrine_room** (6.40):
   - the gameplay camera hugs a near-black blue stone wall, which fills half the frame (3/3);
   - the interiors are flat orange-brown corridors;
   - saturated cyan or magenta portal arches read as a different family from the timber village;
   - a bare stone plinth wall;
   - flat exterior grass with an empty horizon;
   - a cyan light pillar in the sky.
3. **Rain** (6.40):
   - the rain reads, but the grade is a flat grey-green with little value range;
   - no fog depth, light shafts or wet sheen (3/3);
   - flat, plasticky blob tree crowns;
   - a creature half-buried in grass.
4. **Detail views** (6.55):
   - a noisy, low-res boulder texture;
   - an off-family cyan cylinder or barrel prop;
   - the camera behind a wooden post, which blocks a third of the frame (3/3);
   - the camera hugging a brick wall;
   - a pale placeholder slab under the bench;
   - a teal rope hanging in the air.
5. **band4 + band5** (6.79):
   - a uniform grass carpet to the horizon;
   - flat, low-detail blob tree crowns, with the forest row a wall of the same tree;
   - a featureless haze distance;
   - the boar cropped at the frame edge.
   The owl reads well.
6. **village_road + hall_front** (7.06, near-bar):
   - a stone wall fills the bottom-middle frame;
   - the pale-stone portal with cyan trim is off-family;
   - the bench sits on a flat quad and floats slightly.
7. **farm_to_hall + band1** (7.38, the strongest; near-bar):
   - cyan quest-beam light pillars over the roofs (3/3);
   - carpet grass and a flat horizon in the lower row;
   - the coyote cropped at the frame edge.

Cross-cutting, named by all three judges:
- uniform grass carpet with a flat, hazeless horizon (break it into groves, edges and clearings, with aerial-perspective fog);
- fixed cameras hugging walls, rocks or posts;
- the cyan quest or light pillars;
- blob tree crowns and noisy rock materials (new art: a hero tree and rock family).

The red banners seen are at Team Tether sites; the judges accepted them.
