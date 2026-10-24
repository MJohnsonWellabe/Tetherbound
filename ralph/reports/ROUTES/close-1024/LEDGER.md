# F49#0 seam ledger (Routes, built from main 5f1f388cc, 23 Oct 2026)

Each row is a seam: the end save of the left piece must be the start save of the right piece. The kinds:
- **MATCH-SAVED**: both saves are committed under `tests/fixtures/earned_saves/`, and the right piece's receipt loads the left one.
- **MATCH-RECEIPT**: proven by receipts and a seam manifest (`ralph/reports/ROUTES*/close-1020/seams/`), but the saves were container-local and lost.
- **GENERATED**: the right piece starts from a disclosed generated boundary, not from the left piece's end save. No run proves the seam.
- **MISSING**: the right piece is unproven.

The committed fixtures are the older chain from before the training loop: generated arrivals at L20/L31/L40 with no Master wins and no feasts. None of them carries a training-loop state. So every Master/Kitchen piece ran from an independent generated boundary.

## Piece order and seam status

| # | Seam (left → right) | Kind | Evidence |
|---|---|---|---|
| M1 | new game → opening_village → … → bridge (4 pieces) | MATCH-RECEIPT (current chain); the old chain `meadows_chain_ev_fights` is MATCH-SAVED | ROUTES close-1020 receipts 01–04 |
| M2 | bridge → t1_earn → t1_altar_1..5 → t1_master → t1_kitchen → t1_feed (9 seams) | MATCH-RECEIPT | close-1020 seams |
| M3 | t1_feed → t2_earn → t2_altar_1..5 → t2_master → t2_kitchen → t2_feed → t2_return | MISSING (six t2_earn refusals; not run since) | close-1020 note |
| M4 | t2_return → warrens | MISSING | |
| M5 | warrens → relay | GENERATED (relay from the `relay` profile, PASS 1c0078796) | |
| M6 | relay → sigils | MISSING (sigils abandoned: entombed near the Sigil gate (-224,6602)) | |
| M7 | sigils → hall | GENERATED (hall from the `hall` profile, PASS ac9a32e22) | |
| M8 | hall → warden → tidewake_handoff | MATCH-RECEIPT | seams/hall__warden, warden__tidewake_handoff |
| T1 | tidewake_handoff → tidewake 01_opening | GENERATED (`tidewake_arrival_generated`, L20) | |
| T2 | 01 → 02 → 03 → 04 → 05_tidal | MATCH-SAVED | fixtures tidewake_01..05 |
| T3 | 05_tidal → T3 loop (05i Ione → … → training_t3_return) | GENERATED start (`tidewake_t3_ione_independent`, L29); 12 inner seams MATCH-RECEIPT, real master_t3 and feasts | close-1020 |
| T4 | t3_return → 07a_salt_bex | GENERATED (`tidewake_late_independent`, L31) | |
| T5 | 07a → 07b → 07c → 07d → 08_ending → 09_cloudreach_handoff | MATCH-RECEIPT (L31 chain); older L44 chain 07_human_late → 08_ending_earned → 09 is MATCH-SAVED | close-1020; fixtures |
| C1 | tidewake 09 → cloudreach 01_arrival_gate | GENERATED (`cloudreach_arrival_generated`, L31) | |
| C2 | 01 → 02 → 03 → 04_high_roost | MATCH-SAVED | fixtures cloudreach_01..04 |
| C3 | 04 → 05/06_veyra_relay | GENERATED (`cloudreach_05_generated_veyra_boundary`, L40) | |
| C4 | 06 → 07_stormward_handoff | MATCH-SAVED | fixtures cloudreach_06, 07 |
| C5 | 07 → T4 loop (06k … Aster … altar_5) | GENERATED start (`cloudreach_t4_aster_independent`, L39); inner seams to altar_5 MATCH-RECEIPT, real master_t4 | ROUTES-B close-1020 |
| C6 | t4_altar_5 → t4_kitchen → t4_feed → t4_return | MISSING; owner Routes; start chain regenerated and committed (`tests/fixtures/earned_saves/f49_c4_*`), Kitchen running | |
| C7 | t4_return → 07_stormward_handoff (trained) | MISSING; owner Routes; queued after C6 | |
| S1 | cloudreach 07 → stormwood 01_arrival_prefix → 02 → 03 → 04 → 05_rootgate → 06_dynamo → 07_marrow_aftermath | MATCH-SAVED (no training state; 07 accepts the Stormheart and releases slot 4, which breaks the five) | fixtures stormwood_01..07 |
| S2 | rootgate → T5 loop (Rowan … altar_5) | GENERATED start (`stormwood_t5_rowan_independent`, L49); inner seams MATCH-RECEIPT except t5_chest → preparehome (8 m Load placement, UNEXPLAINED), real master_t5 | ROUTES-B |
| S3 | t5_altar_5 → t5_kitchen → t5_feed → t5_return | MISSING; **owner: Stormwood lane (tb/stormwood-routes)** | |
| S4 | ending: dynamo → marrow_settlement (Stormheart refused, five kept) → home_key → home_relic | GENERATED start (`stormwood_rootgate_crown`); inner seams MATCH-RECEIPT | ROUTES-B |
| S5 | home_relic → home_credits | MISSING; **owner: Stormwood lane (tb/stormwood-routes)** | |

## Per-chapter Master and feast (cooked and fed)
- Meadows: T1 proven (Orin; Kitchen; five feasts fed).
- Tidewake: T3 proven (Ione), from a generated start.
- Cloudreach: master_t4 proven; Kitchen and feed MISSING (C6).
- Stormwood: master_t5 proven; Kitchen and feed MISSING (S3).

## Count
Missing pieces: M3, M4, M6, C6, C7, S3, S5. Generated seams no run proves: M5, M7, T1, T3, T4, C1, C3, C5, S2, S4. A generated seam closes only by running the left piece's real end save into the right piece. The bulk of that is level: generated L29/L31/L39/L49 against earned L20/L31/L40.

Owners (coordinator, 24 Oct 06:21Z): Routes owns C6, C7 and the Meadows rows (M3–M7); the Stormwood lane owns S3 and S5.
