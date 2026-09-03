# CATCH — Rework aiming/throw interaction toward a Palworld-like over-the-shoulder feel

## Owner decision
The owner played the current catch aiming/throw flow on the ROG Ally and described it plainly: **our version is bad**.

Approved interaction target, borrowing interaction grammar rather than proprietary assets/code:

**hold aim -> camera tightens/offsets over shoulder -> visible reticle -> right stick freely aims -> readable throw trajectory/landing assistance -> throw while in aim mode -> cancel/release cleanly returns to normal camera.**

Mild target assistance is acceptable. Default hard lock-on is not.

## Goal
Make catching feel like a deliberate third-person physical throw the player can understand before committing the orb, while preserving Tetherbound's existing catch legality/probability and combat rules.

This is now a concrete near-term implementation task. It supersedes the `catch feel` portion of the old R9.1 scoping prompt.

## Inspect first
- current combat/catch state machine and catch eligibility
- camera rig and combat camera profile
- current throw-aim code / reticle
- orb projectile/trajectory code
- input actions for aim/throw/cancel and controller triggers/buttons
- combat HUD catch prompts and orb count
- active creature/camera retarget logic
- catch probability/result code
- existing catch tests and any quality-plan catching requirements

Do not change capture chance simply because the input presentation changes.

## Aim-mode entry
Aim mode must be explicit and stable.

Preferred controller grammar:
- hold the existing/appropriate Aim input;
- camera blends quickly into an over-shoulder catch profile rather than teleporting;
- normal right-stick look remains available and becomes throw aiming;
- reticle appears only while aim mode owns the interaction;
- the active creature/opponent remains readable rather than being hidden by trainer/player model.

If current controller bindings already have a well-established catch aim action, keep them. If not, choose the smallest InputMap addition and update glyph/help surfaces.

## Camera behavior
Use the existing camera rig/profile architecture. Do not create a second unrelated camera controller.

Requirements:
- slight shoulder offset and closer FOV/distance than ordinary exploration/combat;
- free horizontal/vertical aim within sensible pitch limits;
- camera collision/spring arm still prevents clipping through walls/terrain;
- entering/exiting aim does not steal camera control after the throw or after cancelling;
- after catch attempt resolves, return to the correct combat/exploration target/profile.

Coordinate with RG8: ordinary combat retains free orbit around the active creature. Catch aim is a temporary mode, not a locked battle camera.

## Reticle and trajectory readability
The player should have useful pre-throw information.

Show:
- a clear reticle/aim point;
- a trajectory arc, projected landing point, or equivalent readable assistance based on the **real throw physics**;
- invalid/blocked trajectory feedback when a throw would collide immediately with world geometry;
- target-assist indication only if assistance is actually being applied.

Do not draw a fake arc that differs materially from the projectile path.

The assistance should make a handheld controller throw usable, not automate it. Mild magnetism/aim slowdown around an eligible wild target is acceptable; do not snap the reticle into a hard lock that removes aiming.

## Throw execution
- A fresh Throw input while aiming launches exactly one orb.
- The orb begins from a believable hand/release point and follows the same trajectory previewed.
- One orb is consumed only when a real throw is committed according to existing inventory rules.
- Holding Throw cannot machine-gun orbs.
- Releasing/cancelling Aim without throwing consumes nothing.
- If catching is currently illegal (trainer-owned creature, wrong combat state, no orbs, etc.), aim/throw UI must communicate that and existing legality remains authoritative.

## Result feedback
Preserve or improve the existing hit/miss/shake/result sequence, but keep this item focused.

At minimum the player must understand:
- orb launched;
- whether it hit the creature or missed/world-collided;
- capture resolution started;
- success/failure;
- remaining orb count.

Do not hide gameplay for unnecessary cinematic duration.

## Movement during aim
Inspect current catch design before choosing. The player should not accidentally walk the trainer around while right stick/aim mode owns input. If limited trainer movement during aim already exists, preserve it. If the mode is stationary today, keep that unless evidence says movement is needed. The owner ask is aiming feel, not a new dodge mechanic.

## Input ownership
Aim mode must have a clear owner and clean transitions:
- no menu/build/dialogue action leaks into catch;
- cancel returns to combat/exploration;
- entering aim after a switch/combat camera transition works;
- repeated aim -> cancel -> aim cycles do not lose camera or world controls.

## Tests
Automate math/state where practical:
- trajectory preview matches projectile initial conditions;
- no orb consumption on cancel;
- exactly one orb on committed throw;
- hard-illegal targets remain uncatchable;
- aim-mode state exits on miss/success/failure/cancel;
- camera profile/target restores after exit.

But final acceptance requires live controller feel on a representative wild encounter.

## Live acceptance matrix
On ROG/controller:
1. engage catch-eligible wild creature;
2. hold Aim;
3. verify smooth shoulder camera and reticle;
4. aim above/below/left/right freely;
5. see trajectory/landing feedback move coherently;
6. cancel and regain normal combat camera;
7. re-enter aim;
8. make intentional miss;
9. make intentional hit;
10. complete successful/failed capture resolution;
11. immediately continue combat/exploration without camera/input loss.

Test near terrain/rocks so camera collision and trajectory obstruction are real.

## Preserve
- existing capture probability/balance unless a separate task changes it;
- trainer creatures cannot be caught;
- five-creature ownership/release ceremony rules;
- combat is piloted, no shields/dodge added;
- existing orb item economy;
- one shared camera rig.

## Acceptance criteria
- Aim mode feels intentionally third-person and controller-usable.
- Right stick remains responsive throughout aim.
- Player can predict the throw from real trajectory assistance.
- Throw originates and travels consistently with preview.
- Cancel is free and restores camera/input.
- No hard lock-on is required to use it.
- Existing catch legality and odds remain correct.
- Repeated aim/throw cycles do not freeze/steal camera control.

## Definition of done
A player can look at a wild creature, enter a clear over-the-shoulder aiming mode, deliberately place a physical throw, and understand the result without fighting the camera or guessing where the orb will go.