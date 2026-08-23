# D2 HUD and menus — round 2

Round 1's report is `ralph/reports/VISUAL_UI_2026-08-23.md`. This round did two
things: it found that most of what round 1 named was the survey photographing
something other than the game, and it fixed the defects that were left once
that was corrected.

## The headline: six of round 1's findings were capture artefacts

`ralph/VISUAL_LEDGER.md` already records that this sweep photographed the wrong
subject six times across all domains. D2 alone now accounts for five more, and
every one was diagnosed by experiment rather than by looking at the frame
again.

**1. `08-party-strip` and `09-stamina-arc` came back solid near-black.** Neither
widget is broken. Both closeups staged a full-screen backdrop in a
`CanvasLayer` at layer 0 and parented the widget straight to `root`, and a
`CanvasLayer` at layer 0 draws OVER root's default canvas — so the backdrop
painted across the very widget it was staged to sit behind. Probed both ways
(backdrop pushed behind; widget lifted into its own layer): identical
non-empty frames, 6919 sampled pixels above the backdrop in each, with
`party_strip.gd` drawing its header, five rows, portraits, HP bars and slot
tags exactly as written.

**2. "Controller first is violated everywhere" — mostly not true.** The survey
pinned every frame but one to the keyboard. `game_state.gd` seeds
`_last_input_was_gamepad` from whether a joypad is connected; under `xvfb-run`
none is, so every glyph in the set rendered its keycap half. The ROG Ally's pad
is an always-connected XInput device, so the owner's own hardware draws pad
glyphs from the first frame and never shows most of what round 1 was looking
at. The starter picker's arrow keycaps, the dialogue panel's "E", combat's
mouse icon / "F" / `[C]` were all this. `dialogue_panel.gd` and
`starter_picker.gd` were checked directly and needed no change: both already
route through `input_glyph.gd::icon()` and redraw every frame.

**3-5. The empty minimap, the black world map and the missing reticle were one
line.** The survey mounted the world with `root.add_child(world)` and never set
`current_scene`. Four separate systems resolve the world through
`get_tree().get_current_scene()`:

- `playground_hud.gd::_ensure_minimap_baked()` — so `map_baker.gd::bake_cached()`
  never ran and the minimap drew its frame, fog and markers over the live 3D
  view with no terrain under them ("a frame around sky").
- `tab_map.gd::_draw_map` — same bake, so the full map had no terrain either.
- `playground_hud.gd::_combat_is_running()` — so during the survey's own fight
  the exploration HUD believed no fight was happening and kept drawing over the
  combat HUD.
- `game_menu.gd::_set_world_hud_visible()` — which already hides the HUD when
  the pause menu opens, and which silently did nothing. **The "HUD bleeds
  through the pause menu" defect had a correct fix in the codebase the whole
  time.** A second visibility gate was written for it before that was found,
  and reverted.

**6. `11-capture-reticle` had no reticle.** The survey's camera is the current
one and was framed for the exploration shot; teleporting the player into the
practice cluster does not carry it along, and the rig camera `_aim_at` steers
is neither current nor processing. `combat_hud.gd::_update_capture_reticle()`
unprojects the target through `get_viewport().get_camera_3d()` and gives up
when it falls outside that frustum. The reticle was working; the camera was
pointed somewhere else.

The lesson is the ledger's own: **a fix that lives in one tool does not protect
the next tool that does the same thing.** `current_scene` is not optional
staging — it is the handle four unrelated systems use to find the world.

## What was actually wrong, and is now fixed

- **The shared pause footer led with the keyboard** on every menu tab
  (`{menu_confirm} / A  Select`) while every fixture panel already led with the
  pad (`Leave: B / Esc`). Two contradictory conventions, and the one on the
  screen a player sees most often was the wrong way round. Now controller-first
  everywhere, `{action}` substitution kept so a rebind cannot make the legend
  lie. Same for the satchel's two footer overrides.
- **The settings keybinding table listed Keyboard/mouse first.** Columns
  swapped, and the left/right focus-neighbour chain swapped with them —
  reordering the cells alone would have left controller navigation walking the
  columns in an order that no longer matched what is drawn.
- **Dev toggles led the shipping settings menu.** "Free build" and "Debug
  teleport" are now deferred to the end of the page regardless of JSON order.
- **The Day-1 quest log printed the chapter's ending.** All 22 authored steps,
  flat and equally weighted, through "Defeat the Meadows Warden". Now: finished
  history, the open step (loudest thing on the page), and one step of
  look-ahead. A fresh save is two rows instead of twenty-two. The whole tab is
  in a `ScrollContainer`, which is both the missing affordance and the fix for
  the clipped last line. `objectives.json` and `quest_log.gd` are untouched.
