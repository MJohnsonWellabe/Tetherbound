# Master chest: a guest's first press opens it (co-op follow-up to F28#4)

Branch tb/ev-coop-chapters @ 2f280eab4. Run Mon 12 Oct 12:35–12:51 AM CT, Godot 4.7-stable headless, two real ENet peers.
Command: `tools/net/run_net_smoke.sh f28_masters`, result ALL CHECKS PASSED, 89 PASS (`net-checks.txt`).

- The guest's first chest is now ONE real press (the chest prompt's `chest_requested`), with no harness re-press.
- The host refused it `owner_passive_original_pending` twice, then `source_or_revision_changed`.
- The game held the press ("Opening the chest...") and re-sent it, re-reading the personal view.
- New check `#4 the guest's first chest press opens its chest: its own feast recipe, once, with no second press` PASS.
- All earlier F28#4 checks (once only, through a second press, reconnect and reload) still pass.
- Disclosed: same smoke fixtures as F28-4 (party_grant seeds, teleports beside the Master, peer_runner strikes).
