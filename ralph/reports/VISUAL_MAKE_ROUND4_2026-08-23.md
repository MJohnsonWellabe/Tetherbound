# VIS-MAKE round 4 — two blind Fable critics

| domain | A (keyart) | B (Palworld) | vs previous |
|---|---|---|---|
| D8 combat | **no** | **no** | B fell from "yes" (round 3) |
| D5 structures + builds | **no** | **no** | unchanged from round 2 |

Both named many new defects, so the round improved by
`ralph/conventions.md`'s rule. **B falling is not noise and is not softened
here:** round 3 answered B "yes" on the strength of HUD grammar, and round 4
judged the same grammar against `palworld-01` and said no. A round that moves a
verdict backwards is the loop working.

## The root cause of nearly every combat finding, established

Round 4, blind, in five of six frames: *"A Bramblebun is embedded in the
Terrapup's face"*, *"The Terrapup stands inside the Elder Mosshell... the
climactic frame of the set is two meshes occupying the same volume."*

This is arithmetic, and it had been sitting in the config the whole time. A
creature's forward extent is its collider radius times its per-species
`footprint_allowance`, because `creature_body.gd` fits the art to exactly that:

    terrapup    0.76 x 2.40 (default; none authored) = 1.82 m
    bramblebun  0.60 x 2.20                          = 1.32 m
                                       nose to nose  = 3.14 m

The spacing floor gave `(0.76 + 0.60) x 1.8` = **2.45 m**. The two creatures
were authored **0.70 m inside each other**, every fight, by construction.

`body_clearance` is now 2.75 -> 3.74 m, with about 0.6 m of daylight. The
working is in the config comment so the next person does not guess: it had
already been raised once, 1.35 -> 1.8, against this same defect and by feel.

**This subsumes the projectile finding.** Three rounds reported "nothing is
firing". The bolt now renders (see below), but it was crossing a gap of roughly
zero because the target was inside the caster. A ranged move has never had a
visible distance to travel in any survey this sweep has run.

## What the projectile work actually achieved, stated honestly

Round 4's critic magnified the corridor and said plainly: *"no projectile, no
muzzle/cast flash, no trail, no dust... The move exists in the UI and nowhere in
the world."*

That verdict stands, and it is the one that matters. What is also true, and does
not rescue it: the bolt IS now rendering. It was drawn with both of the things
`impact_flash.gd` rules out by name (additive blend, vertex-colour alpha) and
rendered as literally nothing; on MIX it produces a measurable cream-coloured
cluster at the caster's muzzle, confirmed by differencing the firing frame
against the engagement frame from the same camera.

So: **the material bug was real and is fixed, and the frame still fails**,
because the bolt has nowhere to fly. Two separate defects wearing one symptom,
which is exactly why the first three rounds could not resolve it. The spacing
fix above is the half that was missing.

## A change of mine that did NOT work

`27-creature_bed` was repointed from a furniture-pack twin bed to the camp set's
own owner-referenced `camp_bed.glb`. Round 4's critic, blind:

> *"It reads unambiguously as furniture **for a person** — specifically a human
> camp bedroll or a child's cot... nothing about the shape, scale, or dressing
> says 'animal'. If anything, the set now contains two human beds in two
> different art styles."*

