# Two-peer proof: F11: eligible peers accept/refuse the Stormheart independently

**Verdict: PASS** (exit 0)

Scenario: `/home/user/x05-ledger/tools/net/proof_scenarios/f11_stormheart_accept_refuse.json`  
Run: `net-20260925T151615Z-13665`  
Rendered: yes

ACCEPTANCE F11, 'eligible peers accept/refuse independently': both players fought the Dynamo; the host says Yes and keeps its own Stormheart, the guest says No and keeps nothing; each answer is its own world receipt and neither affects the other. Setup stands in for PLAYING the Dynamo fight only (contributors + Marrow's defeat flag through the ledger); the release, offers, dialogue answers, grants and saves are the game's own code.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: a fresh trainer in the Meadows | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | host | PASS | PASS | hosting udp/28881 as peer 1 |
| 4 | 1 | join | PASS | PASS | joined 127.0.0.1:28881 as peer 207624832 after 13 frames; snapshot applied; 2 peer(s) in registry |
| 5 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 5 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 6 | 0 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 6 | 1 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 7 | 0 | enter_realm — host first: its shell builds inside its own step | PASS | PASS | crossed 'meadows' -> 'stormwood' after 485 observed physics frames / 43417 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 8 | 1 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 504 observed physics frames / 27464 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 9 | 0 | screenshot | PASS | PASS | captured 960x540 -> peer-0/01_both_in_stormwood.png |
| 9 | 1 | screenshot | PASS | PASS | captured 960x540 -> peer-1/01_both_in_stormwood.png |
| 10 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to peer-0/before |
| 10 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-879b844692ff687d09707cb6cd9923ac' on disk=true; copied 1 files to peer-1/before |
| 11 | 0 | stormheart_fixture — both fought the Dynamo (setup) | PASS | PASS | Dynamo contributors [1, 207624832]; committed ["stormwood:act_ii_complete", "stormwood:marrow_defeated"] |
| 12 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 12 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 6 frames |
| 13 | 0 | stormheart_answer | PASS + {"has_stormheart":true} | PASS | party holds the Stormheart=true; claim settled=true; answered accept by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 3 earlier line(s) and 3 offer line(s); captured 960x540 -> peer-0/02_host_offer_yes_no.png |
| 14 | 1 | stormheart_answer | PASS + {"has_stormheart":false} | PASS | party holds the Stormheart=false; claim settled=true; answered refuse by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 3 earlier line(s) and 3 offer line(s); captured 960x540 -> peer-1/02_guest_offer_yes_no.png |
| 15 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-f41f4a49223483d6bfdf56715944bb7b (any) set after 0 frames |
| 15 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-f41f4a49223483d6bfdf56715944bb7b (any) set after 0 frames |
| 16 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:refused:character-879b844692ff687d09707cb6cd9923ac (any) set after 0 frames |
| 16 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:refused:character-879b844692ff687d09707cb6cd9923ac (any) set after 94 frames |
| 17 | 0 | stormheart_state — host kept its own | PASS + {"accepted_anywhere":true,"has_stormheart":true,"world_accepted":true,"world_refused":false} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true } |
| 18 | 1 | stormheart_state — guest refused, nothing granted | PASS + {"accepted_anywhere":false,"has_stormheart":false,"world_accepted":false,"world_refused":true} | PASS | { "character_id": "character-879b844692ff687d09707cb6cd9923ac", "party": [], "has_stormheart": false, "freed": true, "world_accepted": false, "world_refused": true, "accepted_anywhere": false } |
| 19 | 0 | screenshot | PASS | PASS | captured 960x540 -> peer-0/03_after_answers.png |
| 19 | 1 | screenshot | PASS | PASS | captured 960x540 -> peer-1/03_after_answers.png |
| 20 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to peer-0/after |
| 20 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-879b844692ff687d09707cb6cd9923ac' on disk=true; copied 1 files to peer-1/after |
| 21 | 0 | check_saved — host's pre-offer saved world held no answers (non-vacuous baseline) | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under before/worlds |
| 22 | 0 | check_saved — host's saved world holds both answers | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under after/worlds |
| 23 | 0 | check_saved — host's saved character keeps its Stormheart | PASS | PASS | missing []; unexpectedly present []; read ["character-f41f4a49223483d6bfdf56715944bb7b/character.json"] under after/characters |
| 24 | 1 | check_saved — guest's saved character refused and holds none | PASS | PASS | missing []; unexpectedly present []; read ["character-879b844692ff687d09707cb6cd9923ac/character.json"] under after/characters |
| 25 | 1 | check_saved — guest's pre-offer save held no answer (non-vacuous baseline) | PASS | PASS | missing []; unexpectedly present []; read ["character-879b844692ff687d09707cb6cd9923ac/character.json"] under before/characters |

## Captured files

- `peer-0/01_both_in_stormwood.png`
- `peer-0/02_host_offer_yes_no.png`
- `peer-0/03_after_answers.png`
- `peer-0/after/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/worlds/slot-0/world.json`
- `peer-0/before/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/before/saves/slot_0.json`
- `peer-0/before/worlds/slot-0/world.json`
- `peer-1/01_both_in_stormwood.png`
- `peer-1/02_guest_offer_yes_no.png`
- `peer-1/03_after_answers.png`
- `peer-1/after/characters/character-879b844692ff687d09707cb6cd9923ac/character.json`
- `peer-1/before/characters/character-879b844692ff687d09707cb6cd9923ac/character.json`

---
Annotated after the run (not written by the runner): in the repo, `worlds/` and `characters/` files are committed gzipped (`.json.gz`) and `saves/` slot copies and `net/` logs are omitted for size.
