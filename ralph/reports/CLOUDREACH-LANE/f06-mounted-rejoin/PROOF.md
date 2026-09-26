# Two-peer proof: F06: two-peer join, rejoin and mounted rejoin do not bypass Cloudreach's closed counterweight gate

**Verdict: PASS** (exit 0)

Scenario: `/home/user/wt-summit/tools/net/proof_scenarios/f06_cloudreach_mounted_rejoin.json`  
Run: `net-f06-20260926T071242Z-15018`  
Rendered: no (headless)

ACCEPTANCE F06: 'two-peer rejoin does not bypass a closed gate or lose an owned creature'. The guest's own world has Cloudreach's upper route open and its portable character is saved past upper_counterweight_gate (in Upper Cloudreach). The host's world has that gate CLOSED (no cloudreach_upper_route_unlocked). (1) JOIN: the guest continues its own save through the title's production join; it must not stand inside sealed Upper Cloudreach, must keep its five, and the host's world flags must not change. (2) REJOIN: at the gate's legal side it leaves and rejoins: same checks, same party ids. (3) MOUNTED REJOIN: it launches on its galecrest, its link drops mid-flight, it rejoins from the title, then lands: sane rider state, same five ids, not inside sealed Upper Cloudreach, no flag change; because the title returning route first loads the guest's own slot-0 (a different world instance from the host's), it stands at the home slot's authored regional spawn (the Cloudreach arrival), not its mid-flight pose, per MULTIPLAYER 'Return-home placement'. (4) CONTROL: the host opens the gate, the guest stands past it, leaves and rejoins and DOES stand past it, so the 'not past the gate' check can fail. Setup stand-ins (disclosed): world flags through the ledger (story_flag) stand in for playing to Cloudreach, the Windscar flight trial and (guest's own world only) the Sky Shrine windlass; party_grant and fly_setup fill the guest's five; teleport places the guest past the gate in its own open world and at the gate's legal side. Saves, loads, join, leave, drop, rejoin, flight and snapshots are the game's own code. Loopback ENet: local evidence, not internet/Steam acceptance.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | boot — each peer boots its own fresh Meadows world | PASS | PASS | booted world (240 settle frames) |
| 1 | 1 | boot — each peer boots its own fresh Meadows world | PASS | PASS | booted world (240 settle frames) |
| 2 | 0 | story_flag — setup: both worlds hold the Cloudreach key | PASS | PASS | realm_key_cloudreach: ok=true pending=false code='' reason='' |
| 2 | 1 | story_flag — setup: both worlds hold the Cloudreach key | PASS | PASS | realm_key_cloudreach: ok=true pending=false code='' reason='' |
| 3 | 0 | story_flag — setup: both worlds finished the Windscar flight trial (the Fly gate, not the counterweight gate) | PASS | PASS | fly_traversal_unlocked: ok=true pending=false code='' reason='' |
| 3 | 1 | story_flag — setup: both worlds finished the Windscar flight trial (the Fly gate, not the counterweight gate) | PASS | PASS | fly_traversal_unlocked: ok=true pending=false code='' reason='' |
| 4 | 1 | story_flag — setup: ONLY the guest's own world has the upper counterweight route open | PASS | PASS | cloudreach_upper_route_unlocked: ok=true pending=false code='' reason='' |
| 5 | 1 | party_grant | PASS | PASS | 'bramblebun' at level 20 joined the party (1 member(s)) |
| 6 | 1 | party_grant | PASS | PASS | 'terrapup' at level 20 joined the party (2 member(s)) |
| 7 | 1 | party_grant | PASS | PASS | 'brooktail' at level 20 joined the party (3 member(s)) |
| 8 | 1 | party_grant | PASS | PASS | 'mudsnout' at level 20 joined the party (4 member(s)) |
| 9 | 0 | enter_realm — host enters Cloudreach in its own world | PASS | PASS | crossed 'meadows' -> 'cloudreach' after 264 observed physics frames / 317553 ms (budget 6000 physics frames); current scene is /root/CloudreachCliffs |
| 10 | 1 | enter_realm — guest enters Cloudreach in its own world | PASS | PASS | crossed 'meadows' -> 'cloudreach' after 268 observed physics frames / 317050 ms (budget 6000 physics frames); current scene is /root/CloudreachCliffs |
| 11 | 1 | fly_setup — setup: guest's fifth creature is its Fly carrier (galecrest) | PASS | PASS | SETUP: fly_traversal_unlocked set, galecrest active, anchor=(0.0, 105.0302, -260.0), screen: no SequenceDirector here; nothing holding the screen, launch site: already clear where it stood (locomotion=true carried=false on_floor=true) |
| 12 | 1 | assert — guest owns five | PASS | PASS | party size 5 (wanted 5) |
| 13 | 1 | teleport — setup: guest stands in Upper Cloudreach, past the gate (open in its own world) | PASS | PASS | trainer stands at (-400.00, 780.03, 3890.00) |
| 14 | 1 | probe position — guest pose in its own world | PASS | PASS | [-400.0,780.030639648438,3890.0] |
| 15 | 1 | assert — baseline: guest IS past the gate in its own world | PASS | PASS | 0.00 m from (-400.0, 3890.0), wanted within 40.00 |
| 16 | 1 | save_character_here — guest saves its own world + portable character past the gate | PASS | PASS | character 'character-9ff3d8b4f951e0bf2cc59465856f99c6' is on disk (wrote_world=true) |
| 17 | 1 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-9ff3d8b4f951e0bf2cc59465856f99c6' on disk=true; copied 3 files to <scratch>/f06v/run7/peer-1/guest_home_past_gate |
| 18 | 1 | check_saved — guest's own saved world has the gate open | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under guest_home_past_gate/worlds |
| 19 | 1 | check_saved — guest's saved character: Cloudreach pose, carrier owned | PASS | PASS | missing []; unexpectedly present []; read ["character-9ff3d8b4f951e0bf2cc59465856f99c6/character.json"] under guest_home_past_gate/characters |
| 20 | 0 | host | PASS | PASS | hosting udp/33381 as peer 1 |
| 21 | 0 | assert — host world: gate CLOSED before the join | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 22 | 1 | production_join — guest continues its own save through the title (world built from its autosave, then JoinDriver dials) | PASS | PASS | title fresh entry built 'CloudreachCliffs' first, then JoinDriver joined 127.0.0.1:33381 as peer 241400630 after 50 frames |
| 23 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 23 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 24 | 1 | probe player_identity — JOIN: guest in Cloudreach, five owned | PASS + {"character_id":"character-9ff3d8b4f951e0bf2cc59465856f99c6","party_size":5.0,"realm":"cloudreach"} | PASS | {"appearance_id":"trainer","body":{"exists":true,"in_current_scene":true,"model_appearance_id":"trainer","model_exists":true,"model_has_art":true,"model_requested_appearance_id":"","position":[-100.0,470.031036376953,2440.0]},"character_id":"character-9ff3d8b4f951e0bf2cc59465856f99c6","display_name":"","inside_grandpas_village":false,"party":["bramblebun@20","terrapup@20","brooktail@20","mudsnout@20","galecrest@1"],"party_size":5.0,"realm":"cloudreach"} |
| 25 | 1 | probe position — JOIN: guest position | PASS | PASS | [-100.0,470.031036376953,2440.0] |
| 26 | 1 | assert — JOIN: guest now reads the host's closed gate | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 27 | 1 | assert — JOIN: guest is NOT standing in sealed Upper Cloudreach | FAIL | FAIL | 1480.71 m from (-400.0, 3890.0), wanted within 40.00 |
| 28 | 0 | assert — JOIN: host world flags unchanged | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 29 | 1 | teleport — setup: guest stands at the gate's legal (south) side | PASS | PASS | trainer stands at (-104.00, 470.03, 2436.00) |
| 30 | 1 | probe position | PASS | PASS | [-104.0,470.030639648438,2436.0] |
| 31 | 1 | save_character_here — guest saves its portable character at the gate | PASS | PASS | character 'character-9ff3d8b4f951e0bf2cc59465856f99c6' is on disk (wrote_world=false) |
| 32 | 1 | probe tournament — party ids before leave | PASS | PASS | {"battle_active":false,"flags":{"recipe_saddle":false,"tournament_quarter_won":false,"tournament_semi_won":false,"tournament_won":false},"party_ids":["creature-36fbcd9a288f0dd5f80021d9f643afa9","creature-098bbe5768c135546b41c7b60a117ea3","creature-5b5a27e5aa1a7c1dde8309e476a3af35","creature-1817710436276494121c7aea121b35da","creature-90eaa2cb6021b67f0f4dcbf48d39b47a"],"ready":false,"selection_ids":[]} |
| 33 | 1 | leave | PASS | PASS | client left cleanly after 0 frames |
| 34 | 0 | expect_peers | PASS | PASS | registry reports 1 peer(s) after 4 frames |
| 35 | 1 | join — guest rejoins | PASS | PASS | joined 127.0.0.1:33381 as peer 51187717 after 6 frames; snapshot applied; 2 peer(s) in registry |
| 36 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 36 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 37 | 1 | probe player_identity — REJOIN: guest in Cloudreach, five owned | PASS + {"character_id":"character-9ff3d8b4f951e0bf2cc59465856f99c6","party_size":5.0,"realm":"cloudreach"} | PASS | {"appearance_id":"trainer","body":{"exists":true,"in_current_scene":true,"model_appearance_id":"trainer","model_exists":true,"model_has_art":true,"model_requested_appearance_id":"","position":[-104.0,470.030639648438,2436.0]},"character_id":"character-9ff3d8b4f951e0bf2cc59465856f99c6","display_name":"","inside_grandpas_village":false,"party":["bramblebun@20","terrapup@20","brooktail@20","mudsnout@20","galecrest@1"],"party_size":5.0,"realm":"cloudreach"} |
| 38 | 1 | probe tournament — REJOIN: party ids after (compare with the row before leave) | PASS | PASS | {"battle_active":false,"flags":{"recipe_saddle":false,"tournament_quarter_won":false,"tournament_semi_won":false,"tournament_won":false},"party_ids":["creature-36fbcd9a288f0dd5f80021d9f643afa9","creature-098bbe5768c135546b41c7b60a117ea3","creature-5b5a27e5aa1a7c1dde8309e476a3af35","creature-1817710436276494121c7aea121b35da","creature-90eaa2cb6021b67f0f4dcbf48d39b47a"],"ready":false,"selection_ids":[]} |
| 39 | 1 | probe position — REJOIN: guest position | PASS | PASS | [-104.0,470.030639648438,2436.0] |
| 40 | 1 | assert — REJOIN: guest is NOT standing in sealed Upper Cloudreach | FAIL | FAIL | 1483.82 m from (-400.0, 3890.0), wanted within 40.00 |
| 41 | 1 | assert — REJOIN: guest stands at the gate's legal side | PASS | PASS | 0.00 m from (-104.0, 2436.0), wanted within 20.00 |
| 42 | 0 | assert — REJOIN: host world flags unchanged | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 43 | 1 | fly_launch — MOUNTED: guest launches on its galecrest at the gate's legal side | PASS | PASS | flying (glide) at y=478.99 on attempt 0 |
| 44 | 1 | probe flying — MOUNTED: guest flight state before the drop | PASS | PASS | {"local":{"anchor":{"accepts":2.0,"anchor":[-104.0,470.109985351562,2436.0],"host_granted":true,"host_validated":true,"last_code":"ok","last_denial":"","pending":false,"proposals":4.0,"realm":"cloudreach","refusals":2.0},"blockers":"","carried":false,"carrier":true,"flying":true,"lockout":{"downed":false,"fighting":false,"pending_build":"","trainer_battle":false},"locomotion":true,"on_floor":false,"species":"galecrest","state":"glide","y":478.958251953125},"remote":{"1":{"carrier":false,"flying":false,"hanging":false,"pos":[0.0,105.030204772949,-260.0],"species":"","state":"","visible":true,"y":105.030204772949}}} |
| 45 | 1 | probe tournament — MOUNTED: party ids before the drop | PASS | PASS | {"battle_active":false,"flags":{"recipe_saddle":false,"tournament_quarter_won":false,"tournament_semi_won":false,"tournament_won":false},"party_ids":["creature-36fbcd9a288f0dd5f80021d9f643afa9","creature-098bbe5768c135546b41c7b60a117ea3","creature-5b5a27e5aa1a7c1dde8309e476a3af35","creature-1817710436276494121c7aea121b35da","creature-90eaa2cb6021b67f0f4dcbf48d39b47a"],"ready":false,"selection_ids":[]} |
| 46 | 1 | drop_link — MOUNTED: guest's link drops mid-flight | PASS | PASS | transport closed without a Session.leave() |
| 47 | 0 | expect_peers | PASS | PASS | registry reports 1 peer(s) after 0 frames |
| 48 | 1 | probe input_context — MOUNTED: the dropped guest is back at the title (Session._on_server_disconnected -> _return_to_title) | PASS | PASS | "title" |
| 49 | 1 | production_join — MOUNTED: guest rejoins from the title as the same character (title _join_via -> JoinDriver; reclaims its held seat) | PASS | PASS | title returning entry built 'CloudreachCliffs' first, then JoinDriver joined 127.0.0.1:33381 as peer 1166566877 after 30 frames |
| 50 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 50 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 51 | 1 | probe flying — MOUNTED: flight state after rejoin | PASS | PASS | {"local":{"anchor":{"accepts":1.0,"anchor":[0.0,106.910209655762,-260.0],"host_granted":true,"host_validated":true,"last_code":"ok","last_denial":"","pending":false,"proposals":1.0,"realm":"cloudreach","refusals":0.0},"blockers":"Find a clear launch with room for your companion overhead.","carried":false,"carrier":false,"flying":false,"lockout":{"downed":false,"fighting":false,"pending_build":"","trainer_battle":false},"locomotion":true,"on_floor":true,"species":"","state":"grounded","y":105.030204772949},"remote":{"1":{"carrier":false,"flying":false,"hanging":false,"pos":[0.0,105.030204772949,-260.0],"species":"","state":"","visible":true,"y":105.030204772949}}} |
| 52 | 1 | fly_land — MOUNTED: guest comes down to solid ground (not stuck mounted in the void) | PASS | PASS | already grounded |
| 53 | 1 | assert — MOUNTED: still five (no lost or duplicated carrier) | PASS | PASS | party size 5 (wanted 5) |
| 54 | 1 | probe player_identity — MOUNTED: identity after landing | PASS + {"character_id":"character-9ff3d8b4f951e0bf2cc59465856f99c6","party_size":5.0,"realm":"cloudreach"} | PASS | {"appearance_id":"trainer","body":{"exists":true,"in_current_scene":true,"model_appearance_id":"trainer","model_exists":true,"model_has_art":true,"model_requested_appearance_id":"","position":[0.0,105.030204772949,-260.0]},"character_id":"character-9ff3d8b4f951e0bf2cc59465856f99c6","display_name":"","inside_grandpas_village":false,"party":["bramblebun@20","terrapup@20","brooktail@20","mudsnout@20","galecrest@1"],"party_size":5.0,"realm":"cloudreach"} |
| 55 | 1 | probe tournament — MOUNTED: party ids after (compare with the row before the drop) | PASS | PASS | {"battle_active":false,"flags":{"recipe_saddle":false,"tournament_quarter_won":false,"tournament_semi_won":false,"tournament_won":false},"party_ids":["creature-36fbcd9a288f0dd5f80021d9f643afa9","creature-098bbe5768c135546b41c7b60a117ea3","creature-5b5a27e5aa1a7c1dde8309e476a3af35","creature-1817710436276494121c7aea121b35da","creature-90eaa2cb6021b67f0f4dcbf48d39b47a"],"ready":false,"selection_ids":[]} |
| 56 | 1 | probe position — MOUNTED: landed position | PASS | PASS | [0.0,105.030204772949,-260.0] |
| 57 | 1 | assert — MOUNTED: guest is NOT inside sealed Upper Cloudreach | FAIL | FAIL | 4169.23 m from (-400.0, 3890.0), wanted within 40.00 |
| 58 | 1 | assert — MOUNTED: guest stands on legal ground at the authored Cloudreach arrival (cloudreach_world.json cloudreach_arrival_from_meadows, (0, 105, -260)): the title returning route loads the guest's own slot-0, whose world instance differs from the host's that the character last stood in, so save_game.gd drops the saved pose for the home slot's authored regional spawn (MULTIPLAYER 'Return-home placement') | PASS | PASS | 0.00 m from (0.0, -260.0), wanted within 5.00 |
| 59 | 0 | assert — MOUNTED: host world flags unchanged | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 60 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-4207d4e6495853c624004ef981a172b3' on disk=true; copied 3 files to <scratch>/f06v/run7/peer-0/after_rejoins |
| 60 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-9ff3d8b4f951e0bf2cc59465856f99c6' on disk=true; copied 3 files to <scratch>/f06v/run7/peer-1/after_rejoins |
| 61 | 0 | check_saved — host's saved world: gate still closed | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under after_rejoins/worlds |
| 62 | 0 | story_flag — CONTROL setup: the host opens the gate | PASS | PASS | cloudreach_upper_route_unlocked: ok=true pending=false code='' reason='' |
| 63 | 1 | wait_flag | PASS | PASS | flag cloudreach_upper_route_unlocked (any) set after 0 frames |
| 64 | 1 | teleport — CONTROL setup: guest stands past the now-open gate | PASS | PASS | trainer stands at (-400.00, 780.03, 3890.00) |
| 65 | 1 | save_character_here | PASS | PASS | character 'character-9ff3d8b4f951e0bf2cc59465856f99c6' is on disk (wrote_world=false) |
| 66 | 1 | leave | PASS | PASS | client left cleanly after 0 frames |
| 67 | 0 | expect_peers | PASS | PASS | registry reports 1 peer(s) after 2 frames |
| 68 | 1 | join — CONTROL: guest rejoins the open world | PASS | PASS | joined 127.0.0.1:33381 as peer 694594052 after 3 frames; snapshot applied; 2 peer(s) in registry |
| 69 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 69 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 70 | 1 | probe player_identity — CONTROL: guest in Cloudreach, five owned | PASS + {"character_id":"character-9ff3d8b4f951e0bf2cc59465856f99c6","party_size":5.0,"realm":"cloudreach"} | PASS | {"appearance_id":"trainer","body":{"exists":true,"in_current_scene":true,"model_appearance_id":"trainer","model_exists":true,"model_has_art":true,"model_requested_appearance_id":"","position":[-400.0,780.030639648438,3890.0]},"character_id":"character-9ff3d8b4f951e0bf2cc59465856f99c6","display_name":"","inside_grandpas_village":false,"party":["bramblebun@20","terrapup@20","brooktail@20","mudsnout@20","galecrest@1"],"party_size":5.0,"realm":"cloudreach"} |
| 71 | 1 | probe position — CONTROL: guest position | PASS | PASS | [-400.0,780.030639648438,3890.0] |
| 72 | 1 | assert — CONTROL: with the gate open the rejoined guest DOES stand past it (the 'not sealed' check can fail) | PASS | PASS | 0.00 m from (-400.0, 3890.0), wanted within 40.00 |

