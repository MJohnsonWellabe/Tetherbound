# D08 — Catching costs you your pal

**Status:** accepted
**Decided by:** owner, during M3
**Builds on:** `D07-combat-is-piloted-not-commanded.md`

## The decision

Pressing Throw hands camera and control from the pal back to the **trainer**,
for a real-time over-the-shoulder aim. Release throws a physical orb on an arc.
Cancel costs nothing.

While you are aiming, **your pal stops taking stick input and the opponent does
not stop attacking it.**

## Why the trainer aims

Combat is piloted (D07), so at the moment you decide to throw you are driving
the creature, not the person. Three ways to resolve that were considered:

1. Snap control to the trainer to aim. **Chosen.**
2. Throw from the pal's position with no control swap.
3. Auto-throw with no aiming.

Three is forbidden outright — `GAME_DESIGN.md` §15: *"Do not automatically
throw/roll without player aim."*

Two is simplest and was rejected because it muddles who is catching. Catching is
the trainer's job; it is the one thing in a fight the trainer does. D07 turned
them into a spectator, and this is what makes them a participant again without
breaking the rule that they never attack.

## Why it costs you

The pal being abandoned mid-fight is not a side effect of the control swap — it
is the reason the control swap is worth having.

Without a cost, throwing is free, and the correct play becomes throwing
constantly between attacks. That is not a decision, it is an extra button. With
the cost, every throw is a question: *is the opponent hurt enough that this is
worth a few seconds of my pal being hit?* That question is the mechanic.

It also gives the damage curve teeth in both directions. Chipping a pal down
raises the odds (`hp_factor`), but over-damaging it ends the chance entirely
(§15), and the seconds you spend aiming are seconds your pal might land the blow
that kills the thing you were trying to keep.

The trainer themself still cannot be hit. §14's trainer safety rule is unchanged;
the risk is entirely to the pal.

## Aiming in real time

No slow-motion. It was offered and declined.

Slowing time while aiming makes the throw nearly free again, and everything
above stops being true. If aiming turns out to be too hard on the handheld, the
levers in order are:

1. `throw.radius` — widen the orb's collision. Forgives the input without
   removing the skill.
2. Slow the target during the aim window.
3. Slow time — the option declined here, kept as the last resort.

A lock-on is explicitly **not** on that list. It would delete the skill the
milestone exists to create.

## The rules the implementation must keep

**The reticle is a promise.** The aim camera sits about a metre and a half off to
one side so the trainer's body does not cover the crosshair. An orb thrown
*parallel to the camera* from the trainer's hand travels a line offset by exactly
that much, and lands a body's width to the side of everything you aimed at —
consistently, which reads as the game ignoring your input. So the throw is aimed
at the point under the reticle, not along the camera's forward.

**The outcome is decided once.** `catch_math.resolve()` rolls, and the wobble is
derived from the decision already made. A shake sequence that can contradict a
result the game has computed is a lie, and dramatising a lie is what makes catch
animations feel cheap. The wobble count carries honest information instead: a
near miss shakes longer than a hopeless throw.

**A faint is a refusal, not long odds.** §15 says over-damaging a pal ends the
capture opportunity. The game says so before the orb is spent, and the fainted
creature stays visible on the ground for a few seconds afterwards — the body is
the feedback for the mistake, and a creature that vanishes on fainting never
shows you the chance you destroyed.

## Not in this milestone

The party and the five-slot rule (M4). Orb tiers beyond the basic one (M8's
crafting). An inventory — the orb stock is a milestone-local placeholder that
refills with the practice pal, and `CLAUDE.md`'s ban on storage beyond five pals
applies to M4's party, not to this.

Caught creatures are appended to a list on `EncounterDirector`. That list is the
seam M4 attaches to, in the same way `CombatManager._active_index` is the seam
for switching.
