# EV9 — Title screen and HUD remainder mount points

## Goal
Finish the two EV9 presentation pieces that have been stranded because the game still boots directly into the world:

1. add a real controller-first **title / save-select screen** with the approved Tetherbound branding/wordmark treatment;
2. mount the already-produced `orb_capture.png` into a useful **orb-count HUD panel** during exploration.

This item is presentation/integration. Do not invent a second save system or regenerate art that already exists.

## Owner / backlog decisions — locked
- The owner approved a title screen.
- The old direct-boot decision (D18) is superseded by this newer direction; record that formally in a new decision entry rather than silently contradicting history.
- `assets/ui/icons/hud/orb_capture.png` already exists and is the EV9 capture-orb glyph.
- Current `playground_hud.gd` explicitly records that this icon has no mount because no orb-count panel exists.
- RG25 owns boot-performance measurement and also needs title/save-select/quit behavior. Coordinate rather than build competing front ends.

## Current systems to reuse
Inspect current `main` first:
- `project.godot` currently points `run/main_scene` directly at `meadows_playground.tscn`.
- `scripts/ui/tab_save.gd` already exposes five save slots (slot 1 autosave, 2-5 manual) and uses GameState's real `has_save`, `save_slot_info`, `save_game`, and `load_game` APIs.
- `autoload/game_state.gd` owns the save system and the global menu.
- `scripts/ui/playground_hud.gd` already builds the exploration HUD and tracks inventory/state every frame.
- `assets/ui/icons/hud/orb_capture.png` is already imported.
- Reuse the existing `UITokens`/theme/input-glyph conventions and Ally-native 1920x1080 authoring.

## Title screen behavior
Create the smallest coherent title flow:
- branded Tetherbound title/wordmark treatment using the approved EV9 assets/style already in repo;
- **Continue** when an appropriate save exists;
- **New Game**;
- **Load Game** / save-select using the same five slots and metadata as `tab_save.gd`;
- **Settings** only if current menu architecture can be reused cleanly without duplicating settings logic;
- **Quit** on Windows/ROG Ally.

Controller is primary: first focus must be obvious, d-pad/stick navigation and A/confirm/B/back must work, no mouse required.

Do not make the player enter the Meadows scene merely to inspect save slots. The title flow should decide which save/new-game path is being entered before normal world play begins.

### Save-select
Do not clone save parsing. Extract/reuse shared presentation helpers if necessary, but GameState/save_game remain the source of truth. Show enough metadata to distinguish saves (at least current day and party size as the existing Save tab already does). Empty slots must be visibly disabled/unavailable for load.

### D18 supersession
Add a decision doc using the next available D-number that says the old direct-to-world boot is superseded: Tetherbound now starts at a title/save-select screen. Preserve the old decision file as history if it exists; do not delete history to make the contradiction disappear.

## Orb-count HUD panel
Add a compact exploration HUD element using `orb_capture.png` and the actual count of the player's currently usable capture orbs.

Requirements:
- read from the existing inventory/item IDs; no separate counter state;
- update immediately when orbs are given, spent, crafted, bought, gathered, loaded, etc.;
- if multiple capture-orb tiers exist, present a truthful useful count consistent with current catching selection semantics rather than summing unrelated items blindly;
- readable on Ally at 1080p without competing with party strip, minimap, objective block, hotbar, or the permanent control legend from RG3;
- hide/fade with the exploration HUD in the same contexts the rest of that HUD hides/fades;
- use the commissioned orb icon rather than a text-only substitute.

Do not change catching balance or inventory capacity here.

## Preserve
- existing five-slot save format and migration;
- opening sequence behavior once a new game is entered;
- current pause menu and Save tab;
- existing UI theme/tokens;
- controller-first rules;
- EV9-produced art assets.

## Acceptance criteria
1. App launches to a real title screen instead of immediately placing the player in Meadows.
2. New Game reaches the normal opening sequence from a clean state.
3. Load/Continue use existing save files and select the intended slot.
4. Empty slots cannot be loaded.
5. Title screen is fully usable with ROG Ally controls.
6. Windows Quit exits cleanly.
7. A new decision formally supersedes the old direct-boot decision.
8. Exploration HUD shows the commissioned orb glyph plus the truthful current capture-orb count.
9. Orb count updates after inventory changes and after save/load.
10. No duplicate save parser/state or second inventory counter is introduced.

## Testing / verification
- existing save/load tests and `test_menu_data` / controller UI tests;
- focused title-flow smoke: new game, continue/load several slots, empty slot, back navigation, quit path mocked where necessary;
- focused HUD test that inventory orb changes are reflected;
- real joypad events, not only `InputEventAction`;
- capture title and in-world HUD frames and run the normal visual-judge pass.

## Definition of done
EV9 is done when the two stranded presentation assets finally have honest homes: **the game opens through a branded, controller-first title/save-select flow, and the exploration HUD visibly tells the player how many capture orbs they actually have.**