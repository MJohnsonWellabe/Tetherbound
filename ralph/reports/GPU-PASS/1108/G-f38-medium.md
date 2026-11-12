# GPU re-score 1108, section G Medium: F38#36, F38#38, F38#18 and F38#23 at Medium (mapped)

**Verdict:**
- **F38#36 (dialogue speaker occlusion), F38#38 (craft action hint contrast) and F38#18 (craft recipe text) map to 7.5 or above on Medium as well as High, so all three close.**
- **F38#23 (Tether Relay yard) does not close:** it maps to 7.58 on High but 7.07 on Medium.

| Row | High mapped (source) | Medium mapped (this batch) | Both at 7.5 or above? |
|---|---|---|---|
| F38#36 dialogue speaker occlusion | 7.74 (`B.md`) | **8.08** | **Yes: closes** |
| F38#38 craft action hint contrast | 8.16 (`F-meadows.md`) | **8.30** | **Yes: closes** |
| F38#18 craft recipe text | 7.95 (`F-meadows.md`) | **8.19** | **Yes: closes** |
| F38#23 Tether Relay yard | 7.58 (`F-meadows.md`) | **7.07** | No: Medium is 0.43 short |

**Caveats, which do not change the verdict under the yardstick rules:**
- All three closing Medium scores, and all three High scores, sit above the top anchor (7.35). Each batch includes the craft "after" anchor at 7.35, so each is its own confirming batch (SKILL "Extrapolated passes").
- Their raw judge means are 6.5–7.2.
- This batch's slope is steep (1.604). Calibrate also warns that "some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)".
- The Medium and High frames come from different live trees: Medium ba6778f45 and High be95950b. Each row is scored on the tree its own capture used.
- F38#18 is still PARTIAL 3/3 on its recorded defect, because the "Prime Orb 4 Ironwood · 2 Rootstone · 4 F…" line is still clipped. The row closes on its score, but that one clipped line remains.

## Method
- **Frames:** `tb/gpu-frames-1108` (1866896d), on an NVIDIA GTX 1060, Forward+ Medium 1920x1080, JPEG q85, live tree ba6778f45:
  - manifest-G-f38-36-medium.json: 3 frames (Kell, Corin and Captain Halder dialogue);
  - manifest-G-f38-38-medium.json: 1 frame;
  - manifest-G-f38-18-medium.json: 1 frame;
  - manifest-G-f38-23-medium.json: 2 frames.
- **Batch:** one batch of the 4 rows. It used the standard JUDGE_PROMPT and 3 pinned anchor pairs (craft, f10_2_r3_capacitor, f04_6_r22), with three fresh code-blind judges, mapped by `calibrate.py`.
- **Fit:** slope 1.6038, intercept -2.7164, r 0.933, anchor RMSE 0.415. It is a confirming batch (top anchor 7.35).
- **Warnings:**
  - "meets the bar only above the top anchor (7.35): F38#18, F38#36, F38#38; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch"
  - "some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)".
- **Sets:** one-sided, so each judge's score is the mean of the two sides. All three judges scored both sides of every one-sided set identically.
- **Judging:** by LANE-SCOUT, 9 Nov 2026 ~03:20 UTC. Judge folders and replies stayed local.

| Row | Medium mapped | Mapped per judge | Raw per judge | Defect calls (j1, j2, j3) | Last CPU / board | Earlier GPU Compat | Batch |
|---|---|---|---|---|---|---|---|
| F38#23 | **7.07** | 6.59 / 7.39 / 7.23 | 5.8 / 6.3 / 6.2 | FIXED, FIXED, FIXED | - | 6.59 | b1 |
| F38#36 | **8.08** | 7.55 / 8.51 / 8.19 | 6.4 / 7.0 / 6.8 | FIXED, FIXED, FIXED | - | 5.20 | b1 |
| F38#18 | **8.19** | 7.55 / 8.83 / 8.19 | 6.4 / 7.2 / 6.8 | PARTIAL, PARTIAL, PARTIAL | - | 7.53 | b1 |
| F38#38 | **8.30** | 7.71 / 8.83 / 8.35 | 6.5 / 7.2 / 6.9 | FIXED, FIXED, FIXED | - | 6.86 | b1 |

## Judges' notes (all three unless noted)
- **F38#36:**
  - Kell, Corin and Captain Halder are framed clearly, with no creature in front of them (FIXED 3/3). One judge answered Bar B with yes.
  - The player's head is cropped at the left edge in frames 1 and 3.
  - A hot magenta-pink specular hotspot sits on the red banner behind Halder in frame 3. If that banner is not Team Tether's, this is an oxblood leak worth checking.
- **F38#38:** the Craft and Leave hints are white with glyphs on a footer bar (FIXED 3/3). They are still small, with no teal accent.
- **F38#18:** five of six rows fit; the Prime Orb material line is cut off. No gold progression accent.
- **F38#23:**
  - The yard is clean cobble with no overgrowth (FIXED 3/3), but it reads empty.
  - Frame 1 is overexposed, and the cobble texture is large and repeated.
  - Props are spread thinly along the edges, and two judges asked for worn paths.
  - The fix is a scene dressing pass (foreground props, wear paths, and exposure on frame 1), then re-capture both presets.
