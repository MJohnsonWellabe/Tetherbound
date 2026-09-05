# N01-SAVE-FORMAT-0905 — report

**Lane:** N01-SAVE-FORMAT · **Branch:** `ralph/N01-SAVE-FORMAT-0905` (from `origin/main` at
`f8a47ee4`) · **Kind:** test repair; one test file, no game code, no data.
**Commits:** `d10e4ef8` (the test repair, WIP-marked), `9a89d3e0` (report draft), and the final commit that closes this report on top of them — `git log -1 origin/ralph/N01-SAVE-FORMAT-0905`. The tree is identical from `d10e4ef8` onward except for this report and one `CURRENT_STATE.md` row.

**Brief:** the session was opened as "Lane N01-SAVE-FORMAT (Fable): fix the 5 false-passing
save-format tests" with the instruction to read `ralph/briefs/0905-followup/COMMON.md` and
`N01-SAVE-FORMAT.md`. **Neither file exists on any branch of `origin`** (checked `main` at
`f8a47ee4` and every `refs/heads/*` three times across the session, the last just before the
final commit; `ralph/briefs/` holds only `0904/LANES.md`). The lane therefore worked from the session title, the 0904 lane conventions
(`ralph/<LANE>-<date>` branch, `ralph/reports/<LANE>-<date>/REPORT.md`, `docs/AGENT_WORKFLOW.md`
§4 completion contract), and this repository's own testing rules. Every call that a brief
would normally settle is recorded under "Calls made without the brief" below.

## One line per item, up front

| Item | Verdict |
|---|---|
| Identify the five false-passing tests in `tests/test_save_format.gd` | **done** — the five in the "tournament across a save (26-RG19)" section; mechanism confirmed by running the file |
| Make each of the five actually execute its assertions | **done** |
| See each go red for the right reason before calling it green | **done** — four loader mutations, each fails exactly the tests it should |
| Full `test_save_format.gd` green after the repair | **done** — 56 tests / 304 assertions / 0 failed, 0 SCRIPT ERROR lines (was 279 assertions with 5 SCRIPT ERROR lines) |
| Full unit suite (the rule for save-format changes, `docs/AGENT_WORKFLOW.md` §6) | **done** — 2004 tests / 3,765,645 assertions / 0 failed, exit 0, 2348 s; the log carries **10 SCRIPT ERROR lines, none from this file** — all ten are `test_shiny.gd`, five more tests with the identical defect, handed over below |
| Systemic fix so an aborted test method cannot read as `ok` again | **not done, deliberately** — `tests/run_tests.gd` and `ci.yml` are shared harness files outside a one-file test-repair lane; the gap and two candidate fixes are handed over below |

## The defect

`save_game.gd`'s API is `save(game, slot)` and `load_slot(game, slot)`. The `Game` autoload
(`autoload/game_state.gd`) wraps those as `save_game(slot)` and `load_game(slot)`. Commit
`d409939e` (2026-08-22, "Tests: the tournament across a save, which 26-RG19 required and
nothing covered") added five tests that call `saver.save_game(game, 0)` and
`saver.load_game(loaded, 0)` on the **saver**, where neither method has ever existed:

1. `test_a_half_fought_bracket_survives_a_save`
2. `test_the_board_reads_the_same_bracket_after_a_reload`
3. `test_a_won_tournament_cannot_be_reloaded_into_a_second_payout`
4. `test_condition_survives_a_save`
5. `test_a_pre_condition_save_loads_at_the_configured_start`

GDScript aborts the running method on a call to a nonexistent function and prints a
`SCRIPT ERROR`. `tests/run_tests.gd` runs each test with `instance.callv(method, [])` and then
reads only `instance.failures`; an aborted method has appended nothing, so it prints `ok`. On
unmodified `main` the file reports every one of those five as `ok` while the same log carries
five `Invalid call. Nonexistent function 'save_game' in base 'RefCounted (save_game.gd)'` lines
(reproduction below). CI's unit-test jobs do not grep their logs for `SCRIPT ERROR` (only the
import step does, `ci.yml` line ~440), so this has been invisible for fourteen days across
every green run. `docs/CURRENT_STATE.md` §2 lists `test_save_format` as green on that basis.

Two further defects were latent behind the abort and would have turned the tests red the
moment the method names were fixed:

- `test_a_pre_condition_save_loads_at_the_configured_start` rewrote `"%ssave_0.json" % TEST_DIR`;
  the saver writes `slot_%d.json`. `FileAccess.open` returned null and the next line aborted.
