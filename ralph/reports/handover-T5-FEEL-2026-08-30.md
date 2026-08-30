# T5-FEEL handover — 2026-08-30

Lane: `ralph/T5-FEEL`, branched from `origin/main` at `1d7fc8e7`.

Two owner-playtest items, both from `ralph/OWNER_PLAYTEST_2026-08-30.md`, which
under `CLAUDE.md`'s precedence rules outranks every other document in this repo
for what it covers:

| Item | Owner's words | State |
|---|---|---|
| **OP-0830-3** | *"all items in the grass like tms, potions, orbs whatever should glow so they're visible."* | **Landed.** One shared treatment, six pickup paths, verified on rendered frames with grass confirmed present. |
| **OP-0830-5** | *"catching is way too hard."* | **Diagnosed and fixed.** Root cause was measured, not guessed; before/after success rates below. |

---

## OP-0830-5 — catching. The measurement first.

The lane order was explicit that this had to be diagnosed rather than tuned, so
nothing in `catching.json`'s odds was touched until there was a number.

### The instrument

`tools/_probe_catch_rate.gd` (new) drives the **real** loop — real input actions,
real aim camera, real orb, real `catch_math.resolve()` — at a representative
early-game encounter, and records where each throw actually died: refused,
physically missed, landed-and-lost, or caught. It re-acquires a fresh encounter
after each catch or faint (trimming the party back to the starter, since the
five-creature cap is a hard rule and would otherwise start refusing throws), so
the sample is many throws rather than many throws at one lucky creature.

It does **not** aim the way `tests/smoke_catching.gd` does. That test sets the
camera *rig's* yaw at the creature, and its own docstring records that this does
not put the reticle on the body — the aim profile carries a 1.45 m
`shoulder_offset`. Measuring through that would have measured the harness. The
probe closes the loop on the camera's actual forward instead, which converges the
screen-centre ray onto the body the way a player does with a thumbstick, and
`--jitter=<deg>` then adds a fixed angular error so the report brackets "a player
who lined it up" against "a player who nearly lined it up".

**Encounter:** `bramblebun`, the practice cluster's own species, `catch_rate`
**0.60** — the most catchable creature in the Meadows. That is deliberate: if the
easiest early catch is a chore, OP-0830-5 is not about rare species.

### BEFORE — measured on `main` at `1d7fc8e7`

| Tier | Real throws | Orb landed | Caught | **Catches per throw** |
|---|---|---|---|---|
| 50% health, aim converged on the body | 17 | 16 | 3 | **17.6%** |
| 50% health, 2.5° aim error | 16 | 14 | 4 | **25.0%** |
| Full health, 2.5° aim error | 18 | 17 | 2 | **11.1%** |

### What the numbers ruled out

Four of the five candidate causes the order named are **not** the problem, and
the data says so:

- **The orb's flight and collision are fine.** 47 of 51 real throws (92%)
  physically reached the body. Both recorded misses were sub-decimetre grazes
  (`closest=0.93 needed=0.93`), not wild throws.
- **The timing window is fine.** No attempt failed for the wind-up, the
  cooldown or the resolution.
- **The aim/throw feel is broadly fine.** The launch assist was eligible on 47
  of 51 throws (92%), and `predict_launch_point` committed and led the orb on
  every one of them.
- **The HP precondition is doing what it was designed to do.** Full health is
  brutal (11%) and `GAME_DESIGN.md` §15 asks for exactly that. Untouched.

### The actual cause

`catch_math.accuracy_bonus()` divided the strike's offset by **`body_radius`**,
and `orb.gd` clamped the reported offset at the same number before emitting it.
A Bramblebun's `body_radius` is **0.325 m**. Across the 47 landed throws:

| | |
|---|---|
| Median real placement | **0.375 m** — already off the end of the scale |
| Throws saturating the clamp | **36 / 47 = 77%** |
| Mean accuracy multiplier | **0.845** |
| `centre_bonus` the config advertises | **1.45** |

So the term `catching.json` itself calls *"the ONLY reason the aiming skill
exists"* was a near-constant, stuck within 6% of its worst possible value, on
throws that were assisted, on target, and aimed at the predicted body centre.
Every landed throw silently lost about 40% of the odds the HUD was showing it —
the reticle advertised 0.428 while the resolution rolled at 0.236.

The residual 0.375 m is **not player error**. It is the target moving during the
orb's flight; the launch prediction leads it but cannot cancel it. No amount of
aiming removes it, which is why the scale was unreachable rather than merely
demanding.

This is the same 1.81× discrepancy `tests/smoke_catching.gd`'s own comments
describe. A previous lane fixed *where* the offset is measured
(`closest_approach_ahead`, so a perfect trajectory reports 0 rather than a
graze). It did not fix *what it is measured against*, so in live play against a
moving creature the clamp went straight back to saturating.

### The fix

**Placement is now judged over the envelope that defines a hit** —
`body_radius + orb radius`, which is exactly the distance
`orb.gd::_check_target()` already tests against — rather than over the creature's
own collider.

