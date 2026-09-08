# SAVE lane — atomic and recoverable save proof

Date: 2026-09-07  
Branch: `codex/save-proof-0907`  
Starting tree: PR #79 merge `7ab4a12647a377a400c43335b64aff8b03ca6d43`

## Verdict

**PASS after repair.** The landed rewrite was not safe as written: a corrupt canonical
JSON file masked a valid `.previous` file, and a subsequent save could discard the valid
recovery document before the new commit was installed. In addition, `SaveGame.save()`
reported success after the slot write even if its world/character split failed, leaving
different generations on disk.

The repair makes JSON-object validity the selection rule for canonical versus
`.previous`, preserves a valid recovery document while replacing a corrupt canonical,
deletes both generations, and rolls slot/world/character back to their retained recovery
generation when either split writer refuses. The helper still makes no OS `fsync` claim; Godot
exposes `flush`, and this is the bounded per-file plus synchronous split-failure guarantee
the contract asks to prove.

All destructive fixtures use a random `user://test_atomic_save_<random>/` scratch tree
and are recursively removed after each test. No production or owner save path is touched.

## Ordered exit proof

| Item | Before fixture / injected fault | After / asserted result | Evidence |
|---|---|---|---|
| 1. Existing save loads | A directly written v22 slot, no `.previous`, representing the pre-rewrite single-file shape | Production `SaveGame.load_slot()` migrates it to v23 and restores day, realm and party | `test_pre_rewrite_slot_without_previous_loads_through_production_loader` |
| 2. Every reader falls back | Canonical absent or corrupt with valid `.previous` | Slot existence, slot metadata/title listing, slot load, world `has/list/read`, character `has/list/read/apply`, and delete all use the recovery generation | `test_interrupted_replacement_reloads_through_all_save_readers`; `test_corrupt_canonical_falls_back_for_*`; `test_delete_removes_canonical_and_backup_for_every_save_store` |
| 3. Corrupt canonical is distinguished | Truncated canonical beside valid `.previous`; separate corrupt-only slot | Recovery copy is selected before trust; corrupt-only slot is not listed as a save; no parser error is emitted on the accepted implementation | `test_corrupt_canonical_falls_back_for_*`; `test_corrupt_canonical_without_valid_backup_is_not_listed_as_a_save`; clean focused log |
| 4. Split failure is propagated | Existing day-7 slot/world/character; changed day-12 snapshot; injected character-writer refusal after slot and world succeed | `save()` returns false; slot/world remain day 7; character remains Meadows; no `.previous` residue remains | `test_character_half_failure_rolls_slot_and_world_back_to_same_generation` |
| 5. Failure tests are real | Three temporary feature removals: short-write verification removed; validity-aware fallback removed; split rollback removed | Expected-red runs returned 1: 2/2 short-write cases failed with a published truncation; 3/3 corrupt-recovery cases failed; split test exposed day 12 slot/world against old character | Mutation commands and results below |
| 6. Full suite | Required because this is save-format/autoload-adjacent | Every save test passed. The repository-wide run reached a real terminal result but remains red in two untouched Gate-F harness methods (five assertion messages); see the external blocker below. | `save-full-suite-clean.log`; ownership diff against the starting tree is empty for both failing files |

## Mutation proof

The source was restored immediately after each expected-red run, then the full focused
suite was rerun green.

```text
--only=test_atomic_save_file.gd::test_short
2 tests, 7 assertions, 2 failed; exit 1 (expected red)

--only=test_atomic_save_file.gd::test_corrupt_canonical
3 tests, 20 assertions, 3 failed; exit 1 (expected red)

--only=test_atomic_save_file.gd::test_character_half_failure
1 test, 11 assertions, 1 failed; exit 1 (expected red)
observed without rollback: slot day 12, world day 12, character still old
```

## Validation

Godot: `C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe`

```text
godot --headless --path . --import --log-file save-import.log
PASS; zero ERROR/SCRIPT ERROR/Parse Error lines

godot --headless --path . --script res://tests/run_tests.gd -- --only=test_atomic_save_file
18 tests, 114 assertions, 0 failed

godot --headless --path . --script res://tests/run_tests.gd -- --only=<11 save-format selectors>
155 tests, 1,030 assertions, 0 failed

godot --headless --path . --script res://tests/smoke_save_persistence.gd
PASS: exact pose, opening/starter, Tam gift, TM/key one-shots, and controls survived a real Meadows save/load

godot --headless --path . --script res://tests/smoke_title_load_game.gd
title load game: OK -- physical pad activation loaded a real save and entered Meadows

godot --headless --path . --script res://tests/smoke_clock_survives_a_reload.gd
clock-survives-a-reload smoke passed

godot --headless --path . --script res://tests/smoke_finale_persistence.gd
finale persistence smoke passed

godot --headless --path . --log-file save-full-suite-clean.log --script res://tests/run_tests.gd
2,871 tests, 3,834,666 assertions, 2 failed methods (five assertion messages); exit 1
```

## Full-suite external blocker

The two failed methods are outside SAVE ownership and neither their tests nor their
production surfaces differ from starting tree `7ab4a126` on this branch:

```text
test_gate_f_harness_predicates.gd::test_the_route_row_thresholds_leave_headroom_below_the_shortest_run
  S04 threshold is 420 rows vs shortest healthy 363 (115.7%; test ceiling 85%)
  S05 threshold is 970 rows vs shortest healthy 500 (194.0%; test ceiling 85%)

test_gate_f_rig.gd::test_the_runner_declares_its_own_logic_lane_so_a_run_can_start
  bash tools/gate_f/run_segment.sh --write-lane-declaration ... returned -1
  no freeze record was written; the absent record was not a JSON object
```

Read-only ownership classification:

```text
git diff --name-only 7ab4a126 -- \
  tests/test_gate_f_harness_predicates.gd tests/test_gate_f_rig.gd \
  tests/test_vegetation_siting.gd scripts/world/vegetation.gd
<empty>
```

The run also emitted existing headless fixture diagnostics, including detached-node
renderer errors and `CountingVegetation.restore_drained` argument mismatch script
errors. They did not fail their test methods. SAVE neither changes nor hides those
diagnostics. No Godot process remained after the run.

## 180-second fallback autosave boundary

This repair touches the same synchronous save path observed in STAB but does **not**
remove its hitch. It removes the earlier draft's full-byte capture rollback, but a
normal split save still snapshots state, serializes JSON, validates existing JSON,
writes/flushes/reopens the staged bytes, and commits slot/world/character on the main
thread. The 536.7 ms frame at `_autosave_elapsed 180.0 -> 0.0` therefore remains a
separate scheduling/performance defect, not evidence against the recovery semantics.

The safest next strategy is phase timing first, then a single-flight fallback-autosave
worker fed an immutable snapshot, with queued requests coalesced and explicit completion
on the main thread. Bed/quit/manual durability boundaries must still wait for completion,
and the atomic writer plus split rollback tests must remain unchanged. Spreading the
three file commits across ordinary frames without a generation manifest is not safe: a
process death between frames can expose mixed generations.
