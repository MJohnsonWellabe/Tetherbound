# Corrected adapter component proof — pass with explicit limits

2026-09-09. First candidate after the observation diagnosed the zero-peer visibility shortcut. Retained artifacts: `.artifacts/realm-transition-adapter-20260909-v4/`, including exact source SHA256 values and all six raw logs. Earlier v1/v2/v3 failures and the observation remain preserved.

The focused correction passed 12 tests/52 assertions and an 18-check pre-network preflight before this run; logs are in `.artifacts/realm-transition-visibility-correction-tests/`. The correction aggregates scoped zero-peer visibility across actual connected recipients and refreshes each actual peer explicitly during phase changes. Native automatic idle visibility cadence and baseline filters remain intact.

The three-peer candidate completed in 7.521079 seconds. Host/departing/staying each returned launcher exit 0, with 29/29/23 checks respectively: 54 preflight checks plus 27 protocol checks. All six raw logs contain zero engine errors, script errors, warnings or fixture failures. A terminal CIM check found zero Godot processes.

Observed acceptance within this component fixture:

- Both request/response fence rounds completed and the prior real scene-bound reply was consumed before old receiver removal.
- Departing trainer and creature spawn parents became empty, and all three actual spawner receipt inventories became zero before the source subtree was deleted.
- Destination held zero bodies before explicit readiness, then admitted the actual trainer and creature.
- Staying peer had no destination or dummy path, retained exactly host/own trainer and creature, and kept receiving host movement. Host kept receiving staying movement and reliable presentation; only the mover left the tiny participant list.
- Actual `visibility_changed` signals recorded automatic zero-peer updates and explicit phase updates for both actual client IDs, on host State and Admission synchronizers. The public aggregate remained denied after departure while the staying recipient remained allowed.

Engine children: host PID 11940 peak 143.890625 MB, departing PID 2648 peak 143.136719 MB, staying PID 18780 peak 143.75 MB. Launchers 20800/12396/20184 each exited 0; engine child exit codes are unavailable in the process handles after terminal exit. System peak 77.739076% used, minimum free 1741.070313 MB. All samples stayed within the 90%/400 MB guard.

This is an actual ENet proof of the production Session/coordinator/adapter using tiny authored worlds and a simplified producer. It is pre-snapshotted. It does not prove native initial join or scoped late join, actual encounter completion, rollback/disconnect, host travel, saves, Game entry, or full Water traversal. `Game.enter_realm` is still unconnected and CI has not been run for this draft. Those limits remain open before shipping the Phase1 repair.
