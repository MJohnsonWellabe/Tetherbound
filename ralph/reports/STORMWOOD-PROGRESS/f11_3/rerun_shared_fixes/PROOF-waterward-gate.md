# Two-peer proof: F11 Waterward gate: charted by the host, opened once by the guest, kept by both peers through a save/reload

**Verdict: PASS** (exit 0)

Scenario: `/home/user/tetherbound/tools/net/proof_scenarios/stormwood_f11_waterward_gate_two_peer_reload.json`  
Run: `net-20260926T162252Z-12562`  
Rendered: no (headless)

ACCEPTANCE F11 'the once-opened physical Tidewake gate persists' (two peers + reload). After both answer their own Stormheart (host Yes, guest No), the HOST walks onto the high platform and presses 'Look beyond the broken storm' (stormwood_ending.gd _on_waterward_view -> host _reveal_for -> chapter aftermath:waterward_view, which grants the one-time realm_key_water). The GUEST walks to the Waterward gate and presses its prompt once (stormwood_water_gate.gd try_unlock -> UNLOCK_INTENT -> host host_commit: key consumed and realm_gate_water_unlocked in one journaled transaction). Both peers then save_reload_here and the gate stays open on both, the key stays consumed. Setup, disclosed: the Dynamo fight fixture, and `teleport` to stand beside each prompt (the walk up the platform is not played); the presses are ordinary `interact` presses. The gate is NOT pressed a second time, because an open gate's press enters Tidewake.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: a fresh trainer in the Meadows | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | host | PASS | PASS | hosting udp/29741 as peer 1 |
| 4 | 1 | join | PASS | PASS | joined 127.0.0.1:29741 as peer 49127255 after 10 frames; snapshot applied; 2 peer(s) in registry |
| 5 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 5 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 6 | 0 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 6 | 1 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 7 | 0 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 481 observed physics frames / 34715 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 8 | 1 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 502 observed physics frames / 23022 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 9 | 0 | probe downed — trainer vitals on arrival | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":100.0,"hold_peer":0.0,"hold_s":0.0,"host_authority_attempts":[],"host_views":{"1":{"body_id":47659809482736.0,"position":[-300.0,32.271728515625,180.0],"realm":"stormwood","valid":true},"49127255":{"body_id":50751850184823.0,"position":[-300.0,32.271728515625,180.0],"realm":"stormwood","valid":true}},"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":47659809482736.0,"prompt":"[img=36x36]res://assets/ui/input_prompts/keyboard_e.png[/img]   Take Good Candy","viewer_id":47659809482736.0,"viewer_position":[-300.0,32.271728515625,180.0]},"interaction_winner":{"class":"Node3D","name":"Interactable"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_radius_m":2.5,"revived |
| 9 | 1 | probe downed — trainer vitals on arrival | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":100.0,"hold_peer":0.0,"hold_s":0.0,"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":47553089486412.0,"prompt":"[img=36x36]res://assets/ui/input_prompts/keyboard_e.png[/img]   Take Good Candy","viewer_id":47553089486412.0,"viewer_position":[-300.0,32.271728515625,180.0]},"interaction_winner":{"class":"Node3D","name":"Interactable"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_radius_m":2.5,"revived":0.0,"satchel_nodes":0.0,"satchels":0.0,"stamina":100.0,"window_s":45.0} |
| 10 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to shared/waterward/peer-0/before |
| 10 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-661649581c52a618dec4cb84bb9efc2d' on disk=true; copied 1 files to shared/waterward/peer-1/before |
| 11 | 0 | stormheart_fixture — both fought the Dynamo (setup) | PASS | PASS | Dynamo contributors [1, 49127255]; committed ["stormwood:act_ii_complete", "stormwood:marrow_defeated"] |
| 12 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 12 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 31 frames |
| 13 | 0 | stormheart_answer — host says Yes | PASS + {"has_stormheart":true} | PASS | party holds the Stormheart=true; claim settled=true; answered accept by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 3 earlier line(s) and 3 offer line(s) |
| 14 | 1 | stormheart_answer — guest says No | PASS + {"has_stormheart":false} | PASS | party holds the Stormheart=false; claim settled=true; answered refuse by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 3 earlier line(s) and 3 offer line(s) |
| 15 | 0 | wait_flag — the world's offer fact (the view's prerequisite) | PASS | PASS | flag stormwood:legendary_offer_made (any) set after 0 frames |
| 15 | 1 | wait_flag — the world's offer fact (the view's prerequisite) | PASS | PASS | flag stormwood:legendary_offer_made (any) set after 0 frames |
| 16 | 0 | teleport — SETUP: the host stands on the high platform beside the view | PASS | PASS | trainer stands at (-98.00, 262.06, 5487.00) |
| 17 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 18 | 0 | press — the host presses 'Look beyond the broken storm' | PASS | PASS | pressed 'interact' x1 |
| 19 | 0 | wait_flag — the cleared sky is charted for both | PASS | PASS | flag stormwood:waterward_revealed (any) set after 0 frames |
| 19 | 1 | wait_flag — the cleared sky is charted for both | PASS | PASS | flag stormwood:waterward_revealed (any) set after 0 frames |
| 20 | 0 | wait_flag — the one-time Water key exists (before the gate) | PASS | PASS | flag realm_key_water (any) set after 0 frames |
| 20 | 1 | wait_flag — the one-time Water key exists (before the gate) | PASS | PASS | flag realm_key_water (any) set after 0 frames |
| 21 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 22 | 1 | teleport — SETUP: the guest stands at the Waterward gate | PASS | PASS | trainer stands at (-100.00, 262.06, 5498.00) |
| 23 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 24 | 1 | probe input_context — the Stormheart's 3-line aftermath conversation (stormwood_waterward_aftermath) holds the guest's screen | PASS | PASS | "narrative_modal" |
| 25 | 1 | press — the guest reads the 3 aftermath lines with interact (the first attempt's gate press only advanced this dialogue) | PASS | PASS | pressed 'interact' x3 |
| 26 | 1 | wait_context — the conversation is closed: the guest is back in the world context | PASS | PASS | input_context=world after 0 frames |
| 27 | 0 | wait_flag — the gate is still sealed before the guest's gate press (non-vacuous) | FAIL | FAIL | flag realm_gate_water_unlocked (any) never set within 30 frames |
| 27 | 1 | wait_flag — the gate is still sealed before the guest's gate press (non-vacuous) | FAIL | FAIL | flag realm_gate_water_unlocked (any) never set within 30 frames |
| 28 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 29 | 1 | press — the guest presses 'Unlock the way to Tidewake' once | PASS | PASS | pressed 'interact' x1 |
| 30 | 0 | wait_flag — the gate is open for both peers | PASS | PASS | flag realm_gate_water_unlocked (any) set after 0 frames |
| 30 | 1 | wait_flag — the gate is open for both peers | PASS | PASS | flag realm_gate_water_unlocked (any) set after 0 frames |
| 31 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 32 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to shared/waterward/peer-0/opened |
| 32 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-661649581c52a618dec4cb84bb9efc2d' on disk=true; copied 1 files to shared/waterward/peer-1/opened |
| 33 | 0 | save_reload_here — RELOAD: host autosave + load_slot in place | PASS | PASS | host slot reload preserved party=true selection=true hosted_world=true |
| 34 | 1 | save_reload_here — RELOAD: guest character save + apply from disk | PASS | PASS | client character reload preserved party=true selection=true hosted_world=true |
| 35 | 0 | wait_flag — after the reload the gate is still open on both peers | PASS | PASS | flag realm_gate_water_unlocked (any) set after 0 frames |
| 35 | 1 | wait_flag — after the reload the gate is still open on both peers | PASS | PASS | flag realm_gate_water_unlocked (any) set after 0 frames |
| 36 | 0 | wait_flag — after the reload the charted sky persists on both | PASS | PASS | flag stormwood:waterward_revealed (any) set after 0 frames |
| 36 | 1 | wait_flag — after the reload the charted sky persists on both | PASS | PASS | flag stormwood:waterward_revealed (any) set after 0 frames |
| 37 | 0 | probe downed — trainer vitals at the end | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":100.0,"hold_peer":0.0,"hold_s":0.0,"host_authority_attempts":[],"host_views":{"1":{"body_id":47659809482736.0,"position":[-98.0,262.059173583984,5487.0],"realm":"stormwood","valid":true},"49127255":{"body_id":50751850184823.0,"position":[-100.0,262.060089111328,5498.0],"realm":"stormwood","valid":true}},"interaction_arbiter":{"enabled":true,"input_context":"narrative_modal","local_player_id":47659809482736.0,"prompt":"Waterward route charted","viewer_id":47659809482736.0,"viewer_position":[-98.0,262.059173583984,5487.0]},"interaction_winner":{"class":"Node3D","name":"WaterwardView"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_radius_m":2.5,"revived":0.0,"satchel_nodes":0.0,"satchels":0.0, |
| 37 | 1 | probe downed — trainer vitals at the end | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":100.0,"hold_peer":0.0,"hold_s":0.0,"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":47553089486412.0,"prompt":"[img=36x36]res://assets/ui/input_prompts/xbox_button_x.png[/img]   Enter Tidewake","viewer_id":47553089486412.0,"viewer_position":[-100.0,262.059722900391,5498.0]},"interaction_winner":{"class":"Node3D","name":"Interactable"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_radius_m":2.5,"revived":0.0,"satchel_nodes":0.0,"satchels":0.0,"stamina":100.0,"window_s":45.0} |
| 38 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 38 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 39 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to shared/waterward/peer-0/after |
| 39 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-661649581c52a618dec4cb84bb9efc2d' on disk=true; copied 1 files to shared/waterward/peer-1/after |
| 40 | 0 | check_saved — baseline: the host's pre-offer world has no Water key, no open gate | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under before/worlds |
| 41 | 0 | check_saved — the host's saved world holds the open gate | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under opened/worlds |
| 42 | 0 | check_saved — after the reload the host's saved world: gate open, the one-time key consumed (no quoted realm_key_water flag) | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under after/worlds |

## Captured files

- `peer-0/after/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/worlds/slot-0/world.json`
- `peer-0/before/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/before/saves/slot_0.json`
- `peer-0/before/worlds/slot-0/world.json`
- `peer-0/opened/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/opened/saves/slot_0.json`
- `peer-0/opened/worlds/slot-0/world.json`
- `peer-1/after/characters/character-661649581c52a618dec4cb84bb9efc2d/character.json`
- `peer-1/before/characters/character-661649581c52a618dec4cb84bb9efc2d/character.json`
- `peer-1/opened/characters/character-661649581c52a618dec4cb84bb9efc2d/character.json`
