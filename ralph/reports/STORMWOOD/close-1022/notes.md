# Stormwood lane, close plan from 22 Oct 2026 (F41#1–#3, #5; F10#2; F22#4 Stormwood)

Renderer for every capture here: Godot 4.7 Compatibility (opengl3), Mesa llvmpipe, CPU, 1280x720, Xvfb. Shipping renderer default, iteration only; GPU confirmation goes through the coordinator.

Messaging: `send_message` to the coordinator session is refused from this session ("elevated_session_untrusted_device"). Reports to the coordinator are kept in the "To the coordinator" section below on the pushed branch until a channel works.

## Worklist (GPU-PASS/F10-2/VERDICT.md asks)
1. Darkness and grade (every preset mean luma about 29/255). In progress.
2. Flat magenta lane slabs: the six Stormwood named rows' `cue_lane_solid` lanes (fill 0.6, F10#2 C3). Candidate `charger_lunge.lane_charged` (OFF).
3. Floating NPC text over the enemy panel (Capacitor): Master signpost Label3D had no draw distance. Fixed with a focused test.
4. No impact VFX: `vfx.json hit_spark` is OFF by owner decision (2026-10-04); per-move impacts come from move_library. Not changed.
5. HUD covers the trainer; clone herds behind Crown; pilot no taller than the trainer: routed (below).
6. Forward+ saturation drain: waiting on GPU-PASS/forward-plus-grade.

## Grade candidate (not judged)
Candidate = close-1020 r10 patch (look rig ON etc.) plus:
- look rig: exposure 0.82 -> 1.35, adjustment_saturation 0.94 -> 1.1, ambient_colour #a4a8c4 -> #aab0bc (less lavender; bark went pink);
- ground finish: wet-soil pools #141716/#1d211f -> #1e2420/#2a312b (were a black void); moss terrain tints #9aae98 -> #b8a882, forest floor #8c9f8c -> #a89a78 (the Meshy moss albedo is teal; warm tint pulls it to moss), damp #a8b2ac -> #85836f (read as pale slabs);
- bark tint #a39a86 -> #a8977a (vegetation config; rebaked).
Snapshot: `candidate-config.patch` (config only; apply, then rebake Stormwood scatter).

Measured (luma over the play area, HUD bands excluded; 0–255):

| Capture | Mean luma | Floor band | Saturation |
|---|---|---|---|
| GPU shipping fights (GPU-PASS, Low) | 28.9 | 22.7 | 0.49 |
| CPU r10 candidate, forest Calm | 39.1 | 34.4 | 0.41 |
| CPU g2 Calm matrix (5 stands) | 77.6 | 70.0 | 0.37 |
| CPU g3 glass_field fight (7 interval frames) | 77.7 | 68.2 | 0.29 |
| CPU g3 capacitor fight (7 interval frames) | 78.0 | 61.1 | 0.27 |
| Reference boards (Stormheart a/b, Palworld) | 114–131 | — | 0.37–0.46 |

## To the coordinator
- Signpost fix (ON, with test) is in f90f2a3ca: `masters.json sign_presentation.visible_range_m` 24 m + 4 m fade; `tests/test_master_sign_visible_range.gd` fails without it. It touches every realm's Master signpost. Ready to land with the next batch.
- Out of lane: (a) the fight pilot (Lv 42 Sparkit fixture) renders about trainer height; GPU judges say "pilot no taller than the 1.80 m trainer" (hard rule, creatures lane). (b) The HUD bottom band covers roughly 45% of a 1280x720 fight frame (UI lane). (c) Crown clone herds come from hollow_crown wild cluster tables (encounter data); not changed without a ruling.
