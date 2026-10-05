# R2 unchanged baseline: native hitstop error

Game/source pin: `785057d4a3b48faa7445b4cc1c5d35e649466416`, equivalent to the F22 handoff's game data and relevant source/tools. Godot 4.7 stable Windows, existing imported cache copied from exact baseline `e2fa5e4e6` into the isolated R2 checkout. No asset changes or new instruments.

Existing invocation: `--headless --fixed-fps 60 --script tests/smoke_f22_pattern_bands.gd -- --seeds=12 --trainers --json=.../r2/baseline/full.json`. Pilots and sweep unchanged. Isolated APPDATA: `D:/tetherbound/.artifacts/r2-baseline-home`.

The still-running baseline logged `ERROR: Can't play finished Tween, use stop() first to reset its state.` The first original log excerpt is preserved as `native-error-first.txt`. Stack: `creature_body.gd::set_combat_hitstop(false)` → `combat_manager.gd::_end_hitstop` → `_begin_resolve` → `_perform_player_strike`.

The product release path calls `play()` on any valid flinch Tween, even if it was not paused by this hitstop and has finished in the current frame. The repair tracks and resumes only the running Tween actually paused by hitstop. It is prepared independently while the baseline continues: `combat_depth_pilot.gd` preloads `BODY` and `WILD` before the sweep begins, so the active process retains its original scripts. No game data, pilot or sweep is changed. New validation processes load the repair.

Existing focused checks on the repair: `tests/run_tests.gd -- --only=combat_feedback,hit_feedback,f21_hit_presentation`, private APPDATA `D:/tetherbound/.artifacts/r2-unit-home`. Exit 0; 23 tests, 156 assertions, 0 failed; no `ERROR` or `SCRIPT ERROR` in `hitstop-unit.log`. These cover hitstop, reduced motion and host presentation contracts; they do not independently reproduce the completed-Tween frame race. The final unchanged sweep must verify its native-error absence.

This baseline cannot be clean engine acceptance. Its complete table, fixture validity and single-hit results are pending. Final validation must retain the floor-trainer bars, all starters, Tidewake passes and the neutral worst-variance single-hit ceiling. GPU work is paused for the owner's Valheim reservation.
