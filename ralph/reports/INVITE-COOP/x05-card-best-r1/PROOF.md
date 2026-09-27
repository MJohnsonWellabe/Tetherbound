# Two-peer proof: X05: host-rolled guest defence carries Best Creature survivability (co-op parity)

**Verdict: FAIL** (exit 1)

Scenario: `/home/runner/work/Tetherbound/Tetherbound/tools/net/proof_scenarios/x05_card_best_survivability.json`  
Run: `net-20260927T100433Z-2209`  
Rendered: no (headless)

encounter_director._creature_card now passes is_best and the species' Best Creature ability to effective_defence, as combat_manager's solo hit path does, and re-announces the card when the title moves while the creature stays deployed. Two peers: the host reads the card it holds for the guest (the defence host_pick_struck_participant hands to every host-rolled blow) and compares it with the solo reference rebuilt from the card's species and level, before, during and after the guest designates its deployed Terrapup. Setup: production deploy/adopt only; no fixtures.

## Failures

- #7 peer 1 party_best (guest designates its deployed Terrapup Best Creature (party toggle)) -> FAIL; data did not match {"best_index":0.0,"species":"terrapup"} -- Best Creature on slot 0: {"active_index":0,"best_index":-1,"index":0,"species":""}

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | host | PASS | PASS | hosting udp/35641 as peer 1 |
| 2 | 1 | join | PASS | PASS | joined 127.0.0.1:35641 as peer 507720931 after 9 frames; snapshot applied; 2 peer(s) in registry |
| 3 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 3 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 4 | 0 | deploy_creature — host production summon (a creature out on both sides) | PASS | PASS | deployed AllyCreature |
| 5 | 1 | deploy_creature — guest production summon/adopt of the Terrapup starter; its card is announced to the host | PASS | PASS | deployed AllyCreature |
| 6 | 0 | host_card_defence — BASELINE: guest creature not designated -- host card defence equals plain solo effective defence | PASS | PASS | host card for peer 507720931 (want plain): {"ability_kind":"survivability","best_ref":25.3,"bond_nodes":0,"bonus_is_real":true,"defence":22.0,"level":3,"matches_best":false,"matches_plain":true,"peer_id":507720931,"plain_ref":22.0,"species":"terrapup"} |
| 7 | 1 | party_best — guest designates its deployed Terrapup Best Creature (party toggle) | PASS + {"best_index":0.0,"species":"terrapup"} | FAIL **(unexpected)** | Best Creature on slot 0: {"active_index":0,"best_index":-1,"index":0,"species":""} |

## Captured files

