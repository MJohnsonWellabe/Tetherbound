# D23 — A trainer battle is N ordinary fights in a row

**Status:** accepted
**Decided by:** implementation, during M13/M14
**Builds on:** `D07-combat-is-piloted-not-commanded.md`, `D13-the-five-pal-cap-is-code.md`, `D16-the-release-ceremony-is-the-only-exit.md`

## The decision

`GAME_DESIGN.md` §14 says "Trainer fights are team-vs-team". Nothing in
`scripts/combat/` grew a team.

An opposing trainer owns a list of creatures and an index into it
(`scripts/trainers/trainer_battle.gd`). When the player accepts a challenge, the
trainer stands one of them in front of the player and calls
`EncounterDirector.engage()` — the same function a wild encounter goes through.
`CombatManager` fights one creature against one creature inside one arena, as it
has since M2. When that creature goes down, the trainer waits a beat and sends
the next one, which is another call to the same function.

The arena, the camera handover, the aimed cone, the wind-up and recovery, the
Switch command, the five-pal party, the XP payout and the fainting rules are all
untouched. The only change inside `scripts/combat/` is the one described below,
which is four lines.

## Why not a team mode in the combat manager

The tempting shape is a `CombatManager` that knows about two teams and cycles
both. It is wrong for a specific reason rather than an aesthetic one: **the
player's side is not a team in that sense.**

The player already has five pals and already switches between them mid-fight,
with a cooldown and an entry lag, under `Switchboard`. That is §14's Switch
command and it is a *decision made inside one fight*. An opposing trainer's
sequence is the opposite — their creature is knocked out and the next one
arrives, with no choice involved. Modelling both with one mechanism would mean
either giving the player automatic replacement (which deletes the cost of losing
a deployed pal, and with it M6) or giving the opponent a switch (which is a
whole second AI).

So: the player's side is a party with a Switch command; the trainer's side is a
queue. They are different things and they stay different.

The other half of the argument is M14. The Warden IS a Team Tether trainer
fight, and building the boss separately would mean two implementations of
team-vs-team, two places the cannot-catch rule has to be remembered, and two
things to fix when the AI changes. There is no boss code path anywhere in this
milestone; what makes the Warden the Warden is a longer team, three higher
levels, and a harder tether grade, all of it data.

## The hard rule was written and unreachable

CLAUDE.md: *"Trainer-owned pals cannot be caught."*

`catch_math.can_be_caught(is_fainted, already_owned)` has taken that second
argument since M3, with a comment saying the rule was "enforced here so every
future path into catching inherits it". `tests/test_catch_math.gd` covered it.
Both call sites in `combat_manager.gd` passed a literal `false`.

Nothing in the game had ever passed `true`, because until this milestone there
was no creature in the world that anybody else owned. The rule existed, was
documented, was tested, and could not fire. This is the same shape as D13's
unbounded `_caught` array whose accessor had zero callers, and as the reward
system that was thoroughly tested and never called.

What changed:

* `scripts/trainers/tether_pal.gd` declares `is_trainer_owned()`.
* `combat_manager._opponent_is_trainer_owned()` asks the opponent for it, and
  both call sites pass the answer.
* The refusal has its own sentence, because "it fainted" is a mistake the player
  made and "it belongs to somebody" is a rule, and a player who cannot tell the
  two apart will keep testing the second one.

**Duck-typed, not a flag.** `tether_pal` answers yes by *having* the method;
`wild_pal` answers no by not having it. There is no boolean anybody can forget
to set on a new opponent, and no way to give a wild creature the wrong answer.
`tests/test_trainer_battle.gd` asserts that both call sites ask, and that no call
site passes a constant — because a test of `can_be_caught` itself would have
passed happily for the four milestones the rule was dead.

## Difficulty is timing, never stats

M14's bullet is "meaningful difficulty". The cheapest way to produce that number
is a health multiplier, and it is a wall rather than a difficulty: a player
cannot read it, cannot play around it, and experiences it as the fight taking
longer.

So the tether — the thing Team Tether puts on a creature, visible on the creature
as an oxblood collar — multiplies **only beat timings**:

