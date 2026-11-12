# G-floor2-creature-ruler-depth-r3-medium: F38#5 Medium close-out

Frames: `tb/gpu-frames-1108` aaec05df8, **Medium**, `tb/floor2` aac9c84a3, seed 2042.
- Capture: `phase2_capture_creatures.gd --biome=meadows --only=bramblebun,pipwing,brooktail,trailpup --poses=idle`.
- base = `creature_ruler_depth` off (subject 7.3–7.5 m from the trainer).
- arm = base + `FLOOR2-STAGE/overlay_ruler_depth.json`, identical to the High arm in `G-floor2-creature-ruler-depth-r3.md`.
- Arm readout: contact 0.02 m behind the trainer's feet on all four frames; all in frame, no trainer overlap.

Sheet: the same four Meadows idle frames as the F38#5 set at High, in a 2×2 grid, on F38#5's brief and recorded defect.

Render check: 8–11% of pixels changed. Blank frames: 0 of 4 per side.

Batch `G-rd3m`:
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.
- The yardstick holds no Medium-specific anchors, so the standard anchor set was used, as for every Medium verdict so far.

Fit: linear, slope 1.3901, intercept −1.8391, r 0.926, anchor RMSE 0.521.

Warning, verbatim: "meets the bar only above the top anchor (7.53): F38#5 arm; extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch".

## Verdict: F38#5 Medium = 7.71. CLOSES (High 7.77, Medium 7.71, both at or above 7.5)

| | Base | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| F38#5 normal creature scale, Medium | 6.27 | **7.71** | +1.44 | 3/3 |

Raw Bar A, base → arm (judges a, b, c): 5.8, 6.0, 5.7 → 6.7, 7.1, 6.8.

Mapped arm: 7.47, 8.03, 7.61. The mean is 7.71; judge a alone sits at 7.47.

| | High (`G-rd3`) | Medium (this batch) |
|---|---|---|
| F38#5 arm, mapped | 7.77 | 7.71 |
| Confirming batch | yes | yes |

**F38#5 meets the close bar:** a mapped 7.5 or above on both High and Medium, per the 31 Oct order.

Recorded defect, "several normal creatures read visibly shorter than the trainer":
- base: PRESENT 3/3;
- arm: FIXED for judge b; PARTIAL for judges a and c.
  - Judge a: the owl and coyote read "about trainer height, though the depth offset makes this ambiguous".
  - Judge c: "the coyote is about trainer height".
- The score clears the bar, but two judges still see the owl and coyote as only marginally taller.

## What the judges still name (not blocking the close)
- **Owl:**
  - leans mascot, with oversized eyes and a puffy body (judges a and c);
  - judge a calls a realistic adult-owl remake new_art.
- **Hare:** the grey plating is low-contrast against the dark grass.
- **Dark panther:** sinks into the tree line (judge b).
- **Contact:** weak contact shadows; feet poorly grounded in the grass (judges a and c).
- **Meadows backdrop:** a uniform grass carpet with flat, evenly spaced "lollipop" trees (3/3).
