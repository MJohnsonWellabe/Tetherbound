# D28 — A UI token module

**Status:** accepted
**Milestone:** EV9 (HUD rebuild)

## The problem

`PANEL_BG`, `PANEL_BORDER`, `OUTLINE`, `OUTLINE_SIZE`, font sizes, spacing —
the same handful of values, each declared as its own `const` in
`scripts/ui/playground_hud.gd`, `scripts/ui/menu_tab.gd`,
`scripts/ui/combat_hud.gd`, and (once they exist) `craft_panel.gd` and
`storage_panel.gd`. They already drift: `playground_hud.gd`'s
`OUTLINE_SIZE` is 6, `combat_hud.gd`'s is 7, for what is meant to read as the
same outline treatment. Four screens independently guessing at "dark and
teal" is how a HUD stops reading as one system, which is the failure
`menu_tab.gd`'s own header comment already names for its narrower case.

## What was decided

One module, `scripts/ui/ui_tokens.gd` (`class_name UITokens`), `RefCounted`,
all `static`/`const`, not an autoload — every value is either a constant or a
pure function of its arguments, so there is nothing here that needs a node in
the tree. It is the single source of truth for color, type, spacing, and
motion timing across the HUD, the pause menu, and the two Themes below.

The old per-screen constants are not deleted by this item. They migrate one
screen at a time in a follow-on pass, so a HUD rebuild and a token-module
introduction are not the same commit. Values in `ui_tokens.gd` are starting
points, not canon frozen the moment this file lands — the usual "tunable,
not permanent" rule from `CLAUDE.md` applies to a color exactly as it does to
a cooldown.

Two Theme resources ride on the same tokens: `assets/ui/theme/tetherbound_theme.tres`
(the teal/dark palette, superseding `scenes/ui/menu_theme.tres`'s gold focus
ring per spec §17 — focus is now a teal border, not gold) and
`assets/ui/theme/build_theme.tres` (a warm brass variant for build/craft
surfaces). Both point at the vendored Kenney Future / Kenney Future Narrow
fonts (`assets/ui/fonts/`) rather than the engine default.

## What was deliberately not built

- **Migrating `playground_hud.gd`, `menu_tab.gd`, `combat_hud.gd` onto the new
  module.** A separate item's job; this one only adds the source of truth.
- **Swapping `scenes/ui/menu_theme.tres` for `tetherbound_theme.tres` in any
  live scene.** Same reason — the new Theme exists and loads, and nothing
  points at it yet.
- **A runtime theme switcher between the two Themes.** `build_theme.tres` is
  for whichever build/craft screen chooses to use it explicitly; there is no
  mechanism here for swapping a CanvasLayer's theme at runtime.