## Captured files

- `peer-0/after_rejoins/characters/character-4207d4e6495853c624004ef981a172b3/character.json`
- `peer-0/after_rejoins/saves/slot_0.json`
- `peer-0/after_rejoins/worlds/slot-0/world.json`
- `peer-1/after_rejoins/characters/character-9ff3d8b4f951e0bf2cc59465856f99c6/character.json`
- `peer-1/after_rejoins/saves/slot_0.json`
- `peer-1/after_rejoins/worlds/slot-0/world.json`
- `peer-1/guest_home_past_gate/characters/character-9ff3d8b4f951e0bf2cc59465856f99c6/character.json`
- `peer-1/guest_home_past_gate/saves/slot_0.json`
- `peer-1/guest_home_past_gate/worlds/slot-0/world.json`

## Reviewer note: #58 placement provenance (appended, not generated)

#58 previously asserted the guest came back at the gate's legal side (-104, 2436) after the mid-flight drop; it stood at (0, 105, -260). Cause, from this run's saves: on drop the client writes its character with the HOST's world instance (`last_world_instance_id` = host `reward_delivery_namespace`, e003a699…), locator `slot-0`. The title's returning route (`title_screen.gd::_begin_join`) first loads the guest's OWN `slot-0` (`reward_delivery_namespace` 0223a0ec…). `save_game.gd` (split load) sees locator equal but instance different and calls `_seat_portable_character_for_slot`, clearing the saved pose so the home slot's authored regional spawn (`cloudreach_world.json` `cloudreach_arrival_from_meadows`, (0, 105, -260)) is used. The join then applies the host snapshot without re-placing the player. That is the MULTIPLAYER "Return-home placement" rule (different provenance -> authored regional spawn), not a placement defect and not a gate bypass. #58 now asserts that spawn explicitly (within 5 m); #57 asserts it is outside sealed Upper Cloudreach.

Open observation (not F06 scope): a guest who has its own local slot-0 never recovers its exact pose on a returning join to the same host, because provenance is judged against the home slot before the host's world instance is known.

Launched with the lane coordinator `tests/smoke_cloudreach_rejoin_closed_gate_proof.gd` (raised heartbeat-silence tolerance). The stock `tools/net/run_two_peer_proof.sh` failed three times at #9 (host Cloudreach build silent > 150 s + 15 s), before any F06 step.