- **The quickbar cut "40/40" mid-glyph.** A tool slot drew a 28px icon and its
  durability on one line — about 119px of content in roughly 104px of slot,
  with `scroll_active = false`. The icon moved to its own line and slots grew
  taller. Height, not width: `smoke_prompt_hotbar_dock.gd` fails the build if
  the dock reaches the central focus lane, which leaves about 8px of slack.
- **Craft rows drew past themselves.** A row is a `Button`, not a `Container`,
  so it never grew for its word-wrapped cost line while the VBox kept
  positioning siblings by the declared minimum — and the next row, painted
  later, drew over the overflow. All four reported symptoms had one cause.
- **The creatures tab overflowed its rows and framed fur.** 404px of
  fixed-width children in a ~260px column, overflowing under the viewport
  added later in the row. The preview camera claimed to copy
  `starter_picker.gd`'s framing and had drifted tighter than it. The roster now
  draws the same real portraits the HUD does, over the swatch, instead of
  running a second identity system.
- **The map printed its callouts through their own column headings.** A
  callout's glyph top lands at `label_y + 12 - descent - ascent`; the spread
  started at a flat 42 while the heading occupied roughly y=4 to y=34. About
  19px of overlap in every map frame. Now derived from live font metrics.
- **The same creature was named in three places during a fight.**
  `combat_hud.gd` mounts its OWN independent `party_strip.gd` instance and
  draws the active creature's name/level/HP/energy again in its ally panel,
  while the exploration HUD kept drawing both underneath. The creature block
  and party strip now stand down for the length of a fight. The minimap and
  objective block deliberately do not — combat draws no equivalent, and hiding
  them would remove information nothing replaces.
- **An unlabelled 800x12 pill floated bottom-centre of every gameplay frame.**
  `_prompt_label` carries a backing plate so the contextual line reads over
  grass, but `fit_content` only collapses the TEXT when the string is empty,
  not the plate's own 6px content margins. Gated on the text being non-empty.

## What is NOT a defect, stated so a later round does not re-open it

**The world map being a black column is correct.** `world_bounds` is 2048m
across and 8192m deep — a 1:4 portrait world fitted into a landscape panel,
with the callout columns using the space either side by design. Fog is opaque
on unexplored ground on purpose (`tab_map.gd`'s note on spec 16: the map "does
not reveal everything automatically"). What WAS wrong is that the survey
photographed it with a single 55m circle revealed in that world — roughly a
thousandth of a percent — so there was no fog edge, no terrain and no
discovered region to judge. It now reveals the road corridor the chapter's
first hour walks, which is the same POPULATION rule the ledger already applies
to inventories and quest logs.

## Deliberate trade-off, recorded rather than buried

The hotbar panel also stops being drawn during a fight. When combat starts the
exploration legend and prompt both vanish, the bottom dock collapses downward,
and the hotbar lands directly on combat's own move grid and orb readout — both
anchored bottom-right, neither able to move without taking the central focus
lane `smoke_prompt_hotbar_dock.gd` guards.

The BINDINGS are untouched. `ralph/OWNER_DIRECTIVES_2026-08-22.md` keeps the
d-pad on hotbar 2-5 in every context "so food and orbs stay reachable
mid-fight", and `_read_hotbar_input()` still polls through a fight. But a bar
the player cannot see is harder to use than one they can. If a later blind
round says the fight gives no way to find a potion, the fix is to move combat's
grid, not to restore this panel where it is.

## Outside this lane's file list

`tests/smoke_settings.gd` was edited. Its focus-graph walk hard-coded
Keyboard/mouse as the leftmost binding column, which the Controller-first swap
invalidated: from row 0's gamepad cell, D-pad Left can no longer reach a
keyboard cell, because gamepad IS the leftmost column now. The walk's shape and
every assertion it makes are unchanged — only which column each step expects
moved with the screen. The alternative was shipping a red branch or reverting a
hard-rule fix.

## Tests

`smoke_menu.gd`, `smoke_settings.gd`, `smoke_exploration_legend.gd`,
`smoke_combat.gd`, `smoke_prompt_hotbar_dock.gd`,
`smoke_hud_handheld_legibility.gd`, `test_quest_log.gd`, `test_party.gd`,
`smoke_creature_control.gd`, `smoke_evolution.gd` — all pass.

Measured baseline for the convergence rule:
`shots/_rounds/ui-round2/frame_stats.txt`.

## Round 2 blind verdict

Pending — appended below when the critic reports.
