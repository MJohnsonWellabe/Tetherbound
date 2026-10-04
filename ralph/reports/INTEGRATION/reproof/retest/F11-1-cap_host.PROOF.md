# Two-peer proof: F11 capacity: host full at five says Yes then lets the Stormheart go; guest with space says Yes

**Verdict: FAIL** (exit 1)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/stormwood_f11_capacity_host_full_lets_stormheart_go.json`  
Run: `net-20261004T201726Z-4219`  
Rendered: no (headless)

ACCEPTANCE F11 'at capacity', the other branch of the five-slot choice: the host's belt holds five when it says Yes. The ceremony offers the newcomer's own row; the host lets the Stormheart go, keeps all five, and the game records that as its refusal (stormwood_ending.gd: 'exactly as letting the newcomer go at five'). No sixth slot, no belt member lost. The guest, with space, says Yes and keeps its own, independently. Setup, disclosed: the Dynamo fight fixture and the host's five belt members (party_grant -> party_seam.add); everything from the offer on is the game's own code.

## Failures

- #1 peer 0 load_save (named save: Meadows, Stormwood route open, loaded like Continue) -> FAIL; data did not match {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} -- Game.load_game(0) refused /home/user/Tetherbound/tools/net/proof_saves/host_meadows_stormwood_route_open

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | FAIL **(unexpected)** | Game.load_game(0) refused /home/user/Tetherbound/tools/net/proof_saves/host_meadows_stormwood_route_open |

## Captured files

