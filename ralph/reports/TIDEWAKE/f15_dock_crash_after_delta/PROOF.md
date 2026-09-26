# Two-peer proof: F15: paid dock debit survives a guest crash (after_delta)

**Verdict: PASS** (exit 0)

Scenario: `/home/user/tb-pockets/tools/net/proof_scenarios/f15_dock_crash_after_delta.json`  
Run: `net-20260926T031557Z-26335`  
Rendered: no (headless)

ACCEPTANCE F15 (T3): 'including paid-debit crash/retry'. Same setup as f15_dock_exchange_once. The guest presses the paid repair and its process 'crashes' after the host's commit reached it (its bag debited in memory) but before any character save: the stand-in pulls the transport (no Session.leave) and, in that same frame, drops everything the process holds and reads its character back from disk with no save, as a restarted process would. The guest then relaunches through the title's returning Join (its character loaded from disk) into the still-running host and presses the repair again (a real retry; forced if the prompt is already dark). The repair must be done exactly once and the guest's 6 reed fiber + 4 driftwood taken exactly once (not zero, not twice), in memory and on disk, and the retry must not charge again.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: the host's world | PASS + {"realm":"meadows"} | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: its own trainer | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | host | PASS | PASS | hosting udp/31461 as peer 1 |
| 4 | 1 | join | PASS | PASS | joined 127.0.0.1:31461 as peer 1439593904 after 14 frames; snapshot applied; 2 peer(s) in registry |
| 5 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 5 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 6 | 0 | story_flag — SETUP: the Water route is open (stands in for Stormwood) | PASS | PASS | realm_gate_water_unlocked: ok=true pending=false code='' reason='' |
| 7 | 0 | story_flag — SETUP: the Water key (stands in for Stormwood) | PASS | PASS | realm_key_water: ok=true pending=false code='' reason='' |
| 8 | 0 | story_flag — SETUP: the swim lesson is done (the repair's prerequisite) | PASS | PASS | water_swim_lesson_complete: ok=true pending=false code='' reason='' |
| 9 | 0 | wait_flag | PASS | PASS | flag water_swim_lesson_complete (world) set after 0 frames |
| 9 | 1 | wait_flag | PASS | PASS | flag water_swim_lesson_complete (world) set after 0 frames |
| 10 | 0 | enter_realm — host enters Water | PASS | PASS | crossed 'meadows' -> 'water' after 278 observed physics frames / 22343 ms (budget 6000 physics frames); current scene is /root/WaterArchipelago |
| 11 | 1 | enter_realm — guest enters Water | PASS | PASS | crossed 'meadows' -> 'water' after 467 observed physics frames / 15661 ms (budget 6000 physics frames); current scene is /root/WaterArchipelago |
| 12 | 0 | water_dock_state — SETUP: 8 reed fiber + 6 driftwood gathered and saved (cost is 6 + 4) | PASS + {"bag":{"driftwood":6.0,"reed_fiber":8.0},"disk":{"driftwood":6.0,"reed_fiber":8.0}} | PASS | SETUP (stands in for gathering): bag { "driftwood": 6, "reed_fiber": 8 }, on disk { "driftwood": 6, "reed_fiber": 8 }, saved=true; then { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "done": { "reedhaven_repair": false, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": false }, "bag": { "reed_fiber": 8, "driftwood": 6 }, "disk": { "reed_fiber": 8, "driftwood": 6 }, "prompt_enabled": <null>, "session_active": true, "realm": "water" } |
| 12 | 1 | water_dock_state — SETUP: 8 reed fiber + 6 driftwood gathered and saved (cost is 6 + 4) | PASS + {"bag":{"driftwood":6.0,"reed_fiber":8.0},"disk":{"driftwood":6.0,"reed_fiber":8.0}} | PASS | SETUP (stands in for gathering): bag { "driftwood": 6, "reed_fiber": 8 }, on disk { "driftwood": 6, "reed_fiber": 8 }, saved=true; then { "character_id": "character-2355b7dfc4a50258daa9e3a1bc41aaf1", "done": { "reedhaven_repair": false, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": false }, "bag": { "reed_fiber": 8, "driftwood": 6 }, "disk": { "reed_fiber": 8, "driftwood": 6 }, "prompt_enabled": <null>, "session_active": true, "realm": "water" } |
| 13 | 0 | water_dock_state — before: nothing done, the repair offered (baseline) | PASS + {"done":{"deep_watch_chart":false,"reedhaven_repair":false},"prompt_enabled":true} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "done": { "reedhaven_repair": false, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": false }, "bag": { "reed_fiber": 8, "driftwood": 6 }, "disk": { "reed_fiber": 8, "driftwood": 6 }, "prompt_enabled": true, "session_active": true, "realm": "water" } |
| 13 | 1 | water_dock_state — before: nothing done, the repair offered (baseline) | PASS + {"done":{"deep_watch_chart":false,"reedhaven_repair":false},"prompt_enabled":true} | PASS | { "character_id": "character-2355b7dfc4a50258daa9e3a1bc41aaf1", "done": { "reedhaven_repair": false, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": false }, "bag": { "reed_fiber": 8, "driftwood": 6 }, "disk": { "reed_fiber": 8, "driftwood": 6 }, "prompt_enabled": true, "session_active": true, "realm": "water" } |
| 14 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to /home/user/tb-pockets/ralph/reports/TIDEWAKE/f15_dock_crash_after_delta/peer-0/before |
| 14 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-2355b7dfc4a50258daa9e3a1bc41aaf1' on disk=true; copied 1 files to /home/user/tb-pockets/ralph/reports/TIDEWAKE/f15_dock_crash_after_delta/peer-1/before |
| 15 | 1 | water_dock_act — guest presses the paid repair, then crashes (after_delta) | PASS | PASS | prompt activated (offered) standing (1.4, 0.3, 0.0); flag false -> true; bag { "reed_fiber": 8, "driftwood": 6 } -> { "reed_fiber": 2, "driftwood": 2 } (disk { "reed_fiber": 8, "driftwood": 6 } -> { "reed_fiber": 2, "driftwood": 2 }); item_take ops seen []; refusals []; CRASH stand-in: transport closed; character 'character-2355b7dfc4a50258daa9e3a1bc41aaf1' read back from disk=true (no save) |
| 16 | 0 | expect_peers — host sees the guest gone | PASS | PASS | registry reports 1 peer(s) after 0 frames |
| 17 | 0 | water_dock_state — host: did the repair commit before the crash? (reported) | PASS | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "done": { "reedhaven_repair": true, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": false }, "bag": { "reed_fiber": 8, "driftwood": 6 }, "disk": { "reed_fiber": 8, "driftwood": 6 }, "prompt_enabled": false, "session_active": true, "realm": "water" } |
| 18 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to /home/user/tb-pockets/ralph/reports/TIDEWAKE/f15_dock_crash_after_delta/peer-0/host_after_crash |
| 19 | 1 | water_dock_state — guest after the crash stand-in, before rejoin (reported) | PASS | PASS | { "character_id": "character-2355b7dfc4a50258daa9e3a1bc41aaf1", "done": { "reedhaven_repair": true, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": false }, "bag": { "reed_fiber": 2, "driftwood": 2 }, "disk": { "reed_fiber": 2, "driftwood": 2 }, "prompt_enabled": <null>, "session_active": false, "realm": "water" } |
| 20 | 1 | water_dock_state — guest relaunches: the title's returning Join loads its character from disk and rejoins the same host | PASS | PASS | REJOIN: title returning entry built 'WaterArchipelago' first, then JoinDriver joined 127.0.0.1:31461 as peer 849392864 after 49 frames; then { "character_id": "character-2355b7dfc4a50258daa9e3a1bc41aaf1", "done": { "reedhaven_repair": true, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": false }, "bag": { "reed_fiber": 2, "driftwood": 2 }, "disk": { "reed_fiber": 2, "driftwood": 2 }, "prompt_enabled": <null>, "session_active": true, "realm": "water" } |
| 21 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 21 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 22 | 1 | water_dock_state — guest after rejoin (reported) | PASS | PASS | { "character_id": "character-2355b7dfc4a50258daa9e3a1bc41aaf1", "done": { "reedhaven_repair": true, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": false }, "bag": { "reed_fiber": 2, "driftwood": 2 }, "disk": { "reed_fiber": 2, "driftwood": 2 }, "prompt_enabled": <null>, "session_active": true, "realm": "water" } |
| 23 | 1 | water_dock_act — guest retries the repair after rejoin (presses it; forced if the prompt is already dark) | PASS | PASS | prompt activated (FORCED: prompt dark, stale-client resend) standing (not offered); flag true -> true; bag { "reed_fiber": 2, "driftwood": 2 } -> { "reed_fiber": 2, "driftwood": 2 } (disk { "reed_fiber": 2, "driftwood": 2 } -> { "reed_fiber": 2, "driftwood": 2 }); item_take ops seen []; refusals [] |
| 24 | 0 | wait_flag — the repair is done in the world | PASS | PASS | flag water_dock_reedhaven_repaired (world) set after 0 frames |
| 24 | 1 | wait_flag — the repair is done in the world | PASS | PASS | flag water_dock_reedhaven_repaired (world) set after 0 frames |
| 25 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-2355b7dfc4a50258daa9e3a1bc41aaf1' on disk=true; copied 1 files to /home/user/tb-pockets/ralph/reports/TIDEWAKE/f15_dock_crash_after_delta/peer-1/after_retry |
| 26 | 1 | water_dock_state — ASSERT: crash + rejoin + retry: repair done once, the guest paid exactly once (6+4), in memory and on disk | PASS + {"bag":{"driftwood":2.0,"reed_fiber":2.0},"disk":{"driftwood":2.0,"reed_fiber":2.0},"done":{"reedhaven_repair":true}} | PASS | { "character_id": "character-2355b7dfc4a50258daa9e3a1bc41aaf1", "done": { "reedhaven_repair": true, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": false }, "bag": { "reed_fiber": 2, "driftwood": 2 }, "disk": { "reed_fiber": 2, "driftwood": 2 }, "prompt_enabled": <null>, "session_active": true, "realm": "water" } |
| 27 | 1 | water_dock_act — ASSERT: a second retry charges nothing | PASS + {"flag_before":true,"taken":{"driftwood":0.0,"reed_fiber":0.0}} | PASS | prompt activated (FORCED: prompt dark, stale-client resend) standing (not offered); flag true -> true; bag { "reed_fiber": 2, "driftwood": 2 } -> { "reed_fiber": 2, "driftwood": 2 } (disk { "reed_fiber": 2, "driftwood": 2 } -> { "reed_fiber": 2, "driftwood": 2 }); item_take ops seen []; refusals [] |
| 28 | 0 | water_dock_act — host presses the finished repair: not charged | PASS + {"flag_before":true,"taken":{"driftwood":0.0,"reed_fiber":0.0}} | PASS | prompt activated (FORCED: prompt dark, stale-client resend) standing (not offered); flag true -> true; bag { "reed_fiber": 8, "driftwood": 6 } -> { "reed_fiber": 8, "driftwood": 6 } (disk { "reed_fiber": 8, "driftwood": 6 } -> { "reed_fiber": 8, "driftwood": 6 }); item_take ops seen []; refusals [] |
| 29 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to /home/user/tb-pockets/ralph/reports/TIDEWAKE/f15_dock_crash_after_delta/peer-0/after |
| 29 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-2355b7dfc4a50258daa9e3a1bc41aaf1' on disk=true; copied 1 files to /home/user/tb-pockets/ralph/reports/TIDEWAKE/f15_dock_crash_after_delta/peer-1/after |
| 30 | 1 | water_dock_state — ASSERT final: guest paid exactly once | PASS + {"bag":{"driftwood":2.0,"reed_fiber":2.0},"disk":{"driftwood":2.0,"reed_fiber":2.0},"done":{"reedhaven_repair":true}} | PASS | { "character_id": "character-2355b7dfc4a50258daa9e3a1bc41aaf1", "done": { "reedhaven_repair": true, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": false }, "bag": { "reed_fiber": 2, "driftwood": 2 }, "disk": { "reed_fiber": 2, "driftwood": 2 }, "prompt_enabled": <null>, "session_active": true, "realm": "water" } |
| 31 | 0 | water_dock_state — host never charged | PASS + {"bag":{"driftwood":6.0,"reed_fiber":8.0},"disk":{"driftwood":6.0,"reed_fiber":8.0}} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "done": { "reedhaven_repair": true, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": false }, "bag": { "reed_fiber": 8, "driftwood": 6 }, "disk": { "reed_fiber": 8, "driftwood": 6 }, "prompt_enabled": <null>, "session_active": true, "realm": "water" } |
| 32 | 0 | check_saved — host's saved world holds the repair | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under after/worlds |

## Captured files

- `peer-0/after/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/after/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json.gz`
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/worlds/slot-0/world.json`
- `peer-0/after/worlds/slot-0/world.json.gz`
- `peer-0/before/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/before/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json.gz`
- `peer-0/before/saves/slot_0.json`
- `peer-0/before/worlds/slot-0/world.json`
- `peer-0/before/worlds/slot-0/world.json.gz`
- `peer-0/host_after_crash/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/host_after_crash/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json.gz`
- `peer-0/host_after_crash/saves/slot_0.json`
- `peer-0/host_after_crash/worlds/slot-0/world.json`
- `peer-0/host_after_crash/worlds/slot-0/world.json.gz`
- `peer-1/after/characters/character-2355b7dfc4a50258daa9e3a1bc41aaf1/character.json`
- `peer-1/after/characters/character-50f6969fdbaa8eb1339f2383a3023c29/character.json.gz`
- `peer-1/after_retry/characters/character-2355b7dfc4a50258daa9e3a1bc41aaf1/character.json`
- `peer-1/after_retry/characters/character-50f6969fdbaa8eb1339f2383a3023c29/character.json.gz`
- `peer-1/before/characters/character-2355b7dfc4a50258daa9e3a1bc41aaf1/character.json`
- `peer-1/before/characters/character-50f6969fdbaa8eb1339f2383a3023c29/character.json.gz`
- `render/PROOF.md`
- `render/net/net-proof_two_peer-20260926T022015Z/NET_RUN.json`
- `render/net/net-proof_two_peer-20260926T022015Z/SUMMARY.md`
- `render/peer-0/after/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json.gz`
- `render/peer-0/after/worlds/slot-0/world.json.gz`
- `render/peer-0/before/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json.gz`
- `render/peer-0/before/worlds/slot-0/world.json.gz`
- `render/peer-0/host_after_crash/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json.gz`
- `render/peer-0/host_after_crash/worlds/slot-0/world.json.gz`
- `render/peer-1/after/characters/character-85df773f8db00a6ea3b072c0a7dc10c4/character.json.gz`
- `render/peer-1/after_retry/characters/character-85df773f8db00a6ea3b072c0a7dc10c4/character.json.gz`
- `render/peer-1/before/characters/character-85df773f8db00a6ea3b072c0a7dc10c4/character.json.gz`
