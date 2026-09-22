# D14 — One autoload, and a menu described in JSON

> Vocabulary note: written when the game called its creatures "pals"; R1.1 (2026-08-14) renamed the term to "creature" throughout the codebase without rewriting this historical record.
**Status:** accepted
**Milestone:** M4/M8/M9 groundwork (party, inventory, build menus)

## The problem

Before this, `project.godot` had no `[autoload]` section at all. Run-time state
was owned by whichever node happened to hold it: the fight owned the pals, and
nothing owned an inventory because there was not one. A menu cannot read state
that is scattered across three scenes, and a party that only exists inside
`CombatManager` cannot survive leaving a fight.

## What was decided

### 1. One autoload, `Game`, and it is meant to stay the only one

`autoload/game_state.gd` owns the party, the satchel and the day counter —
everything that outlives the scene tree. Nothing with a transform goes in it.
The fight, the camera and the terrain keep owning their own state.

The pure logic sits beside it as plain `RefCounted` classes (`inventory.gd`,
`party.gd`, `item_db.gd`) so it can be tested headlessly. `GameState` is the
thing that holds one of each; it is not where the rules live.

### 2. The autoload also mounts the pause menu

This is a second job for one object and it is deliberate. The alternative is
instancing the menu into every world scene by hand, and world scenes belong to
other people — a menu that has to be added to each new scene is a menu that will
be missing from one. One autoload line buys a menu that exists in scenes nobody
has written yet.

### 3. The menu is described in `data/config/menu.json`

The tab list, the actions that open and cycle it, the grid columns and the
footer legend are all data. Adding a screen is a JSON entry plus a script that
extends `scripts/ui/menu_tab.gd`; it never edits the shell. This is the one
structural idea worth keeping from the previous prototype's `pauseMenu.json`.
`tests/test_menu_data.gd` fails the build if a tab points at a missing script,
if an action named in the JSON is not in the input map, or if a build cost names
an item that does not exist — all of which would otherwise show as a silently
blank panel rather than as an error.

### 4. The menu polls; it is not pushed at

`scripts/ui/combat_hud.gd` set the house rule and this follows it: the menu
re-reads `GameState` every frame and keeps no copy. Actions are polled too,
because a focused `Button` swallows events and the close and cycle keys have to
work from on top of one.

Structure is rebuilt only when a `revision` counter changes, because rebuilding
nodes every frame destroys the focused node every frame — and on a controller a
focus that vanishes mid-press means the cursor cannot be moved at all. Cursor
movement itself is Godot's built-in `ui_*` focus navigation, with no code of
ours in the path.

## The consequence worth knowing about

**`menu_cancel` and `combat_run` share a DEFAULT binding.** Both ship on Escape
and gamepad button 1 (B). In a fight that button already means "flee". The menu
therefore refuses to open while a fight is running, and `inventory` (I / Y) is
the way in that never conflicts.

### Superseded, in part: the player can now move it

Settings > Controls (D15) makes every action rebindable at run time, so this is
no longer a thing the player is stuck with — `menu_cancel` can be put on any
button they like, at which point the clash and the refuse-mid-fight rule stop
mattering to them. The guard stays in `open()` because the *defaults* still
overlap and most players will never touch them, but it is now a default a
player can undo rather than a wall.

What this replaces is the fix that was pencilled in here: adding `menu_open` and
shoulder-button actions to `project.godot`'s input map. That is no longer worth
doing on its own account, and the reason it was being avoided is now a rule.
`project.godot` **is the defaults and is never written to** — the settings
screen snapshots the input map at boot and lays the player's overrides on top,
which keeps that file's documentation comments intact and means a default
changed later still reaches players who already have a settings file.

The tab row also remains focusable, and `tool_cycle` (Q / left shoulder) steps
forward through the tabs.

## What was deliberately not built

- **Storage beyond five pals.** CLAUDE.md forbids it twice. `autoload/party.gd`
  enforces the cap in `add()` and nowhere else, and there is no container, no
  reserve and no overflow list anywhere in it. The party screen draws five rows
  whether or not they are filled, so the cap is visible from the first minute
  rather than at the moment it bites.
- **The release ceremony.** M5, and a "generic delete dialog" is explicitly
  ruled out. `party.add()` returns false when full and says so on screen; it
  does not offer to drop anyone.
- **Carry weight.** GAME_DESIGN.md 19 is slot + stack with no weight limit.
  `test_inventory.gd` checks `items.json` for a `weight` or `mass` key, because
  that is how the rule would get broken quietly.
- **Placing what the build menu arms.** Confirming a buildable sets
  `GameState.pending_build` and says the hammer is still to come. Nothing is
  spent, because materials should come out when the piece is placed — deducting
  at selection would let a cancelled placement eat a gathering trip.
