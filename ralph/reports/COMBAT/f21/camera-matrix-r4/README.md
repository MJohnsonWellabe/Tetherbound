# F21#4 size matrix r4 (final camera source)

Source: SOURCE.txt. Inset-envelope foreground fade (0.65), nearest fallback lens within `fallback_overlap_tolerance`.
Tool: `tools/capture_f21_size_matrix.gd` (xvfb + llvmpipe, gl_compatibility, Low preset, 1920x1080, `--fixed-fps 60`, undrawn frames between stills).
9 pairs x 4 stills (frame 12, 36, 60 and 71, with the ally walking between frames 24 and 48).
`matrix.json`: all 36 stills are framed with 0 box overlap and the HUD clear; the lens sits at 9.5-22.6 m and never at the 39.5 m cap.
Fresh code-blind judge: **PASS**, all nine pairings (`judge.txt`).
Supersedes the strict FAIL in camera-readability-r2. Native-GPU re-capture was handed to Codex at SHA 61a6b5e4c.
Frame times are from software rendering and are not quoted.
