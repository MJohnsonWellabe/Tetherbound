# G-reverify-f36-medium: real Medium on the pose stage after #925 (black-background stage; GPU Medium)

All scores here are on the **black-background stage**: main 6906a2ebf, the first tree on which the pose stage applies the preset. Since #925 the background renders black, not dark slate. LANE-THINGS is fixing it.

## Verdict: all four closed rows HOLD at Medium. Ashtusk does not close. Stormtrail meets the bar at Medium; its High read is 0.01–0.05 short.

| Row | Medium (mapped) | Per judge | 7.5 or above at Medium? | High read | Row status |
|---|---|---|---|---|---|
| **F36#72 Stormbrush** | **7.55** ↑top | 7.59, 7.85, 7.20 | **holds** (narrowly; one judge 7.20) | 7.68 (G-f36-72) | stays closed |
| **F36#69 Solmane** | **7.72** ↑top | 7.59, 8.11, 7.46 | **holds** | closed earlier at High | stays closed |
| **F36#58 Pebbik** | **7.63** ↑top | 7.59, 7.85, 7.46 | **holds** | 7.65 | stays closed |
| **F36#35 Breezetail** | **7.59** ↑top | 7.46, 7.72, 7.59 | **holds** | 7.61 | stays closed |
| F36#33 Ashtusk | 7.42 | 7.46, 7.46, 7.33 | no | see below | open |
| Stormtrail | **7.72** ↑top | 7.46, 7.98, 7.72 | yes | 7.49 (G-cc, with embers); 7.40 before embers | open: High 0.01 short |

- **Pooled High for Ashtusk.** Three panels: G-rr 8.03, G-abm 7.28 and G-cc 7.32, which pool to 7.54.
  - G-rr and G-abm predate the embers + hit change, and G-abm was a High copy labelled Medium.
  - The only High panel on the current state is G-cc at 7.32. With Medium at 7.42, Ashtusk stays open.
  - What holds it, 3/3: the dark plates still merge in the standing and hit frames (PARTIAL), and the tusk tips still reach floor level in the hit reaction (PARTIAL). 1/3: the belly-up faint end reads cartoonish. The floating line is FIXED 3/3.
- **Stormtrail.** Medium 7.72 clears the bar. Its only current-state High panel is 7.49 (G-cc), and pooling with the pre-embers 7.40 gives 7.45.
  - A fresh High read on the corrected stage would likely settle it. The judges' remaining item is a faint end that is "still very flat" (PARTIAL 2/3, FIXED 1/3).
- **Every bar-meeting score is above the top anchor.** The batch's anchors reach 7.47/7.53 (f36_0_npc:C1), so this is the confirming batch.

## The black background
- **2 of 3 judges named the stage.**
  - Judge b, top change: "Put the creature pose stage on natural ground ... instead of a grey slab on black". It scored the creatures 6.8–7.3 raw.
  - Judge c, Bar B note: "every pose-stage set sits on a black void with no sky, fog or light mood ... I judged only the creature". It scored 6.6–7.0 raw, the lowest panel.
  - Judge a did not mention it.
- **Effect:** both judges treated the black as a presentation limit, not a creature defect. Judge c did mark the dark ashtusk back as merging "with the black backdrop".
- **Stormbrush (7.55)** is the only closed row within 0.1 of the bar. It is the candidate for a re-run on the corrected stage, if the coordinator wants extra margin.

## Frames
- **Source:** `tb/gpu-frames-1108` section `G-reverify-f36-medium` (2f7b3b01d), Medium, one side.
- **Build:** main 6906a2ebf.
- **Capture:** `capture_f36_poses.gd --whole-body --context --roles=hit,faint`, for stormbrush, solmane, pebbik, breezetail, ashtusk and stormtrail.
- **Health:** the log shows "STAGE graphics preset applied: Medium". 0 script errors. `PACK_STAGE_FRAMES=1` after an eye check.
- **GPU lane check:** Ashtusk High vs Medium on the same tree differs by a mean of 0.11 per frame, against 0.001 before #925. The preset now reaches the frames, mainly in body shading, shadow edges and the trainer.
- **Sets:** one-sided, the same image on both sides, so judges see "A and B look the same".
  - Crop 560,200, 1000×640. Tiles: hit 000, hit 050, faint 050, faint 100.
  - F36 (1) brief.
- **Recorded defects:** the latest roster causes.
  - Stormbrush: "oversaturated plastic-blue fur", "bulk hides the trainer ruler".
  - Pebbik and breezetail: the faint-ground defect.
  - Ashtusk: plates, floating line, tusk clip.
  - Stormtrail: placeholder look, faint sheet.
  - Solmane: none.

## Batch `G-rvm`
- Three code-blind judges, standard prompt, six candidate sets.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22. This is a confirming batch.
- **Fit:** linear, slope 1.294, intercept −1.3387, r 0.948, anchor RMSE 0.32.
- **Warning, verbatim:** "meets the bar only above the top anchor (7.53): breezetail, pebbik, solmane, stormbrush, stormtrail; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch".

**Raw Bar A (judges a, b, c):**

| Row | Raw |
|---|---|
| solmane | 6.9, 7.3, 6.8 |
| ashtusk | 6.8, 6.8, 6.7 |
| stormbrush | 6.9, 7.1, 6.6 |
| breezetail | 6.8, 7.0, 6.9 |
| pebbik | 6.9, 7.1, 6.8 |
| stormtrail | 6.8, 7.2, 7.0 |

**Recorded defects:**
- **Stormbrush:** plastic-blue fur and hidden ruler, both FIXED 3/3.
- **Pebbik and breezetail:** faint reaches the ground, FIXED 3/3.
- **Stormtrail:** placeholder look FIXED 3/3. Faint sheet PARTIAL 2/3, FIXED 1/3.

## Remaining items named (no row reopens on these)
- **Solmane:** the wings fan upright in faint mid and hide the head in faint end (3/3).
- **Stormbrush:** the faint end is "a shapeless fur blob" with no readable face (3/3).
- **Pebbik:** the green lines are faint at small size (3/3).
- **Breezetail:** low value contrast against the stage. The body is about trainer height, though the ears rise above it (1/3).
