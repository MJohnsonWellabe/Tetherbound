# D34. Combat Mode is a state, and the throw is never gated

Kind: implementation

ARCHITECTURE.md rule 5 and GAME_DESIGN.md section 7. Entering a fight changes
the input mode and the HUD and nothing else: no scene swap, no chunk unload, no
loading screen. `CombatMode` holds phase, charge and timers, and the world keeps
streaming underneath it.

`tryThrow()` has no wind-up, no cooldown and no health gate, so it resolves on
the opening tick of a fight. That is CLAUDE.md hard constraint 3 and it is
enforced by there being nothing to remove rather than by a check.

A collared pal returns a catch chance of exactly 0 rather than a very small
number. It is a rule, not a bad roll, and the HUD needs to tell the difference
so it can bounce the orb instead of shaking it.

A failed throw still spends the orb and hands the enemy a free attack window,
because a free throw would make throwing strictly better than fighting and the
five-slot decision only bites if orbs are scarce.

One bug worth recording: `Encounter` called `settle()` after `maybeStart()` in
the same tick, so a fight was torn down on the step it began and combat could
never last longer than one frame. The unit tests all passed; a browser run
caught it. `settle()` now runs first and only acts on terminal phases.
