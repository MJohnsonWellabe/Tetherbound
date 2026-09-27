# Two-peer proof: X05 guest lane presentation: a guest in the host's Hollows Alpha fight sees the travelling lane

**Verdict: FAIL** (exit 1)

Scenario: `/home/runner/work/Tetherbound/Tetherbound/tools/net/proof_scenarios/x05_guest_lane_presentation.json`  
Run: `net-20260927T022541Z-2289`  
Rendered: yes

Presentation evidence for the guest-side lane/cue change (#356 01:40 ruling; not a criterion close). The host engages the Hollows Alpha (a Stormwood named CHARGER, lunge_travels) through the production engage press; the guest joins through the production joinable list. Each peer then waits until ITS OWN view draws the lane: the host's real wild body, and the guest's SharedOpponentProxy drawing it from the host's optional cue shape. Setup, disclosed: the host save has the Stormwood route open and both peers use explore_at to stand at the Hollows Alpha instead of walking there.

## Failures

- #11 peer 0 engage_wild (the host engages the Hollows Alpha (production engage press)) -> FAIL -- could not stand where body 53985188796905 was the one on offer (offered nothing)

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save | PASS | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: a fresh trainer in the Meadows | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | host | PASS | PASS | hosting udp/29781 as peer 1 |
| 4 | 1 | join | PASS | PASS | joined 127.0.0.1:29781 as peer 717768563 after 10 frames; snapshot applied; 2 peer(s) in registry |
| 5 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 5 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 6 | 0 | wait_flag | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 6 | 1 | wait_flag | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 7 | 0 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 415 observed physics frames / 22161 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 8 | 1 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 425 observed physics frames / 20011 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 9 | 0 | explore_at — SETUP: the host stands at the Hollows Alpha | PASS | PASS | stood at (-526, 1660), settled at (-526.0, 1660.0), y=29.4 |
| 10 | 1 | explore_at — SETUP: the guest stands a few metres behind the host | PASS | PASS | stood at (-530, 1654), settled at (-530.0, 1654.0), y=28.3 |
| 11 | 0 | engage_wild — the host engages the Hollows Alpha (production engage press) | PASS | FAIL **(unexpected)** | could not stand where body 53985188796905 was the one on offer (offered nothing) |

## Captured files

