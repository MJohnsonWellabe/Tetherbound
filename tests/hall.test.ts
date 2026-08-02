import { describe, expect, it } from 'vitest';
import { DOOR_WIDTH, WALL_STEP, WALL_THICKNESS } from '../src/world/Hall';
import landmarks from '../src/data/landmarks.json';
import { wallRingColliders } from '../src/world/WallRing';

/**
 * The Hall's front entrance, checked against the exact numbers buildHall
 * uses (imported, not hand-copied), rather than only the generic WallRing
 * maths in wallRing.test.ts.
 *
 * Regression for: the Hall used to compute its own colliders inline, pulling
 * the boundary spheres back by the collider radius alone. With
 * WALL_STEP=3 (radius 2.25) and the player's own 0.36m radius added at test
 * time, `reach` (2.61) exceeded the last collider's distance from the
 * centreline (2.5), so the two boundary spheres overlapped clear across the
 * 5m gap and the front door was entirely impassable.
 */

const { width: WIDTH, depth: DEPTH } = landmarks.hall.footprint;
const PLAYER_RADIUS = landmarks.playerRadius;

function hallColliders() {
  return wallRingColliders({
    halfWidth: (WIDTH - WALL_THICKNESS) / 2,
    halfDepth: (DEPTH - WALL_THICKNESS) / 2,
    originX: 0,
    originZ: 0,
    yaw: 0,
    step: WALL_STEP,
    doorGapWidth: DOOR_WIDTH,
    doorX: 0,
    playerRadius: PLAYER_RADIUS
  });
}

describe('Hall front entrance', () => {
  it('is passable: a walkable slot exists at the centreline for the real player radius', () => {
    const colliders = hallColliders();
    const halfD = (DEPTH - WALL_THICKNESS) / 2;
    const front = colliders.filter((c) => Math.abs(c.z - -halfD) < 1e-6);

    // No front collider's own reach (radius + player radius) covers x=0: if
    // one did, the centreline itself would be blocked, which is exactly the
    // old bug (two boundary spheres overlapping across it).
    const centreBlocked = front.some((c) => {
      const reach = c.radius + PLAYER_RADIUS;
      return Math.abs(c.x - 0) < reach;
    });
    expect(centreBlocked).toBe(false);
  });

  it('gives a walkable slot at least as wide as the configured door width', () => {
    const colliders = hallColliders();
    const halfD = (DEPTH - WALL_THICKNESS) / 2;
    const front = colliders.filter((c) => Math.abs(c.z - -halfD) < 1e-6);
    const left = front.filter((c) => c.x < 0);
    const right = front.filter((c) => c.x > 0);
    const leftReach = Math.max(...left.map((c) => c.x + c.radius + PLAYER_RADIUS));
    const rightReach = Math.min(...right.map((c) => c.x - c.radius - PLAYER_RADIUS));
    expect(rightReach - leftReach).toBeGreaterThanOrEqual(DOOR_WIDTH - 1e-6);
  });
});
