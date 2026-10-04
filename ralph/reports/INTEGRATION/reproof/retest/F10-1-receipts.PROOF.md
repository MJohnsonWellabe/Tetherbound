# Two-peer proof: F10 six Stormwood side chains: receipts on both peers through a save/reload, never twice

**Verdict: FAIL** (exit 1)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/stormwood_f10_side_chain_receipts.json`  
Run: `net-20261004T201612Z-3274`  
Rendered: no (headless)

ACCEPTANCE F10: all six Stormwood side chains satisfy section 5 with persistent receipts. Two real processes. Each chain's final step (and every earlier step that has one) is played through its production path by ordinary Interact presses: Dark Arches (host: Relight prompts on the four dark arches, the arch runtime's step 2, Hesk's report), Pim's Parcels (guest, client path: Pim, three deliveries, Pim's return; host: Pim's thanks; each character paid 2 Small Potions once through reward_grant), What the Crown Remembers (host: three record prompts, Wen), Glass for Bryn (guest: Bryn's offer and request, the host-owned delivery transaction taking the guest's materials, the inspect prompt), Raise a Road (host: two footing prompts, two Stormglass Arches built through build_place, travel through the new road both ways, Ondra's report), Deepwood Circuit (host: Rook's offer, the chapter runtime crediting three circuit wins, Rook's return). Each completion flag reaches both peers; both save_reload_here; every completion and each character's rate hold on both and in the saved world/character files; a second visit to each completing NPC or prompt offers and grants nothing again. Disclosed fixtures: the host's named save; debug travel (explore_at) to each NPC or prompt instead of walking; main-route facts set as world flags where the side chain has no step of its own (ashfoot_arch_relit, rootgate_released, lantern_pools_linked, crown_reached, crown guardian cleared, engine_truth_learned, bryn_met, arch_recipe_known, lantern_hollow_reached); Stormglass and Conductor Vine granted in place of gathering; the road arches built with Free Build (materials not charged); and three circuit trainers' defeat facts set in place of three hosted fights (the chapter runtime itself turns them into circuit wins).

## Failures

- #1 peer 0 load_save (named save: Meadows, Stormwood route open, loaded like Continue) -> FAIL; data did not match {"form":"captured directory (split path)","realm":"meadows"} -- Game.load_game(0) refused /home/user/Tetherbound/tools/net/proof_saves/host_meadows_stormwood_route_open

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open, loaded like Continue | PASS + {"form":"captured directory (split path)","realm":"meadows"} | FAIL **(unexpected)** | Game.load_game(0) refused /home/user/Tetherbound/tools/net/proof_saves/host_meadows_stormwood_route_open |

## Captured files

