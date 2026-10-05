# CI-SEGMENTS phase C: isolation audit of the packed steps

One row per packed step: 105 steps in 101 units (head after the re-review fixes).
`.github/ci/suites.yml` holds the suites; `tools/ci/packed.py` runs them.

Generated from the suites file by expanding every suite under a full
selection. For each step, the audit lists the GDScript, shell and Python
scripts the step invokes, and scans each one for:

- `user://` use;
- writes to `res://`;
- ENet or the net harness;
- `GITHUB_ENV` / `GITHUB_OUTPUT`;
- spawned processes;
- the hosting paths: `Session.host`, the title screen, the LAN beacon.

## How each shared resource is handled

| Resource | Found | How it is isolated |
|---|---|---|
| `user://` | 30 steps | Every unit gets fresh `XDG_DATA_HOME`, `XDG_CONFIG_HOME` and `XDG_CACHE_HOME`. No unit sees another's `user://`, not even one from its own former job. |
| `TMPDIR`, `RUNNER_TEMP`, `mktemp` | all steps | Fresh per unit. |
| Fixed `/tmp/...` paths | 21, each a uniquely named per-step log | No path is shared by two units. |
| Repo tree, `res://` writes | none | No change needed. |
| `GITHUB_ENV`, `GITHUB_PATH` | none written | Per step, applied within the unit (as in a job). A malformed file fails its step. |
| ENet ports | none | No packed step uses the net harness. Net smokes stay in the net shards, which have per-lane ENet ranges. |
| udp/27015 and the LAN beacon | 9 units: every step whose test/tool code, followed transitively through `res://tests|tools/...` loads, reaches `Session.host`, the title screen or the beacon. That is `title_load_game` and `title_new_game`, `gate_b_continuous`, gate-evidence shard #1/#2 and finale (through `gate_a_opening_drive.gd`), combat #3 and cloudreach-persistence. | Planned only into lane a of a runner, so no runner ever runs two of them at once (separate runners are separate machines). A bind-failure line in any step's log also fails that step. |
| Producer → consumer order | 3 chained units (7 steps: harvest 3, gate-evidence 2, segment-handoffs 2): a step without `!cancelled()` depended on every step before it | The unit keeps the whole prefix in one lane, in order. After a failure, dependent steps are skipped and `!cancelled()` steps still run, as on GitHub. |
| Step and suite time limits | all | Each unit is bounded by its suite's own `timeout-minutes`. |

## Kept as their own jobs (not packed)

- **`verify-regions-shard` (world):** a step script writes `GITHUB_ENV`, and
  an artifact upload depends on it.
- **`verify-veridian-offer`:** net group, with a named artifact.
- **`verify-cloudreach-midride-rejoin`:** two-peer, named artifacts, two
  producer processes.
- **`export`, `verify-unit-tests`, `verify-bake-freshness`:** their own
  setup, and they also run on the fast tier.
- **`verify-unbroken-chains`, the known-red jobs:** schedule-only and
  non-blocking.
- **`verify-multiplayer-shard`:** net lanes (phase A).

## Local proof (cfe997e9, 4-vCPU container)

All 8 runners ran one after another, each with its two lanes side by side:

| Runner | Result | Time |
|---|---|---|
| 1 | PASS | 1097 s |
| 2 | PASS | 855 s |
| 3 | PASS | 1149 s |
| 4 | PASS | 724 s |
| 5 | PASS | 833 s |
| 6 | PASS | 852 s |
| 7 | PASS | 895 s |
| 8 | PASS | 906 s |

- 105 of 105 planned steps PASS, each with exactly one verdict.
- 0 errors, and 0 Godot processes left after any runner.
- This container runs about 1.3× slower than a CI runner.

## Drills

**Packed lane, real Godot.** A failing step (a missing smoke script) gave a
named error:

    ::error::drill-lane-a :: Real smoke fails on purpose (missing script) -- FAIL (exit 1) (lane b)

- Its dependent step was SKIPPED by name.
- The independent step after it still ran and passed (192 s).
- The other lane's suite passed alongside it.
- The job exited 1, with no Godot process left.

**Cancellation, twice.** SIGTERM in the middle of a runner, and once a
runner killed at the 2-hour limit: every running and remaining step was
reported CANCELLED by name, and no Godot process was left.

**Net lane.**
- A missing smoke gave a named error while the other three smokes passed
  (exit 1).
