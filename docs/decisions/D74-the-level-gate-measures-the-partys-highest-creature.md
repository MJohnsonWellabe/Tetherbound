# D74 — A trainer's level gate measures the party's highest-level creature

**Date:** 2026-09-04 · **Decided by:** lane W10-TRAINER-RULES, under
`docs/owner/OWNER_DIRECTIVES_2026-09-04-B.md` D-0904B-4 and amendment A-4:
*"gate just make the fight not start unless you're a certain level. the guy can
just say 'you're too low level I'll crush you and send you crying to Grandpa'."*

The owner settled the shape of the gate (a trainer refusing in character, not a
UI lock) and the wording. They did not say **which** number the gate reads, and
three readings are defensible. This records the choice so the mechanism cannot
drift, and so a later authored gate is tuned against a number that means one
thing.

## The decision

`min_level` on a trainer row is compared against **the highest level in the
player's party** (`scripts/world/trainer_npc.gd::party_high_level()`), not the
level of the deployed creature and not a party average.

## Why not the deployed creature

The player pilots one creature but fights with a team: `combat_manager.gd`
switches mid-fight, and `encounter_director.gd` deploys whoever `Game.party`
has active — which is frequently whoever was out last, not whoever is
strongest. Gating on that refuses a player whose level-12 answer to this
trainer is one `party_cycle` press away, with a taunt that is simply untrue.
The refusal has to be about the team, because the fight is.

## Why not an average

Five creatures total, and the chapter wants the player catching new ones. A
freshly caught level-2 creature drags an average down hard enough to re-lock a
gate the player already cleared the intent of — punishing exactly the behaviour
`docs/GAME_VISION.md` and D-0904B-1's alpha pins are trying to encourage.

## What this does not decide

- **No shipped trainer carries a `min_level`.** The mechanism exists; no gate is
  authored. `docs/FINISH_THE_MEADOWS.md`'s own dependency stands: wild density
  lands on the route before a level gate goes on it, or the gate is the wall
  D-0904B-4 says it must not be.
- **The South Bridge keeps its physical key.** `MEADOWS_PROGRESSION_SPEC.md`
  § the South Bridge is unchanged in substance — amendment A-4 explicitly
  preserves "a physical key/mechanism, not a UI level lock", because a trainer
  who sizes you up and refuses *is* the world creating the gate. One paragraph
  was added there describing the level condition as a diegetic refusal.
- **Fainted and resting creatures still count.** The gate asks what the player
  *owns*, not what is battle-ready this second; "nothing usable to fight with"
  is already its own separate refusal with its own two honest lines
  (`no_usable_ally()`, dark-features T1), and collapsing the two would put the
  wrong sentence in front of a player whose only problem is a hurt creature.
