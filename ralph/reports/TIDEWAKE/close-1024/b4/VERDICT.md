# Tidewake close-1024 round b4: lesson-dune clusters and lane tint, CPU pre-judge (25 Oct 2026, CT)

Two candidate sets, one batch, all OFF in play.

## Shore: wl2 against wl2 + `lesson_clusters_candidate`

`lesson_clusters_candidate` is an authored grove on the swim-lesson dune midground, built from the installed Tidewake family:
- shrub cluster at 1.9 m;
- four beach-grass clumps;
- a half-buried driftwood log;
- a tide-line group of wake rocks and wrack in the right foreground.

It is presentation only, with no colliders. It went through two placements:
- **r1:** the grove sat at (78, 137), which fell out of frame in the dune shadow.
- **r2:** the grove moved to about (72, 148) and grew.

Frames: the lesson-dune frame is r2 (`wl3_b2`). The first-shore day and 18:00 frames are from the r1 capture (`wl3_b`). The clusters sit on the lesson dune, not the first shore, so those two frames show no grove in either placement.

Arms:
- **A (wl2):** `current_flow,shore_surf_candidate,shore_surf_vary_candidate,first_shore_declutter_candidate,stones_candidate,golden_sky_candidate`.
- **B:** A plus `lesson_clusters_candidate`.

## Currents: bands against bands + `current_tint_candidate`

The soft channel tint changes from #2c5f80 at 0.12 to a lighter #5fb3c2 at 0.3.

Arms:
- **A:** `current_flow,swim_candidate,current_bands_candidate`.
- **B:** A plus `current_tint_candidate`.

## Mapped Bar A

- **Yardstick:** standard prompt, three code-blind judges, 3 anchor pairs (seed 23617).
- **Calibration:** slope 1.06, r 0.77, anchor RMSE 0.60. This is a weak fit: the villager anchors scored identically on both sides.

| Set | A | B | Δ | Judges |
|---|---|---|---|---|
| Shore, 3 frames | 6.32 | **6.71** | +0.39 | higher x3 |
| Currents swim | **6.35** | 5.86 | -0.49 | lower x3 |

**Shore defect changes:**
- **Empty or evenly scattered:** PRESENT x3 → PARTIAL x3. The grove reads as "an authored focal point".
- **Clutter:** FIXED x2 on both sides.
- **18:00:** PARTIAL on both sides. The warmer sky reads, but there is still no sun-side glow or low-sun direction.

**Currents defect changes (tint):**
- The tint flattens the whole sea to one pale turquoise when the camera sits inside the lane.
- **Lane separation:** PARTIAL → PRESENT x1.
- **Direction:** PARTIAL → PRESENT x2.

## Disposition

**Shore (wl3):** wl2 plus `lesson_clusters_candidate` maps to 6.71, at the 6.7 CPU-provisional floor. That makes it **CPU-provisional at best**:
- the fit is weak (r 0.77);
- one batch only;
- a GPU pass is owed before it counts.

It is READY for the GPU.

**Current tint:** loses, stays OFF, and is parked. The bands alone remain the current candidate.

## Remaining (all three)

1. **Shore:**
   - The rest of the dune is still a broad bare plane, with thin dune vegetation.
   - The cropped NPC and barrel in the first-shore foreground sit under the HUD.
   - 18:00 needs a sun-side warm sky and glints on the water.
   - The blue wake-rock reads as a blob.
2. **Currents:** a tiny head-up swimmer with arms raised. All three ask for a horizontal crawl animation, which is new animation art. The lane needs a darker edge, not a lighter fill.
