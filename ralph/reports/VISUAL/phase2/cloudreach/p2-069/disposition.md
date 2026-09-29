# P2-069 landing presentation after the owned-carrier change

**Deferred. Owner: shared Fly gameplay/Claude owner, with Cloudreach animation support.** No landing-animation acceptance is claimed.

The catalog's stills and this lane's original source audit predate main's owned-carrier Fly changes. In the audited earlier controller, floor contact called `_finish`, which freed the flight visual. That explained why a grounded still could lack a bird without establishing that a wing-fold clip was missing.

At main `cf0a3b974`, `fly_controller.gd::_finish` still frees the flight visual, but now conditionally calls the director's `summon_active_creature()` when `_recalled_follower` is true. Owned-carrier follower restoration must therefore be distinguished from the loaner teardown path. The prior missing-bird observation cannot be asserted unchanged on this newer source. Conversely, the source's summon call does not prove a continuous, readable touchdown/wing-fold/separation transition.

Next: record dense ordinary-input landing beats for both a deployed owned carrier and Maela's lawful loaner, including visible ground contact and the return to following/resting. Judge the transition before assigning animation work or changing shared lifecycle/camera/collision logic. Retain the original four-biome sightings as historical evidence; none becomes a current visual PASS merely because the owned-carrier functionality landed.
