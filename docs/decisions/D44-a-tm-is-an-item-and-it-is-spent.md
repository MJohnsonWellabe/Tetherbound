# D44 — A TM is an item in the satchel, and teaching spends it

**Date:** 2026-08-15 · **Decided by:** the owner, in a playtest report:
*"I can pick up a TM but it needs to go in my inventory and then I see it's
stats and choose who to teach it to."* (`docs/CURRENT_STATE.md`, OF29.)

## The decision

1. **A TM is an inventory item.** `scripts/world/tm_pickup.gd` no longer
   converts a found TM into a progression flag and disappears. It calls
   `inventory.add()` like `key_pickup.gd` does, with the same refusal
   contract: a full satchel leaves the disc standing in the world, still
   offering. Each TM in `data/moves/tms.json` now has a matching
   `kind: "tm"` item in `data/items/items.json` **under the same id** —
   that shared string is the entire link between the two files, and
   `tests/test_moves.gd` fails the build if either side lacks its half.
2. **You inspect it before you spend it.** The backpack detail panel reads a
   TM's move name, slot, type and power from `move_db.gd` and its
   compatibility list from `tm_db.gd`. Neither is copied into `items.json`;
   the item entry only names its `move` id.
3. **You choose who learns it.** Use on a TM opens the *same* target picker
   OF2/OF22 built for potions — rows made eligible by
   `teaching.gd::can_learn` plus "does not already know it", ineligible rows
   greyed with the reason in the row text ("already knows it" / "can't learn
   it"), and a refusal-to-open when nobody on the belt qualifies.
4. **Teaching consumes the TM.** One disc teaches one creature. This
   overrules `docs/specs/GAME_DESIGN.md` §13's "Not consumed after one teaching"
   and the R4.4 implementation built on it.
5. **The silent auto-teach is gone.** `tab_creatures.gd`'s `TEACH_ACTION`
   picked both the TM and the moment for the player and showed neither. It
   is deleted; the Team screen's hint line points at the backpack.

## Why

R4.4 read §13's "not consumed after one teaching" as "not consumed by any
teaching", and followed that reading all the way down: if a TM is permanent
knowledge rather than an object, it does not belong in a satchel at all, so
it became a flag and the Team screen grew a one-press verb to apply it. That
was internally consistent and it produced a feature the owner could not see
working — nothing to look at, nothing to choose, no way to tell that the
press had done anything.

The owner's sentence settles all of it at once. "It needs to go in my
inventory" is an item. "I see it's stats" is a detail panel. "Choose who to
teach it to" is a target picker — and a choice with no cost is not a choice,
so the disc is spent. Reusing the potion picker rather than building a second
one keeps one answer to "which of my five is this for?" on screen, and one
place where the "never open a picker nobody can use" rule lives.

## Reversibility

If the owner prefers reusable TMs after playing with these, the revert is one
line: drop the `inventory.remove()` call in the TM branch of
`scripts/ui/tab_backpack.gd::_on_target_row()`. `teaching.gd` never touched
an inventory and still does not — it takes a creature and a TM id and writes
a move slot — so nothing below the UI has an opinion about consumption. The
`stack: 1` cap in `items.json` and `tests/test_moves.gd`'s
`test_a_tm_item_does_not_stack` are the other two lines that encode the
choice.

## Migration

The `tm:<id>` progression flag survives with a narrower job: *this world
pickup has been taken*. `playground_world.gd::_place_tms()` now reads it and
skips placing an already-taken TM, which is what stops a reload from minting
a fresh copy of a consumable.

A save written before this decision carries that flag from the old flag-only
pickup, and gets exactly the same treatment: the prop stays gone and **no
free item is granted**. The flag's only other reader was the auto-teach this
decision deletes, so a player who took a TM under the old rules already had
every teach that screen would ever have given them. Handing them a disc now
would be inventing a reward the old design never promised. The two TM props
are a few minutes' walk apart in the Meadows and this is a vertical slice
still being rebuilt around the player, so the cost of being wrong here is one
`progression.set_flag("tm:...", false)` away from being undone.
