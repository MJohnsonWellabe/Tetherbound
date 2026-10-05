# F18 closeout receipt: portal runtime on (tb/f18)

Shipped config has `session.redesign_portal_runtime_enabled = true` (flip commit b2dfc11e). Every proof below ran with it on. Saves stay v28. Head: ea685537.

## Criteria

| # | Status | Proof (flag on) |
|---|---|---|
| 0 Opening Home Key, protected | PASS | Units: `test_opening_home_key` (legacy reconcile, gift-request evidence, no evidence on a rejected request), `test_opening_gift_waits_for_owner` (orbs wait for the owner record, bounded exit, a changed character or world drops the held batch), `test_portal_request_expiry` (reconcile arm lifecycle), `test_home_key_protection`. Smokes: `smoke_opening` (`opening.log.gz`, 50 orbs + Home Key), `smoke_f18_legacy_home_key` (save, reset, load in Tidewake: exactly one key and one row; negative control logged), gate A opening segment (`gatea2.log.gz`). |
| 1 One-tap use, refusals | PASS | Units: `test_home_key_action`, `test_home_key_channels`, `test_home_key_clock`. Smoke: `smoke_f18_home_key_refusal_input` (28 checks, 0 failures). |
| 2 Portal keys; retired crossings | PASS | Units: `test_portal_admission_mode`, `test_crossing_hall_portal_mount`, `test_meadows_tidewake_handoff`. The five transition smokes pass under the disclosed legacy toggle (`sw4`, `wr3`, `tr*` logs). |
| 3 Waystones + home arch | PASS | Decision #11 settled by the owner 2026-10-05 (STATE §0; PR #538): `portals.json home_arch.returns_to_last_meadows_waystone = true`. Units: `test_home_arch_meadows_return` (last touched stone; no stone lands at the entry; a stale saved stone lands at the entry; a forged biome return point is still refused), `test_f18_waystones`, `test_waystone_refusal_releases` (a refused touch releases the stone for its retry; fails on the previous stone). Smoke: `smoke_f18_waystone_mounts`. |
| 4 Co-op | PASS (multiplayer-wide 37320227493 @ea685537, green) | `smoke_net_f18_travel`, 3 peers: own Home Key moves only that player; guest touch durable on the host journal; a guest unlock follows the character to a second host whose world stays locked; fresh-process rejoin; home arch return. Root cause of the earlier intermittent guest stalls: a guest's Game drops its travel baseline while an arrival holds its owner record, and only fly landings minted the host reset proof, so the guest's owner-passive stream refused every later owner-gated action (`travel_baseline_mismatch`). Fix 79de8d82 + 4683b4d5 + ea685537: the host mints an arrival proof when the arrival is durable, bound by the live host body. Tests: `test_owner_passive_sync`, `test_portal_arrival_travel_reset`. Guest homecoming ack (`smoke_net_f20_ending`): guest window `guest_ack_timeout_seconds` (24 s, tunable) and an expired ack keeps re-sending while still owed, settling once (`test_regional_ack_guest_view`). |
| 5 Earned loop | BLOCKED (F31) | `smoke_f18_earned_loop` clears the opening, protected drop/sell/satchel, village tools, materials, Workbench build, combat/cutscene and locked-arch refusals. The paid Workbench craft stall is a game bug routed to F31: on the host nothing emits `homestead_action_completed` for station actions. The batch merging lane A's 0d04beca runs `smoke_net_homestead_station_craft` with portals on. |

## Independent reviews
- Review 1 of the delta since 4503b8c1: REQUEST CHANGES. Fixed in dd380a7b: guest walk_out never reached the host; held batch released to a newly loaded character; host arm erased early; stale Meadows stone refused the home arch.
- Re-review of dd380a7b: APPROVE WITH NITS. Fixed in 71d0c0a5.
- Guest ack expiry recovery (9fdf2332): REQUEST CHANGES (view requests at 2 Hz while away). Fixed in 6ee60120.
- Arrival travel reset (79de8d82, 4683b4d5): APPROVE WITH NITS. Fixed in ea685537 (mint when durable; live-body bound).

## Other fixes this round
- `sequence_director.gd`: the Home Key gift batch is held until the owner record releases (orbs were lost); bounded 20 s exit.
- `game_state.gd`: guest homecoming ack waits for a fresh personal view, re-sends on a slow cadence, logs refusals once.
- `.github/workflows/ci.yml`: eleven net shards. Ten overflowed the 1200 s budget once the flip added three smokes to the gate.
- `smoke_veridian_offer_choice.gd`: the disclosed capacity fixture holds `home_key_given` (a reload inferred the opening and the reconcile journalled against a roster the next case replaces).
- Hot files touched: `session.gd`, `ledger_rpc.gd`, `ci.yml`.

## CI
- Multiplayer-wide (3 peers) 37320227493 @ea685537: green.
- Full CI 37320223520 @ea685537: see the final report (filled when it completes).
- Known-red jobs (`gate-b-full-known-red`, `continuous-core-known-red`) fail by design and are excluded.
