# F21#4 fight camera size matrix: frames for the code-blind judge

Captured Sun 11 Oct 2026, finished about 12:20 PM CT (render.yml run 38157074132, source `0d598b9b`). This lane captures; it does not judge.

- **Tool:** the existing `tests/smoke_combat_camera.gd --matrix-dir --matrix-preset=Low --source-commit`, Low preset (`gl_compatibility`), 1920x1080.
- **Method:** a real Meadows encounter is entered physically, then each pair is staged: the authored small, normal and giant bodies (mudsnout, terrapup, veridian) are set side by side, actor simulation is held, and the normal production rig frames them for 180 physics frames. No species is rescaled.
- **Matrix result (`matrix.json`):** all 9 pairs framed, measured size classes match, actor overlap 0.000 in every pair, `failures: []`, `all_nine_complete: true`.
- **Run exit was a failure, for an unrelated reason.** The smoke's later render-corner check failed for a wild Bramblebun (`Wild_bramblebun_0_2`) at the 3 m and 9 m requested frames. That check runs after the matrix and is not part of these pixels.
- **Live matrix not producible here.** `--matrix-live` (run 38154932804) hit its 30 s per-pair wall-clock budget at about 64 of 300 physics steps on llvmpipe and wrote no frames.
- **Medium Forward+ not producible on render.yml** (Forward+ crashes on llvmpipe Vulkan).

`sheet.jpg` is a 3x3 grid, rows = ally small/normal/giant, columns = foe small/normal/giant. Full frames are in `frames/` (960x540).
