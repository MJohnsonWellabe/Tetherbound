# G-confirm-75 Medium + G-occlusion-fade-off

Frames: `tb/gpu-frames-1108` d1a5304d. The manifests are `G-confirm-75-ghostglow-medium` (live on main d9d79ff93, Medium) and `G-occlusion-fade-off` (High; live is main d9d79ff93, arm is live plus `COORDINATOR/overlays/occlusion_fade_off`).

Batch `G-med-occl`:
- One batch with three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so the top anchor is 7.35 and this is a **confirming batch**.
- Fit: linear, slope 1.4468, intercept −2.172, r 0.912, anchor RMSE 0.474 (6 points).
- Calibrate warning: F40#12 meets the bar only above the top anchor. This batch's anchors reach 7.35, so it is the confirming batch.

## Confirm-75 at Medium (one-sided)

| Row | Item | Raw (j1, j2, j3) | Mapped judges | **Mapped Medium** | High (G-confirm-75) | Verdict |
|---|---|---|---|---|---|---|
| F40#12 | Cloudreach dialogue speaker | 6.85, 6.8, 6.6 | 7.74, 7.67, 7.38 | **7.59** | 7.73 | **CLOSES: ≥7.5 on High and Medium** (both from confirming batches) |
| F38#28 | Warden arena boundary | 6.4, 6.4, 6.2 | 7.09, 7.09, 6.80 | **6.99** | 7.54 | open (Medium 0.51 short) |
| F41#17 | Crown Arch | 6.2, 6.3, 5.6 | 6.80, 6.94, 5.93 | **6.56** | 7.13 | open |

Remaining F38#28 defects at Medium, from all three judges:
- The thin cyan floor arc still reads as a guide line under the creatures (PARTIAL 3/3).
- The frame-3 dust burst is a ring of flat, white, blobby billboard puffs over Terrapup (3/3).
- A red banner hangs on the arena wall (3/3 flagged against the oxblood reserve).

At High the same arc was marked FIXED. Medium shows it more strongly.

F41#17 defects, all three judges:
- A hard-edged square plinth on the black pool.
- Uniform, unweathered lilac stone.
- Pink-salmon background bears.
- Needle-like rain streaks.

## Occlusion-fade-off arm (live vs arm, High)

Ship rule: mapped gain > 0 and ≥2/3 judges prefer the arm.

| Row | Item | Live mapped | Arm mapped | Gain | Judges preferring arm | Ship |
|---|---|---|---|---|---|---|
| F39#18 | Tidewake dialogue camera framing | 6.85 | 6.75 | −0.10 | 0/3 (1 tie) | no |
| F39#26 | Tidewake dialogue foreground obstruction | 6.51 | 6.85 | +0.34 | 2/3 (1 tie) | **yes** |
| F39#29 | Tidewake speaker visibility | 5.59 | 5.98 | +0.39 | 3/3 | **yes** |

Raw scores (j1, j2, j3), live → arm:
- F39#18: 6.6, 6.3, 5.8 → 6.5, 6.3, 5.7.
- F39#26: 6.1, 5.9, 6.0 → 6.5, 6.2, 6.0.
- F39#29: 5.8, 5.3, 5.0 → 6.0, 5.6, 5.3.

The arm passes the ship rule on two of three rows, mean +0.21. The gain comes from the player's head and back covering the speaker less; the judges name Adair, Nerissa and Rowan.

**The speakers are still ghosted on both sides.** All three judges describe the Tidewake speakers (Bex, Daro, Irva, Nalia, Adair, Iona, Rowan) as washed out and see-through on live *and* arm. Turning occlusion fade off does **not** remove the NPC ghosting, so `fade_transparency` is ruled out as its cause. All three judges' top change is "render dialogue speakers fully opaque and lit". The ghosting is the largest remaining loss on F39#18, #26 and #29, and also shows faintly on F40#12 (judge a: "slightly hazy").

Remaining suspects on the NPC path, not yet tested on GPU:
- Material transparency or alpha mode on the speaker meshes.
- Day-rim or fresnel strength on Tidewake NPCs.
- Tidewake fog or exposure acting on mid-distance characters.

Nerissa's frames also stage the speaker small, far down a dark chamber (Wp, 3/3).
