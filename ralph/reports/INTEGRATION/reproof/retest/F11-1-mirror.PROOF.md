# Two-peer proof: F11 mirror: host refuses, guest accepts the Stormheart (space on both sides)

**Verdict: FAIL** (exit 1)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/stormwood_f11_mirror_host_refuses_guest_accepts.json`  
Run: `net-20261004T201637Z-3611`  
Rendered: no (headless)

ACCEPTANCE F11, 'eligible peers accept/refuse independently', mirrored from x05's rendered PASS: both players fought the Dynamo and both have a free party slot; the HOST says No and keeps nothing, the GUEST says Yes and keeps its own Stormheart. Each answer is its own world receipt and its own character receipt; a second press on the now-dark prompt grants nothing. Setup stands in for PLAYING the Dynamo fight only (contributors + Marrow's defeat flag through the ledger); the release, offers, dialogue answers, grants and saves are the game's own code.

## Failures

- #1 peer 0 load_save (named save: Meadows, Stormwood route open, loaded like Continue) -> FAIL; data did not match {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} -- Game.load_game(0) refused /home/user/Tetherbound/tools/net/proof_saves/host_meadows_stormwood_route_open

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | FAIL **(unexpected)** | Game.load_game(0) refused /home/user/Tetherbound/tools/net/proof_saves/host_meadows_stormwood_route_open |

## Captured files

