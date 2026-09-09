# Realm migration despawn finding — PR94 review

2026-09-09. PR94 head `e5056c65f` is held for investigation despite successful
test assertions. CI run `34340315960`, job `102430304824` (network shard 5),
reported a distinct native error during `smoke_net_water_alpha.gd`:
`!pinfo.recv_nodes.has(net_id)` in `on_despawn_receive`, returning
`ERR_UNAUTHORIZED`, at 10:41:10.0265302 UTC. This followed Water shell readiness
and preceded the arriving client's trainer proxy construction. Existing missing
Meadows trainer/cache and invalid synchronizer errors surround it.

The exact class is absent from the reviewed preceding main `4830bf402` run's
complete 27 raw logs, as well as the inspected `8c0bfb31a` and PR94 `f823de9a5`
logs. It must not be folded into an unchanged-baseline claim. This does not yet
establish that PR94's death repair caused it; its corrected head changes only
the telemetry output environment and report relative to `f823de9a5`.

## Source hypothesis, not runtime attribution

`Game.enter_realm` announces the transition, then replaces the current scene.
`Session.announce_realm` sends a reliable request without a host acknowledgement.
The host subsequently reconciles trainer bodies; `trainer_spawn._despawn_for`
queues the old body for freeing, which sends Godot's replicated despawn.
The departing client can therefore destroy its old subtree before that message
arrives. Godot removes a locally deleted remote node from its receive map in
`_untrack`; a later despawn requires that same map entry.

Engine source inspected at the installed revision's
[scene replication implementation](https://raw.githubusercontent.com/godotengine/godot/5b4e0cb0f/modules/multiplayer/scene_replication_interface.cpp).
This ordering explains the observed error class, but the exact offending node
ID and packet ordering need a bounded native reproduction before production
changes. No engine errors have been suppressed, CI rerun, or exception added.

Next investigation must distinguish host-confirmed departure from destination
readiness and account for the different reliable channels. A mere arbitrary
delay is not an ordering proof. Preserve the old trainer path until its host
despawn has been consumed, and do not authorize early destination replication
into an absent scene. The existing asynchronous transition and rollback paths
must remain usable solo and during disconnect. No implementation is claimed.
