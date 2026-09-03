# D15 — Remappable controls, and the project's first file in `user://`

**Status:** accepted
**Milestone:** menu groundwork (Settings tab)

## The problem

The owner: *"I should be able to map controls to whatever buttons I want. this
should be a controls setting in settings in the menus"*.

Every action shipped with one keyboard binding and one Xbox-layout gamepad
binding, baked into `project.godot`, and there was no way to change any of it
from inside the game. On a handheld that is not a preference — it is the
difference between a comfortable grip and a button the player's hand cannot
reach.

Underneath it there was a second problem: **nothing in this codebase had ever
written to `user://`.** No `ConfigFile`, no `ResourceSaver`, no save system.
Controls that do not persist are not controls, so this feature had to establish
that pattern before it could exist.

## What was decided

### 1. `project.godot` is the defaults, and is never written to

`scripts/ui/key_bindings.gd` snapshots the input map as Godot loaded it, at
autoload time, before any world scene has read an action. The player's overrides
are applied on top, and only the *differences* are saved.

Three things follow, and all three are the point:

- The file's documentation comments survive. An editor pass over
  `project.godot` strips them, which has already cost this project once.
- A default that changes later still reaches a player who already has a settings
  file — because their file only records what they personally moved.
- "Reset to defaults" is a real operation with a real answer, rather than a
  guess at what the game shipped with.

### 2. Two slots per action: keyboard and gamepad, both on screen at once

Windows and the ROG Ally are both primary, so both bindings are shown on every
row and either can be changed from the same screen. Mouse buttons live in the
keyboard column, because that is where a desk player looks for them —
`combat_quick` ships on left click.

The camera stick is listed and rebindable; the **mouse** is not, and the screen
says so. Mouse look is `InputEventMouseMotion` read directly in
`scripts/player/camera_rig.gd`, not an input-map action at all, so a row for it
would be a row that does nothing.

### 3. Clashes are ALLOWED, and named out loud

This was the real decision. Three options: swap the other action onto the old
binding, refuse the clash, or allow it and say so.

**Allow it.** The shipped defaults already contain four deliberate duplicates —
A is `jump` *and* `combat_quick* *and* `menu_confirm`; B is `menu_cancel` *and*
`combat_run` — because the world, a fight and a menu are different contexts and
a button is allowed to mean different things in each. Refusing duplicates would
have made the game's own defaults unreachable from the screen that is supposed
to reproduce them. Swapping is worse still: "your throw button is now whatever
your flee button used to be" is a surprise, and it chains.

So the binding is taken, and the status line says what else now answers to it:

> Map is now I — so is Open the backpack. Both will fire.

And because a status line is gone in three seconds, **both rows stay marked** in
amber for as long as the clash exists. Refusing silently was never on the table;
this screen's one job is to be honest about what the buttons do.

### 4. Reset is a safety feature, so there are three of them

A player can rebind themselves out of being able to open or navigate the menu.
Every route back has to survive that:

- **Per action.** A `Default` button on every row.
- **Everything.** A button at the *top* of the section — above the rows, not
  below them, because it is the way out of a layout the player may no longer be
  able to scroll. It takes two presses, like picking a stack up and putting it
  down, so one stray press cannot throw away ten minutes of fiddling.
- **The panic chord.** Hold the pad's **Menu + View** together, or **F10**, for
  a second and a half, anywhere in the game. This reads the *device* through
  `Input.is_key_pressed` / `Input.is_joy_button_pressed` rather than the input
  map, which is the whole point: every other way in goes through an action the
  player is allowed to move, so every other way can be lost.

  `docs/TECHNICAL_ARCHITECTURE.md` says never to scatter raw device checks through
  gameplay. This is the exception that rule needs — it is the one check that has
  to keep working when the input map is what is broken — and it lives in exactly
  one place, `scripts/ui/game_menu.gd`.

Godot's built-in `ui_*` actions are **not rebindable and never will be**. They
are the focus navigation that drives this very screen with a stick; a player who
rebound `ui_down` could not reach the control that would undo it.
`tests/test_controls.gd` fails the build if one ever appears in the JSON.

### 5. The file: `user://settings.json`, versioned, and never fatal

This is the project's first write to `user://`, so the shape is worth stating.

```
user://settings.json     preferences — controls now, display and audio later
user://saves/            game saves, when there are any. NOT created here.
```

Preferences and saves are different things with different lifetimes: wiping a
save should not cost the player their button layout, and the two want separate
file formats and separate migration stories. They live beside each other so a
save system has somewhere obvious to go, and that is as far as this work builds
towards one — **no save system was written**.

The file is JSON to match the rest of the project's data, and carries a
`version` field from its very first write, as `docs/TECHNICAL_ARCHITECTURE.md` asks.
It has named sections (`controls`) so display and audio join this file rather
than each inventing one of their own.

**A settings file must never stop the game booting.** Four cases, four
behaviours, all of them "carry on with defaults and log it":

| the file is | what happens |
|---|---|
| missing | normal first run, no warning |
| corrupt or not JSON | defaults, warning |
| an older version | defaults, warning — there is no migration yet |
| a newer version | defaults, warning, **and it is not overwritten** — the player may go back to the build that wrote it |

Individually bad entries are skipped rather than fatal: an action this build no
longer has, or a binding string it cannot parse, costs that one line and nothing
else. Renaming an action must not brick everyone's settings.

### 6. Where the code lives

`scripts/ui/key_bindings.gd` is a plain `RefCounted` with no node, no scene and
no autoload in it, following `autoload/inventory.gd` and `autoload/party.gd`:
the rules live in something that can be tested headlessly, and holding one of
them is somebody else's job. Here that somebody is `scripts/ui/game_menu.gd`,
which is mounted by the autoload at boot and therefore exists in every scene
before anything reads an action.

The rebindable list, the action labels and the Xbox glyph names are all in
`data/config/menu.json`, next to the rest of the menu. A PlayStation glyph set
is a swap of one JSON block.

## What was deliberately not built

- **Display and audio sections.** The tab loops `settings.sections` from the
  JSON and that list has one entry. Adding a section is an entry plus a
  `_build_*` method, which is the shape the rest of the menu already uses.
  Building empty ones now would be furniture.
- **A save system.** `user://saves/` is named in this document and created by
  nobody. Persisting the party and the world is its own milestone with its own
  migration story, and quietly starting it inside a settings screen would be the
  worst possible place to make those decisions.
- **Per-device profiles, and controller layouts other than Xbox.** The Ally is
  an Xbox-layout pad. The glyph table is data, so the day a second layout
  matters it is a JSON block and a way to pick between them — not a rewrite.
- **Binding Escape or gamepad B from this screen.** They always cancel a
  capture, read off the device, so that getting out of a rebind never depends on
  bindings the player may have just broken. Both are already the defaults for
  "back", and every reset puts them there.
- **Rebinding the mouse.** See section 2: mouse look is camera code, not an
  action.
