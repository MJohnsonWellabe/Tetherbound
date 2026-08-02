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

  const gapMin = Math.max(-hw, doorX - gapWidth / 2);
  const gapMax = Math.min(hw, doorX + gapWidth / 2);
  pushRun(out, opts, -hw, -hd, gapMin, -hd);
  pushRun(out, opts, gapMax, -hd, hw, -hd);
  return out;
}
