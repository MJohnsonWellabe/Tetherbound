import { describe, expect, it } from 'vitest';
import { centreOf, placeStarters } from '../src/ui/starterPlacement';

/**
 * Where the three starters stand. Written before StarterPicker wires it to
 * the scene, same as combat's stagePlacement.ts.
 */

const CFG = { forward: 1.3, spread: 1.0 };

describe('placeStarters', () => {
  it('puts the middle spot forward of the anchor, facing the same way', () => {
    const spots = placeStarters({ x: 0, z: 0, yaw: 0 }, 3, CFG);
    expect(spots).toHaveLength(3);
    expect(spots[1]?.x).toBeCloseTo(0);
    expect(spots[1]?.z).toBeCloseTo(CFG.forward);
    expect(spots[1]?.yaw).toBeCloseTo(0);
  });

  it('spreads the outer two spots symmetrically, perpendicular to facing', () => {
    const spots = placeStarters({ x: 0, z: 0, yaw: 0 }, 3, CFG);
    expect(spots[0]?.x).toBeCloseTo(-CFG.spread);
    expect(spots[2]?.x).toBeCloseTo(CFG.spread);
    expect(spots[0]?.z).toBeCloseTo(spots[2]?.z ?? NaN);
  });

  it('every spot faces the anchor facing, not the line between them', () => {
    const spots = placeStarters({ x: 0, z: 0, yaw: 0 }, 3, CFG);
    for (const spot of spots) expect(spot.yaw).toBeCloseTo(0);
  });

  it('rotates the whole row with the anchor yaw', () => {
    const spots = placeStarters({ x: 0, z: 0, yaw: Math.PI / 2 }, 3, CFG);
    // Facing +X now: forward moves along +X, spread along -Z.
    expect(spots[1]?.x).toBeCloseTo(CFG.forward);
    expect(spots[1]?.z).toBeCloseTo(0);
    for (const spot of spots) expect(spot.yaw).toBeCloseTo(Math.PI / 2);
  });

  it('translates with the anchor position', () => {
    const spots = placeStarters({ x: 5, z: -3, yaw: 0 }, 3, CFG);
    expect(spots[1]?.x).toBeCloseTo(5);
    expect(spots[1]?.z).toBeCloseTo(-3 + CFG.forward);
  });

  it('handles a single spot without dividing by zero', () => {
    const spots = placeStarters({ x: 0, z: 0, yaw: 0 }, 1, CFG);
    expect(spots).toHaveLength(1);
    expect(spots[0]?.x).toBeCloseTo(0);
  });
});

describe('centreOf', () => {
  it('averages the row', () => {
    const spots = placeStarters({ x: 0, z: 0, yaw: 0 }, 3, CFG);
    const centre = centreOf(spots);
    expect(centre.x).toBeCloseTo(0);
    expect(centre.z).toBeCloseTo(CFG.forward);
  });

  it('is the origin for an empty row', () => {
    expect(centreOf([])).toEqual({ x: 0, z: 0 });
  });
});
