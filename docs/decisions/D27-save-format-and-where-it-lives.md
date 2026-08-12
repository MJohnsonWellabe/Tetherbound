# D27 — Save format, and where it lives

**Status:** accepted
**Milestone:** R3.1 (Phase 3)

## The problem

`docs/decisions/D15` wrote `user://saves/` into the file layout and then
explicitly did not build a save system, on purpose — "persisting the party
and the world is its own milestone with its own migration story." Until this,
`docs/HANDOFF.md` §4 could still say "there is still not one write to
`user://` outside settings" and be correct.

## What was decided

### 1. Same shape as `user://settings.json`, not a new one

JSON, a `version` field from the first write, and never fatal on load: a
missing, corrupt, or newer-than-this-build slot leaves the game untouched
rather than guessing. `scripts/save/save_game.gd` is deliberately the same
kind of object as `scripts/ui/key_bindings.gd` — a plain `RefCounted`, no
node, no scene — for the same reason: it has to be testable headlessly
(`tests/test_save_format.gd`), and `docs/decisions/D02` scopes the test
harness to exactly this class of thing ("stat growth, catch chance, party
rules, save round-trips").

### 2. Five slots, one of them the autosave

`SLOT_COUNT = 5`, matching the shape the backlog item asked for ("3-5
slots"). Slot 0 is written automatically whenever the player rests
(`scripts/build/camp.gd::_pass_the_night`) — the "frequent autosave" the item
asked for, hung on the checkpoint the game already asks the player to return
to every day, the same precedent survival games with a sleep beat use. Slots
1-4 are the player's own, reached through a new "Save" tab in the pause menu
(`data/config/menu.json`, `scripts/ui/tab_save.gd`) with separate Save and
Load buttons per slot — a single button would have to guess whether a slot
that already holds a save should be overwritten or returned to, and guessing
wrong there is the one mistake on this screen that actually costs progress.

### 3. What is persisted, and by what mechanism

- **Day counter** — `GameState.day`, a plain int, round-tripped directly.
- **Party** — every field on `pal_instance.gd` (species, nickname, current
  and max HP, attack, defence, energy, fainted), reconstructed by setting
  properties directly rather than through `PalInstance.from_species()`, so a
  load never depends on `species.json` still defining that species.
- **Satchel** — every slot, **including empty ones**, because slot POSITION
  is player-visible state (the same rule `autoload/inventory.gd`'s own class
  comment already states for drag-and-drop). `Inventory.set_slot()` is new,
  and exists only for this: a direct write that bypasses `add()`'s stacking
  and slot-picking rules.
- **Placed buildings** — new: `GameState.placed_buildings`, a plain
  `[{id, position}]` array that is now the canonical record of what the
  player has built. Before this, `build_placer.gd` wrote scene nodes
  directly and nothing tracked them as data at all — a gap this item closes
  incidentally, since a build placed in a session that is never saved was
  already going to vanish the moment the scene reloaded, save system or not.
  `build_placer.gd::restore_from_game()` rebuilds the scene from the
  registry; `GameState.load_game()` calls it "by group"
  (`get_tree().get_nodes_in_group("build_placer")`), the same pattern
  `camp.gd` already uses to reach the day/night cycle without holding a
  direct reference to it.

### 4. What is deliberately NOT persisted yet

- **Storage container contents.** A placed chest (`R2.7`) keeps its own
  independent `Inventory` instance, and nothing hands that instance's state
  back to the registry entry that placed it. The chest itself survives a
  save — its id and position are ordinary `placed_buildings` data — but
  reloads empty. Narrow, named, and left for whoever next touches
  `storage_container.gd`, rather than grown into this item's scope.
- **Death satchels.** Explicitly `R3.2`, not this item — CLAUDE.md's
  "multiple death satchels persist" is a separate, not-yet-built system this
  format does not need to anticipate.
- **Auto-load on boot.** Considered and rejected for this pass: the project's
  own smoke tests share a `user://` directory within one CI job, and a save
  written by an earlier test (or a real playthrough on a developer's own
  machine) auto-loading into an unrelated scene would be exactly the kind of
  cross-test contamination `docs/decisions/D02` warns a "pure logic" test
  suite has to stay clear of. Loading is opt-in, through the Save tab, every
  time.

## What was deliberately not built

- **Migration between versions.** There is exactly one version. A newer save
  than the running build understands is left alone, same as D15's settings
  file; there is nothing yet for an older one to migrate *from*.
- **A title-screen New Game / Continue flow.** The project has no title
  screen (`project.godot`'s main scene is the playground directly). Adding
  one is out of this item's scope; the Save tab is reachable from the pause
  menu that already exists in every scene.
