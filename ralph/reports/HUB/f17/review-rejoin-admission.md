# Independent review: rejoin admission and owner-passive cost (c8ebaa3c)

**Verdict on c8ebaa3c:** BLOCK. The reviewer was an independent agent; it did not edit anything. The fixes below are in the commit that follows.

| # | Severity | Finding | Fix |
|---|---|---|---|
| H1 | High | The hello path changed the held record before the hello could still be refused (by seed flags, recover vitals or recover training) | `session.gd` snapshots the held record before `rejoin_admission` and restores it on any later refusal (`snapshot_record` / `restore_record`). Unit-tested |
| H2 | High | Readmit could adopt an OLDER declaration (a restored backup) and re-earn what this world already paid | New `declaration_behind`. Every held transaction receipt must be in the declaration, unless its kind's window (`receipt_windows.json`, or the F32 window) shows the declaration compacted it. Every host-recorded personal flag must be among the declared flags. Otherwise the code is `declaration_behind_held`: the held record stays and the old loud refusal applies. Unit-tested (a missing receipt, a missing flag, a compacted window) |
| M1 | Medium | `owes_unsettled` missed a pending portal mutation | Added `_portal_mutation_pending` |
| M2 | Medium | The rebuild could match the Home Key grant row, which is a host CAS, not owner-applied | `owner_applied_row` excludes `home_key:grant:` sources. Unit-tested |
| L1 | Low | The committed evidence came from a debug build | Replaced with a fresh run of the fixed code |
| L2 | Low | The smoke could not tell the rebuild path from readmit | `op_state` exposes the host's `last_rejoin_admission`. The smoke asserts `replayed_deliveries` (deliver-then-leave) and `readmitted_portable` (offline change) |
| L3 | Low | A duplicate delivery id could be re-credited | `apply_owner_reward_delivery` refuses an id that is already absorbed. Unit-tested |
| B-nit | Low | The working copy could become the cursor without validation on a mid-batch exit | `_inputs_host` became a wrapper plus `_inputs_host_batch`. Condition ticks advance a private copy, and `_settle_working` validates it before it becomes the cursor: before any other input and on every exit |

## Checks

- `test_rejoin_admission`: 6 tests, 35 assertions.
- `test_owner_passive_sync`: 33 / 550.
- `test_owner_passive_replay`: 10 / 377.
- Admission, authority and delivery suites (listed in the commit): all pass.
- `smoke_net_owner_passive_rejoin`: ALL CHECKS PASSED (`rejoin-admission/owner-passive-rejoin-2peer.txt`).
- Regression net smokes: `gather_departure` and `homestead_station_craft`, both ALL CHECKS PASSED.

**Still open:** a re-review of these fixes.
