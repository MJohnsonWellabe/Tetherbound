> **Provenance.** X05's scenario `tools/net/proof_scenarios/f12_remote_rider_identity_reconnect.json`, with its runner and proof steps, all from `ralph/x05-proofs-tidewake` 5afb4a6f9 (X05's evidence: `ralph/reports/INVITE-COOP/x05-proof-f12-rider-identity/PROOF.md`).
> Run headless against this branch's `encounter_director.gd` fix. On main the run fails at step #24: the host has no mount for the returning rider. With the fix, #24 and #25 pass, with the mount present on the first poll. Those files were only checked out for the run; none of them is committed here.
> Step #17 (`leave`, expect: any) reports FAIL by design, because a dropped link leaves no session to leave.

# Two-peer proof: F12: remote rider identity agrees mid-water, before and after a reconnect

**Verdict: PASS** (exit 0)

Scenario: `/home/user/tetherbound/tools/net/proof_scenarios/f12_remote_rider_identity_reconnect.json`  
Run: `net-20260925T195749Z-23887`  
Rendered: no (headless)

ACCEPTANCE F12 clause '... dismount/remount, reload and remote rider identity agree'. In Tidewake, the guest rides its Aquaryn into deep water; the host's picture of that rider -- registry row, trainer body (character, nameplate, riding and seated), and the mount carrying it (owner character and peer, authority, species, saddle, mounted swim mode) -- names the same player as the guest's own state. The guest then saves mid-water, loses its link, and comes back through the production returning route with a NEW peer id; the ride is restored and the host's picture agrees again, found by character, with nothing left over from the old peer id. Setup only: the host stands on the first shore (water_fixture) and the guest is given the Aquaryn and tack (water_mount_fixture), standing in for earning them.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | host | PASS | PASS | hosting udp/29341 as peer 1 |
| 2 | 1 | join | PASS | PASS | joined 127.0.0.1:29341 as peer 1570379631 after 7 frames; snapshot applied; 2 peer(s) in registry |
| 3 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 3 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 4 | 0 | water_fixture — setup: host on the first shore | PASS | PASS | SETUP: Water island fixture at (0.0, 1.931176, 162.0); catching level 0 |
| 5 | 1 | water_mount_fixture — setup: guest has its Aquaryn and tack | PASS | PASS | SETUP: water_aquaryn standing as AllyCreature, swim_saddle in the satchel |
| 6 | 1 | ride_mount | PASS | PASS | riding AllyCreature |
| 7 | 1 | water_mounted_swim | PASS | PASS | Started real mounted input from lesson shore to deep offshore point |
| 8 | 1 | await_probe — the mounted swim reaches deep water | PASS | PASS | water_mounted.motion.completed == true after 431 polls |
| 9 | 1 | rider_self — BEFORE: the guest's own ride | PASS + {"character_id":"character-3d940bbfd21e19bd4210d218e81dc757","mount_species":"water_aquaryn","mounted":true,"realm":"water","swim_mode":2.0} | PASS | {"character_id":"character-3d940bbfd21e19bd4210d218e81dc757","mount_species":"water_aquaryn","mounted":true,"peer_id":1570379631,"realm":"water","saddle_worn":true,"swim_mode":2} |
| 10 | 0 | rider_identity — BEFORE: the host's picture of that rider agrees | PASS + {"agree":true,"body_visible_in_scene":true,"mount_species":"water_aquaryn","mount_swim_mode":2.0,"seated":true} | PASS | character character-3d940bbf: {"agree":true,"bodies":1,"body_peer_id":1570379631,"body_visible_in_scene":true,"mount_authority":1570379631,"mount_owner_peer_id":1570379631,"mount_saddle_worn":true,"mount_species":"water_aquaryn","mount_swim_mode":2,"mount_swim_owner":1570379631,"mounts":1,"nameplate":"Trainer","peer_id":1570379631,"registry_display_name":"Trainer","registry_rows":1,"riding":true,"seated":true,"stale_bodies":0,"stale_mounts":0} |
| 11 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 11 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 12 | 1 | save_character_here — the guest's character is written while mounted mid-water | PASS | PASS | character 'character-3d940bbfd21e19bd4210d218e81dc757' is on disk (wrote_world=false) |
| 13 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f2525e14bd1d6e9f631da59ce841c85a' on disk=true; copied 3 files to /tmp/claude-0/-home-user/8c0c9b9d-9e1d-5f90-951e-bc836afff2c2/scratchpad/f12rr/peer-0/before_drop |
| 13 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-3d940bbfd21e19bd4210d218e81dc757' on disk=true; copied 1 files to /tmp/claude-0/-home-user/8c0c9b9d-9e1d-5f90-951e-bc836afff2c2/scratchpad/f12rr/peer-1/before_drop |
| 14 | 1 | check_saved — the saved character carries the ride | PASS | PASS | missing []; unexpectedly present []; read ["character-3d940bbfd21e19bd4210d218e81dc757/character.json"] under before_drop/characters |
| 15 | 1 | drop_link | PASS | PASS | transport closed without a Session.leave() |
| 16 | 0 | expect_peers | PASS | PASS | registry reports 1 peer(s) after 0 frames |
| 17 | 1 | leave — tear down if anything is left (after a dropped link there is no session, as smoke_net_reconnect_keeps_character expects) | any | FAIL | no active session to leave |
| 18 | 1 | wipe_character — the live character is blanked, so the ride must come back from the save | PASS | PASS | in-memory character blanked (party 1 -> 0), id 'character-3d940bbfd21e19bd4210d218e81dc757' kept, file untouched |
| 19 | 1 | production_join | PASS | PASS | title returning entry built 'WaterArchipelago' first, then JoinDriver joined 127.0.0.1:29341 as peer 1343298827 after 42 frames |
| 20 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 20 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 21 | 1 | await_probe — the ride is restored | PASS | PASS | riding.local.mounted == true after 0 polls |
| 22 | 1 | rider_self — AFTER: the guest's own ride, same character | PASS + {"character_id":"character-3d940bbfd21e19bd4210d218e81dc757","mount_species":"water_aquaryn","mounted":true,"realm":"water","swim_mode":2.0} | PASS | {"character_id":"character-3d940bbfd21e19bd4210d218e81dc757","mount_species":"water_aquaryn","mounted":true,"peer_id":1343298827,"realm":"water","saddle_worn":true,"swim_mode":2} |
| 23 | 0 | await_probe — the host sees the new peer id riding | PASS | PASS | riding.remote.1343298827.0.riding == true after 0 polls |
| 24 | 0 | await_probe — give the returning rider's mount time to reach the host (about 25 s) | PASS | PASS | water_mounted.remote_mounts.1343298827.0.owner_peer_id == 1343298827.0 after 0 polls |
| 25 | 0 | rider_identity — AFTER: the host's picture agrees, found by character, nothing stale | PASS + {"agree":true,"mount_species":"water_aquaryn","mount_swim_mode":2.0,"peer_id":1343298827,"seated":true,"stale_bodies":0.0,"stale_mounts":0.0} | PASS | character character-3d940bbf: {"agree":true,"bodies":1,"body_peer_id":1343298827,"body_visible_in_scene":true,"mount_authority":1343298827,"mount_owner_peer_id":1343298827,"mount_saddle_worn":true,"mount_species":"water_aquaryn","mount_swim_mode":2,"mount_swim_owner":1343298827,"mounts":1,"nameplate":"Trainer","peer_id":1343298827,"registry_display_name":"Trainer","registry_rows":1,"riding":true,"seated":true,"stale_bodies":0,"stale_mounts":0} |
| 26 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 26 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |

## Captured files

- `peer-0/before_drop/characters/character-f2525e14bd1d6e9f631da59ce841c85a/character.json`
- `peer-0/before_drop/saves/slot_0.json`
- `peer-0/before_drop/worlds/slot-0/world.json`
- `peer-1/before_drop/characters/character-3d940bbfd21e19bd4210d218e81dc757/character.json`
