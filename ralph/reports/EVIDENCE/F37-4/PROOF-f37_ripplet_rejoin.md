# Two-peer proof: F37 Ripplet surface mount, Dive and durable two-peer rejoin

**Verdict: PASS** (exit 0)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/f37_ripplet_rejoin.json`  
Run: `net-20261011T164307Z-16563`  
Rendered: no (headless)

Pending runtime fixture proof only. Owned Ripplet and L30 breakthrough are explicit pre-admission fixtures. Real Interact/Jump, host admission, replicated carrier identity, disk character save and new-peer returning join. Save restores the mount at the surface with spent stamina and remaining dive debt, per WORLD 6.7. No earned feast, campaign, device or visual acceptance.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 1 | f37_fixture — SETUP before host admission: owned Ripplet and L30 feast record | PASS | PASS | SETUP owned L30 Ripplet and explicit breakthrough fixture before admission |
| 2 | 0 | host | PASS | PASS | hosting udp/33781 as peer 1 |
| 3 | 1 | join | PASS | PASS | joined 127.0.0.1:33781 as peer 1621947873 after 12 frames; snapshot applied; 2 peer(s) in registry |
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
| 13 | 1 | rider_self — BEFORE: the guest's own ride | PASS + {"character_id":"character-e6a86b4441c47d5949eee4fc53456330","mount_species":"ripplet","mounted":true,"realm":"water","swim_mode":2.0} | PASS | {"character_id":"character-e6a86b4441c47d5949eee4fc53456330","mount_species":"ripplet","mounted":true,"peer_id":1621947873,"realm":"water","saddle_worn":false,"swim_mode":2} |
| 14 | 0 | rider_identity — BEFORE: the host's picture of that rider agrees | PASS + {"agree":true,"body_visible_in_scene":true,"mount_species":"ripplet","mount_swim_mode":2.0,"seated":true} | PASS | character character-e6a86b44: {"agree":true,"bodies":1,"body_peer_id":1621947873,"body_visible_in_scene":true,"mount_authority":1621947873,"mount_owner_peer_id":1621947873,"mount_saddle_worn":false,"mount_species":"ripplet","mount_swim_mode":2,"mount_swim_owner":1621947873,"mounts":1,"nameplate":"Trainer","peer_id":1621947873,"registry_display_name":"Trainer","registry_rows":1,"riding":true,"seated":true,"stale_bodies":0,"stale_mounts":0} |
| 15 | 1 | save_character_here — the guest's character is written while mounted mid-water | PASS | PASS | character 'character-e6a86b4441c47d5949eee4fc53456330' is on disk (wrote_world=false, waited 0 frames for the save fence) |
| 16 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-0f950b48b321f8d93bff1d670ff62e4f' on disk=true; copied 3 files to f37proof4/peer-0/before_drop |
| 16 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-e6a86b4441c47d5949eee4fc53456330' on disk=true; copied 1 files to f37proof4/peer-1/before_drop |
| 17 | 1 | check_saved — the saved character carries the ride | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-e6a86b4441c47d5949eee4fc53456330/character.json"] under before_drop/characters |
| 18 | 1 | drop_link | PASS | PASS | transport closed without a Session.leave() (ENet disconnect sent to 1 peer(s), acknowledged by 1 after 4 frames) |
| 19 | 0 | expect_peers | PASS | PASS | registry reports 1 peer(s) after 0 frames (0.0 s) |
| 20 | 1 | leave — tear down if anything is left (after a dropped link there is no session, as smoke_net_reconnect_keeps_character expects) | any | FAIL | no active session to leave |
| 21 | 1 | wipe_character — the live character is blanked, so the ride must come back from the save | PASS | PASS | in-memory character blanked (party 1 -> 0), id 'character-e6a86b4441c47d5949eee4fc53456330' kept, file untouched |
| 22 | 1 | production_join | PASS | PASS | title returning entry built 'WaterArchipelago' first, then JoinDriver joined 127.0.0.1:33781 as peer 1098313394 after 51 frames |
| 23 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 23 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 24 | 1 | await_probe — the ride is restored | PASS | PASS | riding.local.mounted == true after 0 polls |
| 25 | 1 | rider_self — AFTER: the guest's own ride, same character | PASS + {"character_id":"character-e6a86b4441c47d5949eee4fc53456330","mount_species":"ripplet","mounted":true,"realm":"water","swim_mode":2.0} | PASS | {"character_id":"character-e6a86b4441c47d5949eee4fc53456330","mount_species":"ripplet","mounted":true,"peer_id":1098313394,"realm":"water","saddle_worn":false,"swim_mode":2} |
| 26 | 0 | await_probe — the host sees the new peer id riding | PASS | PASS | riding.remote.1098313394.0.riding == true after 0 polls |
| 27 | 0 | await_probe — give the returning rider's mount time to reach the host (about 25 s) | PASS | PASS | water_mounted.remote_mounts.1098313394.0.owner_peer_id == 1098313394.0 after 0 polls |
| 28 | 0 | await_probe — the returning mount's swim mode reaches the host (race seen at tb/tidewake-full fa287aa4) | PASS | PASS | water_mounted.remote_mounts.1098313394.0.applied_aquatic.mode == 2.0 after 16 polls |
| 29 | 0 | rider_identity — AFTER: the host's picture agrees, found by character, nothing stale | PASS + {"agree":true,"mount_species":"ripplet","mount_swim_mode":2.0,"peer_id":1098313394,"seated":true,"stale_bodies":0.0,"stale_mounts":0.0} | PASS | character character-e6a86b44: {"agree":true,"bodies":1,"body_peer_id":1098313394,"body_visible_in_scene":true,"mount_authority":1098313394,"mount_owner_peer_id":1098313394,"mount_saddle_worn":false,"mount_species":"ripplet","mount_swim_mode":2,"mount_swim_owner":1098313394,"mounts":1,"nameplate":"Trainer","peer_id":1098313394,"registry_display_name":"Trainer","registry_rows":1,"riding":true,"seated":true,"stale_bodies":0,"stale_mounts":0} |
| 30 | 1 | f37_status — Reconnect seats surface, with remaining dive debt on saved owned mount | PASS + {"diving":false,"mounted":true} | PASS |  |
| 31 | 1 | f37_jump | PASS | PASS | ordinary Jump tap |
| 32 | 1 | f37_status — A fresh tap resumes the saved bounded dive budget | PASS + {"diving":true} | PASS |  |

## Captured files

- `peer-0/before_drop/characters/redesign-v28/character-0f950b48b321f8d93bff1d670ff62e4f/character.json`
- `peer-0/before_drop/saves/redesign-v28/slot_0.json`
- `peer-0/before_drop/worlds/redesign-v28/slot-0/world.json`
- `peer-1/before_drop/characters/redesign-v28/character-e6a86b4441c47d5949eee4fc53456330/character.json`
