# GPU arm round 1108, G-ghost-glow: Forward+ glow and creature-rim tone (live vs arm, GPU High, mapped)

**Verdict:**
- **The arm fixes the see-through "ghost" creatures. 5 of 11 rows pass the ship rule (gain > 0 and at least 2/3 judges prefer the arm):**

  | Row | Subject | Gain | Judges preferring arm |
  |---|---|---|---|
  | F38#28 | Warden arena | +0.91 | 3/3 |
  | F38#2 | Hurt poses | +0.67 | 3/3 |
  | F38#14 | Catch effect | +0.57 | 3/3 |
  | F38#7 | Catch aim | +0.53 | 2/3 |
  | F41#15 | Marrow and Nysa | +0.29 | 3/3 |
- **3 rows go backwards**, all with 0/3 judges preferring the arm:
  - F38#13 catch camera, −0.62.
  - F39#18 dialogue framing, −0.33.
  - F39#26 dialogue obstruction, −0.33.
  - For two of the three, the loss comes from a composition difference between the live and arm captures, not from the glow change; see the notes.
- **3 rows are level:** F39#29 and F41#4 (identical scores) and F41#7 (+0.05, 1/3).
- **Emissive check passes.** On the Lantern Pools close (F41#4), all three judges scored live and arm identically. The amber vein lines and glowing mushrooms still read on the arm side.
- **Mean gain across the 11 rows:** +0.16.
- **Recommendation:** ship it for creatures. The per-row rule passes the Meadows creature rows decisively.
  - It does not fix NPC ghosting. F39#18 and F39#26 speakers still read translucent on the arm side, and Marrow's white head is unchanged on F41#7 and F41#15.
  - That matches `G-f41-15.md`: NPC blowout responds to albedo, not glow. Pair this arm with the albedo approach for NPCs.

| Row | Subject | Live mapped | Arm mapped | Gain | Prefer arm | Ship rule |
|---|---|---|---|---|---|---|
| F38#28 | Warden arena boundary | 5.91 | **6.82** | **+0.91** | **3/3** | **Ships** |
| F38#2 | Creature hurt/move poses | 5.34 | **6.01** | **+0.67** | **3/3** | **Ships** |
| F38#14 | Catch effect finish | 6.30 | **6.87** | **+0.57** | **3/3** | **Ships** |
| F38#7 | Catch aim readability | 5.96 | **6.49** | **+0.53** | **2/3** (1 level) | **Ships** |
| F41#15 | Marrow/Nysa dialogue obstruction | 5.82 | **6.11** | **+0.29** | **3/3** | **Ships** |
| F41#7 | Marrow trainer dialogue | 6.68 | 6.73 | +0.05 | 1/3 (2 level) | No (flat) |
| F41#4 | Lantern Pools close (emissive check) | 5.91 | 5.91 | 0.00 | 0/3 (3 level) | Level; glows still read |
| F39#29 | Tidewake speaker visibility | 5.39 | 5.39 | 0.00 | 0/3 (3 level) | Level |
| F39#26 | Tidewake dialogue obstruction | 5.91 | 5.58 | −0.33 | 0/3 | No |
| F39#18 | Tidewake dialogue framing | 6.44 | 6.11 | −0.33 | 0/3 | No |
| F38#13 | Catch camera framing | 7.11 | 6.49 | −0.62 | 0/3 | No |

**Per judge, mapped (raw):**

| Row | Live: j1 / j2 / j3 | Arm: j1 / j2 / j3 |
|---|---|---|
| F38#28 | 5.96 / 5.67 / 6.11 (5.6 / 5.4 / 5.7) | 6.97 / 6.54 / 6.97 (6.3 / 6.0 / 6.3) |
| F38#2 | 5.53 / 4.95 / 5.53 (5.3 / 4.9 / 5.3) | 6.25 / 5.53 / 6.25 (5.8 / 5.3 / 5.8) |
| F38#14 | 6.39 / 5.67 / 6.82 (5.9 / 5.4 / 6.2) | 7.11 / 6.25 / 7.26 (6.4 / 5.8 / 6.5) |
| F38#7 | 5.82 / 5.53 / 6.54 (5.5 / 5.3 / 6.0) | 6.54 / 6.39 / 6.54 (6.0 / 5.9 / 6.0) |
| F41#15 | 5.96 / 5.24 / 6.25 (5.6 / 5.1 / 5.8) | 6.25 / 5.53 / 6.54 (5.8 / 5.3 / 6.0) |
| F41#7 | 6.39 / 6.82 / 6.82 (5.9 / 6.2 / 6.2) | 6.54 / 6.82 / 6.82 (6.0 / 6.2 / 6.2) |
| F41#4 | 5.96 / 5.96 / 5.82 (5.6 / 5.6 / 5.5) | 5.96 / 5.96 / 5.82 (5.6 / 5.6 / 5.5) |
| F39#29 | 5.39 / 5.10 / 5.67 (5.2 / 5.0 / 5.4) | 5.39 / 5.10 / 5.67 (5.2 / 5.0 / 5.4) |
| F39#26 | 5.67 / 6.11 / 5.96 (5.4 / 5.7 / 5.6) | 5.24 / 5.67 / 5.82 (5.1 / 5.4 / 5.5) |
| F39#18 | 6.97 / 6.11 / 6.25 (6.3 / 5.7 / 5.8) | 6.25 / 5.96 / 6.11 (5.8 / 5.6 / 5.7) |
| F38#13 | 7.40 / 6.54 / 7.40 (6.6 / 6.0 / 6.6) | 6.97 / 5.96 / 6.54 (6.3 / 5.6 / 6.0) |

## What the judges saw (code-blind; sides mapped to live and arm through the key)
- **The ghost look is on the live side and gone on the arm side for creatures.** All three judges independently called it the largest drag on the batch.
  - F38#2: on live, the creature renders as a translucent blue-white wash in frames 1 and 3. On the arm side its brown values are normal.
  - F38#14: Terrapup and Bramblebun look like x-ray holograms on live and are opaque on the arm side.
  - F38#28: Burrowback shows as a pink translucent glow, and a white puff cluster covers a third of frame 3. On the arm side the creatures are opaque in a warm torchlit hall, and the cyan floor ring reads as thinner. One judge marked that defect FIXED on the arm side.
  - F38#7: Terrapup and Bramblebun are ghost-blue on live. On the arm side they are opaque, but white smoke puffs cover the companion in frame 2.
- **F38#13 (−0.62):**
  - The live capture's frame 3 cuts to a low medium shot with Bramblebun, the trainer and Terrapup together, which all three judges called "the best creature frame in the batch". The arm capture's frame 3 stays on the wide aim view.
  - That is a difference in what the capture caught, not in the glow; on live, Terrapup is still ghost-translucent in frames 1 and 2.
  - Re-capture both arms with the same frame-3 beat before reading this row.
- **F39#26 (−0.33):** the arm capture puts the player's head and backpack into the left third of frames 2 and 3 (a composition difference). The speakers (Adair, Iona, Rowan) read semi-transparent on both sides.
- **F39#18 (−0.33):** one judge saw Bex and Daro more ghosted on the arm side than on live. The other two called both sides faintly translucent. This is the one row where the glow arm may make an NPC look worse.
- **F41#15 and F41#7:** Marrow's head is still blown out to white on both sides. The F41#15 gain comes from less edge intrusion in the arm frames. The glow arm does not fix Marrow; the albedo arm does (`G-f41-15.md`).
- **F41#4, Lantern Pools close (the emissive check):** identical on both sides. The amber crack lines and glowing mushrooms still read, so no emissive is lost. The remaining notes apply to both sides equally: no landmark subject, heavy rain bars, and a blurry green foreground prop.

## Packer correction (from the GPU lane)
- Between 278c29ae and d1b60a49, 31 section F frame paths held main pixels.
- **My F verdicts are unaffected.** Every F batch was built from extracts taken before 278c29ae: F-meadows at 50257949, the other biomes at 6fb6e76e and 7416d0d8. The G Medium batch used 1866896d and Medium-only paths.
- `G-f41-15.md` used the b5a5aabb extract. Its live frames are main ba6778f45 pixels, which is what that live-vs-arm round compares, so it stands.
- For this round, the 60 frames from my 85147381 extract are byte-identical (md5) to the same frames at their new `G-ghost-glow/` paths at d1b60a49. Only the live paths moved.

## Method
- **Frames:** `tb/gpu-frames-1108`, `manifest-G-ghost-glow.json` (85147381; verified against d1b60a49). 60 frames: 30 live and 30 arm, NVIDIA GTX 1060, Forward+ High 1920x1080, JPEG q85.
  - Live: main ba6778f45.
  - Arm: main plus `scripts/ui/graphics_prefs.gd` from `tb/item-ghost-glow` de6361be6 plus `overlay_glow_threshold.json` (glow threshold 1.6, intensity 0.5, bloom 0, creature rim 0.35/3.0).
  - The blank-frame checks report 0 blank frames on both arms.
- **Judging:** each row's live and arm frames from the same stands sit side by side, up to 4 in a 2x2 grid at 640x360. `anchor_tiles.py` shuffles the sides and keeps the key outside the judge folder. Three fresh code-blind judges scored with the standard JUDGE_PROMPT and 3 pinned anchor pairs (craft, f10_2_r3_capacitor, f04_6_r22).
- **Fit:** `calibrate.py` linear, slope 1.4388, intercept −2.0959, r 0.901, anchor RMSE 0.501. Confirming batch (top anchor 7.35); no warnings.
- **Scale:** these mapped scores are on this batch's own scale, so read gains within this file.
- **Judged by:** LANE-SCOUT, 9 Nov 2026 ~04:45 UTC. Judge folders and replies stayed local.
