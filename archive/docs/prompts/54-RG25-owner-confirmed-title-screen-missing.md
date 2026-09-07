# RG25/EV9 Phase -1.7 — Title screen is still absent in the owner's played build

## Current owner reproduction
On the 2026-08-18 evening ROG playtest, the game still launches without a proper menu screen.

Owner requirement is unambiguous:
- launch -> title/front door;
- **New Game**;
- **Load Game**;
- a normal way to **Quit Game**.

This is no longer a `verify whether title landed` task. The owner has verified it did **not** exist in the build he played. Inspect current `main` in case code landed after that build, but acceptance is the exported player path, not presence of a scene file.

This prompt tightens `27-RG25-title-save-select-quit-and-boot-measurement.md` and coordinates with `20-EV9-title-screen-and-orb-count-mounts.md`.

## Goal
Make the game's boot/front-door flow feel like a normal shipped game while preserving save semantics and improving perceived/actual load responsiveness.

## Required boot flow
1. Process starts.
2. A lightweight branded title/front-door scene becomes interactive without constructing the full Meadows first.
3. Player can choose:
   - New Game;
   - Load Game;
   - Quit Game.
4. Selecting New/Load enters a responsive loading transition.
5. World constructs/loads.
6. Player reaches the correct opening or saved position with controls active.

Do not boot directly into Meadows behind the title and simply hide it with CanvasLayer if that keeps paying world startup before the menu can respond.

## Inspect first
- `project.godot` `run/main_scene`
- current title/menu scenes, if any
- `autoload/game_state.gd` startup behavior
- save slot APIs and `save_game.gd`
- current five-slot UI/menu code
- EV9 wordmark/display-style assets
- boot log/instrumentation
- world loading entry point
- return-to-title / quit paths if partially implemented
- controller UI/focus helpers

## Title presentation
Use existing Tetherbound art direction/EV9 style guide.

At minimum:
- TETHERBOUND wordmark/title;
- New Game;
- Load Game;
- Quit Game;
- clear focus state at ROG handheld scale;
- dynamic or established controller glyph/help as appropriate;
- no placeholder debug look.

Do not block this on new external art if existing references/EV9 can produce a coherent screen.

## New Game
- create/reset a genuinely fresh run through existing state APIs;
- enter the real opening sequence;
- do not inherit flags/party/world state from a previously loaded session;
- if an existing save would be overwritten, follow current save-slot policy/confirmation rather than silently destroying it.

## Load Game
Load should lead to a save-select surface that shows the project's existing slots and enough metadata to choose safely.

Requirements:
- empty slots visually distinct/non-loadable;
- selected slot focus clear with controller;
- load exact slot chosen;
- restore position/facing/progression according to RG7;
- back/cancel returns to title;
- no stale session state from previous load.

If the existing save screen already lives in the pause menu, reuse its data/components where clean; do not create competing save-slot models.

## Quit Game
- title Quit Game cleanly exits Windows/exported game;
- pause menu while in world should also expose the already-requested quit/return flow from RG25;
- wording distinguishes `Return to Title` from `Quit Game` if both exist;
- protect unsaved progress according to existing save policy.

## Return to title / session reset
Critical regression:
- launch -> load Save A -> return title -> load Save B;
- Save B must not inherit Save A's transient world nodes, modal owners, pending catch, selected creature, placed runtime nodes beyond its own persisted state, day/session state where save says otherwise, etc.

Audit teardown rather than relying on a scene change that leaves autoload state dirty.

## Loading responsiveness
Use the existing boot log and prior RG25 performance prompt.

Measure separately:
- process launch -> title interactive;
- title -> New Game playable;
- title -> Load slot playable.

The title itself should be fast because it should not require Terrain3D/vegetation/world construction.

Show loading feedback after New/Load if legitimate wait remains; UI must not appear frozen.

## Input
Controller-first:
- focus lands on a sensible default;
- d-pad and stick navigate;
- A/confirm activates;
- B/back behaves consistently on submenus;
- no physical keyboard required;
- no input leaks into a world scene being loaded in the background.

## Tests / verification
Required exported-build sequence:
1. cold launch -> title appears and responds;
2. New Game -> real opening;
3. quit/return title;
4. Load Game -> choose valid slot -> saved position/progression;
5. return title;
6. choose a different save;
7. Quit Game -> process exits.

Add smoke coverage for front-door state and real joypad navigation where practical.

Record boot timings before/after on comparable hardware/environment.

## Acceptance criteria
1. Exported game no longer drops directly into Meadows.
2. Branded title screen is the first interactive game surface.
3. New Game works.
4. Load Game exposes/loads valid save slots correctly.
5. Quit Game exits cleanly.
6. Return-to-title/session switching does not leak prior run state.
7. Title is responsive without waiting for full Meadows construction.
8. Remaining world load shows understandable responsive feedback.
9. Controller can complete the entire front-door flow.
10. EV9 wordmark/title work has a real mount and no duplicate title implementation exists.

## Definition of done
A player launching Tetherbound sees a real front door and chooses whether to start, continue or leave before the expensive world is built.