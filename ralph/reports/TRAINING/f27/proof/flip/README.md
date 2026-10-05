# F27 actor_vitals flip: flag-on proof (`tb/f27`)

The flip commit is `00c35830`: `combat.json actor_vitals.runtime_enabled` true, and `smoke_net_f27_guest_wild_win` gets the exact `# peers: 2` header.
The head includes merged main through #539 and the B1 fix `26959092`.

## Product fixes (flag-on only bugs)

| Commit | Bug | Witness |
|---|---|---|
| `4bcd1edb` | The trainer round re-seat blanked the host's bound creature, so every host strike from round two was `stale_actor`. | `test_actor_vitals_authority::test_round_reseat_without_uid_keeps_the_bound_active_creature` (fails without the fix) |
| `ed83bd92` | A lazily bound trainer/boss actor made every participant's first attack `move_start_required`. | `test_director_join_snapshot` native guest-trainer cases, unchanged (fail without the fix) |
| `26959092` | Review finding B1: guests were re-seated without a character, so a departed guest came back blank. | `test_actor_vitals_authority::test_trainer_round_reseat_restores_a_departed_guests_retained_row` (fails without the fix) |

Independent review of `4bcd1edb` and `ed83bd92`: PASS WITH ISSUES. Its one blocking finding, B1, is fixed in `26959092`.

## Fixture changes

These fall under exception (a): production now requires an owned, host-bound fighter, and the host decides catches and HP from its own records. No assertion was removed or loosened.

- `ef814a8e`: smoke_party_count_after_catches, smoke_catch_respawn_fresh_individual.
- `eda3ed10`: aggression, arena_contain, audio, catch_aim_slowdown, catching, encounter_scaling.
- `cdf1a939`: catch_retry, controller_catching, smoke_net_catch_race.
- `c3870eb9`: smoke_net_catch_race compares only the newly granted card.
- `4bcd1edb`: aggression fresh-world starter.
- `31eac8ff`: test_move_commit_runtime, test_f23_live_moves, test_process_exit_settlement, test_combat_mastery_delivery bind the actor as the director does.

## Results with the flag on

- **55 CI SMOKE jobs:** all pass, after the fixture fixes above.
  - veridian_offer_choice ran group by group as CI does: space, capacity and recovery.
  - An earlier capacity failure came from my own parallel runs sharing save slot 3. Run alone, it passes.
- **Catch and capture set:** catching, catch_aim_slowdown, party_count_after_catches, catch_respawn_fresh_individual, water_capture_recovery, f48_capture_evidence and smoke_net_catch_race (61/61) all pass.
- **Full unit suite:** 6112 tests, 0 failed, before the merge of main.
  - After the merge and B1: the affected files pass (51 tests, 0 failed), and smoke_combat, trainer_battle, encounter_scaling, party_count, f27_wild_defeat_essence, release and net client_trainer_rewards pass.
- **smoke_net_shared_boss:** run alone, ALL CHECKS PASSED. One earlier run in a batch exceeded the smoke time budget; that was a timeout, not an assertion failure.

## Main debt (not the flip)

`smoke_catch_retry` ("could not re-arm the aim within 3 presses") and `smoke_controller_catching` ("attacks did not naturally weaken the target") also fail with the flag OFF on their original versions. Neither is in CI.
