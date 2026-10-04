# Two-peer proof: F09 gates: an Arch pair relit by the two peers, a dark pair and the Rootgate stay closed, all kept through a save/reload

**Verdict: PASS** (exit 0)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/stormwood_f09_arch_gates_two_peer_reload.json`  
Run: `net-20261004T221802Z-10607`  
Rendered: no (headless)

ACCEPTANCE F09 'A closed Arch cannot be bypassed; two peers and reload retain the same world gates'. Pair A (Ashfoot <-> Lantern Pools South) is relit by the two peers through each arch's own 'Relight' prompt (stormwood_arch_runtime.gd _relight -> world_ledger stormwood_relight_arch: one world lit flag + 3 Stormglass taken from THAT peer): the host lights Ashfoot, the guest lights Lantern Pools South. Stepping into the lit Ashfoot arch carries the host to its twin (Session arch travel). Pair B stays dark: stepping into Lantern Pools North does nothing. Pair C sits behind the closed Rootgate (requires_flag stormwood:rootgate_released): its arches are not available, so stepping into Rodline Long Road Arch carries nobody. Both peers then save_reload_here and the same lit/dark/gated state holds on both and in the host's saved world. Setup, disclosed: Stormglass granted into each satchel (storage_grant: 9 host, 3 guest) and `explore_at` to stand at each arch (ground height + 1 m) instead of walking the roads; the relights, refusals and arch travel are the game's own code.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: a fresh trainer in the Meadows | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | host | PASS | PASS | hosting udp/33241 as peer 1 |
| 4 | 1 | join | PASS | PASS | joined 127.0.0.1:33241 as peer 950249534 after 24 frames; snapshot applied; 2 peer(s) in registry |
| 5 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 5 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 6 | 0 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 6 | 1 | wait_flag — the route comes from the host's save | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 7 | 0 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 495 observed physics frames / 67153 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 8 | 1 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 1101 observed physics frames / 54673 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 9 | 0 | probe downed — trainer vitals on arrival | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":100.0,"hold_peer":0.0,"hold_s":0.0,"host_authority_attempts":[],"host_views":{"1":{"body_id":59513231347048.0,"position":[-300.0,32.271728515625,180.0],"realm":"stormwood","valid":true},"950249534":{"body_id":65295616165772.0,"position":[-300.0,32.271728515625,180.0],"realm":"stormwood","valid":true}},"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":59513231347048.0,"prompt":"[img=36x36]res://assets/ui/input_prompts/keyboard_e.png[/img]   Take Good Candy","viewer_id":59513231347048.0,"viewer_position":[-300.0,32.271728515625,180.0]},"interaction_winner":{"class":"Node3D","name":"Interactable"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_radius_m":2.5,"revive |
| 9 | 1 | probe downed — trainer vitals on arrival | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":100.0,"hold_peer":0.0,"hold_s":0.0,"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":55335285132671.0,"prompt":"[img=36x36]res://assets/ui/input_prompts/keyboard_e.png[/img]   Take Good Candy","viewer_id":55335285132671.0,"viewer_position":[-300.0,32.271728515625,180.0]},"interaction_winner":{"class":"Node3D","name":"Interactable"},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_radius_m":2.5,"revived":0.0,"satchel_nodes":0.0,"satchels":0.0,"stamina":100.0,"window_s":45.0} |
| 10 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 5 files to /tmp/claude-0/-home-user-Tetherbound/6050aa73-5362-5e48-a427-17c5687ec66b/scratchpad/proofs/F09-4-arch_gates-v28/peer-0/before |
| 10 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-8b5702278daad34d033df13d91c3c889' on disk=true; copied 2 files to /tmp/claude-0/-home-user-Tetherbound/6050aa73-5362-5e48-a427-17c5687ec66b/scratchpad/proofs/F09-4-arch_gates-v28/peer-1/before |
| 11 | 0 | storage_grant — SETUP: 9 Stormglass in the host's satchel | PASS | PASS | granted 9 stormglass (0 did not fit; waited 0 guard frame(s)) |
| 12 | 1 | storage_grant — SETUP: 3 Stormglass in the guest's satchel | PASS | PASS | granted 3 stormglass (0 did not fit; waited 0 guard frame(s)) |
| 13 | 0 | explore_at — SETUP: the host stands before Ashfoot Arch (A) | PASS | PASS | stood at (-350, 497), settled at (-350.0, 497.0), y=29.1 |
| 14 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 15 | 0 | press — the host presses 'Relight Ashfoot Arch' | PASS | PASS | pressed 'interact' x1 |
| 16 | 0 | wait_flag — Ashfoot lit, for both peers | PASS | PASS | flag stormwood:arch:a_ashfoot:lit (any) set after 0 frames |
| 16 | 1 | wait_flag — Ashfoot lit, for both peers | PASS | PASS | flag stormwood:arch:a_ashfoot:lit (any) set after 894 frames |
| 17 | 1 | explore_at — SETUP: the guest stands before Lantern Pools South Arch (A) | PASS | PASS | stood at (-350, 1443), settled at (-350.0, 1443.0), y=31.7 |
| 18 | 1 | press — the guest presses 'Relight Lantern Pools South Arch' (client path, its own Stormglass) | PASS | PASS | pressed 'interact' x1 |
| 19 | 0 | wait_flag — Lantern Pools South lit, for both peers: pair A is open | PASS | PASS | flag stormwood:arch:a_pools:lit (any) set after 0 frames |
| 19 | 1 | wait_flag — Lantern Pools South lit, for both peers: pair A is open | PASS | PASS | flag stormwood:arch:a_pools:lit (any) set after 0 frames |
| 20 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 21 | 0 | explore_at — the host steps into the lit Ashfoot arch | PASS | PASS | stood at (-350, 500), settled at (-350.0, 1436.5), y=31.7 |
| 22 | 0 | probe position — OPEN PAIR: the host now stands at the Lantern Pools South twin (z ~ 1436), not at Ashfoot (z 500) | PASS | PASS | [-350.0,31.6851997375488,1436.5] |
| 23 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 24 | 1 | explore_at — the guest steps into dark Lantern Pools North (B) | PASS | PASS | stood at (-410, 1350), settled at (-410.0, 1350.0), y=29.6 |
| 25 | 1 | probe position — CLOSED PAIR: the guest is still at Lantern Pools North (z ~ 1350) | PASS | PASS | [-410.0,29.5512409210205,1350.0] |
| 26 | 0 | explore_at — the host steps into Rodline Long Road Arch (C), which stays unavailable (hidden, prompt disabled) behind the closed Rootgate | PASS | PASS | stood at (-720, 2260), settled at (-720.0, 2260.0), y=43.1 |
| 27 | 0 | probe position — GATED PAIR: the host is still at Rodline (z ~ 2260), not carried to Lantern Hollow (z ~ 4010) | PASS | PASS | [-720.0,43.0534400939941,2260.0] |
| 28 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 29 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 5 files to /tmp/claude-0/-home-user-Tetherbound/6050aa73-5362-5e48-a427-17c5687ec66b/scratchpad/proofs/F09-4-arch_gates-v28/peer-0/lit |
| 29 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-8b5702278daad34d033df13d91c3c889' on disk=true; copied 2 files to /tmp/claude-0/-home-user-Tetherbound/6050aa73-5362-5e48-a427-17c5687ec66b/scratchpad/proofs/F09-4-arch_gates-v28/peer-1/lit |
| 30 | 0 | save_reload_here — RELOAD: host autosave + load_slot in place | PASS | PASS | host slot reload preserved party=true selection=true hosted_world=true |
| 31 | 1 | save_reload_here — RELOAD: guest character save + apply from disk | PASS | PASS | client character reload preserved party=true selection=true hosted_world=true |
| 32 | 0 | wait_flag — after the reload Ashfoot is still lit on both | PASS | PASS | flag stormwood:arch:a_ashfoot:lit (any) set after 0 frames |
| 32 | 1 | wait_flag — after the reload Ashfoot is still lit on both | PASS | PASS | flag stormwood:arch:a_ashfoot:lit (any) set after 0 frames |
| 33 | 0 | wait_flag — after the reload Lantern Pools South is still lit on both | PASS | PASS | flag stormwood:arch:a_pools:lit (any) set after 0 frames |
| 33 | 1 | wait_flag — after the reload Lantern Pools South is still lit on both | PASS | PASS | flag stormwood:arch:a_pools:lit (any) set after 0 frames |
| 34 | 1 | explore_at — after the reload the guest steps into the lit Lantern Pools South arch | PASS | PASS | stood at (-350, 1440), settled at (-350.0, 1440.0), y=31.7 |
| 35 | 1 | probe position — OPEN PAIR after reload: the guest now stands at the Ashfoot twin (z ~ 504) | PASS | PASS | [-350.0,31.6851997375488,1440.0] |
| 36 | 0 | probe downed — trainer vitals at the end | PASS | PASS | {"available":true,"carried":{"stormglass":6.0},"downed_peers":[],"expired":0.0,"health":100.0,"hold_peer":0.0,"hold_s":0.0,"host_authority_attempts":[],"host_views":{"1":{"body_id":59513231347048.0,"position":[-720.0,43.0534400939941,2260.0],"realm":"stormwood","valid":true},"950249534":{"body_id":65295616165772.0,"position":[-350.0,31.6845302581787,1440.0],"realm":"stormwood","valid":true}},"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":59513231347048.0,"prompt":"","viewer_id":59513231347048.0,"viewer_position":[-720.0,43.0534400939941,2260.0]},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_radius_m":2.5,"revived":0.0,"satchel_nodes":0.0,"satchels":0.0,"stamina":100.0,"window_s":45.0} |
| 36 | 1 | probe downed — trainer vitals at the end | PASS | PASS | {"available":true,"carried":{},"downed_peers":[],"expired":0.0,"health":100.0,"hold_peer":0.0,"hold_s":0.0,"interaction_arbiter":{"enabled":true,"input_context":"world","local_player_id":55335285132671.0,"prompt":"","viewer_id":55335285132671.0,"viewer_position":[-350.0,31.6851997375488,1440.0]},"local_downed":false,"locomotion":true,"progress_peer":0.0,"progress_s":0.0,"remaining_s":0.0,"revive_hold_s":3.0,"revive_move_deadzone_m":0.3,"revive_progress_s":3.0,"revive_radius_m":2.5,"revived":0.0,"satchel_nodes":0.0,"satchels":0.0,"stamina":100.0,"window_s":45.0} |
| 37 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 37 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 38 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-f41f4a49223483d6bfdf56715944bb7b' on disk=true; copied 5 files to /tmp/claude-0/-home-user-Tetherbound/6050aa73-5362-5e48-a427-17c5687ec66b/scratchpad/proofs/F09-4-arch_gates-v28/peer-0/after |
| 38 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-8b5702278daad34d033df13d91c3c889' on disk=true; copied 2 files to /tmp/claude-0/-home-user-Tetherbound/6050aa73-5362-5e48-a427-17c5687ec66b/scratchpad/proofs/F09-4-arch_gates-v28/peer-1/after |
| 39 | 0 | check_saved — baseline: no arch lit in the host's pre-run world | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/slot-0/world.json"] under before/worlds |
| 40 | 0 | check_saved — after the reload the host's saved world: pair A lit, pair B dark, pair C unlit, Rootgate closed | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/slot-0/world.json"] under after/worlds |

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
- `peer-0/lit/characters/redesign-v28/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/lit/saves/redesign-v28/characters/character-f41f4a49223483d6bfdf56715944bb7b/character.json`
- `peer-0/lit/saves/redesign-v28/slot_0.json`
- `peer-0/lit/saves/redesign-v28/worlds/slot-0/world.json`
- `peer-0/lit/worlds/redesign-v28/slot-0/world.json`
- `peer-1/after/characters/redesign-v28/character-8b5702278daad34d033df13d91c3c889/character.json`
- `peer-1/after/saves/redesign-v28/characters/character-8b5702278daad34d033df13d91c3c889/character.json`
- `peer-1/before/characters/redesign-v28/character-8b5702278daad34d033df13d91c3c889/character.json`
- `peer-1/before/saves/redesign-v28/characters/character-8b5702278daad34d033df13d91c3c889/character.json`
- `peer-1/lit/characters/redesign-v28/character-8b5702278daad34d033df13d91c3c889/character.json`
- `peer-1/lit/saves/redesign-v28/characters/character-8b5702278daad34d033df13d91c3c889/character.json`
