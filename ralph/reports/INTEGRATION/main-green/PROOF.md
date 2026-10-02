# Main integration repairs

Baseline: `f48a0ba1ea54bf39149e37695804fdc976a1f9e7` (PR519).

## Authored catalogue reuse

`Teaching.allowed_saved_moves` reparsed all species and rebuilt the Water adapters for each creature during every admitted-character validation. It now reads the existing `CreatureSpecies.table()` through a lazy load, retaining the established preload-cycle boundary. Character level, breakthrough history, ancestry, compatible TMs and allowed moves are still evaluated on each call. No character state, receipt, admission result or validation failure is cached.

Native Godot 4.7 measurement, five owned creatures, ten calls per operation, same machine and fixture (`tools/probe_admitted_character_cost.gd`):

| Operation | Baseline mean ms | Candidate mean ms |
|---|---:|---:|
| Validate portable character | 74.011 | 16.574 |
| Refresh host-local character | 75.726 | 17.520 |
| Recover durable vitals | 75.157 | 17.076 |
| Recover durable portals | 79.520 | 17.567 |

This is a scoped CPU measurement, not a frame-time or multiplayer acceptance claim. Empty journals isolate the repeated admission cost; populated journal/world performance remains to be checked by the selected CI jobs.

Affected regression command:

```text
Godot_v4.7-stable_win64_console.exe --headless --path . --script tests/run_tests.gd -- --only=test_breakthrough_saved_move_history.gd,test_actor_vitals_authority.gd,test_combat_mastery_delivery.gd,test_guest_groom_passive_sync.gd
```

Result: 24 tests, 2,810 assertions, zero failures. Covers every authored tier's JSON-restored eligibility, malformed prefixes, authority identity/refused writes/replay, mastery persistence, and guest grooming save/ACK ordering. No gate or assertion was removed or relaxed. Independent static review approved the bounded change with no actionable findings: no preload cycle, shared-catalogue writes or cached personal state; equivalent authored catalogue and Water merge behavior. The reviewer did not rerun tests. Exact-head full CI remains required before landing.

Balance: game 1 / tests-tools 1 (one performance probe).
