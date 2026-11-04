# Quick judge qj_canopy: F40#6 tree_canopy_camera_stops (not judged)

- Overlay: `cloudreach_look.json:tree_canopy_camera_stops.enabled`. Captured `phase2_capture_cloudreach_ride.gd` on tree `7ff3b7defe3e`, base and candidate (quick_judge `capture`; the job's frame ids no longer match the ride's names now that the shipped scramble recovers the mount at 1.2 s, so pairing is manual).
- **Result: no visible change.** The road-back frames (`phase2_19_terrace_road_back_01.5s`, `_20_..._03.0s`) are the same on both sides: the camera still sits inside the same canopy. That tree is not one of `cloudreach_look.gd`'s look trees, or the camera pivot itself is inside the crown, so a crown stop cannot pull the arm out. Not judged; stays OFF. A follow-up would need the tree's source (settlement or arrival dressing) or a foliage fade near the camera.

## Second attempt (qj_canopy2)

A headless probe found the tree: `AuthoredRoutes/LandingTree171` (CommonTree_2) at (5.1, 104.9, -258.6), 15 m from the terrace road, not a look tree. The arm was extended to `LandingTree*`/`RouteTree*` (commit after a15b...); the recapture on tree `0b496d173fc7` still shows the camera inside the same canopy at `phase2_19_terrace_road_back_01.5s`. **Second failure on the same item: parked** (owner rule) until there is a new idea; the riding camera evidently does not stop on the occlusion-only layer in this case. Flag stays OFF.
