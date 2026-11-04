# VIS-TIDEWAKE golden-hour sand-stripe probes (capture only, never shipped)

The judges keep naming hard, regularly spaced dark diagonal stripes across the First Shore sand at golden hour (sun pitch -8 deg, yaw 252) and dawn.

| Probe | What changed vs base | Stripes |
|---|---|---|
| r16 | dune ripple_strength 0.009 -> 0.004, normal_strength 0.14 -> 0.08 | unchanged |
| r17 | shadow_normal_bias 3.0 at dawn/golden, dune shadow_push 0.10 | unchanged |
| r18 | First Shore declutter (driftwood, work cluster) | unchanged |
| p1 | landmark_props_candidate + lesson_clusters_candidate off | unchanged |
| p2 | dock_village/dressing/equipment/workplace/residents/barrier removed | unchanged |

They are not ripple normals, terrain shadow acne, landmark props, lesson dressing or the dock. They are real cast shadows of something to the west of the stand that none of these sections owns: most likely terrain relief, vegetation (tree rows or grass-field bushes) or another world-built layer. Next step, if picked up: a probe that hides the `water_vegetation` trees/shrubs layers, then the terrain shadow caster flag.
