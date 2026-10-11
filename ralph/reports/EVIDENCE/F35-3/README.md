# F35#3 — presentation 2–3 s, control returns after (lane tb/ev-ultimates)

Commit: 77b57674 adds `test_f23_live_moves.gd::test_ultimate_control_returns_when_its_presentation_ends`
(the "control-restore timing test" gap; the existing test only summed the raw row's windup+recovery).

The test, run for every authored ultimate (31):
- builds the actual host profile with `CombatManager.host_move_profile(..., "player_ultimate", ...)`;
- asserts presentation_seconds is in [2, 3] (2.4 for all), recovery equals the presentation, and
  windup + recovery <= 3 s (0.51 + 2.4 = 2.91 s after player_pace 0.85);
- runs the real action clock (`_tick_action`, 1/60 s steps) from RECOVERY, the state entered when the
  wind-up launches the presentation, and asserts Action.READY comes back within one tick of the presentation
  end, with no committed move left behind.

Command: `godot --headless --path . --audio-driver Dummy --script res://tests/run_tests.gd --
--only=test_f23_live_moves.gd,test_move_effects.gd` -> 36 tests, 2867 assertions, 0 failed (the new test ok).

Disclosures: the test doesn't cover readability in four-player fights. That part of F35#3 needs the
GPU four-at-once captures. The 9 `!is_inside_tree()` engine errors in this suite also appear on
the base branch; the new test adds none.
