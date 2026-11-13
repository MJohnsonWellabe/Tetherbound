# G-things-bedroomwood: calmer loft floor wood (F38#19; GPU High)

## Verdict: SHIP. F38#19 gains +0.51 (3/3), and the three menu rows are identical per judge. F38#19 does not close: High reads 7.15. Medium is not needed this round, because High is under 7.5.

| Row | Set | Base | Arm | Gain | Prefer arm | Arm per judge (mapped) |
|---|---|---|---|---|---|---|
| **F38#19** | exploration HUD in the loft | 6.64 | **7.15** | **+0.51** | 3/3 | 6.95, 7.46, 7.05 |
| F38#9 (no-loss) | backpack, build and creatures menus | 7.12 | 7.12 | 0.00 | identical | 6.95, 7.26, 7.15 |
| F38#4 (no-loss) | map | 6.91 | 6.91 | 0.00 | identical | 6.64, 7.05, 7.05 |
| F38#10 (no-loss) | build panel | 7.33 | 7.33 | 0.00 | identical | 7.05, 7.46, 7.46 |
| control F38#38 | High / Medium | 7.67 | 7.67 | | identical | |

- **Control.** F38#38 read 7.67 against its closing 8.16/8.30, so this panel is about 0.5 strict. F38#19's earlier 7.17/7.17 came from a panel whose control read 7.70 (G-closeout-meadows-ui), so the two are comparable.
- **Fit.** This batch's fit is looser than usual: slope 1.03, r 0.912, anchor RMSE 0.41.

## Why F38#19 gains (3/3)
- **The base reads as an overcooked orange cast.** "A heavy orange-brown grade that floods the walls and floor and kills the cream plaster's value range" (judge b). "The whole room is overcooked orange-amber" (judge a).
- **The arm reads as natural light.** "More neutral warm morning light, with plaster reading as plaster" (judge a). None of the judges name the floor itself: they read the base floor's orange as a grade over the whole room.
- **Recorded defect: PARTIAL on both sides (3/3).** The HUD is "compact" and "tidier than the recorded defect describes". The quest card, minimap and hint row still cluster in the upper and middle right over the room, and the empty "+" quick slots add noise.
- **What still holds it under 7.5:**
  - the right-hand HUD cluster over the scene (3/3);
  - a smeared wood texture on the ceiling (1/3).

## No-loss rows
- The menus are identical per judge. The darker wood at their edges does not register.
- The judges' remaining asks:
  - F38#9: hierarchy in the charcoal panel bodies, and a lit backdrop behind the creature preview.
  - F38#4: about 70% of the map canvas is still blank fogged parchment.
  - F38#10: Quests and Players are not shown in this capture, so the Build panel alone is judged PARTIAL.

## Frames
- **Source:** `tb/gpu-frames-1108` section `G-things-bedroomwood-high` (21fa0dc6a), `tb/things` 44f0847bd, High, `phase2_capture_ui.gd` (Meadows).
  - **base:** branch as is.
  - **arm:** `overlay_bedroom_wood.json`, farmhouse_shell interior_floor_material.tint #c9b49b → #7f8a92.
- **Render difference:** 9.7 on the loft frame, 1.5–2.4 on the menus. 0 script errors, 0 blank frames.
- **Sets:**
  - F38#19 exploration_hud, single.
  - F38#9 backpack, build and creatures in a 2×2 grid.
  - F38#4 map and F38#10 build, single.
  - F38#38's closing crafting frames as control.
  - F38-34 system__building (outdoors, unaffected) was left out.
  - Recorded defects come from job.json.

## Batch `G-bw`
- Three code-blind judges, standard prompt, five candidate sets.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22. This is a confirming batch.
- **Fit:** linear, slope 1.033, intercept 0.439, r 0.912, anchor RMSE 0.41.
- **Warning:** "meets the bar only above the top anchor (7.53)" for the F38#38 control only. This batch's anchors reach 7.35 or more, so it is the confirming batch.
- Yardstick: `yardstick_g_things_bedroomwood/`.

**Raw Bar A (judges a, b, c):**

| Set | Base | Arm |
|---|---|---|
| F38#19 | 5.6, 6.3, 6.1 | 6.3, 6.8, 6.4 |
| F38#9 | 6.3, 6.6, 6.5 | 6.3, 6.6, 6.5 |
| F38#4 | 6.0, 6.4, 6.4 | 6.0, 6.4, 6.4 |
| F38#10 | 6.4, 6.8, 6.8 | 6.4, 6.8, 6.8 |
| F38#38 | 7.0, 7.0, 7.0 | 7.0, 7.0, 7.0 |

Bar B: no on F38#19 (3/3).
