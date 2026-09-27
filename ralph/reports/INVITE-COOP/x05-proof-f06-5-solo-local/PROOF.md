# Two-peer proof: F06#5 solo half: saved mid-flight by the game's own autosave, reloaded through the title, from the earned flight-trained checkpoint

**Verdict: PASS** (exit 0)

Scenario: `/tmp/claude-0/-home-user-Tetherbound/514e25e3-5581-5cbe-8b81-fab518e9a091/scratchpad/wt7/tools/net/proof_scenarios/f06_5_solo_flight_autosave_earned.json`  
Run: `net-20260927T071538Z-2662`  
Rendered: no (headless)

F06#5 'Save/reload keeps same five and closed gates' (gap: save while mounted; reload mid-flight), solo half. Start (declared, disclosed): the earned checkpoint tests/fixtures/earned_saves/checkpoints/c1_flight_trained (tb/cloudreach-b b084432d; Fly earned in Maela's trial, the earned five, upper counterweight gate closed), loaded through Game.load_game. The trainer walks off the Aerie deck by stick and taps jump in the air (the ordinary launch; Maela's loaner carries it, none of the five flies). The game's OWN periodic autosave is taken while flying; the process ends; a fresh one loads that save through the title's Load. Then: same five UIDs in order, on a floor and not flying or carried, the upper gate still closed, not inside sealed Upper Cloudreach. Disclosed shortcuts: declared start save; the step reads the autosave timer to time the launch (read only). No flag, party, item or position write.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — the EARNED flight-trained checkpoint, loaded through Game.load_game | PASS | PASS | loaded save (earned save fixture root (split path)) as slot 1; realm 'cloudreach' booted as 'cloudreach'; character 'character-afb79936a9ddebd411e54dfa2817d5b0' |
| 2 | 0 | assert — Fly was earned (Maela's trial) in this save | PASS | PASS | flag fly_traversal_unlocked set |
| 3 | 0 | assert — the upper counterweight gate is CLOSED | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 4 | 0 | party_uids — the earned five, as the loaded checkpoint holds them (same UIDs as c1_arrival's PROVENANCE party; literal so the check survives the restart) | PASS | PASS | 5 owned: ["creature-f4118d54a2317867246afbf1e8ea834f", "creature-390db8e0de00cd1fcaaf1747203b0768", "creature-c785f517af159966b72ca0f49f61d386", "creature-8e12dace31044e591f02b96391ca2372", "creature-9d1cb676a71c2f31e5555ec9eec9905f"]; exactly the 'literal' list |
| 5 | 0 | probe position — on the Aerie deck | PASS | PASS | [399.736694335938,610.130126953125,3249.18383789062] |
| 6 | 0 | ledge_probe — read-only: where the deck drops away | PASS | PASS | [{"drop_m":600.0,"edge_m":22.0,"heading_deg":0,"to":[399.7,3277.2]},{"drop_m":600.0,"edge_m":22.0,"heading_deg":22,"to":[410.5,3275.1]},{"drop_m":50.0,"edge_m":22.0,"heading_deg":45,"to":[419.5,3269.0]},{"drop_m":600.0,"edge_m":22.0,"heading_deg":67,"to":[425.6,3259.9]},{"drop_m":600.0,"edge_m":21.0,"heading_deg":90,"to":[426.7,3249.2]},{"drop_m":600.0,"edge_m":21.0,"heading_deg":112,"to":[424.7,3238.9]},{"drop_m":600.0,"edge_m":21.0,"heading_deg":135,"to":[418.8,3230.1]},{"drop_m":600.0,"edge_m":20.0,"heading_deg":157,"to":[409.7,3225.2]},{"drop_m":31.0,"edge_m":20.0,"heading_deg":180,"to":[399.7,3223.2]},{"drop_m":600.0,"edge_m":20.0,"heading_deg":202,"to":[389.8,3225.2]},{"drop_m":600.0,"edge_m":20.0,"heading_deg":225,"to":[381.4,3230.8]},{"drop_m":600.0,"edge_m":21.0,"heading_deg":247,"to":[374.8,3238.9]},{"drop_m":600.0,"edge_m":27.0,"heading_deg":270,"to":[366.7,3249.2]},{"drop_m": |
| 7 | 0 | ledge_launch — LAUNCH by input: waits for the game's autosave timer to near its next save, walks off the deck by stick, TAPS jump in the air | PASS | PASS | {"autosave_elapsed_s":169.562934444485,"edge":{"drop_m":600.0,"edge_m":20.0,"heading_deg":157,"to":[409.7,3225.2]},"flying":true,"loaner":true,"position":[408.041290283203,608.824157714844,3229.19067382812],"toward":[409.7,3225.2],"walk_frames":249} |
| 8 | 0 | await_autosave — SAVE WHILE FLYING: the game's own periodic autosave is taken mid-flight | PASS | PASS | autosave taken: {"flying":true,"frame":626,"loaner":true,"position":[408.045135498047,587.929260253906,3229.18139648438]} |
| 9 | 0 | probe flying — still flying after the save | PASS | PASS | {"local":{"anchor":{"accepts":0.0,"anchor":[407.501312255859,610.030334472656,3230.48974609375],"host_granted":false,"host_validated":false,"last_code":"","last_denial":"","pending":false,"proposals":0.0,"realm":"cloudreach","refusals":0.0},"blockers":"","carried":false,"carrier":true,"flying":true,"lockout":{"downed":false,"fighting":false,"pending_build":"","trainer_battle":false},"locomotion":true,"on_floor":false,"species":"galecrest","state":"glide","y":581.897399902344},"remote":{}} |
| 10 | 0 | probe position — mid-flight position | PASS | PASS | [408.045135498047,581.864074707031,3229.18139648438] |
| 11 | 0 | restart_peer — RELOAD: the process ends mid-flight; a fresh one starts at the title on the same disk | PASS | PASS | peer 0 process 2684 ended (graceful quit=true); fresh process 3028 on the same home booted 'title' and said hello |
| 12 | 0 | title_load — RELOAD: the title's own Load of the save made mid-flight | PASS | PASS | title Load slot 1 -> /root/CloudreachCliffs (realm 'cloudreach'), hosting on port 33721 after 8 frames |
| 13 | 0 | wait | PASS | PASS | waited 120 physics frames |
| 14 | 0 | probe flying — RELOAD: flight state | PASS | PASS | {"local":{"anchor":{"accepts":0.0,"anchor":[0.0,105.030204772949,-260.0],"host_granted":false,"host_validated":false,"last_code":"","last_denial":"","pending":false,"proposals":0.0,"realm":"cloudreach","refusals":0.0},"blockers":"","carried":false,"carrier":false,"flying":false,"lockout":{"downed":false,"fighting":false,"pending_build":"","trainer_battle":false},"locomotion":true,"on_floor":true,"species":"","state":"grounded","y":105.030204772949},"remote":{}} |
| 15 | 0 | assert — RELOAD: standing on a floor (not in the air, not in the void) | PASS | PASS | on_floor=true flying=false carried=false at (0.0, 105.0302, -260.0) |
| 16 | 0 | party_uids — RELOAD: exactly the same five UIDs, same order | PASS | PASS | 5 owned: ["creature-f4118d54a2317867246afbf1e8ea834f", "creature-390db8e0de00cd1fcaaf1747203b0768", "creature-c785f517af159966b72ca0f49f61d386", "creature-8e12dace31044e591f02b96391ca2372", "creature-9d1cb676a71c2f31e5555ec9eec9905f"]; exactly the 'literal' list |
| 17 | 0 | assert — RELOAD: the upper gate is still closed | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 18 | 0 | assert — RELOAD: not inside sealed Upper Cloudreach | FAIL | FAIL | 4169.23 m from (-400.0, 3890.0), wanted within 40.00 |
| 19 | 0 | probe position — RELOAD: position | PASS | PASS | [0.0,105.030204772949,-260.0] |

## Captured files

