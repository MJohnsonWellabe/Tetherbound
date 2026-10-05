# Home creature bed: two-peer case on CI (r1)

`tests/smoke_net_home_creature_bed.gd` (`# peers: 2`) at tb/f17 2fd37a71, render.yml headless run 37252637112
(job 111583235807). Exit 0, ALL CHECKS PASSED, 211 s. Real ENet over loopback.

- The host and a fresh guest are admitted as two separate characters, with actual host/client roles.
- Each peer puts its own creature to rest in the same world bed (index -40). Both are assigned, both rest, and both
  heal to 120/120 over `creature_bed.full_heal_seconds` (120 s).
- The host's resting creature does not block the guest's rest, and the guest's rest does not evict the host's creature.
- The guest's production leave saves its portable character. After a returning-character rejoin, the same character
  reads 120/120 and is still resting in bed -40.
- The peer logs have no script errors.

Disclosed fixtures (see `tests/helpers/hall_agreement_net_peer.gd::_home_bed_rest`): a starter is added to each fresh
character's empty party, its HP is set to 10%, and the 120 s heal is stepped through `_tick_creature_bed_recovery`.

Locally the host's heartbeat lapsed during the world build. The existing F17#5 smoke failed the same way locally on this
head, and F17#5 also passed on CI at 2fd37a71 (run 37252639171, exit 0).
