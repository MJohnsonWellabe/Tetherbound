# Production adapter third attempt — timeout, no acceptance credit

2026-09-09. Artifacts: `.artifacts/realm-transition-adapter-20260909-v3/`; exact source SHA256 values and all six raw role logs are retained there. This is a failed candidate, not a clean multiplayer result.

The runner stopped on `ADAPTER FAIL host native adapter deadline` after 23.340387 seconds including startup. The host's internal deadline was 20 seconds. Host/departing/staying console launchers were PID 4628/7100/15836 and recorded forced exit -1. All roles completed the 18 preflight checks; departing and staying received six live replicated bodies, and departing consumed its earlier scene reply. No assertion established completion of either fence round, actual drain, destination readiness, or retained-player behavior after crossing. All six raw logs contain zero native `ERROR` or `SCRIPT ERROR` entries. Absence of those errors does not negate the timeout failure.

System memory peaked at 79.115445% used, with minimum free memory 1633.421875 MB. The receipt's approximately 7.25 MB per-process peaks describe console launchers, **not the Godot engine children**; actual engine peaks were not captured and cannot be inferred. A post-run process check found zero Godot processes. The runner has since been changed to identify engine children by parent PID plus fixture command, role and port, report their peaks separately, and stop its owned process trees. That corrected accounting has not yet been exercised by another candidate.

## Static review and diagnostics after failure

No fourth network candidate was launched. The coordinator now exposes a read-only diagnostic snapshot: pending requests; local phase; installation quorum; current round; every missing sender/receiver/channel fence; and actual received count versus current body count for each spawner. The fixture prints changes while moving and a final snapshot on failure. These additions do not change protocol gates.

A separately authorized pre-network check passed all 18 checks in 3.236 seconds, exit 0, without raw errors. It opened no ENet peer. The actual mounted coordinator reported `process_enabled=true` and `can_process=true`, ruling out the specific initial-condition hypothesis that disabling Session's process callback also disables its child coordinator. This does not establish its later runtime state.

Static inspection finds no confirmed blocking dependency yet. The fixture producer always reports settled, so it cannot intentionally withhold installation for combat completion. Grant depends on the coordinator processing its pending queue; each round then requires all three installation acknowledgments and 12 directed channel receipts; drain requires the host marker and both receipt and body inventories becoming empty. The previous logs cannot distinguish those gates. The actual-despawn callback can fire before body deletion, but `_process` polls the empty-body condition afterward, so that ordering alone is not a demonstrated deadlock.

Game integration remains untouched. Native transport acceptance, actual join/snapshot ordering, rollback/disconnect, host travel, real Water traversal and CI remain unproven. Further execution is held for root review; this report does not justify another near-identical run or broader architecture changes.
