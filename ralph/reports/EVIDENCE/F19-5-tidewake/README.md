# F19#5 Tidewake checkpoints (tb/ev-tidewake-route)
Runner: tools/earned_saves/tidewake_piece_runner.gd (fresh process per piece, title Load, handoff
check of uids/flags/items/realm, unchanged helpers, Game.save_game(0)); chain: run_tidewake_chain.sh.
Start: tidewake_arrival_generated (generated, five L20). Checkpoints: tests/fixtures/earned_saves/tidewake_NN_*.
| Piece | Result | Input |
|---|---|---|
| 01 opening | PASS | generated arrival |
| 02 Reedhaven | PASS | earned (01) |
| 03 Brine | PASS, Tovin 183.2 s sim | earned (02) |
| 04 Shellwatch | PASS, Solm/Irva (Irva 181.2 s sim) | earned (03) |
| 05 Tidal | PASS, Aquaryn L26 | earned (04) |
| 06 swimmer+saddle | GAP (optional, RD-15: saddle at home Workbench) | catch+farewell PASS (uid receipt) |
| 07 human late | FAIL: route PASS to Veilfall; Venn wins at L20/L32/L33 (balance finding) | generated levels |
| 08 ending | PASS, Guardian, currents, Water relic | generated boundary from 05 |
Game fixes: duplicate/unbound Water harvest nodes after Load (cf9e6d84, 5d124b41); trainer arena
seats on slopes/beside trainer (51f85d43, a255ca25); wedged follower leash snap (b9975478).
Helper alignments (coordinator-approved / Rules v2): F32 renewable receipt; 600 s SIM fight budgets;
Aquaryn authored level (water_alpha.json 26); offer-decoded catch by uid.
Stale data: water_encounters.json Aquaryn reference level 49 vs authored 26.
Gaps: L20 team never levels past its cap on this route; Cloudreach handoff (Home Key, relic hang,
portal) not exercised; Venn difficulty vs an all-ground team (to F14#0).
Logs: <piece>.log here (git-ignored); receipts/PROVENANCE beside each save.
