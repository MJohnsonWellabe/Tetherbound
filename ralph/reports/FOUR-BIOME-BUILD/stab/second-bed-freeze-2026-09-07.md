# STAB — second Creature Bed freeze

Branch base: `7ab4a12647a377a400c43335b64aff8b03ca6d43`

Date: 2026-09-07

Verdict: **the re-entrant bed-placement hang is fixed; the broader owner freeze
contract is still red on the synchronous 180-second fallback autosave.**

## Reproduction and cause

The new production-world smoke was first run against the unchanged base:

```text
Godot_v4.7-stable_win64_console.exe --headless --path . \
  --script tests/smoke_build_two_creature_beds.gd
```

The first controller placement never settled. Godot continuously emitted stack
overflow traces through this synchronous loop:

```text
ledger_rpc._commit_here
  -> sequence_director._on_ledger_delta
  -> sequence_director._share_the_camp
  -> home_progress.maybe_set_creature_beds
  -> home_progress._grant
  -> story_ledger.write_flag
  -> ledger_rpc.submit/_commit_here
```

The process produced more than 100 MB of repeated traces before it was stopped.
This confirms prompt 77 §STAB-LEADS H1. `maybe_set_creature_beds()` granted every
standing rung again even when `progression.has(flag)` was already true, and every
grant synchronously committed a new sequence-numbered delta that re-entered the
same function. The fix skips already-earned monotonic rungs before submitting a
ledger grant.

## Regression proof

`tests/smoke_build_two_creature_beds.gd` boots the production Meadows world with
its real `SequenceDirector`, resets the same in-place state used by New Game,
places each bed from a physical joypad `build_place` event, and asserts that each
placement retires its ticket. It performs ten fresh-state two-bed cycles in one
world boot. Each cycle emitted exactly four deltas: one building delta and one
new player-flag delta per bed. The regression uses a test-only save directory.

Clean final command:

```text
Godot_v4.7-stable_win64_console.exe --headless --path . \
  --script tests/smoke_build_two_creature_beds.gd -- --soak-seconds=180
```

Placement result:

```text
two-bed run 1/10 ... 10/10 settled with 4 total deltas
```

No run hung and no placement ticket remained. The smoke is added to the Gate A
evidence shard with no retry.

Related checks:

- `tests/smoke_gate_a_build_house.gd`: PASS.
- `tests/test_realm_world_records.gd`: 4 tests, 46 assertions, 0 failed.
- `tests/test_autosave_fallback.gd`: 4 tests, 5 assertions, 0 failed.

## Remaining freeze-contract failure

The same final run measured wall-clock gaps for a 180-second soak. Per the
contract, the first minute is reported separately and only seconds 60–180 gate
the 250 ms threshold:

```text
warmup max:       572.4 ms at soak 59.5 s; autosave 64.1 -> 64.2 s
post-warmup max:  536.7 ms at soak 175.9 s; autosave 180.0 -> 0.0 s
                  (fallback autosave fired)
```

The post-warmup result fails the written bar. Its exact coincidence with
`GameState._tick_autosave()` resetting `_autosave_elapsed` identifies the
remaining cause: the fallback calls `autosave_here()` synchronously on the main
thread, and the current save path snapshots, JSON-stringifies, atomically writes,
and writes the split world/character files before returning. Moving or staging
that serialization belongs with the concurrent SAVE lane because it changes the
save transaction now governing every biome; this lane did not alter it.

The owner hardware result also remains required: the headless Windows proof
eliminates the bed recursion and names the autosave hitch, but it is not a
substitute for the first-hour shipped-build run on the ROG Ally.
