# Two-peer proof: F11: eligible peers accept/refuse the Stormheart independently

**Verdict: FAIL** (exit 1)

Scenario: `/tmp/claude-0/-home-user-Tetherbound/6363066d-9ebc-5645-8000-19dadf1d76a6/scratchpad/scen/f11_stormheart_accept_refuse.json`  
Run: `net-20261011T172327Z-25996`  
Rendered: no (headless)

ACCEPTANCE F11, 'eligible peers accept/refuse independently': both players fought the Dynamo; the host says Yes and keeps its own Stormheart, the guest says No and keeps nothing; each answer is its own world receipt and neither affects the other. Setup stands in for PLAYING the Dynamo fight only (contributors + Marrow's defeat flag through the ledger); the release, offers, dialogue answers, grants and saves are the game's own code.

## Failures

- #24 peer 0 check_saved (host's saved world holds both answers) -> FAIL -- missing []; unexpectedly present ["stormwood:waterward_revealed"]; read ["redesign-v28/slot-0/world.json"] under after/worlds

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: a fresh trainer in the Meadows | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | enter_realm — DISCLOSED SETUP: initial Hall arch position and the Stormwood portal open for this world (stands in for the earned Cloudreach-finale unlock), no earned credit | PASS | PASS | Disclosed initial actual ground/route fixture; return cases include an initial Home Key; no earned credit |
| 4 | 1 | enter_realm — DISCLOSED SETUP: initial Hall arch position and the Stormwood portal open for this world (stands in for the earned Cloudreach-finale unlock), no earned credit | PASS | PASS | Disclosed initial actual ground/route fixture; return cases include an initial Home Key; no earned credit |
| 5 | 0 | host | PASS | PASS | hosting udp/33361 as peer 1 |
| 6 | 1 | join | PASS | PASS | joined 127.0.0.1:33361 as peer 699416660 after 51 frames; snapshot applied; 2 peer(s) in registry |
| 7 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 7 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 8 | 0 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 8 | 1 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 9 | 1 | enter_realm — through the Crossing Hall Stormwood portal (RD-17) | PASS | PASS | crossed 'meadows' -> 'stormwood' after 824 observed physics frames / 37569 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 10 | 0 | enter_realm — through the Crossing Hall Stormwood portal (RD-17); host first: its shell builds inside its own step | PASS | PASS | crossed 'meadows' -> 'stormwood' after 743 observed physics frames / 34337 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 11 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 11 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 12 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 5 files to /tmp/claude-0/-home-user-Tetherbound/6363066d-9ebc-5645-8000-19dadf1d76a6/scratchpad/ar/peer-0/before |
| 12 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-30b5eeefbf932ef281f129ba19165211' on disk=true; copied 3 files to /tmp/claude-0/-home-user-Tetherbound/6363066d-9ebc-5645-8000-19dadf1d76a6/scratchpad/ar/peer-1/before |
| 13 | 0 | stormheart_fixture — both fought the Dynamo (setup) | PASS | PASS | Dynamo contributors [1, 699416660]; committed ["stormwood:act_ii_complete", "stormwood:marrow_defeated"] |
| 14 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 14 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 15 | 0 | stormheart_answer | PASS + {"has_stormheart":true} | PASS | party holds the Stormheart=true; claim settled=true; answered accept by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 2 earlier line(s) and 1 offer line(s); headless peer: no frame to capture (run with --render) |
| 16 | 1 | stormheart_answer | PASS + {"has_stormheart":false} | PASS | party holds the Stormheart=false; claim settled=true; answered refuse by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 2 earlier line(s) and 2 offer line(s); headless peer: no frame to capture (run with --render) |
| 17 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-f41f4a49223483d6bfdf56715944bb7b (any) set after 0 frames |
| 17 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-f41f4a49223483d6bfdf56715944bb7b (any) set after 0 frames |
| 18 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:refused:character-30b5eeefbf932ef281f129ba19165211 (any) set after 0 frames |
| 18 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:refused:character-30b5eeefbf932ef281f129ba19165211 (any) set after 0 frames |
| 19 | 0 | stormheart_state — host kept its own | PASS + {"accepted_anywhere":true,"has_stormheart":true,"world_accepted":true,"world_refused":false} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true, "party_uids": ["creature-cd9565f58fce03555b0c194ffb7788ef"] } |
| 20 | 1 | stormheart_state — guest refused, nothing granted | PASS + {"accepted_anywhere":false,"has_stormheart":false,"world_accepted":false,"world_refused":true} | PASS | { "character_id": "character-30b5eeefbf932ef281f129ba19165211", "party": [], "has_stormheart": false, "freed": true, "world_accepted": false, "world_refused": true, "accepted_anywhere": false, "party_uids": [] } |
| 21 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 21 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 22 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 5 files to /tmp/claude-0/-home-user-Tetherbound/6363066d-9ebc-5645-8000-19dadf1d76a6/scratchpad/ar/peer-0/after |
| 22 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-30b5eeefbf932ef281f129ba19165211' on disk=true; copied 3 files to /tmp/claude-0/-home-user-Tetherbound/6363066d-9ebc-5645-8000-19dadf1d76a6/scratchpad/ar/peer-1/after |
| 23 | 0 | check_saved — host's pre-offer saved world held no answers (non-vacuous baseline) | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/slot-0/world.json"] under before/worlds |
| 24 | 0 | check_saved — host's saved world holds both answers | PASS | FAIL **(unexpected)** | missing []; unexpectedly present ["stormwood:waterward_revealed"]; read ["redesign-v28/slot-0/world.json"] under after/worlds |

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
- `peer-1/after/characters/redesign-v28/character-30b5eeefbf932ef281f129ba19165211/character.json`
- `peer-1/after/saves/redesign-v28/characters/character-30b5eeefbf932ef281f129ba19165211/character.json`
- `peer-1/after/worlds/redesign-v28/slot-0/world.json`
- `peer-1/before/characters/redesign-v28/character-30b5eeefbf932ef281f129ba19165211/character.json`
- `peer-1/before/saves/redesign-v28/characters/character-30b5eeefbf932ef281f129ba19165211/character.json`
- `peer-1/before/worlds/redesign-v28/slot-0/world.json`
