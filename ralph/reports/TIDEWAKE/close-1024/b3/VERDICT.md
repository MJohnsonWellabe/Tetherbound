# Tidewake close-1024 round b3: current bands and shore wl2, CPU pre-judge (25 Oct 2026, CT)

Two candidate sets, one batch, all OFF in play.

## Current bands (`current_bands_candidate`, layered on sw2)

- **What changed:** the crescent chop caps drop from 0.35 to 0.06. The long bank seams go from 0.3 to 0.55, wider and with fewer breaks (gap 0.45 → 0.28). The lane band comes on at 0.16.
- **Unchanged:** flow vectors, strengths and the restored flag.
- **Arms:** A = `current_flow,swim_candidate` (sw2). B = A plus `current_bands_candidate`.

## Shore wl2 (`stones_candidate` + new `golden_sky_candidate`)

- **What changed:** the wl1 base gains the grouped-stone pass (density 0.2, a tide-line band). The 18:00 sky is warmed: dusk-violet top, a taller warm horizon haze, warmer clouds. The shore stand looks away from the 18:00 sun, so it showed only the slate-blue sky top.
- **Arms:** A = `current_flow,shore_surf_candidate,shore_surf_vary_candidate,first_shore_declutter_candidate` (wl1 base). B = A plus `stones_candidate,golden_sky_candidate`.

## Mapped Bar A

- **Yardstick:** standard prompt, three code-blind judges, 3 anchor pairs (seed 22501).
- **Calibration:** slope 1.09, r 0.89, anchor RMSE 0.43.

| Set | A | B | Δ | Judges |
|---|---|---|---|---|
| Currents swim | 5.87 | 6.05 | +0.18 | higher x2, lower x1 |
| Shore, 3 frames | 5.91 | **6.30** | +0.39 | higher x3 |

**Defect changes:**
- **Current direction unclear:** PRESENT x1, PARTIAL x2 → PARTIAL x3.
- **Road markings:** PRESENT x2, PARTIAL x1 → PARTIAL x3. The crescents read as dashes; the bands read as one streak.
- **Shore clutter:** PRESENT x1 → PARTIAL x3.
- **Empty or evenly scattered:** PRESENT x3 → PRESENT x2, PARTIAL x1.
- **18:00 reads as midday:** PARTIAL on both sides. B is called warmer x3 but still has no visible low sun.

## Disposition

- **Shore wl2:** READY for the GPU at +0.39.
- **Current bands:** a small gain, also READY, layered on sw2.
- **Gain rule:** both are under 0.5, so the next round on each must change approach, not tune.

## Remaining (all three)

1. **Currents:** read as one painted streak (bands) or as scattered dashes (sw2). Judges want foam ribbons that move, with a lighter in-lane tint and swell. The swimmer is small and vanishes at night; the asks are a rim light and a visible stroke wake.
2. **Shore:** dunes are bare and smooth, with no grouping.
   - Cluster driftwood, dune grass and rocks at the edges.
   - The waterline poles and the cropped NPC/barrel under the HUD read as noise.
   - The hard black shadow wedge on the lesson dune reads as an artefact.
   - 18:00 needs a visible low warm sun.
