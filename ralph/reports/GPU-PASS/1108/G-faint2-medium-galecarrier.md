# G-faint2-medium-galecarrier: pebbik and breezetail faint at Medium (close-outs), and the galewisp flight carrier (GPU)

## Verdicts
- **F36#58 pebbik and F36#35 breezetail CLOSE.** Both now score 7.5 or above at High and at Medium.
- **The galewisp carrier SHIPS.** Flight scores rise from 6.17 to 6.83 (+0.66), and all three judges prefer the arm.

## Frames
All on `tb/gpu-frames-1108`.
- **`G-faint2-pebbik-breezetail-medium` (6cf29c52b):** Medium, arm only, from `tb/things` a90645724 with the THINGS-FAINT2 overlay. Captured with `capture_f36_poses.gd --whole-body --context --clear-ruler --roles=hit,faint`.
- **`G-galecarrier-flight` (138592fa3):** High, Meadows realm flight, three frames: launch, glide, landed.
  - **base:** overlay off. The trainer is carried by the old fox-bird.
  - **arm:** `overlay_galewisp_carrier.json`. The flight carrier is the 1 Nov galewisp remake, an owl-griffin gripping with foot_l and foot_r.
  - The arm tool logged "double Jump denied" but wrote all three frames.
- **`G-galecarrier-poses` (51fbc23df):** identical on both sides, because the pose stage already uses the remake. Not judged.

**Render check:** 0 blank frames. The flight sheets differ by a mean of 10.5 between sides.

## Sets
- **Pebbik and breezetail:** same format as `G-things-faint2.md`.
  - Crop: 560,200 1000×640.
  - Tiles: standing, hit 050, faint 050, faint 100.
  - Brief: the F36 (1) brief.
  - Recorded defect: the faint-grounding defect.
- **Galewisp:** the three flight frames in a 2×2, with the fourth tile empty.
  - Brief: "the creature carrying the 1.80 m trainer in flight (fly-grip)".
  - Recorded defect: "carrying frame carries nothing".

## Batch `G-w1`
- Three code-blind judges, standard prompt.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22.
- **Fit:** linear, slope 0.9924, intercept 0.5783, r 0.926, anchor RMSE 0.375.
- **Warning:** pebbik and breezetail meet the bar only above the top anchor. The batch's anchors reach 7.35 or more, so this is the confirming batch.

## Results

| Row | High (`G-f2a`) | **Medium (`G-w1`)** | Raw a, b, c | Mapped per judge | Result |
|---|---|---|---|---|---|
| **F36#58 pebbik** | 7.65 ↑top | **7.56** ↑top | 7.0, 7.0, 7.1 | 7.53, 7.53, 7.62 | **CLOSES** (every judge ≥7.5) |
| **F36#35 breezetail** | 7.61 ↑top | **7.56** ↑top | 6.9, 7.0, 7.2 | 7.43, 7.53, 7.72 | **CLOSES** (mean ≥7.5; judge a at 7.43) |

- **Recorded faint defect:** FIXED 3/3 on both.
- **Bar B:**
  - pebbik: yes 2/3. Judges call it a "lean realistic coyote ... near the Tanglevolt bar".
  - breezetail: yes 1/3.
- **Remaining notes, not blocking:**
  - Pebbik's green lines are too faint to read at 30% size (3/3).
  - Breezetail's ice-blue coat is low in value contrast on the grey stage, and its elemental trait reads weakly (2/3).

| Set | Base raw → mapped | Arm raw → mapped | Gain | Prefer arm | "Carries nothing" (base / arm) |
|---|---|---|---|---|---|
| galewisp flight carrier | 5.6, 5.5, 5.8 → 6.17 | 6.3, 6.3, 6.3 → **6.83** | **+0.66** | 3/3 | FIXED/PARTIAL/FIXED → FIXED/PARTIAL/FIXED |

### Galewisp: what the judges say
- **The arm carrier (3/3):** "a naturalistic owl-griffin" with "white and pale-blue plumage", "closer to the realistic-with-fantasy target". The trainer hangs beneath it in launch and glide.
- **The base carrier (3/3):** "big-eyed mascot ... oversized ears, chibi-like face and thin bat-like wings", and "off the owner's creature target". Two judges also call its wings undersized for the trainer.
- **Still wrong on the arm:**
  - The talon grip is too small to read as a grip. The trainer "looks dangled rather than held" (judges a and b).
  - In the landing frame the creature is "half hidden behind the trainer and a flat foreground bush and looks barely taller than him" (3/3). Base's landing frame was better composed.
  - Behind the flight there is only a flat fog plane, a hazy olive plain and grey mountain cards, with no depth layers (3/3).
- **Board row:** the galewisp pose-stage row stays at 7.44, because its pose captures do not change. This arm only changes the flight carrier, which affects the flight look and the F36 (1) fly-grip read.

## Recommendation
1. **Close F36#58 and F36#35.**
2. **Land the galewisp carrier overlay.**
3. **Next for galewisp:**
   - Show a visible talon clasp on the trainer's shoulders or harness.
   - Restage the landing so the creature stands clear of the trainer and the bush.
