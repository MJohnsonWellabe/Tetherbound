# G-things-convtight: tighter conversation camera, 3.5 → 2.9 m and fov 40 → 36 (F38#16, #17, #37; F39#26; F40#10, #12; GPU High)

## Verdict: SHIP. No judged row or sample loses.
- The arm gains on 10 of 11 sets; F38#16 is level.
- 3/3 judges prefer the arm on 9 sets, and 2/3 on F38#37 (one tie).
- No judge prefers base on any set.

| Set | Base | Arm | Gain | Prefer arm | Arm per judge (raw) |
|---|---|---|---|---|---|
| **F38#17** named trainer subject visibility (3 frames) | 6.46 | **6.85** | +0.39 | 3/3 | 6.3, 6.2, 6.0 |
| **F38#37** dialogue rock obstruction (2 frames) | 6.50 | **6.69** | +0.19 | 2/3 (1 tie) | 5.6, 6.3, 6.2 |
| **F38#16** tournament subject identity (3 frames) | 5.57 | 5.57 | 0.00 | identical | 5.0, 5.2, 5.0 |
| **F39#26** dialogue foreground obstruction (3 frames) | 6.73 | **7.04** | +0.31 | 3/3 | 6.4, 6.2, 6.4 |
| **F40#10** dialogue foreground composition (3 frames) | 6.61 | **6.92** | +0.31 | 3/3 | 6.6, 6.3, 5.8 |
| **F40#12** dialogue speaker visibility (2 frames) | 6.85 | **7.12** | +0.27 | 3/3 | 6.6, 6.3, 6.3 |
| Meadows sample 1 (9 conversations) | 6.85 | 7.31 | +0.46 | 3/3 | 6.6, 6.6, 6.5 |
| Meadows sample 2 (9) | 6.65 | 7.00 | +0.35 | 3/3 | 6.2, 6.4, 6.3 |
| Tidewake sample (9) | 6.38 | 6.57 | +0.19 | 3/3 | 5.8, 6.0, 6.0 |
| Stormwood sample 1 (9) | 6.85 | 7.27 | +0.42 | 3/3 | 6.6, 6.4, 6.6 |
| Stormwood sample 2 (9) | 6.81 | 7.27 | +0.46 | 3/3 | 6.6, 6.4, 6.6 |

## Why the arm wins (3/3)
**On base, the player's head, shoulder or backpack pokes in at the left edge** of many dialogue frames. The tighter arm camera mostly drops it.

Judges name this on the base side in:
- F38#17: Bram, Solene;
- Stormwood: Hesk, Ivo, Nell, Sera, Ren, Marl, Dace, Orin, Rook;
- F40#12: both frames;
- F40#10: Tavi, Rusk;
- Meadows sample 2: Maren, Rae, Tam, Juno;
- F38#37: larger on base;
- F39#26: Adair, Rowan, where base is marked PARTIAL by 2/3 and the arm FIXED.

**The judges were blind to which side was which.** The arm was side A in 9 sets and side B in Meadows sample 1. In Meadows sample 1 they preferred B, which was the arm: the "player crowding the edge" there is on base (Ada, Rescued Ranger, Wilhelm, Bryn). So this is not a position bias.

**Heads are never cropped on the arm.** No judge flags a head crop on either side. The one "cropped too tight" note (Rowan, judge b) is on base.

## Recorded defects on the arm

| Row | Arm verdict |
|---|---|
| F38#17 "no speaker visible" | FIXED 3/3 |
| F40#12 "speaker absent" | FIXED 3/3 |
| F39#26 "player overlaps speaker" | FIXED 3/3 (base PARTIAL 2/3) |
| F40#10 "player or posts hide speaker" | FIXED 2/3, PARTIAL 1/3 (base: FIXED 1/3, PARTIAL 2/3). Judge c: the workbench crosses Tavi's torso on both sides |
| F38#37 "rock faces hide speaker" | FIXED 2/3, PARTIAL 1/3 on both sides. The Foreman now stands in front of the rock, which fills the background |
| F38#16 "same grey-haired character" | FIXED 1/3, PARTIAL 2/3 on both sides |

**F38#16 cannot move with this camera.** Mira's frame puts the camera inside a timber-and-lattice wall on both sides, so no speaker is visible (3/3). The other two speakers, Tam and Oskar, are distinct and match their portraits. The Mira stand needs moving, as in G-things-convclear-meadows.

## Still holding these rows (3/3 unless noted)
1. **The Mira tournament stand: camera inside a wall** (F38#16).
2. **Warder Solene's face is blown out to white** (F38#17, both sides). Judge c also says it does not match her portrait.
3. **Foreground props cutting speakers (both sides):**
   - a chain prop across Captain Vance;
   - a crimson pillar half in front of Captain Vess. It is next to a Tether captain, so it is acceptable;
   - a tree trunk half-covering Gil (judge b);
   - a dark mass at the top right of Rae's frame.
4. **Flat backgrounds:**
   - the Stormwood lavender sky and Captain Marrow's plank floor;
   - Tidewake's bare, blown-out sand planes. Tovin, Nel and Orsen share one cowboy mesh (judge b);
   - the Cloudreach courtyard is a sparse beige plane;
   - Keeper Hald's corridor is flat green stone.
5. **Minor:**
   - a floating teal disc above Senn (2/3);
   - Rusk is lost against a dark trunk (2/3);
   - the Iona frame's background creature differs between sides (a water dragon on base, a turtle on the arm). This is a spawn difference, not the arm.

## Current levels with the arm
- F39#26 7.04 and F40#12 7.12 are close-out-exception candidates: both are at 7.0 or above.
- F40#10 6.92, F38#17 6.85, F38#37 6.69 and F38#16 5.57.
- Sample mean: 7.08 on the arm, against 6.71 on base.

## Frames
- **Source:** `tb/gpu-frames-1108`, High, `--fixed-fps 20`, `tb/things` 4f26fcac3 on both sides. Captured with `phase2_capture_dialogue.gd --sight-stand`, as in G-things-convclear-*.

  | Biome | Commit | Frames per side |
  |---|---|---|
  | meadows | aa8a5c5c6 | 96 |
  | tidewake | fdb8d1281 | 80 |
  | cloudreach | 75047a1c3 | 22 |
  | stormwood | c87f2dcce | 86 |

  - **base:** no overlay.
  - **arm:** `overlay_conv_tight.json` (camera.json conversation distance 3.5 → 2.9 m, fov 40 → 36).
  - 0 script errors.
- **Render check:**
  - dialogue mean difference is 15–33 per frame;
  - Mira's frame is 3.7 (the camera is in the wall on both sides);
  - by eye, the arm frames the speaker tighter, and the player's head shows less at the left edge.
- **Sets:**
  - each row's job.json frames, in a 2×2 grid. Cloudreach `captain_veyra__defeated` was not captured, so F40#12 uses two frames.
  - 3×3 samples of the other conversations, in `samples.json`: Meadows ×2, Tidewake ×1 and Stormwood ×2, evenly strided. `water_trainer_rune` is excluded because its camera does not engage on either side.

## Batch `G-ct`
- Three code-blind judges, standard prompt, 11 candidate sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.160, intercept −0.305, r 0.910, anchor RMSE 0.57. No warnings.
- Bar B: no on every candidate set (3/3).
- Yardstick: `yardstick_g_things_convtight/`.
