# Two-peer proof: F11: a guest's link dies at the Stormheart claim acknowledgement; no duplicated grant

**Verdict: FAIL** (exit 1)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/f11_stormheart_drop_at_ack.json`  
Run: `net-20261004T201816Z-4553`  
Rendered: no (headless)

ACCEPTANCE F11 'through disconnect ... without duplicated grants', the claim-acknowledgement window. Both players fought the Dynamo. The host says Yes. The guest walks up, opens its own offer and says Yes through the real dialogue. The guest's transport is closed from the dialogue's own `completed` signal, in the physics step that accepted the Yes. The ending then records the receipt and saves the character locally (stormwood_ending.gd _finish_local_claim), and its `ending_settled` acknowledgement fails with 'Trying to call an RPC via a multiplayer peer which is not connected' (peer-1 log). The host holds no world receipt of the guest's answer and its one claim for the guest is unsettled. The guest rejoins from the title as the same character. The host settles that one claim from the resent claim and the guest's saved receipt (settled, kept), and the guest holds exactly one Stormheart. A repeat of the claim the prompt sends is refused by the host, before and after both peers reload. Setup: the host's captured save with the Stormwood route open, and the Dynamo fixture, which also commits stormwood:act_ii_complete and stormwood:marrow_defeated through the ledger. Disclosed: the local close() sends an ENet disconnect, so the host sees the leave at once (a silent partition is not this proof); the guest's leave-time character write runs before the deferred commit, as a real link death would not order it; after the rejoin the guest arrives downed (it lands from height near the Stormheart), which touches no grant. Not covered here: the host dropping; a refusal at the acknowledgement; a drop before the receipt is saved; a silent partition timed out by the host; a rejoin after the 120 s seat hold.

## Failures

- #1 peer 0 load_save (named save: Meadows, Stormwood route open, loaded like Continue) -> FAIL; data did not match {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} -- Game.load_game(0) refused /home/user/Tetherbound/tools/net/proof_saves/host_meadows_stormwood_route_open

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | FAIL **(unexpected)** | Game.load_game(0) refused /home/user/Tetherbound/tools/net/proof_saves/host_meadows_stormwood_route_open |

## Captured files

