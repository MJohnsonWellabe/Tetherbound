# Two-peer proof: F08 #2: guest Veyra win journaled once in the host world, through drop and rejoin

**Verdict: FAIL** (exit 1)

Scenario: `tests/smoke_net_cloudreach_veyra_reconnect.gd`  
Run: `net-20260926T053151Z-3019`  
Rendered: no (headless)

ACCEPTANCE F08: Veyra's win persists through two-peer reconnect without double grants; a client-run trainer win goes through the host-journaled trainer_victory route and never a local world-flag write.

## Failures

- #30 peer 1 veyra_client_win (REJOIN: a repeat win after rejoin asks the host nothing and announces nothing) -> FAIL; data did not match {"had_flag":true,"local_flag_same_frame":true,"sent_to_host":false,"victory_emits":0,"world_store_writes_same_frame":0} -- no Game or no Cloudreach EncounterDirector in scene 'TitleScreen'

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | boot — each peer boots its own fresh Meadows world | PASS | PASS | booted world (240 settle frames) |
| 1 | 1 | boot — each peer boots its own fresh Meadows world | PASS | PASS | booted world (240 settle frames) |
| 2 | 0 | story_flag — setup: both worlds hold the Cloudreach key | PASS | PASS | realm_key_cloudreach: ok=true pending=false code='' reason='' |
| 2 | 1 | story_flag — setup: both worlds hold the Cloudreach key | PASS | PASS | realm_key_cloudreach: ok=true pending=false code='' reason='' |
| 3 | 0 | enter_realm — host enters Cloudreach | PASS | PASS | crossed 'meadows' -> 'cloudreach' after 265 observed physics frames / 308278 ms (budget 6000 physics frames); current scene is /root/CloudreachCliffs |
| 4 | 1 | enter_realm — guest enters Cloudreach in its own world | PASS | PASS | crossed 'meadows' -> 'cloudreach' after 264 observed physics frames / 313286 ms (budget 6000 physics frames); current scene is /root/CloudreachCliffs |
| 5 | 1 | save_character_here — guest saves its portable character in Cloudreach | PASS | PASS | character 'character-0b70dda5e5c127cde33059422c12d0af' is on disk (wrote_world=true) |
| 6 | 0 | host | PASS | PASS | hosting udp/34741 as peer 1 |
| 7 | 1 | production_join — guest continues its own save into the host's world | PASS | PASS | title fresh entry built 'CloudreachCliffs' first, then JoinDriver joined 127.0.0.1:34741 as peer 1840409528 after 35 frames |
| 8 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 8 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 9 | 1 | probe player_identity — guest stands in Cloudreach | PASS + {"realm":"cloudreach"} | PASS | {"appearance_id":"trainer","body":{"exists":true,"in_current_scene":true,"model_appearance_id":"trainer","model_exists":true,"model_has_art":true,"model_requested_appearance_id":"","position":[0.0,105.030204772949,-260.0]},"character_id":"character-0b70dda5e5c127cde33059422c12d0af","display_name":"","inside_grandpas_village":false,"party":[],"party_size":0.0,"realm":"cloudreach"} |
| 10 | 0 | story_flag — setup (host world): Veyra prerequisite cloudreach_act_ii_complete | PASS | PASS | cloudreach_act_ii_complete: ok=true pending=false code='' reason='' |
| 11 | 0 | story_flag — setup (host world): Veyra prerequisite cloudreach_upper_anchors_disabled | PASS | PASS | cloudreach_upper_anchors_disabled: ok=true pending=false code='' reason='' |
| 12 | 0 | story_flag — setup (host world): Veyra prerequisite summit_extraction_engine_reached | PASS | PASS | summit_extraction_engine_reached: ok=true pending=false code='' reason='' |
| 13 | 1 | wait_flag — the guest reads the host's prerequisites | PASS | PASS | flag summit_extraction_engine_reached (world) set after 6 frames |
| 14 | 0 | assert — CONTROL: host world has Veyra unbeaten before the win | FAIL | FAIL | flag captain_veyra_defeated NOT set |
| 15 | 1 | assert — CONTROL: guest reads Veyra unbeaten before the win | FAIL | FAIL | flag captain_veyra_defeated NOT set |
| 17 | 1 | veyra_client_win — NEGATIVE CONTROL: main's unfixed client route (Ila) writes the world flag locally in the same frame | PASS + {"had_flag":false,"local_flag_same_frame":true} | PASS | {"flag":"defeated_cloudreach_ila","had_flag":false,"host":false,"local_flag_same_frame":true,"mode":"base","multi_peer":true,"sent_to_host":true,"trainer":"trainer_ila_lower_ring","victory_emits":0,"world_store_writes_same_frame":1} |
| 18 | 1 | veyra_client_win — guest wins Veyra: one trainer_victory in flight, nothing written locally | PASS + {"had_flag":false,"local_flag_same_frame":false,"sent_to_host":true,"victory_emits":1,"world_store_writes_same_frame":0} | PASS | {"flag":"captain_veyra_defeated","had_flag":false,"host":false,"local_flag_same_frame":false,"mode":"production","multi_peer":true,"sent_to_host":true,"trainer":"captain_veyra_storm_anchor","victory_emits":1,"world_store_writes_same_frame":0} |
| 19 | 1 | wait_flag — Veyra's flag reaches the guest with the host's delta | PASS | PASS | flag captain_veyra_defeated (world) set after 35 frames |
| 20 | 0 | assert — host world holds Veyra's defeat | PASS | PASS | flag captain_veyra_defeated set |
| 22 | 1 | save_character_here — guest saves its portable character | PASS | PASS | character 'character-0b70dda5e5c127cde33059422c12d0af' is on disk (wrote_world=false) |
| 24 | 1 | drop_link — guest's link drops | PASS | PASS | transport closed without a Session.leave() |
| 25 | 0 | expect_peers | PASS | PASS | registry reports 1 peer(s) after 0 frames |
| 26 | 1 | join — guest rejoins (reclaims its held seat) | PASS | PASS | joined 127.0.0.1:34741 as peer 455010785 after 3 frames; snapshot applied; 2 peer(s) in registry |
| 27 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 27 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 28 | 1 | wait_flag — REJOIN: the guest reads Veyra's defeat from the host's world | PASS | PASS | flag captain_veyra_defeated (world) set after 0 frames |
| 29 | 1 | probe player_identity — REJOIN: guest back in Cloudreach | PASS + {"realm":"cloudreach"} | PASS | {"appearance_id":"trainer","body":{"exists":false,"in_current_scene":false,"model_appearance_id":"","model_exists":false,"model_has_art":false,"model_requested_appearance_id":"","position":[]},"character_id":"character-0b70dda5e5c127cde33059422c12d0af","display_name":"","inside_grandpas_village":false,"party":[],"party_size":0.0,"realm":"cloudreach"} |
| 30 | 1 | veyra_client_win — REJOIN: a repeat win after rejoin asks the host nothing and announces nothing | PASS + {"had_flag":true,"local_flag_same_frame":true,"sent_to_host":false,"victory_emits":0,"world_store_writes_same_frame":0} | FAIL **(unexpected)** | no Game or no Cloudreach EncounterDirector in scene 'TitleScreen' |
| 31 | 1 | wait | PASS | PASS | waited 240 physics frames |
| 33 | 1 | save_character_here — guest saves again after the rejoin | PASS | PASS | character 'character-0b70dda5e5c127cde33059422c12d0af' is on disk (wrote_world=false) |
| 35 | 0 | save_world — host saves its world | PASS | PASS | saved slot 3 to user://saves/slot_3.json |
| 36 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-bf069c59326500663fcd88c85df9090d' on disk=true; copied 4 files to /tmp/claude-0/-home-user/a928e74c-55ea-5de6-a21f-37d302e2ef4c/scratchpad/net/net-cloudreach_veyra_reconnect-20260926T053151Z/proof/peer-0/final |
| 36 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-0b70dda5e5c127cde33059422c12d0af' on disk=true; copied 3 files to /tmp/claude-0/-home-user/a928e74c-55ea-5de6-a21f-37d302e2ef4c/scratchpad/net/net-cloudreach_veyra_reconnect-20260926T053151Z/proof/peer-1/final |
| 37 | 0 | check_saved — CONTROL: the host's saved world names Veyra's defeat | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under final/worlds |
| 38 | 1 | check_saved — the guest's saved character holds no copy of the world flag | PASS | PASS | missing []; unexpectedly present []; read ["character-0b70dda5e5c127cde33059422c12d0af/character.json"] under final/characters |

