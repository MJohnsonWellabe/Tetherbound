# N01-SAVE-FORMAT

**Source:** W13-PROGRESSION-FEED-0904's report, §6b addendum.

## Why
`tests/test_save_format.gd` has five tests that report green while never executing their
assertions — they call `saver.save_game(...)`/`saver.load_game(...)`, which do not exist on
the real save API (`save`/`load_slot`), so every one aborts on line 1 with
`Invalid call. Nonexistent function 'save_game'` and the test runner still counts it as a pass
because the abort happens before any assertion. These five cover real, never-verified
behaviour: a half-fought tournament bracket surviving a save, a won tournament not double-
paying on reload, and creature condition surviving a save.

## Owns
`tests/test_save_format.gd` only.

## Do
1. Confirm the real API by reading the ~30 other call sites in the same file already using
   `saver.save(...)` / `saver.load_slot(...)` correctly.
2. Rename the five broken call sites (as of `f8a47ee4`, expect these test names — line numbers
   may have shifted, find them by function name):
   - `test_a_half_fought_bracket_survives_a_save`
   - `test_the_board_reads_the_same_bracket_after_a_reload`
   - `test_a_won_tournament_cannot_be_reloaded_into_a_second_payout`
   - `test_condition_survives_a_save`
   - `test_a_pre_condition_save_loads_at_the_configured_start`
   Mechanical rename only: `saver.save_game(` → `saver.save(`, `saver.load_game(` →
   `saver.load_slot(`. Match the calling convention (arguments, return handling) already used
   by the correct call sites in the same file — do not guess a different signature.
3. **Expect real failures once these actually run for the first time.** That is not a sign
   your rename is wrong — it's the whole point of the fix. Root-cause and fix whatever each
   newly-executing assertion finds, inside this file and the save system it's testing
   (`scripts/save/save_game.gd` — check with the coordinator/report a routed finding if the
   real bug turns out to need a change outside `save_game.gd` and this test file).

## Verify
- Run `godot --headless --path . --script tests/run_tests.gd -- --only=test_save_format.gd`
  before your fix (confirm the 5 false-passes) and after (confirm they now execute and, once
  any real bugs are fixed, pass for real).
- Run the full file's suite and the wider save-adjacent suite (`test_bond.gd`,
  `test_progression_feed.gd`, `test_candy_progression_safety.gd`) to confirm no regression.

## Acceptance
All five tests execute their bodies and pass for a real reason (seen failing first, per
COMMON.md's testing discipline), or — if a real bug surfaces that needs a fix outside this
file's ownership — the exact bug and reproduction are documented as a routed finding and the
test itself is left honestly red with that note, not silently skipped or weakened.
