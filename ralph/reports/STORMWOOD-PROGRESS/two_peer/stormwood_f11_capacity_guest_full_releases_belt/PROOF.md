# Two-peer proof: F11 capacity: guest full at five says Yes and gives up a belt member; host with space says Yes

**Verdict: PASS** (exit 0)

Scenario: `/home/user/tb-road/tools/net/proof_scenarios/stormwood_f11_capacity_guest_full_releases_belt.json`  
Run: `net-20260925T191830Z-22102`  
Rendered: yes

ACCEPTANCE F11 'at capacity' + CLAUDE.md 'five creatures total, no hidden sixth': the guest's belt already holds five when it says Yes to its own Stormheart. The Stormheart does not take a sixth slot and is not silently dropped: Yes hands it to the Team tab's five-slot release ceremony (stormwood_ending.gd _begin_local_ceremony -> Game.pending_catch), where the guest, by ordinary presses, lets belt row 1 (bramblebun) go and the Stormheart takes that holder. The host, with a free slot, says Yes and keeps its own. Setup, disclosed: the Dynamo fight (contributors + Marrow's flag, as x05's fixture) and the guest's five belt members (peer_runner party_grant -> party_seam.add, the game's own add), since no named save with a full five exists; everything from the offer on is the game's own code.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: a fresh trainer in the Meadows | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | host | PASS | PASS | hosting udp/32821 as peer 1 |
| 4 | 1 | join | PASS | PASS | joined 127.0.0.1:32821 as peer 939369931 after 8 frames; snapshot applied; 2 peer(s) in registry |
| 5 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 5 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 6 | 0 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 6 | 1 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 7 | 0 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 481 observed physics frames / 38879 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 8 | 1 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 434 observed physics frames / 22643 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 9 | 1 | party_grant — SETUP: guest's belt member 1/5 (bramblebun) through party_seam.add | PASS | PASS | 'bramblebun' at level 20 joined the party (1 member(s)) |
| 10 | 1 | party_grant — SETUP: guest's belt member 2/5 (terrapup) through party_seam.add | PASS | PASS | 'terrapup' at level 20 joined the party (2 member(s)) |
| 11 | 1 | party_grant — SETUP: guest's belt member 3/5 (ripplet) through party_seam.add | PASS | PASS | 'ripplet' at level 20 joined the party (3 member(s)) |
| 12 | 1 | party_grant — SETUP: guest's belt member 4/5 (galewisp) through party_seam.add | PASS | PASS | 'galewisp' at level 20 joined the party (4 member(s)) |
| 13 | 1 | party_grant — SETUP: guest's belt member 5/5 (mudsnout) through party_seam.add | PASS | PASS | 'mudsnout' at level 20 joined the party (5 member(s)) |
| 14 | 1 | party_grant — guest's belt is full: a sixth party_seam.add is refused (no sixth slot) | FAIL | FAIL | party_seam.add('trailpup') refused -- the party is full (five, and there is no sixth slot) |
| 15 | 0 | stormheart_state — host: free slots before the offer | PASS + {"has_stormheart":false,"party":[]} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": [], "has_stormheart": false, "freed": false, "world_accepted": false, "world_refused": false, "accepted_anywhere": false } |
| 16 | 1 | stormheart_state — guest: exactly five before the offer | PASS + {"has_stormheart":false,"party":["bramblebun","terrapup","ripplet","galewisp","mudsnout"]} | PASS | { "character_id": "character-180bcd1ee30651b6ab9dc9654e32fa96", "party": ["bramblebun", "terrapup", "ripplet", "galewisp", "mudsnout"], "has_stormheart": false, "freed": false, "world_accepted": false, "world_refused": false, "accepted_anywhere": false } |
| 17 | 0 | screenshot | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_guest_full_releases_belt/peer-0/01_both_in_stormwood.png |
| 17 | 1 | screenshot | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_guest_full_releases_belt/peer-1/01_both_in_stormwood.png |
| 18 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_guest_full_releases_belt/peer-0/before |
| 18 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-180bcd1ee30651b6ab9dc9654e32fa96' on disk=true; copied 1 files to /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_guest_full_releases_belt/peer-1/before |
| 19 | 0 | stormheart_fixture — both fought the Dynamo (setup) | PASS | PASS | Dynamo contributors [1, 939369931]; committed ["stormwood:act_ii_complete", "stormwood:marrow_defeated"] |
| 20 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 20 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 891 frames |
| 21 | 0 | stormheart_answer — host (space) says Yes | PASS + {"has_stormheart":true} | PASS | party holds the Stormheart=true; claim settled=true; answered accept by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 3 earlier line(s) and 3 offer line(s); captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_guest_full_releases_belt/peer-0/02_host_offer_yes_no.png |
| 22 | 1 | stormheart_answer — guest (five) says Yes: the claim does NOT settle on its own -- no sixth slot, nothing added, nothing recorded yet; the ceremony holds it | FAIL + {"has_stormheart":false,"party":["bramblebun","terrapup","ripplet","galewisp","mudsnout"],"world_accepted":false,"world_refused":false} | FAIL | party holds the Stormheart=false; claim settled=false; answered accept by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 3 earlier line(s) and 3 offer line(s); captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_guest_full_releases_belt/peer-1/02_guest_offer_yes_no.png |
| 23 | 1 | probe input_context — the guest is now in the Team tab's ceremony, not the world | PASS | PASS | "menu_creatures" |
| 24 | 1 | screenshot — guest: the Team tab's release ceremony is on screen (newcomer row focused) | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_guest_full_releases_belt/peer-1/03a_ceremony_choose.png |
| 25 | 1 | press — down from the newcomer row wraps to belt row 1 | PASS | PASS | pressed 'ui_down' x1 |
| 26 | 1 | press — A on belt row 1: this one goes free | PASS | PASS | pressed 'ui_accept' x1 |
| 27 | 1 | screenshot — the farewell question (Keep focused first) | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_guest_full_releases_belt/peer-1/03b_farewell_question.png |
| 28 | 1 | press — down to 'Let them go' | PASS | PASS | pressed 'ui_down' x1 |
| 29 | 1 | press — A: the one irreversible press | PASS | PASS | pressed 'ui_accept' x1 |
| 30 | 1 | screenshot — the goodbye beat | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_guest_full_releases_belt/peer-1/03c_goes_free.png |
| 31 | 1 | press — A on the done button: the ceremony ends | PASS | PASS | pressed 'ui_accept' x1 |
| 32 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-f41f4a49223483d6bfdf56715944bb7b (any) set after 0 frames |
| 32 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-f41f4a49223483d6bfdf56715944bb7b (any) set after 0 frames |
| 33 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-180bcd1ee30651b6ab9dc9654e32fa96 (any) set after 0 frames |
| 33 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-180bcd1ee30651b6ab9dc9654e32fa96 (any) set after 846 frames |
| 34 | 1 | stormheart_state — guest: still five; bramblebun went free by its own choice, the Stormheart took that holder | PASS + {"accepted_anywhere":true,"has_stormheart":true,"party":["terrapup","ripplet","galewisp","mudsnout","fulgocobra"],"world_accepted":true,"world_refused":false} | PASS | { "character_id": "character-180bcd1ee30651b6ab9dc9654e32fa96", "party": ["terrapup", "ripplet", "galewisp", "mudsnout", "fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true } |
| 35 | 0 | stormheart_state — host kept its own, independently | PASS + {"has_stormheart":true,"party":["fulgocobra"],"world_accepted":true,"world_refused":false} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true } |
| 36 | 1 | press — B closes the Team tab once the ceremony has let go | PASS | PASS | pressed 'menu_cancel' x1 |
| 37 | 1 | stormheart_answer — double press: the answered prompt must not offer the guest a second Stormheart | FAIL | FAIL | the offer prompt is not offering itself to this player (enabled=false, standing nowhere in reach, label 'Answer the freed Stormheart') |
| 38 | 1 | stormheart_state — guest still five with exactly one Stormheart | PASS + {"has_stormheart":true,"party":["terrapup","ripplet","galewisp","mudsnout","fulgocobra"]} | PASS | { "character_id": "character-180bcd1ee30651b6ab9dc9654e32fa96", "party": ["terrapup", "ripplet", "galewisp", "mudsnout", "fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true } |
| 39 | 0 | screenshot | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_guest_full_releases_belt/peer-0/04_after_answers.png |
| 39 | 1 | screenshot | PASS | PASS | captured 960x540 -> /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_guest_full_releases_belt/peer-1/04_after_answers.png |
| 40 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_guest_full_releases_belt/peer-0/after |
| 40 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-180bcd1ee30651b6ab9dc9654e32fa96' on disk=true; copied 1 files to /home/user/tb-road/ralph/reports/STORMWOOD-PROGRESS/two_peer/stormwood_f11_capacity_guest_full_releases_belt/peer-1/after |
| 41 | 0 | check_saved — host's pre-offer saved world held no answers (non-vacuous baseline) | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under before/worlds |
| 42 | 0 | check_saved — host's pre-offer character held no answer | PASS | PASS | missing []; unexpectedly present []; read ["character-f41f4a49223483d6bfdf56715944bb7b/character.json"] under before/characters |
| 43 | 1 | check_saved — guest's pre-offer character held no answer | PASS | PASS | missing []; unexpectedly present []; read ["character-180bcd1ee30651b6ab9dc9654e32fa96/character.json"] under before/characters |
| 44 | 1 | check_saved — guest's pre-offer save held the five (baseline) | PASS | PASS | missing []; unexpectedly present []; read ["character-180bcd1ee30651b6ab9dc9654e32fa96/character.json"] under before/characters |
| 45 | 0 | check_saved — host's saved world: both accepted, each once | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under after/worlds |
| 46 | 1 | check_saved — guest's saved character: the Stormheart in, the released bramblebun gone, the other four kept | PASS | PASS | missing []; unexpectedly present []; read ["character-180bcd1ee30651b6ab9dc9654e32fa96/character.json"] under after/characters |
| 47 | 0 | check_saved — host's saved character keeps its Stormheart | PASS | PASS | missing []; unexpectedly present []; read ["character-f41f4a49223483d6bfdf56715944bb7b/character.json"] under after/characters |

## Captured files

- `peer-0/01_both_in_stormwood.png`
- `peer-0/02_host_offer_yes_no.png`
- `peer-0/04_after_answers.png`
- `peer-0/after/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/worlds/slot-0/world.json`
- `peer-0/before/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/before/saves/slot_0.json`
- `peer-0/before/worlds/slot-0/world.json`
- `peer-1/01_both_in_stormwood.png`
- `peer-1/02_guest_offer_yes_no.png`
- `peer-1/03a_ceremony_choose.png`
- `peer-1/03b_farewell_question.png`
- `peer-1/03c_goes_free.png`
- `peer-1/04_after_answers.png`
- `peer-1/after/characters/character-180bcd1ee30651b6ab9dc9654e32fa96/character.json`
- `peer-1/before/characters/character-180bcd1ee30651b6ab9dc9654e32fa96/character.json`

---
Annotated after the run (not written by the runner): run dir `net/net-proof_two_peer-20260925T191830Z`. In the repo, `worlds/` and `characters/` files are committed gzipped (`.json.gz`), PNGs are 256-colour quantized, and `saves/` slot copies and `net/` logs are omitted for size (`NET-SUMMARY.md` is the harness summary). `SCRIPT ERROR` lines across both peer logs: 0.
