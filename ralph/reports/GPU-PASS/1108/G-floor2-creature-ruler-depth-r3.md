# G-floor2-creature-ruler-depth-r3: contact at the trainer's feet depth, landing candidate (F38#5, F38#26, F38#31; GPU High)

Frames: `tb/gpu-frames-1108` 34865ea78, High, seed 2042, 18 pairs, `phase2_capture_creatures.gd`.
- base = `tb/floor2` aac9c84a3 with `creature_ruler_depth` off.
- arm = base + `FLOOR2-STAGE/overlay_ruler_depth.json`.
- Arm manifests report every subject's nearest ground contact at 0.02 m or more behind the trainer's feet:
  - 0.02 m on 15 frames;
  - aquaryn fainted and resting 5.01 m;
  - galewisp hurt 1.34 m.
  - All frames are `in_frame`, none overlaps the trainer, and none is nearer the lens.
- Meadows feet still draw lower in frame (feet_screen_y 0.79–0.92 against the trainer's 0.723) because the hillside falls away. That is slope, not nearness.
- This is the version that would land.

Sheets: the same sets and briefs as round 2 (`G-floor2-creature-ruler-depth-r2.md`), with this round's two added frames placed:

| Set | Brief | Frames | Layout |
|---|---|---|---|
| F38#5 | normal creature scale | bramblebun, brooktail, pipwing and trailpup idle | |
| F38#26 | creature ground contact | bramblebun idle, mosshell alpha_idle, brooktail fainted, mosshell fainted | |
| F38#31 | alpha rarity read | brooktail and trailpup, each normal idle beside its alpha_idle | |
| No-loss A | F38#5 brief | galewisp idle (added), galewisp hurt, sparkit idle and hurt, stormraven idle, fulgocobra idle | 3×2 |
| No-loss B | F38#5 brief | aquaryn idle, resting and fainted (added) | one row of three, so no empty cell |

Render check: 12–18% of pixels changed on the Meadows frames, 4–13% on the no-loss frames. Blank frames: 0 of 18 per side.

Batch `G-rd3`:
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.

Fit: linear, slope 1.3152, intercept −1.4379, r 0.921, anchor RMSE 0.541.

Warning, verbatim: "meets the bar only above the top anchor (7.53): F38#5 arm; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch".

## Verdict: SHIP. Every row gains well over 0.5, 3/3 prefer on every set, and both no-loss sets gain.

| Set | Base | Arm | Gain | Judges preferring arm | Round 2 arm | Board |
|---|---|---|---|---|---|---|
| **F38#5** normal creature scale | 5.80 | **7.77** (above top anchor; confirming batch) | **+1.97** | 3/3 | 8.00 | 5.86 |
| F38#31 alpha rarity read | 5.80 | **7.20** | +1.40 | 3/3 | 7.17 | 5.85 |
| F38#26 creature ground contact | 5.44 | **6.85** | +1.41 | 3/3 | 6.39 | 5.91 |
| No-loss A (Cloudreach, Stormwood) | 5.71 | 7.51 | +1.80 | 3/3 | 7.17 | — |
| No-loss B (aquaryn) | 5.53 | 7.11 | +1.58 | 3/3 | 6.91 | — |

Raw Bar A, base → arm (judges a, b, c):
- F38#5: 5.3, 5.6, 5.6 → 6.9, 7.2, 6.9. Mapped arm 7.64, 8.03, 7.64.
- F38#31: 5.3, 5.6, 5.6 → 6.5, 6.6, 6.6.
- F38#26: 5.0, 5.3, 5.4 → 6.3, 6.2, 6.4.
- No-loss A: 5.2, 5.5, 5.6 → 6.6, 7.0, 6.8.
- No-loss B: 5.2, 5.3, 5.4 → 6.6, 6.6, 6.3.

Recorded defects:
- **F38#5:** base PRESENT 3/3; arm FIXED 3/3.
- **F38#31:** base PRESENT 3/3; arm PARTIAL 3/3.
- **F38#26:** base PRESENT 3/3; arm PARTIAL 3/3.
- **No-loss A:** base PRESENT 3/3; arm FIXED for judges b and c, PARTIAL for judge a. Judge a: the sparkit lunge frame is about trainer height.
- **No-loss B:** base PRESENT 3/3; arm FIXED 3/3.

### F38#5 maps 7.5 or above at High: it now needs Medium
- Mapped 7.77; every judge maps at 7.64 or above.
- The score is above the top anchor (7.53), but this batch includes f36_0_npc:C1, so it is its own confirming batch.
- Round 2 gave 8.00 for the earlier, nearer staging. This landing version holds at 7.77 with nothing nearer the lens than the trainer.
- Per the 31 Oct order, **F38#5 needs the same arm captured and judged at Medium**. It closes only at 7.5 or above on both.
- F38#31 (7.20) and F38#26 (6.85) stay at High only.

## The depth question: settled for this version
- **Perspective is no longer driving the scale result.** With contact measured at or behind the trainer's feet, the scale gain holds: F38#5 gains +1.97, against +2.86 in round 2.
- **No judge says any subject is nearer the camera** or "crowds the camera" this round. Two round-2 judges had said so.
- **The flat-ground sets still gain:** Cloudreach and Stormwood +1.80, Tidewake +1.58. On flat ground, slope cannot explain the gain.

## What the judges flag on the arm (for follow-up, not blocking)
- **Stormwood:**
  - stormraven blooms to near-white over the whole body (3/3), the same finding as the F41#13 batches;
  - fulgocobra's bands are heavy (judge c);
  - the sky reads washed-out lilac, not storm purple (judges a and c);
  - sparkit's lunge or sprawl pose reads odd (judges a and c).
- **Aquaryn hurt and fainted** lie on their side and read as floating or toppled, with feet off the sand and a soft contact shadow (3/3). This is an F39#6 pose issue, newly visible now the creature is near.
- **F38#31:** alphas still read as "bigger plus sparkle"; the motes are generic blobs (3/3). The mosshell alpha fringe noted in round 2 was not raised this round.
- **F38#26:** the dark Mirejaw and the olive turtle merge into the uniform grass carpet. Feet are still partly in grass (3/3).

## What would add the most
1. **Grass and lighting (scene):** clear or flatten grass in a small radius under each staged creature, and add a rim light per creature. This moves F38#26.
2. **Alphas (new_art or scene):** give them a distinct trait (markings, mane or plates, or a richer coat), not size and motes. This moves F38#31.
3. **Electric glow (scene):** clamp the whole-body emissive glow on the stormraven and cobra.
4. **Aquaryn poses (scene):** ground the hurt and faint poses on the sand.
