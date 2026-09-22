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

## The CanvasLayer plan

The token module also ends order-of-addition layer stacking. Every HUD
script (`combat_hud.gd`, `craft_panel.gd`, `storage_panel.gd`,
`dialogue_panel.gd`, `starter_picker.gd`, `game_menu.gd`, `name_prompt.gd`,
`playground_hud.gd`) `extends CanvasLayer` with no `layer` set at all, so
draw order is whichever order the scene happened to add nodes in — correct
today by accident, and one new panel away from a dialogue box drawing under
the pause menu. `ui_tokens.gd` fixes the order as data:

```
LAYER_HUD = 1            LAYER_DIALOGUE = 5
LAYER_COMBAT = 2         LAYER_PROMPTS = 6
LAYER_WORLD_PANELS = 3   LAYER_MENU = 20
```

Each HUD script sets its own `layer` to the matching constant on `_ready()`
as part of the migration pass named above — declaring the plan and wiring
every screen to it are still two separate steps, for the same
one-commit-at-a-time reason the palette migration is.

## Resolving the spec's own minimap conflict

The owner's UI spec ships two minimap placement sections that disagree:
§6A.1 says the minimap goes **top-right**, with the objective block sliding
beneath it when the objective panel would otherwise run too tall; the
shorter, earlier-drafted §6.5 says **top-left**. §6A.1 wins — §6A is the
fuller section (fourteen numbered sub-sections against §6.5's one pass), and
§6.3's own objective placement independently agrees with top-right, which a
top-left minimap under §6.5 would sit directly against. Minimap: top-right.
Objective: beneath it, per §6A.1's own fallback rule. See `D33` for the map
data layer the minimap and full map both read.

## What was deliberately not built

- **Migrating `playground_hud.gd`, `menu_tab.gd`, `combat_hud.gd` onto the new
  module** — including setting each `CanvasLayer`'s `layer` to its
  `ui_tokens.gd` constant. A separate item's job; this one only adds the
  source of truth and the plan both migrations read from.
- **Swapping `scenes/ui/menu_theme.tres` for `tetherbound_theme.tres` in any
  live scene.** Same reason — the new Theme exists and loads, and nothing
  points at it yet.
- **A runtime theme switcher between the two Themes.** `build_theme.tres` is
  for whichever build/craft screen chooses to use it explicitly; there is no
  mechanism here for swapping a CanvasLayer's theme at runtime.
