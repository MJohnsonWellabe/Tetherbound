# F18 closeout receipt: portal runtime on (tb/f18)

Shipped config has `session.redesign_portal_runtime_enabled = true` (flip commit b2dfc11e). Every proof below ran with it on. Saves stay v28.

## Criteria

| # | Status | Proof (flag on) |
|---|---|---|
| 0 Opening Home Key, protected | PASS | Units: `test_opening_home_key`, `test_home_key_protection`, `test_regional_ack_guest_view`. Smokes: `smoke_opening` (`opening.log.gz`, 50 orbs + Home Key), gate A opening segment (`gatea2.log.gz`; the drive now counts when control returns). Protected drop/sell/satchel receipts are in the earned-loop run. |
| 1 One-tap use, refusals | PASS | Units: `test_home_key_action`, `test_home_key_channels`, `test_home_key_clock`. Smoke: `smoke_f18_home_key_refusal_input` (`smoke_f18_home_key_refusal_input.log.gz`, 28 checks, 0 failures). |
| 2 Portal keys; retired crossings | PASS | Units: `test_portal_admission_mode`, `test_crossing_hall_portal_mount`, `test_meadows_tidewake_handoff`. `realm_transition` requires a portal permit unless the legacy toggle is set. All five transition smokes pass only under the disclosed legacy toggle: cloudreach, rift, meadows handoff, stormwood (`sw4.log.gz`), water (`wr3.log.gz`, xvfb). |
| 3 Waystones | PASS for Tidewake, Cloudreach and Stormwood. Meadows home arch BLOCKED_OWNER (decision #11). | Unit: `test_f18_waystones`. Smoke: `smoke_f18_waystone_mounts` (`smoke_f18_waystone_mounts.log.gz`). Switch: `data/config/portals.json home_arch.returns_to_last_meadows_waystone` (false ships; true is the recommendation). |
| 4 Co-op | Local PASS; CI BLOCKED (guest owner hold on CI) | `smoke_net_f18_travel`, 3 peers. Local PASS twice: 45371171 and f390f061, 77 PASS / 0 FAIL, clean peer logs (`net-travel-45371171/`). It covers: own Home Key moves only that player; guest touch durable on the host journal; a guest unlock follows the character to a second host whose world stays locked; fresh-process rejoin; home-only home arch. CI multiplayer-wide fails at a different guest owner-gated step each run: 37259196490 @e7ae1b53 guest Home Key; 37262272256 @45371171 guest touch, no durable reply in 16 s; 37265213849 @f390f061 guest Home Key after rejoin, no verdict. The same family shows in CI `smoke_net_f20_ending`: the guest's owner training row stays `portal_arrival`, so its `regional_ack` never commits. |
| 5 Earned loop | BLOCKED (proof harness) | `smoke_f18_earned_loop` (logs `smoke_f18_earned_loop-earned3/4/5.log.gz`). Now clears: opening, protected drop/sell/satchel, village tools, materials, Workbench build, combat/cutscene refusals and locked-arch refusal. Remaining: (a) the paid Workbench craft stayed `awaiting_saved_decision` for 600 frames in 2 runs, while CI `f31_station_paid_path` is green; (b) one run's capsule walk to the CraftInteractable failed. Three attempts with a different failure each; stopped under the two-attempt rule. |

## Fixes in this closeout (all flag-on regressions)
- `waystone.gd`: `bool(null)` crash on worlds with no `simulation_only` property.
- `sequence_director.gd`:
  - the spoken Home Key gift retries every 250 ms on the host, backing off 250 ms / 1 s / 3 s on a guest;
  - the batch is held until the key's owner CAS releases the owner record. Before this, the satchel refused the 50 orbs and they were lost;
  - the shell guard (5fe6b2ec) also lands here.
- `game_state.gd`: a guest's homecoming acknowledgement waits for the host's fresh personal view. Pending acks are keyed by transaction and expire with the caller's timeout.
- `realm_shells.gd`: threaded load no longer leaks load tokens (the earlier ObjectDB leak).
- Test equipment repaired:
  - gate opening drive;
  - earned-loop farmyard lead-in;
  - stormwood transition fixture (F06 fact, crossing release);
  - `f18_net_peer` await.

## Unit batch
`u18.log.gz`: 114 tests, 0 failed, after the tb/integration merge. `u19`: regional ack and homecoming suites, 35 tests, 0 failed.

## CI (full, tier full) at 45371171: run 37261541423, attempts 1 and 2
- Green: units 1-3, gate A UI/build (`opening`, `f31_station_paid_path`), gate B core, gate evidence shard and finale, Veridian ×3, regions, combat, catching, harvest, export, multiplayer shards 1, 3, 4, 6-10.
- Known-red, excluded by design:
  - `gate-b-full-known-red`: save refused at three-bed readiness;
  - `continuous-core-known-red`: pickaxe swing on attempt 1, PASS on attempt 2.
- Shard 2: `boss_rewards_each_participant` (pending_vitals) failed on attempt 1 and passed on attempt 2. `cloudreach_riding` passed on attempt 1 and failed on attempt 2.
- Shard 5: `smoke_net_f20_ending` guest `f20_talk`, as above.
