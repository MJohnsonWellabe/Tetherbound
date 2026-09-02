# RG14 — Verify build placement controls remain readable after piece selection

## Goal
Verify the current placement-mode control strip on current `main` solves the owner’s playtest complaint that once a build piece is selected and the Build menu closes, the player can no longer see how to place/rotate it.

Do **not** reopen or pin the Build menu during placement. The intended flow is still:
1. open Build menu,
2. choose a piece,
3. menu closes,
4. world placement mode takes over,
5. a compact placement legend remains visible until the piece is placed or cancelled.

## Owner report
“The placement/rotate controls are unreadable once a piece is selected.”

The underlying design issue was that the controls were readable in the Build menu, but the menu deliberately closes on selection, leaving the player to manipulate the ghost in the world.

## Current-main finding — verify before changing
Current `scripts/build/build_placer.gd` already appears to contain a later implementation that may have resolved this backlog item:
- lazy placement overlay (`CanvasLayer`),
- bottom-center `RichTextLabel` named `PlacementHints`,
- live `input_glyph.gd` glyphs,
- control text for Rotate / Snap step / Place / Cancel,
- overlay shown whenever an armed ghost is active,
- refusal reason prepended when a ghost cannot be placed,
- placement grid + snap dots remain separate world/overlay aids.

The current `_hint_text()` contract is effectively:
- Rotate
- Snap step
- Place
- Cancel

and `_position_hint_label()` anchors it near the bottom center of the viewport.

This means RG14 may already be landed on current main. Treat the old owner report as a reproduction target, not proof that the current code is still wrong.

## Required workflow
### 1. Reproduce on current main first
On the target handheld/controller configuration:
1. Open Build.
2. Select several different pieces.
3. Confirm the Build menu closes.
4. Confirm the ghost appears.
5. Confirm a placement control strip is visible immediately.
6. Rotate left/right.
7. Cycle snap step.
8. Move between legal and illegal placement spots.
9. Place.
10. Repeat and then cancel.

Check at the actual 1920x1080 authoring/stretch behavior used on the ROG Ally, not only desktop editor resolution.

### 2. If it is already good
Do not redesign it. Record verification and close RG14.

### 3. If it still fails
Fix only the actual failure. Likely classes include:
- strip is clipped/offscreen,
- strip is obscured by another HUD block,
- glyphs resolve incorrectly for controller,
- font/glyph size is too small on handheld,
- strip only appears after an input instead of immediately,
- overlay disappears while the ghost remains armed,
- invalid-placement reason causes the strip to overflow,
- controller/device switching leaves stale glyphs.

## Desired player-facing behavior
While a build ghost is armed, the player should always be able to answer four questions without reopening a menu:
- How do I rotate it?
- How do I change snap/rotation precision?
- How do I place it?
- How do I cancel?

The legend should be compact, legible, and secondary to the world view. It should not become a large tutorial panel.

Use the live binding/glyph system rather than hard-coded Xbox button letters so the strip stays truthful if bindings/device change.

If the ghost is invalid, keep the reason visible in the same strip without replacing the controls themselves. The player must see both **why** placement is blocked and **what buttons still work**.

## Preserve
- Build menu closes after selecting a piece.
- Current ghost workflow.
- Current placement grid and snap dots.
- Existing anti-same-press placement guard.
- Current rotate/snap/place/cancel actions.
- Current live input glyph system.
- Current invalid-placement reason behavior.
- World remains visible and controllable in placement mode.

## Do not
- Do not keep the Build menu open during placement.
- Do not duplicate the entire Build menu as an overlay.
- Do not hard-code controller button names.
- Do not move placement instructions into a one-time tutorial that disappears forever.
- Do not alter placement mechanics, costs, snapping logic, rotation increments, or confirmation semantics unless reproduction proves one of them is directly causing the legend failure.

## Acceptance criteria
1. Select a build piece from the Build menu.
2. Menu closes as intended.
3. Placement ghost is visible.
4. A compact control strip is immediately visible and readable on the target handheld screen.
5. Strip accurately shows live glyphs for Rotate / Snap step / Place / Cancel.
6. Legal and illegal placement both retain the control legend.
7. Illegal placement additionally communicates the refusal reason.
8. Device/binding changes do not leave misleading button labels.
9. Strip remains present until placement is committed or cancelled.
10. No overlap/clipping with existing bottom HUD at target resolution.

## Tests / verification
Retain/add smoke coverage that arms a real build through the normal Build menu selection path and asserts:
- placement overlay becomes visible,
- hint label is non-empty,
- required actions are represented,
- cancelling/placing hides the overlay,
- invalid placement preserves both refusal reason and controls.

Use real joypad-style input where practical, consistent with RG6/RG4 controller testing.

## Definition of done
RG14 is done when the player can choose a build piece, leave the menu, and still clearly see the placement controls for the entire ghost-placement interaction. If current main already satisfies that on the target device, make no unnecessary gameplay/UI changes and close the item as verified.