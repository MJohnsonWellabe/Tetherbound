# BUILD-FLOW — Valheim-style persistent placement after each build

## Owner decision
The owner confirmed on the latest ROG playtest that **basic structure placement now works**. Preserve that fix.

The remaining problem is the interaction model: after placing one piece, the player should not be forced back into the Build menu to select the same piece again.

Locked behavior:
- choose a buildable once;
- enter placement mode;
- place it;
- immediately get another ghost of the **same buildable**;
- keep placing copies until the player cancels placement or deliberately selects a different buildable;
- this applies to **all buildables**, including floors, walls, roofs, doors, fences, workbenches, beds, storage, camp pieces and later unlocked buildables.

This supersedes the older RG4 prompt's caution that successful placement should normally clear/disarm the selected piece.

## Goal
Make construction feel like a real build mode rather than a repeated menu transaction, while preserving the now-working placement confirmation path and all cost/validity rules.

## Inspect first
- `scripts/build/build_placer.gd`
- `scripts/ui/build_menu.gd`
- `autoload/game_state.gd` / `pending_build`
- `data/items/buildables.json`
- cost/payment code
- grid/snap/rotation code
- build-control hint strip
- save/placed-building registry
- free-build preference
- tests around arming, placement, menu input and save/load

## State model
Do not solve this by repeatedly reopening the menu or synthetically re-pressing selection.

After selecting a buildable, placement mode should own a stable **selected buildable id** until explicit exit/change. One placement consumes/records exactly one piece but does not erase the selection.

If current `pending_build` semantics mean `one pending transaction`, either cleanly generalize the state or keep a separate selected-build id. Do not overload a variable in a way that makes save state or menu code ambiguous.

## Required behavior
### Successful placement
1. Legal green ghost is shown.
2. Player presses Place.
3. One real piece is created at the shown transform.
4. Cost is charged exactly once unless Free Build.
5. Piece is registered for save/load exactly once.
6. A fresh ghost of the same id immediately becomes active at the next candidate location.
7. Rotation/snap settings remain useful; do not unexpectedly reset orientation after every piece unless existing Valheim-like behavior/documentation says so.

### Invalid placement
- remains refused;
- selected piece remains active;
- player can reposition/rotate and try again.

### Insufficient materials
- do not create a piece;
- give clear feedback;
- do not silently drop out of build mode unless the player cancels;
- if keeping the ghost active would be confusing, indicate unaffordable state clearly through existing feedback.

### Cancel
- B/right-click/current `build_cancel` exits placement entirely;
- ghost disappears;
- selected buildable clears;
- normal exploration controls return without opening another menu automatically.

### Change piece
Player can reopen Build while placement is active and choose another piece. The new selection replaces the old one cleanly and returns to placement without an input-edge auto-place.

## Controller / action-edge requirement
The historical RG4 defect involved select -> menu close -> fresh placement input. Preserve the rule that the same confirm press used to choose a piece **cannot also place it**.

Persistent mode must also require a fresh Place edge for every copy. Holding the Place button/trigger must not machine-gun structures each frame.

## Coordination with BUILD-SNAP and BUILD-REMOVE
- `42-BUILD-modular-snap-contract.md` owns how pieces align.
- `41-BUILD-dismantle-full-refund.md` owns removal.

These should all feel like one construction mode, but do not turn them into one giant rewrite if separable changes are safer.

## UI
The placement hint strip should remain visible while persistent build mode is active and show:
- Place
- Rotate left/right
- Snap step/toggle if applicable
- Cancel
- Dismantle/remove once that prompt lands
- a discoverable way to reopen/change the selected buildable

Use dynamic glyphs from the existing input glyph system.

## Acceptance tests
Automate the production flow with real controller events:
1. open Build;
2. select Floor;
3. place Floor A;
4. verify floor selection remains active and a new floor ghost exists;
5. reposition and place Floor B without opening Build;
6. place Floor C;
7. cancel;
8. verify ghost gone and exploration restored.

Repeat with a stateful/special object such as workbench or creature bed to prove the behavior is data/system-wide.

Verify paid mode charges each placement independently and refuses once resources run out. Verify Free Build never charges.

## Acceptance criteria
- Base placement still works reliably.
- Every buildable remains selected after a successful placement.
- A fresh press places exactly one new object.
- Player may chain many pieces without reopening the catalogue.
- Cancel exits cleanly.
- Reopening Build during placement changes selection cleanly.
- Costs, collision legality, snapping, rotation, save/load and free-build semantics remain correct.
- No auto-placement occurs from the selection press.
- No post-modal freeze is introduced; coordinate with reopened RG1.

## Definition of done
Building a floor, wall line or roof run feels continuous: select once, place repeatedly, cancel when finished.