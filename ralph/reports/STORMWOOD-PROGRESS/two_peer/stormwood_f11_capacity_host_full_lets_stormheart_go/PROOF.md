# Two-peer proof: F11 capacity: host full at five says Yes then lets the Stormheart go; guest with space says Yes

**Verdict: PASS** (exit 0)

Scenario: `/home/user/tb-road/tools/net/proof_scenarios/stormwood_f11_capacity_host_full_lets_stormheart_go.json`  
Run: `net-20260925T192701Z-23676`  
Rendered: yes

ACCEPTANCE F11 'at capacity', the other branch of the five-slot choice: the host's belt holds five when it says Yes. The ceremony offers the newcomer's own row; the host lets the Stormheart go, keeps all five, and the game records that as its refusal (stormwood_ending.gd: 'exactly as letting the newcomer go at five'). No sixth slot, no belt member lost. The guest, with space, says Yes and keeps its own, independently. Setup, disclosed: the Dynamo fight fixture and the host's five belt members (party_grant -> party_seam.add); everything from the offer on is the game's own code.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: a fresh trainer in the Meadows | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | host | PASS | PASS | hosting udp/33761 as peer 1 |
| 4 | 1 | join | PASS | PASS | joined 127.0.0.1:33761 as peer 122349314 after 11 frames; snapshot applied; 2 peer(s) in registry |
| 5 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 5 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 6 | 0 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 6 | 1 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 7 | 0 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 480 observed physics frames / 32583 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 8 | 1 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 498 observed physics frames / 22827 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 9 | 0 | party_grant — SETUP: host's belt member 1/5 (bramblebun) through party_seam.add | PASS | PASS | 'bramblebun' at level 20 joined the party (1 member(s)) |
| 10 | 0 | party_grant — SETUP: host's belt member 2/5 (terrapup) through party_seam.add | PASS | PASS | 'terrapup' at level 20 joined the party (2 member(s)) |
| 11 | 0 | party_grant — SETUP: host's belt member 3/5 (ripplet) through party_seam.add | PASS | PASS | 'ripplet' at level 20 joined the party (3 member(s)) |
| 12 | 0 | party_grant — SETUP: host's belt member 4/5 (galewisp) through party_seam.add | PASS | PASS | 'galewisp' at level 20 joined the party (4 member(s)) |
| 13 | 0 | party_grant — SETUP: host's belt member 5/5 (mudsnout) through party_seam.add | PASS | PASS | 'mudsnout' at level 20 joined the party (5 member(s)) |
| 14 | 0 | party_grant — host's belt is full: a sixth party_seam.add is refused (no sixth slot) | FAIL | FAIL | party_seam.add('trailpup') refused -- the party is full (five, and there is no sixth slot) |
| 15 | 0 | stormheart_state — host: exactly five before the offer | PASS + {"has_stormheart":false,"party":["bramblebun","terrapup","ripplet","galewisp","mudsnout"]} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": ["bramblebun", "terrapup", "ripplet", "galewisp", "mudsnout"], "has_stormheart": false, "freed": false, "world_accepted": false, "world_refused": false, "accepted_anywhere": false } |
| 16 | 1 | stormheart_state — guest: free slots before the offer | PASS + {"has_stormheart":false,"party":[]} | PASS | { "character_id": "character-171423f4a99b693d7f7e19da2ad1b9ae", "party": [], "has_stormheart": false, "freed": false, "world_accepted": false, "world_refused": false, "accepted_anywhere": false } |
| 17 | 0 | probe downed — trainer vitals on arrival (health recorded, see the HUD note) | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":100.0,"hold_peer":0.0,"hold_s":0.0,"host_authority_attempts":[],"host_views":{"1":{"body_id":46519361446466.0,"position":[-300.0,32.271728515625,180.0],"realm":"stormwood","valid":true},"122349314":{"body_id":49642473564426.0,"position":[-300.0,32.271728515625,180.0],"realm":"stormwood","valid":true}},"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":46519361446466.0,"prompt":"[img=36x36]res://assets/ui/input_prompts/keyboard_e.png[/img]   Take Good Candy","viewer_id":46519361446466.0,"viewer_position":[-300.0,32.271728515625,180.0]},"interaction_winner":{"class":"Node3D","name":"Interactable"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_radius_m":2.5,"revive |
| 17 | 1 | probe downed — trainer vitals on arrival (health recorded, see the HUD note) | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":100.0,"hold_peer":0.0,"hold_s":0.0,"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":63459148544592.0,"prompt":"[img=36x36]res://assets/ui/input_prompts/keyboard_e.png[/img]   Take Good Candy","viewer_id":63459148544592.0,"viewer_position":[-300.0,32.271728515625,180.0]},"interaction_winner":{"class":"Node3D","name":"Interactable"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_radius_m":2.5,"revived":0.0,"satchel_nodes":0.0,"satchels":0.0,"stamina":100.0,"window_s":45.0} |
| 18 | 0 | screenshot | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_host_full_lets_stormheart_go/peer-0/01_both_in_stormwood.png |
| 18 | 1 | screenshot | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_host_full_lets_stormheart_go/peer-1/01_both_in_stormwood.png |
| 19 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_host_full_lets_stormheart_go/peer-0/before |
| 19 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-171423f4a99b693d7f7e19da2ad1b9ae' on disk=true; copied 1 files to /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_host_full_lets_stormheart_go/peer-1/before |
| 20 | 0 | stormheart_fixture — both fought the Dynamo (setup) | PASS | PASS | Dynamo contributors [1, 122349314]; committed ["stormwood:act_ii_complete", "stormwood:marrow_defeated"] |
| 21 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 21 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 8 frames |
| 22 | 0 | stormheart_answer — host (five) says Yes: no sixth slot, nothing added, nothing recorded yet; the ceremony holds the Stormheart | FAIL + {"has_stormheart":false,"party":["bramblebun","terrapup","ripplet","galewisp","mudsnout"],"world_accepted":false,"world_refused":false} | FAIL | party holds the Stormheart=false; claim settled=false; answered accept by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 3 earlier line(s) and 3 offer line(s); captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_host_full_lets_stormheart_go/peer-0/02_host_offer_yes_no.png |
| 23 | 0 | probe input_context — the host is now in the Team tab's ceremony | PASS | PASS | "menu_creatures" |
| 24 | 0 | screenshot — host: the Team tab's release ceremony is on screen (newcomer row focused) | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_host_full_lets_stormheart_go/peer-0/03a_ceremony_choose.png |
| 25 | 0 | press — A on the focused newcomer row: 'this one goes free' | PASS | PASS | pressed 'ui_accept' x1 |
| 26 | 0 | screenshot — the farewell question (Keep focused first) | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_host_full_lets_stormheart_go/peer-0/03b_farewell_question.png |
| 27 | 0 | press — down to 'Let them go' | PASS | PASS | pressed 'ui_down' x1 |
| 28 | 0 | press — A: the one irreversible press | PASS | PASS | pressed 'ui_accept' x1 |
| 29 | 0 | screenshot — the goodbye beat | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_host_full_lets_stormheart_go/peer-0/03c_goes_free.png |
| 30 | 0 | press — A on the done button: the ceremony ends | PASS | PASS | pressed 'ui_accept' x1 |
| 31 | 0 | wait_flag — letting the newcomer go at five is recorded as the host's refusal | PASS | PASS | flag stormwood:legendary_resolution:refused:character-f41f4a49223483d6bfdf56715944bb7b (any) set after 0 frames |
| 31 | 1 | wait_flag — letting the newcomer go at five is recorded as the host's refusal | PASS | PASS | flag stormwood:legendary_resolution:refused:character-f41f4a49223483d6bfdf56715944bb7b (any) set after 0 frames |
| 32 | 0 | stormheart_state — host: the same five, no Stormheart, a refusal on record | PASS + {"accepted_anywhere":false,"has_stormheart":false,"party":["bramblebun","terrapup","ripplet","galewisp","mudsnout"],"world_accepted":false,"world_refused":true} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": ["bramblebun", "terrapup", "ripplet", "galewisp", "mudsnout"], "has_stormheart": false, "freed": true, "world_accepted": false, "world_refused": true, "accepted_anywhere": false } |
| 33 | 0 | press — B closes the Team tab once the ceremony has let go | PASS | PASS | pressed 'menu_cancel' x1 |
| 34 | 1 | stormheart_answer — guest (space) says Yes after the host's refusal: its own offer is still its own | PASS + {"has_stormheart":true} | PASS | party holds the Stormheart=true; claim settled=true; answered accept by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 3 earlier line(s) and 3 offer line(s); captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_host_full_lets_stormheart_go/peer-1/04_guest_offer_yes_no.png |
| 35 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-171423f4a99b693d7f7e19da2ad1b9ae (any) set after 0 frames |
| 35 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-171423f4a99b693d7f7e19da2ad1b9ae (any) set after 144 frames |
| 36 | 1 | stormheart_state — guest kept exactly one of its own | PASS + {"has_stormheart":true,"party":["fulgocobra"],"world_accepted":true,"world_refused":false} | PASS | { "character_id": "character-171423f4a99b693d7f7e19da2ad1b9ae", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true } |
| 37 | 0 | stormheart_answer — the host cannot re-open its settled offer by pressing again | FAIL | FAIL | the offer prompt is not offering itself to this player (enabled=false, standing nowhere in reach, label 'Answer the freed Stormheart') |
| 38 | 0 | stormheart_state — host still the same five | PASS + {"has_stormheart":false,"party":["bramblebun","terrapup","ripplet","galewisp","mudsnout"]} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": ["bramblebun", "terrapup", "ripplet", "galewisp", "mudsnout"], "has_stormheart": false, "freed": true, "world_accepted": false, "world_refused": true, "accepted_anywhere": false } |
| 39 | 0 | probe downed — trainer vitals at the end (health recorded, see the HUD note) | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":99.649033544381,"hold_peer":0.0,"hold_s":0.0,"host_authority_attempts":[],"host_views":{"1":{"body_id":46519361446466.0,"position":[-103.0,220.729873657227,5477.5],"realm":"stormwood","valid":true},"122349314":{"body_id":49642473564426.0,"position":[-98.0,262.059844970703,5480.5],"realm":"stormwood","valid":true}},"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":46519361446466.0,"prompt":"[img=36x36]res://assets/ui/input_prompts/xbox_rb.png[/img]   Call out Bramblebun","viewer_id":46519361446466.0,"viewer_position":[-103.0,220.729873657227,5477.5]},"interaction_winner":{"class":"Node","name":"EncounterDirector"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_ra |
| 39 | 1 | probe downed — trainer vitals at the end (health recorded, see the HUD note) | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":100.0,"hold_peer":0.0,"hold_s":0.0,"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":63459148544592.0,"prompt":"[img=36x36]res://assets/ui/input_prompts/xbox_button_x.png[/img]   Look beyond the broken storm","viewer_id":63459148544592.0,"viewer_position":[-98.0,262.058654785156,5480.5]},"interaction_winner":{"class":"Node3D","name":"WaterwardView"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_radius_m":2.5,"revived":0.0,"satchel_nodes":0.0,"satchels":0.0,"stamina":100.0,"window_s":45.0} |
| 40 | 0 | screenshot | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_host_full_lets_stormheart_go/peer-0/05_after_answers.png |
| 40 | 1 | screenshot | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_host_full_lets_stormheart_go/peer-1/05_after_answers.png |
| 41 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_host_full_lets_stormheart_go/peer-0/after |
| 41 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-171423f4a99b693d7f7e19da2ad1b9ae' on disk=true; copied 1 files to /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_host_full_lets_stormheart_go/peer-1/after |
| 42 | 0 | check_saved — host's pre-offer saved world held no answers (non-vacuous baseline) | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under before/worlds |
| 43 | 0 | check_saved — host's pre-offer character held no answer | PASS | PASS | missing []; unexpectedly present []; read ["character-f41f4a49223483d6bfdf56715944bb7b/character.json"] under before/characters |
| 44 | 1 | check_saved — guest's pre-offer character held no answer | PASS | PASS | missing []; unexpectedly present []; read ["character-171423f4a99b693d7f7e19da2ad1b9ae/character.json"] under before/characters |
| 45 | 0 | check_saved — host's pre-offer save held the five (baseline) | PASS | PASS | missing []; unexpectedly present []; read ["character-f41f4a49223483d6bfdf56715944bb7b/character.json"] under before/characters |
| 46 | 0 | check_saved — host's saved world: host refused, guest accepted, each once | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under after/worlds |
| 47 | 0 | check_saved — host's saved character: all five kept, no Stormheart, a refusal | PASS | PASS | missing []; unexpectedly present []; read ["character-f41f4a49223483d6bfdf56715944bb7b/character.json"] under after/characters |
| 48 | 1 | check_saved — guest's saved character keeps its Stormheart | PASS | PASS | missing []; unexpectedly present []; read ["character-171423f4a99b693d7f7e19da2ad1b9ae/character.json"] under after/characters |

