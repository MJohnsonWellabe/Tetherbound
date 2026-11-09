STATUS: ready (land; CI co-op failure investigated, not reproducible and not caused by this flag; one confirming CI rerun recommended)
BRANCH: tb/item-f41-21
HEAD: see git log

# F41#21 victory card ON (LANE-MESHY, 9 Nov)

- `hud.json victory_focus.enabled` true with `_why_on` "GPU 1108 section C, 5.61 -> 7.13, 3/3" (the GPU arm tb/gpu-arm-f41-21-on 2c593b05, all three judges preferred it). `route_trainer_receipts` stays true, so named-trainer acknowledgements become the victory Moment receipt instead of a quickbar message-strip line.
- Tests flipped to the ON behaviour (pins of OFF):
  - tests/test_uiposes_victory_focus.gd: `test_victory_focus_ships_off` -> `test_victory_focus_ships_on` (asserts enabled); `victory_receipt_routed()` now asserted true.
  - tests/test_trainer_reward_delivery.gd `test_persistent_reward_pays_only_nonfainted_owned_creatures`: when the receipt is routed, it asserts the line reaches the progression feed (the Moment receipt) and never the message strip; the OFF branch keeps the old strip assertion. XP assertions unchanged.
- Pre-ready: tests that grep hud.json / victory_focus / victory_receipt_routed / trainer_reward_delivery: 68 + 5 tests, 0 failed; test_band_content + test_chapter_rewards 19/0; smoke_trainer_battle exit 0 (same "adopt_starter is not a swap" line as main); net smoke client_trainer_rewards: ALL CHECKS PASSED.
- Pre-existing, unchanged by this (fails identically on main be95950b): smoke_progression_feedback (landmark strip tick, creature-bed arbitration, level-up banners).

## CI co-op failure (PR #867, verify-multiplayer-shard (1), run 42541405048) — LANE-MESHY 9 Nov
- CI: smoke_net_f48_coop_loop feast step, "peer 1 fed its own Pup ()" FAIL: peer 1 cooked (feast_t1_ground +1) but `f28_feed` found no enabled "Pup · " button (pressed false, empty message), so 0 feast_feed receipts and cap 10. The CI job log does not print peer 1's feed labels.
- Local reproductions on this branch (tb/item-f41-21, victory_focus ON), `GODOT_BIN=/usr/local/bin/godot tools/net/run_net_smoke.sh f48_coop_loop`:
  - run 1 (ON): ALL CHECKS PASSED (both peers exited cleanly).
  - run 2 (ON): ALL CHECKS PASSED.
  - run 3 (victory_focus temporarily OFF in the working tree, not committed): ALL CHECKS PASSED.
- In all three runs peer 1's feed shows the same sequence: a first completion `owner_passive_checkpoint_pending` (ok false), then `ok: true` with the feast_feed receipt. The pattern is identical with the flag OFF, so the guest feed path already races the owner-passive checkpoint before this change; the flag does not touch it.
- Also: the feast step runs BEFORE the boss in this smoke (after the Master fight), so the boss victory Moment cannot affect it. The Master win's routed receipt is the only victory-focus effect before the feast, and the OFF run (no routing) shows the same pending-then-ok race.
- Conclusion: no root cause in the victory Moment to fix; the CI miss is the existing guest feast-feed race losing on a slower runner (the "no enabled button" outcome means the guest's feed list was built before its dish view arrived). Recommendation: one confirming CI rerun (the house rule for a suspected flake), and a separate multiplayer item for the guest feed race (f28 feed list refresh after the dish view, or a retry on owner_passive_checkpoint_pending in the panel). The smoke was not changed.
