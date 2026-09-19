# D48 — Riding is a world verb, and it costs no stamina

**Date:** 2026-08-16
**Items:** `R6.1` (riding), `R6.2` (Meadowhart + the craftable saddle)
**Status:** built

---

## 1. Riding is the interact button, not a mode

You walk up to your own creature, the one prompt line says **"Ride Meadowhart"**,
and you press the button you already press for Grandpa, for a berry bush and for
the bed. Pressing it again says **"Dismount"**. There is no new binding, no held
modifier, and no menu.

This is `D35`'s Palworld control parity read literally, and it is the only shape
that survives CLAUDE.md's controller-first rule without spending a face button
the Ally does not have spare. `OF21`'s rebind plumbing was checked and
deliberately **not** used: adding a binding is the expensive option and nothing
here needed it.

Mechanically that means `scripts/world/riding_controller.gd` is an ordinary
interaction provider registered with `scripts/world/interaction_arbiter.gd`,
exactly like every `interactable.gd` in the world. Riding therefore competes for
the one prompt line by the same distance/priority rule as everything else, and
the modal lockout `sequence_director.gd::_refresh_lockout()` already computes —
fight, trainer battle, conversation, naming prompt, starter picker, fade, armed
build ghost — is the *same* flag that ends a ride. A new modal added there ends
a ride for free, instead of being a case somebody has to remember to list twice.

## 2. What drives what while mounted

```
stick   -> riding_controller -> creature_body.request_move()   the CREATURE walks
camera  -> camera_rig.set_target(mount, riding profile)        the rig follows it
trainer -> player_controller.set_carrier(mount, offset)        the trainer is cargo
```

There is **no second movement implementation**. The mount walks with the same
acceleration, turn rate, slope handling and animation blending it uses while
following you or fighting, because it is the same code path — the riding
controller only chooses a direction and a speed, exactly as
`follower_creature.gd` and `combat_ai.gd` do.

`player_controller.gd` gained `set_carrier(node, offset)` and nothing more. It
still does not know what a creature is: it knows a body can be *carried*, which
is the same statement a lift or a cart would need. While carried it runs no
gravity, no friction, no jump and no `move_and_slide` — two things writing one
transform in one frame is one of them silently losing, the rule
`encounter_director._set_exploration_active()` already states for the ally body.

Which creature is a mount is **data**: `data/creatures/species.json`'s per-species
`rideable` block (mount offset, ride-speed multiplier, `can_carry`,
`requires_item`, dismount distance). `R8.5`'s legendary mount is a second block,
not a second branch.

## 3. Riding costs no stamina, and the mount has no stamina bar

The simpler honest option, chosen deliberately over both alternatives:

- The trainer is **sitting down**. Draining their meter would be modelling
  exertion nobody is doing.
- A stamina meter on the mount is a whole HUD element and a whole tuning problem
  for a system whose stated value (spec §3) is *"revisiting known areas is less
  of a chore"* — a meter that ends the ride attacks the only thing riding is
  being sold on.
- The creature's endurance is already spoken for by combat energy, which is a
  different resource with a different meaning, and reusing it would couple
  exploring to fighting for no gain.

So the player's stamina simply **regenerates** while mounted (`vitals.tick` still
runs, with sprinting false — the same thing standing still does). Satiety still
drains: riding is not a pause button on the day (`D29`).

If riding later needs a cost, the honest place to put it is a **cooldown or a
distance budget on the mount**, not a meter that drains while you hold forward.
That is a new decision, not a tuning tweak.

## 4. The saddle

One **generic** saddle for every mount — the brief's "no species-specific saddle
clutter". Which creature it fits is the creature's business
(`rideable.requires_item`), so a second mount either wants this same saddle or
names its own tack in its own block.

`saddle` (item, `kind: gear`, stack 1) is crafted from `SD18`'s `saddle_frame`
plus Rootstone, wood and fiber. It is never consumed and has no durability —
riding only ever *asks* whether one is in the satchel. It carries no
`unlocked_by` flag, for `recipes_rootstone.json`'s own stated reason: the real
gate is Rootstone, which is quarry-locked, and a flag would gate the same door
twice. What teaches the player it exists is the world — standing next to a
rideable creature without one draws **"Meadowhart needs a Riding Saddle."**
through the ordinary prompt.

**Ironwood (`SF31`) does not exist yet.** Spec §3 Band 4 prices riding equipment
in Rootstone *and* Ironwood, and a recipe costing an item `item_db` cannot
resolve is a recipe the craft screen cannot draw. So the saddle ships at the
Rootstone price with the seam written into the recipe's own comment: when SF31
lands, add one `ironwood` line to `cost` and drop the `wood` count to keep the
total investment where it is. Nothing in code reads the cost, so that is the
whole change.

## 5. The bug this cost us, recorded because it will happen again

**In GDScript a freed Object reference compares EQUAL to `null`.** Both
"the mount was despawned out from under the rider" guards were written as
`if _mount != null`, and both were dead code from the first frame: dismissing
your creature while riding it left the trainer invisible, on no collision layer,
falling through the world forever. `is_instance_valid()` is the only honest test
of *"is it still there"*, and a separate boolean is the only honest test of
*"were we on it"* — `riding_controller._riding_now` and
`player_controller._carried` are that, and both carry the reason in a comment.

Found by `tests/smoke_riding.gd`'s despawn case. Every unit test passed
throughout.
