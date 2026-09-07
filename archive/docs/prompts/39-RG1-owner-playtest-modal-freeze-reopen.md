# RG1 Phase -1.7 — Reopen modal/input freeze with new owner reproductions

## Why this supersedes the old RG1 conclusion
The earlier RG1 prompt and `smoke_post_modal_control.gd` focused on two known cases: trader/shop exit and Build-menu exit. A prior lane measured those paths on then-current `main` and could not reproduce the freeze.

The owner has now reproduced the failure again on the ROG Ally, with **new paths and a more severe state**. Therefore RG1 is open again. Do not close this by citing the prior smoke.

## Current owner reproductions — 2026-08-18 evening
1. Talk to the **innkeeper**, use/leave his menu -> game freezes / world control does not return.
2. Use a **creature bed**, rest a pal, leave the rest UI -> game freezes.
3. Open **Build from the main/pause menu**, leave that screen into world placement -> game freezes.
4. In the most severe Build case, the player could not move **and could not even reopen the main/pause menu**. This differs from the older RG1 symptom where menu UI could still open.

Treat these as one failure family until evidence proves otherwise, not as three unrelated patches.

## Goal
Establish one reliable modal/input-lifecycle contract so every Meadows-reachable modal returns the game to the correct owner/state when it closes or hands off to another mode.

The game must never require a quit/restart because a panel or transition left stale pause, input-owner, process, mouse, interaction, or build-placement state behind.

## Inspect first
At minimum inspect current:
- `scripts/ui/input_owner.gd`
- `scripts/ui/game_menu.gd`
- innkeeper NPC/dialogue/menu code and any inn/shop panel it launches
- `scripts/ui/creature_bed_panel.gd`
- `scripts/build/creature_bed.gd`
- `scripts/ui/build_menu.gd`
- `scripts/build/build_placer.gd`
- interaction arbiter / interactable system
- pause and process-mode changes performed by all above panels
- `tests/smoke_post_modal_control.gd`
- modal-stacking/menu smoke tests
- player controller/HUD gates that decide whether world input is accepted

`creature_bed_panel.gd` currently pauses the tree, stores `_paused_before`, changes mouse mode, joins the input-owner group, and restores those values on `close()`. Do not assume that means its lifecycle is correct; reproduce the real player path.

## Required diagnostic distinction
The new reports include at least two visible end states:

### State A — world dead, pause menu still usable
Historical RG1 state. Likely stale world-specific suppression, input owner, player processing or arbiter lock.

### State B — world dead AND pause menu cannot reopen
Current severe Build reproduction. This can indicate a broader stale owner/modal state, tree pause/process interaction, a menu believing it is still open, or an action-edge/reopen guard trapping the shell.

Instrument enough state to distinguish these, rather than logging only `player did not move`.

On failure record:
- `SceneTree.paused`
- `Input.mouse_mode`
- current input owner node/path and all nodes in the owner group
- `game_menu.is_open()` and visibility/process state
- inn/shop/bed/build panel `is_open` / visible / process mode
- build pending/ghost state
- interaction-arbiter/modal lock state
- player physics/input processing state
- HUD/world input gates
- action pressed/just-pressed state for the button used to close/confirm
- focused Control node if any

## Production-faithful reproduction matrix
Use real InputMap-backed joypad events; do not prove this with direct `.close()` calls.

### Innkeeper
- interact with innkeeper normally;
- advance real dialogue;
- open whatever menu/service he owns;
- perform at least one normal service interaction if applicable;
- leave with the production controller path;
- immediately walk, look, interact, open pause menu, close it, walk again.

### Creature bed
- interact with placed creature bed;
- choose a real party creature;
- perform Rest through the actual UI;
- close/return through normal controller flow;
- verify world + menu access.

Repeat after the Phase -1.7 overnight-rest mechanic lands as well; assigning a creature to bed must not change modal release guarantees.

### Build via exploration shortcut
- open Build using the world build action;
- select a piece;
- hand off to placement;
- cancel/complete placement;
- verify control.

### Build via main/pause menu
This is newly load-bearing.
- open main menu;
- navigate to Build;
- choose a piece;
- exit/handoff from paused menu to live-world placement;
- verify tree unpaused, menu shell actually closed, correct input owner, ghost active, player can build/cancel and pause menu can reopen.

## Stress requirement
The owner says the freeze is intermittent. For each path, run repeated cycles in one loaded world. Prefer deterministic action-edge/process-order reproduction if found; otherwise use a bounded stress loop large enough to make the prior false confidence unlikely.

Alternate paths as well: innkeeper -> bed -> build -> pause -> innkeeper. Leaked state may only surface after another modal has changed the stored `paused_before`/mouse/owner state.

## Fix principles
- One authoritative acquire/release contract is preferable to per-panel magic delays.
- A panel must never restore stale state that belonged to a modal opened after it.
- Closing/handoff actions must not leak into another layer on the same frame.
- Pause restoration must respect whether another legitimate owner/modal still exists.
- Input-owner membership must reflect real active ownership, not merely node existence.
- Build handoff is special: menu ownership ends and placement ownership begins without losing world processing.
- Do not globally swallow B/A/Esc/confirm to hide the race.
- Do not add arbitrary wait timers without explaining why they are part of the intended state machine.

## Acceptance criteria
1. Innkeeper service exit returns world control every time across repeated real-controller cycles.
2. Creature-bed rest/assignment exit returns world control every time.
3. Build shortcut -> placement returns correct control.
4. Main menu -> Build -> placement returns correct control and unpauses the world.
5. After all four flows, pause/menu can open and close normally.
6. No stale input-owner/modal/arbiter state survives closure.
7. Mouse/camera state restores correctly for controller and keyboard/mouse.
8. Repeated mixed-modal sequence remains healthy.
9. Automated regression drives real joypad bindings and the actual menus, not direct close calls.
10. The completion report names the actual root cause and why previous smoke coverage missed it.

## Preserve
- controller-first ROG Ally operation;
- valid modal stacking;
- new Valheim-style persistent build placement mode;
- dialogue/shop/bed functionality;
- legitimate pause behavior;
- existing reopen/action-edge guards that are still necessary.

## Definition of done
RG1 closes only when the owner-reported modal family has a production-faithful regression and a root-cause repair. A green old trader/build smoke alone is explicitly insufficient.