Nothing moved at either end. A dead-centre throw is worth `centre_bonus` 1.45
exactly as before; a throw at the very edge of the collision sphere is worth
`edge_bonus` 0.80 exactly as before. `tests/test_catch_math.gd::test_the_ceiling_did_not_move`
pins both. What changed is that everything in between now grades, which is what
the term was written to do. **No species rate, HP factor, orb multiplier or
clamp bound was raised.**

Three smaller defects found in the same measurement and fixed with it:

1. **Your own creature blocked the assist.** `throw_aim.gd`'s eligibility
   raycast treated the player's creature as an occluder and reported
   `line_of_sight_blocked` — while `_release()` hands the orb an ignore list
   containing that same creature, so the orb flies straight through it. The ray
   and the orb now agree about what is solid. This does not widen the assist: a
   reticle genuinely off the body is still ineligible. It is a real geometry,
   not a corner case — combat is piloted, so your creature is *supposed* to be
   in the opponent's face, which is exactly where it occluded it.
2. **The HUD clamped its advertised offset at `body_radius` too**
   (`combat_manager.gd::catch_aim_offset`), so the reticle reported the worst
   possible placement for any aim more than 0.325 m off a small creature's
   centre. Clamped at the placement scale now, so the number the player reads
   and the number the throw resolves at are on the same ruler.
3. **`"so close — 0.0m wide"`.** A miss by less than the message could express
   printed a zero and read as a bug. It now says so in words.

### AFTER

<!-- AFTER-TABLE -->

---

## OP-0830-3 — nothing in the grass glows

### What was actually there

Five separate pickup props, each with its own idea of how to be noticed, which
is why the answer to "does it glow" depended on which object you were standing
in front of:

| Path | What it had |
|---|---|
| `key_pickup.gd` | four blind rounds of shape, scale, metallic and emission work — each round still judged "an anonymous yellow speck" at range |
| `tm_pickup.gd` | a plinth, a slow spin and an `OmniLight3D` |
| `item_cache_pickup.gd` | a different `OmniLight3D` |
| `harvest_node.gd` | nothing |
| `felled_resource.gd` | nothing |
| `death_satchel.gd` | nothing |

The key's four rounds are the tell. Every one of them tried to make an 18 cm
object legible in a meadow *using the object itself*, and every one was judged to
have failed.

### The treatment

One shared system, registered from all six paths:

- `scripts/world/pickup_glow.gd` — the field and the register/unregister API
- `shaders/pickup_glow.gdshader` — the draw
- `data/config/pickup_glow.json` — every number, with `enabled: false` as the
  whole revert
- `tests/test_pickup_glow.gd` — the regressions

Adding a seventh pickup path is one call: `PICKUP_GLOW.attach(self, colour)`.

### Height, not brightness — and why that is the load-bearing decision

The lane order named the trap: the ground lane is **raising grass density**, so a
treatment tuned against today's carpet stops working when theirs ships.

**Brightness cannot beat opaque geometry.** A grass blade in front of a glow
occludes it whatever its emission is, which is why four rounds of emission work
on the key did not fix the key. `grass_field.json`'s blades stand 0.40–0.62 m
with 0.38 height jitter — about **0.86 m** at the tallest. So the mote rides at
**1.15 m**, clear of the canopy, and the depth test is left **on**: this is still
occluded by terrain, trees and walls, exactly as a glow should be. It beats grass
by standing over it, not by cheating depth.

`tests/test_pickup_glow.gd` asserts that clearance **against
`grass_field.json`'s own numbers**, not against a constant copied out of them. If
the ground lane raises blade height or jitter, that test fails and names the
number to move. That is the coupling the order asked for, made mechanical.

A second, flat **ground aura** sits at the object's foot. The mote alone is not
enough precisely *because* it clears the grass — a mote high enough to be seen is
by definition not where the item is, so without the aura the player walks to a
floating light and then hunts at their feet.

For a tall prop (a felled log, a rootstone deposit) the mote is lifted to the
prop's own crown plus a clearance, capped at 2.2 m — a mote inside a two-metre
prop reads as a rendering bug, and one above head height reads as a waypoint.

### Restraint

It is not a loot beam, and the config is explicit about the three levers that
keep it that way:

- **Distance compensation.** A fixed-size world quad is a dinner plate at 2 m and
  a sub-pixel speck at 40 m, which is exactly backwards — the far case is the one
  the owner reported. The quad scales toward a constant *screen* size, clamped at
  both ends.
- **`near_floor` 0.32.** Inside a few metres the player can see the object, so
  the glow steps down to a third of itself rather than washing out the thing it
  was pointing at. It never goes to zero: an item at your feet in tall grass is
  still the case being solved.
- **`far_fade_end` 46 m.** A pickup glow readable across the whole meadow is a
  quest marker, not an affordance.

### Perf

