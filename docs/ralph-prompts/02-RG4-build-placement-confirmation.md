# RG4 — Build placement confirm fails from the real build flow

## Objective
Fix the player-facing build bug where a buildable can be selected, its placement ghost appears correctly, the ghost can be moved and rotated, and the spot is visibly legal/valid, but the final placement action usually does nothing.

This is a **core gameplay blocker**. The player cannot reliably build even with Free Build enabled.

## Owner-confirmed behavior
The original backlog report said builds would not place except for the workbench. The owner has since clarified the real behavior:

- The workbench is **not reliably working** either; it placed successfully only once.
- In normal play, essentially every buildable fails at the final placement step.
- The build menu selection succeeds.
- The ghost appears in the world.
- The ghost can be repositioned normally.
- Rotation still works.
- The ghost visibly indicates a viable/legal placement position.
- Pressing the control shown by the UI to place does not commit the object.
- The owner also tried other controller buttons in case the prompt/binding was wrong; none caused placement.
- The problem is therefore not adequately explained by “the wrong button is shown” or “all build-mode input is dead.”

Treat the single successful workbench placement as evidence that the underlying spawn/placement machinery can work, not as evidence that workbench has a different intended code path.

## Important current-code context
Inspect current `main` before changing anything. At minimum read:

- `scripts/build/build_placer.gd`
- `scripts/ui/build_menu.gd`
- `scripts/ui/input_owner.gd`
- the current input mappings in `project.godot`
- `data/items/buildables.json`
- `tests/smoke_free_build.gd`
- other build/input regression tests that touch the build menu, placement, controller navigation, input ownership, or D34 behavior
- `docs/decisions/D34` and any newer decision/docs referenced by the current build scripts

The current placer has a deliberate `arming never places` safeguard using `_armed_last` / `_place_blocked`. That exists to prevent the same press that selects a piece from immediately planting it. Do **not** simply delete or bypass that safeguard unless measurement proves it is the root cause and the replacement preserves the original requirement: selecting a piece must never auto-place it.

The current build menu is intentionally live over the world and participates in `input_owner.gd`. The placer also refuses action changes while another input owner is active. Verify the ownership lifecycle around selection → menu close → ghost active → fresh place press.

## Critical warning about existing test coverage
Do not trust a green `smoke_free_build.gd` as proof that this bug is absent.

The existing smoke suite performs significant placement checks by directly assigning `GameState.pending_build` in code and then injecting `build_place`. That bypasses the exact handoff the player is reporting as broken:

**real controller → Build menu → select piece → Build menu closes → ghost appears → fresh controller place press → piece commits**

A test that starts after `pending_build` is already armed can remain green while the real gameplay path is broken.

The test suite itself has already documented a similar historical false-negative around placement: a synthetic sequence missed the same-frame select/place behavior until the input was modeled more faithfully. Treat that as a lesson for this task.

## Required investigation — reproduce before fixing
Start by reproducing the failure on current `main` through the real user path. Do not start with a speculative patch.

### Target input path
Use real joypad events through the live `InputMap` wherever the UI/focus layer is involved. Do not use `InputEventAction` as a substitute for actual controller input when proving a UI/controller bug.

Exercise this exact sequence:

1. Start in the Meadows playable world.
2. Enable Free Build if useful to remove material affordability from the test.
3. Open the actual build UI using the same route available to the player.
4. Navigate the real build menu with joypad input.
5. Select a buildable using the real controller confirm input.
6. Verify the Build menu closes.
7. Verify the correct `pending_build` id is armed.
8. Verify the ghost exists.
9. Verify the ghost reaches a legal state (`_ghost_ok` / equivalent actual state), not merely a visually green approximation.
10. Rotate the ghost at least once with controller input and prove rotation is received.
11. Release all selection/confirm inputs fully.
12. Send a **fresh** real controller placement input matching the current advertised control.
13. Verify whether `_place()` is reached and whether a placed-world node actually appears.

Run this sequence repeatedly. The owner observed intermittent behavior, so a single successful iteration is not enough.

### Buildable coverage
Do not diagnose this from one catalogue item. Exercise representative entries from each actual placement path, including at minimum:

- a generic geometry piece such as wall/floor/fence/roof/door as available in the current catalogue;
- workbench;
- camp;
- storage;
- any other stateful/special buildable currently listed in `STATEFUL_IDS` or its current equivalent.

Then run the final regression across **every buildable currently exposed by `data/items/buildables.json`** that should be placeable by the player.

## Instrument the real handoff
If reproduction is not immediately deterministic, add temporary diagnostic logging/assertions around the exact placement state transition. Capture enough state to answer these questions on the frame of selection, the first ghost frames, and the attempted place press:

