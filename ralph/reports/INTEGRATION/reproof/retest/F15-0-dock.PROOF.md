# Two-peer proof: F15: host and guest settle the dock exchange once

**Verdict: FAIL** (exit 1)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/f15_dock_exchange_once.json`  
Run: `net-20261004T205159Z-6468`  
Rendered: no (headless)

ACCEPTANCE F15 (T3): 'Host and guest settle the dock exchange once' - the ordinary (no-crash) half. Setup stands in for reaching Water with the swim lesson done and the materials gathered only. The guest walks to the Reedhaven departure dock and presses 'Repair departure dock' (the one PAID dock action: 6 reed fiber + 4 driftwood) through the real prompt; the host presses a different action (Deep Watch chart, free). Each must be done once, the payer's cost taken exactly once, and later presses of the finished repair by either player charge nothing.

## Failures

- #1 peer 0 load_save (named save: the host's world) -> FAIL; data did not match {"realm":"meadows"} -- Game.load_game(0) refused /home/user/Tetherbound/tools/net/proof_saves/host_meadows_stormwood_route_open

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: the host's world | PASS + {"realm":"meadows"} | FAIL **(unexpected)** | Game.load_game(0) refused /home/user/Tetherbound/tools/net/proof_saves/host_meadows_stormwood_route_open |

## Captured files

