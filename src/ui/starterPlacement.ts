/**
 * Where Grandpa Orin's three starters stand, and the point the camera should
 * hold on while the player is looking at them.
 *
 * Pure math, no scene, no DOM, so it is testable the same way stagePlacement.ts
 * is: an anchor (Orin's own position and facing) in, a line of spots out.
 */

export interface StarterAnchor {
  x: number;
  z: number;
  /** Facing, radians, in this codebase's convention: 0 faces +Z. */
  yaw: number;
}

export interface StarterSpot {
  x: number;
  z: number;
  yaw: number;
}

export interface StarterPlacementConfig {
  /** Metres in front of the anchor, along its own facing. */
  forward: number;
  /** Metres between neighbouring spots, perpendicular to that facing. */
  spread: number;
}

/**
 * A row of `count` spots centred on the anchor's forward line, each facing
 * the same way the anchor does (so a pal placed in front of Orin looks back
 * toward wherever he is looking, which is toward the player).
 */
export function placeStarters(
  anchor: StarterAnchor,
  count: number,
  config: StarterPlacementConfig
): StarterSpot[] {
  const sin = Math.sin(anchor.yaw);
  const cos = Math.cos(anchor.yaw);
  const mid = (count - 1) / 2;
  const spots: StarterSpot[] = [];
  for (let i = 0; i < count; i++) {
    const side = (i - mid) * config.spread;
    spots.push({
      x: anchor.x + sin * config.forward + cos * side,
      z: anchor.z + cos * config.forward - sin * side,
      yaw: anchor.yaw
    });
  }
  return spots;
}

/** The point a camera pinning on the whole row should look toward. */
export function centreOf(spots: readonly StarterSpot[]): { x: number; z: number } {
  if (spots.length === 0) return { x: 0, z: 0 };
  let x = 0;
  let z = 0;
  for (const spot of spots) {
    x += spot.x;
    z += spot.z;
  }
  return { x: x / spots.length, z: z / spots.length };
}
