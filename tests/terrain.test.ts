import { describe, expect, it } from 'vitest';
import { Terrain, WATER_LEVEL } from '../src/world/gen/Terrain';

/**
 * The heightfield is sampled by physics, the ground mesh, the camera, prop
 * placement and spawn logic. If any of those disagreed with the others the
 * player would fall through the world or float above it, so the contract is
 * "one function, same answer every time" and that gets asserted.
 */

const SEED = 'hollowbrook';

describe('Terrain determinism', () => {
  it('returns the same height for the same point', () => {
    const t = new Terrain(SEED);
    for (const [x, z] of [
      [0, 0],
      [123.5, -87.25],
      [-940, 610],
      [1200, 1200]
    ] as const) {
      expect(t.heightAt(x, z)).toBe(t.heightAt(x, z));
    }
  });

  it('two instances of the same seed agree everywhere sampled', () => {
    // This is the property that lets a save store a seed instead of terrain,
    // and lets two devices load the same world.
    const a = new Terrain(SEED);
    const b = new Terrain(SEED);
    for (let i = 0; i < 400; i++) {
      const x = (i * 37) % 2000 - 1000;
      const z = (i * 91) % 2000 - 1000;
      expect(a.heightAt(x, z)).toBe(b.heightAt(x, z));
    }
  });

  it('different seeds produce different worlds', () => {
    const a = new Terrain('alpha');
    const b = new Terrain('beta');
    let differences = 0;
    for (let i = 0; i < 200; i++) {
      const x = i * 13 - 500;
      const z = i * 29 - 700;
      if (Math.abs(a.heightAt(x, z) - b.heightAt(x, z)) > 0.5) differences++;
    }
    expect(differences).toBeGreaterThan(150);
  });
});

describe('Terrain shape', () => {
  const t = new Terrain(SEED);

  it('produces finite heights across a wide area', () => {
    for (let x = -1500; x <= 1500; x += 97) {
      for (let z = -1500; z <= 1500; z += 97) {
        const h = t.heightAt(x, z);
        expect(Number.isFinite(h)).toBe(true);
        // A sane range. Catches an octave with a runaway amplitude.
        expect(h).toBeGreaterThan(-40);
        expect(h).toBeLessThan(120);
      }
    }
  });

  it('is continuous: no cliffs between adjacent samples', () => {
    // A discontinuity here is a seam the player can fall through.
    let worst = 0;
    for (let x = -600; x <= 600; x += 3) {
      for (let z = -600; z <= 600; z += 60) {
        worst = Math.max(worst, Math.abs(t.heightAt(x, z) - t.heightAt(x + 1, z)));
      }
    }
    expect(worst).toBeLessThan(6);
  });

  it('keeps Hollowbrook flat and buildable', () => {
    // GAME_DESIGN.md section 9: the village always sits at world origin. It
    // needs ground you can actually place a workbench on.
    let min = Infinity;
    let max = -Infinity;
    for (let x = -40; x <= 40; x += 5) {
      for (let z = -40; z <= 40; z += 5) {
        const h = t.heightAt(x, z);
        min = Math.min(min, h);
        max = Math.max(max, h);
      }
    }
    expect(max - min).toBeLessThan(0.5);
    expect(min).toBeGreaterThan(WATER_LEVEL);
  });

  it('blends the village plateau into the surrounding land', () => {
    // A flatten with a hard edge leaves a circular cliff around the village.
    let worst = 0;
    for (let a = 0; a < Math.PI * 2; a += 0.15) {
      for (let d = 40; d < 110; d += 1) {
        const h1 = t.heightAt(Math.cos(a) * d, Math.sin(a) * d);
        const h2 = t.heightAt(Math.cos(a) * (d + 1), Math.sin(a) * (d + 1));
        worst = Math.max(worst, Math.abs(h1 - h2));
      }
    }
    expect(worst).toBeLessThan(6);
  });

  it('leaves river banks walkable', () => {
    // Regression. The first carve dropped terrain from whatever height it
    // happened to be straight to the river bed over ~25m, producing banks at a
    // median 54 degrees and a worst case of 81. The controller clamps at 45,
    // so the player could see water they could never reach. Fixed with a wide
    // gentle valley plus a narrow bed; this asserts the banks stay climbable.
    const slopes: number[] = [];
    for (let x = -1200; x <= 1200; x += 11) {
      for (let z = -1200; z <= 1200; z += 11) {
        if (t.biomeAt(x, z) === 'riverbank') slopes.push(t.slopeAt(x, z));
      }
    }
    expect(slopes.length).toBeGreaterThan(200);
    slopes.sort((a, b) => a - b);
    const at = (q: number): number => slopes[Math.floor(slopes.length * q)] ?? 0;

    expect(at(0.5)).toBeLessThan(20);
    // 45 degrees is the controller's hard limit. Asserting the 99th percentile
    // rather than the maximum is deliberate: measured, 0.33% of bank samples
    // exceed it, clustered where a river runs into a hillside. That is real
    // terrain and the player simply walks around it. The bug this guards
    // against had a MEDIAN of 54 degrees, so a p99 bound catches it with room
    // to spare while leaving the world allowed to have a steep corner.
    expect(at(0.99)).toBeLessThan(45);
  });

  it('carves rivers below water level somewhere in the world', () => {
    let submerged = 0;
    for (let x = -1500; x <= 1500; x += 23) {
      for (let z = -1500; z <= 1500; z += 23) {
        if (t.heightAt(x, z) < WATER_LEVEL) submerged++;
      }
    }
    // Some water, but the Meadows is grassland and not a swamp.
    expect(submerged).toBeGreaterThan(0);
    const total = Math.pow(Math.floor(3000 / 23) + 1, 2);
    expect(submerged / total).toBeLessThan(0.25);
  });
});

