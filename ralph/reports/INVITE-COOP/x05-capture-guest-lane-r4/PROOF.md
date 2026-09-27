# Two-peer proof: X05 guest lane presentation: a guest in the host's Hollows Alpha fight sees the travelling lane

**Verdict: PASS** (exit 0)

Scenario: `/home/runner/work/Tetherbound/Tetherbound/tools/net/proof_scenarios/x05_guest_lane_presentation.json`  
Run: `net-20260927T032609Z-2489`  
Rendered: yes

Presentation evidence for the guest-side lane/cue change (#356 01:40 ruling; not a criterion close). The host engages the Hollows Alpha (a Stormwood named CHARGER, lunge_travels) through the production engage press; the guest joins through the production joinable list. Each peer then waits until ITS OWN view draws the lane: the host's real wild body, and the guest's SharedOpponentProxy drawing it from the host's optional cue shape. Setup, disclosed: the host save has the Stormwood route open and both peers use explore_at to stand at the Hollows Alpha instead of walking there.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save | PASS | PASS | loaded host_meadows_stormwood_route_open (captured directory (split path)) as slot 0; realm 'meadows' booted as 'world'; character 'character-f41f4a49223483d6bfdf56715944bb7b' |
| 2 | 1 | boot — guest: a fresh trainer in the Meadows | PASS | PASS | booted world (240 settle frames) |
| 3 | 0 | host | PASS | PASS | hosting udp/33141 as peer 1 |
| 4 | 1 | join | PASS | PASS | joined 127.0.0.1:33141 as peer 1029026675 after 10 frames; snapshot applied; 2 peer(s) in registry |
| 5 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 5 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 6 | 0 | wait_flag | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 6 | 1 | wait_flag | PASS | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 7 | 0 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 480 observed physics frames / 24989 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 8 | 1 | enter_realm | PASS | PASS | crossed 'meadows' -> 'stormwood' after 493 observed physics frames / 21181 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 9 | 0 | explore_at — SETUP: the host stands at the Hollows Alpha | PASS | PASS | stood at (-526, 1660), settled at (-526.0, 1660.0), y=29.4 |
| 10 | 1 | explore_at — SETUP: the guest stands a few metres behind the host | PASS | PASS | stood at (-530, 1654), settled at (-530.0, 1654.0), y=28.3 |
| 11 | 0 | deploy_creature — SETUP: the host's lead creature is out (the engage press needs a standing ally) | PASS | PASS | deployed AllyCreature |
| 12 | 0 | probe deployed_creatures — DIAG: host's deployed bodies before the engage | PASS | PASS | {"AllyCreature":{"authority":1.0,"local":true,"mine":true,"owner":1.0,"pos":[-525.11181640625,29.2660598754883,1657.6494140625],"species":"terrapup","visible":true},"AllyCreature_1":{"authority":1.0,"local":false,"mine":true,"owner":1.0,"pos":[-525.098205566406,29.2654132843018,1657.638671875],"species":"terrapup","visible":false}} |
| 13 | 0 | probe tournament — DIAG: host party before the engage | PASS | PASS | {"battle_active":false,"flags":{"recipe_saddle":false,"tournament_quarter_won":false,"tournament_semi_won":false,"tournament_won":false},"party_ids":[],"ready":false,"selection_ids":[]} |
| 14 | 0 | engage_wild — the host engages the Hollows Alpha (production engage press) | PASS | PASS | engaged voltarach as encounter 1:1 (bound after 0 frame(s)) |
| 15 | 1 | deploy_creature — SETUP: the guest's lead creature is out (joining needs a standing ally) | PASS | PASS | deployed AllyCreature |
| 16 | 1 | join_running_fight — the guest joins the host's fight in progress (production join_encounter) | PASS | PASS | joined 1:1 beside 'voltarach' at (-523.0, 1659.4) |
| 17 | 1 | shared_cue_shape — GUEST: its proxy draws the Alpha's lane from the host's cue shape | PASS | PASS | guest proxy draws the lane: {"body":"guest proxy","cone":false,"lane":true,"lane_length":7.0,"lane_locked":false,"routes":0,"screenshot":"/home/runner/work/Tetherbound/Tetherbound/ralph/reports/INVITE-COOP/x05-capture-guest-lane-r4/peer-1/01_guest_sees_lane.png","telegraphs":1} |
| 18 | 0 | shared_cue_shape — HOST: the real body draws the same lane | PASS | PASS | host wild draws the lane: {"body":"host wild","cone":false,"lane":true,"lane_length":7.0,"lane_locked":false,"screenshot":"/home/runner/work/Tetherbound/Tetherbound/ralph/reports/INVITE-COOP/x05-capture-guest-lane-r4/peer-0/02_host_sees_lane.png","telegraphs":11} |
| 19 | 1 | shared_cue_shape — GUEST: a later tell draws it again | PASS | PASS | guest proxy draws the lane: {"body":"guest proxy","cone":false,"lane":true,"lane_length":7.0,"lane_locked":true,"routes":0,"screenshot":"/home/runner/work/Tetherbound/Tetherbound/ralph/reports/INVITE-COOP/x05-capture-guest-lane-r4/peer-1/03_guest_sees_lane_again.png","telegraphs":11} |

## Captured files

- `peer-0/02_host_sees_lane.png`
- `peer-1/01_guest_sees_lane.png`
- `peer-1/03_guest_sees_lane_again.png`
