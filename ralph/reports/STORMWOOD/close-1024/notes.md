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

## Round r13 result (24 Oct, about 02:30 UTC)
- Batch: 4 anchor pairs, fixed: craft, f10_2_r3_capacitor, f36_0_npc:C5 (`--include`), plus f36_0_gap:C2; 5 candidate sets; three fresh code-blind judges, JUDGE_PROMPT v1 verbatim. Files: `r13/` (spec, sets, key, recorded defects, batch, mapped, `_sheet_r13.png` = Calm set).
- Fit: linear, slope 1.18, intercept -0.49, r 0.73, anchor RMSE 0.78 (warning: > 0.75). Confirming batch (top anchor 7.35).

| Set | Control raw (j1/j2/j3) | Control mapped | Candidate raw | Candidate mapped | Gain |
|---|---|---|---|---|---|
| F41#3 Calm | 5.5/4.9/4.8 | 5.48 | 5.6/5.0/4.8 | 5.56 | +0.08 |
| F41#3 Break | 5.0/4.5/4.3 | 4.93 | 5.1/4.5/4.3 | 4.97 | +0.04 |
| F41#3 aftermath | 5.8/5.2/5.2 | 5.87 | 5.9/5.3/5.2 | 5.95 | +0.08 |
| F10#2 glass_field | 5.7/5.4/5.2 | 5.91 | 5.6/5.2/4.9 | 5.68 | -0.23 |
| F10#2 capacitor | 5.9/5.8/5.5 | 6.26 | 5.9/5.8/5.7 | 6.34 | +0.08 |

- Control is main's ON r11 look; its mapped scores (5.48/4.93/5.87/5.91/6.26) sit near r12's mapped candidate scores, so main holds roughly the r11/r12 level.
- Reading: the r13 config changes are below the judges' resolution. Gain rule: r12 and r13 are two consecutive rounds under +0.5. Before parking, one clearly different approach (r14).
- F41#5 defect scan, all three judges: no flat magenta ground disc in Break on either side (FIXED); the fights still show thin magenta lane/ring outlines (PARTIAL; Fights-owned `charger_lunge`/telegraph). Other recorded defects still present: near-lens trunk/root (forest, giant, reverse), black foreground patch (forest), squat Stormheart, unreadable glass scar, Break forest near-black, lightning not lighting trunks and ground in the forest stands.
- Judges' top changes (all three): (scene) relight forest interiors (lift shadow and fill, rim on trunks, lightning lighting ground and trunks, depth fog); (scene, out of lane) slim the fight HUD and frame the pilot larger, real arc/crack telegraphs and impact bursts; (new_art) a tall split Stormheart hero, a strike-scarred glass field.
- Coordinator delivered the Meshy batch on `tb/meshy-1024` 38602bdb0: `assets/props/meshy-1024/stormwood_stormheart_v3_far` (about 1.2:1, faint cleft) and `stormwood_glass_scar_crystals`. Unwired.

## Round r14 (clearly different approach: new art + interior fill), capturing
- Candidate = r13 patch plus (`r14-candidate.patch`):
  - Stormheart hero `meshy_hero.model` -> `assets/props/meshy-1024/stormwood_stormheart_v3_far` (coordinator Meshy, tb/meshy-1024 38602bdb0), height 300 m, shape 0.8/1/0.8 (v3 is about 1.2:1; 380 m ran the crown off the top of the 300 m stand's frame);
  - glass field `shard_finish.crystal_model` -> `assets/props/meshy-1024/stormwood_glass_scar_crystals`, `crystal_height_scale` 0.55 (one fulgurite cluster per scar, 3.9-7.2 m); new code `_add_crystals` in stormwood_glass_field.gd (no key = off), focused test `test_fulgurite_clusters_build_only_with_their_model` (fails without the code);
  - forest-interior fill: `stormwood_look.json rig.environment.ambient_energy` 1.65 -> 2.3 (shadow opacity is pinned by the surge tests; ambient is not).
- Both Meshy folders: texture_import_policy --apply then reimport; --check PASS (6 sidecars mode 2).
- Control: the r13 control frames (main 5f1f388cc, unchanged rendering path).
