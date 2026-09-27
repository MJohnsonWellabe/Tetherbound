# Two-peer proof: X05: host-rolled guest defence carries Best Creature survivability (co-op parity)

**Verdict: PASS** (exit 0)

Scenario: `/home/runner/work/Tetherbound/Tetherbound/tools/net/proof_scenarios/x05_card_best_survivability.json`  
Run: `net-20260927T102512Z-2498`  
Rendered: no (headless)

encounter_director._creature_card now passes is_best and the species' Best Creature ability to effective_defence, as combat_manager's solo hit path does, and re-announces the card when the title moves while the creature stays deployed. Two peers: the host reads the card it holds for the guest (the defence host_pick_struck_participant hands to every host-rolled blow) and compares it with the solo reference rebuilt from the card's species and level, before, during and after the guest designates its deployed Terrapup. Setup (disclosed): party_grant of one creature per peer into Game.party before the production summon (adopt_starter never enters Game.party, so there would be no slot to designate).

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | host | PASS | PASS | hosting udp/29121 as peer 1 |
| 2 | 1 | join | PASS | PASS | joined 127.0.0.1:29121 as peer 1812441648 after 10 frames; snapshot applied; 2 peer(s) in registry |
| 3 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 3 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 4 | 0 | party_grant — setup: host party member (so summon uses Game.party) | PASS | PASS | 'bramblebun' at level 20 joined the party (1 member(s)) |
| 5 | 1 | party_grant — setup: guest party gains a Terrapup (Best Creature ability shell_guard, survivability +15%) in Game.party slot 0 | PASS | PASS | 'terrapup' at level 20 joined the party (1 member(s)) |
| 6 | 0 | deploy_creature — host production summon (a creature out on both sides) | PASS | PASS | deployed AllyCreature |
| 7 | 1 | deploy_creature — guest production summon of its party Terrapup; its card is announced to the host | PASS | PASS | deployed AllyCreature |
| 8 | 0 | host_card_defence — BASELINE: guest creature not designated -- host card defence equals plain solo effective defence | PASS | PASS | host card for peer 1812441648 (want plain): {"ability_kind":"survivability","best_ref":44.85,"bond_nodes":0,"bonus_is_real":true,"defence":39.0,"level":20,"matches_best":false,"matches_plain":true,"peer_id":1812441648,"plain_ref":39.0,"species":"terrapup"} |
| 9 | 1 | party_best — guest designates its deployed Terrapup Best Creature (party toggle) | PASS + {"best_index":0.0,"species":"terrapup"} | PASS | Best Creature on slot 0: {"active_index":0,"best_index":0,"index":0,"species":"terrapup"} |
| 10 | 0 | host_card_defence — PARITY: host card defence now equals the solo Best Creature survivability defence (shell_guard +15%) -- the number every host-rolled blow on the guest uses | PASS + {"ability_kind":"survivability","bonus_is_real":true} | PASS | host card for peer 1812441648 (want best): {"ability_kind":"survivability","best_ref":44.85,"bond_nodes":0,"bonus_is_real":true,"defence":44.85,"level":20,"matches_best":true,"matches_plain":false,"peer_id":1812441648,"plain_ref":39.0,"species":"terrapup"} |
| 11 | 1 | party_best — guest clears the title | PASS + {"best_index":-1.0} | PASS | Best Creature off slot 0: {"active_index":0,"best_index":-1,"index":0,"species":"terrapup"} |
| 12 | 0 | host_card_defence — PARITY: the refreshed card drops the bonus | PASS | PASS | host card for peer 1812441648 (want plain): {"ability_kind":"survivability","best_ref":44.85,"bond_nodes":0,"bonus_is_real":true,"defence":39.0,"level":20,"matches_best":false,"matches_plain":true,"peer_id":1812441648,"plain_ref":39.0,"species":"terrapup"} |

## Captured files

