# Two-peer proof: F11 mirror, clean health: host refuses, guest accepts, both trainers up when they answer

**Verdict: FAIL** (exit 1)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/stormwood_f11_mirror_clean_health.json`  
Run: `net-20261004T201701Z-3888`  
Rendered: no (headless)

Rerun of the mirrored mix (host No, guest Yes, free slot on both sides) asserting that both trainers are up (DownedState local_downed=false, never expired or revived) on arrival, immediately before and immediately after each answer. The first mirror run's guest had gone down on arrival (0/100). No double-press steps here: stormheart_answer's fallback offsets on an already-dark prompt were the likely fall in the capacity run, and the double press is proven in the other two runs. Setup: the Dynamo fight fixture only.

## Failures

- #1 peer 0 load_save (named save: Meadows, Stormwood route open, loaded like Continue) -> FAIL; data did not match {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} -- Game.load_game(0) refused /home/user/Tetherbound/tools/net/proof_saves/host_meadows_stormwood_route_open

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | FAIL **(unexpected)** | Game.load_game(0) refused /home/user/Tetherbound/tools/net/proof_saves/host_meadows_stormwood_route_open |

## Captured files