describe('Terrain normals and slope', () => {
  const t = new Terrain(SEED);

  it('returns unit normals pointing upward', () => {
    for (let i = 0; i < 200; i++) {
      const n = t.normalAt(i * 17 - 800, i * 41 - 900);
      expect(Math.hypot(n.x, n.y, n.z)).toBeCloseTo(1, 6);
      // Terrain is a heightfield, so it can never overhang.
      expect(n.y).toBeGreaterThan(0);
    }
  });

  it('reports flat ground as flat in the village', () => {
    expect(t.slopeAt(0, 0)).toBeLessThan(3);
  });

  it('reports slope in degrees within range', () => {
    for (let i = 0; i < 300; i++) {
      const s = t.slopeAt(i * 31 - 1000, i * 13 - 400);
      expect(s).toBeGreaterThanOrEqual(0);
      expect(s).toBeLessThan(90);
    }
  });
});

describe('Terrain biomes', () => {
  const t = new Terrain(SEED);

  it('classifies every point as a known biome', () => {
    const known = new Set(['meadow', 'grove', 'rock', 'riverbank', 'water']);
    for (let x = -900; x <= 900; x += 71) {
      for (let z = -900; z <= 900; z += 71) {
        expect(known.has(t.biomeAt(x, z))).toBe(true);
      }
    }
  });

  it('keeps meadow the dominant surface', () => {
    // The biome is called the Meadows. Grassland should win by a wide margin,
    // or the scatter tables and spawn weights are tuned against the wrong mix.
    const counts: Record<string, number> = {};
    let total = 0;
    for (let x = -1200; x <= 1200; x += 29) {
      for (let z = -1200; z <= 1200; z += 29) {
        const b = t.biomeAt(x, z);
        counts[b] = (counts[b] ?? 0) + 1;
        total++;
      }
    }
    expect((counts.meadow ?? 0) / total).toBeGreaterThan(0.4);
  });

  it('agrees with isSubmerged about water', () => {
    for (let x = -800; x <= 800; x += 37) {
      for (let z = -800; z <= 800; z += 37) {
        expect(t.biomeAt(x, z) === 'water').toBe(t.isSubmerged(x, z));
      }
    }
  });
});
