# D18 — The opening starts indoors

> Vocabulary note: written when the game called its creatures "pals"; R1.1 (2026-08-14) renamed the term to "creature" throughout the codebase without rewriting this historical record.
**Status:** accepted, by the owner
**Decided:** after the owner's first real playtest of the build, 2026-08-09

## The decision

The player wakes in a bed, upstairs, inside Grandpa's farmhouse. They walk
downstairs, talk to him, receive a parting gift of orbs and potions and the
**creature belt**, and step out the front door to the three starters waiting
beside it. The old beats 1–2 — fade in outside the house, walk across open
meadow to Grandpa — are replaced by **wake** and **house**; everything from
the starter choice onward is unchanged.

Three things ship together because they are one idea:

1. **The house is real.** Grandpa's farmhouse has an interior — bed, stairs,
   the room where he waits — built from the Quaternius Farm Buildings and
   Ultimate Furniture packs (CC0, recorded in `docs/ASSET_LEDGER.md`). The
   camera switches to an interior profile via `camera_rig`'s `set_target`
   profiles and back on exit.
2. **The gifts are real items.** `orb_basic` and `potion_small` are entries in
   `data/items.json`, and Grandpa's dialogue grants them through a new
   `give:item:count` dialogue effect — the same dialogue data format, one new
   effect verb. `throw_aim` now spends an orb from the satchel per throw;
   there is no infinite pocket of orbs anymore.
3. **The five-slot party is the belt.** The UI and Grandpa's dialogue both
   call it the **creature belt**: five holders on a strip of leather he hands
   you. The cap stops being an abstract rule and becomes an object you were
   given.

## Why

**The owner played the first build and asked for it.** The old opening faded
in on open grass with Grandpa standing in a field; it read as a sandbox with a
greeter in it, not a home being left.

**The design already said this.** `GAME_DESIGN.md` §33's first-day criterion
begins *"Wake at Grandpa's home"*, and §24: the player *lives with Grandpa*,
his home is the safe starting location. `docs/OPENING_SEQUENCE.md`'s "no
interior" note was a cost-saving call with its own revisit clause written in —
*"Revisit only if the fade-in reads as cheap in playtest"* — and that is
exactly what happened. This is the revisit, on the terms the original decision
set for itself.

**The gifts kill two long-standing fakes at once.** Orbs came from nowhere and
potions did not exist; the first crafting and economy work (Ralph Phase 2)
needs both to be inventory items with counts, and the opening is the natural
place they enter the world — from Grandpa, with a line of dialogue, not from a
config default.

## What it cost

- **An interior art dependency.** The opening now depends on two sourced packs
  for the house and furniture. Both are CC0 and in the ledger, but the
  farmhouse interior is now on the list of things that must be judged with
  representative art (`CLAUDE.md`'s prototyping rule) — a bare box with a bed
  in it would fail the exact test this restaging exists to pass.
- **An interior camera.** Third-person orbit in a bedroom clips walls; the
  interior profile (tighter distance, capped pitch) is new tuning surface that
  did not exist when the whole game was outdoors.
- **A larger opening to smoke-test.** `smoke_opening` now walks a staircase
  and a doorway before it reaches the old flow.

## What stays true

- **The starter choice is physical, not a menu.** You still walk to the one
  you want; the other two stay with Grandpa where you can see them. Moving
  them from the meadow to the front door changes the set dressing, not the
  choice.
- **No branching dialogue.** Grandpa's lines advance on the interact button.
  The `give:` effect is a side effect of a line, not a choice node.
- **Naming is mandatory.** Unchanged.
- **The five-cap is untouched.** The belt is a *framing* of `MAX_PALS := 5`,
  not a mechanic. Nothing reads the belt; `Game.party` is still the truth.
  If a later idea wants belt upgrades or a sixth holder, that is a party-limit
  change and `CLAUDE.md` forbids inventing it.

## Where it is recorded

- this file
- `data/config/opening.json` — the wake/house beats
- `data/dialogue/` — Grandpa's gift lines and the `give:item:count` effects
- `data/items.json` — `orb_basic`, `potion_small`
- `docs/ASSET_LEDGER.md` — the two Quaternius packs
