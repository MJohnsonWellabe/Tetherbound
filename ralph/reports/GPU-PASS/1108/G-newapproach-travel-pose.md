# G-newapproach-travel-pose: capture-stage fix for ride, swim and fly-grip (F36#94 Water Mosshell, F36#48 Galewisp; GPU High)

**Frames:** `tb/gpu-frames-1108` eccd101c5, High. Both sides were captured in one session on main 3a514ef5c with `--species=water_mosshell,galewisp --whole-body --context`.
- **base:** main's `capture_f36_poses.gd`.
- **arm:** that tool from `tb/newapproach` 1833b8a9c. It fixes three capture-stage faults:
  - the faint clip's pivot leaking into ride and swim;
  - the swim ruler standing on the water;
  - fly-grip never hanging the trainer.
- 35 frames per side; blank frames 0 of 35 per side.

**Sets:** crop 560,200 1000×640, F36 (1) brief.
- **Row sets:**
  - Water Mosshell: standing, hit, ride, faint mid, faint end, swim.
  - Galewisp: standing, hit, fly-grip, faint mid, faint end, fly-grip.
- **Travel-only sets:**
  - Water Mosshell: ride 025 and 075, swim 025 and 075.
  - Galewisp: fly-grip 000, 025, 075 and 100.

**Pixels changed:** row 1.6% and 2.6%; travel 4.8% and 7.4%.

**Batch `G-tp`:**
- Three code-blind judges, standard prompt.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22. This is a confirming batch.
- **Fit:** slope 1.2122, intercept −0.5592, r 0.959, RMSE 0.281.
- **Warning:** "some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)". This applies to the very low base travel sets.

## Verdict: BOTH SHIP (3/3 on every set, no frame loses)

| Set | Base | Arm | Gain | Prefer arm | Raw base → arm (a, b, c) |
|---|---|---|---|---|---|
| **F36#94 Water Mosshell, row** | 4.65 | **6.67** | **+2.02** | 3/3 | 4.0, 4.3, 4.6 → 5.6, 6.0, 6.3 |
| Water Mosshell, travel only | 3.76 | 6.75 | +2.99 | 3/3 | 3.4, 3.5, 3.8 → 5.5, 6.2, 6.4 |
| **F36#48 Galewisp, row** | 6.35 | **7.44** | **+1.09** | 3/3 | 5.1, 6.2, 5.8 → 6.2, 7.0, 6.6 |
| Galewisp, fly-grip only | 5.10 | 6.92 | +1.82 | 3/3 | 4.2, 5.0, 4.8 → 5.8, 6.5, 6.2 |

- **Water Mosshell's base row (4.65) is lower than the game-clip re-score (6.09, `G-water-gameclip-rescores.md`).** Main's capture tool shows the broken ride on the row tile. The arm is above both.
- **Galewisp at 7.44** is a close-out candidate (7.0 or above), 0.06 under the bar.

## Per-role notes (3/3 unless noted)

**Ride, Water Mosshell:**
- **Base:** "a broken, multi-headed folded mesh", upside down, with the trainer floating above it.
- **Arm:** "an intact turtle", upright, with the rider aboard.
- **Remaining ("rider perched" PRESENT 3/3):** the rider sits small and high on the dome apex with "no seat or leg contact".
- **Ask:** seat the rider lower, in a saddle notch or on a flattened shell plateau, with leg contact.

**Swim, Water Mosshell:**
- **Base:** the trainer stands on the water beside a ghostly submerged mesh.
- **Arm:** the shell breaks the waterline and the rider stays on it. "Trainer stands on the water" is FIXED 3/3.

**Fly-grip, Galewisp:**
- **Base:** "the bird hovers while the trainer stands on the ground" in every frame.
- **Arm:** the trainer hangs under the talons in all four moments. "Carries nothing" is FIXED 3/3.
- **Remaining:** the carried trainer is "dark, backlit and partly clipped into the belly feathers", head buried (3/3).
- **Ask:** grip at the shoulders so the whole body hangs visible and lit below the bird.

**Faint, both species:** unchanged by the arm.
- Water Mosshell's faint is a shell withdraw (PARTIAL 3/3).
- Galewisp's faint wing stays clear of the trainer (FIXED 2/3, PARTIAL 1/3).

**Owner rules:** no red on either creature. Both are taller than the trainer.

## Recommendation
1. **Land the capture-tool fix.** It is a capture-stage change only, so these rows' board scores should be re-based on the arm.
2. **Galewisp (7.44):** the next swing is the shoulder grip and lit trainer. That should take it over 7.5; then capture Medium.
3. **Water Mosshell (6.67):** next, the rider seat height and contact, and the faint collapse.
