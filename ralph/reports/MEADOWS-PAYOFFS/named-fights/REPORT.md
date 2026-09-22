# Named Meadows fights: audit and the check that keeps them distinct

ROADMAP Phase 1 item 7. Audit Quarry/captains/Warden against BOSSES -- what
identifies the fight, what the player does differently, what changes afterward
-- reusing the per-body combat override rather than branching the combat
manager.

## What the audit found

The Meadows named fights already satisfy BOSSES §2. This is the honest result,
and it is worth less than it sounds: nothing connected the prose to the data,
so the match was true today and unenforced tomorrow.

Every profiled fight carries its behaviour in `combat` blocks on trainer team
members, read by `wild_creature.gd`'s per-body `combat_override` (assigned in
`encounter_director.gd:787`/`5209`). No combat-manager branch is involved, and
ordinary wild bodies with no override fight exactly as before.

| Fight | BOSSES row | Data |
|---|---|---|
| `relay_captain` | Tuskroot CHARGER | member 3 CHARGER (range 4.5, lunge 7.0) |
| `captain_riverwatch` | WALL -> baseline -> CURRENT | members 1 and 3 overridden, 2 clean |
| `captain_field` | baseline -> CHARGER -> CURRENT | members 2 and 3 overridden, 1 clean |
| `stronghold_elite` | DIVER -> baseline -> WALL | members 1 and 3 overridden, 2 clean |
| `warden_aldis` | WALL -> DIVER -> CURRENT -> CHARGER -> ACE | all five overridden |

`quarry_picket_dorn` and `warrens_watch_pell` have no profile, and should not.
BOSSES calls them a "quarry gate baseline" and a "cave-door composition" on
purpose and says trainer ladders "do not acquire artificial boss phases".
Demanding profiles there would contradict the document item 7 audits against.

## The check

`tests/test_named_fight_profiles.gd` -- 7 tests, 53 assertions with docs present,
43 without.

1. BOSSES still names all five fights (keeps the list from going stale).
2. Each profiled fight carries an authored override, not a name and more HP.
3. The override lands on the creature BOSSES names, positionally: a row's
   baseline slot stays a baseline, because the contrast is what the named steps
   are read against.
4. Each profiled fight changes something afterwards (defeat flag or reward flag).
5. A profile means the same thing wherever it is used. `power` is excluded --
   it follows the level band -- so the pin is on timings, ranges and poise.
6. A baseline gate is *not* required to be a boss. This is the guard that keeps
   the file honest against a future "fix" that adds profiles everywhere.

Band trainer files are discovered by scanning `data/config/bands/*/trainers.json`
rather than a pinned path list, and the scan asserts it found something: the
first draft used guessed folder names, found no trainers, and would have passed
vacuously had the lookup not been asserted. Two vacuity floors do the same job
for the sequenced rows (>= 3 checked) and the profile reuses (>= 3 compared).

Assertion 5 is derived from the current data, not from a line in BOSSES. It
holds today with no data change: WALL is the same WALL in the river lock, the
stronghold approach and the Hall. If a fight is later meant to hold a genuinely
different WALL, the right answer is a new profile name in its row -- but that is
the owner's decision, and this test failing is how the question gets asked
instead of lost.

## CI cannot read the document, and the first version of this file did not know

The first version asserted BOSSES was readable and passed locally. It failed in
CI with "BOSSES.md must be readable" and every prose-derived check going quiet --
because every CI job's sparse checkout excludes `/docs/` (`docs/.gdignore`
keeps Godot out of it locally too). That is also why no other test in this
repository reads a design document: it does not work there.

So the sequences are TRANSCRIBED into the test as `MEADOWS_SEQUENCES`, the data
checks run off the transcription -- in CI, where they matter most -- and a
further test compares the transcription against the real BOSSES rows wherever
docs are present, so the copy cannot drift from the source it enforces. Where
the document is absent, that test says so rather than passing silently.

## Evidence

Focused run, actual terminal results:

    godot --headless --path . --script tests/run_tests.gd -- --only=test_named_fight_profiles.gd
    7 tests, 53 assertions, 0 failed

Same file with `docs/` moved aside, reproducing CI's checkout:

    7 tests, 43 assertions, 0 failed

Mutation check, so the pass is not vacuous: stripping `combat` from
`captain_field`'s members makes assertion 2 fail with
"BOSSES gives 'captain_field' a named behaviour profile, but not one of its
members carries an authored override". The data was restored and `git diff` on
that file is empty.

## Not done here

Item 7's other half -- "real player-camera tells/hit windows" -- is a judgement
against the running fight camera, which is item 2's open guardian readability
work and the owner's to accept. This slice does not claim it. The complete
Hall/Warden route is covered by the two-peer `--hall` leg (46 checks, 0 failed)
under this lane, not by this file.
