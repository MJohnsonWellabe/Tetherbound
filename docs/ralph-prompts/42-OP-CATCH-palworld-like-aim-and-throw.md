# OP-CATCH — Palworld-like readable aim-and-throw interaction

## Goal
Replace the current awkward throw-aim experience with a clear controller-first aiming mode that has the usability of Palworld while keeping Tetherbound's own art/UI/mechanics.

## Owner intent — locked
- Hold an aim control to enter throw aiming.
- Camera shifts/tightens into a useful over-the-shoulder view.
- Right stick freely aims.
- Reticle clearly communicates aim mode.
- Show useful trajectory/landing assistance.
- Mild target assistance is acceptable; do not hard-lock the player onto a target.
- Throw while remaining in aim mode as appropriate.
- Cancel/release returns cleanly to ordinary camera/control.

Do not copy Palworld assets, UI layout, animations or exact values. The reference is interaction clarity and feel.

## Current systems to inspect
Inspect current catch/combat manager, camera rig/profile handling, reticle/throw projectile/orb code, InputMap actions, target legality and catch probability. Preserve the existing rule that capture legality/probability is separate from aiming presentation.

## Aim mode
Entering aim must be deterministic and reversible:
- preserve enough camera state to restore exploration/combat correctly;
- use a camera profile/offset rather than spawning a parallel camera system;
- right-stick aim must remain responsive with appropriate pitch/yaw limits;
- world/player input not related to aim must not leak through unexpectedly;
- target assistance should bias/softly guide rather than rotate the camera against player intent.

## Trajectory
Provide a readable projected path/landing indicator based on the actual throw physics. Do not draw a decorative line that disagrees with where the orb will go.

Trajectory assistance should update live as aim changes and account for current throw origin/velocity/gravity. Keep it visually restrained and performant.

## Throw feedback
On throw:
- visible throw animation/orb launch must match the trajectory origin;
- hit/miss feedback must be immediate and legible;
- camera should not jerk or lose look control unexpectedly;
- subsequent catch-result flow remains governed by existing catch rules.

## Edge cases
Verify very close targets, long throws, uphill/downhill targets, target moving laterally, no valid target, multiple nearby creatures, aim cancel, combat switch while eligible, and repeated aim/throw cycles.

## Controller requirements
ROG Ally first. Show dynamic glyphs for Aim, Throw and Cancel while aiming. Do not require mouse emulation.

## Preserve
- existing catch probability math;
- five-creature ownership cap and overflow ceremony rules;
- trainer creatures cannot be caught;
- combat camera freedom from RG8 outside the temporary aim profile;
- no hard lock-on.

## Testing / acceptance
Automated tests should cover state transitions and trajectory math; live controller verification must cover feel. Done when the player can hold aim, understand where the orb is going, adjust smoothly with right stick, throw confidently, and return to normal control without camera/input residue.