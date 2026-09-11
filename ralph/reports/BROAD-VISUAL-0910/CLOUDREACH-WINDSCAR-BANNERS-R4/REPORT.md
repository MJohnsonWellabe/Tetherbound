# Windscar Beacon banners R4 — production disposition

## Disposition: POLISH — retain

Two collision-free installed cloth banners move the Beacon's blue/gold route
identity onto its outer shoulders, where the production location overlay does not
consume it. Both banners remain visible in the exact retained stand-05 day and
night compositions, while the open eight-metre passage, four terrain-fitted feet,
ten matching colliders, pickup clearance, and production-proven signal/light bounds
remain unchanged.

This remains POLISH. The banners improve colour identity, but the broad timber arch
is still geometrically plain and the cloth reads as lightly attached dressing rather
than a character-quality landmark system. Night surface separation also remains
weak. Retain this bounded gain; do not promote Windscar Beacon to hard pass.

## Evidence

- Production scene: `res://scenes/world/cloudreach_cliffs.tscn`
- Accepted output: exact canonical stand-05 day/night pair at 1280x720
- Manifest: complete, two of two frames, zero failures; two of two banners visible
  in both frames
- Focused validation: 3 tests, 35 assertions, zero failures
- Four foot contacts remain within 0.000014 m of their measured terrain sockets
- R1 failed before world load because it used editor mode; R2 exposed a stale
  1280x800 harness assumption; R3's extra walking-camera diagnostic was rejected
  after it produced an unhelpful low-angle composition. None is acceptance evidence.
