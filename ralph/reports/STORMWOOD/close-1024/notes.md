# Stormwood lane, close-1024 (F41#1, #2, #3, #5; F10#2)

Baseline: origin/main 5f1f388cc, where the r11 look is ON (commit 30b8264f4). Previous round notes: `../close-1022/notes.md`.
Renderer: Godot 4.7 Compatibility, Mesa llvmpipe CPU, 1280x720, Xvfb. CPU-provisional bar 6.7 mapped; GPU 7.5.

## Meshy request (day 1)
References drafted as crops of the owner boards (`docs/reference/boards-2026-09-06/`), in `meshy-refs/`:
1. Stormheart v3 hero: `stormheart_v3_ref_a.jpg` (board a exterior) + `stormheart_v3_ref_b.jpg` (board b exterior). About 380 m tall, height:width 1.6:1; keep v2 identity (V-split trunk with a glowing blue cleft), wooden platforms and walkways, navy banners only (no red), green crown. Used beyond `swap_radius_m` 75 m; scale to the 1.80 m trainer goes through the procedural shell. Purpose: judges r11/r12 call the distant Stormheart squat.
2. Glass-field strike scar crystals: `glass_scar_ref_details.jpg` (lightning crystal, electric roots) + `glass_scar_ref_palette.jpg`. A cluster of pale-blue fulgurite glass spikes rising from a scorched, fused ground crust, about 4 m wide x 2.5 m tall (taller than the trainer). Purpose: judges cannot read the glass-field scar.

## TO COORDINATOR
- 23 Oct 22:35 CT MESHY (send_message refused: elevated_session_untrusted_device). (1) Stormheart v3: `ralph/reports/STORMWOOD/close-1024/meshy-refs/stormheart_v3_ref_a.jpg` + `_b.jpg`, ~380 m, h:w 1.6:1, far LOD only, keep v2 V-split cleft, navy banners, no red. (2) Glass-scar crystal cluster: `meshy-refs/glass_scar_ref_details.jpg` + `glass_scar_ref_palette.jpg`, ~4 m wide x 2.5 m tall, pale-blue fulgurite on scorched crust. Return GLB paths on a branch; both stay flag-off until judged.

## Round r13 (in progress, 23 Oct)
- Baseline = origin/main 5f1f388cc (r11 look ON, commit 30b8264f4). Candidate = config only, OFF on main until judged:
  - wet-soil patches (`stormwood_ground_finish.json forest_layers.wet_soil`): tint #1e2420/#2a312b -> #39362b/#4a4738, item_size 2.8 -> 2.2 (the black patches fill the lower third of forest/giant frames);
  - `stormwood_surge.json sky_lightning.ground_light_exposure` 0 -> 0.6 (Break bolts light trunks and ground);
  - `presentation.telegraph.soft_style.enabled` true (F41#5: strike warning not a flat disc);
  - `stormwood_glass_field.json shard_finish`: height_scale 0.45 -> 0.8, emission 0.45 -> 1.1, crust_footprint 0.9 -> 1.05 (glass scar unreadable).
- Capture fix (run option only, no tool change): Break stills without `--fixed-fps` advance ~2-5 s of game time per CPU frame, so a 0.25 s bolt has decayed by the screenshot (why `_await_sky_bolt` "mostly timed out"). Matrix now runs as two passes per arm: Calm + aftermath at normal stepping, then `--phases=break --no-aftermath` with `--fixed-fps 10`. `--fixed-fps 20` for the whole run was tried and dropped: the 6 s phase blend then costs ~5 min per frame.
