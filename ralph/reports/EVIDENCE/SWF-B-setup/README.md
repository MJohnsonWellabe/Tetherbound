# smoke_net_shared_wild_fight: deterministic B setup (coordinator backlog), Systems lane

Tue 13 Oct 2026 (CT), tb/ev-systems. CI red intermittently on main (nightly 38211185984) and on #682
(run 38371856742 shard 14): "host started a second ordinary wild fight B (could not stand where
body X was the one on offer (offered Y))". A wandering ambient wild sat nearer every stand spot.

## Changes (harness only, no assertion changed)
- 1de5680b, tools/net/peer_runner.gd `engage_wild` gains an opt-in `accept_offered`. It first stands
  on the remaining sides of the intended body; if that body still isn't on offer, it engages the live
  wild the director actually offers, provided it is not the excluded body (A). That is what a player
  standing there would fight. Exact retained-Alpha and shipping-capture bindings never substitute.
  smoke_net_shared_wild_fight passes it for B only.
- 2ecb0b07, the smoke's read of A after the host's flee now waits (bounded at 120 polls) for the
  host's leave. A disengage that lands while A's saved vitals are pending is held by design
  (encounter_director._deferred_disengages) and applied when the save lands. The single
  first-frame read saw the host still listed in 1 of 3 local runs.

## Proof (local)
- With both changes: 3/3 PASS. Each run: "A remains active for the guest after host flee" PASS and
  "host started a second ordinary wild fight B (engaged bramblebun as encounter 1:2)" PASS.
- With only 1de5680b: B setup 3/3; the earlier A-after-flee read failed once (the cause of 2ecb0b07).
