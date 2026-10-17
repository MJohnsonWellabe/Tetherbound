# Cloud render capacity (coordinator, 17 Oct 2026)

Question: can a Claude cloud container (no GPU) render judgeable world frames?

- Machine: 4 vCPU, 15 GB RAM, no GPU, no Vulkan ICD. Godot 4.7-stable official.
- Renderer: `OpenGL API 4.5 (Core Profile) Mesa 25.2.8 - Compatibility - Using Device: Mesa - llvmpipe (LLVM 20.1.2, 256 bits)`.
- Command (from `main` `e6f5b9600` plus the restart commit, unchanged capture script):
  `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --resolution 1920x1080 --script res://tools/visual_judge/capture_camera_set.gd -- --set=res://tools/visual_judge/camera_sets/F17-6.json --out=<dir> --views=hall-approach_day_clear`
- Result: exit 0 in 527 s (most of it world load, about 5 GB RSS); one 1920x1080 frame with full Meadows vegetation, village houses, Crossing Hall, trainer and shadows. Downscaled copy: `_sheet_cloud_llvmpipe.png`.

Decision: Compatibility-renderer captures and code-blind judging run in cloud lanes, one render process per container, disclosed as Mesa llvmpipe. Forward+ Medium/High (F26#3) cannot run here and waits for a GPU machine. `MESHY_API_KEY` is not set in this environment, so new Meshy generations wait until the owner adds it as an environment secret; existing flag-off candidates can still be judged.
