# G-below6-swim-sea-r5: swim pose round 5 (F39#5, F39#14) and restored sea round 5 (F39#17) (LANE-BELOW6; GPU High)

## Verdicts

| Arm | Set | Base | Arm | Gain | Prefer arm | Verdict |
|---|---|---|---|---|---|---|
| swim r5 | **F39#5 row** (entry, surface_west, surface_mid) | 5.45 | **5.98** | **+0.53** | 3/3 | **SHIP**, with the confound below |
| swim r5 | **F39#14 row** (same frames, water contact) | 5.74 | **6.12** | +0.38 | 3/3 | |
| swim r5 | F39#5 other frames (surface_east, surface_far, dry exit) | 6.70 | 6.41 | −0.29 | 0/3 | capture confound, not the arm |
| restored sea r5 | **F39#17 row** (S1/S2 live and restored) | 6.08 | **6.27** | +0.19 | 2/3 | **SHIP** |
| restored sea r5 | F39#17 other stands (S3/S4 restored) | 5.98 | 6.08 | +0.10 | 2/3 | no loss |

## Swim r5: the pose works; the losing set is the shore creature
- **The arm fixes what it targets.**
  - "Arms spread at the surface ... closer to swimming than wading" (3/3).
  - The F39#5 recorded defect is PARTIAL on the arm 3/3. On base it is PRESENT 2/3 ("a head bobbing upright with a boot spot behind it").
  - F39#5 rises 5.45 → 5.98, just under the 6 floor. F39#14 clears 6 (5.74 → 6.12).
- **Why the no-loss set drops: a capture confound.**
  - The creature on the shore differs between the two runs in every swim frame. Base has the blue armoured turtle; the arm has the green crocodilian (checked by eye on entry, surface_mid, surface_east and surface_far).
  - All three judges explain the other-frames set by that creature: "B's blue turtle reads better against the sand", "the blue armoured turtle reads strongly in the water board's palette", "B's turtle is stronger".
  - The dry-exit frame is pixel-identical (difference 0.0), and the trainer's swim frames differ only at the body.
- **The confound runs against the arm in the row too.** The arm carries the weaker crocodile in the row frames and still gains +0.53 3/3. So the pose gain is, if anything, understated.
- **Ruling.**
  - Read strictly, the ship rule fails here: one judged set loses.
  - I rule it SHIP because the loss is the follower creature's position at capture time, not the overlay. The overlay only changes the trainer's arm pose.
  - If the coordinator wants a clean read, recapture surface_east and surface_far with the shore creature pinned. That is one short GPU piece and needs no new arm.
- **What still holds both rows (3/3):**
  - The boots still show as dark blobs behind the head. The judges ask for a horizontal body with legs hidden below the surface (new art: a real swim pose or stroke cycle).
  - The wake foam has a radial pinwheel seam at its centre in surface_west (both sides). F39#14's "hard dark shadow" reads as those boot blobs.
  - The near-camera water is a soft, low-resolution smear (2/3).

## Restored sea r5: the restoration reads again, modestly
- **The row gains 2/3.** In the arm's restored frames the deep channel turns navy and "foam rings surround each sandbar ... a diagonal flow streak crosses the water". The recorded defect is PARTIAL on the arm 3/3 and PRESENT on base 3/3.
  - Round 4 lost this read (−0.03). Round 5 brings back round 1's deeper water.
- **The dissent (judge c, base by 0.4).** The rings "look like a shader seam rather than authored shallows", flat concentric bands. Judges a and b also call them "flat, uniform rings" that "look generated" (2/3 total). This is the next lever: the rings need break-up, with irregular surf and foam lanes along the sandbars.
- **No loss on S3/S4.** +0.10, 2/3. The sunset still has the blown vertical sun-glare column and near-black left water on both sides (3/3).
- **Colour flag.** Base's restored S1 and sunset frames show "a dark red-brown clump" mid-water that "leans toward oxblood" (2/3; judge c calls it brown debris). On the arm those frames read as small creatures in the water instead (2/3). Worth one look by LANE-BELOW6 or PLACES at what the object is: red is Team Tether only.
- **Shared, both sides:**
  - a hard navy/cyan diagonal edge reads as a shading seam (judge b; the r4 report's "dark wedge");
  - flat sand-disc islands with sparse, even scatter (3/3).

## Pooled current-main lines
- **F39#17:** two base panels on unchanged sea code, 6.26 (G-below6-sea-r4-stronghold) and 6.08 (this batch), pool to ≈ 6.17 at High. The arm's 6.27 is evidence of the gain, not yet the row score.
- **F39#5 and F39#14:** no earlier GPU panel of these frames is on main; this batch's bases (5.45, 5.74) are the current-main reads.

## Frames
- **Sources:** `tb/gpu-frames-1108`, High, `--fixed-fps 20`.
  - `G-below6-swim-r5` (5f025653b): `tb/below6` 2d35377bc both sides. base: no overlay; arm: `BELOW6-SWIM/overlay.json` (surface_crawl_1112, arms swept sideways at the waterline). 7 frames per side.
  - `G-below6-restored-sea-r5` (15076fecf): `tb/below6` e4a71f5df both sides. base: no overlay; arm: `BELOW6-RESTORED-SEA/overlay.json`. Four stands, live and restored, t0/t1; 32 frames.
- **Health:** 0 script errors, 0 blank frames. The sky flag on the S2 restored arm frames was bypassed by the GPU lane after an eye check.
- **GPU lane pre-checks:**
  - **Swim:** no hand above the head at entry or surface_mid.
  - **Sea:** S4 sunset black share 69.7% → 43.9%. Day restored is a deep, calm channel (S1 L 57 → 41, S2 71 → 46) with surf rings.
- **Render check:**
  - **Swim:** 0.0–1.1 mean per frame. The trainer is small in frame; by eye the arms sweep sideways at the waterline in every swim frame.
  - **Sea:** live frames 0.0–0.3 (identical); restored S1 13.2, S2 17.1, S3 3.7, S4 7.5.
- **Sets:**
  - F39#5 and F39#14 use each row's job.json frames, stacked.
  - F39#17 uses a 2×2 grid as in round 4: S1 live t0, S1 restored t0, S2 live t0, S2 restored t0. The other-stands set is S3 and S4 restored t0/t1.

## Batch `G-b5`
- Three code-blind judges, standard prompt, five candidate sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.441, intercept −1.994, r 0.912, anchor RMSE 0.57. No warnings.
- Yardstick: `yardstick_g_below6_swim_sea_r5/`.

**Raw Bar A and mapped arm, per judge:**

| Set | Base (a, b, c) | Arm (a, b, c) | Arm mapped (a, b, c) |
|---|---|---|---|
| F39#5 row | 5.1, 4.9, 5.5 | 5.5, 5.3, 5.8 | 5.93, 5.64, 6.37 |
| F39#14 row | 5.2, 5.4, 5.5 | 5.5, 5.6, 5.8 | 5.93, 6.08, 6.37 |
| F39#5 other frames | 5.9, 6.1, 6.1 | 5.6, 6.0, 5.9 | 6.08, 6.65, 6.51 |
| F39#17 row | 5.5, 5.6, 5.7 | 6.0, 5.9, 5.3 | 6.65, 6.51, 5.64 |
| F39#17 other stands | 5.3, 5.7, 5.6 | 5.6, 5.8, 5.4 | 6.08, 6.37, 5.79 |

Bar B: no on every candidate set (3/3).
