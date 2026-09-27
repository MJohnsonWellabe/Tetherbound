# Two-peer proof: DRY RUN — does not count: F06#5: a host saves while its guest is mounted mid-flight, restarts and reloads; the guest rejoins with the same five and the closed gate holds (guest reaches the gate by ordinary movement, no teleport)

**Verdict: FAIL** (exit 1)

Scenario: `tools/net/proof_scenarios/f06_cloudreach_host_restart_mounted_ordinary_dryrun.json`  
Run: `net-20260927T001822Z-2590`  
Rendered: no (headless)

DRY RUN — does not count. Purpose: find blockers before the earned Cloudreach handoff save exists. Same flow as f06_cloudreach_host_restart_mounted_save.json, but every guest `teleport` is replaced by `move_to` (the stick navigator, ordinary input). Still uses the fixture start (story_flag, party_grant, fly_setup), so it can never close F06#5. ACCEPTANCE F06 'save/reload and two-peer rejoin do not bypass a closed gate or lose an owned creature', co-op half (F06#5): the save is made while the guest is mounted and the reload happens mid-flight. The guest's own world has Cloudreach's upper counterweight route OPEN; the host's world has it CLOSED. In the host's session the guest launches on its galecrest at the gate's legal side; while it is in the air its own portable character is written and the HOST saves its world. The host's Godot process then ends and a fresh one starts at the title on the same disk (restart_peer), and loads that save through the title's own Load, which hosts. The guest, dropped to the title mid-flight, rejoins through the title's returning route as the same character. Asserted: exactly the same five creature UIDs in the same order (kept in the guest's process across the restart); same character in Cloudreach; on solid ground; not inside sealed Upper Cloudreach; back at its own spot at the gate's legal side (same host world instance); the gate still closed for host and guest and in the host's saved world; the galecrest carries it again. CONTROL: with the host's gate open, the same save-while-mounted, host restart and rejoin bring the guest back past the gate, so the negative check can fail. Setup stand-ins (disclosed): world flags through the ledger (story_flag) stand in for playing to Cloudreach, the Windscar trial and (guest's world only) the windlass; party_grant and fly_setup fill the guest's five; teleport places the guest. Saves, the process restart, the title Load, join, rejoin, flight and snapshots are the game's own code. Loopback ENet: local evidence, not internet/Steam acceptance.

## Failures

- #19 peer 1 move_to (DRY RUN (replaces teleport): setup: the guest stands at the gate's legal (south) side) -> FAIL -- did not reach (-104.0, 2436.0): 2506.30 m short of close_enough=6.00

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | boot — each peer boots its own fresh Meadows world | PASS | PASS | booted world (240 settle frames) |
| 1 | 1 | boot — each peer boots its own fresh Meadows world | PASS | PASS | booted world (240 settle frames) |
| 2 | 0 | story_flag — setup: both worlds hold the Cloudreach key | PASS | PASS | realm_key_cloudreach: ok=true pending=false code='' reason='' |
| 2 | 1 | story_flag — setup: both worlds hold the Cloudreach key | PASS | PASS | realm_key_cloudreach: ok=true pending=false code='' reason='' |
| 3 | 0 | story_flag — setup: both worlds finished the Windscar flight trial (the Fly gate) | PASS | PASS | fly_traversal_unlocked: ok=true pending=false code='' reason='' |
| 3 | 1 | story_flag — setup: both worlds finished the Windscar flight trial (the Fly gate) | PASS | PASS | fly_traversal_unlocked: ok=true pending=false code='' reason='' |
| 4 | 1 | story_flag — setup: ONLY the guest's own world has the upper counterweight route open (a leak of its own world would show) | PASS | PASS | cloudreach_upper_route_unlocked: ok=true pending=false code='' reason='' |
| 5 | 1 | party_grant | PASS | PASS | 'bramblebun' at level 20 joined the party (1 member(s)) |
| 6 | 1 | party_grant | PASS | PASS | 'terrapup' at level 20 joined the party (2 member(s)) |
| 7 | 1 | party_grant | PASS | PASS | 'brooktail' at level 20 joined the party (3 member(s)) |
| 8 | 1 | party_grant | PASS | PASS | 'mudsnout' at level 20 joined the party (4 member(s)) |
| 9 | 0 | enter_realm — host enters Cloudreach in its own world | PASS | PASS | crossed 'meadows' -> 'cloudreach' after 264 observed physics frames / 105653 ms (budget 6000 physics frames); current scene is /root/CloudreachCliffs |
| 10 | 1 | enter_realm — guest enters Cloudreach in its own world | PASS | PASS | crossed 'meadows' -> 'cloudreach' after 267 observed physics frames / 105769 ms (budget 6000 physics frames); current scene is /root/CloudreachCliffs |
| 11 | 1 | fly_setup — setup: the guest's fifth creature is its Fly carrier (galecrest) | PASS | PASS | SETUP: fly_traversal_unlocked set, galecrest active, anchor=(0.0, 105.0302, -260.0), screen: no SequenceDirector here; nothing holding the screen, launch site: already clear where it stood (locomotion=true carried=false on_floor=true) |
| 12 | 1 | assert — guest owns five | PASS | PASS | party size 5 (wanted 5) |
| 13 | 0 | host | PASS | PASS | hosting udp/34141 as peer 1 |
| 14 | 0 | assert — host world: the upper gate is CLOSED | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 15 | 1 | join | PASS | PASS | joined 127.0.0.1:34141 as peer 453545888 after 6 frames; snapshot applied; 2 peer(s) in registry |
| 16 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 16 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 17 | 1 | assert — the joined guest reads the host's closed gate | FAIL | FAIL | flag cloudreach_upper_route_unlocked NOT set |
| 18 | 1 | probe position — DRY RUN: guest position before walking to (-104, 2436) | any | PASS | [0.0,105.030204772949,-260.0] |
| 19 | 1 | move_to — DRY RUN (replaces teleport): setup: the guest stands at the gate's legal (south) side | PASS | FAIL **(unexpected)** | did not reach (-104.0, 2436.0): 2506.30 m short of close_enough=6.00 |

## Captured files


---
DRY RUN — does not count. Local run at 576a35020205fdd36fdafa7e56d94c99cfc0e03e. Finding: the guest arrives in Cloudreach at (0, 105, -260); the closed gate's legal side is (-104, 2436), ~2.7 km across the cliff regions. A straight-line stick walk (`move_to`, 18000 frames) ended 2506 m short. Reaching the gate by ordinary input needs the real Cloudreach route (road waypoints and Fly legs), which is the C1 earned traversal (Cloudreach lane). The F06#5 co-op proof should instead start from an earned save captured on that route near the gate.
