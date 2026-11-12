# G-scout-arms: F41#1 muted Stormheart banners and F38#32 camp spacing

Frames: `tb/gpu-frames-1108`, High, live main 4af7d07a9 (batch 28).
- `G-f41-1-banners` (ddcf54699): arm = `ITEM-F41-1-ARM/overlay_banners_muted.json`.
- `G-f38-32-camp` (4d1857ac1): arm = `ITEM-F38-32-ARM/overlay_camp_spacing.json`.

Batch `G-scout`:
- Three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so the top anchor is 7.35 and this is a confirming batch.
- The briefs say "score the subject, not the rest of the frame".
- Fit: linear, slope 1.3283, intercept −1.3724, r 0.893, anchor RMSE 0.519. No warnings.

| Row | Live | Arm | Gain | Judges preferring arm | Ship |
|---|---|---|---|---|---|
| F41#1 | 4.87 (raw 4.9, 4.8, 4.4) | 4.87 (raw 4.9, 4.8, 4.4) | **0.00** | 0/3 (3 ties) | **no** |
| F38#32 | 6.24 (raw 5.5, 6.0, 5.7) | 5.89 (raw 5.8, 5.5, 5.1) | **−0.35** | 1/3 | **no** |

Both arms are flat or worse. Neither ships.

## F41#1: only half of the arm reached the render

A pixel check of the frames shows that **the lip-banner count and phase applied but the colour did not**:
- In the close frame, four banners in view became two.
- The arm's banners are the same saturated royal blue with a white bolt as live.

All three judges again describe "flat saturated-blue squares", so the muted `#34475c` slate and `#b49a62` brass never rendered.

`stormheart_tree.gd` reads both colours from `_presentation.built_detail` (lines 900 and 1524), the key the overlay set. Possible causes:
- The GPU lane's overlay merge skipped the `built_detail` block.
- The visible banner colour comes from somewhere that block does not feed.

**Ask for the GPU lane:** confirm that the imported tree's `stormheart_presentation.json` carried `built_detail.banner_colour = #34475c` for this capture.

Even so, judges rate the banners minor beside the row's main defects:
- No branching crown or glowing core: new art, 3/3.
- Flat white zig-zag lightning: code, 3/3.
- A blotchy green moss floor with a decal-like orange seam: 3/3.

Banner-only arms are unlikely to move F41#1 by 0.5, so **park F41#1 banners**.

## F38#32: the arm cost legibility, and my CPU stand check was wrong

- **The CAMP sign is in the GPU camp_tent frame on main, both sides (3/3).** It is a large dark red-brown board in the foreground; two judges flag it as near-oxblood on a friendly element.
  - My CPU capture placed the approach stand south of the camp with the sign behind the camera.
  - The GPU capture's stand differs, and the sign fills the lower left.
  - The ARM.md claim that the sign "needs no move" is wrong for the GPU stand. This is noted in that ARM.md.
- **Moving the "trail_*" stores and the Bench off the stand line made the props smaller and less legible.** On the arm side the props are "fewer and smaller … pushed to the edge of the path where they merge with grass and the fire" (judge b), and "barrels, crates and tools shrink to specks" (judge c).
  - In live, those stores were the large, separated props the subject is scored on ("a barrel, a plank bench, a bucket, crates and pumpkins on the dirt clearing", judge c).
  - Lesson: for a "prop legibility" row, the props near the lens are the subject. Moving them away removes what is being judged.

**What the judges ask for instead:**
- Recolour or re-seat the TRAIL CAMP threshold board out of the camp_tent stand: 2/3 flag its red as reserved-colour leakage. The board is `clusters[6].roadside_threshold`.
- Keep the big props near the stand, but stage them in separated groups on clear dirt.
- Sharpen the blurry dirt disc. The disc is `camp_floor` `texture` and `uv_per_m`.

A second F38#32 idea should keep the stores where they are and move or recolour only the threshold board. That needs the GPU stand position, which the GPU capture manifest records as `camera_position`.

## Other notes from this batch (anchors excluded)
- **F41 named fight (capacitor alpha), 3/3:**
  - The camera goes inside canopy in i13 and i15.
  - The telegraphs are flat magenta rings.
  - The player's creature is near-invisible.
- **Meadows faction-site aftermaths:** the new aftermath side is clearly better, by about 1.0–1.5 raw (3/3).
