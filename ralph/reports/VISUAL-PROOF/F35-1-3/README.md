# F35#1 / F35#3 signature ultimates: frames for the code-blind judge (recapture)

Captured Sun 11 Oct 2026, finished about 2:38 PM CT. Local tree tb/ev-captures `194cc7b3`, which merges tb/ev-coordinator with the reworked Veridian, Fulgocobra and Solmane ultimates (`ba2afbfc`). Low/Compatibility (llvmpipe), 1280x720, `--fixed-fps 30`. This lane captures; it does not judge.

- **F35#1 (and #2 growth), `unique-sheet-1..3.jpg`:** the 12 unique ultimates, each at breakthrough 0 and 5, with five beats each (windup, travel, contact, peak, late).
  - Order: terrapup, ripplet, galewisp, veridian, abyssal_guardian, solmane, fulgocobra, stormursa, tuskroot, ashtusk, cannonback, stormcapra.
  - Tool: the existing `tests/smoke_move_effects_library.gd --batch=ultimates` (real `ULTIMATES.launch` nodes on the Meadows stage; the smoke enables ultimates in its own process).
  - Result: 24 cases, 0 failures, 1 arrival each (`results-unique.json`).
- **F35#3, `four-sheet.jpg`:** terrapup, veridian, fulgocobra and solmane fired on one frame; beats are travel, contact, peak and late.
  - Tool: `tools/capture_f35_four_contact.gd`, a disclosed wrapper over the smoke's four-at-once case. It times beats on game frames under `--fixed-fps` instead of wall clock, because the smoke's wall-clock loop drew only 3 frames on llvmpipe.
  - Its camera is elevated on the target's side, because the smoke's view from behind the attackers was filled by Solmane (attempt 1, not used).
  - Result: 84 frames, all 4 effects arrived (contact at game 0.80 s), 0 failures (`results-four.json`).
- **Observed, not diagnosed:** from the contact frame on, only the Solmane attacker body is visible; the other three attackers are no longer drawn (they are visible at travel). This is the stage/presentation's behaviour; the capture changes no visibility.
- **Limits:** stage presentation only; no earned four-player fight; Compatibility only.
