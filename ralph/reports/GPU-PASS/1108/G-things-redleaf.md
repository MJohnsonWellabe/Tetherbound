# G-things-redleaf: red-leaf fix (#930) two-tree confirm, no-red check, and F38#30 / F38#24 scores (GPU High)

## Verdict: the no-red check PASSES, and #930 is confirmed on main. Nothing loses except one confounded frame.
- **The crimson leaves are gone on main, and the warrens views gain.** All three judges name the red bushes on base only.
- **F38#30 and F38#24 do not move:** the fix is leaf colour, not those rows' subjects.
- **The one loss is the arm's tan mountains in the stronghold route_day frame.** That is the backdrop load or LOD confound the GPU lane flagged, not the fix. Re-shoot that one frame.

| Set | Base (f5263ebc7) | Arm (511dba55d) | Gain | Prefer arm |
|---|---|---|---|---|
| **No-red: Burrow Warrens other views** (route_day, walk_01, vista_dusk) | 5.43 | **6.41** | **+0.98** | 3/3 |
| **F38#30** Burrow Warrens hillside (walk_02, walk_03) | 4.89 | 4.99 | +0.10 | 2/3 (1 tie) |
| **F38#24** distant mountains, walk frames (walk_02, walk_03) | 5.87 | 5.87 | 0.00 | 1/3 (1 for base, 1 tie) |
| F38#24 distant mountains, stronghold route_day (**confounded**) | **7.73** | 5.14 | −2.59 | 0/3 |
| No-loss: stronghold other views (walk_01–03, vista_dusk) | 6.80 | 6.75 | −0.05 | 1/3 (1 for base, 1 tie): level |

## No-red check
- **Base: red outside Team Tether (3/3).** All three judges independently flag it:
  - "saturated crimson or oxblood bushes" beside the warren mouth in walk_01, route_day and vista_dusk, called "Team Tether red leaking onto friendly foliage";
  - an orange-red bush or tree behind the badgers in walk_03, in both the F38#30 and F38#24 sets.
- **Arm:** no judge finds red outside the stronghold.
- **The stronghold's red banners are on the Team Tether stronghold:** correct (3/3).
- This matches the GPU lane's crimson pixel counts (route_day 6645 → 2166, walk_01 12018 → 2069, and so on). By eye, the walk_03 red tree is green on the arm.

## F38#24 mountains
- **Walk frames (the two job frames that are unconfounded):** the facets and slashes are FIXED on both sides (2/3), PARTIAL for the third.
  - The mountains are "small simple blue cones" visible only in walk_03, and absent from walk_02's frame (3/3).
  - Level at 5.87.
- **Stronghold route_day (third job frame), base:** "blue-grey snow-capped ridges with atmospheric fade", FIXED (3/3). It scores **7.73** mapped (7.0 raw from every judge).
  - That is above the top anchor, but this batch has anchors at 7.35 and above, so it confirms.
  - This one frame is at the bar on base.
- **The arm's route_day** is "a flat tan-orange sheet, reads as desert" (3/3), so it scores 5.14.
  - The game clock is identical, the other nine frames match, and #930 only touches `harvest_node.gd`. So this is a backdrop state in that boot, not the change.
- **The same tan sheet also appears in both sides' stronghold vista_dusk** ("flat tan haze swallows the mountains", 3/3).
  - So the tan backdrop is a state the game reaches on main, not only in the arm's one boot.
  - It is worth a look by whoever owns the far backdrop: it costs F38#24 wherever it appears.
- **Current-main F38#24 read over its job frames,** using base's clean route_day: (5.87 × 2 + 7.73) / 3 ≈ **6.49**. A re-shot arm route_day would confirm it on the post-#930 tree.

## F38#30 hillside
- The recorded defect is PRESENT on both sides (3/3): "a straight-edged slab with a ruler-straight lower edge and a dark cut", and a smeared low-resolution grass texture.
- Current main: 4.99.
- The judges' ask is new art: a sculpted, broken hillside with rock outcrops and edge vegetation.

## Other shared defects (3/3, both sides)
- A solid white vertical "smoke" column stands over the burrow mouth and reads as geometry.
- Pale-blue leaf or paper quads float on the warrens slope (2/3).
- The dusk grade is flat olive-brown at the warrens and flat tan at the stronghold.
- Spawn differences, which are not the arm:
  - in walk_03, base has a second badger and the arm has a dark brown creature;
  - in stronghold walk_01 and walk_02, base has plated badgers by the trainer and the arm has none.

## Frames
- **Source:** `tb/gpu-frames-1108` section `G-things-redleaf` (4dfcb2c20), High, two-tree confirm, no overlay.
  - **base:** main f5263ebc7, before #930.
  - **arm:** main 511dba55d, after #930.
  - Routes boot over burrow_warrens and stronghold_approach, 10 frames per side, 0 script errors.
- **Render check:** mean difference per frame is 4.0–9.0 at the warrens and 7.0–13.0 at the stronghold, where the spawns and the route_day backdrop differ. By eye, the walk_03 red tree is green on the arm, and the arm's route_day mountains are tan.
- **Sets:**
  - F38#30: walk_02 and walk_03.
  - F38#24 walk: the same two frames, with the mountain brief.
  - F38#24 route: route_day.
  - Warrens other: three frames.
  - Stronghold other: four frames.

## Batch `G-rl`
- Three code-blind judges, standard prompt, five candidate sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.467, intercept −2.542, r 0.968, anchor RMSE 0.35.
- **Warning:** "meets the bar only above the top anchor (7.53): G F38#24 route [base]; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch."
- Yardstick: `yardstick_g_things_redleaf/`.

**Raw Bar A (judges a, b, c):**

| Set | Base | Arm |
|---|---|---|
| Warrens other | 5.7, 5.5, 5.1 | 6.3, 6.2, 5.8 |
| F38#30 | 5.0, 5.3, 4.9 | 5.0, 5.4, 5.0 |
| F38#24 walk | 5.9, 5.6, 5.7 | 6.0, 5.6, 5.6 |
| F38#24 route | 7.0, 7.0, 7.0 | 4.8, 5.3, 5.6 |
| Stronghold other | 6.6, 6.2, 6.3 | 6.3, 6.4, 6.3 |

Bar B: yes on base's F38#24 route (3/3); no on every other set.