- What physical joypad event entered the tree?
- Which InputMap actions report pressed / just-pressed?
- What is `GameState.pending_build`?
- What is `_armed_last`?
- What is `_place_blocked`?
- Is `build_place` still considered held from menu selection?
- Does `_place_blocked` ever clear after the selection button is released?
- What does `INPUT_OWNER.current(get_tree())` return?
- Is the Build menu still registered as an active input owner after its visual close?
- Is the pause/game menu or another panel unexpectedly the current input owner?
- Is `_ghost_ok` actually true on the attempted placement frame?
- Is `_ghost_reason` empty or does validity change between render/process/physics frames?
- Does `Input.is_action_just_pressed(PLACE_ACTION)` become true?
- Is `_place()` entered?
- If `_place()` is entered, which subsequent gate refuses the spawn (cost, collision, catalogue lookup, parent/world state, etc.)?

The goal is to identify the first state in the real sequence that differs between a successful placement and a failed one.

## Likely areas to investigate, not assumptions to hard-code
Current evidence makes the shared confirm/handoff path more suspicious than individual recipes or meshes because movement/ghost rendering/rotation continue to work.

Investigate, in evidence order:

1. `_place_blocked` release semantics after a real controller selection.
2. Whether the same physical button participates in both UI confirm and `build_place`, and how `just_pressed` / held state crosses the menu-close boundary.
3. Whether the UI prompt advertises an action that differs from the action `build_placer.gd` actually polls.
4. `input_owner.gd` ownership persisting for one or more frames after the Build menu closes.
5. Process-vs-physics timing between Build menu close, focus release, `pending_build` arming, and place polling.
6. Any controller-specific trigger/axis behavior if `build_place` is mapped to an analog trigger rather than a digital button.
7. Only after the above, piece-specific spawn/catalogue/collision logic.

Do not assume the root cause is `_place_blocked`; prove it.

## Fix requirements
Implement the smallest robust fix at the correct shared layer.

The finished behavior must satisfy all of these:

- Selecting a piece from the Build menu never places it automatically.
- After selection, the player always gets a visible placement ghost before construction.
- A fresh placement press after selection reliably commits a legal ghost.
- Rotation, snap, fine rotation, cancel, and other build controls continue working.
- Invalid/red placement still refuses construction.
- Free Build bypasses costs only; it must not bypass placement validity or alter input behavior.
- Normal paid building still consumes the correct resources exactly once.
- A successful placement clears/disarms the pending piece according to current intended behavior; do not accidentally enable uncontrolled repeat placement unless the existing design explicitly requires it.
- Build-menu input must not leak into the world while the menu is open.
- World/build input must become available promptly and deterministically after the Build menu closes.
- Controller and keyboard/mouse behavior must both remain functional.
- Do not create a second placement system or piece-specific hacks.

If the underlying bug is an input ownership or button-edge lifecycle problem shared with other panels, fix it at the shared abstraction where appropriate rather than adding a special-case delay for one buildable.

## Regression test — this is part of the fix
Add or strengthen automated coverage so the exact owner-reported path cannot regress.

The regression must:

1. Use the actual Build menu.
2. Navigate/select with real joypad events through the live InputMap.
3. Never directly set `pending_build` for the core reproduction/acceptance path.
4. Confirm the menu has closed before attempting placement.
5. Confirm a ghost exists and is legal.
6. Confirm rotation input still works before placement.
7. Fully release the selection input.
8. Send the fresh real placement input.
9. Confirm the expected world node appears.
10. Confirm the placed node has the expected buildable identity/type.
11. Repeat the select → ghost → place cycle enough times to expose timing/intermittent failures.
12. Cover every currently player-placeable catalogue entry, or use a data-driven loop that fails with the exact offending buildable id.

Keep the existing direct-arming tests if they cover useful lower-level behavior, but label them honestly as lower-level tests. They cannot be the sole proof of this player-facing flow.

Also add a focused regression for the `arming never places` rule so the RG4 fix does not reintroduce the historical auto-place bug.

## Verification
Run all relevant existing tests plus the new real-flow regression. At minimum run the build/free-build/menu/controller/input-owner suites touched by the change.

If the repository has a standard full headless test command, run it as well.

Perform a manual controller verification on the playable scene if the environment supports it. Record the exact input sequence and buildables exercised.

## Acceptance criteria
RG4 is done only when all of the following are true:

- From the real Build menu, a controller can select a piece, see the ghost, rotate it, and place it at a legal position.
- This works reliably across repeated attempts, not merely once.
- Every buildable currently exposed to the player can be placed through that same flow.
- Workbench is no longer a special anecdotal success case; it uses the same reliable placement contract as the rest.
- A legal ghost never silently ignores the advertised placement input.
- An invalid ghost still refuses placement for an explicit, correct reason.
- Selecting a buildable does not auto-place it.
- Existing build rotation/snap/grid/cost/save behavior remains intact.
- Automated regression coverage models the actual controller/menu handoff rather than bypassing it with direct `pending_build` assignment.

## Definition of done / handoff note
When finished, report:

- exact root cause;
- files changed;
- why the old tests missed it;
- the real controller event/action mapping involved;
- whether the fix was in placement, input ownership, menu handoff, InputMap, or another layer;
- new/updated regression tests and how many repeated real-flow cycles they execute;
- every buildable verified;
- commands/tests run and their results;
- any remaining controller-only risk that could not be exercised headlessly.

Do not close RG4 based only on code inspection or a green pre-existing smoke test. The acceptance standard is the owner’s real path working reliably.