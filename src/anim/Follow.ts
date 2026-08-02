/**
 * Companion follow steering. Pure math, engine-free, unit tested.
 *
 * The companion aims for a point behind-left of the player and eases toward
 * it. Three rules carry the feel:
 *
 * 1. A dead zone: inside `settleRadius` of the target it stops, so it does
 *    not orbit or jitter against the player's heels.
 * 2. Speed scales with distance (capped), so it saunters when close and
 *    hustles when left behind, exactly how a companion reads as "keeping up"
 *    rather than "attached by spring".
 * 3. A teleport past `teleportDistance`, because a companion lost behind a
 *    hill is worse than one that blinks; every creature-collector does this.
 */

export interface FollowConfig {
  /** Where to stand, relative to the player's facing: metres behind. */
  behind: number;
  /** Metres to the player's left. */
  side: number;
  /** Inside this of the target, stop. */
  settleRadius: number;
  /** Speed per metre of distance, capped by maxSpeed. */
  gain: number;
  maxSpeed: number;
  /** Farther than this from the PLAYER, blink to the target. */
  teleportDistance: number;
}

export interface FollowState {
  x: number;
  z: number;
}

export interface FollowResult {
  x: number;
  z: number;
  /** Metres moved this step; drives walk/run/idle animation choice. */
  speed: number;
  teleported: boolean;
}

/** The point the companion wants to occupy. */
export function followTarget(
  playerX: number,
  playerZ: number,
  playerYaw: number,
  config: FollowConfig
): { x: number; z: number } {
  // Player forward is (sin yaw, cos yaw); behind is the negation, left is the
  // perpendicular.
  const fx = Math.sin(playerYaw);
  const fz = Math.cos(playerYaw);
  return {
    x: playerX - fx * config.behind - fz * config.side,
    z: playerZ - fz * config.behind + fx * config.side
  };
}

/** One fixed step of steering. */
export function stepFollow(
  state: FollowState,
  playerX: number,
  playerZ: number,
  playerYaw: number,
  dt: number,
  config: FollowConfig
): FollowResult {
  const distToPlayer = Math.hypot(state.x - playerX, state.z - playerZ);
  const target = followTarget(playerX, playerZ, playerYaw, config);

  if (distToPlayer > config.teleportDistance) {
    state.x = target.x;
    state.z = target.z;
    return { x: state.x, z: state.z, speed: 0, teleported: true };
  }

  const dx = target.x - state.x;
  const dz = target.z - state.z;
  const dist = Math.hypot(dx, dz);
  if (dist <= config.settleRadius) {
    return { x: state.x, z: state.z, speed: 0, teleported: false };
  }

  const speed = Math.min(config.maxSpeed, dist * config.gain);
  const step = Math.min(dist, speed * dt);
  state.x += (dx / dist) * step;
  state.z += (dz / dist) * step;
  return { x: state.x, z: state.z, speed: step / dt, teleported: false };
}