## Captured files

- `peer-0/01_both_in_stormwood.png`
- `peer-0/02_host_offer_yes_no.png`
- `peer-0/03a_ceremony_choose.png`
- `peer-0/03b_farewell_question.png`
- `peer-0/03c_goes_free.png`
- `peer-0/05_after_answers.png`
- `peer-0/after/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/worlds/slot-0/world.json`
- `peer-0/before/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/before/saves/slot_0.json`
- `peer-0/before/worlds/slot-0/world.json`
- `peer-1/01_both_in_stormwood.png`
- `peer-1/04_guest_offer_yes_no.png`
- `peer-1/05_after_answers.png`
- `peer-1/after/characters/character-171423f4a99b693d7f7e19da2ad1b9ae/character.json`
- `peer-1/before/characters/character-171423f4a99b693d7f7e19da2ad1b9ae/character.json`

---
Annotated after the run (not written by the runner): run dir `net/net-proof_two_peer-20260925T192701Z`. In the repo, `worlds/` and `characters/` files are committed gzipped (`.json.gz`), PNGs are 256-colour quantized, and `saves/` slot copies and `net/` logs are omitted for size (`NET-SUMMARY.md` is the harness summary). `SCRIPT ERROR` lines across both peer logs: 1.
The one SCRIPT ERROR counted above (guest log) was not retained: this run was finalized before the excerpt file existed. Later runs keep LOG-EXCERPTS.txt.
