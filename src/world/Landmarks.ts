import landmarks from '../data/landmarks.json';
import { subRng } from './gen/Rng';
import type { Terrain } from './gen/Terrain';

/**
 * Where the fixed points of the Meadows end up.
 *
 * GAME_DESIGN.md section 9: Hollowbrook is always at the origin, the Hall sits
 * at a seeded angle 900 to 1200m out on flat ground with a road stub pointing
 * back at the village, and the standing stones at a second seeded angle 500 to
 * 700m out.
 *
 * Pure: it takes a terrain sampler and returns coordinates. No meshes, no
 * scene, which is what lets the placement rules be tested directly rather than
 * inferred from a screenshot.
 */

export interface Placement {
  x: number;
  z: number;
  y: number;
  /** Facing back toward the village, so a door faces its own road. */
  yaw: number;
  /** Worst slope found across the footprint, in degrees. Reported for tests. */
  slope: number;
}

export interface SearchSpec {
  distance: readonly [number, number];
  maxSlope: number;
  flattenRadius: number;
}

/**
 * Worst slope across a ring around a candidate centre.
 *
 * Sampling the centre alone is not enough: a single flat pixel on a hillside
 * passes, and then the building's far corner is six meters underground.
 */
function worstSlope(terrain: Terrain, x: number, z: number, radius: number): number {
  let worst = terrain.slopeAt(x, z);
  const SAMPLES = 8;
  for (let i = 0; i < SAMPLES; i++) {
    const angle = (i / SAMPLES) * Math.PI * 2;
    const sx = x + Math.cos(angle) * radius;
    const sz = z + Math.sin(angle) * radius;
    worst = Math.max(worst, terrain.slopeAt(sx, sz));
  }
  return worst;
}

/** Highest ground under a footprint, which is where a platform has to sit. */
export function highestUnder(terrain: Terrain, x: number, z: number, radius: number): number {
  let highest = terrain.heightAt(x, z);
  const SAMPLES = 8;
  for (let i = 0; i < SAMPLES; i++) {
    const angle = (i / SAMPLES) * Math.PI * 2;
    highest = Math.max(
      highest,
      terrain.heightAt(x + Math.cos(angle) * radius, z + Math.sin(angle) * radius)
    );
  }
  return highest;
}

/**
 * Search the distance band for ground flat enough to build on.
 *
 * Always returns a placement. If no candidate clears `maxSlope`, the flattest
 * one seen wins: world generation that can fail to place the Hall is world
 * generation that can produce a save with no win condition in it, and a
 * slightly tilted Hall is a much smaller problem than a missing one.
 */
export function findPlacement(
  terrain: Terrain,
  seed: string,
  label: string,
  spec: SearchSpec
): Placement {
  const rng = subRng(seed, `landmark:${label}`);
  const [minDistance, maxDistance] = spec.distance;

  let best: Placement | null = null;

  for (let attempt = 0; attempt < landmarks.search.attempts; attempt++) {
    const angle = rng() * Math.PI * 2;
    const distance = minDistance + rng() * (maxDistance - minDistance);
    const x = Math.cos(angle) * distance;
    const z = Math.sin(angle) * distance;

    const y = terrain.heightAt(x, z);
    // Never in the river. A Hall in a riverbed is unreachable and a set of
    // standing stones underwater is invisible.
    if (y <= 1) continue;

    const slope = worstSlope(terrain, x, z, spec.flattenRadius);
    // Face the village: atan2 of the vector from here back to the origin.
    const candidate: Placement = { x, z, y, yaw: Math.atan2(-x, -z), slope };

    if (slope <= spec.maxSlope) return candidate;
    if (!best || slope < best.slope) best = candidate;
  }

  if (best) return best;

  // Every candidate was underwater, which means the seed put a lot of river in
  // this band. Fall back to a fixed bearing at the near edge rather than
  // returning nothing.
  const x = 0;
  const z = minDistance;
  return {
    x,
    z,
    y: terrain.heightAt(x, z),
    yaw: Math.atan2(-x, -z),
    slope: worstSlope(terrain, x, z, spec.flattenRadius)
  };
}

export function hallPlacement(terrain: Terrain, seed: string): Placement {
  return findPlacement(terrain, seed, 'hall', {
    distance: landmarks.hall.distance as [number, number],
    maxSlope: landmarks.hall.maxSlope,
    flattenRadius: landmarks.hall.flattenRadius
  });
}

export function stonesPlacement(terrain: Terrain, seed: string): Placement {
  return findPlacement(terrain, seed, 'standingStones', {
    distance: landmarks.standingStones.distance as [number, number],
    maxSlope: landmarks.standingStones.maxSlope,
    flattenRadius: landmarks.standingStones.flattenRadius
  });
}

export const LANDMARK_CONFIG = landmarks;
