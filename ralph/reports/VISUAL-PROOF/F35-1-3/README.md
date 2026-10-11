# F35#1 / F35#3 signature ultimates: frames for the code-blind judge

Captured Sun 11 Oct 2026, about 1:05 PM CT, by the captures lane (`tb/ev-captures`). This lane captures; it does not judge.

- **Source:** `8b6452d4` (origin/tb/ev-coordinator `94368e45` plus capture-tool and evidence commits only).
- **Renderer:** local Linux container, Godot 4.7-stable, `gl_compatibility` / OpenGL on Mesa llvmpipe in xvfb, 1280x720.
- **Tool:** the existing `tests/smoke_move_effects_library.gd --batch=ultimates`. It launches the actual ultimate presentation nodes through `ULTIMATES.launch`, posed between a production attacker of the species and a target on the configured Meadows day stage.
  - It sets `ULTIMATES._config.enabled = true` in its own process, as a diagnostic opt-in (smoke source line ~838).
  - It runs no meter, HP or receipt path (scope `synthetic_no_combat`).

## F35#1 (and #2 growth): `unique-sheet-1..3.jpg`

The 12 unique ultimates F35#1 names, in this order: terrapup, ripplet, galewisp, veridian, abyssal_guardian, solmane, fulgocobra, stormursa (the storm bear), tuskroot, ashtusk, cannonback, stormcapra.
- Each has two rows: breakthrough count 0 (b0) and count 5 (b5).
- Each row shows five beats from `assets/vfx/proof_scenarios.json` `ultimate_capture.shutters`: windup and travel (fractions of the 0.7 s travel), contact and peak (seconds after arrival), and late (0.35 s before the 2.4 s presentation ends).
- Run result: `F23 actual override assertions=361 failures=0`; `F25 batch=ultimates cases=24 failures=0`. Every case reports exactly 1 arrival (`results-unique.json`).

## F35#3: `four-sheet.jpg`

`--simultaneous=ultimate_terrapup,ultimate_ripplet,ultimate_galewisp,ultimate_veridian` fires four ultimates on one frame from four posed attackers side by side, seen from behind and above them. Frames are taken at the early, middle and late beats.

**This run reported a failure, and it is a renderer limit.** The smoke times this case on wall clock, and llvmpipe drew only 3 frames in the 2.4 s presentation (first frame 1155 ms, p95 934 ms). None of the four effects reached the target before the window closed (`Four-ultimate arrivals 0`, `results-four.json`). The frames therefore show the four effects overlapping in flight, not at contact. Readability at contact in a four-creature fight needs a GPU or Forward+ capture; render.yml cannot produce one (its Forward+ crashes on llvmpipe Vulkan).

## Limits

- Compatibility only; a stage, not an earned four-player fight. The smoke's own `limits` list applies: no combat or damage authority, and identity duration slowed for readable frames.
- `frames/` holds every beat as a 960x540 JPEG.
