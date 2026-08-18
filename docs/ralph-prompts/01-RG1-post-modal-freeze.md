# RG1 — Post-modal freeze: trader and build menu exits

## Objective
Fix the intermittent failure where leaving certain menus returns the player visually to the world, but world control is dead. The two confirmed repro families are:

1. Leaving Mira's trader/shop flow.
2. Leaving the Build menu / completing the build-menu handoff.

When the bug occurs, the game is not globally hung: the player can still open the main/pause menu and navigate its screens. What is lost is control of the live world. Movement and normal world interaction stop responding, and the only practical recovery is quitting the game. The failure is intermittent rather than guaranteed.

Do not treat this as a generic "freeze" and do not accept a test that merely proves a direct `close()` call returns. Reproduce and fix the real controller-driven exit paths.

## Owner report
Original report:

> "The game seems to freeze a lot after coming out of an interaction or menu. Like interacting with the trader at the beginning then it freezes. Doing a build, then it freezes."

Clarification from the owner on 2026-08-18:

- When it occurs, you cannot move anything in the world.
- The player can still open the actual game/pause menu and navigate screens there.
- The only recovery is quitting the game.
- It happens only sometimes.
- Trader menu and Build menu are the two known problem paths.

This makes the likely class of defect an intermittent world-input ownership / input-edge / pause-state / mouse-capture restoration problem rather than a full engine lockup.

## Existing context you must inspect first
Read these before changing code:

- `tests/smoke_post_modal_control.gd`
- `scripts/ui/input_owner.gd`
- `scripts/ui/build_menu.gd`
- `scripts/ui/shop_panel.gd`
- `scripts/ui/game_menu.gd`
- the dialogue / sequence code that opens Mira's shop
- the HUD/world-input polling code that checks `input_owner.gd`
- any interaction-arbiter or modal-state code involved in dialogue/shop/build transitions
- `project.godot` bindings for `menu_cancel`, `build_cancel`, and related controller actions

Also read the RG1 section in `ralph/BACKLOG.md` and preserve any relevant project decisions documented in code comments or `docs/decisions/`.

## Critical flaw in the current RG1 regression test
The existing `tests/smoke_post_modal_control.gd` does not faithfully reproduce either confirmed owner path.

### Trader path mismatch
The current test drives the conversation and opens the shop, but closes the shop by calling `shop.close()` directly.

That bypasses the actual player path: pressing the real controller cancel action (`B` / `Esc`, via `menu_cancel`) while multiple input-processing systems may observe the same action edge in the same or adjacent frames.

A direct method call cannot prove that the controller-driven close path is safe.

### Build path mismatch
The current test does not open or exit the Build menu at all. It programmatically sets `pending_build = "workbench"`, plants a workbench with `build_place`, and checks control afterward.

That bypasses the exact surface named in the report. The Build menu already contains special logic around shared B-button bindings and `suppress_reopen()`, which is evidence that action-edge bleed/re-entry has been a real problem in this path before.

Therefore: a passing current smoke test is not evidence that RG1 is fixed.

## Reproduction requirements
Before implementing a fix, make the failure observable with a test/harness that follows real player input paths.

### Trader reproduction
Drive the real sequence:

1. Enter/start Mira's trader conversation using the real interaction path where practical.
2. Advance dialogue with real `interact` input.
3. Let the production sequence/effect path open the shop.
4. Exit the shop with a real `menu_cancel` input event — do **not** call `shop.close()` as the reproduction.
5. After the UI disappears, prove the world has actually regained control.

### Build-menu reproduction
Drive the real Build menu:

1. Open the Build menu through the normal gameplay action / normal production entry point.
2. Navigate/select a buildable through the same input-facing API the player uses.
3. Exercise both relevant exit shapes if they are distinct:
   - cancel/leave the Build menu with the real B/cancel action;
   - select a piece so the menu closes into placement, then complete/cancel placement as appropriate.
4. After the UI transition, prove the world has actually regained control.

Do not substitute direct state assignment such as setting `pending_build` for the Build-menu portion of this regression.

## Intermittency requirement
The owner says this happens only sometimes. A single successful run is insufficient.

Create or extend the regression so each known path is exercised repeatedly in one test run or through a deterministic stress loop. Use enough iterations to expose frame-order/action-edge/state-restoration races without turning CI into an unreasonable soak test.

If the failure can be made deterministic by controlling node/process order or holding/releasing the shared cancel action across frames, prefer that deterministic reproduction over brute-force repetition.

Record enough state on failure to identify the mechanism rather than only saying "player did not move."

