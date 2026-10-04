# Two-peer proof: F11 capacity: guest full at five says Yes and gives up a belt member; host with space says Yes

**Verdict: FAIL** (exit 1)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/stormwood_f11_capacity_guest_full_releases_belt.json`  
Run: `net-20261004T225853Z-14152`  
Rendered: no (headless)

ACCEPTANCE F11 'at capacity' + CLAUDE.md 'five creatures total, no hidden sixth': the guest's belt already holds five when it says Yes to its own Stormheart. The Stormheart does not take a sixth slot and is not silently dropped: Yes hands it to the Team tab's five-slot release ceremony (stormwood_ending.gd _begin_local_ceremony -> Game.pending_catch), where the guest, by ordinary presses, lets belt row 1 (bramblebun) go and the Stormheart takes that holder. The host, with a free slot, says Yes and keeps its own. Setup, disclosed: the Dynamo fight (contributors + Marrow's flag, as x05's fixture) and the guest's five belt members (peer_runner party_grant -> party_seam.add, the game's own add), since no named save with a full five exists; everything from the offer on is the game's own code.

## Failures

- #33 peer 0 wait_flag -> FAIL -- flag stormwood:legendary_resolution:accepted:character-58b41dc557923e24d858575175c7b123 (any) never set within 1800 frames

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: a fresh trainer in the Meadows | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | host | PASS | PASS | hosting udp/35341 as peer 1 |
| 4 | 1 | join | PASS | PASS | joined 127.0.0.1:35341 as peer 649561504 after 21 frames; snapshot applied; 2 peer(s) in registry |
| 5 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 5 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 6 | 0 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 6 | 1 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 7 | 0 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 494 observed physics frames / 46306 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 8 | 1 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 523 observed physics frames / 35856 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 9 | 1 | party_grant — SETUP: guest's belt member 1/5 (bramblebun) through party_seam.add | PASS | PASS | 'bramblebun' at level 20 joined the party (1 member(s)) |
| 10 | 1 | party_grant — SETUP: guest's belt member 2/5 (terrapup) through party_seam.add | PASS | PASS | 'terrapup' at level 20 joined the party (2 member(s)) |
| 11 | 1 | party_grant — SETUP: guest's belt member 3/5 (ripplet) through party_seam.add | PASS | PASS | 'ripplet' at level 20 joined the party (3 member(s)) |
| 12 | 1 | party_grant — SETUP: guest's belt member 4/5 (galewisp) through party_seam.add | PASS | PASS | 'galewisp' at level 20 joined the party (4 member(s)) |
| 13 | 1 | party_grant — SETUP: guest's belt member 5/5 (mudsnout) through party_seam.add | PASS | PASS | 'mudsnout' at level 20 joined the party (5 member(s)) |
| 14 | 1 | party_grant — guest's belt is full: a sixth party_seam.add is refused (no sixth slot) | FAIL | FAIL | party_seam.add('trailpup') refused -- the party is full (five, and there is no sixth slot) |
| 15 | 0 | stormheart_state — host: free slots before the offer | PASS + {"has_stormheart":false,"party":[]} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "party": [], "has_stormheart": false, "freed": false, "world_accepted": false, "world_refused": false, "accepted_anywhere": false, "party_uids": [] } |
| 16 | 1 | stormheart_state — guest: exactly five before the offer | PASS + {"has_stormheart":false,"party":["bramblebun","terrapup","ripplet","galewisp","mudsnout"]} | PASS | { "character_id": "character-58b41dc557923e24d858575175c7b123", "party": ["bramblebun", "terrapup", "ripplet", "galewisp", "mudsnout"], "has_stormheart": false, "freed": false, "world_accepted": false, "world_refused": false, "accepted_anywhere": false, "party_uids": ["creature-798117f5a5a08206ce4159b70c2f95c2", "creature-c9ce387584c0816ec5b2417894b1b8ad", "creature-c867fd868bdefb19456bb865ee8505fb", "creature-4a1d8ff64e9611f4b67086806ebedfe9", "creature-6db1b2f36190259392172856b4933337"] } |
| 17 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 17 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 18 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to /tmp/claude-0/-home-user-Tetherbound/6050aa73-5362-5e48-a427-17c5687ec66b/scratchpad/proofs/F11-1-cap_guest-v28/peer-0/before |
| 18 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-58b41dc557923e24d858575175c7b123' on disk=true; copied 2 files to /tmp/claude-0/-home-user-Tetherbound/6050aa73-5362-5e48-a427-17c5687ec66b/scratchpad/proofs/F11-1-cap_guest-v28/peer-1/before |
| 19 | 0 | stormheart_fixture — both fought the Dynamo (setup) | PASS | PASS | Dynamo contributors [1, 649561504]; committed ["stormwood:act_ii_complete", "stormwood:marrow_defeated"] |
| 20 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 20 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_freed (any) set after 433 frames |
| 21 | 0 | stormheart_answer — host (space) says Yes | PASS + {"has_stormheart":true} | PASS | party holds the Stormheart=true; claim settled=true; answered accept by pressing the enabled prompt '' 0 time(s) (standing (2.0, 0.5, 0.0)), after 3 earlier line(s) and 3 offer line(s); headless peer: no frame to capture (run with --render) |
| 22 | 1 | stormheart_answer — guest (five) says Yes: the claim does NOT settle on its own -- no sixth slot, nothing added, nothing recorded yet; the ceremony holds it | FAIL + {"has_stormheart":false,"party":["bramblebun","terrapup","ripplet","galewisp","mudsnout"],"world_accepted":false,"world_refused":false} | FAIL | party holds the Stormheart=false; claim settled=false; answered accept by pressing the enabled prompt 'Accept the Stormheart's offer' 1 time(s) (standing (2.0, 0.5, 0.0)), after 3 earlier line(s) and 3 offer line(s); headless peer: no frame to capture (run with --render) |
| 23 | 1 | probe input_context — the guest is now in the Team tab's ceremony, not the world | PASS | PASS | "menu_creatures" |
| 24 | 1 | screenshot — guest: the Team tab's release ceremony is on screen (newcomer row focused) | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 25 | 1 | press — down from the newcomer row wraps to belt row 1 | PASS | PASS | pressed 'ui_down' x1 |
| 26 | 1 | press — A on belt row 1: this one goes free | PASS | PASS | pressed 'ui_accept' x1 |
| 27 | 1 | screenshot — the farewell question (Keep focused first) | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 28 | 1 | press — down to 'Let them go' | PASS | PASS | pressed 'ui_down' x1 |
| 29 | 1 | press — A: the one irreversible press | PASS | PASS | pressed 'ui_accept' x1 |
| 30 | 1 | screenshot — the goodbye beat | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 31 | 1 | press — A on the done button: the ceremony ends | PASS | PASS | pressed 'ui_accept' x1 |
| 32 | 0 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-f41f4a49223483d6bfdf56715944bb7b (any) set after 0 frames |
| 32 | 1 | wait_flag | PASS | PASS | flag stormwood:legendary_resolution:accepted:character-f41f4a49223483d6bfdf56715944bb7b (any) set after 0 frames |
| 33 | 0 | wait_flag | PASS | FAIL **(unexpected)** | flag stormwood:legendary_resolution:accepted:character-58b41dc557923e24d858575175c7b123 (any) never set within 1800 frames |

## Captured files

- `peer-0/before/characters/redesign-v28/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/before/saves/redesign-v28/slot_0.json`
- `peer-0/before/worlds/redesign-v28/slot-0/world.json`
- `peer-1/before/characters/redesign-v28/character-58b41dc557923e24d858575175c7b123/character.json`
- `peer-1/before/saves/redesign-v28/characters/character-58b41dc557923e24d858575175c7b123/character.json`
