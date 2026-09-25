# Two-peer proof: F06: two-peer join, rejoin and mounted rejoin do not bypass Cloudreach's closed counterweight gate

**Verdict: FAIL** (exit 1)

Scenario: `/home/user/wt-summit/tools/net/proof_scenarios/f06_cloudreach_mounted_rejoin.json`  
Run: `net-f06-20260925T195427Z-10286`  
Rendered: no (headless)

ACCEPTANCE F06: 'two-peer rejoin does not bypass a closed gate or lose an owned creature'. The guest's own world has Cloudreach's upper route open and its portable character is saved past upper_counterweight_gate (in Upper Cloudreach). The host's world has that gate CLOSED (no cloudreach_upper_route_unlocked). (1) JOIN: the guest continues its own save through the title's production join; it must not stand inside sealed Upper Cloudreach, must keep its five, and the host's world flags must not change. (2) REJOIN: at the gate's legal side it leaves and rejoins: same checks, same party ids. (3) MOUNTED REJOIN: it launches on its galecrest, its link drops mid-flight, it rejoins, then lands: sane rider state, same five ids, legal side, no flag change. (4) CONTROL: the host opens the gate, the guest stands past it, leaves and rejoins and DOES stand past it, so the 'not past the gate' check can fail. Setup stand-ins (disclosed): world flags through the ledger (story_flag) stand in for playing to Cloudreach, the Windscar flight trial and (guest's own world only) the Sky Shrine windlass; party_grant and fly_setup fill the guest's five; teleport places the guest past the gate in its own open world and at the gate's legal side. Saves, loads, join, leave, drop, rejoin, flight and snapshots are the game's own code. Loopback ENet: local evidence, not internet/Steam acceptance.

## Failures

- #27 peer 1 assert (JOIN: guest is NOT standing in sealed Upper Cloudreach) -> PASS -- 0.00 m from (-400.0, 3890.0), wanted within 40.00
- #40 peer 1 assert (REJOIN: guest is NOT standing in sealed Upper Cloudreach) -> PASS -- 0.00 m from (-400.0, 3890.0), wanted within 40.00
- #41 peer 1 assert (REJOIN: guest stands at the gate's legal side) -> FAIL -- 1483.82 m from (-104.0, 2436.0), wanted within 20.00
- #43 peer 1 fly_launch (MOUNTED: guest launches on its galecrest at the gate's legal side) -> FAIL -- the second airborne Jump did not launch; screen: no SequenceDirector here; nothing holding the screen; launch_blockers() said 'This wind route is still sealed: cloudreach_upper.', now 'Fly is unavailable while riding or in combat.'

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | boot — each peer boots its own fresh Meadows world | PASS | PASS | booted world (240 settle frames) |
| 1 | 1 | boot — each peer boots its own fresh Meadows world | PASS | PASS | booted world (240 settle frames) |
| 2 | 0 | story_flag — setup: both worlds hold the Cloudreach key | PASS | PASS | realm_key_cloudreach: ok=true pending=false code='' reason='' |
| 2 | 1 | story_flag — setup: both worlds hold the Cloudreach key | PASS | PASS | realm_key_cloudreach: ok=true pending=false code='' reason='' |
| 3 | 0 | story_flag — setup: both worlds finished the Windscar flight trial (the Fly gate, not the counterweight gate) | PASS | PASS | fly_traversal_unlocked: ok=true pending=false code='' reason='' |
| 3 | 1 | story_flag — setup: both worlds finished the Windscar flight trial (the Fly gate, not the counterweight gate) | PASS | PASS | fly_traversal_unlocked: ok=true pending=false code='' reason='' |
| 4 | 1 | story_flag — setup: ONLY the guest's own world has the upper counterweight route open | PASS | PASS | cloudreach_upper_route_unlocked: ok=true pending=false code='' reason='' |
| 5 | 1 | party_grant | PASS | PASS | 'bramblebun' at level 20 joined the party (1 member(s)) |
| 6 | 1 | party_grant | PASS | PASS | 'terrapup' at level 20 joined the party (2 member(s)) |
| 7 | 1 | party_grant | PASS | PASS | 'brooktail' at level 20 joined the party (3 member(s)) |
| 8 | 1 | party_grant | PASS | PASS | 'mudsnout' at level 20 joined the party (4 member(s)) |
| 9 | 0 | enter_realm — host enters Cloudreach in its own world | PASS | PASS | crossed 'meadows' -> 'cloudreach' after 265 observed physics frames / 216942 ms (budget 6000 physics frames); current scene is /root/CloudreachCliffs |
| 10 | 1 | enter_realm — guest enters Cloudreach in its own world | PASS | PASS | crossed 'meadows' -> 'cloudreach' after 268 observed physics frames / 217575 ms (budget 6000 physics frames); current scene is /root/CloudreachCliffs |
| 11 | 1 | fly_setup — setup: guest's fifth creature is its Fly carrier (galecrest) | PASS | PASS | SETUP: fly_traversal_unlocked set, galecrest active, anchor=(0.0, 105.0302, -260.0), screen: no SequenceDirector here; nothing holding the screen, launch site: already clear where it stood (locomotion=true carried=false on_floor=true) |
| 12 | 1 | assert — guest owns five | PASS | PASS | party size 5 (wanted 5) |
| 13 | 1 | teleport — setup: guest stands in Upper Cloudreach, past the gate (open in its own world) | PASS | PASS | trainer stands at (-400.00, 780.03, 3890.00) |
| 14 | 1 | probe position — guest pose in its own world | PASS | PASS | [-400.0,780.030639648438,3890.0] |
| 15 | 1 | assert — baseline: guest IS past the gate in its own world | PASS | PASS | 0.00 m from (-400.0, 3890.0), wanted within 40.00 |
| 16 | 1 | save_character_here — guest saves its own world + portable character past the gate | PASS | PASS | character 'character-eb5b7cf6ff9e49160b0f319f7fa82485' is on disk (wrote_world=true) |
| 17 | 1 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-eb5b7cf6ff9e49160b0f319f7fa82485' on disk=true; copied 3 files to /tmp/claude-0/-home-user/a928e74c-55ea-5de6-a21f-37d302e2ef4c/scratchpad/f06/run7/peer-1/guest_home_past_gate |
| 18 | 1 | check_saved — guest's own saved world has the gate open | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under guest_home_past_gate/worlds |
| 19 | 1 | check_saved — guest's saved character: Cloudreach pose, carrier owned | PASS | PASS | missing []; unexpectedly present []; read ["character-eb5b7cf6ff9e49160b0f319f7fa82485/character.json"] under guest_home_past_gate/characters |
| 20 | 0 | host | PASS | PASS | hosting udp/33961 as peer 1 |
| 21 | 0 | assert — host world: gate CLOSED before the join | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 22 | 1 | production_join — guest continues its own save through the title (world built from its autosave, then JoinDriver dials) | PASS | PASS | title fresh entry built 'CloudreachCliffs' first, then JoinDriver joined 127.0.0.1:33961 as peer 591152581 after 51 frames |
| 23 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 23 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 24 | 1 | probe player_identity — JOIN: guest in Cloudreach, five owned | PASS + {"party_size":5.0,"realm":"cloudreach"} | PASS | {"appearance_id":"trainer","body":{"exists":true,"in_current_scene":true,"model_appearance_id":"trainer","model_exists":true,"model_has_art":true,"model_requested_appearance_id":"","position":[-400.0,780.030639648438,3890.0]},"character_id":"character-eb5b7cf6ff9e49160b0f319f7fa82485","display_name":"","inside_grandpas_village":false,"party":["bramblebun@20","terrapup@20","brooktail@20","mudsnout@20","galecrest@1"],"party_size":5.0,"realm":"cloudreach"} |
| 25 | 1 | probe position — JOIN: guest position | PASS | PASS | [-400.0,780.030639648438,3890.0] |
| 26 | 1 | assert — JOIN: guest now reads the host's closed gate | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 27 | 1 | assert — JOIN: guest is NOT standing in sealed Upper Cloudreach | FAIL | PASS **(unexpected)** | 0.00 m from (-400.0, 3890.0), wanted within 40.00 |
| 28 | 0 | assert — JOIN: host world flags unchanged | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 29 | 1 | teleport — setup: guest stands at the gate's legal (south) side | PASS | PASS | trainer stands at (-400.00, 780.03, 3890.00) |
| 30 | 1 | probe position | PASS | PASS | [-400.0,780.0302734375,3890.0] |
| 31 | 1 | save_character_here — guest saves its portable character at the gate | PASS | PASS | character 'character-eb5b7cf6ff9e49160b0f319f7fa82485' is on disk (wrote_world=false) |
| 32 | 1 | probe tournament — party ids before leave | PASS | PASS | {"battle_active":false,"flags":{"recipe_saddle":false,"tournament_quarter_won":false,"tournament_semi_won":false,"tournament_won":false},"party_ids":["creature-95cad11f421610561f0d6f358f8542aa","creature-15a5d4099aa1d0a2be17bdca7006521d","creature-9750538067810ecd304a4bdac666c4a8","creature-c3b51c7df1780d5fe77be34fa4c46a77","creature-9be5dab1cc626d997c0d014da13941ff"],"ready":false,"selection_ids":[]} |
| 33 | 1 | leave | PASS | PASS | client left cleanly after 0 frames |
| 34 | 0 | expect_peers | PASS | PASS | registry reports 1 peer(s) after 4 frames |
| 35 | 1 | join — guest rejoins | PASS | PASS | joined 127.0.0.1:33961 as peer 264906796 after 5 frames; snapshot applied; 2 peer(s) in registry |
| 36 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 36 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 37 | 1 | probe player_identity — REJOIN: guest in Cloudreach, five owned | PASS + {"party_size":5.0,"realm":"cloudreach"} | PASS | {"appearance_id":"trainer","body":{"exists":true,"in_current_scene":true,"model_appearance_id":"trainer","model_exists":true,"model_has_art":true,"model_requested_appearance_id":"","position":[-400.0,780.0302734375,3890.0]},"character_id":"character-eb5b7cf6ff9e49160b0f319f7fa82485","display_name":"","inside_grandpas_village":false,"party":["bramblebun@20","terrapup@20","brooktail@20","mudsnout@20","galecrest@1"],"party_size":5.0,"realm":"cloudreach"} |
| 38 | 1 | probe tournament — REJOIN: party ids after (compare with the row before leave) | PASS | PASS | {"battle_active":false,"flags":{"recipe_saddle":false,"tournament_quarter_won":false,"tournament_semi_won":false,"tournament_won":false},"party_ids":["creature-95cad11f421610561f0d6f358f8542aa","creature-15a5d4099aa1d0a2be17bdca7006521d","creature-9750538067810ecd304a4bdac666c4a8","creature-c3b51c7df1780d5fe77be34fa4c46a77","creature-9be5dab1cc626d997c0d014da13941ff"],"ready":false,"selection_ids":[]} |
| 39 | 1 | probe position — REJOIN: guest position | PASS | PASS | [-400.0,780.0302734375,3890.0] |
| 40 | 1 | assert — REJOIN: guest is NOT standing in sealed Upper Cloudreach | FAIL | PASS **(unexpected)** | 0.00 m from (-400.0, 3890.0), wanted within 40.00 |
| 41 | 1 | assert — REJOIN: guest stands at the gate's legal side | PASS | FAIL **(unexpected)** | 1483.82 m from (-104.0, 2436.0), wanted within 20.00 |
| 42 | 0 | assert — REJOIN: host world flags unchanged | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 43 | 1 | fly_launch — MOUNTED: guest launches on its galecrest at the gate's legal side | PASS | FAIL **(unexpected)** | the second airborne Jump did not launch; screen: no SequenceDirector here; nothing holding the screen; launch_blockers() said 'This wind route is still sealed: cloudreach_upper.', now 'Fly is unavailable while riding or in combat.' |

## Captured files

- `peer-1/guest_home_past_gate/characters/character-eb5b7cf6ff9e49160b0f319f7fa82485/character.json`
- `peer-1/guest_home_past_gate/saves/slot_0.json`
- `peer-1/guest_home_past_gate/worlds/slot-0/world.json`
