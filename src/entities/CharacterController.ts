/**
 * Capsule-against-heightfield character controller. Pure maths, no renderer,
 * no physics library, per ARCHITECTURE.md.
 *
 * The contract is deliberately narrow: given a position, an intent, and the
 * ability to sample terrain height and nearby prop colliders, produce the next
 * position. That makes slope limiting and step-up testable without a canvas,
 * which matters because they are the two things that make a controller feel
 * wrong in ways that are hard to describe and easy to regress.
 */

export interface Vec3Like {
  x: number;
  y: number;
  z: number;
}

export interface ControllerConfig {
  radius: number;
  height: number;
  walkSpeed: number;
  sprintSpeed: number;
  /** Upward velocity applied on jump, m/s. */
  jumpSpeed: number;
  gravity: number;
  /** Slopes steeper than this cannot be climbed. */
  maxSlopeDegrees: number;
  /** Ledges up to this high are stepped onto rather than blocked. */
  stepOffset: number;
  /** How fast horizontal velocity converges on the target. Higher is snappier. */
  acceleration: number;
  airControl: number;
}

export const DEFAULT_CONFIG: ControllerConfig = {
  radius: 0.36,
  height: 1.8,
  walkSpeed: 4.2,
  sprintSpeed: 7.1,
  jumpSpeed: 6.4,
  gravity: -19.6,
  maxSlopeDegrees: 45,
  stepOffset: 0.4,
  acceleration: 14,
  airControl: 0.35
};

/**
 * How far ahead the step-up check samples terrain height, in meters. Must be
 * comfortably larger than one frame of movement, or the slope limit leaks.
 */
const PROBE_DISTANCE = 1;

export interface ControllerWorld {
  heightAt: (x: number, z: number) => number;
  slopeAt: (x: number, z: number) => number;
  collidersNear: (x: number, z: number, radius: number) => Array<{ x: number; z: number; radius: number }>;
}

export interface ControllerState {
  position: Vec3Like;
  velocity: Vec3Like;
  grounded: boolean;
  /** Facing, radians. Driven by look input, not by movement. */
  yaw: number;
}

export interface MoveInput {
  /** Desired direction in world space, already rotated by camera yaw. */
  forward: number;
  right: number;
  sprint: boolean;
  jump: boolean;
}

export function createState(position: Vec3Like, yaw = 0): ControllerState {
  return { position: { ...position }, velocity: { x: 0, y: 0, z: 0 }, grounded: false, yaw };
}

/**
 * Advance one fixed step.
 *
 * Order matters and is the usual source of bugs: resolve horizontal movement
 * first (including prop pushback), then vertical, then ground snapping. Doing
 * gravity before horizontal makes the player skim down slopes; snapping to
 * ground before resolving props lets them stand inside a tree.
 */
export function step(
  state: ControllerState,
  input: MoveInput,
  world: ControllerWorld,
  dt: number,
  config: ControllerConfig = DEFAULT_CONFIG
): ControllerState {
  const targetSpeed = input.sprint ? config.sprintSpeed : config.walkSpeed;
  const desiredX = input.right * targetSpeed;
  const desiredZ = input.forward * targetSpeed;

  // Air control is reduced but not zero. Zero feels like ice; full feels like
  // flying, and both read as "the jump is broken".
  const accel = config.acceleration * (state.grounded ? 1 : config.airControl);
  const blend = Math.min(1, accel * dt);
  state.velocity.x += (desiredX - state.velocity.x) * blend;
  state.velocity.z += (desiredZ - state.velocity.z) * blend;

  if (input.jump && state.grounded) {
    state.velocity.y = config.jumpSpeed;
    state.grounded = false;
  }

  const nextX = state.position.x + state.velocity.x * dt;
  const nextZ = state.position.z + state.velocity.z * dt;

  const resolved = resolveHorizontal(state, nextX, nextZ, world, config);

  state.velocity.y += config.gravity * dt;
  let nextY = state.position.y + state.velocity.y * dt;

  const groundY = world.heightAt(resolved.x, resolved.z);
  if (nextY <= groundY) {
    nextY = groundY;
    // Clamping to 0 rather than leaving the accumulated negative velocity
    // means the next jump starts from rest instead of fighting a fall.
    if (state.velocity.y < 0) state.velocity.y = 0;
    state.grounded = true;
  } else {
    state.grounded = false;
  }

  state.position.x = resolved.x;
  state.position.z = resolved.z;
  state.position.y = nextY;
  return state;
}

/**
 * Horizontal movement with slope and prop blocking.
 *
 * When a move is blocked, the axes are retried independently so the player
 * slides along an obstacle instead of sticking to it. Sticking on a tree you
 * are pressing diagonally into is the single most noticeable controller flaw.
 */
function resolveHorizontal(
  state: ControllerState,
  nextX: number,
  nextZ: number,
  world: ControllerWorld,
  config: ControllerConfig
): { x: number; z: number } {
  const from = state.position;

  const passable = (x: number, z: number): boolean => {
    if (world.slopeAt(x, z) > config.maxSlopeDegrees) {
      // Steep ground is normally refused, but a short vertical lip between two
      // walkable areas should be stepped over rather than treated as a wall.
      //
      // The rise is measured over a fixed PROBE_DISTANCE ahead, NOT over the
      // per-frame movement delta. Measuring per frame is a silent hole in the
      // slope limit: at 60Hz a walk covers ~0.07m per step, so even a 46 degree
      // slope only rises ~0.07m per frame, always under the 0.4m step offset,
      // and the player strolls up a cliff. Probing a fixed distance makes a
      // continuous slope report its true rise (over 1m at 46 degrees) while a
      // genuine 0.3m lip still reads as 0.3m.
      const dx = x - from.x;
      const dz = z - from.z;
      const len = Math.hypot(dx, dz);
      if (len <= 1e-6) return true;
      const probeX = from.x + (dx / len) * PROBE_DISTANCE;
      const probeZ = from.z + (dz / len) * PROBE_DISTANCE;
      if (world.heightAt(probeX, probeZ) - from.y > config.stepOffset) return false;
    }
    for (const c of world.collidersNear(x, z, config.radius)) {
      const reach = c.radius + config.radius;
      if ((c.x - x) ** 2 + (c.z - z) ** 2 < reach * reach) return false;
    }
    return true;
  };

  if (passable(nextX, nextZ)) return { x: nextX, z: nextZ };
  if (passable(nextX, from.z)) {
    state.velocity.z = 0;
    return { x: nextX, z: from.z };
  }
  if (passable(from.x, nextZ)) {
    state.velocity.x = 0;
    return { x: from.x, z: nextZ };
  }
  state.velocity.x = 0;
  state.velocity.z = 0;
  return { x: from.x, z: from.z };
}

/**
 * Rotate stick input into world space using the camera yaw.
 *
 * Forward is where the camera looks, which is what every third-person game
 * does and what players expect without being told.
 */
export function intentToWorld(
  moveX: number,
  moveY: number,
  cameraYaw: number
): { forward: number; right: number } {
  const sin = Math.sin(cameraYaw);
  const cos = Math.cos(cameraYaw);
  return {
    forward: moveY * cos - moveX * sin,
    right: moveY * sin + moveX * cos
  };
}
