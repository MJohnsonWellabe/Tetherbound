# F27 proof index (`tb/f27`)

Evidence for ACCEPTANCE §6.2 F27#0–#5 on the code at this branch head. Raw
outputs sit beside this file; commands are repeatable from the repo root with
Godot 4.7 (`$HOME/godot-bin/godot`).

| # | Verdict | Evidence |
|---|---|---|
| 0 | PASS | `test_f27_essence_rules.gd::test_eight_type_essences_and_tether_candy_are_stackable_items` (ItemDB: 8 `essence_*` at 999, `tether_candy` at 99; 900 essence fills one slot). `unit-batch.txt`. |
| 1 | OFF (two of six sources not live) | Rules pass at unit level (`test_f27_essence_rules.gd`: defeat, release, crops, care cap, no automation; existing `test_foundation_resources`, `test_research_log`, `test_den_groom_saved_transaction`). Production paths: **wild defeat** pays essence only when `combat.json actor_vitals.runtime_enabled` is true (`smoke-wild-defeat-off.txt` 0 essence; `smoke-wild-defeat-on.txt` 1 Ground Essence + one defeat receipt with the disclosed in-memory override). **Release** pays nothing on ordinary catches: the ceremony's legacy path (`tab_creatures._do_release`) and Tidewake `water_capture_claims.complete_pending_capture` never stage `essence.stage_release`; only the typed alpha capture offer does, and `alpha_respawns.json runtime_enabled` is false. **Attuned node**: `smoke-essence-node.txt`. |
| 2 | OFF on the production path | Formula: `test_progression`, `test_combat_round_reward`, `test_f27_essence_rules::test_automatic_combat_xp_is_reduced_but_never_zero`. Actual fight with shipped flags pays the legacy full award (L2 wild → 62 XP, `smoke-wild-defeat-off.txt`); with the vitals path on it pays exactly the hybrid 21 (`smoke-wild-defeat-on.txt`). Fixed on this branch: the canonical path used to pay both (83). |
| 3 | PASS (solo/host); guest blocked after reconnect | `smoke-altar-spend.txt`: paid Altar via the host build placer, walk, `interact`, controller `ui_*` navigation, Water Essence L3→L4, one receipt, accepted saved row. Rules: `test_f27_essence_rules` (starters through their own type, dual-type either essence or candy, cap → `breakthrough_needed`, stale level, duplicate spend id). Fixed on this branch: every solo spend was refused `stale_revision` (`test_f27_altar_first_send.gd`). Guest first spend in a session passes (`net-no-dup.txt` case A); a guest's spend after any rejoin never commits (owner-passive stream liveness, see report). |
| 4 | Spend: see `net-no-dup.txt`; release: OFF | `tests/smoke_net_f27_essence_no_dup.gd` (peers: 2). Release has no production two-peer path while release payout is unwired (#1). |
| 5 | PASS (arithmetic; caveats) | `../route-ledger/report.md` from `node tools/f27_route_ledger.mjs --write`; `node --test tests/test_f27_route_ledger.mjs` 7/7. Assumes hybrid auto-XP, which is OFF in production (#2). Break-even 39% of authored main-path wild sites engaged. |

## Commands

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_f27_essence_rules,test_f27_altar_first_send
godot --headless --path . --script tests/smoke_f27_wild_defeat_essence.gd [-- --actor-vitals-override]
godot --headless --path . --script tests/smoke_f27_altar_spend.gd
godot --headless --path . --script tests/smoke_f27_essence_node.gd
tools/net/run_net_smoke.sh f27_essence_no_dup
node --test tests/test_f27_route_ledger.mjs && node tools/f27_route_ledger.mjs --write
```
