# Cloudreach frame matrix at d7c8618e (Low / Compatibility)

- Commit: `d7c8618e` (game code; evidence commits after it change no game files).
- Renderer: Compatibility (Low), Xvfb + llvmpipe, opengl3, 1920x1080; judged as 1280x720 JPGs. Contact sheets here; full frames stayed local (disk budget).
- Command: `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1920x1080 --script tools/capture_cloudreach_frame_matrix.gd -- --active=terrapup --output=<dir>   (+ the same with --night)`
- Day: 37/37 rows in two runs (rows 1-33, then `--only=34,35,36,37` after a 2 h job limit stopped the first run). Night: 37/37 in two runs (rows 1-36, then `--only=37`). 0 rows skipped. Manifests: manifest_day.txt, manifest_night.txt.
- Matrix fixture note: rows run in order, so row 37 is captured after rows 33-36 with the pre/post-finale flags already set (manifest: `flags post_finale`). Row 37's festival bunting is the expected post-finale state, not a leak.
- Medium (Forward+): requested as RENDER REQUEST cloudreach-1. Codex's Medium passes failed to boot (the render loop was off during the shell build); the coordinator is fixing the capture boot and re-requesting.
