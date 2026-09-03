# Controller/UI input audit

Gate A RG6 audit, 2026-08-20. Scope: every player-facing UI surface reachable
in the Meadows chapter. Controller assertions below enter the tree as
`InputEventJoypadButton` or `InputEventJoypadMotion` and travel through the
live `InputMap`; a named `InputEventAction` is not primary controller proof.

## Shared contract

- Opening a selectable surface focuses a sensible enabled action. A modal that
  deliberately polls one story verb (dialogue, starter choice, naming) must
  visibly select its current line/cell instead.
- D-pad and left-stick menu input use Godot's `ui_*` focus path. Hidden and
  disabled controls do not become focus stops.
- Rebuilding dynamic contents restores focus to the same logical row when it
  still exists, or the nearest enabled row when it does not.
- A visible glyph names the same InputMap action the implementation reads.
- A/B ownership belongs to the top visible modal. Closing it cannot leak the
  same B edge into the pause shell or leave the world paused behind no owner.
- Keyboard and mouse remain supported. Creature naming uses a real `LineEdit`
  for keyboard input and the on-screen grid for controller input; both share
  one name buffer.

## Surface contracts and evidence

| Surface | Open / entry state | Controller navigation and actions | Back / return | Regression evidence |
|---|---|---|---|---|
| Grandpa opening dialogue | Authored proximity handoff opens the real conversation; current line is visible | Physical Interact advances repeated lines, including post-open taps, and closes the final line | Story sequence owns the mandatory handoff | `smoke_opening.gd` |
| Ordinary NPC dialogue and Bram shop | Bram's real `Interactable` wins; dialogue then opens his service; first enabled shop row is focused | Physical Interact advances; D-pad changes rows; A buys the focused item | B closes Shop and immediately restores world control | `smoke_post_modal_control.gd` (three mixed cycles) |
| Starter picker | Opens after Grandpa; first orb is selected | Physical D-pad Left/Right changes orb and A chooses; confirm wins a same-frame direction/confirm tie | Mandatory story choice has no cancel | `smoke_starter_picker.gd`, `smoke_opening.gd` |
| Creature naming | Controller opens on the selected `A` grid cell; keyboard opens a focused `LineEdit` | D-pad and left stick move; held stick repeats; A types/activates OK; B deletes one character | OK confirms a non-empty name; keyboard Enter confirms exactly once | `smoke_name_prompt_controller.gd`, `smoke_name_prompt_keyboard.gd`, `smoke_opening.gd` |
| Pause shell / tab rail | Physical Inventory or B opens; current tab supplies its first enabled focus | D-pad moves focus; physical RB reaches all seven tabs and LB reverses; focused A performs the tab action | B closes, unpauses, restores mouse/world control; shell yields to higher modals | `smoke_menu.gd`, `smoke_modal_stacking.gd`, `smoke_post_modal_control.gd` |
| Backpack / Items | First usable slot is focused | D-pad moves slots; A uses and focuses the first eligible creature; Drop, Split, Move/Assign and target confirm all use their live physical bindings | B cancels a target/held stack/drop confirmation before closing the shell | `smoke_menu.gd`, `smoke_backpack_pad_target.gd` |
| Creatures | First creature row is focused | D-pad changes row; A pick-up then A on another row reorders the real party | B releases a pending action or closes through the shell | `smoke_menu.gd` |
| Map | Full-map canvas receives focus | Fixed-view v1 intentionally advertises no pan, zoom, or contextual action; LB/RB leave it through the tab rail | B closes shell | `smoke_menu.gd`, `tab_map.gd` fixed-view contract |
| Quest Log | Main Story list draws its current objective; tab retains a valid focus owner | No contextual action is advertised; LB/RB traverse normally | B closes shell | `smoke_menu.gd` |
| Build tab and Build selector | Build tab focuses Open Build Menu; handoff focuses the first enabled build cell | A opens selector; D-pad/category controls navigate; A arms the focused piece; placement stays active for repeat placement | B cancels selector/armed placement without reopening or freezing the shell | `smoke_post_modal_control.gd`, `smoke_build_menu_pad_pick.gd`, `smoke_menu_owns_dpad.gd`, `smoke_free_build.gd` |
| Save / Load | Save tab focuses slot 1 Save; empty Load buttons are disabled | Physical A writes an isolated slot; D-pad Right reaches newly enabled Load; physical A restores it | B closes shell; test restores the production save-system object and removes its isolated slot | `smoke_menu.gd` |
| Settings | Natural entry focus is the first keyboard binding | Physical D-pad reaches all 126 binding/gamepad/Default cells plus Free Build, Debug Teleport, global Reset and every visible teleport destination; physical left stick moves vertically; scrolling follows; A rebinds/activates | B cancels capture without changing it; shell-close rebind is guarded; panic chord/F10 resets | `smoke_settings.gd` |
| Craft | First known recipe is focused | Physical D-pad changes recipe; A crafts the focused affordable recipe, spends materials and retains focus after refresh | B closes and unpauses | `smoke_craft_panel_controller.gd` |
| Storage | First enabled inventory/storage row is focused | Physical D-pad changes row; A deposits/withdraws and the rebuilt list restores focus | B closes and restores the world | `smoke_menu_focus.gd` |
| Creature bed | First creature row is focused | Physical A changes Rest/wake state and the row remains actionable | B closes and restores the world | `smoke_post_modal_control.gd`, `smoke_menu_focus.gd` |
| Creature swap | First eligible party row is focused; confirmation focuses its confirm button | Physical A arms the selected swap | First B backs out and restores row focus; second B closes | `smoke_menu_focus.gd`, `smoke_village_trade.gd` |

## Finding and fix

The audit reproduced a real Settings defect at the first row after a variable-
height group note: D-pad Down skipped `interact`. The screen relied on Godot's
geometry search across headings and notes, so its claim that every row was
reachable was false. `tab_settings.gd` now wires an explicit vertical lane for
each binding column and explicit horizontal row neighbors. The gameplay,
debug-teleport, global-reset, and conditional destination controls join the
same graph. The exhaustive smoke walks every enabled control and verifies that
the `ScrollContainer` follows focus.

The separate Gate A modal checkpoint fixed the shared B-edge ownership races.
This audit retains that invariant and proves the controller path through the
affected panels rather than adding per-panel input exceptions.
