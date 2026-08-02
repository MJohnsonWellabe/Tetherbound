import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import scatterConfig from '../src/data/scatter.json';
import { allowedInClearings, clearingsFor, resetClearings } from '../src/world/Clearings';
import { villageHousePlacements } from '../src/world/Landmarks';
import { Terrain } from '../src/world/gen/Terrain';

/**
 * Regression for: village houses sit on a ring at `village.radius * 0.55`,
 * outside the village-wide clearing's ground-cover reach, so grass and
 * flowers grew straight through house floors (worst at the home house,
 * where a new player's first frame put a plant beside the bed).
 *
 * The fix is a clearing per house, sized to that house's own footprint. The
 * invariant that has to hold forever after is that Structures.ts (placing
 * the buildings) and Clearings.ts (keeping scatter off their floors) read
 * that footprint from the exact same function, or the two can drift apart
 * again the same way the village-wide clearing did.
 */

const SEEDS = ['hollowbrook', 'meadows', 'tether', 'a', 'zzz'];
const FAMILY_IDS = (scatterConfig.families as Array<{ id: string }>).map((f) => f.id);

describe('villageHousePlacements', () => {
  it('is deterministic for a given seed, across independent Terrain instances', () => {
    // Structures.ts and Clearings.ts each receive their own reference to a
    // terrain sampler; nothing may make the result depend on which instance
    // it is, only on the seed.
    for (const seed of SEEDS) {
      const a = villageHousePlacements(new Terrain(seed), seed);
      const b = villageHousePlacements(new Terrain(seed), seed);
      expect(a).toEqual(b);
    }
  });

  it('places every house at a finite position with a positive footprint', () => {
    for (const seed of SEEDS) {
      const houses = villageHousePlacements(new Terrain(seed), seed);
      expect(houses.length).toBeGreaterThan(0);
      for (const h of houses) {
        expect(Number.isFinite(h.x)).toBe(true);
        expect(Number.isFinite(h.z)).toBe(true);
        expect(h.width).toBeGreaterThan(0);
        expect(h.depth).toBeGreaterThan(0);
      }
    }
  });

  it('puts different seeds in different places', () => {
    const positions = SEEDS.map((s) => {
      const houses = villageHousePlacements(new Terrain(s), s);
      return houses.map((h) => `${Math.round(h.x)},${Math.round(h.z)}`).join('|');
    });
    expect(new Set(positions).size).toBeGreaterThan(1);
  });

  it('is the one place Structures.ts and Clearings.ts both get a house position from', () => {
    // A source-level guard against the exact bug this file exists to fix: two
    // independent copies of the ring-placement maths that can silently drift.
    const structures = readFileSync(join(__dirname, '..', 'src', 'world', 'Structures.ts'), 'utf8');
    const clearings = readFileSync(join(__dirname, '..', 'src', 'world', 'Clearings.ts'), 'utf8');
    expect(structures).toMatch(/villageHousePlacements/);
    expect(clearings).toMatch(/villageHousePlacements/);
    // Neither file may compute a house ring position on its own any more.
    expect(structures).not.toMatch(/village\.radius\s*\*\s*0\.55/);
  });
});

describe('clearingsFor and house footprints', () => {
  it('rejects a point inside a house footprint for every scatter family, ground cover included', () => {
    for (const seed of SEEDS) {
      resetClearings();
      const terrain = new Terrain(seed);
      const clearings = clearingsFor(terrain, seed);
      const houses = villageHousePlacements(terrain, seed);

      for (const h of houses) {
        // The house's own centre is inside its own footprint by construction.
        for (const family of FAMILY_IDS) {
          expect(allowedInClearings(clearings, family, h.x, h.z)).toBe(false);
        }

        // A point offset toward one corner, still safely inside the box
        // (half the footprint's smaller half-extent), catches a clearing
        // sized only to the centre rather than the whole footprint.
        const insideX = h.x + Math.cos(h.yaw) * (Math.min(h.width, h.depth) / 4);
        const insideZ = h.z + Math.sin(h.yaw) * (Math.min(h.width, h.depth) / 4);
        for (const family of FAMILY_IDS) {
          expect(allowedInClearings(clearings, family, insideX, insideZ)).toBe(false);
        }
      }
    }
  });

  it('still allows ground cover well outside any house, just past the village clearing', () => {
    // A regression guard the other way: the per-house fix must not have
    // widened into another village-sized bald patch.
    resetClearings();
    const terrain = new Terrain('hollowbrook');
    const clearings = clearingsFor(terrain, 'hollowbrook');
    // Just past the village-wide ground-cover radius, and far from every
    // house's own footprint.
    expect(allowedInClearings(clearings, 'grass', 21, 21)).toBe(true);
  });
});
