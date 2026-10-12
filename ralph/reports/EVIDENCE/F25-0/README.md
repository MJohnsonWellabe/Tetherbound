# F25#0 — about 24 effect archetypes, each with a real mesh or particle body, trail, impact and sound — CAPTURE-READY

systems-b, Sun 11 Oct 2026 (CT), on 66cb1f85e (tb/ev-coordinator merged). Taken over from the fights/ultimates lanes.
Data: `data/config/vfx.json` move_library.enabled = true; 24 archetypes, and every one declares body, trail, impact and sound (checked by script: no archetype is missing any of them).
Capture: `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --resolution 1920x1080 --script tests/smoke_move_effects_library.gd -- --batch=mastery --ranks=1 --out=<dir>`. Result: 38 cases, 0 failures, renderer gl_compatibility (llvmpipe), scope synthetic_no_combat.
Judge inputs: `sheets/sequence-NN.jpg` (24 generic archetypes) and `sheets/ultimate-NN.jpg` (7 ultimates × 2). Each sheet tiles the phases left→right, top→bottom: launch, flight, contact, impact, aftermath (ultimates: windup, travel, contact, peak, late). Each tile is 960×540, downscaled from the 1920×1080 frames to keep the repo small.
Filenames are neutral; the case → archetype mapping is in `private/results.json` (cases[] in sheet order). Do not show it to the judge.
Not covered here: the F25#4 frame-time half (needs a real GPU, Medium preset); this host is llvmpipe.
