# Two-peer proof: F11 disconnect/reload: guest's link dies with its Stormheart owed, rejoins, answers once; a second drop/rejoin and a save/reload grant nothing twice

**Verdict: PASS** (exit 0)

Scenario: `/tmp/claude-0/scratch/stormwood_f11_disconnect_guest_rejoins_answers_once.json`  
Run: `net-20261011T185430Z-15085`  
Rendered: no (headless)

ACCEPTANCE F11 'through disconnect ... without duplicated grants', partial: both fought the Dynamo, both have space. The host says Yes. The guest's link dies AFTER the release (its offer owed, not yet opened -- the proof steps have no 'open the offer and stop' step), it rejoins as the same character, walks up and says Yes once. Then its link dies again, it rejoins and presses the prompt again: nothing is offered and it still holds exactly one Stormheart. Both peers then save_reload_here (host: autosave + load_slot in place; guest: character save + apply from disk) and press again: still nothing. Setup: the Dynamo fight fixture only.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: a fresh trainer in the Meadows | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | enter_realm — DISCLOSED SETUP: initial Hall arch position and the Stormwood portal open for this world (stands in for the earned Cloudreach-finale unlock), no earned credit | PASS | PASS | Disclosed initial actual ground/route fixture; return cases include an initial Home Key; no earned credit |
| 4 | 1 | enter_realm — DISCLOSED SETUP: initial Hall arch position and the Stormwood portal open for this world (stands in for the earned Cloudreach-finale unlock), no earned credit | PASS | PASS | Disclosed initial actual ground/route fixture; return cases include an initial Home Key; no earned credit |
| 5 | 0 | host | PASS | PASS | hosting udp/31501 as peer 1 |
| 6 | 1 | join | PASS | PASS | joined 127.0.0.1:31501 as peer 586183722 after 17 frames; snapshot applied; 2 peer(s) in registry |
| 7 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 7 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 8 | 0 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 8 | 1 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 9 | 1 | enter_realm — through the Crossing Hall Stormwood portal (RD-17) | PASS | PASS | crossed 'meadows' -> 'stormwood' after 791 observed physics frames / 33237 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 10 | 0 | enter_realm — through the Crossing Hall Stormwood portal (RD-17) | PASS | PASS | crossed 'meadows' -> 'stormwood' after 836 observed physics frames / 32132 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 11 | 0 | probe downed — trainer vitals on arrival (health recorded, see the HUD note) | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":100.0,"hold_peer":0.0,"hold_s":0.0,"host_authority_attempts":[],"host_views":{"1":{"body_id":22945644969051.0,"position":[-298.5,32.3098487854004,180.0],"realm":"stormwood","valid":true},"586183722":{"body_id":22949620878351.0,"position":[-300.0,32.2718391418457,180.0],"realm":"stormwood","valid":true}},"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":22945644969051.0,"prompt":"[img=36x36]res://assets/ui/input_prompts/keyboard_e.png[/img]   Take Good Candy","viewer_id":22945644969051.0,"viewer_position":[-298.5,32.3098487854004,180.0]},"interaction_winner":{"class":"Node3D","name":"Interactable"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_radius_m":2.5,"rev |
| 11 | 1 | probe downed — trainer vitals on arrival (health recorded, see the HUD note) | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":100.0,"hold_peer":0.0,"hold_s":0.0,"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":9392355371273.0,"prompt":"[img=36x36]res://assets/ui/input_prompts/keyboard_e.png[/img]   Take Good Candy","viewer_id":9392355371273.0,"viewer_position":[-300.0,32.2718391418457,180.0]},"interaction_winner":{"class":"Node3D","name":"Interactable"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_radius_m":2.5,"revived":0.0,"satchel_nodes":0.0,"satchels":0.0,"stamina":100.0,"window_s":45.0} |
| 12 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 12 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 13 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 5 files to /tmp/claude-0/runs/proof-stormwood_f11_disconnect_guest_rejoins_answers_once/peer-0/before |
| 13 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-15deb0bc932c37f4c3def9e5e9dee5cb' on disk=true; copied 3 files to /tmp/claude-0/runs/proof-stormwood_f11_disconnect_guest_rejoins_answers_once/peer-1/before |
| 14 | 0 | stormheart_fixture — both fought the Dynamo (setup) | PASS | PASS | Dynamo contributors [1, 586183722]; committed ["stormwood:act_ii_complete", "stormwood:marrow_defeated"] |
| 15 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 15 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 16 | 0 | stormheart_answer — host says Yes | PASS + {"has_stormheart":true} | PASS | party holds the Stormheart=true; claim settled=true; answered accept by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 3 earlier line(s) and 3 offer line(s); headless peer: no frame to capture (run with --render) |
| 17 | 1 | drop_link — first drop (offer owed, unanswered): the guest's link dies (transport closed, no Session.leave) | PASS | PASS | transport closed without a Session.leave() (ENet disconnect sent to 1 peer(s), acknowledged by 1 after 9 frames) |
| 18 | 0 | expect_peers — the host sees the guest gone | PASS | PASS | registry reports 1 peer(s) after 0 frames (0.0 s) |
| 19 | 1 | probe input_context — the dropped guest is back at the title (Session._on_server_disconnected -> _return_to_title) | PASS | PASS | "title" |
| 20 | 1 | production_join — first drop (offer owed, unanswered): the guest rejoins from the title screen as the same character (title_screen _join_via -> JoinDriver) | PASS | PASS | title returning entry built 'Stormwood' first, then JoinDriver joined 127.0.0.1:31501 as peer 614844809 after 71 frames |
| 21 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 21 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 22 | 1 | enter_realm — back into Stormwood (ANY: a rejoin may already stand there) | any | FAIL | Game.enter_realm('stormwood') refused from 'stormwood' (can_enter=true) |
| 23 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 24 | 1 | stormheart_state — after the rejoin the guest holds nothing and has answered nothing | PASS + {"has_stormheart":false,"party":[],"world_accepted":false,"world_refused":false} | PASS | { "character_id": "character-15deb0bc932c37f4c3def9e5e9dee5cb", "party": [], "has_stormheart": false, "freed": true, "world_accepted": false, "world_refused": false, "accepted_anywhere": false, "party_uids": [] } |
| 25 | 1 | stormheart_answer — the rejoined guest is still owed its own offer and says Yes | PASS + {"has_stormheart":true} | PASS | party holds the Stormheart=true; claim settled=true; answered accept by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 0 earlier line(s) and 3 offer line(s); headless peer: no frame to capture (run with --render) |
| 26 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-15deb0bc932c37f4c3def9e5e9dee5cb (any) set after 0 frames |
| 26 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-15deb0bc932c37f4c3def9e5e9dee5cb (any) set after 0 frames |
| 27 | 1 | stormheart_state — exactly one | PASS + {"has_stormheart":true,"party":["fulgocobra"],"world_accepted":true} | PASS | { "character_id": "character-15deb0bc932c37f4c3def9e5e9dee5cb", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true, "party_uids": ["creature-256ba1d1962141423c2dd96a03e92414"] } |
| 28 | 1 | drop_link — second drop (answered): the guest's link dies (transport closed, no Session.leave) | PASS | PASS | transport closed without a Session.leave() (ENet disconnect sent to 1 peer(s), acknowledged by 1 after 2 frames) |
| 29 | 0 | expect_peers — the host sees the guest gone | PASS | PASS | registry reports 1 peer(s) after 0 frames (0.0 s) |
| 30 | 1 | probe input_context — the dropped guest is back at the title (Session._on_server_disconnected -> _return_to_title) | PASS | PASS | "title" |
| 31 | 1 | production_join — second drop (answered): the guest rejoins from the title screen as the same character (title_screen _join_via -> JoinDriver) | PASS | PASS | title returning entry built 'Stormwood' first, then JoinDriver joined 127.0.0.1:31501 as peer 73597774 after 68 frames |
| 32 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 32 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 33 | 1 | enter_realm — back into Stormwood (ANY: a rejoin may already stand there) | any | FAIL | Game.enter_realm('stormwood') refused from 'stormwood' (can_enter=true) |
| 34 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 35 | 1 | stormheart_state — after the second rejoin the guest still holds exactly one Stormheart | PASS + {"accepted_anywhere":true,"has_stormheart":true,"party":["fulgocobra"]} | PASS | { "character_id": "character-15deb0bc932c37f4c3def9e5e9dee5cb", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true, "party_uids": ["creature-256ba1d1962141423c2dd96a03e92414"] } |
| 36 | 1 | stormheart_answer — replay: pressing the prompt again after the reconnect offers nothing | FAIL | FAIL | no verdict |
| 37 | 0 | save_reload_here — RELOAD: the host saves its slot and loads it back in place (autosave_here + load_slot) | PASS | PASS | host slot reload preserved party=true selection=true hosted_world=true |
| 38 | 1 | save_reload_here — RELOAD: the guest saves its character and applies it back from disk | PASS | PASS | client character reload preserved party=true selection=true hosted_world=true |
| 39 | 0 | probe downed — trainer vitals after the reload (health recorded, see the HUD note) | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":100.0,"hold_peer":0.0,"hold_s":0.0,"host_authority_attempts":[],"host_views":{"1":{"body_id":22945644969051.0,"position":[-98.0,262.06005859375,5480.5],"realm":"stormwood","valid":true},"73597774":{"body_id":32407642240036.0,"position":[-103.0,262.059265136719,5477.5],"realm":"stormwood","valid":true}},"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":22945644969051.0,"prompt":"[img=36x36]res://assets/ui/input_prompts/xbox_button_x.png[/img]   Look beyond the broken storm","viewer_id":22945644969051.0,"viewer_position":[-98.0,262.06005859375,5480.5]},"interaction_winner":{"class":"Node3D","name":"WaterwardView"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_rad |
| 39 | 1 | probe downed — trainer vitals after the reload (health recorded, see the HUD note) | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":99.2833747384568,"hold_peer":0.0,"hold_s":0.0,"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":20233641323491.0,"prompt":"[img=36x36]res://assets/ui/input_prompts/xbox_button_x.png[/img]   Look beyond the broken storm","viewer_id":20233641323491.0,"viewer_position":[-103.0,262.06005859375,5477.5]},"interaction_winner":{"class":"Node3D","name":"WaterwardView"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_radius_m":2.5,"revived":0.0,"satchel_nodes":0.0,"satchels":0.0,"stamina":100.0,"window_s":45.0} |
| 40 | 1 | stormheart_answer — after the reload the guest's prompt still offers nothing | FAIL | FAIL | no verdict |
| 41 | 0 | stormheart_answer — after the reload the host's prompt offers nothing | FAIL | FAIL | the offer prompt is not offering itself to this player (enabled=false, standing nowhere in reach, label 'Answer the freed Stormheart') |
| 42 | 1 | stormheart_state — still exactly one Stormheart | PASS + {"has_stormheart":true,"party":["fulgocobra"]} | PASS | { "character_id": "character-15deb0bc932c37f4c3def9e5e9dee5cb", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true, "party_uids": ["creature-256ba1d1962141423c2dd96a03e92414"] } |
| 43 | 0 | stormheart_state — host still exactly one of its own | PASS + {"has_stormheart":true,"party":["fulgocobra"],"world_accepted":true} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true, "party_uids": ["creature-8b24196851d262b3b0ffd99c91d10633"] } |
| 44 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 44 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 45 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 5 files to /tmp/claude-0/runs/proof-stormwood_f11_disconnect_guest_rejoins_answers_once/peer-0/after |
| 45 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-15deb0bc932c37f4c3def9e5e9dee5cb' on disk=true; copied 3 files to /tmp/claude-0/runs/proof-stormwood_f11_disconnect_guest_rejoins_answers_once/peer-1/after |
| 46 | 0 | check_saved — host's pre-offer saved world held no answers (non-vacuous baseline) | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/slot-0/world.json"] under before/worlds |
| 47 | 0 | check_saved — host's pre-offer character held no answer | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-f41f4a49223483d6bfdf56715944bb7b/character.json"] under before/characters |
| 48 | 1 | check_saved — guest's pre-offer character held no answer | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-15deb0bc932c37f4c3def9e5e9dee5cb/character.json"] under before/characters |
| 49 | 0 | check_saved — host's saved world: each accepted once | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/slot-0/world.json"] under after/worlds |
| 50 | 1 | check_saved — guest's saved character keeps one Stormheart | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-15deb0bc932c37f4c3def9e5e9dee5cb/character.json"] under after/characters |

