# Two-peer proof: C3: Cloudreach co-op and aftermath -- host and guest cross flight and realm boundaries, drop/rejoin and reload without duplicating relic/key or losing rider/party identity

**Verdict: PASS** (exit 0)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/c3_cloudreach_coop_aftermath.json`  
Run: `net-20260927T221818Z-18566`  
Rendered: no (headless)

ACCEPTANCE card C3. Fixtures (disclosed): story_flag world flags stand in for the completed Cloudreach chapter (the earned play is card C1); heart_earn submits the Wings heart through the ledger; party_grant gives each peer four L30 creatures and fly_setup adds an owned galecrest carrier as the fifth (the mentor loaner ends at cloudreach_chapter_complete). Launch, landing, drop, rejoin, realm crossings, host restart/title Load, saves and hashes are the game's own code. The heart and key are world flags (entitlements), so 'not duplicated' is checked as: each read once from the host world, unchanged hash across restart+rejoin, and the saved world keeps them. Loopback ENet: local evidence, not internet/Steam acceptance. Owner ruling 2026-09-27 (#356 5858140459): Solmane is freed after Captain Veyra's defeat and offered once to each finale participant, exactly like the Meadows Veridian; this card's own aftermath answers that offer for both peers through the real accept_offer/refuse_offer handlers (veridian_answer, node CloudreachSolmaneClimax). Both peers are already at their five-creature cap here (four granted companions plus the fly_setup galecrest fifth), so both refuse -- an accept without room needs a release ceremony this card does not model -- and the refusal receipt is proven to survive the mid-scenario drop/rejoin and the host's restart+reload with no second offer and no Solmane in either saved character. The no-second-offer-after-restart check is proven by f08_5_solmane_two_peer (run3); here the receipts' persistence through the restart is read from Stormwood (run1: a return crossing to Cloudreach after the restart outran the 15 s heartbeat while the realm built).

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | boot — each peer boots its own fresh Meadows world | PASS | PASS | booted world (240 settle frames) |
| 1 | 1 | boot — each peer boots its own fresh Meadows world | PASS | PASS | booted world (240 settle frames) |
| 2 | 0 | host | PASS | PASS | hosting udp/34521 as peer 1 |
| 3 | 1 | join | PASS | PASS | joined 127.0.0.1:34521 as peer 413422135 after 17 frames; snapshot applied; 2 peer(s) in registry |
| 4 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 4 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 5 | 0 | story_flag — SETUP (disclosed): host world holds realm_key_cloudreach (stands in for the earned chapter; C1 is the earned play) | PASS | PASS | realm_key_cloudreach: ok=true pending=false code='' reason='' |
| 6 | 0 | story_flag — SETUP (disclosed): host world holds fly_traversal_unlocked (stands in for the earned chapter; C1 is the earned play) | PASS | PASS | fly_traversal_unlocked: ok=true pending=false code='' reason='' |
| 7 | 0 | story_flag — SETUP (disclosed): host world holds sky_shrine_reached (stands in for the earned chapter; C1 is the earned play) | PASS | PASS | sky_shrine_reached: ok=true pending=false code='' reason='' |
| 8 | 0 | story_flag — SETUP (disclosed): host world holds cloudreach_upper_route_unlocked (stands in for the earned chapter; C1 is the earned play) | PASS | PASS | cloudreach_upper_route_unlocked: ok=true pending=false code='' reason='' |
| 9 | 0 | story_flag — SETUP (disclosed): host world holds captain_veyra_defeated (stands in for the earned chapter; C1 is the earned play) | PASS | PASS | captain_veyra_defeated: ok=true pending=false code='' reason='' |
| 10 | 0 | story_flag — SETUP (disclosed): host world holds storm_anchor_network_disabled (stands in for the earned chapter; C1 is the earned play) | PASS | PASS | storm_anchor_network_disabled: ok=true pending=false code='' reason='' |
| 11 | 0 | story_flag — SETUP (disclosed): host world holds cloudreach_winds_restored (stands in for the earned chapter; C1 is the earned play) | PASS | PASS | cloudreach_winds_restored: ok=true pending=false code='' reason='' |
| 12 | 0 | story_flag — SETUP (disclosed): host world holds cloudreach_chapter_complete (stands in for the earned chapter; C1 is the earned play) | PASS | PASS | cloudreach_chapter_complete: ok=true pending=false code='' reason='' |
| 13 | 0 | story_flag — SETUP (disclosed): host world holds realm_key_stormwood (stands in for the earned chapter; C1 is the earned play) | PASS | PASS | realm_key_stormwood: ok=true pending=false code='' reason='' |
| 14 | 0 | heart_earn — SETUP: the Wings of Cloudreach heart earned through the ledger | PASS | PASS | earned 'realm_heart_cloudreach_earned' (committed) |
| 15 | 0 | wait_flag — both peers read captain_veyra_defeated from the host world | PASS | PASS | flag captain_veyra_defeated (any) set after 0 frames |
| 15 | 1 | wait_flag — both peers read captain_veyra_defeated from the host world | PASS | PASS | flag captain_veyra_defeated (any) set after 0 frames |
| 16 | 0 | wait_flag — both peers read sky_shrine_reached from the host world | PASS | PASS | flag sky_shrine_reached (any) set after 0 frames |
| 16 | 1 | wait_flag — both peers read sky_shrine_reached from the host world | PASS | PASS | flag sky_shrine_reached (any) set after 0 frames |
| 17 | 0 | wait_flag — both peers read cloudreach_winds_restored from the host world | PASS | PASS | flag cloudreach_winds_restored (any) set after 0 frames |
| 17 | 1 | wait_flag — both peers read cloudreach_winds_restored from the host world | PASS | PASS | flag cloudreach_winds_restored (any) set after 0 frames |
| 18 | 0 | wait_flag — both peers read realm_heart_cloudreach_earned from the host world | PASS | PASS | flag realm_heart_cloudreach_earned (any) set after 0 frames |
| 18 | 1 | wait_flag — both peers read realm_heart_cloudreach_earned from the host world | PASS | PASS | flag realm_heart_cloudreach_earned (any) set after 0 frames |
| 19 | 0 | wait_flag — both peers read realm_key_stormwood from the host world | PASS | PASS | flag realm_key_stormwood (any) set after 0 frames |
| 19 | 1 | wait_flag — both peers read realm_key_stormwood from the host world | PASS | PASS | flag realm_key_stormwood (any) set after 0 frames |
| 20 | 0 | party_grant — SETUP: party_grant bramblebun | PASS | PASS | 'bramblebun' at level 30 joined the party (1 member(s)) |
| 21 | 0 | party_grant — SETUP: party_grant terrapup | PASS | PASS | 'terrapup' at level 30 joined the party (2 member(s)) |
| 22 | 0 | party_grant — SETUP: party_grant mudsnout | PASS | PASS | 'mudsnout' at level 30 joined the party (3 member(s)) |
| 23 | 0 | party_grant — SETUP: party_grant brooktail | PASS | PASS | 'brooktail' at level 30 joined the party (4 member(s)) |
| 24 | 1 | party_grant — SETUP: party_grant bramblebun | PASS | PASS | 'bramblebun' at level 30 joined the party (1 member(s)) |
| 25 | 1 | party_grant — SETUP: party_grant terrapup | PASS | PASS | 'terrapup' at level 30 joined the party (2 member(s)) |
| 26 | 1 | party_grant — SETUP: party_grant mudsnout | PASS | PASS | 'mudsnout' at level 30 joined the party (3 member(s)) |
| 27 | 1 | party_grant — SETUP: party_grant brooktail | PASS | PASS | 'brooktail' at level 30 joined the party (4 member(s)) |
| 28 | 0 | enter_realm — host crosses into Cloudreach | PASS | PASS | crossed 'meadows' -> 'cloudreach' after 761 observed physics frames / 64332 ms (budget 6000 physics frames); current scene is /root/CloudreachCliffs |
| 29 | 1 | enter_realm — guest crosses into Cloudreach | PASS | PASS | crossed 'meadows' -> 'cloudreach' after 777 observed physics frames / 57076 ms (budget 6000 physics frames); current scene is /root/CloudreachCliffs |
| 30 | 0 | teleport — SETUP (disclosed): stand on the Sky Shrine landing pad (open sky, Fly-only landmark) | PASS | PASS | trainer stands at (1110.00, 1050.00, 2940.00) |
| 31 | 0 | assert — standing on the shrine pad before the carrier setup | PASS | PASS | on_floor=true flying=false carried=false at (1110.0, 1050.0, 2940.0) |
| 32 | 0 | fly_setup — SETUP (disclosed): an owned galecrest carrier as the fifth (the loaner ends at chapter completion; galecrest is catchable in Meadows band 1) | PASS | PASS | SETUP: fly_traversal_unlocked set, galecrest active, anchor=(1120.0, 1020.03, 2957.321), screen: no dialogue box was open, launch site: cleared at (1120.0, 2957.3) after 20 m (locomotion=true carried=false on_floor=true) |
| 33 | 0 | assert — the launch search kept the trainer on the shrine pad | PASS | PASS | 20.00 m from (1110.0, 2940.0), wanted within 25.00 |
| 34 | 0 | party_uids — remember this peer's five owned UIDs | PASS | PASS | 5 owned: ["creature-e29fe4d27a3877902be9484b5be81fd7", "creature-fbc1ede0a94b92d85c305afe54ddc817", "creature-1f075afac4b7c211770382f4ead389e5", "creature-9a5dbc485c3a4068d2a149f69d64560f", "creature-b034bd045829fd4fbbf65f161115d95a"]; kept as 'uids0' |
| 35 | 0 | assert | PASS | PASS | party size 5 (wanted 5) |
| 36 | 1 | teleport — SETUP (disclosed): stand on the Sky Shrine landing pad (open sky, Fly-only landmark) | PASS | PASS | trainer stands at (1106.00, 1050.00, 2944.00) |
| 37 | 1 | assert — standing on the shrine pad before the carrier setup | PASS | PASS | on_floor=true flying=false carried=false at (1106.0, 1050.001, 2944.0) |
| 38 | 1 | fly_setup — SETUP (disclosed): an owned galecrest carrier as the fifth (the loaner ends at chapter completion; galecrest is catchable in Meadows band 1) | PASS | PASS | SETUP: fly_traversal_unlocked set, galecrest active, anchor=(1106.0, 1050.08, 2944.0), screen: no dialogue box was open, launch site: already clear where it stood (locomotion=true carried=false on_floor=true) |
| 39 | 1 | assert — the launch search kept the trainer on the shrine pad | PASS | PASS | 0.00 m from (1106.0, 2944.0), wanted within 25.00 |
| 40 | 1 | party_uids — remember this peer's five owned UIDs | PASS | PASS | 5 owned: ["creature-ed72be26c56edb2c2d6457bee308cf99", "creature-43867f20c78112483b2eeb0c931c3b2a", "creature-c8193faad367e68a7cf62c3d98716843", "creature-25c02928b94c2ac88d5df5f067f7c349", "creature-48ad85e12a4ff72c6520e1d549936fbd"]; kept as 'uids1' |
| 41 | 1 | assert | PASS | PASS | party size 5 (wanted 5) |
| 42 | 0 | hashes_agree | PASS | PASS | every peer's heartbeat carries world-state hash 1330741496; remembered as 'cloudreach_arrival' |
| 43 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-d2506ecc5addabed4ff6199524c50a25' on disk=true; copied 3 files to /tmp/claude-0/-home-user-Tetherbound/e2a7b766-819b-5513-9d61-d02cefeeb479/scratchpad/c3-sol-run2/peer-0/before |
| 43 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-b9b186e976e93f4d69e6eb7821e9ad50' on disk=true; copied 1 files to /tmp/claude-0/-home-user-Tetherbound/e2a7b766-819b-5513-9d61-d02cefeeb479/scratchpad/c3-sol-run2/peer-1/before |
| 44 | 0 | fly_launch — host launches Fly by double jump (production input) | PASS | PASS | flying (glide) at y=1022.27 on attempt 0 |
| 45 | 0 | fly_land — host holds descend to a floor landing | PASS | PASS | landed at (1120.00, 1020.03, 2957.32); anchor report {"accepts":0,"anchor":[1120.0,1020.02978515625,2957.32055664062],"host_granted":false,"host_validated":false,"last_code":"","last_denial":"","pending":false,"proposals":0,"realm":"cloudreach","refusals":0} |
| 46 | 0 | assert | PASS | PASS | on_floor=true flying=false carried=false at (1120.0, 1020.03, 2957.321) |
| 47 | 1 | fly_launch — guest launches Fly by double jump | PASS | PASS | flying (glide) at y=1052.24 on attempt 0 |
| 48 | 1 | drop_link — MID-FLIGHT DROP: the guest's link dies while flying | PASS | PASS | transport closed without a Session.leave() |
| 49 | 0 | expect_peers | PASS | PASS | registry reports 1 peer(s) after 0 frames (0.0 s) |
| 50 | 1 | production_join — REJOIN from the title as the same character | PASS | PASS | title returning entry built 'CloudreachCliffs' first, then JoinDriver joined 127.0.0.1:34521 as peer 430476528 after 32 frames |
| 51 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 51 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 52 | 1 | enter_realm — guest back into Cloudreach (ANY: the rejoin may already stand there) | any | FAIL | Game.enter_realm('cloudreach') refused from 'cloudreach' (can_enter=true) |
| 53 | 0 | wait_context | any | PASS | input_context=world after 0 frames |
| 53 | 1 | wait_context | any | PASS | input_context=world after 0 frames |
| 54 | 1 | assert — rider sane after the mid-flight drop: grounded, not flying, not carried | PASS | PASS | on_floor=true flying=false carried=false at (1106.0, 1051.3, 2944.0) |
| 55 | 1 | party_uids — the guest's five are the same owned creatures after the drop | PASS | PASS | 5 owned: ["creature-ed72be26c56edb2c2d6457bee308cf99", "creature-43867f20c78112483b2eeb0c931c3b2a", "creature-c8193faad367e68a7cf62c3d98716843", "creature-25c02928b94c2ac88d5df5f067f7c349", "creature-48ad85e12a4ff72c6520e1d549936fbd"]; exactly the 'uids1' list |
| 56 | 1 | wait_flag — after rejoin the guest still reads captain_veyra_defeated | PASS | PASS | flag captain_veyra_defeated (any) set after 0 frames |
| 57 | 1 | wait_flag — after rejoin the guest still reads sky_shrine_reached | PASS | PASS | flag sky_shrine_reached (any) set after 0 frames |
| 58 | 1 | wait_flag — after rejoin the guest still reads cloudreach_winds_restored | PASS | PASS | flag cloudreach_winds_restored (any) set after 0 frames |
| 59 | 1 | wait_flag — after rejoin the guest still reads realm_heart_cloudreach_earned | PASS | PASS | flag realm_heart_cloudreach_earned (any) set after 0 frames |
| 60 | 1 | wait_flag — after rejoin the guest still reads realm_key_stormwood | PASS | PASS | flag realm_key_stormwood (any) set after 0 frames |
| 61 | 0 | veridian_fixture — SETUP (disclosed): host journals both peers as Veyra participants through the reward_grant the director pays a shared trainer win with (C3's own Veyra defeat is a story_flag fixture, not a live fight) | PASS | PASS | reward_grant to peers [1, 430476528]: ok=true code='' reason='' paid=[1, 430476528] |
| 62 | 0 | story_flag — SETUP (disclosed): the freeing as a world fact (the lever press itself is proven by smoke_cloudreach_solmane_offer_choice) | PASS | PASS | cloudreach:legendary_freed: ok=true pending=false code='' reason='' |
| 63 | 0 | wait_flag — both peers read cloudreach:legendary_freed from the host world | PASS | PASS | flag cloudreach:legendary_freed (any) set after 0 frames |
| 63 | 1 | wait_flag — both peers read cloudreach:legendary_freed from the host world | PASS | PASS | flag cloudreach:legendary_freed (any) set after 9 frames |
| 64 | 0 | teleport — SETUP: host stands in the tether chamber | PASS | PASS | trainer stands at (99.00, 1160.15, 5471.00) |
| 65 | 1 | teleport — SETUP: guest stands in the tether chamber | PASS | PASS | trainer stands at (104.00, 1160.15, 5471.00) |
| 66 | 0 | wait | PASS | PASS | waited 240 physics frames |
| 66 | 1 | wait | PASS | PASS | waited 240 physics frames |
| 67 | 0 | veridian_answer — HOST refuses its own offer: already at capacity (four granted companions plus the fly_setup galecrest fifth), and an accept without room needs a release ceremony this card does not model (owner ruling #356 5858140459: offered, not forced) | PASS | PASS | refuse_offer() -> true; stage now 'ceremony' |
| 68 | 1 | veridian_answer — GUEST refuses its own offer: also at capacity (four granted companions plus the fly_setup galecrest fifth) | PASS | PASS | refuse_offer() -> true; stage now 'ceremony' |
| 69 | 0 | wait_flag — host's world receipt: refused | PASS | PASS | flag cloudreach:legendary_resolution:refused:character-d2506ecc5addabed4ff6199524c50a25 (any) set after 0 frames |
| 69 | 1 | wait_flag — host's world receipt: refused | PASS | PASS | flag cloudreach:legendary_resolution:refused:character-d2506ecc5addabed4ff6199524c50a25 (any) set after 0 frames |
| 70 | 0 | wait_flag — guest's world receipt: refused | PASS | PASS | flag cloudreach:legendary_resolution:refused:character-b9b186e976e93f4d69e6eb7821e9ad50 (any) set after 0 frames |
| 70 | 1 | wait_flag — guest's world receipt: refused | PASS | PASS | flag cloudreach:legendary_resolution:refused:character-b9b186e976e93f4d69e6eb7821e9ad50 (any) set after 0 frames |
| 71 | 0 | assert — host still exactly five: refusing left the belt as it was | PASS | PASS | party size 5 (wanted 5) |
| 72 | 0 | party_uids — host's five are unchanged (no accidental release) | PASS | PASS | 5 owned: ["creature-e29fe4d27a3877902be9484b5be81fd7", "creature-fbc1ede0a94b92d85c305afe54ddc817", "creature-1f075afac4b7c211770382f4ead389e5", "creature-9a5dbc485c3a4068d2a149f69d64560f", "creature-b034bd045829fd4fbbf65f161115d95a"]; exactly the 'uids0' list |
| 73 | 1 | assert — guest still exactly five: refusing left the belt as it was | PASS | PASS | party size 5 (wanted 5) |
| 74 | 1 | party_uids — guest's five are unchanged (no accidental release) | PASS | PASS | 5 owned: ["creature-ed72be26c56edb2c2d6457bee308cf99", "creature-43867f20c78112483b2eeb0c931c3b2a", "creature-c8193faad367e68a7cf62c3d98716843", "creature-25c02928b94c2ac88d5df5f067f7c349", "creature-48ad85e12a4ff72c6520e1d549936fbd"]; exactly the 'uids1' list |
| 75 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-d2506ecc5addabed4ff6199524c50a25' on disk=true; copied 3 files to /tmp/claude-0/-home-user-Tetherbound/e2a7b766-819b-5513-9d61-d02cefeeb479/scratchpad/c3-sol-run2/peer-0/solmane_answered |
| 75 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-b9b186e976e93f4d69e6eb7821e9ad50' on disk=true; copied 1 files to /tmp/claude-0/-home-user-Tetherbound/e2a7b766-819b-5513-9d61-d02cefeeb479/scratchpad/c3-sol-run2/peer-1/solmane_answered |
| 76 | 0 | enter_realm — host crosses into Stormwood | PASS | PASS | crossed 'cloudreach' -> 'stormwood' after 552 observed physics frames / 34670 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 77 | 1 | enter_realm — guest crosses into Stormwood | PASS | PASS | crossed 'cloudreach' -> 'stormwood' after 555 observed physics frames / 34824 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 78 | 0 | wait_context | PASS | PASS | input_context=world after 0 frames |
| 78 | 1 | wait_context | PASS | PASS | input_context=world after 0 frames |
| 79 | 0 | hashes_agree | PASS | PASS | every peer's heartbeat carries world-state hash 4201363108; remembered as 'pre_restart' |
| 80 | 0 | hashes_agree — NEGATIVE CONTROL: the hash check can fail (Stormwood is not the Cloudreach arrival world) | FAIL | FAIL | every peer's heartbeat carries world-state hash 4201363108; 'cloudreach_arrival' was 1330741496 -> DIFFERENT |
| 81 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-d2506ecc5addabed4ff6199524c50a25' on disk=true; copied 3 files to /tmp/claude-0/-home-user-Tetherbound/e2a7b766-819b-5513-9d61-d02cefeeb479/scratchpad/c3-sol-run2/peer-0/pre_restart |
| 81 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-b9b186e976e93f4d69e6eb7821e9ad50' on disk=true; copied 1 files to /tmp/claude-0/-home-user-Tetherbound/e2a7b766-819b-5513-9d61-d02cefeeb479/scratchpad/c3-sol-run2/peer-1/pre_restart |
| 82 | 0 | restart_peer — RESTART: the host process ends; a fresh one boots the title on the same user data | PASS | PASS | peer 0 process 18617 ended (graceful quit=true); fresh process 19751 on the same home booted 'title' and said hello |
| 83 | 0 | title_load — RELOAD: the restarted host presses Load on its autosave, which hosts | PASS | PASS | title Load slot 0 -> /root/Stormwood (realm 'stormwood'), hosting on port 34521 after 18 frames |
| 84 | 1 | production_join — REJOIN the restarted host as the same character | PASS | PASS | title returning entry built 'Stormwood' first, then JoinDriver joined 127.0.0.1:34521 as peer 1324806727 after 48 frames |
| 85 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 85 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 86 | 1 | enter_realm | any | FAIL | Game.enter_realm('stormwood') refused from 'stormwood' (can_enter=true) |
| 87 | 0 | wait_context | any | PASS | input_context=world after 0 frames |
| 87 | 1 | wait_context | any | PASS | input_context=world after 0 frames |
| 88 | 0 | hashes_agree — AFTER RESTART + REJOIN: world hashes agree and equal the pre-restart world | PASS | PASS | every peer's heartbeat carries world-state hash 4201363108; 'pre_restart' was 4201363108 -> EQUAL |
| 89 | 0 | party_uids — host's five owned UIDs after the restart (the remember store is process memory; compared against the pre-restart row by the card) | PASS | PASS | 5 owned: ["creature-e29fe4d27a3877902be9484b5be81fd7", "creature-fbc1ede0a94b92d85c305afe54ddc817", "creature-1f075afac4b7c211770382f4ead389e5", "creature-9a5dbc485c3a4068d2a149f69d64560f", "creature-b034bd045829fd4fbbf65f161115d95a"]; kept as 'uids0_after_restart' |
| 90 | 0 | assert — exactly five: no sixth, no legendary added | PASS | PASS | party size 5 (wanted 5) |
| 91 | 0 | wait_flag — persisted after reload: captain_veyra_defeated | PASS | PASS | flag captain_veyra_defeated (any) set after 0 frames |
| 92 | 0 | wait_flag — persisted after reload: sky_shrine_reached | PASS | PASS | flag sky_shrine_reached (any) set after 0 frames |
| 93 | 0 | wait_flag — persisted after reload: cloudreach_winds_restored | PASS | PASS | flag cloudreach_winds_restored (any) set after 0 frames |
| 94 | 0 | wait_flag — persisted after reload: realm_heart_cloudreach_earned | PASS | PASS | flag realm_heart_cloudreach_earned (any) set after 0 frames |
| 95 | 0 | wait_flag — persisted after reload: realm_key_stormwood | PASS | PASS | flag realm_key_stormwood (any) set after 0 frames |
| 96 | 1 | party_uids — same five owned UIDs after the realm crossing, restart and rejoin | PASS | PASS | 5 owned: ["creature-ed72be26c56edb2c2d6457bee308cf99", "creature-43867f20c78112483b2eeb0c931c3b2a", "creature-c8193faad367e68a7cf62c3d98716843", "creature-25c02928b94c2ac88d5df5f067f7c349", "creature-48ad85e12a4ff72c6520e1d549936fbd"]; exactly the 'uids1' list |
| 97 | 1 | assert — exactly five: no sixth, no legendary added | PASS | PASS | party size 5 (wanted 5) |
| 98 | 1 | wait_flag — persisted after reload: captain_veyra_defeated | PASS | PASS | flag captain_veyra_defeated (any) set after 0 frames |
| 99 | 1 | wait_flag — persisted after reload: sky_shrine_reached | PASS | PASS | flag sky_shrine_reached (any) set after 0 frames |
| 100 | 1 | wait_flag — persisted after reload: cloudreach_winds_restored | PASS | PASS | flag cloudreach_winds_restored (any) set after 0 frames |
| 101 | 1 | wait_flag — persisted after reload: realm_heart_cloudreach_earned | PASS | PASS | flag realm_heart_cloudreach_earned (any) set after 0 frames |
| 102 | 1 | wait_flag — persisted after reload: realm_key_stormwood | PASS | PASS | flag realm_key_stormwood (any) set after 0 frames |
| 103 | 0 | wait_flag — host's refused receipt persisted through the restart | PASS | PASS | flag cloudreach:legendary_resolution:refused:character-d2506ecc5addabed4ff6199524c50a25 (any) set after 0 frames |
| 103 | 1 | wait_flag — host's refused receipt persisted through the restart | PASS | PASS | flag cloudreach:legendary_resolution:refused:character-d2506ecc5addabed4ff6199524c50a25 (any) set after 0 frames |
| 104 | 0 | wait_flag — guest's refused receipt persisted through the restart | PASS | PASS | flag cloudreach:legendary_resolution:refused:character-b9b186e976e93f4d69e6eb7821e9ad50 (any) set after 0 frames |
| 104 | 1 | wait_flag — guest's refused receipt persisted through the restart | PASS | PASS | flag cloudreach:legendary_resolution:refused:character-b9b186e976e93f4d69e6eb7821e9ad50 (any) set after 0 frames |
| 105 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-d2506ecc5addabed4ff6199524c50a25' on disk=true; copied 3 files to /tmp/claude-0/-home-user-Tetherbound/e2a7b766-819b-5513-9d61-d02cefeeb479/scratchpad/c3-sol-run2/peer-0/after |
| 105 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-b9b186e976e93f4d69e6eb7821e9ad50' on disk=true; copied 1 files to /tmp/claude-0/-home-user-Tetherbound/e2a7b766-819b-5513-9d61-d02cefeeb479/scratchpad/c3-sol-run2/peer-1/after |
| 106 | 0 | check_saved — the host's saved world keeps Veyra, the shrine, restored winds, the heart and the key | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under after/worlds |
| 107 | 0 | check_saved — NEGATIVE CONTROL: the saved-world check reads real content (a 'lacks Veyra' claim fails) | FAIL | FAIL | missing []; unexpectedly present ["captain_veyra_defeated"]; read ["slot-0/world.json"] under after/worlds |
| 108 | 0 | check_saved — host's saved character holds no Solmane (refused: already at capacity) | PASS | PASS | missing []; unexpectedly present []; read ["character-d2506ecc5addabed4ff6199524c50a25/character.json"] under after/characters |
| 109 | 1 | check_saved — guest's saved character holds no Solmane (refused: already at capacity) | PASS | PASS | missing []; unexpectedly present []; read ["character-b9b186e976e93f4d69e6eb7821e9ad50/character.json"] under after/characters |
| 110 | 0 | check_saved — NEGATIVE CONTROL: the saved-character check reads real content (a 'contains Solmane' claim fails since the host refused) | FAIL | FAIL | missing ["solmane"]; unexpectedly present []; read ["character-d2506ecc5addabed4ff6199524c50a25/character.json"] under after/characters |

## Captured files

- `peer-0/after/characters/character-d2506ecc5addabed4ff6199524c50a25/character.json`
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/worlds/slot-0/world.json`
- `peer-0/before/characters/character-d2506ecc5addabed4ff6199524c50a25/character.json`
- `peer-0/before/saves/slot_0.json`
- `peer-0/before/worlds/slot-0/world.json`
- `peer-0/pre_restart/characters/character-d2506ecc5addabed4ff6199524c50a25/character.json`
- `peer-0/pre_restart/saves/slot_0.json`
- `peer-0/pre_restart/worlds/slot-0/world.json`
- `peer-0/solmane_answered/characters/character-d2506ecc5addabed4ff6199524c50a25/character.json`
- `peer-0/solmane_answered/saves/slot_0.json`
- `peer-0/solmane_answered/worlds/slot-0/world.json`
- `peer-1/after/characters/character-b9b186e976e93f4d69e6eb7821e9ad50/character.json`
- `peer-1/before/characters/character-b9b186e976e93f4d69e6eb7821e9ad50/character.json`
- `peer-1/pre_restart/characters/character-b9b186e976e93f4d69e6eb7821e9ad50/character.json`
- `peer-1/solmane_answered/characters/character-b9b186e976e93f4d69e6eb7821e9ad50/character.json`
