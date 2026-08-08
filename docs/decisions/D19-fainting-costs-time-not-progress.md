# D19 — Fainting costs time, not progress

**Status:** accepted
**Decided by:** implementation, during M6 (fainting and home recovery)
**Builds on:** `D13-the-five-pal-cap-is-code.md`, `D17-items-and-stations.md`

`GAME_DESIGN.md` §16 is four lines long. It says a pal at 0 HP passes out, is
unavailable, and **does not auto-revive with time in the field**; it comes back
from a special revival item or from recovery in its physical pal bed at home;
and beds also speed normal HP recovery and feed bond.

Everything below is a question §16 does not answer, answered.

## 1. The blanket post-fight heal was the whole problem

`encounter_director._on_combat_exited()` ended by restoring every pal in the
party, under a comment calling itself a placeholder for this milestone. The cost
was larger than "fainting is temporary": **nothing in the game could put a pal
into the state `fainted` describes**, so four separate guards that test for it —
the party menu's refusal, `Switchboard`'s skip, `_engageable()`, the combat
manager's deploy check — were unreachable code that had never once run against a
real downed pal.

Deleting three lines is what makes §16 exist. Everything else in M6 is what makes
deleting them survivable rather than cruel.

`tests/test_recovery.gd` guards it at the source level as well as behaviourally,
because it is a two-line regression that would pass every other test in the
project.

## 2. A fainted pal keeps its level and its XP

**Unstated in the design documents, and decided here.**

§16 enumerates what a faint costs: consciousness, availability, and either an
item or a stay in a bed. Progression is not on that list. §22 settles the same
question for the *player* — "no XP loss, no level loss" — and there is no reason
the creature being carried should be treated more harshly than the person
carrying it.

The five-pal cap is the argument that closes it. With no box and no sixth slot, a
progression penalty compounds on a party that cannot be replaced: the pal you can
least afford to lose ground on is the one that faints, because it is the one you
deploy. The cost of a faint is time and a finite item, which is exactly the cost
§16 names.

## 3. Recovery is not instant, and the number is data

A bed that revives on contact is the deleted heal with extra steps. So a fainted
pal must lie in a pal bed for `bed_revive_seconds`, comes round on
`bed_revive_hp_fraction` of its health, and then heals at `bed_hp_per_second`
until it gets up on its own. All three are tunables in `data/config/party.json`,
because "recovering takes too long" and "fainting costs nothing" are the two
things the owner is most likely to say and both must be answerable without
touching code.

**No field recovery number was invented.** §16's "beds speed normal HP recovery"
implies some baseline recovery away from a bed. There has never been one in this
build, §16 puts no number on it, and adding one would be inventing a healing
system out of a subordinate clause. A pal's health moves in a fight, at a bed, or
from an item, and nowhere else.

**No bond number was invented either.** §16 and §12 both say resting feeds bond.
Bond does not exist. `recovery.rest_finished(pal, seconds, reason)` carries how
long the pal slept and nothing reads it; that signal is the seam, and it needs no
change on this side when bond lands.

## 4. Home is the trainer's bed, and the last one placed wins

§16 does not say "a pal recovers in a pal bed". It says "in its physical pal bed
**at home**". So something has to know where home is, and `scripts/pals/home.gd`
is it: home is the most recently placed `bed_simple` — the piece that already
declares `respawn: true` — and pal beds within `home_radius` of it are the ones a
pal can recover in.

* **Two beds:** the newest wins. It is the rule the genre has already taught the
  player, and it is the only one that survives a reload for free, because
  `structures.load_data()` replays placements in order.
* **Zero beds:** there is no home, recovery by bed is refused with a reason
  saying so, and the revival item is the only route. §20's mandatory tutorial has
  the player build shelter, bed and campfire before anything else; this is what
  makes that sequence mean something rather than being a checklist.
* **A pal bed alone in a field is not a recovery point.** It is a bed nowhere.

## 5. Bringing them home is the trigger, because there is no button

There is no "rest" verb. The screens that could offer one live in `scripts/ui/`
and the input map is a file of its own; neither belonged to this milestone, and a
recovery system nothing can reach is the written-and-never-called shape this
project keeps getting bitten by.

