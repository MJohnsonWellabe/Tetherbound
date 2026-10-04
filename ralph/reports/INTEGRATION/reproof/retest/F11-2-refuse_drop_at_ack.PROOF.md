# Two-peer proof: F11#2: a guest's link dies at its Stormheart REFUSAL acknowledgement; the refusal is settled once and nothing is granted

**Verdict: FAIL** (exit 1)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/f11_stormheart_refuse_drop_at_ack.json`  
Run: `net-20261004T202110Z-4835`  
Rendered: no (headless)

ACCEPTANCE F11 'accept/refuse independently ... through disconnect/reload, without duplicated grants', the refusal-acknowledgement window (the mirror of f11_stormheart_drop_at_ack). Both players fought the Dynamo. The host says Yes. The guest opens its own offer and says No through the real dialogue's No; its transport is closed from the panel's own `declined` signal, before the ending's deferred refusal runs, so the refusal receipt and character save are local and the `ending_settled` acknowledgement finds no connected peer. The host holds no world receipt of the guest's answer and its one claim for the guest is unsettled. The guest rejoins from the title as the same character; the host settles that one claim as REFUSED from the resent claim and the guest's saved receipt. The guest never holds a Stormheart, a repeat claim is refused by the host before and after both peers reload, and the host world records the guest's refusal once and no acceptance. Setup and disclosures as in f11_stormheart_drop_at_ack (captured host save; Dynamo fixture; a local close() sends an ENet disconnect, so this is not a silent partition). Not covered: the host dropping; a drop before the receipt is saved; a silent partition; a rejoin after the 120 s seat hold; the legacy old-build receipt (awaits an owner ruling).

## Failures

- #1 peer 0 load_save (named save: Meadows, Stormwood route open, loaded like Continue) -> FAIL; data did not match {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} -- Game.load_game(0) refused /home/user/Tetherbound/tools/net/proof_saves/host_meadows_stormwood_route_open

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"character_id":"character-f41f4a49223483d6bfdf56715944bb7b","form":"captured directory (split path)","realm":"meadows"} | FAIL **(unexpected)** | Game.load_game(0) refused /home/user/Tetherbound/tools/net/proof_saves/host_meadows_stormwood_route_open |

## Captured files