- `test_condition_survives_a_save` set `happiness` to 88, then called
  `CONDITION.note_rest_completed`, which pays `happiness.on_rest_completed` (12, clamped at the
  meter's max of 100), and then asserted the reload came back at 88. The creature held 100 at
  save time. The assertion was wrong, not the save format.

## Files changed

| File | Change |
|---|---|
| `tests/test_save_format.gd` | the five tests call `saver.save()` / `saver.load_slot()`; the pre-condition test opens `saver.slot_path(0)`; the condition test pins the values the creature actually holds at save time (and asserts they differ from the class defaults, so a loader that dropped the keys cannot pass) and additionally round-trips `rested_seconds_left`; the pre-condition test dirties the in-memory creature before loading so "came back at the start value" cannot be "the loader left the party alone"; a section comment records the defect |
| `ralph/reports/N01-SAVE-FORMAT-0905/REPORT.md` | this file |
| `docs/CURRENT_STATE.md` | the Save / load row in §2 names the repair and the date |

No game code, data, scene, harness or CI file was touched. `scripts/save/save_game.gd` was
mutated locally four times for the red-for-the-right-reason runs below and restored with
`git checkout` each time (`git status` clean of it before the commit).

## Reproduction on unmodified `main`

`tests/test_save_format.gd` exactly as on `origin/main` `f8a47ee4`, in this container after a
clean `godot --headless --path . --import` (exit 0, 0 SCRIPT ERROR lines in the import log):

```
$ godot --headless --path . --script tests/run_tests.gd -- --only=test_save_format.gd
  ok    test_save_format.gd :: test_a_half_fought_bracket_survives_a_save
  ok    test_save_format.gd :: test_a_pre_condition_save_loads_at_the_configured_start
  ok    test_save_format.gd :: test_a_won_tournament_cannot_be_reloaded_into_a_second_payout
  ok    test_save_format.gd :: test_condition_survives_a_save
  ok    test_save_format.gd :: test_the_board_reads_the_same_bracket_after_a_reload
56 tests, 279 assertions, 0 failed        (exit 0)

$ grep -c "SCRIPT ERROR" baseline.log
5
$ grep "Nonexistent" baseline.log | sort | uniq -c
      5 SCRIPT ERROR: Invalid call. Nonexistent function 'save_game' in base 'RefCounted (save_game.gd)'.
```

Five `ok` lines, five aborts, exit 0. None of the five reached its first assertion: each one's
first statement is `assert_true(saver.save_game(...))`, and the argument is evaluated before
`assert_true` is entered.

**After the repair**, same command: `56 tests, 304 assertions, 0 failed`, exit 0, **0** SCRIPT
ERROR lines. The 25 extra assertions are exactly the five bodies now running (5 + 3 + 5 + 8 + 4,
counted by hand against the source), so nothing else in the file changed behaviour.

## Red for the right reason

Each mutation was applied to `scripts/save/save_game.gd` on top of the repaired test file, the
file was run, and the loader was restored before the next.

| Mutation in `save_game.gd` | Simulates | Must fail | Failed |
|---|---|---|---|
| **M1** `load_slot`: progression flags loaded as `{}` | the bracket not surviving a save | the three bracket tests | `test_a_half_fought_bracket_survives_a_save` ("'tournament_entered' did not survive the save; the player is back outside the bracket"), `test_the_board_reads_the_same_bracket_after_a_reload` ("expected Tournament board: Semi-final, you vs Tam, got Tournament board: the draw is open"), `test_a_won_tournament_cannot_be_reloaded_into_a_second_payout` ("the victory flag did not survive; the final would pay out again") — plus the two pre-existing flag round-trip tests that read the same line. 5 failed |
| **M2** `_array_to_party`: `nourishment` / `happiness` / `rested_seconds_left` taken from the defaults, never from the file | a fed, rested team coming back hungry | `test_condition_survives_a_save` | that one only: "expected 91 got 70 (the team came back hungry)", "expected 100 got 55 (the team came back miserable)", "expected 2700 got 0 (the rest clock did not survive)". 1 failed |
| **M3** `_migrate_v12`: a pre-D68 creature is written `nourishment: 0.0`, `happiness: 0.0` | a version-12 save coming back starving | `test_a_pre_condition_save_loads_at_the_configured_start` | that one only: "expected 70 got 0 (a creature from before the model came back starving rather than unmeasured)". 1 failed |
| **M4** `load_slot`: inventory loaded as `[]` | the payout coming back wrong | `test_a_won_tournament_cannot_be_reloaded_into_a_second_payout` | that one ("expected 40, got 0 (the reward did not come back exactly once)") plus the three pre-existing inventory round-trip tests. 4 failed |

Every run: 56 tests, 304 assertions, 0 SCRIPT ERROR lines, exit 1. No mutation failed a test it
had no business failing, and the tests that fell alongside the targets read the same loader line
the mutation removed. Loader restored with `git checkout scripts/save/save_game.gd` after each;
the final commit's diff carries no change to it.

The M2 messages also show why the original 88.0 expectation was wrong: the creature holds
**100** happiness at save time, not 88, because `note_rest_completed` paid its +12.

## Tests run, exact commands

All in this container (4 cores, Godot 4.7-stable, fresh import cache), all foreground, no
retries, each command run once unless stated:

| Command | Result |
|---|---|
| `godot --headless --path . --import` | exit 0; 0 SCRIPT ERROR |
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_save_format.gd` on `main`'s file | 56 tests / 279 assertions / 0 failed; **5 SCRIPT ERROR** (the defect) |
| same, repaired file | **56 tests / 304 assertions / 0 failed; 0 SCRIPT ERROR** |
| same, under M1 / M2 / M3 / M4 | 5 / 1 / 1 / 4 failed, as tabled above |
| `godot --headless --path . --script tests/run_tests.gd` (full suite, repaired file) | **2004 tests / 3,765,645 assertions / 0 failed**, exit 0, 2348 s (39 min, 4 cores); 10 SCRIPT ERROR lines, all in `test_shiny.gd` (see handover), 0 in `test_save_format.gd` |

## Runtime validation

None beyond the unit file: this lane changes a test, not a player path. The save format itself
is unchanged; `smoke_save_persistence` and `test_autosave_fallback` were not affected and were
not the lane's to re-run, though the full suite above includes `test_autosave_fallback`.

## Calls made without the brief

- **Branch and report names** follow the 0904 convention with the date changed:
  `ralph/N01-SAVE-FORMAT-0905`, `ralph/reports/N01-SAVE-FORMAT-0905/`.
- **Scope held to the test file.** The title says "fix the 5 false-passing tests", so the
  runner and CI were left alone even though the mechanism that hid the defect lives there.
- **The condition test was corrected, not deleted.** Its 88.0 expectation was a wrong number;
  pinning the pre-save value keeps the test's stated intent (a fed, rested, happy team comes
  back that way) and strengthens it with the rest clock.
- **No decision record.** Nothing here is a game-behaviour decision. Next free number stays
  D87 per the ledger.
- **`CURRENT_STATE.md` edit is one row.** The landing lane owns the ledger; the status table
  row that claimed the file green is the only line whose claim this lane changes.

## Handover: the gap that let this ship

A test method that dies on a script error is indistinguishable from one that passed, to
`run_tests.gd` and to CI. Two fixes, either sufficient, for whoever owns the harness:

1. **In `ci.yml`**, capture each unit-test job's log and fail the job when it contains
   `SCRIPT ERROR`, the same way the import step already does. Cheapest; catches every file.
2. **In `run_tests.gd`**, fail a test method that recorded zero assertions. Catches an abort
   before the first assert (all five here) but not one after it; would need a sweep for any
   legitimately assertion-free test first.

Until one lands, a `grep -c "SCRIPT ERROR"` over a shard log is the only way to know the
number of `ok` lines means anything.

**Five more of these exist right now, in `tests/test_shiny.gd`, found by that grep over this
lane's full-suite log.** Its `_roll()` helper (line 47) calls
`encounter_director._roll_wild_level` via `call` with the wrong number of arguments ("Expected 4
argument(s)"), the call aborts, and line 76 / 88 / 97 / 113 / 126 then index `'wild'` on the
empty result and abort again — so `test_same_seed_rolls_the_same_shiny_outcome_every_time`,
`test_a_seed_below_the_odds_threshold_rolls_shiny`,
`test_a_seed_above_the_odds_threshold_does_not_roll_shiny`,
`test_existing_level_and_individuality_draws_are_unchanged_by_the_shiny_roll` and
`test_existing_level_and_individuality_draws_are_unchanged_for_a_second_seed` all print `ok`
with no assertion run. The shiny roll has no working regression coverage. **Not touched by this
lane** (a creature/encounter file, not save format); it needs its own owner, and it is the reason
fix 1 above should land before the next lane wave rather than after. The lane checked the repaired file's own run: 0 SCRIPT ERROR lines on the repaired file, against 5 on `main`'s.

## Known limitations

- `test_a_pre_condition_save_loads_at_the_configured_start` cannot tell "the v12 migration
  wrote the configured start" from "the class default happened to equal the configured
  start": both are 70 / 55 and `creature_condition.config()` is a cached static read of the
  shipped JSON, so the test cannot inject a different start. It does catch the failure it names
  (a pre-D68 creature coming back starving at 0), proven by mutation M3.
- The full suite was run once in this container; timings are not CI timings.
