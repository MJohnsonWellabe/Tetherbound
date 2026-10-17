# Routes restart 17 Oct: work note

Cloud container, 4 CPU / 15 GB, Godot 4.7 headless (no rasterization; mechanics pieces only). Source: tb/routes from origin/main 13a8fdda6 (clean tree). Runner: `tools/earned_saves/earned_chain_runner.gd --training-profile=meadows_training_v1`, each piece in its own absent root under `~/routes/`, every piece after the first `--handoff-from=<previous piece dir>`. Receipts copied to `receipts/`; saves stay local.

| Piece | Root | Wall | Result |
|---|---|---|---|
| opening_village (fresh title) | p01b_village | 262 s | PASS, party Terrapup L3 + Bramblebun L2, 19 flags |
| opening_team | p02_team | 675 s | PASS, five owned, all L5, 12 flags |
| camp_tournament | p03_camp | 1171 s | PASS, L7/7/7/5/5, 45 flags |
| bridge | p04_bridge | 874 s | PASS, L8/8/7/5/5, crossed South Bridge |

Notes: first attempt with `--functional-offload` refused (needs a real OpenGL display); plain headless used, no other change.

## Hourly
- 13:55Z: game change none; proof: fresh Meadows prefix opening_village→opening_team→camp_tournament→bridge on 13a8fdda6, each from the previous piece's save; result 4/4 PASS (replaces the VOID Fights bridge prefix). Next: training_t1_altar_1 (first native run of the Fights Altar helper).
- 14:03Z: STOP received from coordinator (owner, 17 Oct). training_t1_altar_1 (root p05_t1a1, from bridge) killed by PID at about 26 min, UNFINISHED, no result/receipt. Last log line: materials phase, `EARNED WALK START purpose=harvest rootstone final target=(399.0,-0.5,1792.0)` at frame 3721 from (-22.7,2.1,22.7) near home, with no later walk output for about 20 min (possible stall on the long walk to the rootstone site; not diagnosed). Criteria closed: 0. Local saves for all four passing pieces are retained under ~/routes/ in this container only.