At minimum capture/report:

- `SceneTree.paused`
- current `INPUT_OWNER.current(tree)` and the owning node name/path if non-null
- whether dialogue/shop/build/pause menu reports itself open
- `Input.mouse_mode`
- player process mode / whether the player node is processing physics/input if relevant
- any interaction-arbiter modal/lock state
- whether the cancel action remains pressed or is being observed as `just_pressed`/`just_released` unexpectedly
- any world-input suppression flags or reopen guards involved

## Root-cause expectations
Do not assume the trader and Build menu necessarily share the exact same bug. Diagnose first.

However, prefer a shared/systemic repair if both failures are caused by the same ownership/restoration contract. Avoid two unrelated one-off patches if the real issue is that modal surfaces do not have one authoritative lifecycle for:

- acquiring/releasing world input ownership,
- pausing/unpausing,
- restoring prior mouse mode,
- consuming/suppressing the action edge used to close a surface,
- restoring interaction-arbiter/world-control state.

Conversely, do not force a shared abstraction if measurements prove two separate defects.

Pay special attention to shared controller bindings and same-frame processing. `build_menu.gd` already documents that `menu_cancel` and `build_cancel` share gamepad B and uses `suppress_reopen()` because the same press could otherwise close one surface and immediately open another. Inspect whether an equivalent edge can leave the world suppressed, or whether a close path restores the wrong previous state after another surface changed it.

The fact that the main/pause menu can still open and navigate while world control is dead is high-value diagnostic evidence. Use it to distinguish:

- a paused tree,
- a stale input owner,
- a world/HUD-only suppression state,
- a player processing/input state problem,
- a mouse/camera capture problem,
- an interaction-arbiter/modal lock,
- an action-edge race between UI layers.

## Implementation constraints
- Preserve controller-first behavior and ROG Ally support.
- Do not solve this by removing the Build menu's live-world/Valheim-style behavior unless an existing project decision explicitly changes that requirement.
- Do not globally swallow B/Esc in a way that breaks legitimate cancel, flee, menu, dialogue, or placement behavior.
- Do not introduce arbitrary delays/timers as the primary fix unless you can prove timing itself is the intended contract.
- Do not make the regression pass by weakening its world-control assertions.
- Reuse existing shared input/modal infrastructure where it is correct; improve its contract if necessary rather than adding another per-screen special case.
- Preserve existing pause-menu, dialogue, shop, build-placement, hotbar, combat, and input-remapping behavior.

## Acceptance criteria
RG1 is done only when all of the following are true:

1. The trader/shop flow can be exited with the real controller cancel action and world control reliably returns.
2. The Build menu can be exited/handed off through the real controller path and world control reliably returns.
3. After either flow, the player can move in the world again.
4. Camera/world input is restored consistently where normal exploration expects it.
5. No stale `input_owner`, modal/arbiter lock, pause state, or equivalent world-input suppression remains after the UI is closed.
6. The main/pause menu still opens and behaves correctly after these transitions.
7. The fix does not reintroduce the known build-menu B-button reopen problem or menu/hotbar input leakage.
8. The regression test exercises the actual input-driven close paths, not direct close/state-assignment shortcuts.
9. The regression covers intermittency with deterministic race reproduction or repeated transitions.
10. Existing relevant tests remain green.

## Verification
At minimum run:

- the upgraded `tests/smoke_post_modal_control.gd`
- existing modal-stacking/input-owner tests
- existing Build-menu input/footprint/placement smoke tests relevant to the changed path
- existing shop/trade tests relevant to shop lifecycle
- existing general input smoke tests

Then manually or with a production-faithful harness verify repeated sequences such as:

- trader conversation → shop → B to leave → walk/look/interact → reopen trader → repeat
- open Build menu → B to cancel → walk/look → reopen → repeat
- open Build menu → select workbench → placement → place/cancel → walk/look → repeat
- alternate trader and Build flows in the same loaded world to expose leaked state between systems

Do not close RG1 based only on a direct-call unit test.

## Definition of done
Commit the root-cause fix plus the strengthened regression. In the completion note, state:

1. the actual root cause,
2. why it was intermittent,
3. why the old smoke test missed it,
4. the files changed,
5. the exact tests run and results,
6. evidence that repeated real-input trader and Build-menu exits return control to the world.

If you cannot reproduce the failure after upgrading the test to the real input paths, do not invent a fix. Land the improved regression/instrumentation only if it adds real coverage, document exactly how many repetitions were run and what state was observed, and leave RG1 open with the strongest next diagnostic lead.