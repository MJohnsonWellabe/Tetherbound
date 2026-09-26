# Two-peer proof: F06#5: a host saves while its guest is mounted mid-flight, restarts and reloads; the guest rejoins with the same five and the closed gate holds

**Verdict: FAIL** (exit 1)

Scenario: `tools/net/proof_scenarios/f06_cloudreach_host_restart_mounted_save.json`  
Run: `net-20260926T220450Z-2092`  
Rendered: no (headless)

ACCEPTANCE F06 'save/reload and two-peer rejoin do not bypass a closed gate or lose an owned creature', co-op half (F06#5): the save is made while the guest is mounted and the reload happens mid-flight. The guest's own world has Cloudreach's upper counterweight route OPEN; the host's world has it CLOSED. In the host's session the guest launches on its galecrest at the gate's legal side; while it is in the air its own portable character is written and the HOST saves its world. The host's Godot process then ends and a fresh one starts at the title on the same disk (restart_peer), and loads that save through the title's own Load, which hosts. The guest, dropped to the title mid-flight, rejoins through the title's returning route as the same character. Asserted: exactly the same five creature UIDs in the same order (kept in the guest's process across the restart); same character in Cloudreach; on solid ground; not inside sealed Upper Cloudreach; back at its own spot at the gate's legal side (same host world instance); the gate still closed for host and guest and in the host's saved world; the galecrest carries it again. CONTROL: with the host's gate open, the same save-while-mounted, host restart and rejoin bring the guest back past the gate, so the negative check can fail. Setup stand-ins (disclosed): world flags through the ledger (story_flag) stand in for playing to Cloudreach, the Windscar trial and (guest's world only) the windlass; party_grant and fly_setup fill the guest's five; teleport places the guest. Saves, the process restart, the title Load, join, rejoin, flight and snapshots are the game's own code. Loopback ENet: local evidence, not internet/Steam acceptance.

## Failures

- #32 peer 1 check_saved (the guest's character saved mid-flight: in Cloudreach, carrier owned) -> ERROR -- unresolved ["$character1"] (no session/character for that peer yet)

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
| 9 | 0 | enter_realm — host enters Cloudreach in its own world | PASS | PASS | crossed 'meadows' -> 'cloudreach' after 265 observed physics frames / 108093 ms (budget 6000 physics frames); current scene is /root/CloudreachCliffs |
| 10 | 1 | enter_realm — guest enters Cloudreach in its own world | PASS | PASS | crossed 'meadows' -> 'cloudreach' after 267 observed physics frames / 107709 ms (budget 6000 physics frames); current scene is /root/CloudreachCliffs |
| 11 | 1 | fly_setup — setup: the guest's fifth creature is its Fly carrier (galecrest) | PASS | PASS | SETUP: fly_traversal_unlocked set, galecrest active, anchor=(0.0, 105.0302, -260.0), screen: no SequenceDirector here; nothing holding the screen, launch site: already clear where it stood (locomotion=true carried=false on_floor=true) |
| 12 | 1 | assert — guest owns five | PASS | PASS | party size 5 (wanted 5) |
| 13 | 0 | host | PASS | PASS | hosting udp/34381 as peer 1 |
| 14 | 0 | assert — host world: the upper gate is CLOSED | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 15 | 1 | join | PASS | PASS | joined 127.0.0.1:34381 as peer 2140178815 after 6 frames; snapshot applied; 2 peer(s) in registry |
| 16 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 16 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 17 | 1 | assert — the joined guest reads the host's closed gate | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 18 | 1 | teleport — setup: the guest stands at the gate's legal (south) side | PASS | PASS | trainer stands at (-104.00, 470.03, 2436.00) |
| 19 | 1 | party_uids — the guest's five creature UIDs before the flight | PASS | PASS | 5 owned: ["creature-134d7922be589720f268cae1aeb29078", "creature-c949feb01cb90281a05141fd93eca887", "creature-04b473ea0a4a69e2ef0a8b88d6fba20f", "creature-d3e29871a56cd4b2017e858384c5d7bd", "creature-27ab3f2bfd94009f08af50c5e028d4b1"]; kept as 'five' |
| 20 | 1 | fly_launch — MOUNTED: the guest launches on its galecrest at the gate's legal side | PASS | PASS | flying (glide) at y=478.99 on attempt 0 |
| 21 | 1 | probe flying — MOUNTED: flight state as the saves are made | PASS | PASS | {"local":{"anchor":{"accepts":2.0,"anchor":[-104.0,470.109985351562,2436.0],"host_granted":true,"host_validated":true,"last_code":"ok","last_denial":"","pending":false,"proposals":2.0,"realm":"cloudreach","refusals":0.0},"blockers":"","carried":false,"carrier":true,"flying":true,"lockout":{"downed":false,"fighting":false,"pending_build":"","trainer_battle":false},"locomotion":true,"on_floor":false,"species":"galecrest","state":"glide","y":478.958251953125},"remote":{"1":{"carrier":false,"flying":false,"hanging":false,"pos":[0.0,105.030204772949,-260.0],"species":"","state":"","visible":true,"y":105.030204772949}}} |
| 22 | 1 | save_character_here — SAVE WHILE MOUNTED: the guest's own portable character is written mid-flight | PASS | PASS | character 'character-d2f6e9cd7f136690dcdfbfddd1a33ab5' is on disk (wrote_world=false) |
| 23 | 0 | save_character_here — SAVE WHILE MOUNTED: the HOST saves its world while the guest is mid-flight | PASS | PASS | character 'character-2050a62a835bf575c0f898b1ebc72f5d' is on disk (wrote_world=true) |
| 24 | 1 | probe flying — MOUNTED: still flying when the host goes down | PASS | PASS | {"local":{"anchor":{"accepts":2.0,"anchor":[-104.0,470.109985351562,2436.0],"host_granted":true,"host_validated":true,"last_code":"ok","last_denial":"","pending":false,"proposals":2.0,"realm":"cloudreach","refusals":0.0},"blockers":"","carried":false,"carrier":true,"flying":true,"lockout":{"downed":false,"fighting":false,"pending_build":"","trainer_battle":false},"locomotion":true,"on_floor":false,"species":"galecrest","state":"glide","y":478.391723632812},"remote":{"1":{"carrier":false,"flying":false,"hanging":false,"pos":[0.0,105.030204772949,-260.0],"species":"","state":"","visible":true,"y":105.030204772949}}} |
| 25 | 1 | probe position — MOUNTED: the guest's mid-flight position | PASS | PASS | [-104.0,478.325073242188,2436.0] |
| 26 | 0 | restart_peer — RELOAD: the HOST's process ends and a fresh one starts at the title on the same disk (memory gone; only its saves survive) | PASS | PASS | peer 0 process 2114 ended (graceful quit=true); fresh process 2663 on the same home booted 'title' and said hello |
| 27 | 1 | await_probe — RELOAD: the guest, mid-flight when its host went down, is back at the title | PASS | PASS | input_context. == title after 0 polls |
| 28 | 0 | title_load — RELOAD: the host loads the save it made while the guest was mounted (the title's own Load, which hosts) | PASS | PASS | title Load slot 0 -> /root/CloudreachCliffs (realm 'cloudreach'), hosting on port 34381 after 8 frames |
| 29 | 0 | assert — RELOAD: the reloaded host world's upper gate is still closed | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 30 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-2050a62a835bf575c0f898b1ebc72f5d' on disk=true; copied 3 files to f06/peer-0/saved_mid_flight |
| 30 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-d2f6e9cd7f136690dcdfbfddd1a33ab5' on disk=true; copied 3 files to f06/peer-1/saved_mid_flight |
| 31 | 0 | check_saved — the host's save made while the guest was mounted: gate closed | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under saved_mid_flight/worlds |
| 32 | 1 | check_saved — the guest's character saved mid-flight: in Cloudreach, carrier owned | PASS | ERROR **(unexpected)** | unresolved ["$character1"] (no session/character for that peer yet) |

## Captured files

- `peer-0/saved_mid_flight/characters/character-2050a62a835bf575c0f898b1ebc72f5d/character.json`
- `peer-0/saved_mid_flight/saves/slot_0.json`
- `peer-0/saved_mid_flight/worlds/slot-0/world.json`
- `peer-1/saved_mid_flight/characters/character-d2f6e9cd7f136690dcdfbfddd1a33ab5/character.json`
- `peer-1/saved_mid_flight/saves/slot_0.json`
- `peer-1/saved_mid_flight/worlds/slot-0/world.json`

---
X05 note: local run in a worktree pinned to d445fec206efa0af7772e18b6cca81747200cd36. FAIL at row 32 is a proof-runner defect, not product: `$character1` was learned lazily and the guest was already at the title after the host restart. Fixed in 22acfc2d (see the r2 run). Loopback ENet only.