- A smoke cut by `NET_SMOKE_TIMEOUT_S` gave
  `FAIL (timed out after 20 s)` by name, exit 1, with nothing left running.
- SIGTERM: none left.

## Per-step table

| Suite | Step | Unit | Scripts | user:// | Fixed /tmp | Ports | Order |
|---|---|---|---|---|---|---|---|
| verify-veg-corridor | Run the corridor vegetation regression checks | #1 | `run_tests.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-scatter-rules | Run the scatter rules regression checks | #1 | `run_tests.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-harvest | Verify f27_altar_spend | #1 | `smoke_f27_altar_spend.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | chained in one lane |
| verify-harvest | Verify release | #1 | `smoke_release.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | chained in one lane |
| verify-harvest | Run the harvest regression checks | #1 | `run_tests.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | chained in one lane |
| verify-core-verb-shard | Verify playground | #1 | `smoke_playground.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-core-verb-shard | Verify input | #2 | `smoke_input.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-core-verb-shard | Verify unstick | #3 | `smoke_unstick.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-core-verb-shard | Verify traversal | #4 | `smoke_traversal.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-core-verb-shard | Verify audio | #5 | `smoke_audio.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-core-verb-shard | Verify backpack_player_eats | #6 | `smoke_backpack_player_eats.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-catching | Verify catching | #1 | `smoke_catching.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-catching | Verify catch aim slowdown | #2 | `smoke_catch_aim_slowdown.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-a-ui-build-shard | Verify free_build | #1 | `smoke_free_build.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-a-ui-build-shard | Verify f31_station_paid_path | #2 | `smoke_f31_station_paid_path.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-a-ui-build-shard | Verify opening | #3 | `smoke_opening.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-a-ui-build-shard | Verify starter_picker | #4 | `smoke_starter_picker.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-a-ui-build-shard | Verify modal_stacking | #5 | `smoke_modal_stacking.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-a-ui-build-shard | Verify menu | #6 | `smoke_menu.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-a-ui-build-shard | Verify settings | #7 | `smoke_settings.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-a-ui-build-shard | Verify objective_hint_card | #8 | `smoke_objective_hint_card.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-a-ui-build-shard | Verify station_panels_hide_world_hud | #9 | `smoke_station_panels_hide_world_hud.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-a-ui-build-shard | Verify combat_hud_left_column | #10 | `smoke_combat_hud_left_column.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-a-ui-build-shard | Verify dialogue_clears_the_world_hud | #11 | `smoke_dialogue_clears_the_world_hud.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-a-ui-build-shard | Verify hud_freed_combat_prompt_lifecycle | #12 | `smoke_hud_freed_combat_prompt_lifecycle.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-combat-shard | Verify combat | #1 | `smoke_combat.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-combat-shard | Verify throw preview physical occlusion | #2 | `smoke_throw_preview_occlusion.gd` | own (fresh XDG per unit) | `/tmp/throw-preview-occlusion.log` | none | independent (`!cancelled()`) |
| verify-combat-shard | Verify earned party controller cycle | #3 | `smoke_earned_party_cycle.gd` | own (fresh XDG per unit) | `/tmp/earned-party-cycle.log` | none | independent (`!cancelled()`) |
| verify-combat-shard | Verify same-live Water Alpha retirement | #4 | `smoke_water_alpha_retirement.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-combat-shard | Verify riding | #5 | `smoke_riding.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-combat-shard | Verify boss | #6 | `smoke_boss.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-combat-shard | Verify trainer_battle | #7 | `smoke_trainer_battle.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-combat-shard | Verify aggression | #8 | `smoke_aggression.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-combat-shard | Verify encounter_scaling | #9 | `smoke_encounter_scaling.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-relay (meadows) | Verify relay | #1 | `smoke_relay.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-relay (meadows) | Verify stronghold | #2 | `smoke_stronghold.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-relay (meadows) | Verify art | #3 | `smoke_art.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-relay (meadows) | Verify F22 enemy patterns | #4 | `smoke_f22_live_pattern_mount.gd`, `smoke_f22_pattern_contract.gd`, `smoke_f22_wild_reactions.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-relay (tidewake) | Verify Tidewake land loops walked (reed root, brine terrace) | #1 | `smoke_water_loops_shortcuts.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-relay (tidewake) | Verify Tidewake land loops walked (salt shrine, sluice patrol) | #2 | `smoke_water_loops_shortcuts.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-relay (tidewake) | Verify Tidewake return shortcuts closed then open and shorter | #3 | `smoke_water_loops_shortcuts.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-owner-regressions-shard (catching) | Verify party_count_after_catches | #1 | `smoke_party_count_after_catches.gd`, `run_godot_smoke.py` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-owner-regressions-shard (controls) | Verify title_load_game | #1 | `smoke_title_load_game.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | hosts udp/27015 + LAN beacon: one lane for all such units | independent (`!cancelled()`) |
| verify-owner-regressions-shard (controls) | Verify title_new_game | #2 | `smoke_title_new_game.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | hosts udp/27015 + LAN beacon: one lane for all such units | independent (`!cancelled()`) |
| verify-owner-regressions-shard (controls) | Verify satchel_owns_hotbar | #3 | `smoke_satchel_owns_hotbar.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-owner-regressions-shard (controls) | Verify build_owns_creature_cycle | #4 | `smoke_build_owns_creature_cycle.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-owner-regressions-shard (controls) | Verify trainer_battle_camera | #5 | `smoke_trainer_battle_camera.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-owner-regressions-shard (controls) | Verify arena_contain | #6 | `smoke_arena_contain.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-owner-regressions-shard (controls) | Verify menu_open_does_not_offer_to_drop | #7 | `smoke_menu_open_does_not_offer_to_drop.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-evidence-shard | Verify post-miss wander aim lifecycle | #1 | `probe_gate_a_aim_wander.gd` | own (fresh XDG per unit) | `/tmp/aim-wander.log` | none | chained in one lane |
| verify-gate-evidence-shard | Verify stick navigator slope and obstacle clearance | #1 | `smoke_stick_navigator_low_geometry.gd` | own (fresh XDG per unit) | `/tmp/stick-navigator.log` | none | chained in one lane |
| verify-gate-evidence-shard | Verify gate_a_opening_segment | #2 | `smoke_gate_a_opening_segment.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-evidence-shard | Verify gate_a_build_house | #3 | `smoke_gate_a_build_house.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-evidence-shard | Verify build_two_creature_beds | #4 | `smoke_build_two_creature_beds.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-evidence-shard | Verify gate_a_rest_torch | #5 | `smoke_gate_a_rest_torch.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-evidence-shard | Verify authored_camps | #6 | `smoke_authored_camps.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-evidence-shard | Verify trainer_no_usable_ally | #7 | `smoke_trainer_no_usable_ally.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-evidence-shard | Verify night_ecology | #8 | `smoke_night_ecology.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-evidence-shard | Verify post_modal_control | #9 | `smoke_post_modal_control.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-evidence-finale (bracket-to-semi) | Verify tournament_bracket segment bracket-to-semi | #1 | `smoke_tournament_bracket.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-evidence-finale (bracket-final) | Verify tournament_bracket segment bracket-final | #1 | `smoke_tournament_bracket.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-evidence-finale (bracket-final) | Verify gate_e_finale | #2 | `smoke_gate_e_finale.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-gate-b-core | Verify gate_b_continuous (CORE — opening through tournament readiness) | #1 | `smoke_gate_b_continuous.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | hosts udp/27015 + LAN beacon: one lane for all such units | independent (`!cancelled()`) |
| verify-cloudreach-persistence | Verify Cloudreach persistence tail | #1 | `smoke_cloudreach_persistence_tail.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-segment-handoffs | Verify midride segment coverage | #1 | `check_coverage.py` | none | none (TMPDIR/RUNNER_TEMP per unit) | none | chained in one lane |
| verify-segment-handoffs | Verify midride checkpoint handoffs | #1 | `run_tests.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | chained in one lane |
| verify-segment-handoffs | Verify bracket checkpoint handoffs | #2 | `run_tests.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify Stormheart approach and open ramp entrance | #1 | `_probe_stormheart_earned_mouth.gd` | own (fresh XDG per unit) | `/tmp/stormheart-earned-mouth.log` | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify earned Stormwood input clocks | #2 | `probe_stormwood_alpha_admission.gd`, `probe_stormwood_fight_clock.gd` | own (fresh XDG per unit) | `/tmp/stormwood-engage-clock.log`, `/tmp/stormwood-fight-clock.log` | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify Stormwood constructed arch journey | #3 | `smoke_stormwood_arches.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify solo Stormwood hosted rewards | #4 | `smoke_stormwood_hosted_rewards.gd` | own (fresh XDG per unit) | `/tmp/stormwood-hosted-rewards.log` | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify Stormwood Deepwood Circuit wiring | #5 | `smoke_stormwood_deepwood_circuit_wiring.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify Stormwood finalized death lifecycle | #6 | `smoke_stormwood_finalized_death.gd` | own (fresh XDG per unit) | `/tmp/stormwood-finalized-death.log` | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify Stormwood combat telemetry | #7 | `smoke_stormwood_combat_telemetry.gd` | own (fresh XDG per unit) | `/tmp/stormwood-combat-telemetry.log` | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify Relay cable socket supports | #8 | `_probe_relay_cable_socket_geometry.gd` | own (fresh XDG per unit) | `/tmp/relay-cable-sockets.log` | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify Stormwood equipped lightning protection | #9 | `smoke_stormwood_lightning.gd` | own (fresh XDG per unit) | `/tmp/stormwood-lightning-equipment.log` | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify controller equipment and disk save | #10 | `smoke_backpack_equipment.gd` | own (fresh XDG per unit) | `/tmp/backpack-equipment.log` | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify Stormwood lightning warning cleanup | #11 | `smoke_stormwood_lightning_cleanup.gd` | own (fresh XDG per unit) | `/tmp/stormwood-lightning-cleanup.log` | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify Stormwood authoritative opponent teardown | #12 | `smoke_stormwood_authoritative_teardown.gd` | own (fresh XDG per unit) | `/tmp/stormwood-authoritative-teardown.log` | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify Stormwood heartstone interaction | #13 | `smoke_stormwood_crown_heartstone.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify Stormwood Crown records side chain | #14 | `smoke_stormwood_crown_records.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify Stormwood per-participant Stormheart offers | #15 | `smoke_stormwood_stormheart_participants.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify Stormwood Stormheart accept/refuse choice | #16 | `smoke_stormwood_stormheart_choice.gd`, `run_godot_smoke.py` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify Stormwood Dynamo Break faint recovery | #17 | `smoke_stormwood_dynamo_break_faint.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify Stormwood ordinary and electric TM pickups | #18 | `smoke_stormwood_pickup_runtime.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify ordinary Stormwood to Water gate path | #19 | `smoke_stormwood_water_gate_path.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify Stormwood Surge audio observer | #20 | `smoke_stormwood_surge_audio.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify Stormwood hosted encounter admission | #21 | `smoke_stormwood_hosted_admission.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (stormwood) | Verify Stormwood Nysa press | #22 | `smoke_stormwood_nysa_press.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (tidewake) | Verify Tidewake closed-gate tide-race seal | #1 | `smoke_water_closed_gate_seal.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (tidewake) | Verify Tidewake dismount leaves no mounted state | #2 | `smoke_water_dismount_state.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (tidewake) | Verify Tidewake drowning and safe shore | #3 | `smoke_water_swimming.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (tidewake) | Verify Tidewake drowned recovery | #4 | `smoke_water_player_death.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (tidewake) | Verify Tidewake reload mid-water | #5 | `smoke_water_reconnect_save.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (tidewake) | Verify Tidewake mounted reload mid-water | #6 | `smoke_water_mounted_reconnect_save.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (tidewake) | Verify Tidewake combat pause while swimming | #7 | `smoke_water_combat_pause.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (tidewake) | Verify Tidewake Guardian offer keeps controller focus across a drop | #8 | `smoke_water_guardian_drop_refocus.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (tidewake) | Verify Tidewake chain side_water_lantern_return | #9 | `smoke_water_lantern_return.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (tidewake) | Verify Tidewake chain side_water_gull_research | #10 | `smoke_water_gull_research.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (tidewake) | Verify Tidewake chain side_water_cradle_care | #11 | `smoke_water_cradle_care.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (tidewake) | Verify Tidewake chain side_water_garden_records | #12 | `smoke_water_garden_records.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (tidewake) | Verify Tidewake chain side_water_deep_watch_chart | #13 | `smoke_water_deep_watch_chart.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (tidewake) | Verify Tidewake chain side_water_lastlight_shelter | #14 | `smoke_water_lastlight_shelter.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (tidewake) | Verify regional credits survive a disk reload | #15 | `smoke_regional_credits_reload.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
| verify-regions-shard (tidewake) | Verify pending regional ending receipts and reconnect rejection | #16 | `smoke_regional_homecoming_pending.gd` | own (fresh XDG per unit) | none (TMPDIR/RUNNER_TEMP per unit) | none | independent (`!cancelled()`) |
