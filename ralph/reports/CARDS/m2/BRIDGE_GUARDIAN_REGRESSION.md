# South Bridge guardian regression (found by the M1/M2 card runs)

Harness: `tests/smoke_four_biome_continuous.gd -- --reload-at-transitions --through-bridge`
(and the M2 `--through-meadows` run), `TB_WORLD_SEED=15`, fresh new game, headless, main `e35e2611`.

| Run | `combat.json` `trainer_ally_lateral_m` | Tournament | South Bridge guardian (`south_bridge_grunt`, mudsnout L10 + burrowback L12) |
|---|---|---|---|
| main run 1 | 2.4 (main) | won, 3 rounds | FAIL: "did not yield the exact real team victories" (9000-frame bound) |
| main run 2 | 2.4 (main) | won, 3 rounds | FAIL: same |
| main run 3 (M2) | 2.4 (main) | won, 3 rounds | FAIL: "The earned party lost the actual bridge guardian fight" |
| diag A1 | 0.0 (local edit, not committed) | won | PASS: 2 wins, 39 hits, key spent, gate opened by ordinary play, crossed |
| diag A2 | 0.0 (local edit, not committed) | won | PASS: 2 wins, 37 hits, crossed |

The last fresh earned bridge passes (batch 13, seed 15 r41 at d9fce875) predate `3f04ece8`
("F04#2: trainer fights seat the ally beside the line and CHARGERs open outside their reach"),
which added `trainer_ally_lateral_m: 2.4` for every trainer fight. With it, the level-5/6 earned
five no longer beats the bridge gatekeeper within the harness bound, or loses outright; with it at 0 the
same fresh route passes 2/2. The bridge fight forms on the carved crossing approach (depth -11.5 m),
where a 2.4 m lateral seat may land the ally on the slope.

Owner: Meadows lane (F04#2, `tb/meadows`), which owns the change; contact spacing is `tb/combat-spacing`.
Not fixed here (cards lane does not edit fight/combat files). Blocks the M2 continuous run.
Logs: `main_e35e2611_m1_bridge_fail.txt` (two interleaved processes), `main_e35e2611_m2_bridge_fail.txt`,
`diag_lateral0_A1_bridge_pass.txt`, `diag_lateral0_A2_bridge_pass.txt`.
