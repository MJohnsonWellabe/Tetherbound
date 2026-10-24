# Stormwood lane: F49#0 route pieces S3 and S5 (coordinator direction 24 Oct 06:21Z)

Pieces taken off the Routes queue (`tb/routes` `ralph/reports/ROUTES/close-1024/LEDGER.md`):
- **S5** home_relic → home_credits (Grandpa and credits).
- **S3** t5_altar_5 → training_t5_kitchen → training_t5_feed → training_t5_return (the Stormwood chapter feast, cooked and fed).

Protocol (CLAUDE.md standing direction 2): no committed save reaches either piece (every committed Stormwood fixture predates the training loop; Routes-B's S2/S4 saves were container-local and lost), so each start is regenerated from its disclosed generated boundary exactly as Routes-B ran it, with the existing runners only (`generate_boundary_save.gd`, `stormwood_chain_runner.gd`, `tidewake_piece_runner.gd`). Each passing piece commits its end save, receipt and PROVENANCE under `tests/fixtures/earned_saves/<piece>/` at once and pushes. Pieces before the counted ones were proven by Routes-B and are not counted again.

Branch `tb/stormwood-routes` from origin/main 7480d1a27. Godot 4.7 headless `--fixed-fps 60`, CPU container, one Godot process at a time.

Chains:
- S5: generate `stormwood_rootgate_crown` → dynamo → marrow_settlement (Stormheart refused, five kept) → home_key → home_relic → **home_credits**.
- S3: generate `stormwood_t5_rowan_independent` → rowan_visit → training_t5_home → storage → return → rowan_visit → rowan_chest → preparehome → altar_1..5 → **training_t5_kitchen → feed → return**.

## Piece table
| Piece | Runner | From | SHA | Wall | Result |
|---|---|---|---|---|---|
| f49_s5_gen | generate_boundary_save `stormwood_rootgate_crown` | generated (disclosed) | 7480d1a27 | 54 s | PASS (d33783708) |

## TO COORDINATOR
- 24 Oct 06:30Z STARTED S5 then S3 on tb/stormwood-routes (send_message still refused here). Seams go below as MATCH-RECEIPT lines as pieces pass.
