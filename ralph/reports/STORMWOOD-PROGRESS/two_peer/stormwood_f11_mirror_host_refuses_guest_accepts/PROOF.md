# Two-peer proof: F11 mirror: host refuses, guest accepts the Stormheart (space on both sides)

**Verdict: PASS** (exit 0)

Scenario: `/home/user/tb-road/tools/net/proof_scenarios/stormwood_f11_mirror_host_refuses_guest_accepts.json`  
Run: `net-20260925T191033Z-20478`  
Rendered: yes

ACCEPTANCE F11, 'eligible peers accept/refuse independently', mirrored from x05's rendered PASS: both players fought the Dynamo and both have a free party slot; the HOST says No and keeps nothing, the GUEST says Yes and keeps its own Stormheart. Each answer is its own world receipt and its own character receipt; a second press on the now-dark prompt grants nothing. Setup stands in for PLAYING the Dynamo fight only (contributors + Marrow's defeat flag through the ledger); the release, offers, dialogue answers, grants and saves are the game's own code.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: a fresh trainer in the Meadows | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | host | PASS | PASS | hosting udp/30121 as peer 1 |
| 4 | 1 | join | PASS | PASS | joined 127.0.0.1:30121 as peer 1576819701 after 9 frames; snapshot applied; 2 peer(s) in registry |
| 5 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 5 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 6 | 0 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 6 | 1 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 7 | 0 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 481 observed physics frames / 37301 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 8 | 1 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 498 observed physics frames / 23200 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 9 | 0 | stormheart_state — host: free slots (party empty) before the offer | PASS + {"has_stormheart":false,"party":[]} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": [], "has_stormheart": false, "freed": false, "world_accepted": false, "world_refused": false, "accepted_anywhere": false } |
| 10 | 1 | stormheart_state — guest: free slots (party empty) before the offer | PASS + {"has_stormheart":false,"party":[]} | PASS | { "character_id": "character-1b75041208a5185f4ee4702f50591c70", "party": [], "has_stormheart": false, "freed": false, "world_accepted": false, "world_refused": false, "accepted_anywhere": false } |
| 11 | 0 | screenshot | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer_f11/stormwood_f11_mirror_host_refuses_guest_accepts/peer-0/01_both_in_stormwood.png |
| 11 | 1 | screenshot | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer_f11/stormwood_f11_mirror_host_refuses_guest_accepts/peer-1/01_both_in_stormwood.png |
| 12 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer_f11/stormwood_f11_mirror_host_refuses_guest_accepts/peer-0/before |
| 12 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-1b75041208a5185f4ee4702f50591c70' on disk=true; copied 1 files to /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer_f11/stormwood_f11_mirror_host_refuses_guest_accepts/peer-1/before |
| 13 | 0 | stormheart_fixture — both fought the Dynamo (setup) | PASS | PASS | Dynamo contributors [1, 1576819701]; committed ["stormwood:act_ii_complete", "stormwood:marrow_defeated"] |
| 14 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 14 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 1098 frames |
| 15 | 0 | stormheart_answer — host says No | PASS + {"has_stormheart":false} | PASS | party holds the Stormheart=false; claim settled=true; answered refuse by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 3 earlier line(s) and 3 offer line(s); captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer_f11/stormwood_f11_mirror_host_refuses_guest_accepts/peer-0/02_host_offer_yes_no.png |
| 16 | 1 | stormheart_answer — guest says Yes | PASS + {"has_stormheart":true} | PASS | party holds the Stormheart=true; claim settled=true; answered accept by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (-2.0, 0.5, 0.0)), after 3 earlier line(s) and 3 offer line(s); captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer_f11/stormwood_f11_mirror_host_refuses_guest_accepts/peer-1/02_guest_offer_yes_no.png |
| 17 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:refused:character-f41f4a49223483d6bfdf56715944bb7b (any) set after 0 frames |
| 17 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:refused:character-f41f4a49223483d6bfdf56715944bb7b (any) set after 0 frames |
| 18 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-1b75041208a5185f4ee4702f50591c70 (any) set after 0 frames |
| 18 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-1b75041208a5185f4ee4702f50591c70 (any) set after 118 frames |
| 19 | 0 | stormheart_state — host refused, nothing granted | PASS + {"accepted_anywhere":false,"has_stormheart":false,"party":[],"world_accepted":false,"world_refused":true} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": [], "has_stormheart": false, "freed": true, "world_accepted": false, "world_refused": true, "accepted_anywhere": false } |
| 20 | 1 | stormheart_state — guest kept exactly one of its own | PASS + {"accepted_anywhere":true,"has_stormheart":true,"party":["fulgocobra"],"world_accepted":true,"world_refused":false} | PASS | { "character_id": "character-1b75041208a5185f4ee4702f50591c70", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true } |
| 21 | 1 | stormheart_answer — double press: the guest walks back and presses again; the answered prompt must not offer itself | FAIL | FAIL | the offer prompt is not offering itself to this player (enabled=false, standing nowhere in reach, label 'Answer the freed Stormheart') |
| 22 | 0 | stormheart_answer — the host cannot turn its No into a Yes by pressing again | FAIL | FAIL | the offer prompt is not offering itself to this player (enabled=false, standing nowhere in reach, label 'Answer the freed Stormheart') |
| 23 | 0 | stormheart_state — host still holds nothing after the second press | PASS + {"has_stormheart":false,"party":[],"world_accepted":false,"world_refused":true} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": [], "has_stormheart": false, "freed": true, "world_accepted": false, "world_refused": true, "accepted_anywhere": false } |
| 24 | 1 | stormheart_state — guest still holds exactly one Stormheart after the second press | PASS + {"has_stormheart":true,"party":["fulgocobra"]} | PASS | { "character_id": "character-1b75041208a5185f4ee4702f50591c70", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true } |
| 25 | 0 | screenshot | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer_f11/stormwood_f11_mirror_host_refuses_guest_accepts/peer-0/03_after_answers.png |
| 25 | 1 | screenshot | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer_f11/stormwood_f11_mirror_host_refuses_guest_accepts/peer-1/03_after_answers.png |
| 26 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer_f11/stormwood_f11_mirror_host_refuses_guest_accepts/peer-0/after |
| 26 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-1b75041208a5185f4ee4702f50591c70' on disk=true; copied 1 files to /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer_f11/stormwood_f11_mirror_host_refuses_guest_accepts/peer-1/after |
| 27 | 0 | check_saved — host's pre-offer saved world held no answers (non-vacuous baseline) | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under before/worlds |
| 28 | 0 | check_saved — host's pre-offer character held no answer | PASS | PASS | missing []; unexpectedly present []; read ["character-f41f4a49223483d6bfdf56715944bb7b/character.json"] under before/characters |
| 29 | 1 | check_saved — guest's pre-offer character held no answer (non-vacuous baseline) | PASS | PASS | missing []; unexpectedly present []; read ["character-1b75041208a5185f4ee4702f50591c70/character.json"] under before/characters |
| 30 | 0 | check_saved — host's saved world holds each answer once, the right way round | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under after/worlds |
| 31 | 0 | check_saved — host's saved character refused and holds none | PASS | PASS | missing []; unexpectedly present []; read ["character-f41f4a49223483d6bfdf56715944bb7b/character.json"] under after/characters |
| 32 | 1 | check_saved — guest's saved character keeps its Stormheart | PASS | PASS | missing []; unexpectedly present []; read ["character-1b75041208a5185f4ee4702f50591c70/character.json"] under after/characters |

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
- `peer-1/after/characters/character-1b75041208a5185f4ee4702f50591c70/character.json`
- `peer-1/before/characters/character-1b75041208a5185f4ee4702f50591c70/character.json`

---
Annotated after the run (not written by the runner): run dir `net/net-proof_two_peer-20260925T191033Z`. In the repo, `worlds/` and `characters/` files are committed gzipped (`.json.gz`), PNGs are 256-colour quantized, and `saves/` slot copies and `net/` logs are omitted for size (`NET-SUMMARY.md` is the harness summary). `SCRIPT ERROR` lines across both peer logs: 0.
