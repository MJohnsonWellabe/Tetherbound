# Two-peer proof: F15: host and guest settle the dock exchange once

**Verdict: PASS** (exit 0)

Scenario: `/home/user/tb-pockets/tools/net/proof_scenarios/f15_dock_exchange_once.json`  
Run: `net-20260926T032617Z-27641`  
Rendered: no (headless)

ACCEPTANCE F15 (T3): 'Host and guest settle the dock exchange once' - the ordinary (no-crash) half. Setup stands in for reaching Water with the swim lesson done and the materials gathered only. The guest walks to the Reedhaven departure dock and presses 'Repair departure dock' (the one PAID dock action: 6 reed fiber + 4 driftwood) through the real prompt; the host presses a different action (Deep Watch chart, free). Each must be done once, the payer's cost taken exactly once, and later presses of the finished repair by either player charge nothing.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: the host's world | PASS + {"realm":"meadows"} | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: its own trainer | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | host | PASS | PASS | hosting udp/32401 as peer 1 |
| 4 | 1 | join | PASS | PASS | joined 127.0.0.1:32401 as peer 842233649 after 10 frames; snapshot applied; 2 peer(s) in registry |
| 5 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 5 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 6 | 0 | story_flag — SETUP: the Water route is open (stands in for Stormwood) | PASS | PASS | realm_gate_water_unlocked: ok=true pending=false code='' reason='' |
| 7 | 0 | story_flag — SETUP: the Water key (stands in for Stormwood) | PASS | PASS | realm_key_water: ok=true pending=false code='' reason='' |
| 8 | 0 | story_flag — SETUP: the swim lesson is done (the repair's prerequisite) | PASS | PASS | water_swim_lesson_complete: ok=true pending=false code='' reason='' |
| 9 | 0 | story_flag — SETUP: Tidecoil resolved (the free Deep Watch chart's prerequisite since F13 6b022c8b3) | PASS | PASS | water_named_deep_watch_tidecoil_resolved: ok=true pending=false code='' reason='' |
| 10 | 0 | wait_flag | PASS | PASS | flag water_swim_lesson_complete (world) set after 0 frames |
| 10 | 1 | wait_flag | PASS | PASS | flag water_swim_lesson_complete (world) set after 0 frames |
| 11 | 0 | wait_flag | PASS | PASS | flag water_named_deep_watch_tidecoil_resolved (world) set after 0 frames |
| 11 | 1 | wait_flag | PASS | PASS | flag water_named_deep_watch_tidecoil_resolved (world) set after 0 frames |
| 12 | 0 | enter_realm — host enters Water | PASS | PASS | crossed 'meadows' -> 'water' after 279 observed physics frames / 23366 ms (budget 6000 physics frames); current scene is /root/WaterArchipelago |
| 13 | 1 | enter_realm — guest enters Water | PASS | PASS | crossed 'meadows' -> 'water' after 464 observed physics frames / 15849 ms (budget 6000 physics frames); current scene is /root/WaterArchipelago |
| 14 | 0 | water_dock_state — SETUP: 8 reed fiber + 6 driftwood gathered and saved (cost is 6 + 4) | PASS + {"bag":{"driftwood":6.0,"reed_fiber":8.0},"disk":{"driftwood":6.0,"reed_fiber":8.0}} | PASS | SETUP (stands in for gathering): bag { "driftwood": 6, "reed_fiber": 8 }, on disk { "driftwood": 6, "reed_fiber": 8 }, saved=true; then { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "done": { "reedhaven_repair": false, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": false }, "bag": { "reed_fiber": 8, "driftwood": 6 }, "disk": { "reed_fiber": 8, "driftwood": 6 }, "prompt_enabled": <null>, "session_active": true, "realm": "water" } |
| 14 | 1 | water_dock_state — SETUP: 8 reed fiber + 6 driftwood gathered and saved (cost is 6 + 4) | PASS + {"bag":{"driftwood":6.0,"reed_fiber":8.0},"disk":{"driftwood":6.0,"reed_fiber":8.0}} | PASS | SETUP (stands in for gathering): bag { "driftwood": 6, "reed_fiber": 8 }, on disk { "driftwood": 6, "reed_fiber": 8 }, saved=true; then { "character_id": "character-dc6171ef36123d52acc7e186af75ac16", "done": { "reedhaven_repair": false, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": false }, "bag": { "reed_fiber": 8, "driftwood": 6 }, "disk": { "reed_fiber": 8, "driftwood": 6 }, "prompt_enabled": <null>, "session_active": true, "realm": "water" } |
| 15 | 0 | water_dock_state — before: nothing done, the repair offered (baseline) | PASS + {"done":{"deep_watch_chart":false,"reedhaven_repair":false},"prompt_enabled":true} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "done": { "reedhaven_repair": false, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": false }, "bag": { "reed_fiber": 8, "driftwood": 6 }, "disk": { "reed_fiber": 8, "driftwood": 6 }, "prompt_enabled": true, "session_active": true, "realm": "water" } |
| 15 | 1 | water_dock_state — before: nothing done, the repair offered (baseline) | PASS + {"done":{"deep_watch_chart":false,"reedhaven_repair":false},"prompt_enabled":true} | PASS | { "character_id": "character-dc6171ef36123d52acc7e186af75ac16", "done": { "reedhaven_repair": false, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": false }, "bag": { "reed_fiber": 8, "driftwood": 6 }, "disk": { "reed_fiber": 8, "driftwood": 6 }, "prompt_enabled": true, "session_active": true, "realm": "water" } |
| 16 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to /home/user/tb-pockets/ralph/reports/TIDEWAKE/f15_dock_exchange_once/peer-0/before |
| 16 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-dc6171ef36123d52acc7e186af75ac16' on disk=true; copied 1 files to /home/user/tb-pockets/ralph/reports/TIDEWAKE/f15_dock_exchange_once/peer-1/before |
| 17 | 1 | water_dock_act — guest pays for the repair through the real prompt (F15 escrow: the cost is debited and saved at the press; the host sends no item_take) | PASS + {"disk_after":{"driftwood":2.0,"reed_fiber":2.0},"flag_after":true,"flag_before":false,"item_takes":[],"offered":true,"taken":{"driftwood":4.0,"reed_fiber":6.0}} | PASS | interact on the offered prompt standing (1.4, 0.3, 0.0); flag false -> true; bag { "reed_fiber": 8, "driftwood": 6 } -> { "reed_fiber": 2, "driftwood": 2 } (disk { "reed_fiber": 8, "driftwood": 6 } -> { "reed_fiber": 2, "driftwood": 2 }); item_take ops seen []; refusals [] |
| 18 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 19 | 0 | wait_flag | PASS | PASS | flag water_dock_reedhaven_repaired (world) set after 0 frames |
| 20 | 0 | water_dock_state — host sees it done and paid nothing | PASS + {"bag":{"driftwood":6.0,"reed_fiber":8.0},"done":{"reedhaven_repair":true},"prompt_enabled":false} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "done": { "reedhaven_repair": true, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": false }, "bag": { "reed_fiber": 8, "driftwood": 6 }, "disk": { "reed_fiber": 8, "driftwood": 6 }, "prompt_enabled": false, "session_active": true, "realm": "water" } |
| 21 | 0 | water_dock_act — host does a different (free) dock action | PASS + {"flag_after":true,"flag_before":false,"offered":true,"taken":{}} | PASS | interact on the offered prompt standing (1.4, 0.3, 0.0); flag false -> true; bag {  } -> {  } (disk {  } -> {  }); item_take ops seen []; refusals [] |
| 22 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 23 | 1 | wait_flag | PASS | PASS | flag water_dock_deep_watch_current_charted (world) set after 0 frames |
| 24 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-dc6171ef36123d52acc7e186af75ac16' on disk=true; copied 1 files to /home/user/tb-pockets/ralph/reports/TIDEWAKE/f15_dock_exchange_once/peer-1/after_pay |
| 25 | 1 | water_dock_state — guest charged exactly once, in memory and on disk | PASS + {"bag":{"driftwood":2.0,"reed_fiber":2.0},"disk":{"driftwood":2.0,"reed_fiber":2.0},"done":{"deep_watch_chart":true,"reedhaven_repair":true},"prompt_enabled":false} | PASS | { "character_id": "character-dc6171ef36123d52acc7e186af75ac16", "done": { "reedhaven_repair": true, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": true }, "bag": { "reed_fiber": 2, "driftwood": 2 }, "disk": { "reed_fiber": 2, "driftwood": 2 }, "prompt_enabled": false, "session_active": true, "realm": "water" } |
| 26 | 1 | water_dock_act — guest retries the finished repair (stale resend): no second charge | PASS + {"flag_before":true,"taken":{"driftwood":0.0,"reed_fiber":0.0}} | PASS | prompt activated (FORCED: prompt dark, stale-client resend) standing (not offered); flag true -> true; bag { "reed_fiber": 2, "driftwood": 2 } -> { "reed_fiber": 2, "driftwood": 2 } (disk { "reed_fiber": 2, "driftwood": 2 } -> { "reed_fiber": 2, "driftwood": 2 }); item_take ops seen []; refusals [] |
| 27 | 0 | water_dock_act — host presses the finished repair: not charged | PASS + {"flag_before":true,"taken":{"driftwood":0.0,"reed_fiber":0.0}} | PASS | prompt activated (FORCED: prompt dark, stale-client resend) standing (not offered); flag true -> true; bag { "reed_fiber": 8, "driftwood": 6 } -> { "reed_fiber": 8, "driftwood": 6 } (disk { "reed_fiber": 8, "driftwood": 6 } -> { "reed_fiber": 8, "driftwood": 6 }); item_take ops seen []; refusals [] |
| 28 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 3 files to /home/user/tb-pockets/ralph/reports/TIDEWAKE/f15_dock_exchange_once/peer-0/after |
| 28 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-dc6171ef36123d52acc7e186af75ac16' on disk=true; copied 1 files to /home/user/tb-pockets/ralph/reports/TIDEWAKE/f15_dock_exchange_once/peer-1/after |
| 29 | 0 | water_dock_state — final | PASS + {"done":{"deep_watch_chart":true,"reedhaven_repair":true}} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "done": { "reedhaven_repair": true, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": true }, "bag": { "reed_fiber": 8, "driftwood": 6 }, "disk": { "reed_fiber": 8, "driftwood": 6 }, "prompt_enabled": <null>, "session_active": true, "realm": "water" } |
| 29 | 1 | water_dock_state — final | PASS + {"done":{"deep_watch_chart":true,"reedhaven_repair":true}} | PASS | { "character_id": "character-dc6171ef36123d52acc7e186af75ac16", "done": { "reedhaven_repair": true, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": true }, "bag": { "reed_fiber": 2, "driftwood": 2 }, "disk": { "reed_fiber": 2, "driftwood": 2 }, "prompt_enabled": <null>, "session_active": true, "realm": "water" } |
| 30 | 1 | water_dock_state — guest: still charged exactly once | PASS + {"bag":{"driftwood":2.0,"reed_fiber":2.0},"disk":{"driftwood":2.0,"reed_fiber":2.0}} | PASS | { "character_id": "character-dc6171ef36123d52acc7e186af75ac16", "done": { "reedhaven_repair": true, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": true }, "bag": { "reed_fiber": 2, "driftwood": 2 }, "disk": { "reed_fiber": 2, "driftwood": 2 }, "prompt_enabled": <null>, "session_active": true, "realm": "water" } |
| 31 | 0 | water_dock_state — host: never charged | PASS + {"bag":{"driftwood":6.0,"reed_fiber":8.0},"disk":{"driftwood":6.0,"reed_fiber":8.0}} | PASS | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "done": { "reedhaven_repair": true, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": true }, "bag": { "reed_fiber": 8, "driftwood": 6 }, "disk": { "reed_fiber": 8, "driftwood": 6 }, "prompt_enabled": <null>, "session_active": true, "realm": "water" } |
| 32 | 0 | check_saved — host's saved world holds both actions | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under after/worlds |
| 33 | 0 | check_saved — baseline world held neither | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under before/worlds |
| 34 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 34 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |

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
- `peer-1/after/characters/character-691c514ec73749640dbb10ba8563bb07/character.json.gz`
- `peer-1/after/characters/character-dc6171ef36123d52acc7e186af75ac16/character.json`
- `peer-1/after_pay/characters/character-691c514ec73749640dbb10ba8563bb07/character.json.gz`
- `peer-1/after_pay/characters/character-dc6171ef36123d52acc7e186af75ac16/character.json`
- `peer-1/before/characters/character-691c514ec73749640dbb10ba8563bb07/character.json.gz`
- `peer-1/before/characters/character-dc6171ef36123d52acc7e186af75ac16/character.json`
- `render/PROOF.md`
- `render/net/net-proof_two_peer-20260926T023858Z/NET_RUN.json`
- `render/net/net-proof_two_peer-20260926T023858Z/SUMMARY.md`
- `render/peer-0/02_host_at_chart_after_press.png`
- `render/peer-0/03_after.png`
- `render/peer-0/after/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json.gz`
- `render/peer-0/after/worlds/slot-0/world.json.gz`
- `render/peer-0/before/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json.gz`
- `render/peer-0/before/worlds/slot-0/world.json.gz`
- `render/peer-1/01_guest_at_dock_after_press.png`
- `render/peer-1/03_after.png`
- `render/peer-1/after/characters/character-52eb198799479f518081065cfe9a4d9f/character.json.gz`
- `render/peer-1/after_pay/characters/character-52eb198799479f518081065cfe9a4d9f/character.json.gz`
- `render/peer-1/before/characters/character-52eb198799479f518081065cfe9a4d9f/character.json.gz`
