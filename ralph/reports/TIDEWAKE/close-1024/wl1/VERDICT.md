# Tidewake close-1024 round wl1: waterline declutter, CPU pre-judge (25 Oct 2026, CT)

## What was tested (`waterline_declutter_candidate`, OFF in play)

- Drift-marker spacing widened to 45 m, capped at 6 markers per lane, and buoys cut to two (at 0.3 and 0.75).
- **Arm A:** `current_flow,shore_surf_candidate,shore_surf_vary_candidate,first_shore_declutter_candidate`.
- **Arm B:** arm A plus `waterline_declutter_candidate`.
- **Frames:** first shore at midday, the swim-lesson dune, and 18:00.

## Mapped Bar A

- **Yardstick:** standard prompt, three code-blind judges, 3 anchor pairs.
- **Calibration:** slope 1.55, r 0.98, anchor RMSE 0.31.

| Set | A | B (fewer markers) | Δ |
|---|---|---|---|
| Waterline | 6.36 | 6.47 | +0.11, level |

**Defect calls (arm B):**
- "Beach and waterline read cluttered" is PARTIAL in both arms, all three judges.
- "Empty or evenly scattered rather than authored" is PRESENT x3 in both arms.

## Disposition

The candidate stays OFF; it is level. The markers were not what the judges saw as clutter. They named three things:

1. **Pier stakes:** small posts, stakes and a pier stub around the first-shore jetty.
2. **Pebbles:** an even pebble carpet on the swim dune.
3. **18:00 sky:** no warm sky grade at 18:00.

They also flagged the hard striped shadows across the 18:00 foreground and the HUD covering the falls.

**Next:** cluster the pebbles into tide-line drifts, add driftwood or wrack groups with open sand between, thin the stakes around the pier, and give 18:00 a warm horizon grade.
