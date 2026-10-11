# Two-peer proof: F11 capacity: guest full at five says Yes and gives up a belt member; host with space says Yes

**Verdict: FAIL** (exit 1)

Scenario: `/tmp/claude-0/-home-user-Tetherbound/6363066d-9ebc-5645-8000-19dadf1d76a6/scratchpad/scen/stormwood_f11_capacity_guest_full_releases_belt.json`  
Run: `net-20261011T170541Z-24063`  
Rendered: no (headless)

ACCEPTANCE F11 'at capacity' + CLAUDE.md 'five creatures total, no hidden sixth': the guest's belt already holds five when it says Yes to its own Stormheart. The Stormheart does not take a sixth slot and is not silently dropped: Yes hands it to the Team tab's five-slot release ceremony (stormwood_ending.gd _begin_local_ceremony -> Game.pending_catch), where the guest, by ordinary presses, lets belt row 1 (bramblebun) go and the Stormheart takes that holder. The host, with a free slot, says Yes and keeps its own. Setup, disclosed: the Dynamo fight (contributors + Marrow's flag, as x05's fixture) and the guest's five belt members (peer_runner party_grant -> party_seam.add, the game's own add), since no named save with a full five exists; everything from the offer on is the game's own code.

## Failures

- #23 peer 0 stormheart_answer (host (space) says Yes) -> FAIL; data did not match {"has_stormheart":true} -- the offer closed before its Yes/No line (2 presses)

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: a fresh trainer in the Meadows | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | enter_realm — DISCLOSED SETUP: initial Hall arch position and the Stormwood portal open for this world (stands in for the earned Cloudreach-finale unlock), no earned credit | PASS | PASS | Disclosed initial actual ground/route fixture; return cases include an initial Home Key; no earned credit |
| 4 | 1 | enter_realm — DISCLOSED SETUP: initial Hall arch position and the Stormwood portal open for this world (stands in for the earned Cloudreach-finale unlock), no earned credit | PASS | PASS | Disclosed initial actual ground/route fixture; return cases include an initial Home Key; no earned credit |
| 5 | 0 | host | PASS | PASS | hosting udp/32001 as peer 1 |
| 6 | 1 | join | PASS | PASS | joined 127.0.0.1:32001 as peer 762863099 after 21 frames; snapshot applied; 2 peer(s) in registry |
| 7 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 7 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 8 | 0 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 8 | 1 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 9 | 1 | enter_realm — through the Crossing Hall Stormwood portal (RD-17) | PASS | PASS | crossed 'meadows' -> 'stormwood' after 997 observed physics frames / 42821 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 10 | 0 | enter_realm — through the Crossing Hall Stormwood portal (RD-17) | PASS | PASS | crossed 'meadows' -> 'stormwood' after 816 observed physics frames / 36418 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 11 | 1 | party_grant — SETUP: guest's belt member 1/5 (bramblebun) through party_seam.add | PASS | PASS | 'bramblebun' at level 20 joined the party (1 member(s)) |
| 12 | 1 | party_grant — SETUP: guest's belt member 2/5 (terrapup) through party_seam.add | PASS | PASS | 'terrapup' at level 20 joined the party (2 member(s)) |
| 13 | 1 | party_grant — SETUP: guest's belt member 3/5 (ripplet) through party_seam.add | PASS | PASS | 'ripplet' at level 20 joined the party (3 member(s)) |
| 14 | 1 | party_grant — SETUP: guest's belt member 4/5 (galewisp) through party_seam.add | PASS | PASS | 'galewisp' at level 20 joined the party (4 member(s)) |
| 15 | 1 | party_grant — SETUP: guest's belt member 5/5 (mudsnout) through party_seam.add | PASS | PASS | 'mudsnout' at level 20 joined the party (5 member(s)) |
| 16 | 1 | party_grant — guest's belt is full: a sixth party_seam.add is refused (no sixth slot) | FAIL | FAIL | party_seam.add('trailpup') refused -- the party is full (five, and there is no sixth slot) |
| 17 | 0 | stormheart_state — host: free slots before the offer | PASS + {"has_stormheart":false,"party":[]} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": [], "has_stormheart": false, "freed": false, "world_accepted": false, "world_refused": false, "accepted_anywhere": false, "party_uids": [] } |
| 18 | 1 | stormheart_state — guest: exactly five before the offer | PASS + {"has_stormheart":false,"party":["bramblebun","terrapup","ripplet","galewisp","mudsnout"]} | PASS | { "character_id": "character-8e475055c694942e915b0ad1ab579f1f", "party": ["bramblebun", "terrapup", "ripplet", "galewisp", "mudsnout"], "has_stormheart": false, "freed": false, "world_accepted": false, "world_refused": false, "accepted_anywhere": false, "party_uids": ["creature-8439b5d6b9666b865166e012667367e9", "creature-4e50b492b001d0b40f04f73d540b9d81", "creature-25ee634179df91c206d93e41ccb00ad9", "creature-52f5912141c74c7f189a4d6fe4a176f2", "creature-ec2e083887e5934e7a658735b26ad2d4"] } |
| 19 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 19 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 20 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 5 files to /tmp/claude-0/-home-user-Tetherbound/6363066d-9ebc-5645-8000-19dadf1d76a6/scratchpad/capg/peer-0/before |
| 20 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-8e475055c694942e915b0ad1ab579f1f' on disk=true; copied 3 files to /tmp/claude-0/-home-user-Tetherbound/6363066d-9ebc-5645-8000-19dadf1d76a6/scratchpad/capg/peer-1/before |
| 21 | 0 | stormheart_fixture — both fought the Dynamo (setup) | PASS | PASS | Dynamo contributors [1, 762863099]; committed ["stormwood:act_ii_complete", "stormwood:marrow_defeated"] |
| 22 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 22 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 23 | 0 | stormheart_answer — host (space) says Yes | PASS + {"has_stormheart":true} | FAIL **(unexpected)** | the offer closed before its Yes/No line (2 presses) |

## Captured files

- `peer-0/before/characters/redesign-v28/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/before/saves/redesign-v28/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/before/saves/redesign-v28/slot_0.json`
- `peer-0/before/saves/redesign-v28/worlds/slot-0/world.json`
- `peer-0/before/worlds/redesign-v28/slot-0/world.json`
- `peer-1/before/characters/redesign-v28/character-8e475055c694942e915b0ad1ab579f1f/character.json`
- `peer-1/before/saves/redesign-v28/characters/character-8e475055c694942e915b0ad1ab579f1f/character.json`
- `peer-1/before/worlds/redesign-v28/slot-0/world.json`
