# Same-live Aquaryn retirement

2026-09-08. The possible Tidal spine-center obstruction recorded in `WATER-EARNED-LATE-WAVE3.md` is now a reproduced production lifecycle defect with a narrow repair. This report supersedes that source-only collision uncertainty; it does not prove the mounted Tidal route or full Water campaign.

## Cause

`WaterAlpha` owns its body independently of the ordinary EncounterDirector. Its `_begin_local` binds the actual manager but never populates inherited `_engaged_with`. The ordinary director's `_on_combat_exited` only calls `notify_fainted` and schedules body clearance when that variable identifies a wild body. Alpha's own `_on_alpha_exit` merely cleared `_local_fight`.

The Alpha authority synchronizes damage and publishes the saved result through `_settle_resolution`. Snapshot presentation resolves local managers and the manager emits its exit signal. None of those paths retired Alpha's collision in the same live world. Only rebuilding an already-completed realm set visibility false, collision layer zero and physics processing false. Thus a saved victory and a disabled challenge prompt left a physical body behind until reload.

## Reproduction and repair

New `tests/smoke_water_alpha_retirement.gd` constructs the actual packed Aquaryn body with its actual Alpha body script, actual Alpha node/process callback and actual manager exit signal. It uses the production reward ledger and real scratch SaveGame writer. The explicit diagnostic defeat and emitted manager exit are a lifecycle fixture, not a player-earned combat victory. No full Water scene or Terrain3D load is used.

Before repair, `.artifacts/water-alpha-retirement-original.log` and `-engine.log` show **7 checks, 3 failures**, exit 1, no engine errors. Unresolved collision, unresolved exit, durable journal and preserving the result beat all passed. The same-live retirement, native collision-ray clearance and stopped body physics all failed.

`scripts/combat/water_alpha.gd` now shares the existing reload retirement state in `_retire_completed_body()`, called from build and process. It does nothing until the durable completion flag exists, and preserves a local participant's body while `_local_fight` remains true. After the result beat exits, it hides that owned body, sets collision layer to zero and stops creature physics. Nonparticipants receiving completion take the same retired state without requiring a local combat exit. There is no damage, AI, terrain, waypoint, body-size or timing-ceiling change.

The changed native run added an actual nonparticipant Alpha/body control and passed **9 checks, 0 failures**, exit 0, no ERROR/SCRIPT ERROR/WARNING entries. Logs: `.artifacts/water-alpha-retirement-fixed.log` and `.artifacts/water-alpha-retirement-fixed-engine.log`. These include actual physics rays hitting unresolved bodies and missing retired bodies, unresolved-exit preservation, durable-outcome result-beat preservation, participant retirement and nonparticipant retirement.

Focused existing Alpha authority/reward suites pass **15 tests, 186 assertions, 0 failed**, exit 0 with no engine errors or warnings; see `.artifacts/water-alpha-retirement-focused.log` and `-engine.log` for exact counts. Each native/focused invocation used its own APPDATA under `%TEMP%/tetherbound-alpha-retirement-{original,fixed,focused}` and a unique engine log. No owner save, full-world fixture, import, unchanged rerun, commit or push was used.

The old late helper remains frozen. Removing this production obstruction is not proof of the rest of the authored approach's footing, mounted stamina or actual earned team combat strength.
