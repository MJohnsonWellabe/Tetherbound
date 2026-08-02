/**
 * Where the fighters stand when a fight starts. Pure math, tested first.
 *
 * The ally takes the field a few metres ahead of the player, on the line to
 * the enemy. An enemy that triggered the fight at point-blank range is pushed
 * out to a readable gap; one that was already far enough stays where it is,
 * because teleporting a visible creature breaks the "combat is a state, not a
 * scene" rule harder than any camera cut.
 */

export interface StagePlacementConfig {
  /** Metres ahead of the player the ally stands. */
  allyForward: number;
  /** Minimum ally-to-enemy distance. */
  gap: number;
}

export interface StagePose {
  x: number;
  z: number;
  yaw: number;
}

export interface StagePlacement {
  ally: StagePose;
  enemy: StagePose;
}

/**
 * The yaw that faces `toX,toZ` from `fromX,fromZ`, in the convention this
 * codebase uses everywhere a body or a camera turns to face a point: 0 faces
 * +Z, and a mesh's local forward is (sin(yaw), cos(yaw)). Shared by the ally
 * and enemy facings below and by CombatStage's per-frame camera lock, so the
 * two can never quietly disagree about which way "facing the fight" is.
 */
export function facingYaw(fromX: number, fromZ: number, toX: number, toZ: number): number {
  return Math.atan2(toX - fromX, toZ - fromZ);
}

export function placeStage(
  playerX: number,
  playerZ: number,
  enemyX: number,
  enemyZ: number,
  config: StagePlacementConfig
): StagePlacement {
  let dx = enemyX - playerX;
  let dz = enemyZ - playerZ;
  const dist = Math.hypot(dx, dz);
  if (dist < 1e-6) {
    // Enemy exactly on top of the player: pick +Z and get on with it.
    dx = 0;
    dz = 1;
  } else {
    dx /= dist;
    dz /= dist;
  }

  const ally: StagePose = {
    x: playerX + dx * config.allyForward,
    z: playerZ + dz * config.allyForward,
    yaw: Math.atan2(dx, dz)
  };

  // Push a point-blank enemy out to the gap; leave a distant one alone.
  const fromAlly = Math.hypot(enemyX - ally.x, enemyZ - ally.z);
  const enemy: StagePose =
    fromAlly >= config.gap
      ? { x: enemyX, z: enemyZ, yaw: 0 }
      : { x: ally.x + dx * config.gap, z: ally.z + dz * config.gap, yaw: 0 };
  enemy.yaw = facingYaw(enemy.x, enemy.z, ally.x, ally.z);

  return { ally, enemy };
}
