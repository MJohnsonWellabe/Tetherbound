# Two-peer proof: F11 capacity: guest full at five says Yes and gives up a belt member; host with space says Yes

**Verdict: FAIL** (exit 1)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/stormwood_f11_capacity_guest_full_releases_belt.json`  
Run: `net-20261004T201751Z-4463`  
Rendered: no (headless)

ACCEPTANCE F11 'at capacity' + CLAUDE.md 'five creatures total, no hidden sixth': the guest's belt already holds five when it says Yes to its own Stormheart. The Stormheart does not take a sixth slot and is not silently dropped: Yes hands it to the Team tab's five-slot release ceremony (stormwood_ending.gd _begin_local_ceremony -> Game.pending_catch), where the guest, by ordinary presses, lets belt row 1 (bramblebun) go and the Stormheart takes that holder. The host, with a free slot, says Yes and keeps its own. Setup, disclosed: the Dynamo fight (contributors + Marrow's flag, as x05's fixture) and the guest's five belt members (peer_runner party_grant -> party_seam.add, the game's own add), since no named save with a full five exists; everything from the offer on is the game's own code.

## Failures

- #1 peer 0 load_save (named save: Meadows, Stormwood route open, loaded like Continue) -> FAIL; data did not match {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} -- Game.load_game(0) refused /home/user/Tetherbound/tools/net/proof_saves/host_meadows_stormwood_route_open

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | FAIL **(unexpected)** | Game.load_game(0) refused /home/user/Tetherbound/tools/net/proof_saves/host_meadows_stormwood_route_open |

## Captured files

