# F17#5 Hall agreement as a peers:2 net smoke — R1

Code: `tests/smoke_net_crossing_hall_agreement.gd` (`# peers: 2`, auto-discovered by the CI
net-smoke shards) with peer helper `tests/helpers/hall_agreement_net_peer.gd`. Revived from the
R4 proposal archived in `../hall-agreement-finalizer-r1/inputs/`, with two changes:

1. Producer trees (village and Hall transforms, meshes, materials, signs, colliders, lights)
   are digested on each peer (SHA-256 of the full structural record) instead of shipping the
   44 MB record over the control channel. The R4 budget overrun from re-hashing resource paths
   is gone.
2. The host's saved world is read through the production `WorldSave.read()` (typed save
   document codec). R1's first attempt FAILED at `hall_reload_host` because the R4 helper
   parsed the file as raw JSON and the save format has changed since.

Command (base 826d273c3 + this branch):

    GODOT_BIN=~/godot-bin/godot tools/net/run_net_smoke.sh crossing_hall_agreement --out=/tmp/claude-0/net

Result: exit 0, 266 PASS, 0 FAIL, no SCRIPT ERROR / Parse Error / Invalid call in the peer logs
(`coordinator.log`, `SUMMARY.md`, `HALL_AGREEMENT.json`, `peer-*.log.gz`). Wall time ≈7 min locally
on 4 cores while a software-GL capture was running at the same time.

Covered: real ENet loopback join; host and guest agree on the village layout, Hall structure,
arch states/signs/membranes and shrine states; guest production leave + portable save; host
production autosave + title Load (scene and Hall rebuilt, same world id); guest returning-character
rejoin; the same agreement and identical producers after reload.

Limits: the lawful fresh default only (home open, three live arches locked, four sealed, eight
empty shrines). Mutable unlock and relic states are F18/F19. The unattended title identity
confirmations and the title Load continuation are disclosed. Not a controller, Steam, cold
process or visual proof.
