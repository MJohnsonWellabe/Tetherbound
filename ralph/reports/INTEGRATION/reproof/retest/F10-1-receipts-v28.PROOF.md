# Two-peer proof: F10 six Stormwood side chains: receipts on both peers through a save/reload, never twice

**Verdict: FAIL** (exit 1)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/stormwood_f10_side_chain_receipts.json`  
Run: `net-20261004T222552Z-11292`  
Rendered: no (headless)

ACCEPTANCE F10: all six Stormwood side chains satisfy section 5 with persistent receipts. Two real processes. Each chain's final step (and every earlier step that has one) is played through its production path by ordinary Interact presses: Dark Arches (host: Relight prompts on the four dark arches, the arch runtime's step 2, Hesk's report), Pim's Parcels (guest, client path: Pim, three deliveries, Pim's return; host: Pim's thanks; each character paid 2 Small Potions once through reward_grant), What the Crown Remembers (host: three record prompts, Wen), Glass for Bryn (guest: Bryn's offer and request, the host-owned delivery transaction taking the guest's materials, the inspect prompt), Raise a Road (host: two footing prompts, two Stormglass Arches built through build_place, travel through the new road both ways, Ondra's report), Deepwood Circuit (host: Rook's offer, the chapter runtime crediting three circuit wins, Rook's return). Each completion flag reaches both peers; both save_reload_here; every completion and each character's rate hold on both and in the saved world/character files; a second visit to each completing NPC or prompt offers and grants nothing again. Disclosed fixtures: the host's named save; debug travel (explore_at) to each NPC or prompt instead of walking; main-route facts set as world flags where the side chain has no step of its own (ashfoot_arch_relit, rootgate_released, lantern_pools_linked, crown_reached, crown guardian cleared, engine_truth_learned, bryn_met, arch_recipe_known, lantern_hollow_reached); Stormglass and Conductor Vine granted in place of gathering; the road arches built with Free Build (materials not charged); and three circuit trainers' defeat facts set in place of three hosted fights (the chapter runtime itself turns them into circuit wins).

## Failures

- #178 peer 0 await_probe ('stormwood_rook_circuit_return' closed) -> FAIL -- relay_crossing.dialogue_open was true, not false, after 240 polls

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"form":"captured directory (split path)","realm":"meadows"} | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: a fresh trainer in the Meadows | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | host | PASS | PASS | hosting udp/33961 as peer 1 |
| 4 | 1 | join | PASS | PASS | joined 127.0.0.1:33961 as peer 728481120 after 31 frames; snapshot applied; 2 peer(s) in registry |
| 5 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 5 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 6 | 0 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 6 | 1 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 7 | 0 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 500 observed physics frames / 74150 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 8 | 1 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 556 observed physics frames / 43310 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 9 | 0 | story_flag — FIXTURE (main-route fact, no side-chain step): stormwood:ashfoot_arch_relit — reveals Dark Arches | PASS | PASS | stormwood:ashfoot_arch_relit: ok=true pending=false code='' reason='' |
| 10 | 0 | story_flag — FIXTURE (main-route fact, no side-chain step): stormwood:rootgate_released — pairs C and D stand beyond it (Act II) | PASS | PASS | stormwood:rootgate_released: ok=true pending=false code='' reason='' |
| 11 | 0 | story_flag — FIXTURE (main-route fact, no side-chain step): stormwood:lantern_pools_linked — reveals Pim's Parcels | PASS | PASS | stormwood:lantern_pools_linked: ok=true pending=false code='' reason='' |
| 12 | 0 | story_flag — FIXTURE (main-route fact, no side-chain step): stormwood:crown_reached — reveals What the Crown Remembers | PASS | PASS | stormwood:crown_reached: ok=true pending=false code='' reason='' |
| 13 | 0 | story_flag — FIXTURE (main-route fact, no side-chain step): stormwood:named:crown_guardian:cleared — Wen speaks only after the Crown guardian | PASS | PASS | stormwood:named:crown_guardian:cleared: ok=true pending=false code='' reason='' |
| 14 | 0 | story_flag — FIXTURE (main-route fact, no side-chain step): stormwood:engine_truth_learned — Wen tells the main truth before the records report | PASS | PASS | stormwood:engine_truth_learned: ok=true pending=false code='' reason='' |
| 15 | 0 | story_flag — FIXTURE (main-route fact, no side-chain step): stormwood:bryn_met — reveals Glass for Bryn | PASS | PASS | stormwood:bryn_met: ok=true pending=false code='' reason='' |
| 16 | 0 | story_flag — FIXTURE (main-route fact, no side-chain step): stormwood:arch_recipe_known — reveals Raise a Road (Ondra's recipe) | PASS | PASS | stormwood:arch_recipe_known: ok=true pending=false code='' reason='' |
| 17 | 0 | wait_flag — fixture fact reached both peers: stormwood:ashfoot_arch_relit | PASS | PASS | flag stormwood:ashfoot_arch_relit (any) set after 0 frames |
| 17 | 1 | wait_flag — fixture fact reached both peers: stormwood:ashfoot_arch_relit | PASS | PASS | flag stormwood:ashfoot_arch_relit (any) set after 550 frames |
| 18 | 0 | wait_flag — fixture fact reached both peers: stormwood:rootgate_released | PASS | PASS | flag stormwood:rootgate_released (any) set after 0 frames |
| 18 | 1 | wait_flag — fixture fact reached both peers: stormwood:rootgate_released | PASS | PASS | flag stormwood:rootgate_released (any) set after 0 frames |
| 19 | 0 | wait_flag — fixture fact reached both peers: stormwood:lantern_pools_linked | PASS | PASS | flag stormwood:lantern_pools_linked (any) set after 0 frames |
| 19 | 1 | wait_flag — fixture fact reached both peers: stormwood:lantern_pools_linked | PASS | PASS | flag stormwood:lantern_pools_linked (any) set after 0 frames |
| 20 | 0 | wait_flag — fixture fact reached both peers: stormwood:crown_reached | PASS | PASS | flag stormwood:crown_reached (any) set after 0 frames |
| 20 | 1 | wait_flag — fixture fact reached both peers: stormwood:crown_reached | PASS | PASS | flag stormwood:crown_reached (any) set after 0 frames |
| 21 | 0 | wait_flag — fixture fact reached both peers: stormwood:bryn_met | PASS | PASS | flag stormwood:bryn_met (any) set after 0 frames |
| 21 | 1 | wait_flag — fixture fact reached both peers: stormwood:bryn_met | PASS | PASS | flag stormwood:bryn_met (any) set after 0 frames |
| 22 | 0 | wait_flag — fixture fact reached both peers: stormwood:arch_recipe_known | PASS | PASS | flag stormwood:arch_recipe_known (any) set after 0 frames |
| 22 | 1 | wait_flag — fixture fact reached both peers: stormwood:arch_recipe_known | PASS | PASS | flag stormwood:arch_recipe_known (any) set after 0 frames |
| 23 | 0 | capture_saves — BASELINE: both peers' saves with every prerequisite and no side-chain step | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 5 files to /tmp/claude-0/-home-user-Tetherbound/6050aa73-5362-5e48-a427-17c5687ec66b/scratchpad/proofs/F10-1-receipts-v28/peer-0/before |
| 23 | 1 | capture_saves — BASELINE: both peers' saves with every prerequisite and no side-chain step | PASS | PASS | client (character only): autosave_here()=false, character 'character-4123983c465de4df2f1642da69142a08' on disk=true; copied 2 files to /tmp/claude-0/-home-user-Tetherbound/6050aa73-5362-5e48-a427-17c5687ec66b/scratchpad/proofs/F10-1-receipts-v28/peer-1/before |
| 24 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 24 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 25 | 0 | storage_grant — SETUP (stands in for gathering): 12 Stormglass for four relights | PASS | PASS | granted 12 stormglass (0 did not fit; waited 0 guard frame(s)) |
| 26 | 0 | explore_at — SETUP (debug travel): stand at dark arch c_rodline | PASS | PASS | stood at (-720, 2257), settled at (-720.0, 2257.0), y=43.1 |
| 27 | 0 | press — host presses 'Relight' on dark arch c_rodline (tries it: the inspection; pays 3 Stormglass) | PASS | PASS | pressed 'interact' x1 |
| 28 | 0 | wait_flag — c_rodline lit, for both peers | PASS | PASS | flag stormwood:arch:c_rodline:lit (any) set after 0 frames |
| 28 | 1 | wait_flag — c_rodline lit, for both peers | PASS | PASS | flag stormwood:arch:c_rodline:lit (any) set after 0 frames |
| 29 | 0 | explore_at — SETUP (debug travel): stand at dark arch c_lantern | PASS | PASS | stood at (-420, 4013), settled at (-420.0, 4013.0), y=61.9 |
| 30 | 0 | press — host presses 'Relight' on dark arch c_lantern (tries it: the inspection; pays 3 Stormglass) | PASS | PASS | pressed 'interact' x1 |
| 31 | 0 | wait_flag — c_lantern lit, for both peers | PASS | PASS | flag stormwood:arch:c_lantern:lit (any) set after 0 frames |
| 31 | 1 | wait_flag — c_lantern lit, for both peers | PASS | PASS | flag stormwood:arch:c_lantern:lit (any) set after 0 frames |
| 32 | 0 | explore_at — SETUP (debug travel): stand at dark arch d_hall | PASS | PASS | stood at (-1120, 3867), settled at (-1120.0, 3867.0), y=37.3 |
| 33 | 0 | press — host presses 'Relight' on dark arch d_hall (tries it: the inspection; pays 3 Stormglass) | PASS | PASS | pressed 'interact' x1 |
| 34 | 0 | wait_flag — d_hall lit, for both peers | PASS | PASS | flag stormwood:arch:d_hall:lit (any) set after 0 frames |
| 34 | 1 | wait_flag — d_hall lit, for both peers | PASS | PASS | flag stormwood:arch:d_hall:lit (any) set after 0 frames |
| 35 | 0 | explore_at — SETUP (debug travel): stand at dark arch d_giant | PASS | PASS | stood at (-150, 4463), settled at (-150.0, 4463.0), y=61.2 |
| 36 | 0 | press — host presses 'Relight' on dark arch d_giant (tries it: the inspection; pays 3 Stormglass) | PASS | PASS | pressed 'interact' x1 |
| 37 | 0 | wait_flag — d_giant lit, for both peers | PASS | PASS | flag stormwood:arch:d_giant:lit (any) set after 0 frames |
| 37 | 1 | wait_flag — d_giant lit, for both peers | PASS | PASS | flag stormwood:arch:d_giant:lit (any) set after 0 frames |
| 38 | 0 | wait_flag — Dark Arches step 1 (a dark arch inspected) on both | PASS | PASS | flag stormwood:side_dark_arches_1 (any) set after 0 frames |
| 38 | 1 | wait_flag — Dark Arches step 1 (a dark arch inspected) on both | PASS | PASS | flag stormwood:side_dark_arches_1 (any) set after 0 frames |
| 39 | 0 | wait_flag — Dark Arches step 2 (both dark pairs relit) on both, from the arch runtime | PASS | PASS | flag stormwood:side_dark_arches_2 (any) set after 0 frames |
| 39 | 1 | wait_flag — Dark Arches step 2 (both dark pairs relit) on both, from the arch runtime | PASS | PASS | flag stormwood:side_dark_arches_2 (any) set after 0 frames |
| 40 | 0 | await_probe — the four relights took all 12 of the host's Stormglass (3 each, host-committed) | PASS | PASS | character_restore.live.satchel.stormglass == <null> after 0 polls |
| 41 | 0 | explore_at — SETUP (debug travel): stand beside Rodkeeper Hesk | PASS | PASS | stood at (-350, 448), settled at (-350.0, 448.0), y=30.2 |
| 42 | 0 | press — Interact with Rodkeeper Hesk | PASS | PASS | pressed 'interact' x1 |
| 43 | 0 | await_probe — Rodkeeper Hesk opens 'stormwood_hesk_dark_arches_report' | PASS | PASS | relay_crossing.conversation_id == stormwood_hesk_dark_arches_report after 0 polls |
| 44 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 45 | 0 | press — read both lines of 'stormwood_hesk_dark_arches_report' (the owed report) | PASS | PASS | pressed 'interact' x2 |
| 46 | 0 | await_probe — 'stormwood_hesk_dark_arches_report' closed | PASS | PASS | relay_crossing.dialogue_open == false after 0 polls |
| 47 | 0 | wait_flag — DARK ARCHES COMPLETE on both peers | PASS | PASS | flag stormwood:side_dark_arches_complete (any) set after 0 frames |
| 47 | 1 | wait_flag — DARK ARCHES COMPLETE on both peers | PASS | PASS | flag stormwood:side_dark_arches_complete (any) set after 0 frames |
| 48 | 1 | explore_at — SETUP (debug travel): stand beside Pim | PASS | PASS | stood at (-380, 1398), settled at (-380.0, 1398.0), y=32.1 |
| 49 | 1 | press — Interact with Pim | PASS | PASS | pressed 'interact' x1 |
| 50 | 1 | await_probe — Pim opens 'stormwood_pim_parcels_offer' | PASS | PASS | relay_crossing.conversation_id == stormwood_pim_parcels_offer after 0 polls |
| 51 | 1 | press — read both lines of 'stormwood_pim_parcels_offer' (take the sealed parcels) | PASS | PASS | pressed 'interact' x2 |
| 52 | 1 | await_probe — 'stormwood_pim_parcels_offer' closed | PASS | PASS | relay_crossing.dialogue_open == false after 0 polls |
| 53 | 0 | wait_flag — Pim's step 1 on both | PASS | PASS | flag stormwood:side_pims_parcels_1 (any) set after 0 frames |
| 53 | 1 | wait_flag — Pim's step 1 on both | PASS | PASS | flag stormwood:side_pims_parcels_1 (any) set after 0 frames |
| 54 | 1 | explore_at — SETUP (debug travel): stand beside Marl | PASS | PASS | stood at (-360, 441), settled at (-360.0, 441.0), y=30.7 |
| 55 | 1 | press — Interact with Marl | PASS | PASS | pressed 'interact' x1 |
| 56 | 1 | await_probe — Marl opens 'stormwood_pim_parcel_cook_marl' | PASS | PASS | relay_crossing.conversation_id == stormwood_pim_parcel_cook_marl after 0 polls |
| 57 | 1 | press — read both lines of 'stormwood_pim_parcel_cook_marl' (hand over a parcel) | PASS | PASS | pressed 'interact' x2 |
| 58 | 1 | await_probe — 'stormwood_pim_parcel_cook_marl' closed | PASS | PASS | relay_crossing.dialogue_open == false after 0 polls |
| 59 | 0 | wait_flag — parcel delivered to Marl, on both | PASS | PASS | flag stormwood:side_pims_parcels_delivered:cook_marl (any) set after 0 frames |
| 59 | 1 | wait_flag — parcel delivered to Marl, on both | PASS | PASS | flag stormwood:side_pims_parcels_delivered:cook_marl (any) set after 0 frames |
| 60 | 1 | explore_at — SETUP (debug travel): stand beside Oswin | PASS | PASS | stood at (-680, 2308), settled at (-680.0, 2308.0), y=46.3 |
| 61 | 1 | press — Interact with Oswin | PASS | PASS | pressed 'interact' x1 |
| 62 | 1 | await_probe — Oswin opens 'stormwood_pim_parcel_trader_oswin' | PASS | PASS | relay_crossing.conversation_id == stormwood_pim_parcel_trader_oswin after 0 polls |
| 63 | 1 | press — read both lines of 'stormwood_pim_parcel_trader_oswin' (hand over a parcel) | PASS | PASS | pressed 'interact' x2 |
| 64 | 1 | await_probe — 'stormwood_pim_parcel_trader_oswin' closed | PASS | PASS | relay_crossing.dialogue_open == false after 0 polls |
| 65 | 0 | wait_flag — parcel delivered to Oswin, on both | PASS | PASS | flag stormwood:side_pims_parcels_delivered:trader_oswin (any) set after 0 frames |
| 65 | 1 | wait_flag — parcel delivered to Oswin, on both | PASS | PASS | flag stormwood:side_pims_parcels_delivered:trader_oswin (any) set after 0 frames |
| 66 | 1 | explore_at — SETUP (debug travel): stand beside Lio | PASS | PASS | stood at (-350, 4048), settled at (-350.0, 4048.0), y=65.2 |
| 67 | 1 | press — Interact with Lio | PASS | PASS | pressed 'interact' x1 |
| 68 | 1 | await_probe — Lio opens 'stormwood_pim_parcel_caretaker_lio' | PASS | PASS | relay_crossing.conversation_id == stormwood_pim_parcel_caretaker_lio after 0 polls |
| 69 | 1 | press — read both lines of 'stormwood_pim_parcel_caretaker_lio' (hand over a parcel) | PASS | PASS | pressed 'interact' x2 |
| 70 | 1 | await_probe — 'stormwood_pim_parcel_caretaker_lio' closed | PASS | PASS | relay_crossing.dialogue_open == false after 0 polls |
| 71 | 0 | wait_flag — parcel delivered to Lio, on both | PASS | PASS | flag stormwood:side_pims_parcels_delivered:caretaker_lio (any) set after 0 frames |
| 71 | 1 | wait_flag — parcel delivered to Lio, on both | PASS | PASS | flag stormwood:side_pims_parcels_delivered:caretaker_lio (any) set after 0 frames |
| 72 | 0 | wait_flag — Pim's step 2 (three deliveries) on both | PASS | PASS | flag stormwood:side_pims_parcels_2 (any) set after 0 frames |
| 72 | 1 | wait_flag — Pim's step 2 (three deliveries) on both | PASS | PASS | flag stormwood:side_pims_parcels_2 (any) set after 0 frames |
| 73 | 1 | explore_at — SETUP (debug travel): stand beside Pim | PASS | PASS | stood at (-380, 1398), settled at (-380.0, 1398.0), y=32.1 |
| 74 | 1 | press — Interact with Pim | PASS | PASS | pressed 'interact' x1 |
| 75 | 1 | await_probe — Pim opens 'stormwood_pim_parcels_return' | PASS | PASS | relay_crossing.conversation_id == stormwood_pim_parcels_return after 0 polls |
| 76 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 77 | 1 | press — read both lines of 'stormwood_pim_parcels_return' (return to Pim: completion and the guest's rate) | PASS | PASS | pressed 'interact' x2 |
| 78 | 1 | await_probe — 'stormwood_pim_parcels_return' closed | PASS | PASS | relay_crossing.dialogue_open == false after 0 polls |
| 79 | 0 | wait_flag — PIM'S PARCELS COMPLETE on both peers | PASS | PASS | flag stormwood:side_pims_parcels_complete (any) set after 0 frames |
| 79 | 1 | wait_flag — PIM'S PARCELS COMPLETE on both peers | PASS | PASS | flag stormwood:side_pims_parcels_complete (any) set after 0 frames |
| 80 | 1 | await_probe — guest paid the courier rate once: 2 Small Potions | PASS | PASS | character_restore.live.satchel.potion_small == 2.0 after 0 polls |
| 81 | 0 | explore_at — SETUP (debug travel): stand beside Pim | PASS | PASS | stood at (-380, 1398), settled at (-380.0, 1398.0), y=32.1 |
| 82 | 0 | press — Interact with Pim | PASS | PASS | pressed 'interact' x1 |
| 83 | 0 | await_probe — Pim opens 'stormwood_pim_parcels_thanks' | PASS | PASS | relay_crossing.conversation_id == stormwood_pim_parcels_thanks after 0 polls |
| 84 | 0 | press — read both lines of 'stormwood_pim_parcels_thanks' (host's own thanks: the host's rate) | PASS | PASS | pressed 'interact' x2 |
| 85 | 0 | await_probe — 'stormwood_pim_parcels_thanks' closed | PASS | PASS | relay_crossing.dialogue_open == false after 0 polls |
| 86 | 0 | await_probe — host paid its own rate once: 2 Small Potions | PASS | PASS | character_restore.live.satchel.potion_small == 2.0 after 0 polls |
| 87 | 0 | explore_at — SETUP (debug travel): stand beside Crown record rain_ledger | PASS | PASS | stood at (671, 2730), settled at (670.7, 2730.2), y=74.0 |
| 88 | 0 | press — Interact with Crown record rain_ledger | PASS | PASS | pressed 'interact' x1 |
| 89 | 0 | await_probe — Crown record rain_ledger opens 'stormwood_crown_record_rain_ledger' | PASS | PASS | relay_crossing.conversation_id == stormwood_crown_record_rain_ledger after 0 polls |
| 90 | 0 | press — read both lines of 'stormwood_crown_record_rain_ledger' (read the record) | PASS | PASS | pressed 'interact' x2 |
| 91 | 0 | await_probe — 'stormwood_crown_record_rain_ledger' closed | PASS | PASS | relay_crossing.dialogue_open == false after 0 polls |
| 92 | 0 | wait_flag — record rain_ledger read, on both | PASS | PASS | flag stormwood:side_crown_remembers_record:rain_ledger (any) set after 0 frames |
| 92 | 1 | wait_flag — record rain_ledger read, on both | PASS | PASS | flag stormwood:side_crown_remembers_record:rain_ledger (any) set after 0 frames |
| 93 | 0 | explore_at — SETUP (debug travel): stand beside Crown record root_census | PASS | PASS | stood at (735, 2715), settled at (735.1, 2715.2), y=74.0 |
| 94 | 0 | press — Interact with Crown record root_census | PASS | PASS | pressed 'interact' x1 |
| 95 | 0 | await_probe — Crown record root_census opens 'stormwood_crown_record_root_census' | PASS | PASS | relay_crossing.conversation_id == stormwood_crown_record_root_census after 0 polls |
| 96 | 0 | press — read both lines of 'stormwood_crown_record_root_census' (read the record) | PASS | PASS | pressed 'interact' x2 |
| 97 | 0 | await_probe — 'stormwood_crown_record_root_census' closed | PASS | PASS | relay_crossing.dialogue_open == false after 0 polls |
| 98 | 0 | wait_flag — record root_census read, on both | PASS | PASS | flag stormwood:side_crown_remembers_record:root_census (any) set after 0 frames |
| 98 | 1 | wait_flag — record root_census read, on both | PASS | PASS | flag stormwood:side_crown_remembers_record:root_census (any) set after 0 frames |
| 99 | 0 | explore_at — SETUP (debug travel): stand beside Crown record reversal_mark | PASS | PASS | stood at (689, 2686), settled at (689.2, 2686.1), y=74.0 |
| 100 | 0 | press — Interact with Crown record reversal_mark | PASS | PASS | pressed 'interact' x1 |
| 101 | 0 | await_probe — Crown record reversal_mark opens 'stormwood_crown_record_reversal_mark' | PASS | PASS | relay_crossing.conversation_id == stormwood_crown_record_reversal_mark after 0 polls |
| 102 | 0 | press — read both lines of 'stormwood_crown_record_reversal_mark' (read the record) | PASS | PASS | pressed 'interact' x2 |
| 103 | 0 | await_probe — 'stormwood_crown_record_reversal_mark' closed | PASS | PASS | relay_crossing.dialogue_open == false after 0 polls |
| 104 | 0 | wait_flag — record reversal_mark read, on both | PASS | PASS | flag stormwood:side_crown_remembers_record:reversal_mark (any) set after 0 frames |
| 104 | 1 | wait_flag — record reversal_mark read, on both | PASS | PASS | flag stormwood:side_crown_remembers_record:reversal_mark (any) set after 0 frames |
| 105 | 0 | wait_flag — Crown step 1 on both | PASS | PASS | flag stormwood:side_crown_remembers_1 (any) set after 0 frames |
| 105 | 1 | wait_flag — Crown step 1 on both | PASS | PASS | flag stormwood:side_crown_remembers_1 (any) set after 0 frames |
| 106 | 0 | wait_flag — Crown step 2 (all three read) on both | PASS | PASS | flag stormwood:side_crown_remembers_2 (any) set after 0 frames |
| 106 | 1 | wait_flag — Crown step 2 (all three read) on both | PASS | PASS | flag stormwood:side_crown_remembers_2 (any) set after 0 frames |
| 107 | 0 | explore_at — SETUP (debug travel): stand beside Archivist Wen | PASS | PASS | stood at (700, 2698), settled at (700.0, 2697.5), y=74.0 |
| 108 | 0 | press — Interact with Archivist Wen | PASS | PASS | pressed 'interact' x1 |
| 109 | 0 | await_probe — Archivist Wen opens 'stormwood_wen_crown_records_return' | PASS | PASS | relay_crossing.conversation_id == stormwood_wen_crown_records_return after 0 polls |
| 110 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 111 | 0 | press — read both lines of 'stormwood_wen_crown_records_return' (bring the account to Wen) | PASS | PASS | pressed 'interact' x2 |
| 112 | 0 | await_probe — 'stormwood_wen_crown_records_return' closed | PASS | PASS | relay_crossing.dialogue_open == false after 0 polls |
| 113 | 0 | wait_flag — WHAT THE CROWN REMEMBERS COMPLETE on both peers | PASS | PASS | flag stormwood:side_crown_remembers_complete (any) set after 0 frames |
| 113 | 1 | wait_flag — WHAT THE CROWN REMEMBERS COMPLETE on both peers | PASS | PASS | flag stormwood:side_crown_remembers_complete (any) set after 0 frames |
| 114 | 1 | storage_grant — SETUP (stands in for gathering): 3 Stormglass | PASS | PASS | granted 3 stormglass (0 did not fit; waited 0 guard frame(s)) |
| 115 | 1 | storage_grant — SETUP (stands in for gathering): 2 Conductor Vine | PASS | PASS | granted 2 conductor_vine (0 did not fit; waited 0 guard frame(s)) |
| 116 | 1 | explore_at — SETUP (debug travel): stand beside Warden-Elect Bryn | PASS | PASS | stood at (-700, 2298), settled at (-700.0, 2298.0), y=43.8 |
| 117 | 1 | press — Interact with Warden-Elect Bryn | PASS | PASS | pressed 'interact' x1 |
| 118 | 1 | await_probe — Warden-Elect Bryn opens 'stormwood_bryn_glass_offer' | PASS | PASS | relay_crossing.conversation_id == stormwood_bryn_glass_offer after 0 polls |
| 119 | 1 | press — read both lines of 'stormwood_bryn_glass_offer' (ask what the crews need) | PASS | PASS | pressed 'interact' x2 |
| 120 | 1 | await_probe — 'stormwood_bryn_glass_offer' closed | PASS | PASS | relay_crossing.dialogue_open == false after 0 polls |
| 121 | 0 | wait_flag — Bryn step 1 on both | PASS | PASS | flag stormwood:side_glass_for_bryn_1 (any) set after 0 frames |
| 121 | 1 | wait_flag — Bryn step 1 on both | PASS | PASS | flag stormwood:side_glass_for_bryn_1 (any) set after 0 frames |
| 122 | 1 | explore_at — SETUP (debug travel): stand beside Warden-Elect Bryn | PASS | PASS | stood at (-700, 2298), settled at (-700.0, 2298.0), y=43.8 |
| 123 | 1 | press — Interact with Warden-Elect Bryn | PASS | PASS | pressed 'interact' x1 |
| 124 | 1 | await_probe — Warden-Elect Bryn opens 'stormwood_bryn_glass_request' | PASS | PASS | relay_crossing.conversation_id == stormwood_bryn_glass_request after 0 polls |
| 125 | 1 | press — read both lines of 'stormwood_bryn_glass_request' (hand over the materials) | PASS | PASS | pressed 'interact' x2 |
| 126 | 1 | await_probe — 'stormwood_bryn_glass_request' closed | PASS | PASS | relay_crossing.dialogue_open == false after 0 polls |
| 127 | 0 | wait_flag — Bryn step 2 (host-committed delivery) on both | PASS | PASS | flag stormwood:side_glass_for_bryn_2 (any) set after 0 frames |
| 127 | 1 | wait_flag — Bryn step 2 (host-committed delivery) on both | PASS | PASS | flag stormwood:side_glass_for_bryn_2 (any) set after 0 frames |
| 128 | 1 | await_probe — the host-owned delivery took the guest's 3 Stormglass | PASS | PASS | character_restore.live.satchel.stormglass == <null> after 0 polls |
| 129 | 1 | await_probe — and its 2 Conductor Vine, once | PASS | PASS | character_restore.live.satchel.conductor_vine == <null> after 0 polls |
| 130 | 1 | explore_at — SETUP (debug travel): stand at the repaired supplies | PASS | PASS | stood at (-713, 2308), settled at (-713.2, 2308.3), y=47.2 |
| 131 | 1 | press — guest presses 'Inspect the repaired supplies' | PASS | PASS | pressed 'interact' x1 |
| 132 | 0 | wait_flag — GLASS FOR BRYN COMPLETE on both peers | PASS | PASS | flag stormwood:side_glass_for_bryn_complete (any) set after 0 frames |
| 132 | 1 | wait_flag — GLASS FOR BRYN COMPLETE on both peers | PASS | PASS | flag stormwood:side_glass_for_bryn_complete (any) set after 0 frames |
| 133 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 134 | 0 | explore_at — SETUP (debug travel): stand at the Verge Road footing prompt | PASS | PASS | stood at (-630, 794), settled at (-630.0, 793.5), y=22.7 |
| 135 | 0 | press — host chooses the Verge Road footing | PASS | PASS | pressed 'interact' x1 |
| 136 | 0 | wait_flag — Verge Road chosen, on both | PASS | PASS | flag stormwood:side_raise_a_road_chosen:verge_road (any) set after 0 frames |
| 136 | 1 | wait_flag — Verge Road chosen, on both | PASS | PASS | flag stormwood:side_raise_a_road_chosen:verge_road (any) set after 0 frames |
| 137 | 0 | explore_at — SETUP (debug travel): stand at the Hollows Road footing prompt | PASS | PASS | stood at (-1050, 1744), settled at (-1050.0, 1743.5), y=29.9 |
| 138 | 0 | press — host chooses the Hollows Road footing | PASS | PASS | pressed 'interact' x1 |
| 139 | 0 | wait_flag — Hollows Road chosen, on both | PASS | PASS | flag stormwood:side_raise_a_road_chosen:hollows_road (any) set after 0 frames |
| 139 | 1 | wait_flag — Hollows Road chosen, on both | PASS | PASS | flag stormwood:side_raise_a_road_chosen:hollows_road (any) set after 0 frames |
| 140 | 0 | wait_flag — Road step 1 on both | PASS | PASS | flag stormwood:side_raise_a_road_1 (any) set after 0 frames |
| 140 | 1 | wait_flag — Road step 1 on both | PASS | PASS | flag stormwood:side_raise_a_road_1 (any) set after 0 frames |
| 141 | 0 | explore_at — SETUP (debug travel): on the Verge Road footing | PASS | PASS | stood at (-630, 797), settled at (-630.0, 797.0), y=22.4 |
| 142 | 0 | build_place — SETUP (free build: materials not charged): raise a Stormglass Arch on the Verge Road footing | PASS | PASS | pressed Place for 'stormglass_arch' (ghost_ok=true); records 0 -> 1 |
| 143 | 0 | explore_at — SETUP (debug travel): on the Hollows Road footing | PASS | PASS | stood at (-1050, 1747), settled at (-1050.0, 1747.0), y=29.7 |
| 144 | 0 | build_place — SETUP (free build): raise its twin on the Hollows Road footing | PASS | PASS | pressed Place for 'stormglass_arch' (ghost_ok=true); records 1 -> 2 |
| 145 | 0 | wait_flag — Road step 2 (both built and bound) on both, from the arch runtime | PASS | PASS | flag stormwood:side_raise_a_road_2 (any) set after 0 frames |
| 145 | 1 | wait_flag — Road step 2 (both built and bound) on both, from the arch runtime | PASS | PASS | flag stormwood:side_raise_a_road_2 (any) set after 9 frames |
| 146 | 0 | explore_at — SETUP (debug travel): walk into the Verge Road arch | PASS | PASS | stood at (-630, 800), settled at (-1050.0, 1753.5), y=29.7 |
| 147 | 0 | probe position — the host was carried to the Hollows Road twin | PASS | PASS | [-1050.0,29.7033843994141,1753.5] |
| 148 | 0 | explore_at — SETUP (debug travel): walk into the Hollows Road arch | PASS | PASS | stood at (-1050, 1750), settled at (-630.0, 803.5), y=22.2 |
| 149 | 0 | probe position — the host was carried back to the Verge Road twin | PASS | PASS | [-630.0,22.209716796875,803.5] |
| 150 | 0 | wait_flag — Road step 3 (travelled both directions) on both | PASS | PASS | flag stormwood:side_raise_a_road_3 (any) set after 0 frames |
| 150 | 1 | wait_flag — Road step 3 (travelled both directions) on both | PASS | PASS | flag stormwood:side_raise_a_road_3 (any) set after 0 frames |
| 151 | 0 | explore_at — SETUP (debug travel): stand beside Keeper Ondra | PASS | PASS | stood at (-160, 2698), settled at (-160.0, 2698.0), y=34.5 |
| 152 | 0 | press — Interact with Keeper Ondra | PASS | PASS | pressed 'interact' x1 |
| 153 | 0 | await_probe — Keeper Ondra opens 'stormwood_ondra_raise_a_road_report' | PASS | PASS | relay_crossing.conversation_id == stormwood_ondra_raise_a_road_report after 0 polls |
| 154 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 155 | 0 | press — read both lines of 'stormwood_ondra_raise_a_road_report' (report the new road) | PASS | PASS | pressed 'interact' x2 |
| 156 | 0 | await_probe — 'stormwood_ondra_raise_a_road_report' closed | PASS | PASS | relay_crossing.dialogue_open == false after 0 polls |
| 157 | 0 | wait_flag — RAISE A ROAD COMPLETE on both peers | PASS | PASS | flag stormwood:side_raise_a_road_complete (any) set after 0 frames |
| 157 | 1 | wait_flag — RAISE A ROAD COMPLETE on both peers | PASS | PASS | flag stormwood:side_raise_a_road_complete (any) set after 0 frames |
| 158 | 0 | story_flag — FIXTURE (main-route fact, no side-chain step): stormwood:lantern_hollow_reached — reveals the Deepwood Circuit (Lantern Hollow arrival) | PASS | PASS | stormwood:lantern_hollow_reached: ok=true pending=false code='' reason='' |
| 159 | 0 | wait_flag — fixture fact reached both peers | PASS | PASS | flag stormwood:lantern_hollow_reached (any) set after 0 frames |
| 159 | 1 | wait_flag — fixture fact reached both peers | PASS | PASS | flag stormwood:lantern_hollow_reached (any) set after 0 frames |
| 160 | 0 | explore_at — SETUP (debug travel): stand beside Rook | PASS | PASS | stood at (-150, 4458), settled at (-150.0, 4458.0), y=61.2 |
| 161 | 0 | press — Interact with Rook | PASS | PASS | pressed 'interact' x1 |
| 162 | 0 | await_probe — Rook opens 'stormwood_rook_circuit_offer' | PASS | PASS | relay_crossing.conversation_id == stormwood_rook_circuit_offer after 0 polls |
| 163 | 0 | press — read both lines of 'stormwood_rook_circuit_offer' (accept the circuit) | PASS | PASS | pressed 'interact' x2 |
| 164 | 0 | await_probe — 'stormwood_rook_circuit_offer' closed | PASS | PASS | relay_crossing.dialogue_open == false after 0 polls |
| 165 | 0 | wait_flag — Circuit step 1 on both | PASS | PASS | flag stormwood:side_deepwood_circuit_1 (any) set after 0 frames |
| 165 | 1 | wait_flag — Circuit step 1 on both | PASS | PASS | flag stormwood:side_deepwood_circuit_1 (any) set after 0 frames |
| 166 | 0 | story_flag — FIXTURE (stands in for the hosted fight; hosted trainer wins are proven by smoke_net_stormwood_hosted_trainers): circuit_lena_giant defeated | PASS | PASS | stormwood:trainer:circuit_lena_giant:defeated: ok=true pending=false code='' reason='' |
| 167 | 0 | wait_flag — the chapter runtime credits circuit_lena_giant as a circuit win, on both | PASS | PASS | flag stormwood:side_deepwood_circuit_win:circuit_lena_giant (any) set after 0 frames |
| 167 | 1 | wait_flag — the chapter runtime credits circuit_lena_giant as a circuit win, on both | PASS | PASS | flag stormwood:side_deepwood_circuit_win:circuit_lena_giant (any) set after 0 frames |
| 168 | 0 | story_flag — FIXTURE (stands in for the hosted fight; hosted trainer wins are proven by smoke_net_stormwood_hosted_trainers): circuit_orin_blackwater defeated | PASS | PASS | stormwood:trainer:circuit_orin_blackwater:defeated: ok=true pending=false code='' reason='' |
| 169 | 0 | wait_flag — the chapter runtime credits circuit_orin_blackwater as a circuit win, on both | PASS | PASS | flag stormwood:side_deepwood_circuit_win:circuit_orin_blackwater (any) set after 0 frames |
| 169 | 1 | wait_flag — the chapter runtime credits circuit_orin_blackwater as a circuit win, on both | PASS | PASS | flag stormwood:side_deepwood_circuit_win:circuit_orin_blackwater (any) set after 0 frames |
| 170 | 0 | story_flag — FIXTURE (stands in for the hosted fight; hosted trainer wins are proven by smoke_net_stormwood_hosted_trainers): circuit_tavi_rodline defeated | PASS | PASS | stormwood:trainer:circuit_tavi_rodline:defeated: ok=true pending=false code='' reason='' |
| 171 | 0 | wait_flag — the chapter runtime credits circuit_tavi_rodline as a circuit win, on both | PASS | PASS | flag stormwood:side_deepwood_circuit_win:circuit_tavi_rodline (any) set after 0 frames |
| 171 | 1 | wait_flag — the chapter runtime credits circuit_tavi_rodline as a circuit win, on both | PASS | PASS | flag stormwood:side_deepwood_circuit_win:circuit_tavi_rodline (any) set after 0 frames |
| 172 | 0 | wait_flag — Circuit step 2 (three of five) on both | PASS | PASS | flag stormwood:side_deepwood_circuit_2 (any) set after 0 frames |
| 172 | 1 | wait_flag — Circuit step 2 (three of five) on both | PASS | PASS | flag stormwood:side_deepwood_circuit_2 (any) set after 0 frames |
| 173 | 0 | explore_at — SETUP (debug travel): stand beside Rook | PASS | PASS | stood at (-150, 4458), settled at (-150.0, 4458.0), y=61.2 |
| 174 | 0 | press — Interact with Rook | PASS | PASS | pressed 'interact' x1 |
| 175 | 0 | await_probe — Rook opens 'stormwood_rook_circuit_return' | PASS | PASS | relay_crossing.conversation_id == stormwood_rook_circuit_return after 0 polls |
| 176 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 177 | 0 | press — read both lines of 'stormwood_rook_circuit_return' (return to Rook) | PASS | PASS | pressed 'interact' x2 |
| 178 | 0 | await_probe — 'stormwood_rook_circuit_return' closed | PASS | FAIL **(unexpected)** | relay_crossing.dialogue_open was true, not false, after 240 polls |

## Captured files

- `peer-0/before/characters/redesign-v28/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/before/saves/redesign-v28/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/before/saves/redesign-v28/slot_0.json`
- `peer-0/before/saves/redesign-v28/worlds/slot-0/world.json`
- `peer-0/before/worlds/redesign-v28/slot-0/world.json`
- `peer-1/before/characters/redesign-v28/character-4123983c465de4df2f1642da69142a08/character.json`
- `peer-1/before/saves/redesign-v28/characters/character-4123983c465de4df2f1642da69142a08/character.json`
