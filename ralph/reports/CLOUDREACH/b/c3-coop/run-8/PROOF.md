# Two-peer proof: C3: Cloudreach co-op and aftermath -- host and guest cross flight and realm boundaries, drop/rejoin and reload without duplicating relic/key or losing rider/party identity

**Verdict: PASS** (exit 0)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/c3_cloudreach_coop_aftermath.json`  
Run: `net-20260927T161115Z-20449`  
Rendered: no (headless)

ACCEPTANCE card C3. Fixtures (disclosed): story_flag world flags stand in for the completed Cloudreach chapter (the earned play is card C1); heart_earn submits the Wings heart through the ledger; party_grant gives each peer four L30 creatures and fly_setup adds an owned galecrest carrier as the fifth (the mentor loaner ends at cloudreach_chapter_complete). Launch, landing, drop, rejoin, realm crossings, host restart/title Load, saves and hashes are the game's own code. The heart and key are world flags (entitlements), so 'not duplicated' is checked as: each read once from the host world, unchanged hash across restart+rejoin, and the saved world keeps them. Loopback ENet: local evidence, not internet/Steam acceptance.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | boot — each peer boots its own fresh Meadows world | PASS | PASS | booted world (240 settle frames) |
| 1 | 1 | boot — each peer boots its own fresh Meadows world | PASS | PASS | booted world (240 settle frames) |
| 2 | 0 | host | PASS | PASS | hosting udp/35521 as peer 1 |
| 3 | 1 | join | PASS | PASS | joined 127.0.0.1:35521 as peer 1635428121 after 16 frames; snapshot applied; 2 peer(s) in registry |
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
| 28 | 0 | enter_realm — host crosses into Cloudreach | PASS | PASS | crossed 'meadows' -> 'cloudreach' after 791 observed physics frames / 73656 ms (budget 6000 physics frames); current scene is /root/CloudreachCliffs |
| 29 | 1 | enter_realm — guest crosses into Cloudreach | PASS | PASS | crossed 'meadows' -> 'cloudreach' after 931 observed physics frames / 64276 ms (budget 6000 physics frames); current scene is /root/CloudreachCliffs |
| 30 | 0 | teleport — SETUP (disclosed): stand on the Sky Shrine landing pad (open sky, Fly-only landmark) | PASS | PASS | trainer stands at (1110.00, 1050.00, 2940.00) |
| 31 | 0 | assert — standing on the shrine pad before the carrier setup | PASS | PASS | on_floor=true flying=false carried=false at (1110.0, 1050.0, 2940.0) |
| 32 | 0 | fly_setup — SETUP (disclosed): an owned galecrest carrier as the fifth (the loaner ends at chapter completion; galecrest is catchable in Meadows band 1) | PASS | PASS | SETUP: fly_traversal_unlocked set, galecrest active, anchor=(1110.0, 1050.0, 2940.0), screen: no SequenceDirector here; nothing holding the screen, launch site: already clear where it stood (locomotion=true carried=false on_floor=true) |
| 33 | 0 | assert — the launch search kept the trainer on the shrine pad | PASS | PASS | 0.00 m from (1110.0, 2940.0), wanted within 25.00 |
| 34 | 0 | party_uids — remember this peer's five owned UIDs | PASS | PASS | 5 owned: ["creature-0ec8b4213496e49fe7ea915c4c6dfc9d", "creature-d3c482888d7773c6a8be7d22d8232f42", "creature-6f7670b9d513ada1ba238d19d3e6a077", "creature-434bd4884917a83a3d54e2295848e562", "creature-14e957237840c4d327bae0c0a41eb14c"]; kept as 'uids0' |
| 35 | 0 | assert | PASS | PASS | party size 5 (wanted 5) |
| 36 | 1 | teleport — SETUP (disclosed): stand on the Sky Shrine landing pad (open sky, Fly-only landmark) | PASS | PASS | trainer stands at (1106.00, 1050.00, 2944.00) |
| 37 | 1 | assert — standing on the shrine pad before the carrier setup | PASS | PASS | on_floor=true flying=false carried=false at (1106.0, 1050.001, 2944.0) |
| 38 | 1 | fly_setup — SETUP (disclosed): an owned galecrest carrier as the fifth (the loaner ends at chapter completion; galecrest is catchable in Meadows band 1) | PASS | PASS | SETUP: fly_traversal_unlocked set, galecrest active, anchor=(1106.0, 1050.08, 2944.0), screen: no SequenceDirector here; nothing holding the screen, launch site: already clear where it stood (locomotion=true carried=false on_floor=true) |
| 39 | 1 | assert — the launch search kept the trainer on the shrine pad | PASS | PASS | 0.00 m from (1106.0, 2944.0), wanted within 25.00 |
| 40 | 1 | party_uids — remember this peer's five owned UIDs | PASS | PASS | 5 owned: ["creature-066d71633ed4786a6c7d69d2bc31fe36", "creature-b2c5d2aeb45310cfd3a83d3b94854f23", "creature-bc1b463c2c215837dfe4530090a52044", "creature-8a73a07d02faa89626e4ccdf47220645", "creature-728479459ee7752a3cbbd94fe2334c88"]; kept as 'uids1' |
| 41 | 1 | assert | PASS | PASS | party size 5 (wanted 5) |
| 42 | 0 | hashes_agree | PASS | PASS | every peer's heartbeat carries world-state hash 1330741496; remembered as 'cloudreach_arrival' |
| 43 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f725a5642b0a37cc545f7fb4a26c058a' on disk=true; copied 3 files to /home/user/Tetherbound/ralph/reports/CLOUDREACH/b/c3-coop/latest-run/peer-0/before |
| 43 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-52092a1bbd1a71bf450c1d6a4beda3ca' on disk=true; copied 1 files to /home/user/Tetherbound/ralph/reports/CLOUDREACH/b/c3-coop/latest-run/peer-1/before |
| 44 | 0 | fly_launch — host launches Fly by double jump (production input) | PASS | PASS | flying (glide) at y=1052.24 on attempt 0 |
| 45 | 0 | fly_land — host holds descend to a floor landing | PASS | PASS | landed at (1110.00, 1050.00, 2940.00); anchor report {"accepts":0,"anchor":[1110.0,1049.99914550781,2940.0],"host_granted":false,"host_validated":false,"last_code":"","last_denial":"","pending":false,"proposals":0,"realm":"cloudreach","refusals":0} |
| 46 | 0 | assert | PASS | PASS | on_floor=true flying=false carried=false at (1110.0, 1049.999, 2940.0) |
| 47 | 1 | fly_launch — guest launches Fly by double jump | PASS | PASS | flying (glide) at y=1052.24 on attempt 0 |
| 48 | 1 | drop_link — MID-FLIGHT DROP: the guest's link dies while flying | PASS | PASS | transport closed without a Session.leave() |
| 49 | 0 | expect_peers | PASS | PASS | registry reports 1 peer(s) after 0 frames (0.0 s) |
| 50 | 1 | production_join — REJOIN from the title as the same character | PASS | PASS | title returning entry built 'CloudreachCliffs' first, then JoinDriver joined 127.0.0.1:35521 as peer 360479383 after 37 frames |
| 51 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 51 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 52 | 1 | enter_realm — guest back into Cloudreach (ANY: the rejoin may already stand there) | any | FAIL | Game.enter_realm('cloudreach') refused from 'cloudreach' (can_enter=true) |
| 53 | 0 | wait_context | any | PASS | input_context=world after 0 frames |
| 53 | 1 | wait_context | any | PASS | input_context=world after 0 frames |
| 54 | 1 | assert — rider sane after the mid-flight drop: grounded, not flying, not carried | PASS | PASS | on_floor=true flying=false carried=false at (1106.0, 1051.3, 2944.0) |
| 55 | 1 | party_uids — the guest's five are the same owned creatures after the drop | PASS | PASS | 5 owned: ["creature-066d71633ed4786a6c7d69d2bc31fe36", "creature-b2c5d2aeb45310cfd3a83d3b94854f23", "creature-bc1b463c2c215837dfe4530090a52044", "creature-8a73a07d02faa89626e4ccdf47220645", "creature-728479459ee7752a3cbbd94fe2334c88"]; exactly the 'uids1' list |
| 56 | 1 | wait_flag — after rejoin the guest still reads captain_veyra_defeated | PASS | PASS | flag captain_veyra_defeated (any) set after 0 frames |
| 57 | 1 | wait_flag — after rejoin the guest still reads sky_shrine_reached | PASS | PASS | flag sky_shrine_reached (any) set after 0 frames |
| 58 | 1 | wait_flag — after rejoin the guest still reads cloudreach_winds_restored | PASS | PASS | flag cloudreach_winds_restored (any) set after 0 frames |
| 59 | 1 | wait_flag — after rejoin the guest still reads realm_heart_cloudreach_earned | PASS | PASS | flag realm_heart_cloudreach_earned (any) set after 0 frames |
| 60 | 1 | wait_flag — after rejoin the guest still reads realm_key_stormwood | PASS | PASS | flag realm_key_stormwood (any) set after 0 frames |
| 61 | 0 | enter_realm — host crosses into Stormwood | PASS | PASS | crossed 'cloudreach' -> 'stormwood' after 549 observed physics frames / 37905 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 62 | 1 | enter_realm — guest crosses into Stormwood | PASS | PASS | crossed 'cloudreach' -> 'stormwood' after 555 observed physics frames / 35839 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 63 | 0 | wait_context | PASS | PASS | input_context=world after 0 frames |
| 63 | 1 | wait_context | PASS | PASS | input_context=world after 0 frames |
| 64 | 0 | hashes_agree | PASS | PASS | every peer's heartbeat carries world-state hash 3234141098; remembered as 'pre_restart' |
| 65 | 0 | hashes_agree — NEGATIVE CONTROL: the hash check can fail (Stormwood is not the Cloudreach arrival world) | FAIL | FAIL | every peer's heartbeat carries world-state hash 3234141098; 'cloudreach_arrival' was 1330741496 -> DIFFERENT |
| 66 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f725a5642b0a37cc545f7fb4a26c058a' on disk=true; copied 3 files to /home/user/Tetherbound/ralph/reports/CLOUDREACH/b/c3-coop/latest-run/peer-0/pre_restart |
| 66 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-52092a1bbd1a71bf450c1d6a4beda3ca' on disk=true; copied 1 files to /home/user/Tetherbound/ralph/reports/CLOUDREACH/b/c3-coop/latest-run/peer-1/pre_restart |
| 67 | 0 | restart_peer — RESTART: the host process ends; a fresh one boots the title on the same user data | PASS | PASS | peer 0 process 20564 ended (graceful quit=true); fresh process 22195 on the same home booted 'title' and said hello |
| 68 | 0 | title_load — RELOAD: the restarted host presses Load on its autosave, which hosts | PASS | PASS | title Load slot 0 -> /root/Stormwood (realm 'stormwood'), hosting on port 35521 after 18 frames |
| 69 | 1 | production_join — REJOIN the restarted host as the same character | PASS | PASS | title returning entry built 'Stormwood' first, then JoinDriver joined 127.0.0.1:35521 as peer 717905828 after 49 frames |
| 70 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 70 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 71 | 1 | enter_realm | any | FAIL | Game.enter_realm('stormwood') refused from 'stormwood' (can_enter=true) |
| 72 | 0 | wait_context | any | PASS | input_context=world after 0 frames |
| 72 | 1 | wait_context | any | PASS | input_context=world after 0 frames |
| 73 | 0 | hashes_agree — AFTER RESTART + REJOIN: world hashes agree and equal the pre-restart world | PASS | PASS | every peer's heartbeat carries world-state hash 3234141098; 'pre_restart' was 3234141098 -> EQUAL |
| 74 | 0 | party_uids — host's five owned UIDs after the restart (the remember store is process memory; compared against the pre-restart row by the card) | PASS | PASS | 5 owned: ["creature-0ec8b4213496e49fe7ea915c4c6dfc9d", "creature-d3c482888d7773c6a8be7d22d8232f42", "creature-6f7670b9d513ada1ba238d19d3e6a077", "creature-434bd4884917a83a3d54e2295848e562", "creature-14e957237840c4d327bae0c0a41eb14c"]; kept as 'uids0_after_restart' |
| 75 | 0 | assert — exactly five: no sixth, no legendary added | PASS | PASS | party size 5 (wanted 5) |
| 76 | 0 | wait_flag — persisted after reload: captain_veyra_defeated | PASS | PASS | flag captain_veyra_defeated (any) set after 0 frames |
| 77 | 0 | wait_flag — persisted after reload: sky_shrine_reached | PASS | PASS | flag sky_shrine_reached (any) set after 0 frames |
| 78 | 0 | wait_flag — persisted after reload: cloudreach_winds_restored | PASS | PASS | flag cloudreach_winds_restored (any) set after 0 frames |
| 79 | 0 | wait_flag — persisted after reload: realm_heart_cloudreach_earned | PASS | PASS | flag realm_heart_cloudreach_earned (any) set after 0 frames |
| 80 | 0 | wait_flag — persisted after reload: realm_key_stormwood | PASS | PASS | flag realm_key_stormwood (any) set after 0 frames |
| 81 | 1 | party_uids — same five owned UIDs after the realm crossing, restart and rejoin | PASS | PASS | 5 owned: ["creature-066d71633ed4786a6c7d69d2bc31fe36", "creature-b2c5d2aeb45310cfd3a83d3b94854f23", "creature-bc1b463c2c215837dfe4530090a52044", "creature-8a73a07d02faa89626e4ccdf47220645", "creature-728479459ee7752a3cbbd94fe2334c88"]; exactly the 'uids1' list |
| 82 | 1 | assert — exactly five: no sixth, no legendary added | PASS | PASS | party size 5 (wanted 5) |
| 83 | 1 | wait_flag — persisted after reload: captain_veyra_defeated | PASS | PASS | flag captain_veyra_defeated (any) set after 0 frames |
| 84 | 1 | wait_flag — persisted after reload: sky_shrine_reached | PASS | PASS | flag sky_shrine_reached (any) set after 0 frames |
| 85 | 1 | wait_flag — persisted after reload: cloudreach_winds_restored | PASS | PASS | flag cloudreach_winds_restored (any) set after 0 frames |
| 86 | 1 | wait_flag — persisted after reload: realm_heart_cloudreach_earned | PASS | PASS | flag realm_heart_cloudreach_earned (any) set after 0 frames |
| 87 | 1 | wait_flag — persisted after reload: realm_key_stormwood | PASS | PASS | flag realm_key_stormwood (any) set after 0 frames |
| 88 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f725a5642b0a37cc545f7fb4a26c058a' on disk=true; copied 3 files to /home/user/Tetherbound/ralph/reports/CLOUDREACH/b/c3-coop/latest-run/peer-0/after |
| 88 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-52092a1bbd1a71bf450c1d6a4beda3ca' on disk=true; copied 1 files to /home/user/Tetherbound/ralph/reports/CLOUDREACH/b/c3-coop/latest-run/peer-1/after |
| 89 | 0 | check_saved — the host's saved world keeps Veyra, the shrine, restored winds, the heart and the key | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under after/worlds |
| 90 | 0 | check_saved — NEGATIVE CONTROL: the saved-world check reads real content (a 'lacks Veyra' claim fails) | FAIL | FAIL | missing []; unexpectedly present ["captain_veyra_defeated"]; read ["slot-0/world.json"] under after/worlds |
| 91 | 0 | check_saved — no legendary in this character's saved party | PASS | PASS | missing []; unexpectedly present []; read ["character-f725a5642b0a37cc545f7fb4a26c058a/character.json"] under after/characters |
| 92 | 1 | check_saved — no legendary in this character's saved party | PASS | PASS | missing []; unexpectedly present []; read ["character-52092a1bbd1a71bf450c1d6a4beda3ca/character.json"] under after/characters |

## Captured files

- `peer-0/after/characters/character-f725a5642b0a37cc545f7fb4a26c058a/character.json`
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/worlds/slot-0/world.json`
- `peer-0/before/characters/character-f725a5642b0a37cc545f7fb4a26c058a/character.json`
- `peer-0/before/saves/slot_0.json`
- `peer-0/before/worlds/slot-0/world.json`
- `peer-0/pre_restart/characters/character-f725a5642b0a37cc545f7fb4a26c058a/character.json`
- `peer-0/pre_restart/saves/slot_0.json`
- `peer-0/pre_restart/worlds/slot-0/world.json`
- `peer-1/after/characters/character-52092a1bbd1a71bf450c1d6a4beda3ca/character.json`
- `peer-1/before/characters/character-52092a1bbd1a71bf450c1d6a4beda3ca/character.json`
- `peer-1/pre_restart/characters/character-52092a1bbd1a71bf450c1d6a4beda3ca/character.json`
