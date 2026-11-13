# G-below6-stormraven-masonry: Stormraven eye round 2 (F41#13) and route-wall masonry scale (F40#15) (LANE-BELOW6; GPU High)

## Verdicts

| Arm | Set | Base | Arm | Gain | Prefer arm | Verdict |
|---|---|---|---|---|---|---|
| masonry | **F40#15 row** (overlook walk_03, aerie vista dusk) | 5.17 | **5.54** | +0.37 | 3/3 | **SHIP** |
| masonry | Overlook routes (walk_01, walk_02, route_day) | 4.54 | 4.72 | +0.18 | 2/3 | (no loss) |
| masonry | Sky Shrine and Summit Eyrie (no-loss) | 6.89 | 6.89 | 0.00 | identical | (no loss) |
| stormraven r2 | **F41#13 row** (Stormraven and Fulgocobra idle) | 5.72 | 5.72 | 0.00 | identical | **Do not ship:** the change does not show at creature-view distance |

## Masonry: smaller wall stones help (F40#15 +0.37, 3/3)
- **Base** (3/3): the foreground wall's "stone texture is very large for the 1.80 m trainer ... oversized and soft" and blurs.
- **Arm** (3/3): "smaller stones read better" as tighter, built masonry. On the overlook route the arm's wall is "finer, better-scaled ... less posterised" (2/3; judge b preferred base by 0.1).
- **The strip defect is FIXED on both sides (3/3).** This matches G-below6-knifeedge: there are no black strips on current main in these frames.
- **No loss** on the shrine and aviary, which score identically per judge.
- **F40#17 is not in these frames.** Its job frames are the High Perches crown rim, not the overlook or aerie, so this batch says nothing about F40#17.

### Artefact: a translucent amber pane on the overlook route (3/3, both sides)
- In overlook walk_02_day "a large semi-transparent amber pane covers the left half of the frame, tinting a wall and the trainer". The judges call it "an occluder fade or debug volume ... the worst artefact in the batch". A white glowing sphere sits next to it.
- This is not the arm, since it is on both sides. It holds the overlook routes at about 4.5–4.7.
- Worth a look by PLACES or BELOW6. It may be the camera-occlusion fade catching a wall.

### What still holds F40#15 (3/3)
- The grass edge "drops straight into the cloud sea with no built kerb, lip or stone edging".
- The aerie vista is "washed flat by an orange haze", with orange-stick trees and toon blob canopies.
- Floating box wall slabs and flat banner cards on the overlook.

## Stormraven r2: no visible change at normal distance (F41#13 level)
- All three judges see the two sides as identical ("nearly pixel-identical"; "I can't see a meaningful difference"). The eye work the GPU lane's crop shows (a pupil inside a white iris) does not register in the row's frames.
- **What the judges see on both sides (3/3):**
  - Stormraven is "a flat, fully saturated royal-blue bird with white speckles ... glossy plastic, no feather detail, no rim light and no electric trait".
  - The style board shows "a black raven with blue lightning".
- **Next lever (3/3, scene):** re-material Stormraven to a near-black or iridescent feather base, with rim light and one electric trait (blue or violet lightning veins or feather edges, glowing eyes). The eye alone cannot carry the row at this distance.
- **Fulgocobra:** "glowing eye and white-cyan hood lines" read (the recorded defect is PARTIAL, 2/3). Its uniform navy body against the board's dark olive is the remaining gap.
- **Scene, both sides (3/3):** pure-black ground blotches and a black path with an orange crack decal. These are the T-DARKRIM and P-STORMSKY causes.

## Pooled current-main lines
- **F40#15:** two base panels of the same frames on current main, 5.77 (G-below6-knifeedge) and 5.17 (this batch), pool to ≈ 5.47 at High. The masonry arm's 5.54 is the gain evidence.
- **F41#13:** this batch's base, 5.72, is the current-main read at High; the board has 5.97.

## Frames
- **Sources:** `tb/gpu-frames-1108`, High, `--fixed-fps 20`, `tb/below6` 49a4b3dc2 on both sides.
  - **base:** no overlay.
  - **arm:** each lane overlay.
- **Sections:**
  - `G-below6-stormraven-r2` (a16cb1d19). Its `_eye_crop_base_r1arm_r2arm.jpg` was not used as a frame.
  - `G-below6-masonry` (c2cfcad91)
  - `G-below6-masonry-noloss` (c8689e59a)
- **Health:** 0 script errors. The aerie's walk_01–03 have no camera stand on either side (a tool survey gap, not the arm).
- **Render check (mean difference per frame):**
  - Stormraven 0.68 and Fulgocobra 0.14.
  - Masonry 1.1–6.6.
  - No-loss 3.4–5.3.
- **GPU lane pre-check (stormraven):** saturated pixels in the eye box went 108 base → 373 (r1) → 288 (r2), and a dark pupil survives in close crop.
- **Sets:**
  - F41#13: Stormraven idle over Fulgocobra idle.
  - F40#15: its job frames.
  - Overlook routes: walk_01, walk_02 and route_day.
  - No-loss: 2×2 grid of shrine approach, shrine close, eyrie approach and eyrie close.

## Batch `G-sm`
- Three code-blind judges, standard prompt, four candidate sets.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22 (creature row). This is a confirming batch.
- **Fit:** linear, slope 1.354, intercept −1.505, r 0.990, anchor RMSE 0.14. No warnings.
- Yardstick: `yardstick_g_below6_stormraven_masonry/`.

**Raw Bar A (judges a, b, c):**

| Set | Base | Arm |
|---|---|---|
| F40#15 row | 5.2, 4.9, 4.7 | 5.4, 5.2, 5.0 |
| Overlook routes | 4.9, 4.6, 3.9 | 5.2, 4.5, 4.1 |
| Shrine and eyrie | 6.4, 6.6, 5.6 | 6.4, 6.6, 5.6 |
| F41#13 row | 5.6, 5.0, 5.4 | 5.6, 5.0, 5.4 |

Bar B: no on every candidate set (3/3).
