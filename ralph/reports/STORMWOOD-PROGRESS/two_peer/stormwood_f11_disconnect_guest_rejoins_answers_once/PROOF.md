# Two-peer proof: F11 disconnect/reload: guest's link dies with its Stormheart owed, rejoins, answers once; a second drop/rejoin and a save/reload grant nothing twice

**Verdict: PASS** (exit 0)

Scenario: `/home/user/tb-road/tools/net/proof_scenarios/stormwood_f11_disconnect_guest_rejoins_answers_once.json`  
Run: `net-20260925T200502Z-30959`  
Rendered: yes

ACCEPTANCE F11 'through disconnect ... without duplicated grants', partial: both fought the Dynamo, both have space. The host says Yes. The guest's link dies AFTER the release (its offer owed, not yet opened -- the proof steps have no 'open the offer and stop' step), it rejoins as the same character, walks up and says Yes once. Then its link dies again, it rejoins and presses the prompt again: nothing is offered and it still holds exactly one Stormheart. Both peers then save_reload_here (host: autosave + load_slot in place; guest: character save + apply from disk) and press again: still nothing. Setup: the Dynamo fight fixture only.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: a fresh trainer in the Meadows | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | host | PASS | PASS | hosting udp/30061 as peer 1 |
| 4 | 1 | join | PASS | PASS | joined 127.0.0.1:30061 as peer 986540584 after 10 frames; snapshot applied; 2 peer(s) in registry |
| 5 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 5 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 6 | 0 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 6 | 1 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 7 | 0 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 416 observed physics frames / 35430 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 8 | 1 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 499 observed physics frames / 23397 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 9 | 0 | probe downed — trainer vitals on arrival (health recorded, see the HUD note) | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":100.0,"hold_peer":0.0,"hold_s":0.0,"host_authority_attempts":[],"host_views":{"1":{"body_id":46470002877024.0,"position":[-300.0,32.271728515625,180.0],"realm":"stormwood","valid":true},"986540584":{"body_id":49576488774732.0,"position":[-300.0,32.271728515625,180.0],"realm":"stormwood","valid":true}},"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":46470002877024.0,"prompt":"[img=36x36]res://assets/ui/input_prompts/keyboard_e.png[/img]   Take Good Candy","viewer_id":46470002877024.0,"viewer_position":[-300.0,32.271728515625,180.0]},"interaction_winner":{"class":"Node3D","name":"Interactable"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_radius_m":2.5,"revive |
| 9 | 1 | probe downed — trainer vitals on arrival (health recorded, see the HUD note) | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":100.0,"hold_peer":0.0,"hold_s":0.0,"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":60939428694072.0,"prompt":"[img=36x36]res://assets/ui/input_prompts/keyboard_e.png[/img]   Take Good Candy","viewer_id":60939428694072.0,"viewer_position":[-300.0,32.271728515625,180.0]},"interaction_winner":{"class":"Node3D","name":"Interactable"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_radius_m":2.5,"revived":0.0,"satchel_nodes":0.0,"satchels":0.0,"stamina":100.0,"window_s":45.0} |
| 10 | 0 | screenshot | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_disconnect_guest_rejoins_answers_once/peer-0/01_both_in_stormwood.png |
| 10 | 1 | screenshot | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_disconnect_guest_rejoins_answers_once/peer-1/01_both_in_stormwood.png |
| 11 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_disconnect_guest_rejoins_answers_once/peer-0/before |
| 11 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-a738b8ae3935212311c403f6d94aae00' on disk=true; copied 1 files to /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_disconnect_guest_rejoins_answers_once/peer-1/before |
| 12 | 0 | stormheart_fixture — both fought the Dynamo (setup) | PASS | PASS | Dynamo contributors [1, 986540584]; committed ["stormwood:act_ii_complete", "stormwood:marrow_defeated"] |
| 13 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 13 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 765 frames |
| 14 | 0 | stormheart_answer — host says Yes | PASS + {"has_stormheart":true} | PASS | party holds the Stormheart=true; claim settled=true; answered accept by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 3 earlier line(s) and 3 offer line(s); captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_disconnect_guest_rejoins_answers_once/peer-0/02_host_offer_yes_no.png |
| 15 | 1 | drop_link — first drop (offer owed, unanswered): the guest's link dies (transport closed, no Session.leave) | PASS | PASS | transport closed without a Session.leave() |
| 16 | 0 | expect_peers — the host sees the guest gone | PASS | PASS | registry reports 1 peer(s) after 0 frames |
| 17 | 1 | probe input_context — the dropped guest is back at the title (Session._on_server_disconnected -> _return_to_title) | PASS | PASS | "title" |
| 18 | 1 | production_join — first drop (offer owed, unanswered): the guest rejoins from the title screen as the same character (title_screen _join_via -> JoinDriver) | PASS | PASS | title returning entry built 'Stormwood' first, then JoinDriver joined 127.0.0.1:30061 as peer 2067683093 after 42 frames |
| 19 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 19 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 20 | 1 | enter_realm — back into Stormwood (ANY: a rejoin may already stand there) | any | FAIL | Game.enter_realm('stormwood') refused from 'stormwood' (can_enter=true) |
| 21 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 22 | 1 | stormheart_state — after the rejoin the guest holds nothing and has answered nothing | PASS + {"has_stormheart":false,"party":[],"world_accepted":false,"world_refused":false} | PASS | { "character_id": "character-a738b8ae3935212311c403f6d94aae00", "party": [], "has_stormheart": false, "freed": true, "world_accepted": false, "world_refused": false, "accepted_anywhere": false } |
| 23 | 1 | stormheart_answer — the rejoined guest is still owed its own offer and says Yes | PASS + {"has_stormheart":true} | PASS | party holds the Stormheart=true; claim settled=true; answered accept by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 0 earlier line(s) and 3 offer line(s); captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_disconnect_guest_rejoins_answers_once/peer-1/03_guest_offer_after_rejoin.png |
| 24 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-a738b8ae3935212311c403f6d94aae00 (any) set after 0 frames |
| 24 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-a738b8ae3935212311c403f6d94aae00 (any) set after 0 frames |
| 25 | 1 | stormheart_state — exactly one | PASS + {"has_stormheart":true,"party":["fulgocobra"],"world_accepted":true} | PASS | { "character_id": "character-a738b8ae3935212311c403f6d94aae00", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true } |
| 26 | 1 | drop_link — second drop (answered): the guest's link dies (transport closed, no Session.leave) | PASS | PASS | transport closed without a Session.leave() |
| 27 | 0 | expect_peers — the host sees the guest gone | PASS | PASS | registry reports 1 peer(s) after 0 frames |
| 28 | 1 | probe input_context — the dropped guest is back at the title (Session._on_server_disconnected -> _return_to_title) | PASS | PASS | "title" |
| 29 | 1 | production_join — second drop (answered): the guest rejoins from the title screen as the same character (title_screen _join_via -> JoinDriver) | PASS | PASS | title returning entry built 'Stormwood' first, then JoinDriver joined 127.0.0.1:30061 as peer 1665870138 after 46 frames |
| 30 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 30 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 31 | 1 | enter_realm — back into Stormwood (ANY: a rejoin may already stand there) | any | FAIL | Game.enter_realm('stormwood') refused from 'stormwood' (can_enter=true) |
| 32 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 33 | 1 | stormheart_state — after the second rejoin the guest still holds exactly one Stormheart | PASS + {"accepted_anywhere":true,"has_stormheart":true,"party":["fulgocobra"]} | PASS | { "character_id": "character-a738b8ae3935212311c403f6d94aae00", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true } |
| 34 | 1 | stormheart_answer — replay: pressing the prompt again after the reconnect offers nothing | FAIL | FAIL | the offer prompt is not offering itself to this player (enabled=false, standing nowhere in reach, label 'Answer the freed Stormheart') |
| 35 | 0 | save_reload_here — RELOAD: the host saves its slot and loads it back in place (autosave_here + load_slot) | PASS | PASS | host slot reload preserved party=true selection=true hosted_world=true |
| 36 | 1 | save_reload_here — RELOAD: the guest saves its character and applies it back from disk | PASS | PASS | client character reload preserved party=true selection=true hosted_world=true |
| 37 | 0 | probe downed — trainer vitals after the reload (health recorded, see the HUD note) | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":100.0,"hold_peer":0.0,"hold_s":0.0,"host_authority_attempts":[],"host_views":{"1":{"body_id":46470002877024.0,"position":[-98.0,262.058654785156,5480.5],"realm":"stormwood","valid":true},"1665870138":{"body_id":53502357512957.0,"position":[-103.0,203.588241577148,5477.5],"realm":"stormwood","valid":true}},"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":46470002877024.0,"prompt":"[img=36x36]res://assets/ui/input_prompts/xbox_button_x.png[/img]   Look beyond the broken storm","viewer_id":46470002877024.0,"viewer_position":[-98.0,262.058654785156,5480.5]},"interaction_winner":{"class":"Node3D","name":"WaterwardView"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive |
| 37 | 1 | probe downed — trainer vitals after the reload (health recorded, see the HUD note) | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":99.649033544381,"hold_peer":0.0,"hold_s":0.0,"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":66292132370341.0,"prompt":"[img=36x36]res://assets/ui/input_prompts/xbox_rb.png[/img]   Call out the Stormheart","viewer_id":66292132370341.0,"viewer_position":[-103.0,194.54655456543,5477.5]},"interaction_winner":{"class":"Node","name":"EncounterDirector"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_radius_m":2.5,"revived":0.0,"satchel_nodes":0.0,"satchels":0.0,"stamina":100.0,"window_s":45.0} |
| 38 | 1 | stormheart_answer — after the reload the guest's prompt still offers nothing | FAIL | FAIL | the offer prompt is not offering itself to this player (enabled=false, standing nowhere in reach, label 'Answer the freed Stormheart') |
| 39 | 0 | stormheart_answer — after the reload the host's prompt offers nothing | FAIL | FAIL | the offer prompt is not offering itself to this player (enabled=false, standing nowhere in reach, label 'Answer the freed Stormheart') |
| 40 | 1 | stormheart_state — still exactly one Stormheart | PASS + {"has_stormheart":true,"party":["fulgocobra"]} | PASS | { "character_id": "character-a738b8ae3935212311c403f6d94aae00", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true } |
| 41 | 0 | stormheart_state — host still exactly one of its own | PASS + {"has_stormheart":true,"party":["fulgocobra"],"world_accepted":true} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true } |
| 42 | 0 | screenshot | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_disconnect_guest_rejoins_answers_once/peer-0/04_after_rejoins.png |
| 42 | 1 | screenshot | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_disconnect_guest_rejoins_answers_once/peer-1/04_after_rejoins.png |
| 43 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_disconnect_guest_rejoins_answers_once/peer-0/after |
| 43 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-a738b8ae3935212311c403f6d94aae00' on disk=true; copied 1 files to /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_disconnect_guest_rejoins_answers_once/peer-1/after |
| 44 | 0 | check_saved — host's pre-offer saved world held no answers (non-vacuous baseline) | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under before/worlds |
| 45 | 0 | check_saved — host's pre-offer character held no answer | PASS | PASS | missing []; unexpectedly present []; read ["character-f41f4a49223483d6bfdf56715944bb7b/character.json"] under before/characters |
| 46 | 1 | check_saved — guest's pre-offer character held no answer | PASS | PASS | missing []; unexpectedly present []; read ["character-a738b8ae3935212311c403f6d94aae00/character.json"] under before/characters |
| 47 | 0 | check_saved — host's saved world: each accepted once | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under after/worlds |
| 48 | 1 | check_saved — guest's saved character keeps one Stormheart | PASS | PASS | missing []; unexpectedly present []; read ["character-a738b8ae3935212311c403f6d94aae00/character.json"] under after/characters |

