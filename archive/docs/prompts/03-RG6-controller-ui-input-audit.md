# RG6 — Controller/UI input contract audit

## Objective
Fix the controller-navigation and controller-action failures that still exist across Tetherbound's dialogue, naming flow, pause-menu tabs, settings, and other menu/panel surfaces.

This is not a request to patch one named Button. The owner has now clarified that the problem is broad and should be treated as a controller/UI contract audit across the game.

Tetherbound is controller-first and primarily played on a ROG Ally. Any visible controller action prompt must work reliably when the player presses the indicated physical control. Any menu that presents selectable controls must be completely traversable and operable without reaching for a mouse or physical keyboard, except where actual text entry intentionally invokes a text-entry surface.

## Owner-confirmed failures
The owner has personally observed all of the following on current builds:

1. **Opening Grandpa dialogue** sometimes does not advance when the player presses the prompted dialogue/interaction control.
2. **Other talking NPCs** also do not always advance reliably.
3. **Creature naming** is unpleasant/unreliable using the game's opening/on-screen keyboard. The device/real keyboard path is substantially better. Do not regress the working real/device-keyboard path; make sure the controller path is genuinely usable as well.
4. **Settings tab navigation is broken**: once inside Settings, D-pad Down and left-stick Down do not reliably move focus down through the settings controls.
5. The owner suspects similar failures throughout the rest of the pause/menu surfaces, including **Creatures, Items/Backpack, Map, Build, and other tabs/panels**.
6. Owner's rule: **every action shown on a menu screen must actually do what the screen says when that controller action is pressed.**

The backlog originally described RG6 only as “Menus still do not read every input” and was blocked because no exact repro was supplied. It is now unblocked: the examples above are concrete reproductions, and the owner explicitly wants the remaining menu surface audited rather than waiting for him to discover every broken control manually.

## Current architecture and important evidence
Read these before changing code:

- `CLAUDE.md`
- `docs/AGENT_WORKFLOW.md`
- `scripts/ui/game_menu.gd`
- `scripts/ui/menu_tab.gd`
- `scripts/ui/tab_settings.gd`
- `scripts/ui/tab_backpack.gd`
- `scripts/ui/tab_creatures.gd`
- `scripts/ui/tab_map.gd`
- `scripts/ui/tab_build.gd`
- `scripts/ui/dialogue_panel.gd`
- `scripts/ui/name_prompt.gd`
- `scripts/ui/name_entry.gd`
- `scripts/ui/build_menu.gd`
- `scripts/ui/shop_panel.gd`
- `scripts/ui/craft_panel.gd`
- `scripts/ui/storage_panel.gd`
- `scripts/ui/swap_panel.gd`
- `scripts/ui/input_owner.gd`
- `scripts/ui/input_glyph.gd`
- `scripts/ui/key_bindings.gd`
- `project.godot`
- `data/config/menu.json`
- existing menu/input smoke tests, especially any tests documenting UI-PAD1 / OW10 / TEST2 lessons.

Important current-code claims that must be verified against real behavior rather than trusted:

- `game_menu.gd` says the menu is **CONTROLLER FIRST** and that everything selectable should be a focusable Control driven by Godot `ui_*` actions.
- `tab_settings.gd` says **EVERYTHING HERE IS REACHABLE WITH A STICK ALONE**.
- `dialogue_panel.gd` advances by polling `Input.is_action_just_pressed("interact")` and includes guard/buffering logic around opening presses.
- `name_prompt.gd` intentionally has two text-entry surfaces: a gamepad-driven on-screen grid and a real `LineEdit` for keyboard input.
- The project has already learned that synthetic `InputEventAction` / direct `Input.action_press()` tests can produce false confidence for UI focus because they do not necessarily exercise the live joypad→InputMap→Control path. Do not repeat that mistake.

## Required investigation
Before fixing anything, inventory every player-facing UI/input surface that can be reached in a normal Meadows play session.

At minimum include:

- Grandpa opening dialogue
- ordinary NPC dialogue
- trader/shop flow
- starter selection
- creature naming
- pause menu shell
- Backpack / Items
- Creatures
- Map
- Build tab
- Build selector
- Settings
- Save
- Quest Log if currently present
- crafting panels
- storage panels
- creature bed / swap panels if currently reachable
- any other modal or panel discovered during the audit that displays controller glyphs or expects controller focus/navigation

For each surface, build a small input contract table during diagnosis:

- how the surface opens
- expected focused control on entry
- D-pad Up/Down/Left/Right behavior
- left-stick navigation behavior
- confirm/accept behavior
- cancel/back behavior
- tab left/right / bumper behavior where advertised
- any contextual action displayed by a glyph or footer
- whether holding a direction should repeat
- what focus should become after an action changes/rebuilds the screen

Then drive the actual surface with **real joypad input events through the live InputMap** and compare actual behavior to that contract.

## Specific repros that must be captured
### A. Dialogue advance
Reproduce Grandpa's opening conversation and at least one ordinary NPC conversation using the real controller interaction button.

Test repeated line advancement, including:

- normal deliberate taps
- taps shortly after the dialogue opens
- several consecutive lines
- final-line close
- reopening another conversation afterwards

The existing open-guard / buffered-input logic may or may not be the defect. Measure it. Do not remove guards blindly and reintroduce the original “opening press also advances” bug.