**Recorded as a lateral move, not an improvement.** It is defensible on other
grounds — the asset is in the game's own generated-camp family, owner-referenced,
and ships a correct `metallicFactor` where the old one needed the kit correction
— but it did not move the finding it was made for, and the critic is right that
the set now shows two human beds. The prediction in its own commit ("a camp bed
is still not a nest") was correct and insufficient.

Not reverted: reverting restores a bedroom suite with a blue quilt, which is
worse on every axis except the duplication. The real fix is an asset that does
not exist -- there is no nest, basket, cushion or straw-bed mesh anywhere in the
build, checked -- and belongs in `BLOCKED.md`, not in another path swap.

## The highest-leverage structures finding is this lane's own harness

> *"Every frame is a single asset on a featureless bright-green plane, under a
> flat gray-blue gradient sky, with a smeared black band where the horizon
> should be... It reads as a rendering bug in all 56 frames and dominates every
> thumbnail on the sheet."*

And: *"the survey stage itself: a grounded terrain material, a real sky, and
killing the black horizon band — **this alone changes all 56 frames**."*

That is `tools/_capture_structures.gd`, which this lane owns. It is the single
cheapest large improvement available to D5 and it is not an art problem.

Two smaller harness faults in the same set, both from the close-frame reframe
this lane made in round 2: `22-door-close` crops the 1.80 m ruler down to a
sliver of hand, and `11-castle-close` is a featureless plane from which nothing
can be judged. The reframe was a large net win — round 2's "a third of the
close-ups show nothing judgeable" is gone, and the critic says the closes are
"where most of this review came from" — but about a fifth of them still fail
their own brief.

## Findings that recurred unchanged, and are therefore not moving

- Three named landmarks are still the same two meshes (`10-inn` = `09`,
  `15-ranger_station` = `03`, `13-mill` has no mill).
- The castle is still untextured blockout.
- The ground is still empty; the meadow still reads as two hue families.
- The Bramblebun is still a photoreal rabbit among painted-toon creatures.
- Windows still glow at midday — and per this lane's round-3 note, that is
  R9.4's own fix for the opposite complaint and must not simply be turned down.

## Standing agreement across seven critics

The trainer is at bar. Round 4 combat: *"the player character is comfortably at
the Palworld bar"*. Round 4 structures: the same, unprompted. That is now nine
independent critics in this sweep saying it.

---

# The spacing fix DID NOT WORK. Measured, not inferred.

Written last, after the fix above had already been committed and described as
solving the interpenetration. It does not, and the number says so plainly.

The capture now prints the separation at every shot instead of leaving it to be
read off pixels — which is what four rounds of critique, and this lane twice,
had been doing:

    [spacing] 01-engagement:     centres 2.00m apart (combined body radii 1.36m)
    [spacing] 02-move-firing:    centres 1.36m apart (combined body radii 1.36m)
    [spacing] 03-hit-landing:    centres 1.36m apart (combined body radii 1.36m)
    [spacing] 04-catching:       centres 1.36m apart (combined body radii 1.36m)
    [spacing] 05-trainer-battle: centres 2.21m apart (combined body radii 1.36m)
    [spacing] 06-elite-encounter: centres 2.28m apart (combined body radii 1.75m)

`body_clearance: 2.75` should hold the pair at **3.74 m**. They sit at **1.36 m**
— which is not a coincidence and not a near miss: it is *exactly* `mine + theirs`,
the distance at which the two capsule colliders touch. The fighters are pressed
together until physics stops them, and `preferred_range` is not governing the
gap at all. Note it is below even the raw 2.1 m the config asks for before any
floor is applied, so this is not a case of my floor failing to apply — nothing
is holding them apart.

**So the config was never the lever.** The most likely mechanism, and it is a
hypothesis with an obvious next test rather than a finding: the ALLY is driven
into the opponent rather than the opponent closing on it. Every attack applies
`add_impulse(facing, lunge)` to the player's creature
(`combat_manager.gd::_resolve_player_strike`, `lunge` 3.6), and the capture fires
repeated quick attacks — so the ally lunges forward each strike and ends up
resting against the enemy's collider. That would explain why 01-engagement, shot
before any attack, is the one frame at 2.00 m, and why every frame after the
first attack sits at exactly collider contact.

If that is right, the fix is in the lunge/separation handling in
`scripts/combat/`, not in `data/config/combat.json`, and raising `body_clearance`
further will do nothing at all.

**`body_clearance` has now been raised twice against this defect — 1.35 -> 1.8 by
feel, and 1.8 -> 2.75 by me with arithmetic — and the measured gap did not move
either time.** That is the strongest available evidence that the whole approach
is aimed at the wrong system. A third raise would be the third guess.

The 2.75 value is left in place rather than reverted: the arithmetic behind it is
correct for what it claims to govern, it is documented, and the five fight smoke
tests pass with it. But it must not be recorded anywhere as having fixed the
interpenetration, because the measurement says it did not.