| what | wild | Warden's grade |
|---|---|---|
| telegraph (the warning) | 0.55s | 0.41s |
| recovery (the player's punish window) | 0.75s | 0.56s |
| attack cooldown | 1.10s | 0.75s |
| chase speed | 4.6 | 5.3 |

Nothing else. `tether_pal.tethered_config()` writes seven keys and they are all
timings or speeds; `tests/test_trainer_battle.gd` asserts that every other key in
the config comes out unchanged, and that no trainer's team entry may carry any
key but `species`, `level`, `tether` and `nickname`.

It is legible because the player has fought thirty untethered creatures in the
meadow by now and knows the rhythm. A tethered one is visibly the same creature
run fast, with the cable that is doing it standing in the frame.

The specific claim, asserted rather than asserted-to: the Warden's 0.56s opening
still fits the player's quick attack (0.40s of wind-up plus recovery) and no
longer fits the charged attack (1.05s). Spending the meter goes back to being a
decision. If tuning ever breaks that inequality, the test fails and the argument
for why the boss is hard fails with it.

Levels are a deliberately small edge (7/8/9). Damage is bounded —
`power * 2 * attack / (attack + defence)` — so a level raises an opponent's
defence and its health together and multiplies time-to-kill much faster than it
raises the threat. A level-14 heavy would be a forty-hit sponge that could not
kill anybody, which is the wall this section exists to refuse.

The second half of the difficulty is structural: **your damage carries between
the trainer's creatures and theirs does not.** Breaking off — running, or losing
your deployed pal — restores the trainer's whole team and never yours. Without
that, any trainer is beatable by attrition across unlimited attempts and
"meaningful difficulty" becomes meaningful patience. It is a config flag with a
paragraph above it saying so.

## The legendary comes in through the narrowest door in the codebase

§3's stronghold conclusion ends "the unique pal voluntarily offers to join. If
the player already has five, trigger the release ceremony."

`legendary_offer.accept()` calls `EncounterDirector.offer_pal()`, which calls
`_keep()` — the same function a capture calls — which calls `Party.add()`, which
refuses a sixth with `REFUSED_PARTY_FULL`, which the director re-emits as
`caught_refused(token, instance)`, which `release_prompt.gd` has been listening to
since M5. There is no new ceremony and no new branch. `legendary_offer.gd` does
not contain the word "ceremony".

D13 and D16 are why. A second route into the party is an exception to the
five-pal cap; a place for the legendary to wait while the player thinks is
storage; and a ceremony that can be skipped for a special creature makes the
game's one irreversible decision optional for the creature it matters most for.

**The consequence is stated rather than softened:** with a full party the ceremony
presents six, the legendary is one of the six, and the player may release it.
Permanently, with no second offer. That is D16's "cancel, made explicit", and
special-casing the legendary out of it would be exactly the exception those two
records exist to forbid.

## What could not be finished here, and is not pretended

**The legendary has no art.** The asset pass rejected the one plausible free
candidate on evidence — a 144-bone rig sharing 47 bones with the knight, so
nothing retargets onto it — and its conclusion was that this creature has to be
*modelled*, not bought. So the species is real, saved, rideable and joins
correctly, and it draws as `pal_body`'s capsule fallback under the display name
"Meadows Legendary (unmodelled)". A scaled-up stag would have photographed as a
legendary and then sat in the game being one; the name and the empty `model` are
both asserted by a test that says, in its own message, to delete the assertion
when real art lands.

**§28 wants a Ground legendary that is the ultimate mount, and every awe-inspiring
free candidate is a flyer.** Flagged in `data/trainers/species_addendum.json` and
not resolved. Do not resolve it by quietly making the legendary an Air type.

**The legendary is not in `species.json`.** That file belonged to another agent
for the whole milestone, and a species that is not in the table would produce a
legendary that joins, saves, and vanishes on the next load —
`pal_instance.from_record()` rebuilds a saved pal by asking the table for its id.
So `tether_roster.gd` merges `data/trainers/species_addendum.json` into the table
at boot, before any save is restored, never overwriting anything `species.json`
defines. It is a seam with its own file and a loud name, and the instruction for
deleting it is in both files.

**`StrongholdRoute` is mounted from code, not from the scene.** Same reason and
the same shape as `build_mode._mount_field_systems()`: two other agents were in
`meadows_playground.tscn`. The exact node to add is written above the function.
