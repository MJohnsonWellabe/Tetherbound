# Routes restart 17 Oct: work note

Cloud container, 4 CPU / 15 GB, Godot 4.7 headless (no rasterization; mechanics pieces only). Source: tb/routes from origin/main 13a8fdda6 (clean tree). Runner: `tools/earned_saves/earned_chain_runner.gd --training-profile=meadows_training_v1`, each piece in its own absent root under `~/routes/`, every piece after the first `--handoff-from=<previous piece dir>`. Receipts copied to `receipts/`; saves stay local.

| Piece | Root | Wall | Result |
|---|---|---|---|
| opening_village (fresh title) | p01b_village | 262 s | PASS, party Terrapup L3 + Bramblebun L2, 19 flags |
| opening_team | p02_team | 675 s | PASS, five owned, all L5, 12 flags |

Notes: first attempt with `--functional-offload` refused (needs a real OpenGL display); plain headless used, no other change.

## Hourly
