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
| M3 | Meadows t2 loop (Mira): generated `meadows_t2_independent` (post-Relay at Mira's sign, L20/cap20 [1], master_t1) → training_t2_master → t2_home → t2_kitchen → t2_feed | GENERATED start (coordinator ruling b); 3 inner seams **MATCH-SAVED** (25 Oct): saves `f49_m2_*`, seams close-1024/seams/m2_*; real master_t2 (Mira) and five feast_t2 cooked and fed. Trained order corrected (bf66c02f1): the t2 loop follows relay | |
| M4 | t2_return → warrens | MISSING | |
| M5 | warrens → relay | GENERATED (relay from the `relay` profile, PASS 1c0078796) | |
| M6 | relay → sigils | **MATCH-SAVED** (25 Oct): `f49_ms_relay` (relay from the generated `relay` profile, 5056 s) → `f49_ms_sigils` (18747 s: three captains 5/5 rounds, three sigils spent, Sigil Gate crossed); seam close-1024/seams/ms_relay__ms_sigils.json (consumer's hash-bound predecessor = producer receipt) | |
| M7 | sigils → hall | **MATCH-SAVED** (25 Oct): `f49_ms_hall` (7514 s) from `f49_ms_sigils`; seam ms_sigils__ms_hall | |
| M8 | hall → warden → tidewake_handoff | **MATCH-SAVED** (25 Oct): `f49_ms_warden` (1866 s), `f49_ms_tidewake_handoff` (696 s, ends in Tidewake); seams ms_hall__ms_warden, ms_warden__ms_tidewake_handoff | |
| T1 | tidewake_handoff → tidewake 01_opening | GENERATED (`tidewake_arrival_generated`, L20) still. Prepared: 01 loads `f49_ms_tidewake_handoff` (pinned start, generated-origin Meadows lineage; 05e3fc8b2). Run stopped at load for the owner's pause, not a failure | |
| T2 | 01 → 02 → 03 → 04 → 05_tidal | MATCH-SAVED | fixtures tidewake_01..05 |
| T3 | 05_tidal → T3 loop (05i Ione → … → training_t3_return) | GENERATED start (`tidewake_t3_ione_independent`, L29); 12 inner seams MATCH-RECEIPT, real master_t3 and feasts | close-1020 |
| T4 | t3_return → 07a_salt_bex | GENERATED (`tidewake_late_independent`, L31) | |
| T5 | 07a → 07b → 07c → 07d → 08_ending → 09_cloudreach_handoff | MATCH-RECEIPT (L31 chain); older L44 chain 07_human_late → 08_ending_earned → 09 is MATCH-SAVED | close-1020; fixtures |
| C1 | tidewake 09 → cloudreach 01_arrival_gate | GENERATED (`cloudreach_arrival_generated`, L31) | |
| C2 | 01 → 02 → 03 → 04_high_roost | MATCH-SAVED | fixtures cloudreach_01..04 |
| C3 | 04 → 05/06_veyra_relay | GENERATED (`cloudreach_05_generated_veyra_boundary`, L40) | |
| C4 | 06 → 07_stormward_handoff | MATCH-SAVED | fixtures cloudreach_06, 07 |
| C5 | 07 → T4 loop (06k … Aster … altar_5) | GENERATED start (`cloudreach_t4_aster_independent`, L39); inner seams to altar_5 MATCH-RECEIPT, real master_t4 | ROUTES-B close-1020 | Regenerated and committed 23–24 Oct: `cloudreach_t4_aster_generated` → `f49_c4_06k` … `f49_c4_a5`, 19 seams MATCH in close-1024/seams. |
| C6 | t4_altar_5 → t4_kitchen_1 → t4_kitchen_2 → t4_kitchen_3 → t4_feed → t4_return | **MATCH-SAVED** (Routes, 25 Oct): saves `tests/fixtures/earned_saves/f49_c4_*`, seams `ralph/reports/ROUTES/close-1024/seams/`; five feast_t4 cooked and fed, breakthroughs [1,2,3,4] | |
| C7 | t4_return → 07_stormward_handoff (trained) | **MATCH-SAVED** (Routes, 25 Oct): `f49_c4_07` ends in Stormwood with master_t1..t4 | |
| S1 | cloudreach 07 → stormwood 01_arrival_prefix → 02 → 03 → 04 → 05_rootgate → 06_dynamo → 07_marrow_aftermath | MATCH-SAVED (no training state; 07 accepts the Stormheart and releases slot 4, which breaks the five) | fixtures stormwood_01..07 |
| S2 | rootgate → T5 loop (Rowan … altar_5) | GENERATED start (`stormwood_t5_rowan_independent`, L49); inner seams MATCH-RECEIPT except t5_chest → preparehome (8 m Load placement, UNEXPLAINED), real master_t5 | ROUTES-B |
| S3 | t5_altar_5 → t5_kitchen → t5_feed → t5_return | MISSING; **owner: Stormwood lane (tb/stormwood-routes)** | |
| S4 | ending: dynamo → marrow_settlement (Stormheart refused, five kept) → home_key → home_relic | GENERATED start (`stormwood_rootgate_crown`); inner seams MATCH-RECEIPT | ROUTES-B |
| S5 | home_relic → home_credits | MISSING; **owner: Stormwood lane (tb/stormwood-routes)** | |

## Per-chapter Master and feast (cooked and fed)
- Meadows: T1 proven (Orin; Kitchen; five feasts fed) and T2 proven (Mira; Kitchen; five feasts fed) from the generated t2 boundary.
- Tidewake: T3 proven (Ione), from a generated start.
- Cloudreach: T4 proven end to end (Aster, chest, five Altar slots, Kitchen tiers 1–3, five feasts cooked and fed), from the generated T4 boundary.
- Stormwood: master_t5 proven; Kitchen and feed MISSING (S3).

## Count
Missing pieces: M4, S3 (C6, C7 and M3 closed 25 Oct; S5 home_credits passed on tb/stormwood-routes as f49_s5b_home_credits). Generated seams no run proves: M5, T1, T3, T4, C1, C3, C5, S2, S4. A generated seam closes only by running the left piece's real end save into the right piece. The bulk of that is level: generated L29/L31/L39/L49 against earned L20/L31/L40.

Owners (coordinator, 24 Oct 06:21Z): Routes owns C6, C7 and the Meadows rows (M3–M7); the Stormwood lane owns S3 and S5.
