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
| f49_s5_dynamo | stormwood_chain_runner dynamo | f49_s5_gen | d33783708 | 10643 s | PASS (a8ea1b504) |
| f49_s5_marrow_settlement | stormwood_chain_runner | f49_s5_dynamo | a8ea1b504 | 1425 s | PASS (a2fc7e4ef): Stormheart refused, five kept |
| f49_s5_home_key | stormwood_chain_runner | f49_s5_marrow_settlement | a2fc7e4ef | 1147 s | PASS (a119bec15) |
| f49_s5_home_relic | stormwood_chain_runner | f49_s5_home_key | a119bec15 | 217 s | PASS (812890f12) |
| f49_s5_home_credits | stormwood_chain_runner | f49_s5_home_relic | 812890f12 | 678 s | **FAIL**: "F49 homecoming lacks the four actual personal chapter choices" |
| f49_s3_gen | generate_boundary_save `stormwood_t5_rowan_independent` | generated (disclosed) | 812890f12 | 55 s | PASS (45dad1ad9) |
| f49_s3_rowan_visit | stormwood_chain_runner | f49_s3_gen | 45dad1ad9 | 3134 s | PASS (6ed02b58f): master_t5 won |
| f49_s3_home | tidewake_piece_runner training_t5_home | f49_s3_rowan_visit | 6ed02b58f | 342 s | PASS (40353e1c9) |
| f49_s3_storage | training_t5_storage | f49_s3_home | 40353e1c9 | 1031 s | PASS (87249f49a) |
| f49_s3_return1 | training_t5_return | f49_s3_storage | 87249f49a | 337 s | PASS (3ee3a508a) |
| f49_s3_rowan_visit2 | stormwood_chain_runner rowan_visit | f49_s3_return1 | 3ee3a508a | 3018 s | PASS (faec30135) |
| f49_s3_rowan_chest | stormwood_chain_runner | f49_s3_rowan_visit2 | faec30135 | 55 s | PASS (6fc5c4b23): feast_t5 + kit |
| f49_s3_preparehome | training_t5_preparehome | f49_s3_rowan_chest | 6fc5c4b23 | 306 s | PASS (f38fbf60a) |
| f49_s3_a1 | training_t5_altar_1 | f49_s3_preparehome | f38fbf60a | 11 s | REFUSED: "Preparation predecessor must use the exact consumer source commit" |
| f49_s5b_gen | generate `stormwood_rootgate_crown` (corrected) | generated (disclosed) | f38fbf60a | 50 s | PASS (1ace2679d): carries cloudreach:legendary_refused/settled |

### S3 altar refusal (driver, not game)
- `chapter_homestead.predecessor_error` requires preparehome → altar_1..5 to run at one source commit (no shared-base reloads within the preparation sequence). This lane's driver committed each passing save at once, so HEAD moved between preparehome (6fc5c4b23) and altar_1 (f38fbf60a). Routes-B ran its altar run at one SHA (e8cff1d5) for the same reason.
- Resume (queued after S5b): preparehome again from the committed `f49_s3_rowan_chest`, then altar_1..5, all at one HEAD; their saves commit together right after altar_5 passes; then kitchen, feed, return commit one by one. The committed `f49_s3_preparehome` stays as superseded evidence.

### S5 home_credits failure and correction
- `GameState.regional_ending_context()` builds one chapter choice per biome from personal flags (`legendary_joined/refused`, `water:…`, `cloudreach:…`) plus the Stormwood answer; the F49 helper requires four. The regenerated save carries `legendary_refused`, `water:legendary_refused` and the Stormwood answer, but no Cloudreach answer: the disclosed `stormwood_rootgate_crown` profile predates the Solmane offer (owner ruling 2026-09-27, #356: Solmane is offered after Captain Veyra). Even the committed earned Cloudreach fixtures 06/07 carry none (they predate it too).
- Correction (efb4b5389, smallest, disclosed): that one profile gains personal `cloudreach:legendary_refused` and world `cloudreach:legendary_settled`, the same shape as its Meadows answer; its disclosure text says so. No game code, no other profile, no relaxed check.
- Next proof: S5 reruns from a regenerated start as `f49_s5b_*` (gen → dynamo → marrow_settlement → home_key → home_relic → home_credits) once the S3 chain finishes (one Godot at a time). The f49_s5_* saves stay committed as the failed attempt's evidence.

## TO COORDINATOR
- 24 Oct 10:35Z S5 home_credits FAIL on the stale generated boundary (no Cloudreach Solmane answer, so three chapter choices, not four). Profile corrected in efb4b5389 (disclosed); S5 reruns as f49_s5b_* after S3. Note for Routes: the `stormwood`, `stormwood_t5_rowan_independent` and Cloudreach-late profiles carry no Cloudreach answer either; any piece that reaches the homecoming from them hits the same check.
- 24 Oct 06:30Z STARTED S5 then S3 on tb/stormwood-routes (send_message still refused here). Seams go below as MATCH-RECEIPT lines as pieces pass.
