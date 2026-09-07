# RG8 — Combat camera must follow the active creature and keep normal player camera control

## Goal
Fix the combat camera regression reported by the owner: when a creature fight starts, the camera neither follows the player's active creature nor responds the way the normal exploration camera does. Combat should reuse the same player-controlled third-person camera model as exploration, retargeted to the active creature.

## Owner-confirmed player-facing behavior
During a creature fight:
- the camera must follow the player's currently active creature;
- the player must retain the same normal camera movement/orbit freedom available during exploration;
- right-stick / normal look input must continue to work;
- the player may rotate the camera freely, including full orbit around the creature;
- combat may use a different distance, height, FOV, pitch range, smoothing, or other framing profile, but it must not take camera control away from the player;
- switching active creatures must retarget the camera to the new active creature without losing look control;
- when combat ends, the camera must return cleanly to following the trainer with exploration settings restored.

Do not replace this with an enemy-lock camera or fixed cinematic combat camera. The design intent is still player-controlled third-person orbit.

## Current code / intended architecture
Inspect the live code before changing anything. Relevant known files/systems include:
- `scripts/player/camera_rig.gd`
- `scripts/combat/combat_manager.gd`
- `scripts/combat/encounter_director.gd`
- combat camera configuration in the combat/movement config files
- player/controller input mappings in `project.godot` / `scripts/ui/key_bindings.gd`
- any input-owner or modal systems that can suppress world input
- tests covering combat entry, switching, camera target, and controller input

The current architecture already intends to reuse the exploration `camera_rig.gd` in combat. `combat_manager.gd::_take_camera()` calls `set_target(_ally_body, combat_camera_profile)`. `camera_rig.gd` also continues to read the normal look actions in `_apply_look()`. Therefore this task is primarily a regression/integration investigation, not a request to invent a second combat camera system.

## Reproduce first
Before patching, reproduce the failure through the real gameplay path with controller-style input:
1. Start in exploration.
2. Verify the normal camera follows the trainer and right-stick orbit/look works.
3. Enter a real creature encounter through the production encounter path.
4. Observe the exact camera target and transform across the transition.
5. Move the player's creature in combat.
6. Apply right-stick look input in every direction.
7. Switch active creatures if switching is currently reachable.
8. Exit combat through at least one normal outcome and verify exploration camera recovery.

Record at minimum during reproduction:
- `camera_rig` target before combat, after combat begin, after switching, and after combat exit;
- whether the target node is valid and moving;
- camera rig global position and target position over several frames;
- yaw/pitch values before and after right-stick input;
- `Input.get_vector("look_left", "look_right", "look_up", "look_down")` or equivalent action-state evidence while combat is active;
- whether any input owner, combat state, pause/modal state, or controller mode prevents look actions from reaching the rig;
- active camera (`Camera3D.current`) and whether another camera becomes current;
- any combat profile values that could effectively pin or collapse movement.

Do not infer the cause from symptoms. Prove whether the failure is target assignment, target lifetime, follow code, input action state, active-camera selection, combat state gating, or another transition bug.

## Implementation requirements
### 1. Follow the active creature
- On combat entry, the camera rig must target the actual deployed active creature body.
- The follow target must remain valid as the creature moves.
- The rig must not remain parked on the trainer, encounter origin, stale creature node, or a temporary object.
- If the active creature changes, retarget the existing camera rig to the newly deployed active creature.
- Retargeting should preserve a sensible view transition and must not zero/lock player orbit unexpectedly.

### 2. Preserve normal look control
- The normal look actions must continue to drive `camera_rig.gd` while combat is active.
- The player must be able to yaw/orbit freely and use the normal pitch range allowed by the active camera profile.
- Do not add combat code that continuously overwrites yaw/pitch to face the enemy.
- Do not re-center the camera every frame.
- Do not consume right-stick input elsewhere in a way that prevents camera look unless a specific temporary mode (for example a deliberate throwing/aiming mode) explicitly owns that input.

### 3. Temporary aim/catch modes must hand camera control back correctly
The project has special camera profiles for throw/catch aiming. Preserve those deliberate temporary modes, but verify every exit path:
- cancel aim;
- successful throw;
- missed throw;
- caught creature;
- failed catch / fight resumes.

When the temporary aim sequence ends and combat continues, the camera must return to the active creature and normal combat orbit control.

### 4. Combat exit restores exploration camera
After combat ends:
- target the trainer again;
- restore exploration distance/height/FOV/pitch/sensitivity/response settings;
- preserve normal look controls;
- no dead camera, stale combat target, stuck aim profile, or wrong active camera may remain.

### 5. Preserve existing combat design
Do not change:
- combat being a state transition in the live world rather than a separate scene;
- piloted creature combat;
- arena placement/rules;
- attack input behavior;
- catch mechanics;
- trainer position rules;
- combat HUD behavior except where required to fix input ownership;
- exploration camera collision behavior;
- normal exploration camera feel.

If the root cause is a shared camera/input lifecycle bug, fix it at the appropriate shared seam. If combat entry, switching, catch aim, and combat exit have separate defects, fix them separately rather than forcing an abstraction that obscures the behavior.

## Likely failure families to evaluate, not assume
- combat never actually calls `set_target()` with the correct live creature body;
- a later call immediately overwrites the target;
- `_ally_body` is stale/replaced after the initial retarget;
- another camera becomes current;
- the camera target is valid but the rig's process/follow path is disabled;
- look actions are suppressed/consumed during combat;
- the combat camera profile uses values that make the rig appear fixed;
- yaw/pitch are continuously overwritten elsewhere;
- switch/catch paths fail to retarget the camera;
- combat exit leaves the rig in the wrong profile/target.

## Regression tests / verification
Add or upgrade tests so this cannot regress behind a green suite.

At minimum cover:
1. **Exploration baseline** — trainer follow + controller look changes yaw/pitch.
2. **Combat entry** — camera target becomes the active creature body.
3. **Combat follow** — move the creature and prove the rig follows it over subsequent frames.
4. **Combat look** — inject real joypad/right-stick events through the production InputMap and prove yaw/pitch visibly change while combat is active.
5. **Free orbit** — prove horizontal camera rotation is not continuously forced toward the enemy.
6. **Creature switch** — camera retargets to the newly active creature and remains controllable.
7. **Aim/catch return** — any temporary throw camera mode returns to active-creature follow and player look control when combat resumes.
8. **Combat exit** — camera retargets to trainer, exploration profile is restored, and normal look still works.
9. Repeat entry/exit cycles to catch state that only fails on a later fight.

Prefer real controller-style events (`Input.parse_input_event` / joypad motion/button events) over direct state mutation when proving user-facing input behavior. A test that only calls `camera_rig.set_target()` directly is not sufficient proof that the gameplay transition is wired correctly.

## Acceptance criteria
RG8 is complete only when all are true:
- entering a real creature fight causes the camera to follow the player's active creature;
- moving the active creature causes the camera to move with it;
- normal right-stick camera movement works during the fight;
- the player can freely orbit rather than being locked to the opponent;
- switching creatures retargets the camera correctly;
- temporary catch/aim camera modes return control correctly;
- leaving combat restores trainer follow and exploration camera behavior;
- repeated fights do not degrade camera behavior;
- automated tests exercise the real transition and controller input paths;
- existing exploration/combat/catching tests remain green.

## Definition of done
The owner can enter a fight on the ROG Ally/controller, immediately recognize that the camera is attached to the creature they are controlling, move the creature and have the camera follow, rotate/look around exactly as they normally can, switch creatures without losing the camera, finish the fight, and continue exploring with the normal trainer camera — without any manual recovery or restart.
