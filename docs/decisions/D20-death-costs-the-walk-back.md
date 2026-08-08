# D20 — Death costs the walk back, and food is only ever a bonus

**Status:** accepted
**Decided by:** implementation, during M9 (the survival loop)
**Builds on:** `D14-one-save-envelope.md`, `D17-items-and-stations.md`

Five decisions M9 had to make, each of which will look arbitrary later and each
of which is load-bearing.

## 1. Food is a buff and there is nothing on the other side of zero

`GAME_DESIGN.md` §18 asks for "Valheim-like buff philosophy: no starvation
death". `CLAUDE.md` says it twice — "Food buffs; no starvation-death meter" —
and lists *adding mandatory hunger/thirst* among the decisions an agent may not
take on its own.

So eating raises two ceilings and the stamina regeneration for a while, and NOT
eating costs exactly nothing. There is no meter, no decay, no state below "has
eaten nothing", and no field anywhere called hunger, satiation or nourishment.

The way this rule dies is not a decision to add hunger. It is one number in a
config nobody reviewed — `hunger_per_second` — so there are two tests watching
it: one runs an hour of game time on an untouched trainer and asserts nothing
moved, and one greps the shipping config for the vocabulary.

Two smaller shapes inside the same decision:

- **Eating again refreshes, it does not stack.** Otherwise a full stack of
  thirty berries is a ceiling with no top.
- **A meal ending cannot kill you.** Health clamps down to the new maximum and
  never below 1. Dying to a berry timer is a death nobody could explain, and §18
  gives food no downside at all.

## 2. The satchel takes everything, and the cost of dying is the walk

`GAME_DESIGN.md` §22 allows exemptions ("exact item exemptions can be tuned").
The shipping list is **empty**: everything carried drops.

The satchel is permanent, it does not move, several coexist, and every one of
them is on the map — so what dying costs is the journey back, not the loss. An
exemption list makes that journey optional, and a journey you can skip is not a
consequence. The hook exists in `data/config/survival.json` and a test proves it
works, so turning it on later is a data edit.

Worn equipment is not an exemption. §22 drops what is *carried*; armour is on
the trainer. There is no armour yet, which is exactly when that distinction is
cheapest to get right.

## 3. You wake up at your bed, or where your journey started

§22 says pals go home and does not say where the player goes. §20 does: the base
is for "safety, recovery, respawn and rest". So the respawn is a placed
`bed_simple` whose station answers `is_respawn_point()` — `home.respawn_point()`
has existed since M6 waiting for a caller.

A player who has not built one yet wakes **where they started**. The other two
options are worse: waking where you died puts you back in the jaws of whatever
killed you, and inventing a respawn shrine is a building nobody designed. It
also gives the tutorial's first bed something to be *for* on the day it is
built.

## 4. Free repair happens at home, because there is no workbench

§19 promises tools "repair for free at appropriate station". `pieces.json` has
no workbench — `station.gd` lists it as waiting on crafting recipes, and
stubbing an empty one in to be a repair point is the pattern that file refuses.

So the station is the base: repair is refused unless the trainer is at home, and
refused with "build a bed" when there is no home at all. Repairing anywhere
makes durability a button rather than a reason to go home, which is the opposite
of what M9 asked durability to be. When the workbench exists it takes this over
and the rule moves; nothing else changes.

## 5. The trainer's inventory is a node in the world, and there is only one

`scripts/items/inventory.gd` shipped complete, tested and **owned by nothing** —
the same shape the save system was in before `save_director.gd`, and with the
same consequence: a finished system the player never meets. `TrainerInventory`
is the owner. Gathering adds to it, build costs spend from it, the satchel
empties it, and `recovery.gd` — which had grown a private bag of its own for the
revival draughts, with a comment asking to be relieved of it — now spends from
it through `inventory_path`.

One bag, therefore. Two would be two places the player's things can be, and the
first symptom is a death satchel that does not contain something you were
definitely carrying.

### The bug that fell out of it, recorded because it will happen again

Moving a stack between two containers with `place()` and then `remove_at()` on
the source **empties the very stack you just handed over** — they are the same
object. It cost a satchel that dropped three stacks and held nothing, and a
storage crate that swallowed an axe, in two different milestones in the same
week. `satchel.take_stack()` is the one way to lift a stack out: it copies
through the item's own save record, which is the path already required to carry
durability, and then clears the slot.

## 6. A restored body does not simulate until there is ground under it

Persisting the trainer's position turned out to be a physics decision, not a
save one. `SaveDirector` restores a frame after the scene is built, while
`playground_world` is still awaiting Terrain3D's data — so the restored position
has no collision under it yet, and when the collision arrives the body is inside
it. Measured: ejected at 456 m/s, two kilometres away and still accelerating.

`player_controller` now holds the body still — no gravity, no input, no
`move_and_slide` — until the heightfield can answer for the spot it was restored
to, and then puts it down two metres above the ground, the same clearance a new
spawn uses and for the same reason (the collision mesh and the heightfield
disagree by up to half a metre on a slope).
