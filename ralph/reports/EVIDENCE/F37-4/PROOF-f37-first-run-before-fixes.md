# Two-peer proof: F37 Ripplet surface mount, Dive and durable two-peer rejoin

**Verdict: FAIL** (exit 1)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/f37_ripplet_rejoin.json`  
Run: `net-20261011T155548Z-6258`  
Rendered: no (headless)

Pending runtime fixture proof only. Owned Ripplet and L30 breakthrough are explicit pre-admission fixtures. Real Interact/Jump, host admission, replicated carrier identity, disk character save and new-peer returning join. Save restores the mount at the surface with spent stamina and remaining dive debt, per WORLD 6.7. No earned feast, campaign, device or visual acceptance.

## Failures

- #14 peer 0 rider_identity (BEFORE: the host's picture of that rider agrees) -> FAIL; data did not match {"agree":true,"body_visible_in_scene":true,"mount_species":"ripplet","mount_swim_mode":2.0,"seated":true} -- character character-8061f997: {"agree":false,"bodies":1,"body_peer_id":20214209,"body_visible_in_scene":true,"mount_authority":20214209,"mount_owner_peer_id":20214209,"mount_saddle_worn":false,"mount_species":"ripplet","mount_swim_mode":2,"mount_swim_owner":20214209,"mounts":1,"nameplate":"Trainer",

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 1 | f37_fixture — SETUP before host admission: owned Ripplet and L30 feast record | PASS | PASS | SETUP owned L30 Ripplet and explicit breakthrough fixture before admission |
| 2 | 0 | host | PASS | PASS | hosting udp/31361 as peer 1 |
| 3 | 1 | join | PASS | PASS | joined 127.0.0.1:31361 as peer 20214209 after 17 frames; snapshot applied; 2 peer(s) in registry |
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
| 13 | 1 | rider_self — BEFORE: the guest's own ride | PASS + {"character_id":"character-8061f9973493e4f52f8ac38bc92d3fc5","mount_species":"ripplet","mounted":true,"realm":"water","swim_mode":2.0} | PASS | {"character_id":"character-8061f9973493e4f52f8ac38bc92d3fc5","mount_species":"ripplet","mounted":true,"peer_id":20214209,"realm":"water","saddle_worn":false,"swim_mode":2} |
| 14 | 0 | rider_identity — BEFORE: the host's picture of that rider agrees | PASS + {"agree":true,"body_visible_in_scene":true,"mount_species":"ripplet","mount_swim_mode":2.0,"seated":true} | FAIL **(unexpected)** | character character-8061f997: {"agree":false,"bodies":1,"body_peer_id":20214209,"body_visible_in_scene":true,"mount_authority":20214209,"mount_owner_peer_id":20214209,"mount_saddle_worn":false,"mount_species":"ripplet","mount_swim_mode":2,"mount_swim_owner":20214209,"mounts":1,"nameplate":"Trainer","peer_id":20214209,"registry_display_name":"Trainer","registry_rows":1,"riding":true,"seated":true,"stale_bodies":0,"stale_mounts":0} |

## Captured files

