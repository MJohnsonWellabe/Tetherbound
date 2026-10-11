# Two-peer proof: F11 mirror: host refuses, guest accepts the Stormheart (space on both sides)

**Verdict: PASS** (exit 0)

Scenario: `/tmp/claude-0/-home-user-Tetherbound/6363066d-9ebc-5645-8000-19dadf1d76a6/scratchpad/scen/stormwood_f11_mirror_host_refuses_guest_accepts.json`  
Run: `net-20261011T164712Z-22097`  
Rendered: no (headless)

ACCEPTANCE F11, 'eligible peers accept/refuse independently', mirrored from x05's rendered PASS: both players fought the Dynamo and both have a free party slot; the HOST says No and keeps nothing, the GUEST says Yes and keeps its own Stormheart. Each answer is its own world receipt and its own character receipt; a second press on the now-dark prompt grants nothing. Setup stands in for PLAYING the Dynamo fight only (contributors + Marrow's defeat flag through the ledger); the release, offers, dialogue answers, grants and saves are the game's own code.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: a fresh trainer in the Meadows | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | enter_realm — DISCLOSED SETUP: initial Hall arch position and the Stormwood portal open for this world (stands in for the earned Cloudreach-finale unlock), no earned credit | PASS | PASS | Disclosed initial actual ground/route fixture; return cases include an initial Home Key; no earned credit |
| 4 | 1 | enter_realm — DISCLOSED SETUP: initial Hall arch position and the Stormwood portal open for this world (stands in for the earned Cloudreach-finale unlock), no earned credit | PASS | PASS | Disclosed initial actual ground/route fixture; return cases include an initial Home Key; no earned credit |
| 5 | 0 | host | PASS | PASS | hosting udp/29921 as peer 1 |
| 6 | 1 | join | PASS | PASS | joined 127.0.0.1:29921 as peer 1181468618 after 29 frames; snapshot applied; 2 peer(s) in registry |
| 7 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 7 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 8 | 0 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 8 | 1 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 9 | 1 | enter_realm — through the Crossing Hall Stormwood portal (RD-17) | PASS | PASS | crossed 'meadows' -> 'stormwood' after 816 observed physics frames / 38741 ms (budget 18000 physics frames); current scene is /root/Stormwood |
| 10 | 0 | enter_realm — through the Crossing Hall Stormwood portal (RD-17) | PASS | PASS | crossed 'meadows' -> 'stormwood' after 743 observed physics frames / 34610 ms (budget 18000 physics frames); current scene is /root/Stormwood |
| 11 | 0 | stormheart_state — host: free slots (party empty) before the offer | PASS + {"has_stormheart":false,"party":[]} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": [], "has_stormheart": false, "freed": false, "world_accepted": false, "world_refused": false, "accepted_anywhere": false, "party_uids": [] } |
| 12 | 1 | stormheart_state — guest: free slots (party empty) before the offer | PASS + {"has_stormheart":false,"party":[]} | PASS | { "character_id": "character-c17093947decc3b8156a1ab6df05dc6d", "party": [], "has_stormheart": false, "freed": false, "world_accepted": false, "world_refused": false, "accepted_anywhere": false, "party_uids": [] } |
| 13 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 13 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 14 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 5 files to /tmp/claude-0/-home-user-Tetherbound/6363066d-9ebc-5645-8000-19dadf1d76a6/scratchpad/mirror/peer-0/before |
| 14 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-c17093947decc3b8156a1ab6df05dc6d' on disk=true; copied 5 files to /tmp/claude-0/-home-user-Tetherbound/6363066d-9ebc-5645-8000-19dadf1d76a6/scratchpad/mirror/peer-1/before |
| 15 | 0 | stormheart_fixture — both fought the Dynamo (setup) | PASS | PASS | Dynamo contributors [1, 1181468618]; committed ["stormwood:act_ii_complete", "stormwood:marrow_defeated"] |
| 16 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 16 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 17 | 0 | stormheart_answer — host says No | PASS + {"has_stormheart":false} | PASS | party holds the Stormheart=false; claim settled=true; answered refuse by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 2 earlier line(s) and 2 offer line(s); headless peer: no frame to capture (run with --render) |
| 18 | 1 | stormheart_answer — guest says Yes | PASS + {"has_stormheart":true} | PASS | party holds the Stormheart=true; claim settled=true; answered accept by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 2 earlier line(s) and 2 offer line(s); headless peer: no frame to capture (run with --render) |
| 19 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:refused:character-f41f4a49223483d6bfdf56715944bb7b (any) set after 0 frames |
| 19 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:refused:character-f41f4a49223483d6bfdf56715944bb7b (any) set after 0 frames |
| 20 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-c17093947decc3b8156a1ab6df05dc6d (any) set after 0 frames |
| 20 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-c17093947decc3b8156a1ab6df05dc6d (any) set after 0 frames |
| 21 | 0 | stormheart_state — host refused, nothing granted | PASS + {"accepted_anywhere":false,"has_stormheart":false,"party":[],"world_accepted":false,"world_refused":true} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": [], "has_stormheart": false, "freed": true, "world_accepted": false, "world_refused": true, "accepted_anywhere": false, "party_uids": [] } |
| 22 | 1 | stormheart_state — guest kept exactly one of its own | PASS + {"accepted_anywhere":true,"has_stormheart":true,"party":["fulgocobra"],"world_accepted":true,"world_refused":false} | PASS | { "character_id": "character-c17093947decc3b8156a1ab6df05dc6d", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true, "party_uids": ["creature-9546e38f597c5a9eda7b34b3677f0fed"] } |
| 23 | 1 | stormheart_answer — double press: the guest walks back and presses again; the answered prompt must not offer itself | FAIL | FAIL | the offer prompt is not offering itself to this player (enabled=false, standing nowhere in reach, label 'Answer the freed Stormheart') |
| 24 | 0 | stormheart_answer — the host cannot turn its No into a Yes by pressing again | FAIL | FAIL | the offer prompt is not offering itself to this player (enabled=false, standing nowhere in reach, label 'Answer the freed Stormheart') |
| 25 | 0 | stormheart_state — host still holds nothing after the second press | PASS + {"has_stormheart":false,"party":[],"world_accepted":false,"world_refused":true} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": [], "has_stormheart": false, "freed": true, "world_accepted": false, "world_refused": true, "accepted_anywhere": false, "party_uids": [] } |
| 26 | 1 | stormheart_state — guest still holds exactly one Stormheart after the second press | PASS + {"has_stormheart":true,"party":["fulgocobra"]} | PASS | { "character_id": "character-c17093947decc3b8156a1ab6df05dc6d", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true, "party_uids": ["creature-9546e38f597c5a9eda7b34b3677f0fed"] } |
| 27 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 27 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 28 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 5 files to /tmp/claude-0/-home-user-Tetherbound/6363066d-9ebc-5645-8000-19dadf1d76a6/scratchpad/mirror/peer-0/after |
| 28 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-c17093947decc3b8156a1ab6df05dc6d' on disk=true; copied 5 files to /tmp/claude-0/-home-user-Tetherbound/6363066d-9ebc-5645-8000-19dadf1d76a6/scratchpad/mirror/peer-1/after |
| 29 | 0 | check_saved — host's pre-offer saved world held no answers (non-vacuous baseline) | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/slot-0/world.json"] under before/worlds |
| 30 | 0 | check_saved — host's pre-offer character held no answer | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-f41f4a49223483d6bfdf56715944bb7b/character.json"] under before/characters |
| 31 | 1 | check_saved — guest's pre-offer character held no answer (non-vacuous baseline) | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-c17093947decc3b8156a1ab6df05dc6d/character.json"] under before/characters |
| 32 | 0 | check_saved — host's saved world holds each answer once, the right way round | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/slot-0/world.json"] under after/worlds |
| 33 | 0 | check_saved — host's saved character refused and holds none | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-f41f4a49223483d6bfdf56715944bb7b/character.json"] under after/characters |
| 34 | 1 | check_saved — guest's saved character keeps its Stormheart | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-c17093947decc3b8156a1ab6df05dc6d/character.json"] under after/characters |

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
- `peer-1/after/characters/redesign-v28/character-c17093947decc3b8156a1ab6df05dc6d/character.json`
- `peer-1/after/saves/redesign-v28/characters/character-c17093947decc3b8156a1ab6df05dc6d/character.json`
- `peer-1/after/saves/redesign-v28/slot_0.json`
- `peer-1/after/saves/redesign-v28/worlds/slot-0/world.json`
- `peer-1/after/worlds/redesign-v28/slot-0/world.json`
- `peer-1/before/characters/redesign-v28/character-c17093947decc3b8156a1ab6df05dc6d/character.json`
- `peer-1/before/saves/redesign-v28/characters/character-c17093947decc3b8156a1ab6df05dc6d/character.json`
- `peer-1/before/saves/redesign-v28/slot_0.json`
- `peer-1/before/saves/redesign-v28/worlds/slot-0/world.json`
- `peer-1/before/worlds/redesign-v28/slot-0/world.json`
