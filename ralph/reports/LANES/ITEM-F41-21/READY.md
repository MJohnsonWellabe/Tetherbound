STATUS: ready (land)
BRANCH: tb/item-f41-21
HEAD: see git log

# F41#21 victory card ON (LANE-MESHY, 9 Nov)

- `hud.json victory_focus.enabled` true with `_why_on` "GPU 1108 section C, 5.61 -> 7.13, 3/3" (the GPU arm tb/gpu-arm-f41-21-on 2c593b05, all three judges preferred it). `route_trainer_receipts` stays true, so named-trainer acknowledgements become the victory Moment receipt instead of a quickbar message-strip line.
- Tests flipped to the ON behaviour (pins of OFF):
  - tests/test_uiposes_victory_focus.gd: `test_victory_focus_ships_off` -> `test_victory_focus_ships_on` (asserts enabled); `victory_receipt_routed()` now asserted true.
  - tests/test_trainer_reward_delivery.gd `test_persistent_reward_pays_only_nonfainted_owned_creatures`: when the receipt is routed, it asserts the line reaches the progression feed (the Moment receipt) and never the message strip; the OFF branch keeps the old strip assertion. XP assertions unchanged.
- Pre-ready: tests that grep hud.json / victory_focus / victory_receipt_routed / trainer_reward_delivery: 68 + 5 tests, 0 failed; test_band_content + test_chapter_rewards 19/0; smoke_trainer_battle exit 0 (same "adopt_starter is not a swap" line as main); net smoke client_trainer_rewards: ALL CHECKS PASSED.
- Pre-existing, unchanged by this (fails identically on main be95950b): smoke_progression_feedback (landmark strip tick, creature-bed arbitration, level-up banners).
