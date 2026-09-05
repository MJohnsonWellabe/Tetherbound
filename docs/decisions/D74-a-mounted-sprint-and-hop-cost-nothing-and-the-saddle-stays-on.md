# D74 — A mounted sprint and hop cost nothing, and a fitted saddle stays on

**Date:** 2026-09-04
**Items:** `OP-0904-3` / `CL-O3` (riding is unfinished three ways), lane `W14-RIDING`
**Supersedes nothing.** Extends `D48` (riding is a world verb and costs no stamina).
**Status:** built

---

## Why this exists

The owner played the shipped build and reported three things about riding:

> When you ride your person didn't show up on the creature.
> You can't sprint or jump when riding.
> Nothing that is rideable should come with a saddle on it. You have to build
> the saddle and put it on then it visually appears. It shouldn't visually be
> there.

The first is a straight defect and needed no decision. The other two each
forced one small choice that nothing in the repo settled, and this file is
those two choices rather than a re-argument of riding.

## 1. A mounted sprint costs nothing — not the player, and not the creature

`D48` §3 already ruled that riding costs the **player** no stamina and that the
mount has **no stamina meter of its own**. It did not consider a mounted sprint,
because there was not one. The question this lane had to answer is whether the
new sprint spends the creature's own endurance.

**It does not.** The three reasons `D48` gave are unchanged by the button being
held down:

- the trainer is still sitting down, so a drain on their meter still models
  exertion nobody is doing;
- a stamina meter on the mount is still a whole HUD element and a whole tuning
  problem, for a system whose stated value (spec §3) is *"revisiting known areas
  is less of a chore"* — and a meter that ends the sprint attacks exactly that;
- the creature's endurance is still spoken for by **combat energy**, a different
  resource with a different meaning, and spending it on travel would couple
  exploring to fighting for no gain. Worse than in `D48`'s case: a player who
  sprinted to a fight would arrive with a charged move missing.

`data/config/riding.json` carries `sprint.creature_stamina_cost: 0.0` so the
ruling is visible where the tuning is, and reads as a decision rather than as a
knob nobody wired.

`D48`'s own escape hatch still stands and is still the right one if riding ever
needs a cost: a **cooldown or a distance budget on the mount**, not a meter that
drains while you hold forward. That would be a new decision.

**The speed the sprint buys** is `1.4 ×` the species' own ride speed — one
multiplier on the existing per-species number rather than a second speed table,
so retuning a mount still moves one number. For Meadowhart that is 10 → 14 m/s
against a **sprinting** trainer's 8.6. The bar is deliberately the trainer's
sprint and not their walk, for the reason `species.json`'s own
`_comment_rideable` gives about `ride_speed_multiplier`: riding has to beat
running, or the spec's promise is a lie.

**The hop** clears 1.6 m, against the trainer's own 1.35 m jump. A mount that
jumped lower than the person riding it would read as a downgrade, which is the
opposite of what the unlock is for. It is asked for in **metres of clearance**
and converted against the creature's own gravity, so retuning creature gravity
cannot silently change how high anything hops.

## 2. A fitted saddle is fitted per species, and it stays on

The owner's sentence has three clauses and the middle one is the decision:
*build* the saddle, *put it on*, and then *it visually appears*.

**Where "fitted" is remembered.** In `autoload/progression_state.gd`'s flag
store, as `saddle_fitted_<species_id>`, which is saved and loaded with the game.
The alternative — a field on `creature_instance.gd` — is the more precise model
and costs a serialised field, a save key and a migration for one boolean, in a
file this lane does not own. The flag is the honest smaller step.

**The consequence, stated rather than discovered:** the fit is **per species**,
not per creature. Two Meadowhearts in a five-creature roster both wear the
saddle the species was fitted for. That is a simplification and it is the right
way round: the alternative reads as a bug the first time a player swaps mounts
and finds bare leather on an animal they already tacked up. If a later lane adds
a per-instance field, this flag is what it should migrate from.

**"Put it on" is mounting.** There is no separate fit prompt, because `D48` §1
spends no new binding and the Ally has no spare face button. You walk up with a
saddle in the satchel, press the button that already says *"Ride Meadowhart"*,
and the saddle is on from that moment — not just for the length of that ride.
The previous implementation attached the mesh in `mount()` and tore it off in
`dismount()`, which satisfied *"never at spawn"* and failed *"then it visually
appears"*: the visible proof of the craft was invisible in every moment the
player would actually look at their creature.

**The legendary is exempt and stays exempt.** Its `requires_item` is empty —
`species.json`'s own comment: *"it carries you because it offered to"* — so the
saddle mesh is gated on the species' own required item and never on "is it
rideable". Strapping the crafting bench's leather to it would say the wrong
thing about what just happened in that chamber.

## 3. What this does not decide

**Which species are rideable.** `CL-O9`/`CL-W3` own the roster (Burrowback,
Tuskroot and Terrapup, plus fly and teleport well after the Meadows) and it
needs a design contract first. Everything here is written against whatever
species carry a `rideable` block, and both tests read that list from the data
rather than naming animals, so the roster lane changes one file and these rules
follow it.

**A seated animation clip.** The rider's pose is authored on the skeleton
(`trainer_model.gd::set_riding()`) because the trainer rig has no sit clip and
`CLAUDE.md` forbids spending a Meshy generation without owner-supplied
reference art. If a clip is ever baked, `RIDE_POSE` is the thing it replaces
and nothing else changes.
