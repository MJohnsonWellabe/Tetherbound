# Two-peer proof: F12: remote rider identity agrees mid-water, before and after a reconnect

**Verdict: FAIL** (exit 1)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/f12_remote_rider_identity_reconnect.json`  
Run: `net-20261011T161737Z-10638`  
Rendered: no (headless)

ACCEPTANCE F12 clause '... dismount/remount, reload and remote rider identity agree'. In Tidewake, the guest rides its Aquaryn into deep water; the host's picture of that rider -- registry row, trainer body (character, nameplate, riding and seated), and the mount carrying it (owner character and peer, authority, species, saddle, mounted swim mode) -- names the same player as the guest's own state. The guest then saves mid-water, loses its link, and comes back through the production returning route with a NEW peer id; the ride is restored and the host's picture agrees again, found by character, with nothing left over from the old peer id. Setup only: the host stands on the first shore (water_fixture) and the guest is given the Aquaryn and tack (water_mount_fixture), standing in for earning them.

## Failures

- #21 peer 1 await_probe (the ride is restored) -> FAIL -- riding.local.mounted was false, not true, after 1800 polls

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | host | PASS | PASS | hosting udp/31881 as peer 1 |
| 2 | 1 | join | PASS | PASS | joined 127.0.0.1:31881 as peer 1065286821 after 10 frames; snapshot applied; 2 peer(s) in registry |
| 3 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 3 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 4 | 0 | water_fixture — setup: host on the first shore | PASS | PASS | SETUP: Water island fixture at (0.0, 1.931176, 162.0); catching level 0 |
| 5 | 1 | water_mount_fixture — setup: guest has its Aquaryn and tack | PASS | PASS | SETUP: water_aquaryn standing as AllyCreature, swim_saddle in the satchel |
| 6 | 1 | ride_mount | PASS | PASS | riding AllyCreature |
| 7 | 1 | water_mounted_swim | PASS | PASS | Started real mounted input from lesson shore to deep offshore point |
| 8 | 1 | await_probe — the mounted swim reaches deep water | PASS | PASS | water_mounted.motion.completed == true after 408 polls |
| 9 | 1 | rider_self — BEFORE: the guest's own ride | PASS + {"character_id":"character-9299b0235a5d7865c4256eb96684d4d0","mount_species":"water_aquaryn","mounted":true,"realm":"water","swim_mode":2.0} | PASS | {"character_id":"character-9299b0235a5d7865c4256eb96684d4d0","mount_species":"water_aquaryn","mounted":true,"peer_id":1065286821,"realm":"water","saddle_worn":true,"swim_mode":2} |
| 10 | 0 | rider_identity — BEFORE: the host's picture of that rider agrees | PASS + {"agree":true,"body_visible_in_scene":true,"mount_species":"water_aquaryn","mount_swim_mode":2.0,"seated":true} | PASS | character character-9299b023: {"agree":true,"bodies":1,"body_peer_id":1065286821,"body_visible_in_scene":true,"mount_authority":1065286821,"mount_owner_peer_id":1065286821,"mount_saddle_worn":true,"mount_species":"water_aquaryn","mount_swim_mode":2,"mount_swim_owner":1065286821,"mounts":1,"nameplate":"Trainer","peer_id":1065286821,"registry_display_name":"Trainer","registry_rows":1,"riding":true,"seated":true,"stale_bodies":0,"stale_mounts":0} |
| 11 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 11 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 12 | 1 | save_character_here — the guest's character is written while mounted mid-water | PASS | PASS | character 'character-9299b0235a5d7865c4256eb96684d4d0' is on disk (wrote_world=false, waited 0 frames for the save fence) |
| 13 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-5be24aa84b236d686f9a969f09933a65' on disk=true; copied 3 files to f12proof/peer-0/before_drop |
| 13 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-9299b0235a5d7865c4256eb96684d4d0' on disk=true; copied 1 files to f12proof/peer-1/before_drop |
| 14 | 1 | check_saved — the saved character carries the ride | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-9299b0235a5d7865c4256eb96684d4d0/character.json"] under before_drop/characters |
| 15 | 1 | drop_link | PASS | PASS | transport closed without a Session.leave() (ENet disconnect sent to 1 peer(s), acknowledged by 1 after 5 frames) |
| 16 | 0 | expect_peers | PASS | PASS | registry reports 1 peer(s) after 0 frames (0.0 s) |
| 17 | 1 | leave — tear down if anything is left (after a dropped link there is no session, as smoke_net_reconnect_keeps_character expects) | any | FAIL | no active session to leave |
| 18 | 1 | wipe_character — the live character is blanked, so the ride must come back from the save | PASS | PASS | in-memory character blanked (party 1 -> 0), id 'character-9299b0235a5d7865c4256eb96684d4d0' kept, file untouched |
| 19 | 1 | production_join | PASS | PASS | title returning entry built 'WaterArchipelago' first, then JoinDriver joined 127.0.0.1:31881 as peer 752335314 after 46 frames |
| 20 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 20 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 21 | 1 | await_probe — the ride is restored | PASS | FAIL **(unexpected)** | riding.local.mounted was false, not true, after 1800 polls |

## Captured files

- `peer-0/before_drop/characters/redesign-v28/character-5be24aa84b236d686f9a969f09933a65/character.json`
- `peer-0/before_drop/saves/redesign-v28/slot_0.json`
- `peer-0/before_drop/worlds/redesign-v28/slot-0/world.json`
- `peer-1/before_drop/characters/redesign-v28/character-9299b0235a5d7865c4256eb96684d4d0/character.json`