**No per-pickup light.** The `OmniLight3D` that `tm_pickup.gd` and
`item_cache_pickup.gd` each carried is gone. The world holds well over a hundred
pickups (114 harvest nodes across the five bands, five TMs, the caches, the key,
plus every death satchel the player has left behind), OP-0830-6 is an open ROG
performance defect, and the order rules a light-each out by name.

Every pickup glow in the game is **two MultiMeshes and two draw calls**. The
vertex shader collapses an out-of-band instance to zero size, so a far or
already-taken pickup costs no fill either. Additive blending is
order-independent, which is what makes one MultiMesh for the whole world
possible at all. `tests/test_pickup_glow.gd::test_no_pickup_keeps_a_light_of_its_own`
stops the next pickup reaching for a light again.

I cannot claim a frame-time number for this. Nothing in this container measures
GPU cost, and `PERF-ROG-GPU` is already on record that no container here can. The
honest claim is the draw-call count and the absence of lights, not a frame rate.

### Evidence

<!-- SHOTS-TABLE -->

---

## For the `ralph/T5-OPENING` lane (OP-0830-2, the key)

The shared treatment exists and is pushed. `key_pickup.gd` already calls it, so
**the key glows on this branch with no work on your side** — take the merge and
delete any bespoke key-glow you were about to write.

If you need to tune it for the key specifically, `PICKUP_GLOW.attach()` takes a
colour, a height override and a scale multiplier; everything else is in
`data/config/pickup_glow.json`. Please do not add a light to the key: the
`OmniLight3D` ban is asserted by `tests/test_pickup_glow.gd` and the reasoning is
in this report's perf section.

I could not message that lane directly — no sibling session was reachable from
this one while it ran.

---

## Files

| File | Change |
|---|---|
| `scripts/world/pickup_glow.gd` | **new** — the shared highlight field, register/unregister, prop-clearance rule |
| `shaders/pickup_glow.gdshader` | **new** — billboard mote + flat aura, distance compensation, per-instance tint and phase |
| `data/config/pickup_glow.json` | **new** — every tunable, `enabled` false is the revert |
| `tests/test_pickup_glow.gd` | **new** — coverage, the grass-clearance rule, the no-lights rule, restraint |
| `tools/capture_pickup_glow.gd` | **new** — evidence frames through the *gameplay* camera, with a per-frame grass verdict |
| `tools/_probe_catch_rate.gd` | **new** — the OP-0830-5 measurement harness |
| `scripts/world/key_pickup.gd` | attaches/detaches the shared highlight |
| `scripts/world/tm_pickup.gd` | `OmniLight3D` → shared highlight |
| `scripts/world/item_cache_pickup.gd` | `OmniLight3D` → shared highlight; `_item_colour()` helper |
| `scripts/world/harvest_node.gd` | attaches on `_visual`, so the glow follows the respawn timer |
| `scripts/world/felled_resource.gd` | attaches/detaches; `_pile_colour()` helper |
| `scripts/world/death_satchel.gd` | attaches |
| `scripts/combat/catch_math.gd` | `accuracy_scale()`; `accuracy_bonus()` grades over the hit envelope |
| `scripts/combat/orb.gd` | strike offset clamped at the envelope, not at `body_radius` |
| `scripts/combat/combat_manager.gd` | `catch_aim_offset()` clamped at the same scale |
| `scripts/combat/throw_aim.gd` | LOS ray excludes the orb's own pass-through bodies; miss wording |
| `data/config/catching.json` | `chance.accuracy_span`, with the measurement written into its comment |
| `tests/test_catch_math.gd` | the placement-scale regressions; the old body-radius assertion re-anchored with its reasoning |

## What I did not do, and why

- **Did not touch the five-creature limit, add storage, or make trainer-owned
  creatures catchable.** All three are hard rules in `CLAUDE.md`.
- **Did not raise `hp_factor_full`, any species `catch_rate`, or any orb
  multiplier.** The measurement says the odds were not the defect; the accuracy
  term being a constant was. Raising rates on top of the real fix would
  double-count it and hide the next regression.
- **Did not touch the ground lane's terrain, grass or scatter configs, or their
  capture tools**, per the file-ownership split. The glow consumes their numbers
  (`grass_field.json`) and asserts against them; it does not edit them.
- **Did not edit `stronghold.gd`/`landmark.gd`, `species.json`, spawn tables,
  `objectives.json`, camp files, `performance.json`, or the opening/item-gate
  files.**
- **Did not claim a device frame-time.** See the perf note above.

## Next

1. **Owner play is the real verdict on both.** The glow's brightness, size and
   pulse are one config file; catching's feel after the fix is a number the owner
   should feel rather than read.
2. **Re-check the glow after the ground lane's density lands.** The regression
   test will fail loudly if their blades outgrow the mote, but the *visual*
   density question (does an aura read through a thicker carpet) wants a fresh
   frame.
3. **`combat_manager.gd::catch_aim_offset()` still returns 0 for an eligible
   assist**, i.e. it advertises a dead-centre placement the assist does not
   quite deliver. The residual is now small — see the AFTER table — but it is
   not zero, and it is the honest remaining gap between what the reticle
   promises and what the roll uses.