## Captured files

- `NET_RUN.json`
- `SUMMARY.md`
- `home-0/godot/app_userdata/Tetherbound/boot_log.txt`
- `home-0/godot/app_userdata/Tetherbound/cache/map_meadows.png`
- `home-0/godot/app_userdata/Tetherbound/cache/map_meadows.png.key`
- `home-0/godot/app_userdata/Tetherbound/characters/character-bf069c59326500663fcd88c85df9090d/character.json`
- `home-0/godot/app_userdata/Tetherbound/logs/godot.log`
- `home-0/godot/app_userdata/Tetherbound/saves/slot_0.json`
- `home-0/godot/app_userdata/Tetherbound/saves/slot_3.json`
- `home-0/godot/app_userdata/Tetherbound/worlds/slot-0/world.json`
- `home-1/godot/app_userdata/Tetherbound/boot_log.txt`
- `home-1/godot/app_userdata/Tetherbound/cache/map_meadows.png`
- `home-1/godot/app_userdata/Tetherbound/cache/map_meadows.png.key`
- `home-1/godot/app_userdata/Tetherbound/characters/character-0b70dda5e5c127cde33059422c12d0af/character.json`
- `home-1/godot/app_userdata/Tetherbound/logs/godot.log`
- `home-1/godot/app_userdata/Tetherbound/saves/slot_0.json`
- `home-1/godot/app_userdata/Tetherbound/worlds/slot-0/world.json`
- `peer-0.log`
- `peer-1.log`
- `proof/peer-0/final/characters/character-bf069c59326500663fcd88c85df9090d/character.json`
- `proof/peer-0/final/saves/slot_0.json`
- `proof/peer-0/final/saves/slot_3.json`
- `proof/peer-0/final/worlds/slot-0/world.json`
- `proof/peer-1/final/characters/character-0b70dda5e5c127cde33059422c12d0af/character.json`
- `proof/peer-1/final/saves/slot_0.json`
- `proof/peer-1/final/worlds/slot-0/world.json`
