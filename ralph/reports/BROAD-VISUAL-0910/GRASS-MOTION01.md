# Shared grass during physical movement

`grass-motion-southbridge-first` completed cleanly from 09:44:14 to 09:45:55 UTC.
The current catalogue supplied one disclosed South Bridge setup, then the probe
held the production forward input for 240 physics steps. Player physics and the
production camera produced 19.941 m of horizontal travel, without further pose
writes. Eleven native 1280×800 frames are retained under
`shots/diagnostics/grass-motion-southbridge-first/`.

Root inspected walking frames 00, 05 and 09. The blades remain visible through
the approach and up the bank; the road clearing and plant layers remain distinct.
This is a bounded coherence check for the already retained mesh/grounding/arc,
not another visual comparison or commercial acceptance. Thin strip-like foliage,
coarse ground material and sparse individual patches remain visible limitations.

The live GrassField subtree contains 128 MultiMesh geometries / 83,984 instances;
that census includes its other cover tiers and is not a count of grass blades.
The grass material's wind clock advances from 2.188274 to 6.366294 with
wind_strength 0.1 and gust 0.7. The base catalogue freezes clear weather and
daylight; weather transitions were not tested. The original old walk probe was
not used because it replaces the camera, manually relocates the player and
disables wind.

Spaced stills cannot establish frame pacing, input latency, between-sample
aliasing, all-world LOD behaviour or ROG Ally performance. The manifest preserves
positions, camera transforms, velocities, live counts and initial/final uniforms.
