# Two-peer proof: X05 guest lane presentation: a guest in the host's Hollows Alpha fight sees the travelling lane

**Verdict: FAIL** (exit 2)

Scenario: `/home/runner/work/Tetherbound/Tetherbound/tools/net/proof_scenarios/x05_guest_lane_presentation.json`  
Run: `net-20260927T020102Z-2486`  
Rendered: yes

Presentation evidence for the guest-side lane/cue change (#356 01:40 ruling; not a criterion close). The host engages the Hollows Alpha (a Stormwood named CHARGER, lunge_travels) through the production engage press; the guest joins through the production joinable list. Each peer then waits until ITS OWN view draws the lane: the host's real wild body, and the guest's SharedOpponentProxy drawing it from the host's optional cue shape. Setup, disclosed: the host save has the Stormwood route open and both peers use explore_at to stand at the Hollows Alpha instead of walking there.

## Failures

- #1 peer 0 load_save -> ERROR -- ERROR: peer silent (peer 0, no heartbeat for >15 s)
- ERROR: peer silent (peer 0, no heartbeat for >15 s)

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save | PASS | ERROR **(unexpected)** | ERROR: peer silent (peer 0, no heartbeat for >15 s) |

## Captured files

