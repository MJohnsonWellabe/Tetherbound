# F18 closeout receipt: portal runtime on (tb/f18)

Shipped config has `session.redesign_portal_runtime_enabled = true` (flip commit b2dfc11e). Every proof below ran with it on. Saves stay v28. Head: 2927506a (main e2fa5e4e merged).

## Criteria

| # | Status | Proof (flag on) |
|---|---|---|
| 0 Opening Home Key, protected | PASS | Units: `test_opening_home_key` (legacy reconcile, gift-request evidence, no evidence on a rejected request), `test_opening_gift_waits_for_owner` (orbs wait for the owner record, bounded exit, a changed character or world drops the held batch), `test_portal_request_expiry` (reconcile arm lifecycle), `test_home_key_protection`. Smokes: `smoke_opening` (`opening.log.gz`, 50 orbs + Home Key), `smoke_f18_legacy_home_key` (save, reset, load in Tidewake: exactly one key and one row; negative control logged), gate A opening segment (`gatea2.log.gz`). |
| 1 One-tap use, refusals | PASS | Units: `test_home_key_action`, `test_home_key_channels`, `test_home_key_clock`. Smoke: `smoke_f18_home_key_refusal_input` (28 checks, 0 failures). |
| 2 Portal keys; retired crossings | PASS | Units: `test_portal_admission_mode`, `test_crossing_hall_portal_mount`, `test_meadows_tidewake_handoff`. The five transition smokes pass under the disclosed legacy toggle (`sw4`, `wr3`, `tr*` logs). |
| 3 Waystones + home arch | PASS | Decision #11 settled by the owner 2026-10-05 (STATE §0; PR #538): `portals.json home_arch.returns_to_last_meadows_waystone = true`. Units: `test_home_arch_meadows_return` (last touched stone; no stone lands at the entry; a stale saved stone lands at the entry; a forged biome return point is still refused), `test_f18_waystones`, `test_waystone_refusal_releases` (a refused touch releases the stone for its retry; fails on the previous stone). Smoke: `smoke_f18_waystone_mounts`. |
| 4 Co-op | PASS (multiplayer-wide 37320227493 @ea685537; smoke_net_f20_ending render 37361153872 @2927506a, green) | `smoke_net_f18_travel`, 3 peers: own Home Key moves only that player; guest touch durable on the host journal; a guest unlock follows the character to a second host whose world stays locked; fresh-process rejoin; home arch return. Guest owner-passive stalls: a guest arrival now mints the host travel-reset proof when durable, bound by the live host body (79de8d82, 4683b4d5, ea685537; `test_owner_passive_sync`, `test_portal_arrival_travel_reset`). Guest homecoming (`smoke_net_f20_ending`, 2 peers incl. drop, wipe and rejoin): sample freshness judged at the request's arrival (c2e41d4a); the portable party decodes without its in-fight energy (9032d90e, `test_water_capture_codec`); the host's admitted record mirrors a guest's settled portal spend so later owner actions do not conflict (6de35900, `test_portal_settled_marker_authority`); no sends on a disconnecting host link (05b08aeb, 7cbf31ad); another player's trainer no longer hides an NPC prompt (2927506a, `test_interactable_coop_sight`). |
| 5 Earned loop | BLOCKED (F31) | `smoke_f18_earned_loop` clears the opening, protected drop/sell/satchel, village tools, materials, Workbench build, combat/cutscene and locked-arch refusals. The paid Workbench craft stall is a game bug routed to F31: on the host nothing emits `homestead_action_completed` for station actions. The batch merging lane A's 0d04beca runs `smoke_net_homestead_station_craft` with portals on. |

## Independent reviews
- Review 1 of the delta since 4503b8c1: REQUEST CHANGES. Fixed in dd380a7b: guest walk_out never reached the host; held batch released to a newly loaded character; host arm erased early; stale Meadows stone refused the home arch.
- Re-review of dd380a7b: APPROVE WITH NITS. Fixed in 71d0c0a5.
- Guest ack expiry recovery (9fdf2332): REQUEST CHANGES (view requests at 2 Hz while away). Fixed in 6ee60120.
- Arrival travel reset (79de8d82, 4683b4d5): APPROVE WITH NITS. Fixed in ea685537 (mint when durable; live-body bound).
- Freshness, codec, settled portal marker (c2e41d4a, 9032d90e, 6de35900): APPROVE WITH NITS / APPROVE / APPROVE WITH NITS. Nits fixed in a5a0e09c.
- Disconnect guards, prompt sight, CI shards, diagnostics (05b08aeb, 7cbf31ad, 2927506a, 9756e15e, 164f4143, 01ce9949, 5a2ce54e): APPROVE WITH NITS / APPROVE / APPROVE WITH NITS / APPROVE. The unmeasured-smoke default no longer takes an isolated lower bound (fixed with this receipt); the misleading deny codes in the disconnect window stay as-is (fail closed).

## Other fixes this round
- `sequence_director.gd`: the Home Key gift batch is held until the owner record releases (orbs were lost); bounded 20 s exit.
- `game_state.gd`: guest homecoming ack waits for a fresh personal view, re-sends on a slow cadence, logs refusals once.
- `tools/ci/net_shards.py` + `.github/workflows/ci.yml`: measured durations for the three smokes the flip adds to the gate (from 37320223520); f20_ending runs alone; 21 shards.
- `smoke_veridian_offer_choice.gd`: the disclosed capacity fixture holds `home_key_given` (a reload inferred the opening and the reconcile journalled against a roster the next case replaces).
- Hot files touched: `session.gd`, `ledger_rpc.gd`, `ci.yml`. Shared: `water_capture_codec.gd`, `owner_passive_sync.gd`, `character_authority.gd`, `interactable.gd`.

## CI
- Multiplayer-wide (3 peers) 37320227493 @ea685537: green.
- Full CI 37357846004 @9756e15e: all jobs green except shard 20 (`smoke_net_f20_ending`, fixed after that head in 2927506a: render 37361153872 green) and shard 6 (`smoke_net_homestead_station_craft`: Lane A's smoke gives its guest no party before the Home Key trip; routed).
- Unit batch on the main merge fbdcd1aa: 6237 tests; the 2 local failures were un-imported WAVs (pass after import).
- Known-red jobs (`gate-b-full-known-red`, `continuous-core-known-red`) fail by design and are excluded.
