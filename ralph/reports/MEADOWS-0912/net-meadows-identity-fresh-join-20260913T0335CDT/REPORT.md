# Meadows multiplayer identity and fresh-join acceptance

**Verdict: PASS — OWNER-0912 Tier 4 #1–#5 and the Tier 0 remote-player visibility defect are closed by one isolated two-peer production run.**

## Run

- Revision reported by both peer hellos: `3fe86b752ae0`
- Godot: `4.7-stable (official)`, headless Windows coordinator plus two directly launched isolated peer processes
- Smoke: `tests/smoke_net_meadows_identity_fresh_join.gd`
- Run id: `meadows-identity-fresh-join-20260913T0335CDT`
- Result: `74` assertions, `ALL CHECKS PASSED`, coordinator exit `0`

## Accepted behavior

- Both production scenes contained exactly two trainer bodies. Each viewer saw the other player's live body and compact chosen-name badge.
- `Rowan`/`kael` and `Juniper`/`sera` survived the production title host/join path, both session registries, local `Player/Model` construction, replicated remote bodies, and `Label3D` nameplates.
- Each production full map rendered exactly one remote-player row: the other peer, never its own hidden proxy. Names matched and marker positions agreed with live bodies at `0.00 m` error.
- The fresh client entered the Meadows inside Grandpa's Village at `[-25.40, 4.95, -15.70]`.
- The moved-on world granted the fresh client exactly one starter, `terrapup@3`, and wrote the personal `opening:starter_granted` receipt.
- A second world delta re-armed catch-up without duplicating or replacing the starter (`["terrapup@3"] -> ["terrapup@3"]`).

`SUMMARY.md` and `NET_RUN.json` are the retained machine receipts. Per-peer logs and isolated `home-*` directories are intentionally not committed; they are local execution scratch rather than acceptance artifacts.
