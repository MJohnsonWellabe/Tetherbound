# F24#5 — co-op: each player's commands affect only their own creature and are host-validated

Lane: systems-a (`tb/ev-systems-a`). Commit under test: `228203a2` (origin/tb/ev-coordinator `00d4a639` + uid sidecars only).
Run: Sun 11 Oct 2026, 10:24–10:43 AM CT, Godot 4.7-stable headless, Linux.

## Proofs

1. Unit: `godot --headless --path . --audio-driver Dummy --script tests/run_tests.gd -- --only=test_f24_host_commands.gd,...`
   → batch `95 tests, 2566 assertions, 0 failed` (`unit-test_f24_host_commands.txt`). Relevant:
   - `test_rally_spends_once_affects_only_owner_and_splits_wind_at_expiry`: Rally affects only the commander's own creature; a command view forged with another character (`owner_b`) for participant 1 is refused by `host.commit_tether_command`.
   - `test_snare_canonical_status_has_one_shared_slow_and_own_catch_grant`, joint-attack forged `source_kind`, forged pouch/equip intents refused (host staging).
2. Two real ENet peers: `GODOT_BIN=godot tools/net/run_net_smoke.sh owner_passive_rejoin` (default path)
   → `ALL CHECKS PASSED`, 103 PASS lines, exit 0 (`net-checks.txt`, `net-SUMMARY.md`). Relevant checks:
   - guest's production Item command request goes through the host (pending while owner save refuses, no effect installed; retry of the same original accepted once, saved receipt on owner disk and in the host row);
   - `tonic: the guest command never buffs the other player's creature` (host's creature has 0 s of the guest's tonic);
   - rejoin never debits the Item twice nor resurrects an expired effect.

## Disclosed fixtures
The smoke's own: `party_grant` terrapup L8 per peer, `op_tonic_supply` two-item stock, proximity teleport into the host's fight. No generated save. Flags shipped on (`data/config/tether_commands.json` runtime/network/ui true).

## Not claimed
The `--prove-host-tether-commands` / snare / rally segments (host-as-commander) were not run here; the guest-commander default path plus the unit-level forged-actor refusal cover this criterion.

Verdict: PASS
