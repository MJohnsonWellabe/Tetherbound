# G-below6-overlook-stone: overlook ruins re-materialed to light cliff stone (F40#15; GPU High)

## Verdict: DO NOT SHIP. Both sets lose with 3/3 preferring base.

| Set | Base | Arm | Gain | Prefer arm | Arm per judge (mapped) |
|---|---|---|---|---|---|
| **F40#15 overlook** (walk_03, vista_dusk) | 4.57 | **3.99** | **−0.58** | 0/3 | 3.78, 4.03, 4.16 |
| Overlook routes (walk_01, walk_02, route_day) | 5.07 | **4.53** | **−0.54** | 0/3 | 4.53, 4.78, 4.28 |

## Why (3/3)
- **The new stone does not read as pale stratified stone.** The arm's walls are "a smeared, low-resolution brown facet texture", "blurry olive-brown blotch with no readable masonry", "uniform orange-brown hammered blotch ... reads as clay, dirt, cork or mud". The judges call it "even further from the pale stratified stone" than base.
  - Base's "dark mossy cobble" is also off-board (it reads as Meadows stone), but it at least "reads as masonry".
  - One judge also flags the arm's towers in vista_dusk turning "reddish-brown, close to an earthy oxblood" (1/3).
- **The texel density is the visible problem.** The faceted stone is stretched across the big wall planes, so at the gameplay camera it blurs to a single flat colour.
- **No loss from anything else.** The ghost planes, the floating walls and the dark seam are on both sides.
- **Next.** The judges' top ask is unchanged from G-below6-overlook-pane: "thick, footed masonry in pale stratified stone with base, cap and trim, no overhangs past the terrain" (new art, 3/3). A material swap on the existing thin wall cards does not get there.

## What every judge flagged on both sides
1. **A dark seam strip across the grass at the trainer's feet** in vista_dusk, with a dark wedge or cobble strip running to the right edge. The judges mark F40#15's strip defect **PRESENT** on both sides (3/3).
   - The earlier F40#15 batches judged the aerie vista (the row's job frame), where the strips are gone. This is the overlook's own vista_dusk, so the strip defect still exists at the overlook.
2. **Translucent ghost planes** in the sky above the wall in walk_02 (3/3). The GPU lane confirms they are on both sides.
3. **Card-thin wall slabs** that overhang the terrain edge with no footing (3/3).
4. **A flat green plateau** with little authored structure.

## Pooled current-main line
- This batch's base reads 4.57 for the overlook F40#15 pair. That pair is not F40#15's job pair: walk_03 is a job frame, but this vista_dusk is the overlook's, not the aerie's.
- F40#15's job-frame current-main read stays ≈ 5.47 (G-below6-stormraven-masonry).

## Frames
- **Source:** `tb/gpu-frames-1108` section `G-below6-overlook-stone` (27fbbacc9), High, `--fixed-fps 20`, `tb/below6` e9dd11ce2 on both sides (pane fix ON for both).
  - **base:** branch as is.
  - **arm:** `BELOW6-OVERLOOK-STONE/overlay.json` (`ruin_material stone_light`).
- **Health:** 0 script errors.
- **Render check:** 2.9–7.4 mean per frame. By eye, the walls go from mossy brick and cobble to a faceted brown stone that reads closer to a dirt cliff than to pale stone.
- **Sets:**
  - F40#15 overlook: walk_03_day and vista_dusk.
  - Routes: walk_01_day, walk_02_day and route_day.
  - Both stacked; F40#15's recorded defect was used.

## Batch `G-os`
- Three code-blind judges, standard prompt, two candidate sets.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22. This is a confirming batch.
- **Fit:** linear, slope 1.242, intercept −1.058, r 0.979, anchor RMSE 0.21.
- **Warning:** "some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)". The scores near 4 sit below the lowest anchor read, but the paired loss holds in raw scores too.
- Yardstick: `yardstick_g_below6_overlook_stone/`.

**Raw Bar A (judges a, b, c):**

| Set | Base | Arm |
|---|---|---|
| F40#15 overlook | 4.4, 4.6, 4.6 | 3.9, 4.1, 4.2 |
| Overlook routes | 5.0, 5.0, 4.8 | 4.5, 4.7, 4.3 |

Bar B: no on both sets (3/3).
