# Game-clip re-scores: F36#92 Water Mangrove Monitor and F36#94 Water Mosshell (GPU High, one-sided)

These are the corrected base scores for two water rows on the game-resolved clips (`tb/things` 5cb2084c3, flags off). They complete part (2) of `G-things-faint.md`.

**Inputs:**
- **#92 frames:** `G-things-faint` (c7479c87e), base side. Its arm equals base: the row is excluded from the faint overlay.
- **#94 frames:** `G-water-mosshell-gameclips-rescore` (187ca7863), 20 frames (hit, faint, ride, swim). Blank frames: 0 of 20.
- **Sets:** crop 560,200 1000×640, F36 (1) brief.
  - #92 tiles: standing, hit 050, faint 050, faint 100.
  - #94 tiles: standing, hit 050, ride 050, faint 050, faint 100, swim 050.
- **Anchors:** craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22. Both are confirming batches; three fresh code-blind judges each; standard prompt.

| Batch | Fit |
|---|---|
| G-wmm | slope 1.152, intercept −0.5347, r 0.920, RMSE 0.390 |
| G-wms | slope 1.2993, intercept −1.2705, r 0.966, RMSE 0.256 |

## Results

| Row | Earlier (raw clip) | Game clip (mapped) | Raw a, b, c |
|---|---|---|---|
| **F36#92 Water Mangrove Monitor** | 6.26 | **6.72** | 6.5, 6.2, 6.2 |
| **F36#94 Water Mosshell** | 5.81 | **6.09** | 5.8, 5.4, 5.8 |

## What the judges say

**#92 Water Mangrove Monitor:**
- **Faint:** "the faint does not reach the ground" is FIXED 3/3. But the faint end lies belly-up with the forelimbs in the air (3/3), which "reads as a dead or flipped lizard". Faint mid is still half raised (3/3).
- **Value:** the dark olive back on the grey stage is PARTIAL 2/3, PRESENT 1/3.
- **Face:** crest spines crowd the face (PARTIAL 3/3).
- **Water trait:** no visible water trait, only a faint teal streak on the head (3/3).
- **Ask:** limbs folded under in the faint, a lifted dorsal value, and a bioluminescent marking.

**#94 Water Mosshell:**
- **Hit and faint:** hit reads, and faint end is a shell withdraw: "faint poses do not collapse" PARTIAL 3/3. Faint mid is still upright (3/3).
- **Ride (PRESENT 3/3):** the ride is unchanged. "The turtle is flipped onto its back and the trainer floats well above it."
- **Swim (3/3):** the trainer stands on the water surface, and the turtle is a translucent ghost under a flat blue plane.
- **Water trait:** none visible (3/3).
- **Scale:** level with the trainer, not clearly taller (judge a).
- **Model:** the standing model is "a convincing realistic tortoise", at the style bar (3/3).
- **The ride and swim arm is the swing for this row.**

**Owner rules:**
- No red on either creature.
- Water Mosshell's height is borderline (1/3).
