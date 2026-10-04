# Two-peer proof: F11 mirror: host refuses, guest accepts the Stormheart (space on both sides)

**Verdict: PASS** (exit 0)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/stormwood_f11_mirror_host_refuses_guest_accepts.json`  
Run: `net-20261004T223456Z-12071`  
Rendered: no (headless)

ACCEPTANCE F11, 'eligible peers accept/refuse independently', mirrored from x05's rendered PASS: both players fought the Dynamo and both have a free party slot; the HOST says No and keeps nothing, the GUEST says Yes and keeps its own Stormheart. Each answer is its own world receipt and its own character receipt; a second press on the now-dark prompt grants nothing. Setup stands in for PLAYING the Dynamo fight only (contributors + Marrow's defeat flag through the ledger); the release, offers, dialogue answers, grants and saves are the game's own code.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: a fresh trainer in the Meadows | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | host | PASS | PASS | hosting udp/28521 as peer 1 |
| 4 | 1 | join | PASS | PASS | joined 127.0.0.1:28521 as peer 1378930538 after 37 frames; snapshot applied; 2 peer(s) in registry |
| 5 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 5 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 6 | 0 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 6 | 1 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 7 | 0 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 563 observed physics frames / 68109 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 8 | 1 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 675 observed physics frames / 45648 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 9 | 0 | stormheart_state — host: free slots (party empty) before the offer | PASS + {"has_stormheart":false,"party":[]} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": [], "has_stormheart": false, "freed": false, "world_accepted": false, "world_refused": false, "accepted_anywhere": false, "party_uids": [] } |
| 10 | 1 | stormheart_state — guest: free slots (party empty) before the offer | PASS + {"has_stormheart":false,"party":[]} | PASS | { "character_id": "character-802ea0935daedf6bb059e66a559488e2", "party": [], "has_stormheart": false, "freed": false, "world_accepted": false, "world_refused": false, "accepted_anywhere": false, "party_uids": [] } |
| 11 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 11 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 12 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 5 files to /tmp/claude-0/-home-user-Tetherbound/6050aa73-5362-5e48-a427-17c5687ec66b/scratchpad/proofs/F11-1-mirror-v28/peer-0/before |
| 12 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-802ea0935daedf6bb059e66a559488e2' on disk=true; copied 2 files to /tmp/claude-0/-home-user-Tetherbound/6050aa73-5362-5e48-a427-17c5687ec66b/scratchpad/proofs/F11-1-mirror-v28/peer-1/before |
| 13 | 0 | stormheart_fixture — both fought the Dynamo (setup) | PASS | PASS | Dynamo contributors [1, 1378930538]; committed ["stormwood:act_ii_complete", "stormwood:marrow_defeated"] |
| 14 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 14 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 409 frames |
| 15 | 0 | stormheart_answer — host says No | PASS + {"has_stormheart":false} | PASS | party holds the Stormheart=false; claim settled=true; answered refuse by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 3 earlier line(s) and 2 offer line(s); headless peer: no frame to capture (run with --render) |
| 16 | 1 | stormheart_answer — guest says Yes | PASS + {"has_stormheart":true} | PASS | party holds the Stormheart=true; claim settled=true; answered accept by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 3 earlier line(s) and 3 offer line(s); headless peer: no frame to capture (run with --render) |
| 17 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:refused:character-f41f4a49223483d6bfdf56715944bb7b (any) set after 0 frames |
| 17 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:refused:character-f41f4a49223483d6bfdf56715944bb7b (any) set after 0 frames |
| 18 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-802ea0935daedf6bb059e66a559488e2 (any) set after 0 frames |
| 18 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-802ea0935daedf6bb059e66a559488e2 (any) set after 0 frames |
| 19 | 0 | stormheart_state — host refused, nothing granted | PASS + {"accepted_anywhere":false,"has_stormheart":false,"party":[],"world_accepted":false,"world_refused":true} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": [], "has_stormheart": false, "freed": true, "world_accepted": false, "world_refused": true, "accepted_anywhere": false, "party_uids": [] } |
| 20 | 1 | stormheart_state — guest kept exactly one of its own | PASS + {"accepted_anywhere":true,"has_stormheart":true,"party":["fulgocobra"],"world_accepted":true,"world_refused":false} | PASS | { "character_id": "character-802ea0935daedf6bb059e66a559488e2", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true, "party_uids": ["creature-e6fa51d07d73e223c8d4433a2118ef86"] } |
| 21 | 1 | stormheart_answer — double press: the guest walks back and presses again; the answered prompt must not offer itself | FAIL | FAIL | no verdict |
| 22 | 0 | stormheart_answer — the host cannot turn its No into a Yes by pressing again | FAIL | FAIL | the offer prompt is not offering itself to this player (enabled=false, standing nowhere in reach, label 'Answer the freed Stormheart') |
| 23 | 0 | stormheart_state — host still holds nothing after the second press | PASS + {"has_stormheart":false,"party":[],"world_accepted":false,"world_refused":true} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": [], "has_stormheart": false, "freed": true, "world_accepted": false, "world_refused": true, "accepted_anywhere": false, "party_uids": [] } |
| 24 | 1 | stormheart_state — guest still holds exactly one Stormheart after the second press | PASS + {"has_stormheart":true,"party":["fulgocobra"]} | PASS | { "character_id": "character-802ea0935daedf6bb059e66a559488e2", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true, "party_uids": ["creature-e6fa51d07d73e223c8d4433a2118ef86"] } |
| 25 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 25 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 26 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 5 files to /tmp/claude-0/-home-user-Tetherbound/6050aa73-5362-5e48-a427-17c5687ec66b/scratchpad/proofs/F11-1-mirror-v28/peer-0/after |
| 26 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-802ea0935daedf6bb059e66a559488e2' on disk=true; copied 2 files to /tmp/claude-0/-home-user-Tetherbound/6050aa73-5362-5e48-a427-17c5687ec66b/scratchpad/proofs/F11-1-mirror-v28/peer-1/after |
| 27 | 0 | check_saved — host's pre-offer saved world held no answers (non-vacuous baseline) | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/slot-0/world.json"] under before/worlds |
| 28 | 0 | check_saved — host's pre-offer character held no answer | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-f41f4a49223483d6bfdf56715944bb7b/character.json"] under before/characters |
| 29 | 1 | check_saved — guest's pre-offer character held no answer (non-vacuous baseline) | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-802ea0935daedf6bb059e66a559488e2/character.json"] under before/characters |
| 30 | 0 | check_saved — host's saved world holds each answer once, the right way round | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/slot-0/world.json"] under after/worlds |
| 31 | 0 | check_saved — host's saved character refused and holds none | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-f41f4a49223483d6bfdf56715944bb7b/character.json"] under after/characters |
| 32 | 1 | check_saved — guest's saved character keeps its Stormheart | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-802ea0935daedf6bb059e66a559488e2/character.json"] under after/characters |

## Captured files

- `peer-0/after/characters/redesign-v28/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/after/saves/redesign-v28/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/after/saves/redesign-v28/slot_0.json`
- `peer-0/after/saves/redesign-v28/worlds/slot-0/world.json`
- `peer-0/after/worlds/redesign-v28/slot-0/world.json`
- `peer-0/before/characters/redesign-v28/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/before/saves/redesign-v28/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/before/saves/redesign-v28/slot_0.json`
- `peer-0/before/saves/redesign-v28/worlds/slot-0/world.json`
- `peer-0/before/worlds/redesign-v28/slot-0/world.json`
- `peer-1/after/characters/redesign-v28/character-802ea0935daedf6bb059e66a559488e2/character.json`
- `peer-1/after/saves/redesign-v28/characters/character-802ea0935daedf6bb059e66a559488e2/character.json`
- `peer-1/before/characters/redesign-v28/character-802ea0935daedf6bb059e66a559488e2/character.json`
- `peer-1/before/saves/redesign-v28/characters/character-802ea0935daedf6bb059e66a559488e2/character.json`
