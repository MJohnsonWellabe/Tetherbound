# F21#4 — Fight camera frames small/normal/giant without overlap; judge PASS

- Commit under test: 826d273c3 (full SHA 826d273c3dbdcb1002034812041b1dfb59d84120)
- Renderer: software renderer (Compatibility), Xvfb + llvmpipe, opengl3, 1920x1080 fullscreen
- Command: `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --fullscreen --rendering-driver opengl3 --audio-driver Dummy --resolution 1920x1080 --script tests/smoke_combat_camera.gd -- --matrix-live --matrix-preset=Low --matrix-dir=<dir> --source-commit=<full sha>` → exit 1, 0 PNG frames, matrix.json + 28 FAIL / 0 PASS lines (live_matrix_lines.txt)
- Replaces: ralph/reports/COMBAT/f21/camera-readability-r2 (native Windows GTX 1060 receipt)

## Result: ERROR — needs native GPU

Every one of the nine size cases (small/normal/giant × small/normal/giant) "ended or exceeded its 30s budget at physics boundary 24–32" and then "failed strict rendered framing/live motion/quick evidence; input travel=0.0": on 4-CPU llvmpipe the live fight cannot advance within the tool's wall-clock budget, so no frame was saved and no code-blind judge could run. Also logged (may be budget-induced, unconfirmed): 8× "the 9m requested frame crops a Wild_bramblebun_1006_3 render corner … outside [P: (96, 54), S: (1728, 972)]", "the rig did not follow the moving active creature", "cancelled aim did not return camera follow to the active creature".

Still needed: the same command on native hardware (as the replaced receipt), then a fresh code-blind judge on the size matrix.
