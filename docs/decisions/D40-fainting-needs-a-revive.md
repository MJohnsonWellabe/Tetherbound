# D40 — Fainting needs a Revive; potions stop reviving

**Date:** 2026-08-15 · **Decided by:** the owner, after a fresh playtest
("Grandpa should give you revives at the beginning too"), asked directly:
should potions keep un-fainting a creature alongside a new dedicated Revive
item, or should reviving become the Revive's job alone? **The owner chose
"potions stop reviving" over "both revive."**

## The decision

A **Revive** is a new consumable. It only acts on a fainted creature —
clearing `fainted` and setting HP to a tunable fraction of max HP (0.5,
i.e. half strength; see `data/items/items.json`'s `revive` field). Used on
a creature that is not fainted, it refuses and restores nothing, the mirror
image of the rule below.

`creature_instance.gd::heal()` (potions) **no longer un-faints.** Called on
a fainted creature it now refuses outright — restores 0, leaves `fainted`
and `hp` untouched — instead of bringing the creature back up. Healing the
standing and reviving the fallen are now two different items with two
different jobs; neither one covers the other's.

Grandpa's parting gifts (`data/dialogue/opening.json`'s `grandpa_house`
conversation) gain `give:revive:2` alongside the existing orbs/potions/
berries, on its own line ("A potion can't help a creature that's already
down — these can"), so a new game starts with the tool the new rule
requires.

## Why

For a year of development `heal()`'s own comment argued the opposite case
outright: "a potion that cannot help the creature that needs it most is a
trap item." That was true right up until fainting got a second, better
answer. Once a dedicated Revive exists, a potion that ALSO revives makes
the Revive redundant — nothing would ever need it specifically, since any
potion in the bag already does the job. Asked to choose between "both
revive" (keep the old potion behaviour, add Revives as a stronger/cheaper
alternative) and "potions stop reviving" (give fainting its own dedicated
item and mean it), the owner picked the latter. A trainer now has to think
about a fallen creature differently from a hurt one — which is closer to
GAME_DESIGN.md's own framing of fainting as a real stakes-bearing state,
not a stat that a plentiful item shrugs off.

## What changes on disk

- `data/items/items.json` — new `revive` item, `kind: consumable`,
  `revive: 0.5` (the restored fraction of max HP, tunable, commented in
  place). Icon via `tools/gen_item_icons.py`'s `icon_revive()`: the same
  flask silhouette `icon_potion_small()` already uses, with a plus-mark
  cutout replacing the liquid-line — same "shared silhouette, one added
  marker" trick `icon_orb_greater()` already uses to tell a tier apart from
  `icon_orb_basic()` without inventing a second object.
- `scripts/creatures/creature_instance.gd` — `heal(amount)` refuses (returns
  0.0, no state change) when `fainted` is true; its old "trap item" comment
  is rewritten in place, not deleted, to record this reasoning next to the
  old one. New `revive(fraction)`: refuses (returns 0.0) unless `fainted`;
  otherwise clears `fainted` and sets `hp = max_hp * fraction`, returning the
  amount restored. `heal_fully()` is **untouched** — it still unconditionally
  clears `fainted`, because home recovery (`home_recovery.gd::rest()`,
  creature beds) is rest, not a potion, and D40 does not touch what rest
  does.
- `data/dialogue/opening.json` — `grandpa_house` gains a `give:revive:2`
  line, same `give:<id>:<count>` effect format the orb/potion/berry lines
  already use, validated the same way by
  `sequence_director.gd::_give_items()`.
- `scripts/ui/playground_hud.gd::_use_hotbar_slot()` — reads both `heal` and
  `revive` off an item's definition (mutually exclusive; an item carries at
  most one). A heal item now skips fainted party members entirely when
  picking the most-hurt target (`heal()` would refuse them anyway; auto-
  aiming a potion at the one creature it cannot help would read as broken).
  A revive item auto-targets the first fainted party member in party order
  (there is no "worst" among the fallen the way there is a most-hurt among
  the living). No valid target gets its own refusal message, matching the
  existing "Everybody's already at full health." style: **"Nobody needs
  reviving."**
- `docs/decisions/D40-fainting-needs-a-revive.md` — this file.

## What was deliberately not built

- **`scripts/ui/tab_backpack.gd`** — untouched by this task on purpose. OF22
  owns the backpack's use-item picker this wave; its eligibility check reads
  the `heal`/`revive` fields generically off an item's definition and needs
  no changes to work with the new item, per this task's own brief.
- **A stronger/rarer second Revive tier.** Not asked for. One Revive, one
  fraction, same "single tier until the roster needs a second one" shape
  `orb_greater` broke from deliberately and `revive` has not yet needed to.
- **Changing what combat does with a mid-fight Revive.** The hotbar is
  already deaf during a fight (`D32`/`HD2`: the d-pad belongs to combat
  input, not the belt, while `combat_manager.gd::is_fighting()` is true) —
  unchanged by this decision. A fainted active creature mid-fight is still
  handled by combat's own switch/end-of-fight flow, never by a hotbar
  Revive reaching in from outside it; confirmed nothing crashes when a
  Revive sits unusable in the belt through a fight that faints and ends
  (`tests/run_tests.gd`, `smoke_combat.gd` both still pass unmodified).

## Regressed 2026-08-28, restored 2026-08-31

The gift line above was dropped from `data/dialogue/opening.json` by
`66eb47ec` ("First-hour: sequence opening through tournament signup"), which
reflowed Grandpa's whole conversation set and took the potion, berry and
Revive gifts with it. One-line commit message, no note anywhere, and this
decision was never superseded — so for three days a new game started with no
answer at all to a fainted creature, which is the exact hole D40 exists to
close. `git log -S "give:revive" -- data/dialogue/opening.json` shows the add
and that silent removal and nothing else.

What it cost is measured: `ralph/reports/gate-f-capstone-1/CAP-1-FINDING.md`,
where a lost tutorial fight left a party of one fainted creature and the
chapter had no way back up. See
`ralph/reports/FINDING-CAP1-TUTORIAL-CATCH-FAINT-2026-08-31.md`.

Restored on `ralph/CAP1-TUTORIAL-CATCH-FAINT`, with one deliberate change: the
line now sits on `grandpa_first_catch` rather than `grandpa_house`, following
the fifteen Basic Orbs, which the same rewrite moved there for a reason this
file agrees with — a `give:` effect belongs on the beat before its first
possible use, not in a briefing three beats earlier. `tests/test_tutorial_faint_floor.gd`
now asserts the opening hands over Revives at all, so the next reflow of this
file cannot drop them silently.

The potions and berries from the same removed block are **not** restored by
that change. They are a pacing question about the opening's supply and nobody
has reopened it; this item is the one a live rule made load-bearing.

## What it supersedes

`creature_instance.gd::heal()`'s prior behaviour — reviving a fainted
creature at whatever `heal` amount the potion carried — is gone. Any
external notes, other decision docs, or design text that still says "a
potion revives" describes the pre-D40 rule.

## The revert

One line: restore `heal()`'s old body (drop the `fainted` refusal, `hp > 0.0`
still sets `fainted = false` same as before D40) and `revive()`, the
`revive` item, and the `give:revive:2` gift line become inert vestiges,
harmless to leave in place or to delete.
