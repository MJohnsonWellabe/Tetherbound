# G-medium-f38-15-galeland: F38#15 Galecrest landing at Medium (GPU)

## Verdict: F38#15 does NOT close. Medium 7.37, 0.13 under the bar.
The arm still wins at Medium (+0.70, 3/3 prefer arm), so the ship rule holds. High stays 7.70 (G-f38-15-row).

| Preset | Base | Arm | Gain | Prefer arm |
|---|---|---|---|---|
| High (G-f38-15-row) | 7.08 | 7.70 | +0.62 | 3/3 |
| **Medium (this batch)** | **6.67** | **7.37** | **+0.70** | **3/3** |

The row closes only at 7.5 or above on both presets. Medium per judge, mapped: 7.60, 7.46, 7.04.

## Frames
- **Source:** `tb/gpu-frames-1108` section `G-medium-f38-15-galeland` (717584748), Medium.
- **Capture:** `phase2_capture_realm_flight.gd --biome=meadows --seed=2042`, default carrier Galecrest.
- **Build:** `tb/things` b628efddf on both sides.
  - **base:** overlay off.
  - **arm:** `THINGS-GALELAND/overlay_galewisp_landing.json`.
- **Row frames:** 02-glide over 03-landed, stacked, as in the High batch (same brief and defect).
- **Health:** 0 script errors, no flight failures, 0 blank frames.
- **Render check:**
  - Mean difference 14.0, 26% of pixels changed.
  - Glide framing matches. The landed Galecrest stands whole beside the trainer, clear of him, and taller than him.
- **Confound:** the two sides are not in the same light.
  - The arm's sky is clear blue (GPU lane: top band 175/185/193). Base is a neutral grey-beige haze (188/187/188).
  - All 3 judges name base's haze as one reason it scores lower.
  - Part of this +0.70 is therefore the grade, not the landing pose. The arm still wins on the pose (base's landed bird sits partly behind the trainer).
  - The GPU lane re-ran the arm to match base daylight. A small blue/grey difference remains, and both manifests say only "day".

## Batch `G-f15m`
- Three code-blind judges, standard prompt, one candidate set.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22. This is a confirming batch.
- **Fit:** linear, slope 1.4028, intercept −2.2189, r 0.952, anchor RMSE 0.30. No warnings. Neither side is above the top anchor.

| Side | Raw | Mapped |
|---|---|---|
| Base | 6.5, 6.6, 5.9 | 6.67 |
| Arm | 7.0, 6.9, 6.6 | 7.37 |

- **Recorded defect** (flight silhouette same in air; landing reads as a cut): PARTIAL 3/3 on both sides. Judges say the landed frame is now a real perch or stand pose, but the glide is unchanged.

## What holds it under 7.5 (3/3 unless noted)
1. **Glide pose.** It is the same flat, symmetric, fully spread wing. Judges ask for a banked or swept-back glide, distinct from the landing flare, plus a settling frame. This is a pose or animation change.
2. **Glide-frame ground.** The plain under the bird is "a blurry, uniform olive carpet with no groves or paths".
3. **Grade and light.** Hold the clear blue Meadows grade; base's haze costs it. One judge asks for rim light on the bird in the glide frame.
4. **Minor.** Three pale owls in the landed frame are evenly spaced and the same size (1/3).

## Recommendation
- **Close-out exception.** F38#15 sits at 7.70 High and 7.37 Medium, so a sub-0.5 change is allowed if it takes Medium across 7.5. The best candidate is a banked glide pose on the carrier during 02-glide, plus a rim light on it.
- **Re-capture.** Re-capture both sides with time of day and weather pinned to the same value, so the next Medium verdict measures the pose alone.
- **Re-judge on both presets.** Re-judge High too, because the glide change touches the High frames.
