# G-below6-overlook-pane: amber pane, beacon balls and banner cards fixed at the Stormward overlook (LANE-BELOW6; GPU High)

## Verdict: SHIP. Both sets gain, with 3/3 preferring the arm on each, and nothing loses.

| Set | Base | Arm | Gain | Prefer arm | Arm per judge (mapped) |
|---|---|---|---|---|---|
| **Overlook routes** (walk_01, walk_02, route_day) | 4.92 | **5.87** | **+0.95** | 3/3 | 5.65, 5.90, 6.06 |
| Overlook edge and vista (walk_03, vista_dusk) | 5.57 | 5.95 | +0.38 | 3/3 | 5.73, 5.90, 6.22 |

- **Fit caveat.** The anchor residual RMSE is 0.80, above the tool's 0.75 limit. This panel did not rank the anchors like the reference judges: all three marked the f10_2_r3 Stormwood fight sheet far down, because it is a very small contact sheet. The slope is a compressed 0.815.
  - The raw scores carry the same result: routes +1.17 raw, edge and vista +0.47 raw, 3/3 on both.
  - So the paired gain is sound, but the absolute mapped levels should not be pooled into a row score.
- **What the arm fixes (3/3):**
  - **The amber pane.** Base's walk_02 has "a large translucent yellow-orange box over the wall and the trainer, tinting both ... the worst artefact in the batch". The arm shows "a solid, textured wall and no overlay".
  - **The white sphere** next to the trainer is gone (a faint green glint remains).
  - **Banners.** Base's "flat, unshaded slabs of saturated blue and yellow ... placeholder quads" become "notched swallowtail pennants in muted cream and pale blue, a believable cloth read".
  - **The white orbs** on the horizon in route_day and vista_dusk are gone.
- **The GPU lane's caution is confirmed (2/3).** On the arm, "faint see-through vertical panels still hang in the sky above the wall" in walk_02. They are much weaker than base's amber pane, but not gone. Judge a did not name them.
- **walk_03** is unchanged (render difference 0.46), so the edge-and-vista gain is the vista's pennants and orbs.

## What still holds the overlook (3/3)
1. **It reads as Meadows on a cliff.** Flat olive ground with carpet grass, and mossy green-brown brick ruins, where the Cloudreach board asks for "pale stratified stone".
2. **Ruins.** Thin, cardboard-like wall slabs with cut-off ends that overhang or float at the cliff edge. In walk_03 the wall is "oversized, evenly tiled stone with a cartoon outline" at the wrong scale.
3. **Terrain.** A hard polygon crease and a raw brown cut bank in route_day and vista_dusk, and a smeared, stretched texture on the floating rock in walk_01.
4. **The cloud sea** is a flat, visibly repeating texture.
- **Next lever:** remove the remaining translucent sky panels (scene), then pale-stone Sky Aviary ruin pieces (new art, 3/3).

## Rows
- These are the Stormward overlook route frames.
- walk_03 is one of F40#15's job frames, but it is unchanged here, so this batch does not move F40#15.
- The pane and orbs fall under F40#21 (cleanliness) and F40#0 (look) in matrix scope. A matrix re-score would show the gain at the row level.

## Frames
- **Source:** `tb/gpu-frames-1108` section `G-below6-overlook-pane` (75604e127), High, `--fixed-fps 20`, `tb/below6` 4e03b0b23.
  - **base:** `pane_fix_1112` OFF (the overlook config from 4e03b0b23^, which has no pane_fix block).
  - **arm:** branch default, ON.
- **Health:** 0 script errors.
- **Render check (mean difference per frame):** walk_02 18.2, walk_01 6.5, route_day 2.8, vista_dusk 2.5, walk_03 0.5. By eye, walk_02's amber pane and white ball are gone on the arm, with faint pale sheets left at the top and right.
- **Sets:** routes (walk_01, walk_02, route_day) and edge and vista (walk_03, vista_dusk), stacked.

## Batch `G-op`
- Three code-blind judges, standard prompt, two candidate sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 0.815, intercept 1.657, r 0.816, anchor RMSE 0.80 (warning above).
- Yardstick: `yardstick_g_below6_overlook_pane/`.

**Raw Bar A (judges a, b, c):**

| Set | Base | Arm |
|---|---|---|
| Overlook routes | 3.6, 4.0, 4.4 | 4.9, 5.2, 5.4 |
| Overlook edge and vista | 4.5, 4.6, 5.3 | 5.0, 5.2, 5.6 |

Bar B: no on both sets (3/3).
