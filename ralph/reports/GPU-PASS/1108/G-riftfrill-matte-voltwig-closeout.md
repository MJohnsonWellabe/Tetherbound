# G-riftfrill-matte-voltwig-closeout: Riftfrill matte coat (F36#62) and the Voltwig Medium close call (F36#87) (GPU High and Medium)

## Verdicts
- **Riftfrill matte: DO NOT SHIP.** Level, and the judges see no difference.
- **Voltwig (F36#87): does not close.** It is 7.27 on both presets.

| Row | Set | Base | Arm | Gain | Prefer arm |
|---|---|---|---|---|---|
| **F36#62 Riftfrill** | matte coat (High) | 6.52 | 6.52 | 0.00 | identical per judge |

| Row | Panel | High | Medium | Control F38#38 |
|---|---|---|---|---|
| **F36#87 Voltwig** | G-things-bandfaint (base, High only) | 7.51 | — | — |
| | **This batch** (High and Medium side by side) | 7.27 (7.60, 7.10, 7.10) | 7.27 (7.60, 7.10, 7.10) | 8.10 |
| | **Pooled** | 7.39 | 7.27 | |

- **Control.** F38#38 read 8.10 against its closing 8.16/8.30, so this panel is about 0.1 strict.
- **Confirming batch.** Neither row is above the top anchor.
- **Fit:** linear, slope 1.250, intercept −0.903, r 0.974, anchor RMSE 0.22.

## Riftfrill matte (F36#62)
- **The change does not register.** All three judges see the sides as "practically identical" (render difference about 0.2).
- **The sheen is still read (3/3).** The "glossy dark purple" recorded defect is PRESENT for 2/3 and PARTIAL for 1/3 on both sides: "large shiny violet patches on a dark navy body look plastic". Metallic 0 and roughness 0.88 did not take the gloss off the purple patches.
  - The patches are probably texture or albedo highlights rather than specular. The next lever is the albedo itself: re-material to "matte navy skin with natural violet markings and glowing spots" (judge a).
- **"Back below the trainer's head" is FIXED or PARTIAL.** The back clears the head when standing; the faint-end mound sits at about head height (1/3).
- **Other defects, both sides:**
  - small floating marks above the head in the standing and hit frames (3/3);
  - the faint end turns into a legless mound that "seems to sink into the floor" (2/3);
  - faint mid stays an upright crouch (1/3).
- **Current-main read:** 6.52 here, against the board's 7.31. This panel scored the row lower than the creature close-out panels, even with a near-neutral control.

## Voltwig close call (F36#87)
- **The judges score High and Medium identically.** Render difference 0.12–0.14: the pose stage barely changes between presets.
- **Below the bar on both presets:** 7.27 (one judge at 7.60, two at 7.10). Pooled High with G-things-bandfaint's 7.51 is 7.39. Not closed.
- **What holds it (3/3):**
  - a "uniform mottled green with little value separation and no strong rim light", which reads monochrome at small size;
  - the faint end "rolls into a lumpy, belly-up cylinder with the legs hidden".
  - These two are the levers to clear 7.5. The poses otherwise "read clearly and stay on the ground".

## Frames
- **Riftfrill:** `tb/gpu-frames-1108` section `G-things-riftfrill-matte` (6ffa11f4b), High, `tb/things` 7949eba7c.
  - **base:** no overlay.
  - **arm:** `overlay_riftfrill_matte.json` (metallic 0, roughness 0.88, specular 0.22).
  - Hit and faint whole-body with context, 10 frames per side.
- **Voltwig:**
  - **Medium:** `G-closeout-voltwig-medium` (872a8dcb6), main fcdf124b4, `capture_f36_poses.gd --species=voltwig --whole-body --context --roles=hit,faint`.
  - **High:** G-things-bandfaint's base-High voltwig frames (29cb35dbe), as the GPU lane asked.
- **Control:** F38#38's closing High and Medium crafting frames.
- **Sets:** pose-stage 2×2 grids of hit-000, hit-050, faint-050 and faint-100, cropped (560, 200, 1560, 840). Riftfrill's recorded defects are "glossy dark purple" and "back below the trainer's head"; Voltwig has none.

## Batch `G-rf`
- Three code-blind judges, standard prompt, three candidate sets.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22.
- Yardstick: `yardstick_g_riftfrill_voltwig/`.

**Raw Bar A (judges a, b, c):**

| Set | Side 1 | Side 2 |
|---|---|---|
| Riftfrill (base / arm) | 6.1, 5.9, 5.8 | 6.1, 5.9, 5.8 |
| Voltwig (High / Medium) | 6.8, 6.4, 6.4 | 6.8, 6.4, 6.4 |
| F38#38 (High / Medium) | 7.1, 7.3, 7.2 | 7.1, 7.3, 7.2 |
