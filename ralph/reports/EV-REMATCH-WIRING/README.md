# F44#0/#1 Tidewake + Cloudreach rematch wiring (lane rematch-wiring)

Code: tb/ev-rematch-wiring 11af2aff. Cloudreach/Water directors tag each trainer with a rematches.json profile as a
foundation_trainer_specs source (canonical spec + its own challenge prompt); foundation_rematches reads that prompt.
Proof: tests/smoke_f44_biome_rematch.gd (headless, each run in its own network namespace: parallel runs otherwise
collide on udp/27015 and the loser stays offline-solo). Disclosed generated saves: profiles f44_tidewake, f44_cloudreach,
f44_tidewake_endgame, f44_cloudreach_endgame (generated_boundary_profiles.json), one disclosed teleport beside the prompt.
Unit: test_f44_repeatables, test_f44_endgame_tier, test_foundation_rematch_bosses, test_rematch_solo_admission,
test_remote_rematch_runtime, test_cloudreach_encounters, test_water_encounter_*: 42 tests, 6998 assertions, 0 failed.

## F44#0 Tidewake (R1): PASS (21 checks, 0 failed)
- witness water_trainer_yara tier r1: levels [43, 43, 43] (first win [27, 28, 28]), outcome won after 5888 frames
- paid {'tidesteel_ingot': 2} once; first-win reward never paid it; win receipt after 8045 frames; reload: rematch receipts, bag and cooldown unchanged
- full receipt: f44_r1_tidewake.json

## F44#0 Cloudreach (R1): PASS (21 checks, 0 failed)
- witness officer_voss_summit_approach tier r1: levels [55, 55, 55] (first win [41, 42, 42]), outcome won after 5447 frames
- paid {'skyglass_ingot': 2} once; first-win reward never paid it; win receipt after 5054 frames; reload: rematch receipts, bag and cooldown unchanged
- full receipt: f44_r1_cloudreach.json

## F44#1 Tidewake (Endgame): PASS (21 checks, 0 failed)
- witness water_trainer_yara tier endgame: levels [55, 55, 55] (first win [27, 28, 28]), outcome won after 6895 frames
- paid {'tidesteel_ingot': 2} once; first-win reward never paid it; win receipt after 9597 frames; reload: rematch receipts, bag and cooldown unchanged
- full receipt: f44_eg_tidewake.json

## F44#1 Cloudreach (Endgame): PASS (21 checks, 0 failed)
- witness officer_voss_summit_approach tier endgame: levels [58, 58, 58] (first win [41, 42, 42]), outcome won after 4648 frames
- paid {'skyglass_ingot': 2} once; first-win reward never paid it; win receipt after 5300 frames; reload: rematch receipts, bag and cooldown unchanged
- full receipt: f44_eg_cloudreach.json
