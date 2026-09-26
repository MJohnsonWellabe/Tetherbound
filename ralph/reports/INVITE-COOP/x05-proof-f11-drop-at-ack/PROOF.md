# Two-peer proof: F11: a guest's link dies at the Stormheart claim acknowledgement; no duplicated grant

**Verdict: PASS** (exit 0)

Scenario: `/home/user/x05-ledger/tools/net/proof_scenarios/f11_stormheart_drop_at_ack.json`  
Run: `net-20260926T061725Z-30566`  
Rendered: yes

ACCEPTANCE F11 'through disconnect ... without duplicated grants', the claim-acknowledgement window. Both players fought the Dynamo. The host says Yes. The guest walks up, opens its own offer and says Yes through the real dialogue. The guest's transport is closed from the dialogue's own `completed` signal, in the physics step that accepted the Yes and before that frame's network poll. The ending then records the receipt and saves the character locally (stormwood_ending.gd _finish_local_claim), and its `ending_settled` acknowledgement finds no connected peer. The host is shown to hold no receipt of the guest's answer. The guest rejoins from the title as the same character. The host settles the guest's answer from the resent claim and the guest's saved receipt, and the guest holds exactly one Stormheart: no second grant, nothing offered on a further press, nothing after both peers reload. Setup: the host's captured save with the Stormwood route open, and the Dynamo fight fixture only.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: a fresh trainer in the Meadows | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | host | PASS | PASS | hosting udp/35641 as peer 1 |
| 4 | 1 | join | PASS | PASS | joined 127.0.0.1:35641 as peer 115972000 after 16 frames; snapshot applied; 2 peer(s) in registry |
| 5 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 5 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 6 | 0 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 6 | 1 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 7 | 0 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 552 observed physics frames / 53896 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 8 | 1 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 510 observed physics frames / 34705 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 9 | 0 | probe downed — trainer vitals on arrival (health recorded, see the HUD note) | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":100.0,"hold_peer":0.0,"hold_s":0.0,"host_authority_attempts":[],"host_views":{"1":{"body_id":94375245940532.0,"position":[-300.0,32.271728515625,180.0],"realm":"stormwood","valid":true},"115972000":{"body_id":97522349686098.0,"position":[-300.0,32.271728515625,180.0],"realm":"stormwood","valid":true}},"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":94375245940532.0,"prompt":"[img=36x36]res://assets/ui/input_prompts/keyboard_e.png[/img]   Take Good Candy","viewer_id":94375245940532.0,"viewer_position":[-300.0,32.271728515625,180.0]},"interaction_winner":{"class":"Node3D","name":"Interactable"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_radius_m":2.5,"revive |
| 9 | 1 | probe downed — trainer vitals on arrival (health recorded, see the HUD note) | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":100.0,"hold_peer":0.0,"hold_s":0.0,"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":94524344942509.0,"prompt":"[img=36x36]res://assets/ui/input_prompts/keyboard_e.png[/img]   Take Good Candy","viewer_id":94524344942509.0,"viewer_position":[-300.0,32.271728515625,180.0]},"interaction_winner":{"class":"Node3D","name":"Interactable"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_radius_m":2.5,"revived":0.0,"satchel_nodes":0.0,"satchels":0.0,"stamina":100.0,"window_s":45.0} |
| 10 | 0 | screenshot | PASS | PASS | captured 960x540 -> ralph/reports/INVITE-COOP/x05-proof-f11-drop-at-ack/peer-0/01_both_in_stormwood.png |
| 10 | 1 | screenshot | PASS | PASS | captured 960x540 -> ralph/reports/INVITE-COOP/x05-proof-f11-drop-at-ack/peer-1/01_both_in_stormwood.png |
| 11 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to ralph/reports/INVITE-COOP/x05-proof-f11-drop-at-ack/peer-0/before |
| 11 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-75e5f1fd6462953e2a2663dd31fb1bb5' on disk=true; copied 1 files to ralph/reports/INVITE-COOP/x05-proof-f11-drop-at-ack/peer-1/before |
| 12 | 0 | stormheart_fixture — both fought the Dynamo (setup) | PASS | PASS | Dynamo contributors [1, 115972000]; committed ["stormwood:act_ii_complete", "stormwood:marrow_defeated"] |
| 13 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 13 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 927 frames |
| 14 | 0 | stormheart_answer — host says Yes | PASS + {"has_stormheart":true} | PASS | party holds the Stormheart=true; claim settled=true; answered accept by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 3 earlier line(s) and 3 offer line(s); captured 960x540 -> ralph/reports/INVITE-COOP/x05-proof-f11-drop-at-ack/peer-0/02_host_offer_yes_no.png |
| 15 | 1 | stormheart_answer — the guest says Yes through the real dialogue, and its link is closed in the answer's own physics step, before any network poll: the Yes receipt is saved on its character, the ending_settled acknowledgement is never sent | PASS + {"accepted_anywhere":true,"cut_at_ack":true,"has_stormheart":true,"receipt_on_disk":true} | PASS | answered Yes; link closed in the answer's own physics step=true (claim already committed then=false); the Yes receipt is on the saved character=true; { "character_id": "character-75e5f1fd6462953e2a2663dd31fb1bb5", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": false, "world_refused": false, "accepted_anywhere": true, "cut_at_ack": true, "committed_before_cut": false, "receipt_on_disk": true } |
| 16 | 0 | expect_peers — the host sees the guest gone | PASS | PASS | registry reports 1 peer(s) after 0 frames |
| 17 | 0 | stormheart_state — the acknowledgement never reached the host: no world receipt of the guest's answer | PASS + {"other_accepted":false,"other_refused":false} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true, "other_accepted": false, "other_refused": false } |
| 18 | 1 | probe input_context — the dropped guest is back at the title | PASS | PASS | "title" |
| 19 | 1 | production_join — the guest rejoins from the title as the same character | PASS | PASS | title returning entry built 'Stormwood' first, then JoinDriver joined 127.0.0.1:35641 as peer 346047526 after 57 frames |
| 20 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 20 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 21 | 1 | enter_realm — back into Stormwood (ANY: a rejoin may already stand there) | any | FAIL | Game.enter_realm('stormwood') refused from 'stormwood' (can_enter=true) |
| 22 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 23 | 0 | wait_flag — after the rejoin the host settles the guest's answer from its saved receipt | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-75e5f1fd6462953e2a2663dd31fb1bb5 (any) set after 0 frames |
| 23 | 1 | wait_flag — after the rejoin the host settles the guest's answer from its saved receipt | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-75e5f1fd6462953e2a2663dd31fb1bb5 (any) set after 0 frames |
| 24 | 1 | stormheart_state — exactly one Stormheart: the resent claim granted nothing twice | PASS + {"accepted_anywhere":true,"has_stormheart":true,"party":["fulgocobra"],"world_accepted":true} | PASS | { "character_id": "character-75e5f1fd6462953e2a2663dd31fb1bb5", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true } |
| 25 | 1 | stormheart_answer — replay: pressing the prompt again offers nothing | FAIL | FAIL | the offer prompt is not offering itself to this player (enabled=false, standing nowhere in reach, label 'Answer the freed Stormheart') |
| 26 | 0 | save_reload_here — RELOAD: the host saves its slot and loads it back in place | PASS | PASS | host slot reload preserved party=true selection=true hosted_world=true |
| 27 | 1 | save_reload_here — RELOAD: the guest saves its character and applies it back from disk | PASS | PASS | client character reload preserved party=true selection=true hosted_world=true |
| 28 | 1 | stormheart_answer — after the reload the guest's prompt still offers nothing | FAIL | FAIL | the offer prompt is not offering itself to this player (enabled=false, standing nowhere in reach, label 'Answer the freed Stormheart') |
| 29 | 1 | stormheart_state — still exactly one Stormheart | PASS + {"has_stormheart":true,"party":["fulgocobra"]} | PASS | { "character_id": "character-75e5f1fd6462953e2a2663dd31fb1bb5", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true } |
| 30 | 0 | stormheart_state — host: its own one, and the guest's answer recorded once as accepted | PASS + {"has_stormheart":true,"other_accepted":true,"other_refused":false,"party":["fulgocobra"],"world_accepted":true} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true, "other_accepted": true, "other_refused": false } |
| 31 | 0 | screenshot | PASS | PASS | captured 960x540 -> ralph/reports/INVITE-COOP/x05-proof-f11-drop-at-ack/peer-0/03_after_rejoin.png |
| 31 | 1 | screenshot | PASS | PASS | captured 960x540 -> ralph/reports/INVITE-COOP/x05-proof-f11-drop-at-ack/peer-1/03_after_rejoin.png |
| 32 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to ralph/reports/INVITE-COOP/x05-proof-f11-drop-at-ack/peer-0/after |
| 32 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-75e5f1fd6462953e2a2663dd31fb1bb5' on disk=true; copied 1 files to ralph/reports/INVITE-COOP/x05-proof-f11-drop-at-ack/peer-1/after |
| 33 | 1 | check_saved — guest's saved character: one Stormheart, answered Yes | PASS | PASS | missing []; unexpectedly present []; read ["character-75e5f1fd6462953e2a2663dd31fb1bb5/character.json"] under after/characters |
| 34 | 0 | check_saved — host world: each character's answer recorded once | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under after/worlds |

## Captured files

- `peer-0/01_both_in_stormwood.png`
- `peer-0/02_host_offer_yes_no.png`
- `peer-0/03_after_rejoin.png`
- `peer-0/after/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/worlds/slot-0/world.json`
- `peer-0/before/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/before/saves/slot_0.json`
- `peer-0/before/worlds/slot-0/world.json`
- `peer-1/01_both_in_stormwood.png`
- `peer-1/02_guest_offer_yes_no.png`
- `peer-1/03_after_rejoin.png`
- `peer-1/after/characters/character-75e5f1fd6462953e2a2663dd31fb1bb5/character.json`
- `peer-1/before/characters/character-75e5f1fd6462953e2a2663dd31fb1bb5/character.json`
