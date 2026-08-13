# D28 — Two UI themes, and one token module underneath both

**Date:** 2026-08-13 · **Decided by:** the owner, in a supplied specification
`TETHERBOUND_UI_PALWORLD_VALHEIM_SPEC_v2.md`, stored under
`docs/reference/external/ui/` and treated as an execution spec, not a mood
board (spec §1).

## The decision

The UI pass adopts the spec's split wholesale: **exploration, inventory, Pal
management, combat and capture stay one dark, translucent, teal-accented
skin; build selection and placement get a separate warmer wood/brass skin**
(spec §12, §26 Final Principle). Two `Theme` resources carry that split —

- `assets/ui/theme/tetherbound_theme.tres` — the general game UI (spec §4).
- `assets/ui/theme/build_theme.tres` — build menu and placement only (spec
  §12–§13).

— and one script owns the values both themes and every hand-drawn HUD element
read from: `scripts/ui/ui_tokens.gd`, an all-static class holding the spec's
§4.1 palette, §4.4 type scale, §5 spacing figures and §19 motion timings.
**Not an autoload.** D14 already drew that line for pure data — `item_db.gd`
sits beside `GameState` rather than inside it — and a palette is exactly that
kind of thing: read everywhere, owned by nothing with a transform.

## Why now, and why one module

Six HUD scripts had independently reinvented the same handful of constants,
and they had drifted apart in the reinventing:

- `PANEL_BORDER` is the identical `Color(0.55, 0.85, 0.86, 0.65)` in
  `craft_panel.gd`, `storage_panel.gd`, `menu_tab.gd` and `playground_hud.gd`
  — four literal copies of one value, none of them referencing the others.
  `dialogue_panel.gd` and `name_prompt.gd` carry a second, deliberately
  quieter pair (`0.55, 0.60, 0.50, 0.55`) for dialogue chrome; that stays a
  second named token (`DIALOGUE_BORDER`) rather than being forced to match,
  since the muted tone there was a choice, not drift.
- `HEALTH_FULL` / `HEALTH_LOW` exist in three places — `combat_hud.gd`,
  `tab_pals.gd`, `playground_hud.gd` — and all three **disagree**:
  `playground_hud.gd`'s green is measurably brighter than the other two's.
  Nobody meant that; nobody would have caught it by reading any one file.
- The outline/shadow treatment (`OUTLINE`, `OUTLINE_SIZE`) is copied into six
  files — `combat_hud.gd`, `dialogue_panel.gd`, `starter_picker.gd`,
  `game_menu.gd`, `name_prompt.gd`, `playground_hud.gd` — always the same
  values, always retyped.

All of it collapses into `ui_tokens.gd`. A HUD script keeps its own layout
code; it stops keeping its own idea of what teal is.

## What changes on disk

- `scripts/ui/ui_tokens.gd` — new. Palette (`UI_BG_DEEP`, `UI_BG_PANEL`,
  `TETHER_TEAL`, `HP_GREEN`, `STAMINA_ORANGE`, etc., spec §4.1), type scale
  (spec §4.4), spacing constants (spec §5), motion timings (spec §19).
- `assets/ui/theme/tetherbound_theme.tres`, `assets/ui/theme/build_theme.tres`
  — new `Theme` resources built from the tokens (spec §22's own suggested
  paths).
- Kenney Future (`assets_raw/vendor/kenney_ui-pack/Font/Kenney Future.ttf`,
  already vendored, CC0) becomes the UI font, closing the "no font chosen"
  gap D24 left open when it scoped the HUD rebuild to Kenney UI + Input
  Prompts.
- Focus ring: gold → teal (spec §17). `menu_tab.gd`'s own comment already
  names the thing being changed — "whatever the shared menu theme already
  draws for them (the gold focus...)".
- Explicit `CanvasLayer.layer` values replace order-of-addition stacking.
  Every HUD script (`combat_hud.gd`, `craft_panel.gd`, `storage_panel.gd`,
  `dialogue_panel.gd`, `starter_picker.gd`, `game_menu.gd`, `name_prompt.gd`,
  `playground_hud.gd`) currently `extends CanvasLayer` with no `layer` set at
  all, so stacking order is whatever order the scene happened to add nodes
  in — correct today by accident, and one new panel away from a dialogue box
  drawing under the pause menu. Assigned layers: HUD 1, combat 2, world
  panels (craft/storage/dialogue content) 3, dialogue 5, prompts 6, menu 20.

## The spec's own internal conflict, resolved

The spec ships two minimap sections that disagree: §6A.1 says **top-right**,
with the objective block beneath it when the objective panel would run too
tall; the older draft at §6.5 says **top-left**. §6A wins — it is the fuller,
later-numbered section (14 sub-sections against §6.5's shorter pass), and
§6.3's own objective placement independently agrees with top-right, which
§6.5's top-left would collide with. Minimap: top-right. Objective: beneath
it. See `D33` for the map data layer this feeds.

## What it supersedes

Every hand-rolled `PANEL_BG` / `PANEL_BORDER` / `HEALTH_FULL` / `HEALTH_LOW` /
`OUTLINE*` constant listed above, in place, not deleted-and-reimplemented —
each file keeps its layout logic and starts reading the shared token instead
of declaring its own. No gameplay state moves; this is presentation only.
