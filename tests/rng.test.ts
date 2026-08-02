import { describe, expect, it } from 'vitest';
import {
  chunkRng,
  hashSeed,
  mulberry32,
  pick,
  pickWeighted,
  range,
  rangeInt,
  subRng
} from '../src/world/gen/Rng';

/**
 * Determinism is a hard constraint (CLAUDE.md #6), and its failure mode is
 * slow: a world that regenerates slightly differently only shows up when a
 * player reloads into a house buried in a hill. So the properties get asserted
 * rather than assumed.
 */

describe('hashSeed', () => {
  it('is stable for the same inputs', () => {
    expect(hashSeed('meadows', 3, 7)).toBe(hashSeed('meadows', 3, 7));
  });

  it('is not symmetric across coordinates', () => {
    // A symmetric hash mirrors the entire world across the diagonal, which
    // looks plausible enough at a glance to survive review.
    expect(hashSeed('meadows', 2, 3)).not.toBe(hashSeed('meadows', 3, 2));
  });

  it('separates neighbouring chunks', () => {
    expect(hashSeed('s', 0, 1)).not.toBe(hashSeed('s', 1, 0));
    expect(hashSeed('s', 0, 0)).not.toBe(hashSeed('s', 0, 1));
  });

  it('separates different world seeds', () => {
    expect(hashSeed('alpha', 5, 5)).not.toBe(hashSeed('beta', 5, 5));
  });

  it('handles negative coordinates', () => {
    expect(hashSeed('s', -4, -9)).not.toBe(hashSeed('s', 4, 9));
    expect(Number.isFinite(hashSeed('s', -4, -9))).toBe(true);
  });

  it('always returns an unsigned 32-bit integer', () => {
    for (let i = -50; i < 50; i++) {
      const h = hashSeed('seed', i, i * 7);
      expect(Number.isInteger(h)).toBe(true);
      expect(h).toBeGreaterThanOrEqual(0);
      expect(h).toBeLessThan(2 ** 32);
    }
  });
});

describe('mulberry32', () => {
  it('produces the same sequence from the same seed', () => {
    const a = mulberry32(12345);
    const b = mulberry32(12345);
    for (let i = 0; i < 100; i++) expect(a()).toBe(b());
  });

  it('stays inside [0, 1)', () => {
    const rng = mulberry32(99);
    for (let i = 0; i < 5000; i++) {
      const v = rng();
      expect(v).toBeGreaterThanOrEqual(0);
      expect(v).toBeLessThan(1);
    }
  });

  it('is roughly uniform across ten buckets', () => {
    const rng = mulberry32(7);
    const buckets = new Array<number>(10).fill(0);
    const n = 100_000;
    for (let i = 0; i < n; i++) {
      const idx = Math.floor(rng() * 10);
      buckets[idx] = (buckets[idx] ?? 0) + 1;
    }
    // Within 10% of even. Loose enough not to be flaky, tight enough to catch
    // a generator that clumps.
    for (const count of buckets) {
      expect(count).toBeGreaterThan((n / 10) * 0.9);
      expect(count).toBeLessThan((n / 10) * 1.1);
    }
  });
});

describe('chunkRng', () => {
  it('regenerates a chunk identically regardless of visit order', () => {
    const first = Array.from({ length: 20 }, chunkRng('meadows', 4, -2));
    const second = Array.from({ length: 20 }, chunkRng('meadows', 4, -2));
    expect(first).toEqual(second);
  });

  it('gives adjacent chunks unrelated streams', () => {
    const a = Array.from({ length: 10 }, chunkRng('meadows', 0, 0));
    const b = Array.from({ length: 10 }, chunkRng('meadows', 0, 1));
    expect(a).not.toEqual(b);
  });
});

describe('subRng', () => {
  it('keeps passes independent so adding one does not shift the others', () => {
    // This is the property that lets a new scatter pass ship without moving
    // every tree in every existing save.
    const trees = Array.from({ length: 10 }, subRng('s', 'trees', 1, 1));
    const rocks = Array.from({ length: 10 }, subRng('s', 'rocks', 1, 1));
    expect(trees).not.toEqual(rocks);
    expect(Array.from({ length: 10 }, subRng('s', 'trees', 1, 1))).toEqual(trees);
  });
});

describe('range helpers', () => {
  it('range stays within bounds', () => {
    const rng = mulberry32(3);
    for (let i = 0; i < 1000; i++) {
      const v = range(rng, -5, 12);
      expect(v).toBeGreaterThanOrEqual(-5);
      expect(v).toBeLessThan(12);
    }
  });

  it('rangeInt is inclusive at both ends', () => {
    const rng = mulberry32(11);
    const seen = new Set<number>();
    for (let i = 0; i < 5000; i++) seen.add(rangeInt(rng, 2, 6));
    expect([...seen].sort((a, b) => a - b)).toEqual([2, 3, 4, 5, 6]);
  });
});

describe('pick', () => {
  it('returns undefined for an empty list', () => {
    expect(pick(mulberry32(1), [])).toBeUndefined();
  });

  it('only ever returns members of the list', () => {
    const rng = mulberry32(5);
    const items = ['a', 'b', 'c'];
    for (let i = 0; i < 500; i++) expect(items).toContain(pick(rng, items));
  });
});

describe('pickWeighted', () => {
  const items = [
    { id: 'common', w: 70 },
    { id: 'uncommon', w: 25 },
    { id: 'rare', w: 5 },
    { id: 'never', w: 0 }
  ];

  it('never returns a zero-weight entry', () => {
    const rng = mulberry32(42);
    for (let i = 0; i < 20_000; i++) {
      expect(pickWeighted(rng, items, (i2) => i2.w)?.id).not.toBe('never');
    }
  });

  it('respects the weights', () => {
    const rng = mulberry32(8);
    const counts: Record<string, number> = {};
    const n = 60_000;
    for (let i = 0; i < n; i++) {
      const id = pickWeighted(rng, items, (x) => x.w)?.id ?? '?';
      counts[id] = (counts[id] ?? 0) + 1;
    }
    expect((counts.common ?? 0) / n).toBeCloseTo(0.7, 1);
    expect((counts.uncommon ?? 0) / n).toBeCloseTo(0.25, 1);
    expect((counts.rare ?? 0) / n).toBeCloseTo(0.05, 1);
  });

  it('returns undefined when every weight is non-positive', () => {
    expect(pickWeighted(mulberry32(1), [{ w: 0 }, { w: -3 }], (i) => i.w)).toBeUndefined();
  });

  it('never returns undefined when some weight is positive', () => {
    // The floating-point sliver at the end of the walk must not leak a
    // "nothing spawned" into the spawn tables.
    const rng = mulberry32(17);
    for (let i = 0; i < 20_000; i++) {
      expect(pickWeighted(rng, items, (x) => x.w)).toBeDefined();
    }
  });
});
