import { describe, expect, it } from 'vitest';
import landmarks from '../src/data/landmarks.json';
import { findPlacement, hallPlacement, stonesPlacement } from '../src/world/Landmarks';
import { Terrain } from '../src/world/gen/Terrain';

/**
 * Landmark placement decides whether a seed produces a finishable game. A Hall
 * in a river, or outside the distance band, or in a different place on a
 * reload, are all ways for a save to contain no win condition.
 */

const SEEDS = ['hollowbrook', 'meadows', 'tether', 'seed-4', 'a', 'zzz'];

describe('the Meadows Hall', () => {
  it('lands inside the published distance band for every seed', () => {
    const [min, max] = landmarks.hall.distance as [number, number];
    for (const seed of SEEDS) {
      const p = hallPlacement(new Terrain(seed), seed);
      const d = Math.hypot(p.x, p.z);
      expect(d).toBeGreaterThanOrEqual(min);
      expect(d).toBeLessThanOrEqual(max);
    }
  });

  it('is never underwater', () => {
    for (const seed of SEEDS) {
      const terrain = new Terrain(seed);
      const p = hallPlacement(terrain, seed);
      expect(terrain.heightAt(p.x, p.z)).toBeGreaterThan(0);
    }
  });

  it('faces back toward the village', () => {
    for (const seed of SEEDS) {
      const p = hallPlacement(new Terrain(seed), seed);
      // yaw points from the Hall to the origin, so walking that heading from
      // the Hall must reduce the distance to Hollowbrook.
      const stepX = p.x + Math.sin(p.yaw) * 10;
      const stepZ = p.z + Math.cos(p.yaw) * 10;
      expect(Math.hypot(stepX, stepZ)).toBeLessThan(Math.hypot(p.x, p.z));
    }
  });

  it('is identical on every regeneration of the same seed', () => {
    for (const seed of SEEDS) {
      const a = hallPlacement(new Terrain(seed), seed);
      const b = hallPlacement(new Terrain(seed), seed);
      expect(a).toEqual(b);
    }
  });

  it('puts different seeds in different places', () => {
    const positions = SEEDS.map((s) => {
      const p = hallPlacement(new Terrain(s), s);
      return `${Math.round(p.x)},${Math.round(p.z)}`;
    });
    expect(new Set(positions).size).toBeGreaterThan(1);
  });
});

describe('the standing stones', () => {
  it('land inside their own band, closer than the Hall', () => {
    const [min, max] = landmarks.standingStones.distance as [number, number];
    const [hallMin] = landmarks.hall.distance as [number, number];
    for (const seed of SEEDS) {
      const p = stonesPlacement(new Terrain(seed), seed);
      const d = Math.hypot(p.x, p.z);
      expect(d).toBeGreaterThanOrEqual(min);
      expect(d).toBeLessThanOrEqual(max);
      expect(d).toBeLessThan(hallMin);
    }
  });

  it('does not sit on top of the village plateau', () => {
    for (const seed of SEEDS) {
      const p = stonesPlacement(new Terrain(seed), seed);
      expect(Math.hypot(p.x, p.z)).toBeGreaterThan(landmarks.village.radius);
    }
  });
});

describe('the search itself', () => {
  it('always returns a placement, even with an impossible slope limit', () => {
    const terrain = new Terrain('hollowbrook');
    const p = findPlacement(terrain, 'hollowbrook', 'impossible', {
      distance: [900, 1200],
      maxSlope: 0,
      flattenRadius: 46
    });
    expect(Number.isFinite(p.x)).toBe(true);
    expect(Number.isFinite(p.z)).toBe(true);
  });

  it('returns the flattest candidate it saw when none clears the limit', () => {
    const terrain = new Terrain('hollowbrook');
    const strict = findPlacement(terrain, 'hollowbrook', 'hall', {
      distance: [900, 1200],
      maxSlope: 0,
      flattenRadius: 46
    });
    const loose = findPlacement(terrain, 'hollowbrook', 'hall', {
      distance: [900, 1200],
      maxSlope: 90,
      flattenRadius: 46
    });
    // The loose search takes the first candidate; the strict one has to beat
    // every candidate it saw, so it cannot be worse.
    expect(strict.slope).toBeLessThanOrEqual(loose.slope);
  });
});
