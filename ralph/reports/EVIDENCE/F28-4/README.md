# F28#4 — each co-op participant earns their own recipe; nobody receives it twice

Lane: systems-a (`tb/ev-systems-a`). Commit under test: `228203a2` (origin/tb/ev-coordinator `00d4a639` + uid sidecars only).
Run: Sun 11 Oct 2026, 10:43–10:54 AM CT, Godot 4.7-stable headless, Linux, two real ENet peers over loopback.

## Proof
`GODOT_BIN=godot tools/net/run_net_smoke.sh f28_masters` → `ALL CHECKS PASSED`, 88 PASS, 0 FAIL, exit 0 (`net-checks.txt`, `net-SUMMARY.md`).

Master `master_t1` (Orin Stonewake), host and guest each win their own 1v1 and open their own chest:
- host learns `feast_t1` exactly once; a second chest press changes nothing (feast, receipts, candy unchanged);
- guest ends with `feast_t1` exactly once (`F28#4 GAP: guest-owned chest delivered=true`), candy 0 → 2 once;
- guest after a second chest, after reconnect (leave + returning production_join), after save/reload, and after a chest replay post-reload: still one recipe, one candy payout, one win; the host's admitted view of the guest agrees at every point.

## Disclosed
- Smoke fixtures: `party_grant` seeds both homes before networking; trainers teleported beside the Master/chest; onboarding modals continued with confirm; strikes via peer_runner `win_trainer_battle`. No generated save.
- Known UX gap the smoke itself discloses: the guest's FIRST chest press is refused while its owner-passive checkpoints from the duel are still queued (no auto-retry); the guest's recipe landed on its second press (`#4 guest after its chest: feast []` then `#4 guest after a second chest: feast ["feast_t1"]`). The grant is still exactly once. Not a criterion failure, but worth a follow-up ticket (auto-retry the chest press after checkpoints settle).

Verdict: PASS
