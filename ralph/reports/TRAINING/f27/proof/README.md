# F27 proof index (`tb/f27`)

Evidence for ACCEPTANCE §6.2 F27#0–#5 at this branch head, which includes origin/main with #531.

Raw outputs sit beside this file. Commands repeat from the repo root with Godot 4.7 (`$HOME/godot-bin/godot`).

Net smokes need the harness environment. `tools/net/run_net_smoke.sh` does not forward `--case=`, so run the coordinator directly:

```
TB_NET_RUN_ID=x TB_NET_OUT_DIR=dir godot --headless --path . --script tests/smoke_net_f27_essence_no_dup.gd -- --case=release
```

| # | Verdict | Evidence |
|---|---|---|
| 0 | PASS | `test_f27_essence_rules.gd::test_eight_type_essences_and_tether_candy_are_stackable_items`: 8 `essence_*` items stack to 999 and `tether_candy` to 99. In `unit-batch.txt`. |
| 1 | PARTIAL: wild defeat OFF in shipped config; release PASS for solo/host and guest (host-admitted creatures) | See the #1 detail below. |
| 2 | OFF on the shipped path; PASS with the flag | `smoke-wild-defeat-on.txt`: exactly the hybrid 21 XP and one battle per win (fixed on this branch: canonical wins credited `battles_fought` twice). `smoke-wild-defeat-off.txt`: shipped flags pay the legacy 62. Formula covered by `test_progression`, `test_combat_round_reward` and `test_f27_essence_rules`. |
| 3 | PASS (solo/host and guest) | `smoke-altar-spend.txt`: controller-path paid Altar, L3→L4, one receipt. The guest spend is case A of `net-no-dup-all-post531.txt`; a guest spend after an ordinary reconnect settles once (`net-reconnect-spend-post531.txt`, 32/32). |
| 4 | PASS for Altar spend (A, B, C), and for release through reconnect | `net-no-dup-all-post531.txt`: A settled, B host cut before delivery and C owner cut before ACK each recover exactly once through hard reload, with the host matching the guest. Release reconnect and reload: `net-guest-release-post531.txt` (52/52). In the all-cases run the release reload timed out on `character_in_use` before the rejoin budget was raised. |
| 5 | PASS (arithmetic; caveats) | `../route-ledger/report.md`; `node --test tests/test_f27_route_ledger.mjs` 7/7. It assumes hybrid auto-XP, which is OFF in production (#2). |

**#1 detail:**
- **Wild defeat** pays essence only when `combat.json actor_vitals.runtime_enabled` is true:
  - `smoke-wild-defeat-on.txt` shows 1 Ground Essence and one defeat receipt;
  - shipped flags pay 0;
  - guest wild wins are not done (`../guest-wild-win/README.md`).
- **Release**, solo/host:
  - `smoke-release.txt`: the ordinary catch-overflow ceremony through `essence_release`;
  - `smoke-water-capture-release.txt`: Tidewake claims.
- **Release**, guest: `net-guest-release.txt` (52 assertions) shows exact payout once and an accepted host row. An unadmitted creature is released unpaid, with a reason.
- **Rules:** `test_f27_essence_rules.gd` (crops, care cap, no automation) and `test_f32_win_shed.gd`.
- **Attuned node:** `smoke-essence-node.txt`, controller gather of `essence_meadows_ground_01` paying 3 Ground Essence and 1 attuned item with an accepted journal and receipt.

## Commands

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_f27_essence_rules,test_f27_altar_first_send,test_f32_win_shed
godot --headless --path . --script tests/smoke_f27_wild_defeat_essence.gd [-- --actor-vitals-override]
godot --headless --path . --script tests/smoke_f27_altar_spend.gd
godot --headless --path . --script tests/smoke_release.gd
godot --headless --path . --script tests/smoke_water_capture_recovery.gd
tools/net/run_net_smoke.sh f27_essence_no_dup   # MANUAL; cases settled, host_before_delivery, owner_before_ack, release
node --test tests/test_f27_route_ledger.mjs && node tools/f27_route_ledger.mjs --write
```
