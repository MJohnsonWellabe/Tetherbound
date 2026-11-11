# G-newapproach-fly-grip: elbow-bend hang pose, arm A (F38#8; GPU High)

Frames: `tb/gpu-frames-1108` f98199652, High, seed 2042, `phase2_capture_realm_flight.gd --biome=meadows`.
- base = main e1c941cbd as is.
- arm A = base + `tb/newapproach` 6ee6f3b0c `NEWAPPROACH-FLYGRIP2/overlay_elbow_bend.json`: hang_pose upper_lateral 2.2, forearm_lateral −0.25, body on.
- Arm B (shoulder grip, 268dc208d) failed the GPU lane's pre-check. It is a diagnostic only and was not judged; marked seen.

Sheet, base against arm A: `meadows__flying__launch` (01-launch) above `__glide` (02-glide), full-size frames stacked. The sheet holds no control frame; the section has none.

Render check: 8.9% of pixels changed on launch, 8.6% on glide. Blank frames: 0 of 2 per side.

Batch `G-fg`:
- three code-blind judges, standard prompt, F38#8 brief and recorded defect;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.

Fit: linear, slope 1.4615, intercept −2.3625, r 0.928, anchor RMSE 0.516. No warnings.

## Verdict: SHIP arm A. +0.88, 3/3 prefer.

| Row | Base | Arm A | Gain | Judges preferring arm | Board |
|---|---|---|---|---|---|
| F38#8 Fly carrier grip pose | 6.26 | **7.14** | **+0.88** | **3/3** | 5.46 |

Raw Bar A, base → arm (judges a, b, c):
- 6.2, 5.9, 5.6 → 6.7, 6.5, 6.3.
- Mapped arm: 7.43, 7.14, 6.85. Not above the top anchor.

Recorded defect: base PRESENT 3/3; arm A PARTIAL 3/3.

Against the board's 5.46, the arm takes F38#8 above 7. The base here maps 6.26, higher than the board. That gap is scale scatter between batches; read the paired gain.

At 7.14, F38#8 is a close-out candidate under the 25 Oct exception. Medium is not captured; per the 31 Oct order it runs only once High reaches 7.5.

## What the judges see
- **Arm A:**
  - The trainer's knees are bent and tucked, with legs swung back and the body drawn up under the talons and slightly angled. The hands wrap into the talons.
  - It reads "more like being carried" (3/3).
- **Arm A, what remains:** the arms are still raised straight to the talons, so the bird still partly reads as perched on the hands. There is no lean or swing (3/3).
- **Base:** the trainer hangs "fully rigid like a pinned doll", with straight raised arms and straight dangling legs.
- **Galecrest is on the owner's style bar on both sides:** raptor silhouette, clear head and eye, a good dark-wing and pale-chest value split. It is clearly larger than the trainer.
- **The drag on both sides is the staging below:**
  - a flat, hazy olive meadow with one tree clump;
  - fog-flattened grey cut-out mountains;
  - no motion cue (wind, wing bend or trail).

## What would add the most (judges' top change for this set)
1. **Carry pose:**
   - bent gripping elbows instead of straight raised arms;
   - a forward lean;
   - a slight swing of the trailing legs.
   - Judges a and c call this new_art (an authored carry pose); judge b calls it scene (a pose retune).
   - Judges a and b also suggest gripping at the shoulders or harness. That is the idea arm B tried, and it failed the pre-check.
2. **Ground under flight:** more groves and less fog, so the glide frame has depth.
