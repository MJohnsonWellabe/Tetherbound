# F21#4 fight camera size matrix on clear ground: frames for the code-blind judge

Captured Sun 11 Oct 2026, about 3:38 PM CT, by the captures lane. This lane captures; it does not judge.

- **Source:** tb/ev-captures `d84a8852`, which merges tb/ev-coordinator past `0d323864` (the Tether Commands meter is now bottom-centre). Local Linux container, Low preset (`gl_compatibility`, llvmpipe), 1920x1080.
- **Tool:** `tools/capture_f21_matrix_clear.gd`, a thin wrapper over the existing `tests/smoke_combat_camera.gd --matrix-dir --matrix-preset=Low` static matrix. The matrix, its framing checks and the production rig are unchanged.
- **Disclosed fixture move:** before the matrix reads its staging transform, the wrapper moves ally, foe and trainer by one shared offset (18.0 m here) to ground with:
  - no solid vegetation scatter within 4 m of either actor;
  - no collider standing on the terrain within 9 m of the pair midpoint.
  The previous capture staged the pairs behind boulders (judge FAIL on staging); attempt 1 of this fix used the scatter test alone and still found the boulder spot.
- **Matrix result (`matrix.json`):** all 9 pairs framed, measured size classes match, actor overlap 0.000, `failures: []`.
- **`sheet.jpg`:** rows are ally small/normal/giant (mudsnout, terrapup, veridian); columns are foe small/normal/giant. Full frames are in `frames/`.
- **Not producible here:** the live matrix (llvmpipe misses its 30 s per-pair budget) and Medium Forward+.