## Captured files

- `peer-0/01_both_in_stormwood.png`
- `peer-0/02_host_offer_yes_no.png`
- `peer-0/04_after_rejoins.png`
- `peer-0/after/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/worlds/slot-0/world.json`
- `peer-0/before/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/before/saves/slot_0.json`
- `peer-0/before/worlds/slot-0/world.json`
- `peer-1/01_both_in_stormwood.png`
- `peer-1/03_guest_offer_after_rejoin.png`
- `peer-1/04_after_rejoins.png`
- `peer-1/after/characters/character-a738b8ae3935212311c403f6d94aae00/character.json`
- `peer-1/before/characters/character-a738b8ae3935212311c403f6d94aae00/character.json`

---
Annotated after the run (not written by the runner): run dir `net/net-proof_two_peer-20260925T200502Z`. In the repo, `worlds/` and `characters/` files are committed gzipped (`.json.gz`), PNGs are 256-colour quantized, and `saves/` slot copies and `net/` logs are omitted for size (`NET-SUMMARY.md` is the harness summary; `LOG-EXCERPTS.txt` keeps every SCRIPT ERROR with context and every [downed] line from the peer logs). `SCRIPT ERROR` lines across both peer logs: 0.

**Scope of the disconnect (read before citing):** both drops happen while the guest's Stormheart offer is *owed but not yet opened*: the first after the release and before the guest pressed the offer prompt, the second after it had answered. No proof step opens the offer and stops before its Yes/No line (a `stormheart_open_offer` step would be needed in `tools/net/proof_steps.gd`, lane X05), so a drop with the Yes/No box on screen is NOT covered here. The rejoin is the player's own route: the dropped client lands on the title screen (`session.gd` `_on_server_disconnected` -> `_return_to_title`) and rejoins through `production_join` (title `_join_via` -> JoinDriver) as the same character; the `enter_realm` rows read FAIL (expected ANY) because the returning route already stood Stormwood up.

**Health note:** the guest's frame `04_after_rejoins.png` shows 0/100 and LOG-EXCERPTS.txt has `[downed]` lines. The probe right after the reload read 99.6. The drop happened during steps #38/#39: `stormheart_answer` on an already-dark prompt tries all six stand-offsets around it and leaves the trainer at the last one, below the core platform. That is a proof-step side effect, not part of the answer path.
