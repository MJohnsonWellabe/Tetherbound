# Two-peer proof: F11 capacity: guest full at five says Yes and gives up a belt member; host with space says Yes

**Verdict: PASS** (exit 0)

Scenario: `/tmp/claude-0/-home-user-Tetherbound/6363066d-9ebc-5645-8000-19dadf1d76a6/scratchpad/scen/stormwood_f11_capacity_guest_full_releases_belt.json`  
Run: `net-20261011T190900Z-6236`  
Rendered: no (headless)

ACCEPTANCE F11 'at capacity' + CLAUDE.md 'five creatures total, no hidden sixth': the guest's belt already holds five when it says Yes to its own Stormheart. The Stormheart does not take a sixth slot and is not silently dropped: Yes hands it to the Team tab's five-slot release ceremony (stormwood_ending.gd _begin_local_ceremony -> Game.pending_catch), where the guest, by ordinary presses, lets belt row 1 (bramblebun) go and the Stormheart takes that holder. The host, with a free slot, says Yes and keeps its own. Setup, disclosed: the Dynamo fight (contributors + Marrow's flag, as x05's fixture) and the guest's five belt members (peer_runner party_grant -> party_seam.add, the game's own add), since no named save with a full five exists; everything from the offer on is the game's own code.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: a fresh trainer in the Meadows | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | enter_realm — DISCLOSED SETUP: initial Hall arch position and the Stormwood portal open for this world (stands in for the earned Cloudreach-finale unlock), no earned credit | PASS | PASS | Disclosed initial actual ground/route fixture; return cases include an initial Home Key; no earned credit |
| 4 | 1 | enter_realm — DISCLOSED SETUP: initial Hall arch position and the Stormwood portal open for this world (stands in for the earned Cloudreach-finale unlock), no earned credit | PASS | PASS | Disclosed initial actual ground/route fixture; return cases include an initial Home Key; no earned credit |
| 5 | 1 | party_grant — SETUP: guest's belt member 1/5 (bramblebun) through party_seam.add (before host/join, so the host admits this roster) | PASS | PASS | 'bramblebun' at level 20 joined the party (1 member(s)) |
| 6 | 1 | party_grant — SETUP: guest's belt member 2/5 (terrapup) through party_seam.add (before host/join, so the host admits this roster) | PASS | PASS | 'terrapup' at level 20 joined the party (2 member(s)) |
| 7 | 1 | party_grant — SETUP: guest's belt member 3/5 (ripplet) through party_seam.add (before host/join, so the host admits this roster) | PASS | PASS | 'ripplet' at level 20 joined the party (3 member(s)) |
| 8 | 1 | party_grant — SETUP: guest's belt member 4/5 (galewisp) through party_seam.add (before host/join, so the host admits this roster) | PASS | PASS | 'galewisp' at level 20 joined the party (4 member(s)) |
| 9 | 1 | party_grant — SETUP: guest's belt member 5/5 (mudsnout) through party_seam.add (before host/join, so the host admits this roster) | PASS | PASS | 'mudsnout' at level 20 joined the party (5 member(s)) |
| 10 | 1 | party_grant — guest's belt is full: a sixth party_seam.add is refused (no sixth slot) (before host/join, so the host admits this roster) | FAIL | FAIL | party_seam.add('trailpup') refused -- the party is full (five, and there is no sixth slot) |
| 11 | 0 | host | PASS | PASS | hosting udp/35261 as peer 1 |
| 12 | 1 | join | PASS | PASS | joined 127.0.0.1:35261 as peer 1115076286 after 60 frames; snapshot applied; 2 peer(s) in registry |
| 13 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 13 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 14 | 0 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 14 | 1 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 15 | 1 | enter_realm — through the Crossing Hall Stormwood portal (RD-17) | PASS | PASS | crossed 'meadows' -> 'stormwood' after 841 observed physics frames / 36015 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 16 | 0 | enter_realm — through the Crossing Hall Stormwood portal (RD-17) | PASS | PASS | crossed 'meadows' -> 'stormwood' after 743 observed physics frames / 35556 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 17 | 0 | stormheart_state — host: free slots before the offer | PASS + {"has_stormheart":false,"party":[]} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": [], "has_stormheart": false, "freed": false, "world_accepted": false, "world_refused": false, "accepted_anywhere": false, "party_uids": [] } |
| 18 | 1 | stormheart_state — guest: exactly five before the offer | PASS + {"has_stormheart":false,"party":["bramblebun","terrapup","ripplet","galewisp","mudsnout"]} | PASS | { "character_id": "character-9fdd8e69ddaab5a891ee0ef3f1822b98", "party": ["bramblebun", "terrapup", "ripplet", "galewisp", "mudsnout"], "has_stormheart": false, "freed": false, "world_accepted": false, "world_refused": false, "accepted_anywhere": false, "party_uids": ["creature-4c133ef89227b1dd67b6532cb41bc7f3", "creature-5a922b599b4f5ec7d4c374475425685d", "creature-d16f1552ae6874c74ccbaf38731a69cc", "creature-2659fbcefa52c01e3679d31289fea543", "creature-58bb99b5d884b180f94d91b81b326317"] } |
| 19 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 19 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 20 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 5 files to /tmp/claude-0/-home-user-Tetherbound/6363066d-9ebc-5645-8000-19dadf1d76a6/scratchpad/capg/peer-0/before |
| 20 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-9fdd8e69ddaab5a891ee0ef3f1822b98' on disk=true; copied 3 files to /tmp/claude-0/-home-user-Tetherbound/6363066d-9ebc-5645-8000-19dadf1d76a6/scratchpad/capg/peer-1/before |
| 21 | 0 | stormheart_fixture — both fought the Dynamo (setup) | PASS | PASS | Dynamo contributors [1, 1115076286]; committed ["stormwood:act_ii_complete", "stormwood:marrow_defeated"] |
| 22 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 22 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 23 | 0 | stormheart_answer — host (space) says Yes | PASS + {"has_stormheart":true} | PASS | party holds the Stormheart=true; claim settled=true; answered accept by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 3 earlier line(s) and 3 offer line(s); headless peer: no frame to capture (run with --render) |
| 24 | 1 | stormheart_answer — guest (five) says Yes: the claim does NOT settle on its own -- no sixth slot, nothing added, nothing recorded yet; the ceremony holds it | FAIL + {"has_stormheart":false,"party":["bramblebun","terrapup","ripplet","galewisp","mudsnout"],"world_accepted":false,"world_refused":false} | FAIL | party holds the Stormheart=false; claim settled=false; answered accept by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 3 earlier line(s) and 3 offer line(s); headless peer: no frame to capture (run with --render) |
| 25 | 1 | probe input_context — the guest is now in the Team tab's ceremony, not the world | PASS | PASS | "panel:Session" |
| 26 | 1 | screenshot — guest: the Team tab's release ceremony is on screen (newcomer row focused) | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 27 | 1 | press — down from the newcomer row wraps to belt row 1 | PASS | PASS | pressed 'ui_down' x1 |
| 28 | 1 | press — A on belt row 1: this one goes free | PASS | PASS | pressed 'ui_accept' x1 |
| 29 | 1 | screenshot — the farewell question (Keep focused first) | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 30 | 1 | press — down to 'Let them go' | PASS | PASS | pressed 'ui_down' x1 |
| 31 | 1 | press — A: the one irreversible press | PASS | PASS | pressed 'ui_accept' x1 |
| 32 | 1 | screenshot — the goodbye beat | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 33 | 1 | press — A on the done button: the ceremony ends | PASS | PASS | pressed 'ui_accept' x1 |
| 34 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-f41f4a49223483d6bfdf56715944bb7b (any) set after 0 frames |
| 34 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-f41f4a49223483d6bfdf56715944bb7b (any) set after 0 frames |
| 35 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-9fdd8e69ddaab5a891ee0ef3f1822b98 (any) set after 0 frames |
| 35 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-9fdd8e69ddaab5a891ee0ef3f1822b98 (any) set after 0 frames |
| 36 | 1 | stormheart_state — guest: still five; bramblebun went free by its own choice, the Stormheart took that holder | PASS + {"accepted_anywhere":true,"has_stormheart":true,"party":["terrapup","ripplet","galewisp","mudsnout","fulgocobra"],"world_accepted":true,"world_refused":false} | PASS | { "character_id": "character-9fdd8e69ddaab5a891ee0ef3f1822b98", "party": ["terrapup", "ripplet", "galewisp", "mudsnout", "fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true, "party_uids": ["creature-5a922b599b4f5ec7d4c374475425685d", "creature-d16f1552ae6874c74ccbaf38731a69cc", "creature-2659fbcefa52c01e3679d31289fea543", "creature-58bb99b5d884b180f94d91b81b326317", "creature-92e5db3517c3313233e28dda53ab9149"] } |
| 37 | 0 | stormheart_state — host kept its own, independently | PASS + {"has_stormheart":true,"party":["fulgocobra"],"world_accepted":true,"world_refused":false} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true, "party_uids": ["creature-2b7b40b2cba81107cca2bbef53dc137e"] } |
| 38 | 1 | press — B closes the Team tab once the ceremony has let go | PASS | PASS | pressed 'menu_cancel' x1 |
| 39 | 1 | stormheart_answer — double press: the answered prompt must not offer the guest a second Stormheart | FAIL | FAIL | the offer prompt is not offering itself to this player (enabled=false, standing nowhere in reach, label 'Answer the freed Stormheart') |
| 40 | 1 | stormheart_state — guest still five with exactly one Stormheart | PASS + {"has_stormheart":true,"party":["terrapup","ripplet","galewisp","mudsnout","fulgocobra"]} | PASS | { "character_id": "character-9fdd8e69ddaab5a891ee0ef3f1822b98", "party": ["terrapup", "ripplet", "galewisp", "mudsnout", "fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true, "party_uids": ["creature-5a922b599b4f5ec7d4c374475425685d", "creature-d16f1552ae6874c74ccbaf38731a69cc", "creature-2659fbcefa52c01e3679d31289fea543", "creature-58bb99b5d884b180f94d91b81b326317", "creature-92e5db3517c3313233e28dda53ab9149"] } |
| 41 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 41 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 42 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 5 files to /tmp/claude-0/-home-user-Tetherbound/6363066d-9ebc-5645-8000-19dadf1d76a6/scratchpad/capg/peer-0/after |
| 42 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-9fdd8e69ddaab5a891ee0ef3f1822b98' on disk=true; copied 3 files to /tmp/claude-0/-home-user-Tetherbound/6363066d-9ebc-5645-8000-19dadf1d76a6/scratchpad/capg/peer-1/after |
| 43 | 0 | check_saved — host's pre-offer saved world held no answers (non-vacuous baseline) | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/slot-0/world.json"] under before/worlds |
| 44 | 0 | check_saved — host's pre-offer character held no answer | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-f41f4a49223483d6bfdf56715944bb7b/character.json"] under before/characters |
| 45 | 1 | check_saved — guest's pre-offer character held no answer | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-9fdd8e69ddaab5a891ee0ef3f1822b98/character.json"] under before/characters |
| 46 | 1 | check_saved — guest's pre-offer save held the five (baseline) | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-9fdd8e69ddaab5a891ee0ef3f1822b98/character.json"] under before/characters |
| 47 | 0 | check_saved — host's saved world: both accepted, each once | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/slot-0/world.json"] under after/worlds |
| 48 | 1 | check_saved — guest's saved character: the Stormheart in, the released bramblebun gone, the other four kept | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-9fdd8e69ddaab5a891ee0ef3f1822b98/character.json"] under after/characters |
| 49 | 0 | check_saved — host's saved character keeps its Stormheart | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-f41f4a49223483d6bfdf56715944bb7b/character.json"] under after/characters |

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
- `peer-1/after/characters/redesign-v28/character-9fdd8e69ddaab5a891ee0ef3f1822b98/character.json`
- `peer-1/after/saves/redesign-v28/characters/character-9fdd8e69ddaab5a891ee0ef3f1822b98/character.json`
- `peer-1/after/worlds/redesign-v28/slot-0/world.json`
- `peer-1/before/characters/redesign-v28/character-9fdd8e69ddaab5a891ee0ef3f1822b98/character.json`
- `peer-1/before/saves/redesign-v28/characters/character-9fdd8e69ddaab5a891ee0ef3f1822b98/character.json`
- `peer-1/before/worlds/redesign-v28/slot-0/world.json`
