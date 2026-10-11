# Two-peer proof: F37 Ripplet surface mount, Dive and durable two-peer rejoin

**Verdict: FAIL** (exit 1)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/f37_ripplet_rejoin.json`  
Run: `net-20261011T161455Z-9305`  
Rendered: no (headless)

Pending runtime fixture proof only. Owned Ripplet and L30 breakthrough are explicit pre-admission fixtures. Real Interact/Jump, host admission, replicated carrier identity, disk character save and new-peer returning join. Save restores the mount at the surface with spent stamina and remaining dive debt, per WORLD 6.7. No earned feast, campaign, device or visual acceptance.

## Failures

- #24 peer 1 await_probe (the ride is restored) -> FAIL -- riding.local.mounted was false, not true, after 1800 polls

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 1 | f37_fixture — SETUP before host admission: owned Ripplet and L30 feast record | PASS | PASS | SETUP owned L30 Ripplet and explicit breakthrough fixture before admission |
| 2 | 0 | host | PASS | PASS | hosting udp/31801 as peer 1 |
| 3 | 1 | join | PASS | PASS | joined 127.0.0.1:31801 as peer 1406884185 after 10 frames; snapshot applied; 2 peer(s) in registry |
| 4 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 4 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 5 | 0 | water_fixture — setup: host on the first shore | PASS | PASS | SETUP: Water island fixture at (0.0, 1.931176, 162.0); catching level 0 |
| 6 | 1 | f37_mount | PASS | PASS | ordinary mount prompt authorized |
| 7 | 1 | f37_status | PASS + {"diving":false,"mounted":true,"saddle_count":0.0,"stone":false} | PASS |  |
| 8 | 1 | f37_deep_fixture — SETUP submerged-save area near Lantern Cove | PASS | PASS | ordinary mapped movement to the optional cache; actual deep-water clearance |
| 9 | 0 | wait | PASS | PASS | waited 90 physics frames |
| 9 | 1 | wait | PASS | PASS | waited 90 physics frames |
| 10 | 1 | f37_jump | PASS | PASS | ordinary Jump tap |
| 11 | 1 | f37_status | PASS + {"diving":true,"mounted":true} | PASS |  |
| 12 | 0 | wait | PASS | PASS | waited 90 physics frames |
| 12 | 1 | wait | PASS | PASS | waited 90 physics frames |
| 13 | 1 | rider_self — BEFORE: the guest's own ride | PASS + {"character_id":"character-31970c242205a9c3b0621ce8039bbcc5","mount_species":"ripplet","mounted":true,"realm":"water","swim_mode":2.0} | PASS | {"character_id":"character-31970c242205a9c3b0621ce8039bbcc5","mount_species":"ripplet","mounted":true,"peer_id":1406884185,"realm":"water","saddle_worn":false,"swim_mode":2} |
| 14 | 0 | rider_identity — BEFORE: the host's picture of that rider agrees | PASS + {"agree":true,"body_visible_in_scene":true,"mount_species":"ripplet","mount_swim_mode":2.0,"seated":true} | PASS | character character-31970c24: {"agree":true,"bodies":1,"body_peer_id":1406884185,"body_visible_in_scene":true,"mount_authority":1406884185,"mount_owner_peer_id":1406884185,"mount_saddle_worn":false,"mount_species":"ripplet","mount_swim_mode":2,"mount_swim_owner":1406884185,"mounts":1,"nameplate":"Trainer","peer_id":1406884185,"registry_display_name":"Trainer","registry_rows":1,"riding":true,"seated":true,"stale_bodies":0,"stale_mounts":0} |
| 15 | 1 | save_character_here — the guest's character is written while mounted mid-water | PASS | PASS | character 'character-31970c242205a9c3b0621ce8039bbcc5' is on disk (wrote_world=false, waited 0 frames for the save fence) |
| 16 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-127f3de90c82d16d174eea0c7c1dcfb0' on disk=true; copied 3 files to f37proof2/peer-0/before_drop |
| 16 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-31970c242205a9c3b0621ce8039bbcc5' on disk=true; copied 1 files to f37proof2/peer-1/before_drop |
| 17 | 1 | check_saved — the saved character carries the ride | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-31970c242205a9c3b0621ce8039bbcc5/character.json"] under before_drop/characters |
| 18 | 1 | drop_link | PASS | PASS | transport closed without a Session.leave() (ENet disconnect sent to 1 peer(s), acknowledged by 1 after 4 frames) |
| 19 | 0 | expect_peers | PASS | PASS | registry reports 1 peer(s) after 0 frames (0.0 s) |
| 20 | 1 | leave — tear down if anything is left (after a dropped link there is no session, as smoke_net_reconnect_keeps_character expects) | any | FAIL | no active session to leave |
| 21 | 1 | wipe_character — the live character is blanked, so the ride must come back from the save | PASS | PASS | in-memory character blanked (party 1 -> 0), id 'character-31970c242205a9c3b0621ce8039bbcc5' kept, file untouched |
| 22 | 1 | production_join | PASS | PASS | title returning entry built 'WaterArchipelago' first, then JoinDriver joined 127.0.0.1:31801 as peer 24705009 after 43 frames |
| 23 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 23 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 24 | 1 | await_probe — the ride is restored | PASS | FAIL **(unexpected)** | riding.local.mounted was false, not true, after 1800 polls |

## Captured files

- `peer-0/before_drop/characters/redesign-v28/character-127f3de90c82d16d174eea0c7c1dcfb0/character.json`
- `peer-0/before_drop/saves/redesign-v28/slot_0.json`
- `peer-0/before_drop/worlds/redesign-v28/slot-0/world.json`
- `peer-1/before_drop/characters/redesign-v28/character-31970c242205a9c3b0621ce8039bbcc5/character.json`
