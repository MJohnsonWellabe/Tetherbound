# Two-peer proof: F06#5: a host saves while its guest is mounted mid-flight, restarts and reloads; the guest rejoins with the same five and the closed gate holds

**Verdict: FAIL** (exit 2)

Scenario: `tools/net/proof_scenarios/f06_cloudreach_host_restart_mounted_save.json`  
Run: `net-20260926T221512Z-3223`  
Rendered: no (headless)

ACCEPTANCE F06 'save/reload and two-peer rejoin do not bypass a closed gate or lose an owned creature', co-op half (F06#5): the save is made while the guest is mounted and the reload happens mid-flight. The guest's own world has Cloudreach's upper counterweight route OPEN; the host's world has it CLOSED. In the host's session the guest launches on its galecrest at the gate's legal side; while it is in the air its own portable character is written and the HOST saves its world. The host's Godot process then ends and a fresh one starts at the title on the same disk (restart_peer), and loads that save through the title's own Load, which hosts. The guest, dropped to the title mid-flight, rejoins through the title's returning route as the same character. Asserted: exactly the same five creature UIDs in the same order (kept in the guest's process across the restart); same character in Cloudreach; on solid ground; not inside sealed Upper Cloudreach; back at its own spot at the gate's legal side (same host world instance); the gate still closed for host and guest and in the host's saved world; the galecrest carries it again. CONTROL: with the host's gate open, the same save-while-mounted, host restart and rejoin bring the guest back past the gate, so the negative check can fail. Setup stand-ins (disclosed): world flags through the ledger (story_flag) stand in for playing to Cloudreach, the Windscar trial and (guest's world only) the windlass; party_grant and fly_setup fill the guest's five; teleport places the guest. Saves, the process restart, the title Load, join, rejoin, flight and snapshots are the game's own code. Loopback ENet: local evidence, not internet/Steam acceptance.

## Failures

- #33 peer 1 production_join (REJOIN: the guest rejoins from the title as the same character (returning route)) -> ERROR -- ERROR: peer silent (peer 1, no heartbeat for >15 s)
- ERROR: peer silent (peer 1, no heartbeat for >15 s)

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
| 9 | 0 | enter_realm — host enters Cloudreach in its own world | PASS | PASS | crossed 'meadows' -> 'cloudreach' after 265 observed physics frames / 111404 ms (budget 6000 physics frames); current scene is /root/CloudreachCliffs |
| 10 | 1 | enter_realm — guest enters Cloudreach in its own world | PASS | PASS | crossed 'meadows' -> 'cloudreach' after 267 observed physics frames / 110181 ms (budget 6000 physics frames); current scene is /root/CloudreachCliffs |
| 11 | 1 | fly_setup — setup: the guest's fifth creature is its Fly carrier (galecrest) | PASS | PASS | SETUP: fly_traversal_unlocked set, galecrest active, anchor=(0.0, 105.0302, -260.0), screen: no SequenceDirector here; nothing holding the screen, launch site: already clear where it stood (locomotion=true carried=false on_floor=true) |
| 12 | 1 | assert — guest owns five | PASS | PASS | party size 5 (wanted 5) |
| 13 | 0 | host | PASS | PASS | hosting udp/30161 as peer 1 |
| 14 | 0 | assert — host world: the upper gate is CLOSED | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 15 | 1 | join | PASS | PASS | joined 127.0.0.1:30161 as peer 1920926357 after 5 frames; snapshot applied; 2 peer(s) in registry |
| 16 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 16 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 17 | 1 | assert — the joined guest reads the host's closed gate | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 18 | 1 | teleport — setup: the guest stands at the gate's legal (south) side | PASS | PASS | trainer stands at (-104.00, 470.03, 2436.00) |
| 19 | 1 | party_uids — the guest's five creature UIDs before the flight | PASS | PASS | 5 owned: ["creature-9589b8247c36e71d31bb5d161ff94cb2", "creature-bde4fbebd3803db807acffd9d13a63cf", "creature-010fd45a25fd3a8f8d693d7c8351d325", "creature-d2dadc6ff143c4e53cc8af30e94e8c5c", "creature-8ebc2c30bc56647dd75697e05465c5bb"]; kept as 'five' |
| 20 | 1 | fly_launch — MOUNTED: the guest launches on its galecrest at the gate's legal side | PASS | PASS | flying (glide) at y=478.99 on attempt 0 |
| 21 | 1 | probe flying — MOUNTED: flight state as the saves are made | PASS | PASS | {"local":{"anchor":{"accepts":2.0,"anchor":[-104.0,470.109985351562,2436.0],"host_granted":true,"host_validated":true,"last_code":"ok","last_denial":"","pending":false,"proposals":2.0,"realm":"cloudreach","refusals":0.0},"blockers":"","carried":false,"carrier":true,"flying":true,"lockout":{"downed":false,"fighting":false,"pending_build":"","trainer_battle":false},"locomotion":true,"on_floor":false,"species":"galecrest","state":"glide","y":478.958251953125},"remote":{"1":{"carrier":false,"flying":false,"hanging":false,"pos":[0.0,105.030204772949,-260.0],"species":"","state":"","visible":true,"y":105.030204772949}}} |
| 22 | 1 | save_character_here — SAVE WHILE MOUNTED: the guest's own portable character is written mid-flight | PASS | PASS | character 'character-4f16e404d6f57a6fdfea0bde47cbe52f' is on disk (wrote_world=false) |
| 23 | 0 | save_character_here — SAVE WHILE MOUNTED: the HOST saves its world while the guest is mid-flight | PASS | PASS | character 'character-f60f2520ef9097ab6e857faac4f3451e' is on disk (wrote_world=true) |
| 24 | 1 | probe flying — MOUNTED: still flying when the host goes down | PASS | PASS | {"local":{"anchor":{"accepts":2.0,"anchor":[-104.0,470.109985351562,2436.0],"host_granted":true,"host_validated":true,"last_code":"ok","last_denial":"","pending":false,"proposals":2.0,"realm":"cloudreach","refusals":0.0},"blockers":"","carried":false,"carrier":true,"flying":true,"lockout":{"downed":false,"fighting":false,"pending_build":"","trainer_battle":false},"locomotion":true,"on_floor":false,"species":"galecrest","state":"glide","y":478.125122070312},"remote":{"1":{"carrier":false,"flying":false,"hanging":false,"pos":[0.0,105.030204772949,-260.0],"species":"","state":"","visible":true,"y":105.030204772949}}} |
| 25 | 1 | probe position — MOUNTED: the guest's mid-flight position | PASS | PASS | [-104.0,478.091796875,2436.0] |
| 26 | 0 | restart_peer — RELOAD: the HOST's process ends and a fresh one starts at the title on the same disk (memory gone; only its saves survive) | PASS | PASS | peer 0 process 3245 ended (graceful quit=true); fresh process 4134 on the same home booted 'title' and said hello |
| 27 | 1 | await_probe — RELOAD: the guest, mid-flight when its host went down, is back at the title | PASS | PASS | input_context. == title after 0 polls |
| 28 | 0 | title_load — RELOAD: the host loads the save it made while the guest was mounted (the title's own Load, which hosts) | PASS | PASS | title Load slot 0 -> /root/CloudreachCliffs (realm 'cloudreach'), hosting on port 30161 after 8 frames |
| 29 | 0 | assert — RELOAD: the reloaded host world's upper gate is still closed | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 30 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f60f2520ef9097ab6e857faac4f3451e' on disk=true; copied 3 files to f06/peer-0/saved_mid_flight |
| 30 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-4f16e404d6f57a6fdfea0bde47cbe52f' on disk=true; copied 3 files to f06/peer-1/saved_mid_flight |
| 31 | 0 | check_saved — the host's save made while the guest was mounted: gate closed | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under saved_mid_flight/worlds |
| 32 | 1 | check_saved — the guest's character saved mid-flight: in Cloudreach, carrier owned | PASS | PASS | missing []; unexpectedly present []; read ["character-4f16e404d6f57a6fdfea0bde47cbe52f/character.json"] under saved_mid_flight/characters |
| 33 | 1 | production_join — REJOIN: the guest rejoins from the title as the same character (returning route) | PASS | ERROR **(unexpected)** | ERROR: peer silent (peer 1, no heartbeat for >15 s) |

## Captured files

- `peer-0/saved_mid_flight/characters/character-f60f2520ef9097ab6e857faac4f3451e/character.json`
- `peer-0/saved_mid_flight/saves/slot_0.json`
- `peer-0/saved_mid_flight/worlds/slot-0/world.json`
- `peer-1/saved_mid_flight/characters/character-4f16e404d6f57a6fdfea0bde47cbe52f/character.json`
- `peer-1/saved_mid_flight/saves/slot_0.json`
- `peer-1/saved_mid_flight/worlds/slot-0/world.json`

---
X05 note: local run in a worktree pinned to 22acfc2da4f029325f44fa5b13c9ea6c02a8a59f. Rows 1–32 PASS (17 and 29 are the scenario's expected FAILs): setup, mid-flight saves, host restart, host title_load, closed gate after reload, both saved-file checks. FAIL at row 33 (`production_join` rejoin): the harness's 90 s production_join heartbeat allowance (net_harness.gd WORLD_BUILD_ALLOWANCE_S) is shorter than a Cloudreach build on this 4-vCPU box (~110 s: rows 9–10 took 111 404 ms and 110 181 ms under enter_realm's 150 s). Not hung. Raising the allowance awaits the coordinator (#292). 0 SCRIPT ERROR; engine errors from fly_controller.gd:853 make_carrier_art (!is_inside_tree) reported to the Cloudreach lane. Loopback ENet only.
