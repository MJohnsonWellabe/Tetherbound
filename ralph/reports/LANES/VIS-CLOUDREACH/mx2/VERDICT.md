# VIS-CLOUDREACH mx2: night moon key light on the matrix night piece (not judged)

- Overlay (temporary, restored): `cloudreach_visual.json` `time_overrides.night` gains `sun` {energy 1.0, shadow_opacity 0.55, colour #c4d4f2} and ambient colour #5568b4.
- Capture: `capture_cloudreach_f40_matrix.gd --piece=7` (realm gate, night clear), Low, CPU; base = `mx1` piece 7.
- **Result: no visible change** in any of the four views (inspected side by side before judging); not judged. A later layer (the realm light candidate / biome rig) evidently sets the night sun after `time_overrides`, so this key never reaches the frame. Parked for F40#19/#0; NEAR6-CR holds F40#17, where the same idea was handed over.
