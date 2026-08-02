import pieces from '../data/pieces.json';

/**
 * The hinge: a door's leaf angle eases toward open or closed rather than
 * snapping, which is what makes it read as a door and not a light switch.
 *
 * Pure and engine-free, so the timing is testable without a scene. `Door.ts`
 * elsewhere (BuildMode) owns the mesh and the pivot transform; this file owns
 * only the angle.
 */

const OPEN_ANGLE_RAD = (pieces.doorOpenAngleDeg * Math.PI) / 180;
const SWING_MS = pieces.doorSwingMs;

/** The leaf's resting angle for a given open/closed state. */
export function targetAngle(open: boolean): number {
  return open ? OPEN_ANGLE_RAD : 0;
}

/**
 * One step of the hinge easing toward `open`'s target angle.
 *
 * Linear in time rather than in angle-remaining, so the swing takes the same
 * SWING_MS whether it started fully open, fully closed, or interrupted
 * partway through reversing direction.
 */
export function stepHinge(current: number, open: boolean, dtMs: number): number {
  const target = targetAngle(open);
  const maxStep = (OPEN_ANGLE_RAD / SWING_MS) * dtMs;
  const diff = target - current;
  if (Math.abs(diff) <= maxStep) return target;
  return current + Math.sign(diff) * maxStep;
}

/** True once the hinge has reached its target (within a hair of drift). */
export function hingeSettled(current: number, open: boolean): boolean {
  return Math.abs(current - targetAngle(open)) < 1e-4;
}
