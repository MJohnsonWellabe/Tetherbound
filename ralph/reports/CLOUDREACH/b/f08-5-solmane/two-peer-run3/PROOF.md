# Two-peer proof: F08#5: Solmane, two peers -- each Veyra participant answers their own offer (host accepts with space, guest refuses at five), through disconnect/rejoin and a host restart, with no duplicate

**Verdict: PASS** (exit 0)

Scenario: `/tmp/claude-0/-home-user-Tetherbound/e2a7b766-819b-5513-9d61-d02cefeeb479/scratchpad/sol/tools/net/proof_scenarios/f08_5_solmane_two_peer.json`  
Run: `net-20260927T210703Z-11459`  
Rendered: no (headless)

Owner ruling 2026-09-27 (#356 5858140459): Solmane works exactly like the Meadows Veridian. Reuses stronghold_climax.gd (CloudreachSolmaneClimax). Fixtures (disclosed): story_flag world flags for the completed chapter through Veyra's defeat and the relays; veridian_fixture journals both peers as Veyra participants (the director's own reward_grant); the freeing is set as a world fact (the lever press itself is proven by smoke_cloudreach_solmane_offer_choice); party_grant fills the belts; teleports stand each trainer in the tether chamber; veridian_answer calls the climax's public accept_offer/refuse_offer (the prompts' own activated handlers). Loopback ENet.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | boot — each peer boots its own fresh Meadows world | PASS | PASS | booted world (240 settle frames) |
| 1 | 1 | boot — each peer boots its own fresh Meadows world | PASS | PASS | booted world (240 settle frames) |
| 2 | 0 | host | PASS | PASS | hosting udp/29421 as peer 1 |
| 3 | 1 | join | PASS | PASS | joined 127.0.0.1:29421 as peer 410414926 after 16 frames; snapshot applied; 2 peer(s) in registry |
| 4 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 4 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 5 | 0 | story_flag — SETUP (disclosed): host world holds realm_key_cloudreach (the earned play is card C1) | PASS | PASS | realm_key_cloudreach: ok=true pending=false code='' reason='' |
| 6 | 0 | story_flag — SETUP (disclosed): host world holds fly_traversal_unlocked (the earned play is card C1) | PASS | PASS | fly_traversal_unlocked: ok=true pending=false code='' reason='' |
| 7 | 0 | story_flag — SETUP (disclosed): host world holds cloudreach_upper_route_unlocked (the earned play is card C1) | PASS | PASS | cloudreach_upper_route_unlocked: ok=true pending=false code='' reason='' |
| 8 | 0 | story_flag — SETUP (disclosed): host world holds cloudreach_act_ii_complete (the earned play is card C1) | PASS | PASS | cloudreach_act_ii_complete: ok=true pending=false code='' reason='' |
| 9 | 0 | story_flag — SETUP (disclosed): host world holds captain_veyra_defeated (the earned play is card C1) | PASS | PASS | captain_veyra_defeated: ok=true pending=false code='' reason='' |
| 10 | 0 | story_flag — SETUP (disclosed): host world holds storm_anchor_network_disabled (the earned play is card C1) | PASS | PASS | storm_anchor_network_disabled: ok=true pending=false code='' reason='' |
| 11 | 0 | story_flag — SETUP (disclosed): host world holds cloudreach_winds_restored (the earned play is card C1) | PASS | PASS | cloudreach_winds_restored: ok=true pending=false code='' reason='' |
| 12 | 0 | party_grant — SETUP: host party_grant bramblebun (four: room on the belt) | PASS | PASS | 'bramblebun' at level 30 joined the party (1 member(s)) |
| 13 | 0 | party_grant — SETUP: host party_grant terrapup (four: room on the belt) | PASS | PASS | 'terrapup' at level 30 joined the party (2 member(s)) |
| 14 | 0 | party_grant — SETUP: host party_grant mudsnout (four: room on the belt) | PASS | PASS | 'mudsnout' at level 30 joined the party (3 member(s)) |
| 15 | 0 | party_grant — SETUP: host party_grant brooktail (four: room on the belt) | PASS | PASS | 'brooktail' at level 30 joined the party (4 member(s)) |
| 16 | 1 | party_grant — SETUP: guest party_grant bramblebun (five: at capacity) | PASS | PASS | 'bramblebun' at level 30 joined the party (1 member(s)) |
| 17 | 1 | party_grant — SETUP: guest party_grant terrapup (five: at capacity) | PASS | PASS | 'terrapup' at level 30 joined the party (2 member(s)) |
| 18 | 1 | party_grant — SETUP: guest party_grant mudsnout (five: at capacity) | PASS | PASS | 'mudsnout' at level 30 joined the party (3 member(s)) |
| 19 | 1 | party_grant — SETUP: guest party_grant brooktail (five: at capacity) | PASS | PASS | 'brooktail' at level 30 joined the party (4 member(s)) |
| 20 | 1 | party_grant — SETUP: guest party_grant ripplet (five: at capacity) | PASS | PASS | 'ripplet' at level 30 joined the party (5 member(s)) |
| 21 | 0 | enter_realm | PASS | PASS | crossed 'meadows' -> 'cloudreach' after 770 observed physics frames / 65687 ms (budget 6000 physics frames); current scene is /root/CloudreachCliffs |
| 22 | 1 | enter_realm | PASS | PASS | crossed 'meadows' -> 'cloudreach' after 797 observed physics frames / 57720 ms (budget 6000 physics frames); current scene is /root/CloudreachCliffs |
| 23 | 0 | veridian_fixture — SETUP (disclosed): host journals both peers as Veyra participants through the reward_grant the director pays a shared trainer win with | PASS | PASS | reward_grant to peers [1, 410414926]: ok=true code='' reason='' paid=[1, 410414926] |
| 24 | 0 | story_flag — SETUP (disclosed): the freeing as a world fact (the lever press is proven by smoke_cloudreach_solmane_offer_choice) | PASS | PASS | cloudreach:legendary_freed: ok=true pending=false code='' reason='' |
| 25 | 0 | wait_flag | PASS | PASS | flag cloudreach:legendary_freed (any) set after 0 frames |
| 25 | 1 | wait_flag | PASS | PASS | flag cloudreach:legendary_freed (any) set after 9 frames |
| 26 | 0 | party_uids | PASS | PASS | 4 owned: ["creature-c57607e0aa092dd200698a3e86fcc900", "creature-f622a6ae0c36ab5048a8b609a2358aa6", "creature-7e7eb40e669c3e8740ff93de83ff1121", "creature-b238706f592e795c8519bff21de8177e"]; kept as 'uids0' |
| 27 | 1 | party_uids | PASS | PASS | 5 owned: ["creature-d0ae7a62eba752f6864ffc9aeb9f9fa4", "creature-f1f65791e9b815767d781eab77be182e", "creature-63378ea3c4871029edf371e948a6c766", "creature-978b7cc372bf7629f5941681790e8c42", "creature-cf00883e4b9f5c64b7778c1b2623087b"]; kept as 'uids1' |
| 28 | 0 | teleport — SETUP: host stands in the tether chamber | PASS | PASS | trainer stands at (99.00, 1160.15, 5471.00) |
| 29 | 1 | teleport — SETUP: guest stands in the tether chamber | PASS | PASS | trainer stands at (104.00, 1160.15, 5471.00) |
| 30 | 0 | wait | PASS | PASS | waited 240 physics frames |
| 30 | 1 | wait | PASS | PASS | waited 240 physics frames |
| 31 | 0 | veridian_answer — HOST accepts its own offer (room on the belt) | PASS | PASS | accept_offer() -> true; stage now 'ceremony' |
| 32 | 1 | veridian_answer — GUEST refuses its own offer (at five) | PASS | PASS | refuse_offer() -> true; stage now 'ceremony' |
| 33 | 0 | wait_flag — host's world receipt: accepted | PASS | PASS | flag cloudreach:legendary_resolution:accepted:character-f3fae5ec5c937d53ad2eb69542d7bca6 (any) set after 0 frames |
| 33 | 1 | wait_flag — host's world receipt: accepted | PASS | PASS | flag cloudreach:legendary_resolution:accepted:character-f3fae5ec5c937d53ad2eb69542d7bca6 (any) set after 0 frames |
| 34 | 0 | wait_flag — guest's world receipt: refused | PASS | PASS | flag cloudreach:legendary_resolution:refused:character-497fd31c3a70d40dfc6f55d1e5927c63 (any) set after 0 frames |
| 34 | 1 | wait_flag — guest's world receipt: refused | PASS | PASS | flag cloudreach:legendary_resolution:refused:character-497fd31c3a70d40dfc6f55d1e5927c63 (any) set after 0 frames |
| 35 | 0 | assert — host kept Solmane: four + one | PASS | PASS | party size 5 (wanted 5) |
| 36 | 1 | assert — guest refused: still its own five | PASS | PASS | party size 5 (wanted 5) |
| 37 | 1 | party_uids — guest's five are unchanged (no accidental release) | PASS | PASS | 5 owned: ["creature-d0ae7a62eba752f6864ffc9aeb9f9fa4", "creature-f1f65791e9b815767d781eab77be182e", "creature-63378ea3c4871029edf371e948a6c766", "creature-978b7cc372bf7629f5941681790e8c42", "creature-cf00883e4b9f5c64b7778c1b2623087b"]; exactly the 'uids1' list |
| 38 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f3fae5ec5c937d53ad2eb69542d7bca6' on disk=true; copied 3 files to /tmp/claude-0/-home-user-Tetherbound/e2a7b766-819b-5513-9d61-d02cefeeb479/scratchpad/f08-5-run3/peer-0/answered |
| 38 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-497fd31c3a70d40dfc6f55d1e5927c63' on disk=true; copied 1 files to /tmp/claude-0/-home-user-Tetherbound/e2a7b766-819b-5513-9d61-d02cefeeb479/scratchpad/f08-5-run3/peer-1/answered |
| 39 | 1 | drop_link — DISCONNECT: the guest's link dies | PASS | PASS | transport closed without a Session.leave() |
| 40 | 0 | expect_peers | PASS | PASS | registry reports 1 peer(s) after 0 frames (0.0 s) |
| 41 | 1 | production_join — REJOIN as the same character | PASS | PASS | title returning entry built 'CloudreachCliffs' first, then JoinDriver joined 127.0.0.1:29421 as peer 374699559 after 34 frames |
| 42 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 42 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 43 | 1 | enter_realm | any | FAIL | Game.enter_realm('cloudreach') refused from 'cloudreach' (can_enter=true) |
| 44 | 1 | teleport | PASS | PASS | trainer stands at (104.00, 1160.15, 5471.00) |
| 45 | 1 | veridian_answer — NO SECOND OFFER: the guest's refusal holds after the rejoin | FAIL | FAIL | offer not answerable: stage 'done', panel open false (no dialogue box was open) |
| 46 | 1 | party_uids — guest's five unchanged after the rejoin | PASS | PASS | 5 owned: ["creature-d0ae7a62eba752f6864ffc9aeb9f9fa4", "creature-f1f65791e9b815767d781eab77be182e", "creature-63378ea3c4871029edf371e948a6c766", "creature-978b7cc372bf7629f5941681790e8c42", "creature-cf00883e4b9f5c64b7778c1b2623087b"]; exactly the 'uids1' list |
| 47 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f3fae5ec5c937d53ad2eb69542d7bca6' on disk=true; copied 3 files to /tmp/claude-0/-home-user-Tetherbound/e2a7b766-819b-5513-9d61-d02cefeeb479/scratchpad/f08-5-run3/peer-0/pre_restart |
| 47 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-497fd31c3a70d40dfc6f55d1e5927c63' on disk=true; copied 1 files to /tmp/claude-0/-home-user-Tetherbound/e2a7b766-819b-5513-9d61-d02cefeeb479/scratchpad/f08-5-run3/peer-1/pre_restart |
| 48 | 0 | restart_peer — RESTART the host process | PASS | PASS | peer 0 process 11547 ended (graceful quit=true); fresh process 12374 on the same home booted 'title' and said hello |
| 49 | 0 | title_load — RELOAD: the host presses Load, which hosts | PASS | PASS | title Load slot 0 -> /root/CloudreachCliffs (realm 'cloudreach'), hosting on port 29421 after 8 frames |
| 50 | 1 | production_join — REJOIN the restarted host | PASS | PASS | title returning entry built 'CloudreachCliffs' first, then JoinDriver joined 127.0.0.1:29421 as peer 471758754 after 46 frames |
| 51 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 51 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 52 | 1 | enter_realm | any | FAIL | Game.enter_realm('cloudreach') refused from 'cloudreach' (can_enter=true) |
| 53 | 0 | wait_flag — host receipt persisted through the restart | PASS | PASS | flag cloudreach:legendary_resolution:accepted:character-f3fae5ec5c937d53ad2eb69542d7bca6 (any) set after 0 frames |
| 53 | 1 | wait_flag — host receipt persisted through the restart | PASS | PASS | flag cloudreach:legendary_resolution:accepted:character-f3fae5ec5c937d53ad2eb69542d7bca6 (any) set after 0 frames |
| 54 | 0 | wait_flag — guest receipt persisted through the restart | PASS | PASS | flag cloudreach:legendary_resolution:refused:character-497fd31c3a70d40dfc6f55d1e5927c63 (any) set after 0 frames |
| 54 | 1 | wait_flag — guest receipt persisted through the restart | PASS | PASS | flag cloudreach:legendary_resolution:refused:character-497fd31c3a70d40dfc6f55d1e5927c63 (any) set after 0 frames |
| 55 | 0 | assert — host still holds exactly five, Solmane among them | PASS | PASS | party size 5 (wanted 5) |
| 56 | 0 | teleport | PASS | PASS | trainer stands at (99.00, 1160.15, 5471.00) |
| 57 | 0 | veridian_answer — NO SECOND OFFER: the host's acceptance holds after the reload (no duplicate) | FAIL | FAIL | offer not answerable: stage 'done', panel open false (no dialogue box was open) |
| 58 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f3fae5ec5c937d53ad2eb69542d7bca6' on disk=true; copied 3 files to /tmp/claude-0/-home-user-Tetherbound/e2a7b766-819b-5513-9d61-d02cefeeb479/scratchpad/f08-5-run3/peer-0/after |
| 58 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-497fd31c3a70d40dfc6f55d1e5927c63' on disk=true; copied 1 files to /tmp/claude-0/-home-user-Tetherbound/e2a7b766-819b-5513-9d61-d02cefeeb479/scratchpad/f08-5-run3/peer-1/after |
| 59 | 0 | check_saved — host's saved character holds its Solmane | PASS | PASS | missing []; unexpectedly present []; read ["character-f3fae5ec5c937d53ad2eb69542d7bca6/character.json"] under after/characters |
| 60 | 1 | check_saved — guest's saved character holds no Solmane | PASS | PASS | missing []; unexpectedly present []; read ["character-497fd31c3a70d40dfc6f55d1e5927c63/character.json"] under after/characters |
| 61 | 1 | check_saved — NEGATIVE CONTROL: the saved-character check reads real content | FAIL | FAIL | missing ["solmane"]; unexpectedly present []; read ["character-497fd31c3a70d40dfc6f55d1e5927c63/character.json"] under after/characters |

## Captured files

- `peer-0/after/characters/character-f3fae5ec5c937d53ad2eb69542d7bca6/character.json`
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/worlds/slot-0/world.json`
- `peer-0/answered/characters/character-f3fae5ec5c937d53ad2eb69542d7bca6/character.json`
- `peer-0/answered/saves/slot_0.json`
- `peer-0/answered/worlds/slot-0/world.json`
- `peer-0/pre_restart/characters/character-f3fae5ec5c937d53ad2eb69542d7bca6/character.json`
- `peer-0/pre_restart/saves/slot_0.json`
- `peer-0/pre_restart/worlds/slot-0/world.json`
- `peer-1/after/characters/character-497fd31c3a70d40dfc6f55d1e5927c63/character.json`
- `peer-1/answered/characters/character-497fd31c3a70d40dfc6f55d1e5927c63/character.json`
- `peer-1/pre_restart/characters/character-497fd31c3a70d40dfc6f55d1e5927c63/character.json`
