# G-things-glidebank: banked glide for Galecrest (F38#15 close-out; GPU High and Medium)

## Verdict: F38#15 does NOT close. The bank reads as a gain, but the steer capture's landed frame sinks the row.
F38#15 stays at 7.70 High and 7.37 Medium (G-f38-15-row, G-medium-f38-15-galeland).

| Set | Base | Arm | Gain | Prefer arm |
|---|---|---|---|---|
| **Row, steer, High** (02-glide in a right turn + 03-landed) | 5.91 | 6.22 | +0.31 | 3/3 |
| **Row, steer, Medium** | 5.96 | 6.22 | +0.26 | 3/3 |
| No-loss, hover, High (original 02-glide + 03-landed) | 6.91 | 7.12 | +0.21 | 2/3 (1 tie) |
| No-loss, hover, Medium | 7.12 | 6.64 | **−0.48** | **0/3** |

1. **The bank works.**
   - On the steer frames all 3 judges prefer the arm's banked glide: "a clearly banked, asymmetric turn, which is the more dynamic read".
   - The recorded defect moves from PRESENT to PARTIAL on the arm's steer glide (3/3).
2. **The steer path's landed frame is the problem, on both sides.**
   - `--glide-steer` lands the bird facing away from the camera: "a hunched mass of dark feathers seen from behind, with the tail sweeping into the trainer ... face and eyes hidden" (3/3).
   - That holds the steer sets at about 6.2, far under the original row frames. On the original framing, the landed bird stands upright, side-on and taller than the trainer, and scored 7.70.
   - The gain is real but small (+0.26 to +0.31). It cannot carry the row while the landed frame reads this way.
3. **The Medium hover loss is the light, not the bank.**
   - Base and arm hover glides are identical (no turn, no bank).
   - All 3 judges name the arm's "warmer, browner haze that flattens the mountains and the creature's whites". The GPU lane measured it: arm Medium top-band sky 181/184/189 against base 173/182/192, with builds about 30 s longer.
   - The landed crest also differs between sides, flared on one and swept on the other (2/3). That is pose timing, not the arm.
   - Formally the arm fails no-loss at Medium. The cause is a capture mismatch, so this is a re-capture, not a park.

## Frames
- **Source:** `tb/gpu-frames-1108`, High and Medium.
  - G-things-glidebank-steer (447df2b26): `--glide-steer`, 02-glide mid right-turn, 03-landed.
  - G-things-glidebank-hover (a0753a6ad): the original hover 02-glide.
- **Capture:** `phase2_capture_realm_flight.gd --biome=meadows --seed=2042`, default carrier Galecrest.
- **Build:** `tb/things` 300f5d4a4 (36° bank) on both sides.
  - **base:** `THINGS-GALELAND/overlay_galewisp_landing.json`.
  - **arm:** that overlay plus `THINGS-GLIDEBANK/overlay_glide_bank.json` (`glide_bank_1112`).
- **Health:** 0 script errors, no flight failures. 4 "double Jump denied" retries were set aside by the GPU lane.
- **Sets:** 02-glide over 03-landed, stacked, with the same brief and recorded defect as the earlier F38#15 batches.
- **Render check:** mean difference steer High 11.6, steer Medium 13.7, hover High 6.5, hover Medium 8.8.
  - By eye: the arm's steer glide rolls into the turn with one wing high, and base stays near level.
  - The Medium arm is visibly hazier.

## Batch `G-gb`
- Three code-blind judges, standard prompt, four candidate sets.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22. This is a confirming batch.
- **Fit:** linear, slope 1.5813, intercept −3.5291, r 0.963, anchor RMSE 0.27. No warnings.

| Set | Base raw | Arm raw |
|---|---|---|
| Steer High | 6.1, 6.0, 5.8 | 6.3, 6.2, 6.0 |
| Steer Medium | 6.2, 6.0, 5.8 | 6.3, 6.2, 6.0 |
| Hover High | 6.6, 6.6, 6.6 | 6.8, 6.8, 6.6 |
| Hover Medium | 6.8, 6.8, 6.6 | 6.5, 6.4, 6.4 |

## What still holds F38#15 (3/3)
1. **The landed read from the steer heading.** The judges' top change (3/3): a landed pose seen front or three-quarter, folded-wing perch, tail lifted, face visible, and a settle frame.
2. **Grey haze and a flat, smeared olive plain under the glide.** It gives little sense of altitude.
3. **Weak value separation** of the dark mantle against the grass when landed, and no rim light.

## Next
1. **Keep the bank.** It is a scene/data flag and it earns 3/3 on the turn.
2. **Re-capture the row on the original landing heading:**
   - Bank the glide on the original path, or end the steer turn back on the original heading, so 03-landed shows the side-on standing bird again. Re-judge on High and Medium.
   - This lane changes no camera; the capture path is the GPU lane's and LANE-THINGS's call.
3. **Re-capture the Medium hover pair** with matched time of day (sky within about 2 L) before using it as a no-loss check.