### B. Settings vertical navigation
Open the actual pause menu, navigate to Settings using the controller, then attempt to traverse the Settings screen from its initial focus using both:

- D-pad Down/Up
- left-stick Down/Up

The player must be able to reach every enabled actionable setting/control and return back through the list. Scrolling must follow focus when the focused control moves outside the visible area.

Inspect focus neighbors, Control focus modes, dynamic rebuild behavior, ScrollContainer behavior, disabled/hidden controls, and whether some child is swallowing `ui_down` / `ui_up`.

### C. All pause-menu tabs
From the live pause shell, fully traverse every current tab using a controller only.

For every visible prompt/action, press the action the UI says to press and verify the expected result actually occurs.

Do not limit this to navigation. Confirm buttons, contextual actions, bumpers/tab switching, back/cancel, assignment/use/drop/etc. actions all belong in the audit when the UI advertises them.

### D. Creature naming
Preserve the working real/device-keyboard text-entry path.

Audit the controller/on-screen naming path as a real handheld flow:

- D-pad navigation
- stick navigation
- held-direction repeat
- letter selection
- delete/backspace
- case/special controls if present
- confirm/done
- initial/final focus behavior
- switching between controller and real keyboard if the current design supports it

The goal is not merely that unit tests pass. The controller naming experience must be practical enough that a ROG Ally player can name a creature without needing the device keyboard. The real/device keyboard should remain available and preferable for players who choose it.

If the current on-screen layout or navigation behavior is the source of the poor experience, improve it within the existing visual/design language rather than deleting controller text entry.

## Implementation principles
1. **Fix shared causes at the shared layer.** If several screens fail because of InputMap, focus-neighbor, input-owner, focus-restoration, or event-consumption behavior, repair the underlying contract rather than adding unrelated special cases to every tab.
2. **Do not replace controller-first UI with mouse dependency.**
3. **Do not hard-code around one ROG Ally instance.** Use Godot's standard joypad/InputMap semantics so normal XInput-style controllers behave consistently.
4. **Visible glyphs are promises.** A glyph/footer/prompt must be derived from or consistent with the action that actually performs the operation.
5. **Focus must never disappear silently.** Opening a menu, switching tabs, rebuilding dynamic contents, closing a subpanel, or changing settings must leave a sensible actionable Control focused when one exists.
6. **Hidden/disabled controls must not trap navigation.**
7. **Do not regress keyboard/mouse support.** Controller-first does not mean controller-only.
8. Preserve deliberate existing input guards unless diagnosis proves they are wrong; several were added to prevent same-frame input bleed.

## Testing requirements
Add or strengthen regression coverage so this class of defect cannot remain green while failing on a handheld.

### Real joypad events required
For controller UI tests, inject real `InputEventJoypadButton` / `InputEventJoypadMotion` through `Input.parse_input_event` (or the repository's established equivalent) so the event goes through the live InputMap and Godot Control focus system.

A test that only uses `InputEventAction`, directly calls a menu method, directly `grab_focus()`es the destination control, or calls an action handler without traversing the actual UI is insufficient as the primary regression proof.

### Minimum regression coverage
Create/extend smoke coverage that proves at least:

- Grandpa dialogue advances through several lines from real joypad presses.
- another NPC dialogue does the same.
- Settings can be entered from the real pause menu and traversed vertically with D-pad.
- Settings can also be traversed with left-stick input.
- every current pause-menu tab can be reached from the tab rail with controller input.
- each tab has at least one meaningful advertised action exercised where applicable.
- Build tab/selector navigation and cancel remain functional.
- creature naming grid can enter a short name, delete a character, and confirm using controller only.
- real keyboard name entry still works.
- menu cancel/back returns to the expected prior surface without leaving dead focus or dead world input.

Prefer a reusable menu/input audit harness over dozens of bespoke mini-tests if the architecture supports it.

## Acceptance criteria
RG6 is done only when all of the following are true:

1. Grandpa dialogue reliably advances and closes with the prompted controller action.
2. Ordinary NPC dialogue reliably advances the same way.
3. Settings is completely navigable vertically with both D-pad and left stick.
4. Every enabled actionable Settings control can be reached without a mouse/keyboard.
5. Every current main-menu tab is navigable with controller input.
6. Every visible controller action prompt tested during the audit performs the action it claims.
7. Creatures, Backpack/Items, Map, Build and all other current tabs/panels have no known dead controller actions or focus traps.
8. Creature naming is usable with controller only, while the real/device keyboard path remains working.
9. Focus survives tab switches, dynamic rebuilds, subpanel opens/closes, and returning from settings/actions.
10. Keyboard/mouse behavior is not regressed.
11. Automated regression uses real joypad events through the live InputMap for the controller cases.
12. The audit records which UI surfaces/actions were checked so a future new menu can follow the same contract.

## Definition of done
- Root causes identified and fixed, favoring shared infrastructure fixes where appropriate.
- Full controller/UI surface audit completed for current Meadows-accessible UI.
- Real joypad regression coverage added/updated and passing.
- Existing relevant tests still pass.
- No visible menu glyph/action is knowingly nonfunctional.
- ROG Ally/controller-only navigation can complete dialogue, naming, settings, menu traversal and menu actions without reaching for a mouse or keyboard, except optional text entry when the player chooses the real/device keyboard.
- Document the important input/focus invariant in the appropriate existing conventions/decision location if the fix establishes a new shared rule.
