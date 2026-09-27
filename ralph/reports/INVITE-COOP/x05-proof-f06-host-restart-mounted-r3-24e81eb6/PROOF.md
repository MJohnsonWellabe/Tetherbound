# Two-peer proof: F06#5: a host saves while its guest is mounted mid-flight, restarts and reloads; the guest rejoins with the same five and the closed gate holds

**Verdict: FAIL** (exit 1)

Scenario: `tools/net/proof_scenarios/f06_cloudreach_host_restart_mounted_save.json`  
Run: `net-20260926T230227Z-3132`  
Rendered: no (headless)

ACCEPTANCE F06 'save/reload and two-peer rejoin do not bypass a closed gate or lose an owned creature', co-op half (F06#5): the save is made while the guest is mounted and the reload happens mid-flight. The guest's own world has Cloudreach's upper counterweight route OPEN; the host's world has it CLOSED. In the host's session the guest launches on its galecrest at the gate's legal side; while it is in the air its own portable character is written and the HOST saves its world. The host's Godot process then ends and a fresh one starts at the title on the same disk (restart_peer), and loads that save through the title's own Load, which hosts. The guest, dropped to the title mid-flight, rejoins through the title's returning route as the same character. Asserted: exactly the same five creature UIDs in the same order (kept in the guest's process across the restart); same character in Cloudreach; on solid ground; not inside sealed Upper Cloudreach; back at its own spot at the gate's legal side (same host world instance); the gate still closed for host and guest and in the host's saved world; the galecrest carries it again. CONTROL: with the host's gate open, the same save-while-mounted, host restart and rejoin bring the guest back past the gate, so the negative check can fail. Setup stand-ins (disclosed): world flags through the ledger (story_flag) stand in for playing to Cloudreach, the Windscar trial and (guest's world only) the windlass; party_grant and fly_setup fill the guest's five; teleport places the guest. Saves, the process restart, the title Load, join, rejoin, flight and snapshots are the game's own code. Loopback ENet: local evidence, not internet/Steam acceptance.

## Failures

- #55 peer 1 fly_launch (CONTROL: the guest launches past the open gate) -> FAIL -- the second airborne Jump did not launch; screen: no SequenceDirector here; nothing holding the screen; launch_blockers() said '', now 'Fly is unavailable while riding or in combat.'

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | boot — each peer boots its own fresh Meadows world | PASS | PASS | booted world (240 settle frames) |
| 1 | 1 | boot — each peer boots its own fresh Meadows world | PASS | PASS | booted world (240 settle frames) |
| 2 | 0 | story_flag — setup: both worlds hold the Cloudreach key | PASS | PASS | realm_key_cloudreach: ok=true pending=false code='' reason='' |
| 2 | 1 | story_flag — setup: both worlds hold the Cloudreach key | PASS | PASS | realm_key_cloudreach: ok=true pending=false code='' reason='' |
| 3 | 0 | story_flag — setup: both worlds finished the Windscar flight trial (the Fly gate) | PASS | PASS | fly_traversal_unlocked: ok=true pending=false code='' reason='' |
| 3 | 1 | story_flag — setup: both worlds finished the Windscar flight trial (the Fly gate) | PASS | PASS | fly_traversal_unlocked: ok=true pending=false code='' reason='' |
| 4 | 1 | story_flag — setup: ONLY the guest's own world has the upper counterweight route open (a leak of its own world would show) | PASS | PASS | cloudreach_upper_route_unlocked: ok=true pending=false code='' reason='' |
| 5 | 1 | party_grant | PASS | PASS | 'bramblebun' at level 20 joined the party (1 member(s)) |
| 6 | 1 | party_grant | PASS | PASS | 'terrapup' at level 20 joined the party (2 member(s)) |
| 7 | 1 | party_grant | PASS | PASS | 'brooktail' at level 20 joined the party (3 member(s)) |
| 8 | 1 | party_grant | PASS | PASS | 'mudsnout' at level 20 joined the party (4 member(s)) |
| 9 | 0 | enter_realm — host enters Cloudreach in its own world | PASS | PASS | crossed 'meadows' -> 'cloudreach' after 263 observed physics frames / 107098 ms (budget 6000 physics frames); current scene is /root/CloudreachCliffs |
| 10 | 1 | enter_realm — guest enters Cloudreach in its own world | PASS | PASS | crossed 'meadows' -> 'cloudreach' after 267 observed physics frames / 109317 ms (budget 6000 physics frames); current scene is /root/CloudreachCliffs |
| 11 | 1 | fly_setup — setup: the guest's fifth creature is its Fly carrier (galecrest) | PASS | PASS | SETUP: fly_traversal_unlocked set, galecrest active, anchor=(0.0, 105.0302, -260.0), screen: no SequenceDirector here; nothing holding the screen, launch site: already clear where it stood (locomotion=true carried=false on_floor=true) |
| 12 | 1 | assert — guest owns five | PASS | PASS | party size 5 (wanted 5) |
| 13 | 0 | host | PASS | PASS | hosting udp/28601 as peer 1 |
| 14 | 0 | assert — host world: the upper gate is CLOSED | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 15 | 1 | join | PASS | PASS | joined 127.0.0.1:28601 as peer 1420797616 after 5 frames; snapshot applied; 2 peer(s) in registry |
| 16 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 16 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 17 | 1 | assert — the joined guest reads the host's closed gate | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 18 | 1 | teleport — setup: the guest stands at the gate's legal (south) side | PASS | PASS | trainer stands at (-104.00, 470.03, 2436.00) |
| 19 | 1 | party_uids — the guest's five creature UIDs before the flight | PASS | PASS | 5 owned: ["creature-48c194d268717e74e272f81a6d15ab02", "creature-e50e5e08a012c7e5cbf180fbe30f9624", "creature-d8ecaff168479ab9e17050c803803b42", "creature-2ee407d8405cefe168e5c9cd3ab30823", "creature-6608d85d2207046d2345dfae66e9ba98"]; kept as 'five' |
| 20 | 1 | fly_launch — MOUNTED: the guest launches on its galecrest at the gate's legal side | PASS | PASS | flying (glide) at y=478.99 on attempt 0 |
| 21 | 1 | probe flying — MOUNTED: flight state as the saves are made | PASS | PASS | {"local":{"anchor":{"accepts":2.0,"anchor":[-104.0,470.109985351562,2436.0],"host_granted":true,"host_validated":true,"last_code":"ok","last_denial":"","pending":false,"proposals":2.0,"realm":"cloudreach","refusals":0.0},"blockers":"","carried":false,"carrier":true,"flying":true,"lockout":{"downed":false,"fighting":false,"pending_build":"","trainer_battle":false},"locomotion":true,"on_floor":false,"species":"galecrest","state":"glide","y":478.8916015625},"remote":{"1":{"carrier":false,"flying":false,"hanging":false,"pos":[0.0,105.030204772949,-260.0],"species":"","state":"","visible":true,"y":105.030204772949}}} |
| 22 | 1 | save_character_here — SAVE WHILE MOUNTED: the guest's own portable character is written mid-flight | PASS | PASS | character 'character-592404de9c35a62410b12f823875b1cb' is on disk (wrote_world=false) |
| 23 | 0 | save_character_here — SAVE WHILE MOUNTED: the HOST saves its world while the guest is mid-flight | PASS | PASS | character 'character-317b11dc5a189456699f576519485663' is on disk (wrote_world=true) |
| 24 | 1 | probe flying — MOUNTED: still flying when the host goes down | PASS | PASS | {"local":{"anchor":{"accepts":2.0,"anchor":[-104.0,470.109985351562,2436.0],"host_granted":true,"host_validated":true,"last_code":"ok","last_denial":"","pending":false,"proposals":2.0,"realm":"cloudreach","refusals":0.0},"blockers":"","carried":false,"carrier":true,"flying":true,"lockout":{"downed":false,"fighting":false,"pending_build":"","trainer_battle":false},"locomotion":true,"on_floor":false,"species":"galecrest","state":"glide","y":478.325073242188},"remote":{"1":{"carrier":false,"flying":false,"hanging":false,"pos":[0.0,105.030204772949,-260.0],"species":"","state":"","visible":true,"y":105.030204772949}}} |
| 25 | 1 | probe position — MOUNTED: the guest's mid-flight position | PASS | PASS | [-104.0,478.291748046875,2436.0] |
| 26 | 0 | restart_peer — RELOAD: the HOST's process ends and a fresh one starts at the title on the same disk (memory gone; only its saves survive) | PASS | PASS | peer 0 process 3154 ended (graceful quit=true); fresh process 3703 on the same home booted 'title' and said hello |
| 27 | 1 | await_probe — RELOAD: the guest, mid-flight when its host went down, is back at the title | PASS | PASS | input_context. == title after 0 polls |
| 28 | 0 | title_load — RELOAD: the host loads the save it made while the guest was mounted (the title's own Load, which hosts) | PASS | PASS | title Load slot 0 -> /root/CloudreachCliffs (realm 'cloudreach'), hosting on port 28601 after 8 frames |
| 29 | 0 | assert — RELOAD: the reloaded host world's upper gate is still closed | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 30 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-317b11dc5a189456699f576519485663' on disk=true; copied 3 files to f06/peer-0/saved_mid_flight |
| 30 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-592404de9c35a62410b12f823875b1cb' on disk=true; copied 3 files to f06/peer-1/saved_mid_flight |
| 31 | 0 | check_saved — the host's save made while the guest was mounted: gate closed | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under saved_mid_flight/worlds |
| 32 | 1 | check_saved — the guest's character saved mid-flight: in Cloudreach, carrier owned | PASS | PASS | missing []; unexpectedly present []; read ["character-592404de9c35a62410b12f823875b1cb/character.json"] under saved_mid_flight/characters |
| 33 | 1 | production_join — REJOIN: the guest rejoins from the title as the same character (returning route) | PASS | PASS | title returning entry built 'CloudreachCliffs' first, then JoinDriver joined 127.0.0.1:28601 as peer 1031347184 after 30 frames |
| 34 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 34 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 35 | 1 | wait | PASS | PASS | waited 120 physics frames |
| 36 | 1 | probe flying — REJOIN: flight state after the rejoin | PASS | PASS | {"local":{"anchor":{"accepts":1.0,"anchor":[-104.0,470.109985351562,2436.0],"host_granted":true,"host_validated":true,"last_code":"ok","last_denial":"The wind put you down somewhere else.","pending":false,"proposals":2.0,"realm":"cloudreach","refusals":1.0},"blockers":"","carried":false,"carrier":false,"flying":false,"lockout":{"downed":false,"fighting":false,"pending_build":"","trainer_battle":false},"locomotion":true,"on_floor":true,"species":"","state":"grounded","y":470.030090332031},"remote":{"1":{"carrier":false,"flying":false,"hanging":false,"pos":[0.0,105.030204772949,-260.0],"species":"","state":"","visible":true,"y":105.030204772949}}} |
| 37 | 1 | fly_land — REJOIN: the guest is on solid ground (not stuck mounted in the void) | PASS | PASS | already grounded |
| 38 | 1 | party_uids — REJOIN: exactly the same five creature UIDs, same order (no lost, duplicated or swapped carrier) | PASS | PASS | 5 owned: ["creature-48c194d268717e74e272f81a6d15ab02", "creature-e50e5e08a012c7e5cbf180fbe30f9624", "creature-d8ecaff168479ab9e17050c803803b42", "creature-2ee407d8405cefe168e5c9cd3ab30823", "creature-6608d85d2207046d2345dfae66e9ba98"]; exactly the 'five' list |
| 39 | 1 | probe player_identity — REJOIN: same character, in Cloudreach, five owned | PASS + {"character_id":"character-592404de9c35a62410b12f823875b1cb","party_size":5.0,"realm":"cloudreach"} | PASS | {"appearance_id":"trainer","body":{"exists":true,"in_current_scene":true,"model_appearance_id":"trainer","model_exists":true,"model_has_art":true,"model_requested_appearance_id":"","position":[-104.0,470.030090332031,2436.0]},"character_id":"character-592404de9c35a62410b12f823875b1cb","display_name":"","inside_grandpas_village":false,"party":["bramblebun@20","terrapup@20","brooktail@20","mudsnout@20","galecrest@1"],"party_names":["","","","",""],"party_size":5.0,"party_uids":["creature-48c194d268717e74e272f81a6d15ab02","creature-e50e5e08a012c7e5cbf180fbe30f9624","creature-d8ecaff168479ab9e17050c803803b42","creature-2ee407d8405cefe168e5c9cd3ab30823","creature-6608d85d2207046d2345dfae66e9ba98"],"realm":"cloudreach"} |
| 40 | 1 | probe position — REJOIN: position after the rejoin | PASS | PASS | [-104.0,470.030090332031,2436.0] |
| 41 | 1 | assert — REJOIN: NOT inside sealed Upper Cloudreach | FAIL | FAIL | 1483.82 m from (-400.0, 3890.0), wanted within 40.00 |
| 42 | 1 | assert — REJOIN: back at its own spot at the gate's legal side (same host world instance: owner ruling 'rejoin returns to exact spot') | PASS | PASS | 0.00 m from (-104.0, 2436.0), wanted within 25.00 |
| 43 | 1 | assert — REJOIN: the guest reads the reloaded host's closed gate (its own world's open flag did not leak) | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 44 | 0 | assert — REJOIN: host world flags unchanged | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 45 | 1 | fly_launch — REJOIN: the same galecrest carries it again | PASS | PASS | flying (glide) at y=478.99 on attempt 0 |
| 46 | 1 | fly_land — REJOIN: and lands | PASS | PASS | landed at (-104.00, 470.03, 2436.00); anchor report {"accepts":2,"anchor":[-104.0,470.109985351562,2436.0],"host_granted":true,"host_validated":true,"last_code":"ok","last_denial":"","pending":false,"proposals":3,"realm":"cloudreach","refusals":1} |
| 47 | 1 | party_uids — REJOIN: still exactly the same five after flying again | PASS | PASS | 5 owned: ["creature-48c194d268717e74e272f81a6d15ab02", "creature-e50e5e08a012c7e5cbf180fbe30f9624", "creature-d8ecaff168479ab9e17050c803803b42", "creature-2ee407d8405cefe168e5c9cd3ab30823", "creature-6608d85d2207046d2345dfae66e9ba98"]; exactly the 'five' list |
| 48 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-317b11dc5a189456699f576519485663' on disk=true; copied 3 files to f06/peer-0/after_rejoin |
| 48 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-592404de9c35a62410b12f823875b1cb' on disk=true; copied 3 files to f06/peer-1/after_rejoin |
| 49 | 0 | check_saved — the host's saved world after the rejoin: gate still closed | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under after_rejoin/worlds |
| 50 | 0 | story_flag — CONTROL setup: the host opens the gate | PASS | PASS | cloudreach_upper_route_unlocked: ok=true pending=false code='' reason='' |
| 51 | 1 | wait_flag | PASS | PASS | flag cloudreach_upper_route_unlocked (any) set after 0 frames |
| 52 | 1 | teleport — CONTROL setup: the guest stands past the now-open gate | PASS | PASS | trainer stands at (-400.00, 780.03, 3890.00) |
| 53 | 1 | probe downed — DIAG: the guest can still move after the control teleport (before any launch attempt) | PASS + {"locomotion":true} | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":98.9212337477344,"hold_peer":0.0,"hold_s":0.0,"interaction_arbiter":{"enabled":true,"input_context":"build_catalogue","local_player_id":119654047684345.0,"prompt":"[img=36x36]res://assets/ui/input_prompts/xbox_rb.png[/img]   Call out Bramblebun","viewer_id":119654047684345.0,"viewer_position":[-400.0,780.030639648438,3890.0]},"interaction_winner":{"class":"Node","name":"EncounterDirector"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_radius_m":2.5,"revived":0.0,"satchel_nodes":0.0,"satchels":0.0,"stamina":100.0,"window_s":45.0} |
| 54 | 1 | probe flying — DIAG: flight and landing-anchor state just before the control launch | any | PASS | {"local":{"anchor":{"accepts":3.0,"anchor":[-400.0,780.110046386719,3890.0],"host_granted":true,"host_validated":true,"last_code":"ok","last_denial":"","pending":false,"proposals":4.0,"realm":"cloudreach","refusals":1.0},"blockers":"","carried":false,"carrier":false,"flying":false,"lockout":{"downed":false,"fighting":false,"pending_build":"","trainer_battle":false},"locomotion":true,"on_floor":true,"species":"","state":"grounded","y":780.030639648438},"remote":{"1":{"carrier":false,"flying":false,"hanging":false,"pos":[0.0,105.030204772949,-260.0],"species":"","state":"","visible":true,"y":105.030204772949}}} |
| 55 | 1 | fly_launch — CONTROL: the guest launches past the open gate | PASS | FAIL **(unexpected)** | the second airborne Jump did not launch; screen: no SequenceDirector here; nothing holding the screen; launch_blockers() said '', now 'Fly is unavailable while riding or in combat.' |

## Captured files

- `peer-0/after_rejoin/characters/character-317b11dc5a189456699f576519485663/character.json`
- `peer-0/after_rejoin/saves/slot_0.json`
- `peer-0/after_rejoin/worlds/slot-0/world.json`
- `peer-0/saved_mid_flight/characters/character-317b11dc5a189456699f576519485663/character.json`
- `peer-0/saved_mid_flight/saves/slot_0.json`
- `peer-0/saved_mid_flight/worlds/slot-0/world.json`
- `peer-1/after_rejoin/characters/character-592404de9c35a62410b12f823875b1cb/character.json`
- `peer-1/after_rejoin/saves/slot_0.json`
- `peer-1/after_rejoin/worlds/slot-0/world.json`
- `peer-1/saved_mid_flight/characters/character-592404de9c35a62410b12f823875b1cb/character.json`
- `peer-1/saved_mid_flight/saves/slot_0.json`
- `peer-1/saved_mid_flight/worlds/slot-0/world.json`

---
X05 note: local run (4 vCPU) in a worktree pinned to 24e81eb66f0c70a0f1d0d01d32fd9bd7146c6ee9, with option B (the proof runner's 150 s production_join allowance). Rows 1–54 PASS, including row 33, the rejoin that failed at 90 s in r2 (17, 29, 41, 43, 44 are the scenario's expected FAILs). Row 55 (CONTROL fly_launch) FAIL. Root cause from the DIAG rows 53–54: the guest is grounded, locomotion on, landing anchor host-granted, no launch blocker, but `input_context` is `build_catalogue`: the REJOIN `fly_land` (row 46) held `fly_descend`, whose controller binding (left trigger, axis 4) is also `build_shortcut`'s, so the build catalogue opened and owns input, swallowing the launch Jump. Product defect reported on #292; the scenario now closes the catalogue with `build_cancel` before the control launch. 0 SCRIPT ERROR. Loopback ENet only.
