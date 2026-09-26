# Two-peer proof: REPRO: host realm crossing after a guest drop/rejoin

**Verdict: FAIL** (exit 1)

Scenario: `<scratch>/repro_epoch.json`  
Run: `net-20260926T151544Z-1566`  
Rendered: no (headless)

Focused repro for the F11#3 finding: after a guest's link drops and it rejoins, does the host's own realm crossing complete?

## Failures

- #13 peer 0 enter_realm (the HOST crosses to Stormwood with the rejoined guest connected) -> FAIL -- Game.enter_realm('stormwood') exceeded its 6000-physics-frame budget (7192 frames / 120018 ms)

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 1 | boot | PASS | PASS | booted world (240 settle frames) |
| 2 | 0 | load_save | PASS | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 3 | 0 | host | PASS | PASS | hosting udp/32701 as peer 1 |
| 4 | 1 | join | PASS | PASS | joined 127.0.0.1:32701 as peer 454640949 after 10 frames; snapshot applied; 2 peer(s) in registry |
| 5 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 5 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 6 | 0 | aftermath_state — epochs before any drop | PASS | PASS | {"active_relic":"","character_id":"character-f41f4a49223483d6bfdf56715944bb7b","dialogue":"","dialogue_open":false,"long_storm_ended":false,"own_answers":[],"realm":"meadows","realm_gate_water_unlocked":false,"realm_heart_stormwood_earned":false,"realm_heart_stormwood_placed":false,"realm_key_water":false,"spark_earned":false,"spark_placed":false,"spark_socket":"unearned","stormhearts_in_party":0,"stormwood:legendary_freed":false,"stormwood:legendary_offer_made":false,"stormwood:long_storm_ended":false,"stormwood:waterward_revealed":false,"strike_serial":0,"surge":"(not in Stormwood)","transition_epoch":1,"world_resolutions":[]} |
| 6 | 1 | aftermath_state — epochs before any drop | PASS | PASS | {"active_relic":"","character_id":"character-4a988e3fe960089b213e840490821d6e","dialogue":"","dialogue_open":false,"long_storm_ended":false,"own_answers":[],"realm":"meadows","realm_gate_water_unlocked":false,"realm_heart_stormwood_earned":false,"realm_heart_stormwood_placed":false,"realm_key_water":false,"spark_earned":false,"spark_placed":false,"spark_socket":"unearned","stormhearts_in_party":0,"stormwood:legendary_freed":false,"stormwood:legendary_offer_made":false,"stormwood:long_storm_ended":false,"stormwood:waterward_revealed":false,"strike_serial":0,"surge":"(not in Stormwood)","transition_epoch":1,"world_resolutions":[]} |
| 7 | 1 | stormheart_state — learn the guest's character id | any + {"character_id":"character-4a988e3fe960089b213e840490821d6e"} | PASS | { "character_id": "character-4a988e3fe960089b213e840490821d6e", "party": [], "has_stormheart": false, "freed": false, "world_accepted": false, "world_refused": false, "accepted_anywhere": false } |
| 8 | 1 | drop_link | PASS | PASS | transport closed without a Session.leave() |
| 9 | 0 | expect_peers | PASS | PASS | registry reports 1 peer(s) after 0 frames |
| 10 | 1 | production_join | PASS | PASS | title returning entry built 'MeadowsPlayground' first, then JoinDriver joined 127.0.0.1:32701 as peer 96628266 after 86 frames |
| 11 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 11 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 12 | 0 | aftermath_state — epochs after the guest's drop + rejoin | PASS | PASS | {"active_relic":"","character_id":"character-f41f4a49223483d6bfdf56715944bb7b","dialogue":"","dialogue_open":false,"long_storm_ended":false,"own_answers":[],"realm":"meadows","realm_gate_water_unlocked":false,"realm_heart_stormwood_earned":false,"realm_heart_stormwood_placed":false,"realm_key_water":false,"spark_earned":false,"spark_placed":false,"spark_socket":"unearned","stormhearts_in_party":0,"stormwood:legendary_freed":false,"stormwood:legendary_offer_made":false,"stormwood:long_storm_ended":false,"stormwood:waterward_revealed":false,"strike_serial":0,"surge":"(not in Stormwood)","transition_epoch":1,"world_resolutions":[]} |
| 12 | 1 | aftermath_state — epochs after the guest's drop + rejoin | PASS | PASS | {"active_relic":"","character_id":"character-4a988e3fe960089b213e840490821d6e","dialogue":"","dialogue_open":false,"long_storm_ended":false,"own_answers":[],"realm":"meadows","realm_gate_water_unlocked":false,"realm_heart_stormwood_earned":false,"realm_heart_stormwood_placed":false,"realm_key_water":false,"spark_earned":false,"spark_placed":false,"spark_socket":"unearned","stormhearts_in_party":0,"stormwood:legendary_freed":false,"stormwood:legendary_offer_made":false,"stormwood:long_storm_ended":false,"stormwood:waterward_revealed":false,"strike_serial":0,"surge":"(not in Stormwood)","transition_epoch":2,"world_resolutions":[]} |
| 13 | 0 | enter_realm — the HOST crosses to Stormwood with the rejoined guest connected | PASS | FAIL **(unexpected)** | Game.enter_realm('stormwood') exceeded its 6000-physics-frame budget (7192 frames / 120018 ms) |

## Captured files

