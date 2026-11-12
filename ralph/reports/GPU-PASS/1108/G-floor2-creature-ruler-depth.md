# G-floor2-creature-ruler-depth: creature subject staged beside the trainer (F38#5, F38#26, F38#31; GPU High)

Frames: `tb/gpu-frames-1108` f7ad234a1, High, seed 2042, 15 pairs.
- base = `tb/floor2` 06ddb072a, with `creature_ruler_depth` off: the subject stands 7.3–8.5 m beyond the trainer.
- arm = base + `FLOOR2-STAGE/overlay_ruler_depth.json`, with `creature_ruler_depth` on: the subject stands 2.0–3.6 m beside the trainer.
- This is a capture-staging change only: the pose stage in `phase2_capture_creatures.gd`.

The GPU lane held back five arm frames, cut by a frame edge or covering the trainer: brooktail fainted, mosshell alpha_idle, and three aquaryn frames.

Sheets, base against arm (frame lists in `yardstick_g_rd/frames.json`):

| Row | Brief | Frames |
|---|---|---|
| F38#5 | normal creature scale | bramblebun, brooktail, pipwing and trailpup idle |
| F38#26 | creature ground contact | mosshell idle; bramblebun, pipwing and trailpup fainted |
| F38#31 | alpha rarity read | brooktail and trailpup, each normal idle beside its alpha_idle |
| No-loss | F38#5 brief | galewisp idle and hurt (Cloudreach); sparkit idle and hurt (Stormwood) |

Render check: 10–18% of pixels changed on the Meadows frames, 3.5–5% on the no-loss frames. Blank frames: 0 of 15 per side.

Batch `G-rd`:
- three code-blind judges, standard prompt, each row on its own catalogue brief;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.

Fit: linear, slope 1.3073, intercept −1.4788, r 0.951, anchor RMSE 0.43. No warnings.

(A first launch of this batch was stopped before any verdict and rebuilt so F38#31 shows each alpha beside its normal form, per the coordinator's brief; no scores came from it.)

## Verdict: SHIP. Every row gains, 3/3 prefer the arm on every row, and the no-loss controls gain.

| Row | Base | Arm | Gain | Judges preferring arm | Board |
|---|---|---|---|---|---|
| F38#5 normal creature scale | 5.62 | **7.45** | **+1.83** | 3/3 | 5.86 |
| F38#31 alpha rarity read | 5.84 | **7.28** | **+1.44** | 3/3 | 5.85 |
| F38#26 creature ground contact | 5.41 | **6.80** | **+1.39** | 3/3 | 5.91 |
| No-loss (galewisp, sparkit) | 5.36 | 6.97 | +1.61 | 3/3 | — |

Raw Bar A, base → arm (judges a, b, c):
- F38#5: 5.2, 5.5, 5.6 → 6.7, 6.8, 7.0. Mapped arm 7.28, 7.41, 7.67.
- F38#31: 5.6, 5.6, 5.6 → 6.5, 6.8, 6.8.
- F38#26: 5.3, 5.4, 5.1 → 6.4, 6.4, 6.2.
- No-loss: 5.2, 5.5, 5.0 → 6.6, 6.5, 6.3.

No mapped score is above the top anchor.

### Recorded defects
- **F38#5:** base PRESENT 3/3. Arm FIXED 2/3, PARTIAL 1/3.
- **F38#26:** base PRESENT 3/3. Arm PARTIAL 3/3: grass still covers the turtle's lower legs and the hare's flank.
- **F38#31:** base PRESENT 3/3. Arm PARTIAL 3/3: alphas now tower over the trainer, but the alpha cue is still size plus generic gold or beige motes, with no distinct alpha trait.
- **No-loss:** base PRESENT 3/3. Arm PARTIAL 3/3: sparkit idle comes to about the trainer's shoulder, and its hurt crouch sits lower still.

## Caveats for the coordinator
1. **Perspective helps the arm's scale read.**
   - In the arm frames the subject stands nearer the camera than the trainer, as well as beside him.
   - Judge b (F38#5): "taller than the trainer, partly helped by standing closer to the camera". Judge a (no-loss): "much of that is perspective".
   - The gain is real: all three judges say the base pushes subjects so far back they are barely readable. But the F38#5 scale verdict is a read through perspective, not a measurement.
   - A stand that places the subject on the trainer's own depth plane would settle it. All three judges name this as their top change.
2. **This changes the rows' fixed camera set.** It is a capture change, not a game change, so it closes rows only if the coordinator accepts the new staging as each row's camera set.
3. **Close-out:**
   - F38#5 sits at 7.45, 0.05 under the bar, with judge c at 7.67. The close-out exception fits: one more near-bar change, then confirm at High, then Medium.
   - F38#31 sits at 7.28 and needs a distinct alpha trait. Judges call this new_art or scene (rim light, aura, ground marker).
   - F38#26 sits at 6.80 and needs grass cleared or thinned at creatures' feet.
   - Medium is not captured; per the 31 Oct order it runs only once High reaches 7.5.

## What the judges ask for next
1. **Stage on the trainer's depth plane.** Put scale and contact views side by side with the trainer, with short or cleared grass at the feet, and add rim light so dark creatures (the Mirejaw, sparkit on Stormwood moss) separate from the ground.
2. **Give alphas a distinct trait** beyond size and motes: stronger elemental markings, a mane or plates, a ground marker.
