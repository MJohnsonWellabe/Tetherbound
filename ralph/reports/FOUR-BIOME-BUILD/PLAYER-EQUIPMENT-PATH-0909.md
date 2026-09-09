# Player equipment path — implementation brief

2026-09-09 17:28 UTC. Status: initial implementation validated locally and held
for independent review, UI rendering and full CI; no shipping claim.

## Current evidence

Five worn-slot buttons are exposed in the Satchel preview column. Controller
Use equips carried armor; Confirm on a worn slot returns it to the bag. Local
transactions preflight swaps without mutating the original inventory, including
a full-bag swap that frees the selected item's slot. Full-bag unequip refuses.

The flat save is now version24 with explicit23→24 empty-equipment migration;
portable character version2 owns equipment, and WorldSave is unchanged. Missing
legacy data clears worn slots. Old readers reject these newer version stamps;
this is not a guarantee that an already-shipped older application cannot later
overwrite a refused character file through a separate path.

Retained evidence under `.artifacts/equipment-player-path-0909/`:

- `first`:66 tests337 assertions, one failure in the exact old15-field schema
  expectation. New transaction/portable cases passed. No engine/script errors.
- `schema-corrected`:66/338/0 after explicitly requiring the equipment field.
- `versioned`:138 tests763 assertions, zero failed, exit0,17:27:11–17:27:19 UTC.
  Four expected negative-case warnings (future character/save versions and
  unknown species), no ERROR or SCRIPT ERROR. Raw streams and guard retained.
- `controller-first`:10/0 real joypad/menu checks, exit0, raw clean.
- `controller-disk`:14/0 checks through real Game/menu input and actual disk
  save/reload, exit0,17:27:45–17:27:47 UTC, raw clean. The worn vest survives
  load, bag count stays zero, and controller Unequip returns exactly one vest.

All runs used isolated profiles, retained process handles/owned PIDs and resource
guards. No full-world/campaign credit. Remaining work includes independent
source review, rendered/controller-navigation review, additional portable
character/reset cases, and required full CI before a separate shipping PR.

## Original bounded brief

### Subsequent controller and image review,17:33 UTC

First Compatibility/OpenGL3 menu capture ran17:30:38–17:30:45,exit0,
14checks,raw clean; `shots/equipment-menu-0909.png` is1280x800. Existing
unrelated Warden agent reviewed the image without UI source (not a fresh
judge). It found no clipping, but dual focus-looking outlines, a contradictory
Empty preview and an unreadable action glyph. No visual acceptance yet.

The response makes worn focus suppress the old bag selection outline, updates
the preview from the worn item, names A/Enter for Unequip and exposes D-pad
navigation text. Initial misplaced preview statements caused a parse failure
(`controller-navigation`); retained and corrected. The subsequent live-pad
case reached the worn column but failed to select its vest using automatic
spatial neighbors (`controller-navigation-fixed`,28checks/four failures).

Changed navigation mechanism to explicit up/down worn-row links and left/right
links to the Satchel. `controller-explicit-focus` ran17:33:07–17:33:11,exit0,
26checks/zero failed, clean raw streams. It reaches equipment and selects the
vest with actual D-pad events, without direct worn-button focus injection.
Second image review remains pending behind the Water capture lease.

Source inspection confirms that `tab_backpack.gd::_read_use()` has no armor
branch, and neither `PlayerState.save_data()` nor the legacy save snapshot
stores equipment. PR100 proves the lightning receiver with equipped fixtures;
it does not yet prove that ordinary players can prepare this way.

Root owns `player_equipment.gd`, `tab_backpack.gd`, `player_state.gd`,
`game_state.gd`, `character_save.gd`, `save_game.gd`, focused equipment/save
tests and a controller input smoke. Other agents must not edit these files.

The player-facing outcome is five inspectable worn slots in the Satchel,
Equip on a carried armor item, and Unequip on a worn slot. Equipment consumes
one carried item; swapping returns the displaced item. Transactions address
item identity, preserve inventory on refusal, and refuse unequip when full.
Equipped items belong to the portable character, survive save/reload and realm
travel, and do not remain available for crafting, giving or dropping from the
bag. Legacy saves with no equipment begin with empty worn slots.

Validation must exercise actual inventory transactions, malformed/legacy save
loading, portable partition/merge, and controller events through the live menu.
The UI additionally requires a rendered check and independent visual review.
Save/autoload changes require full CI and independent review before landing.
No fourth campaign replay, new damage rule, companion armor or weapon slot is
authorized by this brief. Stop and resolve any inventory conservation or save
ownership ambiguity before shipping. Preserve PR100 and PR101 exact heads.
