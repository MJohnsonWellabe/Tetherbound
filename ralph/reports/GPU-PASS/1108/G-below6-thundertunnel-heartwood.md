# G-below6: Thundertunnel coat (F36#80) and Stormheart heartwood (F41#1), GPU High

**Frames:** `tb/gpu-frames-1108`, both on `tb/below6` cbc867f80, High.
- **G-below6-thundertunnel-coat** (050a6fbab): hit and faint 000–100.
  - Base: pink-tan mole with warm white cracks.
  - Arm (`below6_floor_thundertunnel`): grey-brown mole velvet with thin cool blue-white storm lines.
  - Crop 560,200 1000×640; tiles standing, hit 050, faint 050, faint 100.
- **G-below6-heartwood** (b1b75f1af): `phase2_capture_locations.gd`, stormheart_tree and dynamo_core, day, approach and close.
  - Arm (`heartwood_1111`): a Blender heartwood, a blue-white crystal core caged in bark roots, in place of the white zig-zag strokes.
  - Judged twice: as the row (four frames, 2×2) and as close-only (two frames stacked full size).
- Blank frames: 0 of 10 and 0 of 4 per side. Pixels changed: thundertunnel 4.3%, heartwood row 7.3%, close 14.0%.
- Recorded defects are as given by the coordinator.

**Batch `G-hw`:**
- Three code-blind judges, standard prompt.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22. This is a confirming batch.
- **Fit:** slope 1.4574, intercept −2.0207, r 0.991, RMSE 0.134. No warnings.

## Verdict: BOTH SHIP (3/3 on every set, no loss)

| Set | Base | Arm | Gain | Prefer arm | Raw base → arm (a, b, c) |
|---|---|---|---|---|---|
| **F36#80 Thundertunnel** | 4.63 | **6.04** | **+1.41** | 3/3 | 4.5, 4.6, 4.6 → 5.6, 5.4, 5.6 |
| **F41#1 Stormheart, row (4 frames)** | 4.29 | **5.66** | **+1.37** | 3/3 | 4.2, 4.3, 4.5 → 5.1, 5.3, 5.4 |
| F41#1 Stormheart, close only (2 frames) | 4.39 | 5.95 | +1.56 | 3/3 | 4.3, 4.2, 4.7 → 5.3, 5.3, 5.8 |

**Base vs board:** base here is lower than the board (thundertunnel 5.92 in G-things-t4-rescore; F41#1 5.78) because the batches differ in scale. Read the paired gains.

**Thundertunnel moves out of the below-6 band (6.04).** Recorded defects:

| Defect | Base | Arm |
|---|---|---|
| "flat pinkish-tan flesh" | PRESENT 3/3 | FIXED 3/3 |
| "cracks read as mud fissures or decals" | PRESENT 3/3 | PARTIAL 3/3 |
| "faceless ball faint" | PRESENT 3/3 | PRESENT 3/3 |

- Remaining on the arm: the lines are still "uniform white decals with no glow" (3/3), the hit is barely distinct from standing, and the eye is a small cartoon dot (1/3).
- Next asks: emissive veins on the dark fur, and a faint end with the head turned out of the curl.

**Stormheart:**

| Defect | Base | Arm |
|---|---|---|
| "flat white lightning strokes" | PRESENT 3/3 | FIXED 2/3, PARTIAL 1/3 |
| "no core or crown in view" | PRESENT 3/3 | PARTIAL 3/3 |

- The arm's split-root glowing core "reads as a power source in a tree"; judge c calls it "the strongest storm read in the batch".
- Remaining: it is "a fairly flat gradient slab" with hard edges and no bloom falloff, and the crown is never in view.
- **Close-only (5.95) vs row (5.66):** the two approach views (identical on both sides) hold the row down by about 0.3.
  - Both approach views are a flat bark wall filling the frame, with an orange wood-grain slab at the left edge that reads as an untextured placeholder (3/3).
  - This is the stand issue the GPU lane noted, and it is unchanged by the arm.
- Judges also note no storm sky in any frame, and a mauve-pink grade instead of the board's purple.

## Recommendation
1. **Land both arms.**
2. **Next swings:**
   - **F41#1:** fix the approach stands so the crown and core read together against a storm sky (staging, about +0.3 by the close-only gap). Give the core internal arcs, bloom and light cast onto the bark.
   - **F36#80:** glowing veins and a faint that keeps the head out of the curl.

**Owner rules:**
- No oxblood. The red is on Team Tether elements only.
- The orange slab at the Stormheart approach is wood-grain orange, not red.
- Thundertunnel is taller than the trainer (3/3).