So the trigger is the action the player already performs: standing in your base
with a hurt pal puts it in a free pal bed, and walking away takes it out again.
The fainted are bedded before the merely scratched, because with fewer beds than
pals a bed spent on a scratch is the wrong bed.

**This is not a pal doing a job.** `begin_rest()` is called *into* the bed from
`recovery.gd`; the bed never reaches out, has no output, no throughput and no
assignment, and the only thing that happens to the creature is that it gets its
own health back. `tests/test_stations.gd::test_no_station_can_be_told_to_work`
still passes and `tests/test_recovery.gd` asserts the same thing from the other
end.

## 6. The trainer's inventory had to be created, and it is in the wrong place

`scripts/items/` shipped a complete slot/stack inventory with **no owner anywhere
in the scene**. A revival item has to be held to be spent, so `recovery.gd` is
the first thing in the game to need a bag and therefore the first thing to make
one.

It is arranged to be taken away: point `Recovery.inventory_path` at whatever ends
up owning the trainer's bag — M9's survival loop is where it belongs — and this
node stops making one and stops saving one. The items are saved under their own
key inside the `recovery` domain rather than mixed into the resting records, so
moving them is a copy of one array.

The draughts are also **filed as a `material`** in `items.json`, which they are
not. `item_defs.gd` enumerates three categories and a `consumable` category is
the right home for this *and* for berries; adding one is an edit to a file this
milestone did not own.

## 7. With every pal down, the meadow comes for the trainer

**An owner ruling, and an explicit amendment to `GAME_DESIGN.md` §14.** §16 says
the player's own death sends their pals home and says nothing about the reverse.
The answer is not a message box: **while every owned pal is fainted, wild
creatures attack the trainer.**

The player is not stopped and not teleported. They keep walking. But they are a
target, they take damage, and they will die quickly if they stay out — so the
pressure to get home and recover the party is a real one rather than a line of
text asking for it.

What did **not** change, and what the code is arranged to keep true:

* **The trainer cannot fight back. Ever.** There is no attack on the human
  anywhere: `player_controller` grew `hurt()` and nothing else, and
  `tests/test_recovery.gd::test_the_trainer_still_cannot_fight_back` fails if it
  ever grows `attack`, `swing`, `equip_weapon` or their relatives. CLAUDE.md's
  "human cannot fight" is untouched — being hurtable is a different thing from
  being a fighter.
* **This is not Combat Mode.** No arena opens, no camera transfers, the human is
  never a party member and never has a slot in a fight. A creature that would
  have started a fight harasses the player in the world instead.
* **One standing pal and it is over.** `Hunt.tick()` asks the party fresh every
  frame, and a pal that is available resets the grace and clears every cooldown
  in the same call. A player who spends a draught and is still being chased would
  read the game as broken, so there is deliberately no state for it to be stuck
  in. Both of §16's routes — the item and the bed — are tested for it.
* **There is a head start,** `grace_seconds`. Being swarmed the instant your last
  pal drops, with no chance to run, is a different and worse experience from
  being hunted while you retreat. Measured in the real scene: the first blow
  lands about eight seconds after the last pal falls.
* **Only the dangerous species hunt.** `hunters` in `data/config/combat.json`
  chooses the policy and the per-species `aggressive` flag chooses the creatures.
  §14 says peaceful pals never initiate, and a Meadow Hopper mauling a weakened
  trainer would read as the whole meadow turning rather than as the Thornback
  being dangerous.

Every number — grace, reach, interval, damage — is in `combat.json` under
`defenceless`, labelled tunable.

## What is still open

**Player death.** A hunted trainer can reach zero HP, and `player_controller`
emits its existing `died` signal exactly as a lethal fall already does. Nothing
listens. §22's satchel, the respawn at the bed and "pals go home" are M9's
player-death bullet with their own rules about dropped inventory, and inventing
them here would collide with that milestone. `home.respawn_point()` is waiting
for it.

**No button uses the revival item.** `revive_with_item()` works, is tested, and
has no key bound to it, because the party menu and the input map both belong to
files this milestone did not own. Until one exists, the draughts are reachable
from code and from a test but not from a controller — which makes the pal bed the
only route a player can actually take, and the pal bed is the route this
milestone is really about.
