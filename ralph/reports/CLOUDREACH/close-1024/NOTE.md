# Cloudreach lane — close 24 Oct 2026 (tb/cloudreach)

Rows in order: F40#0 recapture + rescore, F40#5 defect pass, F40#3 matrix bar, F08#3, F40#1/#2.
Renderer for every capture: Low preset, Compatibility (`gl_compatibility`/`opengl3`), Mesa llvmpipe CPU, xvfb.
Judging: `tools/visual_judge/` yardstick (standard prompt, ≥3 anchor pairs, `calibrate.py`); CPU-provisional bar 6.7.

## Log (US Central)
- 23 Oct late: branch `tb/cloudreach` cut from origin/main 5f1f388cc. The container had no Godot; installed 4.7-stable (CI's URL). First import exit 0 (~45 min).
- 23 Oct 22:48 – 24 Oct 13:40: F40#0 CPU recapture at source 22b88b52, `tools/capture_cloudreach_f40_matrix.gd --preset=Low --low-resolution=1280x720`, pieces d*8+3..d*8+7 per stand (day clear/rain, golden clear/rain, night clear × approach/gameplay/reverse/detail). World load ~9 min; 1–6 min per frame on llvmpipe (Cliffhold and Windscar Beacon slowest). Stands 0, 6, 7, 8, 9, 10, 11 complete at 20/20, stand 4 at 11/20, no refusals or unsupported stands: **151 frames**, hashes in `f40-0-cpu/frame-manifest.json`, frames local (`.artifacts/f40/r1/`). Not judged.
- 24 Oct 07:00 coordinator (owner): GPU decides done; the CPU-provisional 6.7 rule is retired. CPU frames iterate and pre-judge only; READY lines carry the GPU capture commands; rows close at mapped >=7.5 Medium and High. F40#1/#2 are now one row per catalog item.
- 24 Oct 13:40 coordinator (owner, "switch Cloudreach to scene fixes"): capture stopped (stand 4 killed; stands 1, 2, 5, 3 and the fight not run). The GPU lane's High/Medium matrix replaces these frames for F40#0, #3 and #5. Lane moves to scene-level, flag-OFF candidates on the worst catalog items and the F08#3 GPU asks, pre-judged on CPU with only the views they touch.
- Unjudged self-look at the CPU frames (for the GPU lane's F40#5 scan, not a verdict): High Perches (stand 7) flat saturated blue compass rings and spokes underfoot and an oversized world-space NPC caption ("Windward... Hold your footing. Follow the side path") across the right third; Old Wind Observatory (stand 9) loose flat blue slabs in the grass and the camera hemmed in by trunks; Cliffhold approach (stand 8, 12 m back) puts the camera against a flat building wall; a violet-winged creature at the High Perches.

- 24 Oct 14:00–15:30: scene-fix candidates, both flag OFF, pre-judge on CPU pending.
  - **F08#3 r18** (`cloudreach_settlement_life.json` → `candidate`, arg `--cloudreach-settlement-r18-candidate`, code: a candidate overlay merged over the shipping settings): near-field cobbles, low stones and bushes between the production camera and the trainer at every fixed stand (the CPU control c18 shows bare lawn/dirt there); moonlit cloud ring #3e4a66 → #8a93a8; settlement night ambient 1.8 #44507a → 2.3 #57628c and moon 0.55 → 0.75; seven islets 10–56 m at varied heights instead of five 30–38 m; far haze 0.28 → 0.4. CPU control c18 (shipping, 10/10 views) captured at 5f1f388c+lane notes; candidate a18 at fec610ac.
  - **High Perches compass** (`cloudreach_high_perches_visual.json` → `candidate`, arg `--cloudreach-high-perches-compass-candidate`): inner ring and wide rays in masonry instead of flat banner blue (the flat blue ring in every CPU stand-7 frame). Control = the CPU recapture's stand 7 frames (unchanged path); candidate pieces 59 (day clear) and 63 (night clear).

## TO COORDINATOR
(newest first)
