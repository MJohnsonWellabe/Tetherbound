/**
 * Wall-ring colliders: small circles laid along the four edges of a
 * rectangular footprint, with an optional gap left in the front wall for a
 * doorway.
 *
 * Extracted from Hall.ts's original inline `pushWallColliders`/`toWorld` pair
 * so Structures.ts's houses get the same "walk up to the wall line, not past
 * it" collision without duplicating the trig. Pure: it takes a footprint and
 * a placement and returns collider centres, no scene involved, which is what
 * lets the rotation and the gap be tested directly.
 */

export interface WallCollider {
  x: number;
  z: number;
  radius: number;
}

export interface WallRingOptions {
  /** Half-extents of the footprint in the structure's own local frame, centred at the origin. */
  halfWidth: number;
  halfDepth: number;
  /** World position the local frame's origin sits at. */
  originX: number;
  originZ: number;
  /** The structure's yaw (radians), matching its TransformNode.rotation.y. */
  yaw: number;
  /** Spacing between collider centres along a wall run. */
  step: number;
  /**
   * Width of the gap left in the front wall (local -z), centred on `doorX`.
   * Zero (or omitted) yields a plain unbroken front wall, for a structure
   * with no walkable doorway.
   */
  doorGapWidth?: number;
  /** Local x of the doorway's centre. Defaults to 0 (centred on the wall). */
  doorX?: number;
  /**
   * The character capsule's radius, so the door gap is sized for what the
   * controller actually tests (`collider.radius + player.radius`, see
   * CharacterController.resolveHorizontal) rather than the collider radius
   * alone. Omitted or zero reproduces the old (too-narrow) behaviour.
   */
  playerRadius?: number;
}

/** A point in the structure's local frame, rotated and translated into world space. */
export function toWorld(
  originX: number,
  originZ: number,
  yaw: number,
  localX: number,
  localZ: number
): { x: number; z: number } {
  const sin = Math.sin(yaw);
  const cos = Math.cos(yaw);
  return {
    x: originX + localX * cos + localZ * sin,
    z: originZ - localX * sin + localZ * cos
  };
}

function pushRun(
  out: WallCollider[],
  opts: WallRingOptions,
  fromX: number,
  fromZ: number,
  toX: number,
  toZ: number
): void {
  const length = Math.hypot(toX - fromX, toZ - fromZ);
  if (length <= 1e-6) return;
  const steps = Math.max(1, Math.round(length / opts.step));
  for (let i = 0; i <= steps; i++) {
    const lx = fromX + ((toX - fromX) * i) / steps;
    const lz = fromZ + ((toZ - fromZ) * i) / steps;
    const world = toWorld(opts.originX, opts.originZ, opts.yaw, lx, lz);
    out.push({ x: world.x, z: world.z, radius: opts.step * 0.75 });
  }
}

/**
 * Colliders along all four walls of a rectangle centred on the local origin,
 * with the front wall (local -z) split around a doorway gap when one is
 * given. A ring beats a single inscribed circle on two counts: it hugs the
 * real footprint instead of leaving the corners open, and it can carry a
 * doorway gap at all.
 *
 * The two runs bordering the gap stop short of the gap's true edge by one
 * collider RADIUS plus `playerRadius`, rather than running exactly to it, so
 * the boundary sphere's own bulk sits outside the doorway and the point the
 * CONTROLLER actually stops a capsule at (`collider.radius + player.radius`,
 * CharacterController.resolveHorizontal), not the bare sphere edge, is what
 * meets the gap line. Pulling back by the collider radius alone (the old
 * behaviour) left the controller's own player-radius reach eating into the
 * gap uncounted, so the walkable slot came out `doorGapWidth - 2 *
 * playerRadius` wide instead of the full configured width; a house door
 * ~1m across lost most of its aperture to a player capsule barely narrower
 * than it.
 */
export function wallRingColliders(opts: WallRingOptions): WallCollider[] {
  const out: WallCollider[] = [];
  const { halfWidth: hw, halfDepth: hd } = opts;
  const doorX = opts.doorX ?? 0;
  const gapWidth = opts.doorGapWidth ?? 0;

  pushRun(out, opts, -hw, -hd, -hw, hd); // left wall
  pushRun(out, opts, hw, -hd, hw, hd); // right wall
  pushRun(out, opts, -hw, hd, hw, hd); // back wall

  if (gapWidth <= 0) {
    pushRun(out, opts, -hw, -hd, hw, -hd); // front wall, unbroken
    return out;
  }

  const colliderRadius = opts.step * 0.75;
  const pullback = colliderRadius + (opts.playerRadius ?? 0);
  const gapMin = Math.max(-hw, doorX - gapWidth / 2);
  const gapMax = Math.min(hw, doorX + gapWidth / 2);
  const leftEdge = Math.max(-hw, gapMin - pullback);
  const rightEdge = Math.min(hw, gapMax + pullback);
  pushRun(out, opts, -hw, -hd, leftEdge, -hd);
  pushRun(out, opts, rightEdge, -hd, hw, -hd);
  return out;
}

/**
 * Local x for a door leaf's hinge pivot (its own left edge, the convention
 * BuildMode.mountDoor and Structures.mountHouseDoor both use), so a leaf
 * narrower than its aperture (see models.json's doorLeaf.widthFraction) ends
 * up CENTRED on the doorway instead of pinned to one edge of it. Centring
 * on `doorX` and subtracting half the LEAF's own width, not half the full
 * aperture's width, is what leaves an even reveal on both sides rather than
 * shoving the whole gap to one side.
 */
export function doorLeafPivotX(doorX: number, leafWidth: number): number {
  return doorX - leafWidth / 2;
}
