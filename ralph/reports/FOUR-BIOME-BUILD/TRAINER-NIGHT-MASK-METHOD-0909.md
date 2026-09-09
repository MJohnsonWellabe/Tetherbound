# Trainer night attribution — diagnostic method checkpoint

No production visual change or visual acceptance follows from these probes.
The goal is to measure visible lower-body readability without confusing
camera, animation, mesh detail or foreground occlusion with a material change.

The original source selection contains 6271 triangles whose vertices each
receive at least 95% combined weight from the eight named leg/foot/toe bones.
Imported-skin classification matches all 6271 source UV triangles. This is an
anatomical candidate, not a certified trousers-only paint mask.

The first CPU-baked proxy changed 6242 pixels despite an exact restored frame.
A later GPU-proxy implementation exposed setup errors before capture; their
separate logs remain preserved. The real Compatibility asset preflight then
found five imported LOD index sets. Discarding them would invalidate a split
mesh comparison, so the tool now partitions every original LOD using the same
skin-weight rule and preserves its edge threshold and all vertex arrays.

The corrected asset preflight passed, including actual RenderingServer
readback of both split surfaces. Base lower/other index counts are
18813/65160. Five lower/other LOD counts are 7911/34074, 3429/17559,
1542/8952, 699/4545 and 123/2925. Each sum and decoded index-sequence hash
matches the source partition. The source has 17553 vertices, 24 skin binds,
zero blend shapes and no shadow mesh. Receipt:
`.artifacts/trainer-night-attribution-0909/gpu-preflight-v2-result.json`,
SHA-256 b039cac7df82875aa0b28373bb435ac096a9237416e43968095c50980db60a2a.

World capture 04 (22:06:37–22:08:03 UTC) stopped at the unchanged exact
original/GPU-proxy parity guard. CPU comparison found one blue-channel byte
at pixel (1014,361) differed; no channel difference reached two. The reference
and restored images are identical, with matching recorded pose and transforms.
This does not establish a visible proxy-geometry defect. The LOD split was not
reached. Logs, three captures and `gpu-parity-analysis.json` remain under
`.artifacts/trainer-night-attribution-0909/`.

Next strategy: temporarily modify the original MeshInstance's material and
mesh assignments, then restore them, eliminating the unnecessary proxy
substitution. Exact full-black/split-black and reference/restored comparisons
remain required. Native readback of the preserved LODs remains required.
No readability, lighting, atlas-paint or whole-character pass is claimed.
