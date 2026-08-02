import { describe, expect, it } from 'vitest';
import { toWorld, wallRingColliders } from '../src/world/WallRing';

/**
 * Wall-ring colliders back both Structures.ts's houses and (indirectly, via
 * the same maths) Hall.ts's walls, so the four-sided-plus-gap contract lives
 * here where it can be checked without a scene.
 */

describe('toWorld', () => {
  it('is the identity translation at yaw 0', () => {
    expect(toWorld(10, -5, 0, 2, 3)).toEqual({ x: 12, z: -2 });
  });

  it('rotates a local point by the given yaw', () => {
    const world = toWorld(0, 0, Math.PI / 2, 1, 0);
    expect(world.x).toBeCloseTo(0, 5);
    expect(world.z).toBeCloseTo(-1, 5);
  });
});

describe('wallRingColliders', () => {
  const base = { halfWidth: 3, halfDepth: 4, originX: 0, originZ: 0, yaw: 0, step: 1 };

  it('lays colliders along all four walls', () => {
    const colliders = wallRingColliders({ ...base, doorGapWidth: 0 });
    const onLeft = colliders.some((c) => Math.abs(c.x - -3) < 1e-6);
    const onRight = colliders.some((c) => Math.abs(c.x - 3) < 1e-6);
    const onBack = colliders.some((c) => Math.abs(c.z - 4) < 1e-6);
    const onFront = colliders.some((c) => Math.abs(c.z - -4) < 1e-6);
    expect(onLeft && onRight && onBack && onFront).toBe(true);
  });

  it('leaves a gap of the configured width in the front wall, centred on doorX', () => {
    const doorX = 1;
    const gapWidth = 1.6;
    const colliders = wallRingColliders({ ...base, doorGapWidth: gapWidth, doorX });
    const frontColliders = colliders.filter((c) => Math.abs(c.z - -4) < 1e-6);
    // Strictly inside the gap, with a hair of tolerance for the boundary
    // sample landing exactly on the gap edge by floating-point rounding.
    const inGap = frontColliders.filter((c) => Math.abs(c.x - doorX) < gapWidth / 2 - 1e-6);
    expect(inGap).toEqual([]);
    // Colliders still exist either side of the gap.
    expect(frontColliders.some((c) => c.x < doorX - gapWidth / 2)).toBe(true);
    expect(frontColliders.some((c) => c.x > doorX + gapWidth / 2)).toBe(true);
  });

  it('produces an unbroken front wall when doorGapWidth is zero', () => {
    const gapless = wallRingColliders({ ...base, doorGapWidth: 0 });
    const front = gapless.filter((c) => Math.abs(c.z - -4) < 1e-6);
    // An unbroken run across 2*halfWidth=6 at step 1 has colliders roughly
    // evenly spaced with no hole in the middle.
    const xs = front.map((c) => c.x).sort((a, b) => a - b);
    for (let i = 1; i < xs.length; i++) {
      expect(xs[i]! - xs[i - 1]!).toBeLessThan(base.step * 1.5);
    }
  });

  it('keeps the boundary colliders reach clear of the gap, not just their centres', () => {
    // A fat sphere centred exactly on the gap edge would bulge into it by a
    // full radius; the nearest collider's EDGE, not centre, must be what
    // meets the gap line.
    const doorX = 0;
    const gapWidth = 1.0;
    const colliders = wallRingColliders({ ...base, doorGapWidth: gapWidth, doorX, step: 1 });
    const front = colliders.filter((c) => Math.abs(c.z - -4) < 1e-6);
    for (const c of front) {
      const reachMin = c.x - c.radius;
      const reachMax = c.x + c.radius;
      // Every front collider's own bulk must stay outside the gap interval.
      const outsideGap = reachMax <= doorX - gapWidth / 2 + 1e-6 || reachMin >= doorX + gapWidth / 2 - 1e-6;
      expect(outsideGap).toBe(true);
    }
  });

  it('defaults to a centred gap when doorX is omitted', () => {
    const colliders = wallRingColliders({ ...base, doorGapWidth: 1 });
    const front = colliders.filter((c) => Math.abs(c.z - -4) < 1e-6);
    expect(front.some((c) => Math.abs(c.x) < 0.5)).toBe(false);
  });

  it('rotates the whole ring with the structure yaw, off the axis-aligned lines', () => {
    const yaw = Math.PI / 4;
    const rotated = wallRingColliders({ ...base, yaw, doorGapWidth: 0 });
    // At 45 degrees, no collider should land back on the unrotated axis-
    // aligned wall lines (x = +-halfWidth or z = +-halfDepth), except
    // incidentally at the origin-adjacent samples, so check the bulk of them.
    const onUnrotatedAxis = rotated.filter(
      (c) => Math.abs(Math.abs(c.x) - 3) < 1e-6 || Math.abs(Math.abs(c.z) - 4) < 1e-6
    );
    expect(onUnrotatedAxis.length).toBeLessThan(rotated.length * 0.1);
  });

  it('places a rotated wall at the world offset implied by the yaw', () => {
    // A footprint centred at the world origin, yawed 90 degrees: the local
    // left wall (x=-halfWidth) should land on the world +z axis.
    const colliders = wallRingColliders({ ...base, yaw: Math.PI / 2, doorGapWidth: 0 });
    const leftWallWorld = toWorld(0, 0, Math.PI / 2, -3, 0);
    expect(colliders.some((c) => Math.hypot(c.x - leftWallWorld.x, c.z - leftWallWorld.z) < 1e-6)).toBe(
      true
    );
  });

  it('offsets the whole ring by the given world origin', () => {
    const colliders = wallRingColliders({ ...base, originX: 50, originZ: -20, doorGapWidth: 0 });
    expect(colliders.every((c) => c.x >= 47 && c.x <= 53)).toBe(true);
    expect(colliders.every((c) => c.z >= -24 && c.z <= -16)).toBe(true);
  });
});
