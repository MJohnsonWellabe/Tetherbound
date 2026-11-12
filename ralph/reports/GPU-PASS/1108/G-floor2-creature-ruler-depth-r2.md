# G-floor2-creature-ruler-depth-r2: creature subject on or behind the trainer's depth plane (F38#5, F38#26, F38#31; GPU High)

Frames: `tb/gpu-frames-1108` 751b0657d, High, seed 2042, 16 pairs, `phase2_capture_creatures.gd`.
- base = `tb/floor2` c46704750 with `creature_ruler_depth` off: the subject stands 7.3–10.0 m from the trainer.
- arm = base + `FLOOR2-STAGE/overlay_ruler_depth.json`. The arm manifests report `depth_vs_trainer_m` 0–5 (on or behind the trainer's plane), `overlaps_trainer` false and `in_frame` true.
- This is capture staging only.

The GPU lane held back two frames: aquaryn fainted (cut at the edge) and galewisp idle (claws below the boots).

Sheets, base against arm (frame lists in `yardstick_g_rd2/frames.json`):

| Set | Brief | Frames |
|---|---|---|
| F38#5 | normal creature scale | bramblebun, brooktail, pipwing and trailpup idle |
| F38#26 | creature ground contact | bramblebun idle, mosshell alpha_idle, brooktail fainted, mosshell fainted |
| F38#31 | alpha rarity read | brooktail and trailpup, each normal idle beside its alpha_idle |
| No-loss A | F38#5 brief | galewisp hurt, sparkit idle, stormraven idle, fulgocobra idle |
| No-loss B | F38#5 brief | aquaryn idle, aquaryn resting, sparkit hurt |

No-loss B has three frames in a 2×2 grid, so its fourth cell is black on both sides. That is the sheet layout, not a missing capture; the judges noted it.

Render check: 13–25% of pixels changed on the Meadows frames, 4–13% on the no-loss frames. Blank frames: 0 of 16 per side.

Batch `G-rd2`:
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.

Fit: linear, slope 1.5562, intercept −3.2077, r 0.952, anchor RMSE 0.425.

Warning, verbatim: "meets the bar only above the top anchor (7.53): F38#5 arm; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch".

## Verdict: SHIP. Every row gains well over 0.5, 3/3 prefer on every set, and both no-loss sets gain.

| Set | Base | Arm | Gain | Judges preferring arm | Round 1 arm | Board |
|---|---|---|---|---|---|---|
| **F38#5** normal creature scale | 5.14 | **8.00** (above top anchor; confirming batch) | **+2.86** | 3/3 | 7.45 | 5.86 |
| F38#31 alpha rarity read | 5.04 | **7.17** | +2.13 | 3/3 | 7.28 | 5.85 |
| F38#26 creature ground contact | 4.88 | **6.39** | +1.51 | 3/3 | 6.80 | 5.91 |
| No-loss A (Cloudreach, Stormwood) | 4.94 | 7.17 | +2.23 | 3/3 | 6.97 | — |
| No-loss B (aquaryn, sparkit hurt) | 5.25 | 6.91 | +1.66 | 3/3 | — | — |

Raw Bar A, base → arm (judges a, b, c):
- F38#5: 5.2, 5.6, 5.3 → 7.3, 7.3, 7.0. Mapped arm 8.15, 8.15, 7.69.
- F38#31: 5.0, 5.7, 5.2 → 6.6, 6.8, 6.6.
- F38#26: 5.3, 5.3, 5.0 → 6.2, 6.4, 5.9.
- No-loss A: 5.0, 5.4, 5.3 → 6.5, 6.9, 6.6.
- No-loss B: 5.4, 5.6, 5.3 → 6.4, 6.7, 6.4.

Recorded defects:
- **F38#5:** base PRESENT 3/3; arm FIXED 3/3.
- **F38#31:** base PRESENT 3/3; arm PARTIAL 3/3.
- **F38#26:** base PRESENT 3/3; arm PARTIAL 3/3.

### F38#5 meets the 7.5 bar at High
- Mapped 8.00, with every judge at 7.69 or above.
- The score is above the top anchor, but this batch includes the f36_0_npc:C1 anchor (7.47/7.53), so it is its own confirming batch.
- Per the 31 Oct order, **F38#5 now needs Medium**: capture the same arm at Medium and judge it. It closes only at 7.5 or above on both High and Medium.
- F38#31 (7.17) and F38#26 (6.39) stay at High only.

## The coordinator's depth question: whether the creature stands nearer the camera than the trainer
The standard prompt takes no added questions, so the judges were not asked. Here is what bears on it.
- **My own read of the Meadows arm sheet (F38#5), before judging:** in all four frames the subject's feet sit clearly lower in frame than the trainer's feet. The hare and the owl in particular are large in frame. In these stills they still read as nearer the camera than the trainer, even though the manifests report depth 0–5 m behind the plane. That matches the GPU lane's own caveat (feet 10–15% of frame height lower, on a hillside falling away to the left). Stills cannot separate the slope from nearness.
- **Judges, unprompted:**
  - judge a on F38#31: the arm's alphas are "visibly bigger and staged nearer the camera";
  - judge b: "the alpha coyote crowds the camera".
  - No judge raised it on F38#5. Round 1's judges had (see `G-floor2-creature-ruler-depth.md`).
- **Implication:** the F38#5 scale read probably still gets some help from perspective in Meadows. The Stormwood and Cloudreach no-loss frames (flat ground) gained similarly (+2.23), with every creature reading taller than the trainer. That suggests the scale fix is not only perspective. A flat Meadows stand would settle it.

## Round 1 against round 2 (different base frames, so compare gains, not levels)
- **F38#5:** gain +1.83 → +2.86.
- **F38#31:** gain +1.44 → +2.13.
- **F38#26:** gain +1.39 → +1.51.
- No row lost ground.

## What the judges flag on the arm
- **Mosshell alpha_idle (F38#26, frame 2):** a bright yellow-white fringe or halo around the shell and head, read as "a rendering error" (3/3). This is new to this round's frames. Check whether it is the alpha mote or rim effect at close range.
- **F38#26:** feet still sink into grass. The dark Mirejaw's lower outline is lost in grass and shadow.
- **F38#31:**
  - alphas read mainly by size;
  - the motes are "flat, pale yellow, out-of-focus blobs" (3/3);
  - there is no distinct alpha trait.
- **No-loss A:** the stormraven's and fulgocobra's charged_1105 glow blooms over the whole silhouette when close (3/3). This is the same finding as the F41#13 batches, now visible at close range.
- **Bramblebun:** its plates read as grey armour rather than bark (judge c).
- **Pipwing:** leans chunky, near mascot (judges b and c).

## What would add the most (all scene)
1. **Grass at the feet:** thin or flatten a ring of grass around each staged creature (F38#26).
2. **Alphas:** give them their own look (hardened plates, a distinct aura or a ground effect) instead of blob motes (F38#31).
3. **Mosshell alpha fringe:** fix it.
4. **Electric glow:** cap emissive bloom on the electric creatures to lines and eyes.
