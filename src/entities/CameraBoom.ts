/**
 * Third-person boom length: how far the camera sits from the focus point,
 * pulled in short of terrain or nearby colliders. Pure maths, no renderer
 * imports, so a wall clipping bug can be reproduced and fixed with a plain
 * assertion instead of a screenshot.
 */

export interface Vec3Like {
  x: number;
  y: number;
  z: number;
}

export interface BoomCollider {
  x: number;
  z: number;
  radius: number;
}

export interface BoomConfig {
  /** Sample points along the boom, evenly spaced from the focus outward. */
  steps: number;
  /** Distance floor; the boom never resolves shorter than this. */
  floor: number;
  /** Height the boom must clear above sampled terrain to count as unblocked. */
  groundClearance: number;
  /** Extra radius added to every collider before testing a sample against it. */
  colliderMargin: number;
}

/**
 * March along the boom from `focus` toward `dir * maxDistance` and return the
 * distance to stop at: short of the ground, and short of any collider circle
 * (inflated by `colliderMargin`) the sample would land inside. `dir` need not
 * be unit length in y; only its direction matters, x/z/y are scaled together.
 */
export function resolveBoomDistance(
  focus: Vec3Like,
  dir: Vec3Like,
  maxDistance: number,
  heightAt: (x: number, z: number) => number,
  colliders: BoomCollider[],
  config: BoomConfig
): number {
  const { steps, floor, groundClearance, colliderMargin } = config;
  let distance = maxDistance;

  for (let i = 1; i <= steps; i++) {
    const d = (maxDistance * i) / steps;
    const px = focus.x + dir.x * d;
    const pz = focus.z + dir.z * d;
    const py = focus.y + dir.y * d;

    const ground = heightAt(px, pz) + groundClearance;
    const blockedByGround = py < ground;
    const blockedByCollider = colliders.some((c) => {
      const dx = px - c.x;
      const dz = pz - c.z;
      const margin = c.radius + colliderMargin;
      return dx * dx + dz * dz < margin * margin;
    });

    if (blockedByGround || blockedByCollider) {
      distance = Math.max(floor, (maxDistance * (i - 1)) / steps);
      break;
    }
  }

  return distance;
}

/**
 * Ease the boom's in-use distance toward a freshly resolved target. Pulling
 * in uses `lerpInRate` and letting back out uses `lerpOutRate`; the asymmetry
 * is deliberate (see cameraRig.json) so a wall never gets a frame to bleed
 * through but the boom does not visibly snap back out once it clears.
 *
 * Rates are exponential-decay constants (1/seconds), applied as
 * `1 - exp(-rate * dt)` so the blend looks the same at any frame rate.
 */
export function smoothBoomDistance(
  current: number,
  target: number,
  dt: number,
  lerpInRate: number,
  lerpOutRate: number
): number {
  const rate = target < current ? lerpInRate : lerpOutRate;
  const t = 1 - Math.exp(-rate * dt);
  return current + (target - current) * t;
}
