# Phase1 exact integration manifest

2026-09-09. Uncommitted gameplay lane files, checked against git status after the default Water pass. No branch switch, commit or push. Source behavior remains frozen since that pass. This manifest includes the first-attempt failures and latest receipts; artifact logs remain under .artifacts and are not shipping source.

Acceptance: native component 81 checks, actual Game control flow 73 checks, unchanged default Water Alpha 28 checks. Shipping remains blocked on the begin-client failure-path audit and remaining integration/CI gates. See REALM-TRANSITION-BEGIN-FAILURE-AUDIT.md.

## Source, tests and runners

| Git state | Exact path |
|---|---|
| M | `autoload/game_state.gd` |
| M | `scripts/combat/encounter_director.gd` |
| M | `scripts/net/realm_shells.gd` |
| M | `scripts/net/remote_trainer.gd` |
| M | `scripts/net/session.gd` |
| M | `scripts/net/trainer_spawn.gd` |
| ?? | `scripts/net/realm_receiver_history.gd` |
| ?? | `scripts/net/realm_replication_scope.gd` |
| ?? | `scripts/net/realm_spawn_origins.gd` |
| ?? | `scripts/net/realm_transition.gd` |
| ?? | `scripts/net/trainer_reward_delivery.gd` |
| ?? | `tests/test_director_join_snapshot.gd` |
| ?? | `tests/test_realm_crossing_context.gd` |
| ?? | `tests/test_realm_receiver_history.gd` |
| ?? | `tests/test_realm_replication_scope.gd` |
| ?? | `tests/test_realm_spawn_origins.gd` |
| ?? | `tests/test_realm_transition.gd` |
| ?? | `tests/test_session_physical_timeout.gd` |
| ?? | `tests/test_trainer_reward_delivery.gd` |
| ?? | `tests/fixtures/realm_transition_empty.gd` |
| ?? | `tests/fixtures/realm_transition_source.tscn` |
| ?? | `tests/fixtures/realm_transition_target.tscn` |
| ?? | `tools/probe_realm_transition_adapter.gd` |
| ?? | `tools/probe_realm_transition_adapter_peer.gd` |
| ?? | `tools/probe_realm_transition_game.gd` |
| ?? | `tools/run_phase1_water_alpha.ps1` |
| ?? | `tools/run_realm_transition_adapter.ps1` |

## New gameplay reports

- `ralph/reports/FOUR-BIOME-BUILD/REALM-TRANSITION-ADAPTER-FIRST-ATTEMPT.md`
- `ralph/reports/FOUR-BIOME-BUILD/REALM-TRANSITION-ADAPTER-FOURTH-ATTEMPT.md`
- `ralph/reports/FOUR-BIOME-BUILD/REALM-TRANSITION-ADAPTER-OBSERVATION.md`
- `ralph/reports/FOUR-BIOME-BUILD/REALM-TRANSITION-ADAPTER-PREFLIGHT.md`
- `ralph/reports/FOUR-BIOME-BUILD/REALM-TRANSITION-ADAPTER-SECOND-ATTEMPT.md`
- `ralph/reports/FOUR-BIOME-BUILD/REALM-TRANSITION-ADAPTER-THIRD-ATTEMPT.md`
- `ralph/reports/FOUR-BIOME-BUILD/REALM-TRANSITION-BEGIN-FAILURE-AUDIT.md`
- `ralph/reports/FOUR-BIOME-BUILD/REALM-TRANSITION-GAME-FIRST-ATTEMPT.md`
- `ralph/reports/FOUR-BIOME-BUILD/REALM-TRANSITION-GAME-INTEGRATION-BRIEF.md`
- `ralph/reports/FOUR-BIOME-BUILD/REALM-TRANSITION-GAME-SECOND-ATTEMPT.md`
- `ralph/reports/FOUR-BIOME-BUILD/REALM-TRANSITION-PHASE1-IMPLEMENTATION-STATUS.md`
- `ralph/reports/FOUR-BIOME-BUILD/REALM-TRANSITION-PHASE1-IMPLEMENTATION.md`
- `ralph/reports/FOUR-BIOME-BUILD/REALM-TRANSITION-WATER-ALPHA-PRODUCTION.md`
- `ralph/reports/FOUR-BIOME-BUILD/REALM-TRANSITION-INTEGRATION-MANIFEST.md` (this file)

Existing readiness tests and default Water smoke/harness were executed without edits. Earlier CI/despawn/toy-protocol receipts already committed by root are not listed as new work. Visual image-only review reports are separate from this gameplay shipping manifest. No .import, UID, visual asset or scene-material changes belong to this lane.