## Captured files

- `peer-0/after/characters/redesign-v28/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/after/saves/redesign-v28/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/after/saves/redesign-v28/slot_0.json`
- `peer-0/after/saves/redesign-v28/worlds/slot-0/world.json`
- `peer-0/after/worlds/redesign-v28/slot-0/world.json`
- `peer-0/before/characters/redesign-v28/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/before/saves/redesign-v28/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/before/saves/redesign-v28/slot_0.json`
- `peer-0/before/saves/redesign-v28/worlds/slot-0/world.json`
- `peer-0/before/worlds/redesign-v28/slot-0/world.json`
- `peer-1/after/characters/redesign-v28/character-15deb0bc932c37f4c3def9e5e9dee5cb/character.json`
- `peer-1/after/saves/redesign-v28/characters/character-15deb0bc932c37f4c3def9e5e9dee5cb/character.json`
- `peer-1/after/worlds/redesign-v28/slot-0/world.json`
- `peer-1/before/characters/redesign-v28/character-15deb0bc932c37f4c3def9e5e9dee5cb/character.json`
- `peer-1/before/saves/redesign-v28/characters/character-15deb0bc932c37f4c3def9e5e9dee5cb/character.json`
- `peer-1/before/worlds/redesign-v28/slot-0/world.json`
