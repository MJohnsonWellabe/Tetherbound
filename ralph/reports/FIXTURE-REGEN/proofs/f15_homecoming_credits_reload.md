# Two-peer proof: F15: credits occur once for host and guest, and a disk reload resumes the completed world

**Verdict: FAIL** (exit 1)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/f15_homecoming_credits_reload.json`  
Run: `net-20261004T210828Z-7047`  
Rendered: no (headless)

ACCEPTANCE F15 (T3): 'Credits occur once' and 'reload resumes a safe completed world with local requests, without a fifth key or invented sequel prompt', for HOST and GUEST with a disk reload. Setup stands in for PLAYING Tidewake to the end only: the host's named Meadows save plus the end-of-Tidewake world facts (Nerissa beaten, currents restored, the Water key and gate) committed through the ledger, plus Old Bram met so one Local Request is visible, as tests/smoke_regional_credits_reload.gd's fixture does. The realm keys held before the ending are exactly realm_key_stormwood + realm_key_water, and every later state must hold exactly those (no fifth key). Each peer then walks up to its own Grandpa, presses his real prompt, reads the homecoming the director chose for its own character through with interact, watches the production credits roll and presses Continue (then a second press). Saves are captured, each peer's character is emptied in memory and read back from disk (host: its slot; guest: its character file), and each peer talks to Grandpa again.

## Failures

- #12 peer 0 ending_state (before: no receipts (non-vacuous baseline)) -> PASS; data did not match {"credits_pending":false,"credits_seen":false,"currents_restored":true,"homecoming_seen":false,"local_requests_offered":true,"realm_keys":["realm_key_stormwood","realm_key_water"],"tracked_id":"regional_return_home"} -- { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "host_owned": true, "currents_restored": false, "homecoming_seen": false, "credits_seen": false, "credits_pending": false, "credits_open": false, "grandpa_next": "", "realm_keys": ["realm_key_stormwood", "realm_key_water"], "realm_key_c

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: the host's Meadows world | PASS + {"realm":"meadows"} | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: its own trainer in the Meadows | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | host | PASS | PASS | hosting udp/34401 as peer 1 |
| 4 | 1 | join | PASS | PASS | joined 127.0.0.1:34401 as peer 108925278 after 25 frames; snapshot applied; 2 peer(s) in registry |
| 5 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 5 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 6 | 0 | story_flag — SETUP: end of Tidewake (stands in for playing it) | PASS | PASS | water_captain_nerissa_defeated: ok=true pending=false code='' reason='' |
| 7 | 0 | story_flag — SETUP | PASS | PASS | realm_gate_water_unlocked: ok=true pending=false code='' reason='' |
| 8 | 0 | story_flag — SETUP: the Water key Stormwood granted | PASS | PASS | realm_key_water: ok=true pending=false code='' reason='' |
| 9 | 0 | story_flag — SETUP: currents restored | PASS | PASS | water_currents_restored: ok=true pending=false code='' reason='' |
| 10 | 0 | story_flag — SETUP: one Local Request revealed (Old Bram), as the single-player proof's fixture does | PASS | PASS | old_champion_met: ok=true pending=false code='' reason='' |
| 11 | 0 | wait_flag | PASS | PASS | flag water_currents_restored (world) set after 0 frames |
| 11 | 1 | wait_flag | PASS | PASS | flag water_currents_restored (world) set after 0 frames |
| 12 | 0 | ending_state — before: no receipts (non-vacuous baseline) | PASS + {"credits_pending":false,"credits_seen":false,"currents_restored":true,"homecoming_seen":false,"local_requests_offered":true,"realm_keys":["realm_key_stormwood","realm_key_water"],"tracked_id":"regional_return_home"} | PASS **(unexpected)** | { "character_id": "character-f41f4a49223483d6bfdf56715944bb7b", "host_owned": true, "currents_restored": false, "homecoming_seen": false, "credits_seen": false, "credits_pending": false, "credits_open": false, "grandpa_next": "", "realm_keys": ["realm_key_stormwood", "realm_key_water"], "realm_key_count": 2, "local_requests": 1, "local_requests_offered": true, "tracked_id": "opening_hear_grandpa", "sequel_or_chapter_prompt": false } |

## Captured files

