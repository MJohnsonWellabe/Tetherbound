import { describe, expect, it } from 'vitest';
import { scatterInRect, type ScatterOptions } from '../src/world/gen/Scatter';

const base: ScatterOptions = {
  seed: 'hollowbrook',
  label: 'trees',
  minDistance: 6
};

function keysIn(opts: ScatterOptions, x0: number, z0: number, x1: number, z1: number): Set<string> {
  return new Set(scatterInRect(opts, x0, z0, x1, z1).map((p) => p.key));
}

describe('scatterInRect chunk independence', () => {
  it('produces the same points for the same rectangle', () => {
    const a = scatterInRect(base, 0, 0, 64, 64);
    const b = scatterInRect(base, 0, 0, 64, 64);
    expect(a).toEqual(b);
  });

  it('gives identical results whether a region is sampled whole or in quarters', () => {
    // This is the property the whole design exists for. Sampling per chunk must
    // equal sampling the region at once, or props clump at every chunk seam and
    // walking away and back regenerates a different world.
    const whole = keysIn(base, 0, 0, 128, 128);
    const quarters = new Set([
      ...keysIn(base, 0, 0, 64, 64),
      ...keysIn(base, 64, 0, 128, 64),
      ...keysIn(base, 0, 64, 64, 128),
      ...keysIn(base, 64, 64, 128, 128)
    ]);
    expect(quarters).toEqual(whole);
  });

  it('does not depend on chunk alignment', () => {
    // Same physical area, carved on a different grid offset.
    const aligned = keysIn(base, -64, -64, 64, 64);
    const offset = new Set([
      ...keysIn(base, -64, -64, -19, 64),
      ...keysIn(base, -19, -64, 23, 64),
      ...keysIn(base, 23, -64, 64, 64)
    ]);
    expect(offset).toEqual(aligned);
  });

  it('places no point outside the requested rectangle', () => {
    for (const p of scatterInRect(base, 10, -30, 74, 34)) {
      expect(p.x).toBeGreaterThanOrEqual(10);
      expect(p.x).toBeLessThan(74);
      expect(p.z).toBeGreaterThanOrEqual(-30);
      expect(p.z).toBeLessThan(34);
    }
  });

  it('assigns every point a unique stable key', () => {
    const points = scatterInRect(base, 0, 0, 256, 256);
    const keys = new Set(points.map((p) => p.key));
    expect(keys.size).toBe(points.length);
    // Keys must survive a reload, since worldDeltas records harvested nodes
    // by key and a shifted key points at a different bush.
    expect(new Set(scatterInRect(base, 0, 0, 256, 256).map((p) => p.key))).toEqual(keys);
  });
});

describe('scatterInRect spacing', () => {
  it('respects the minimum distance', () => {
    const points = scatterInRect(base, 0, 0, 200, 200);
    expect(points.length).toBeGreaterThan(50);
    for (let i = 0; i < points.length; i++) {
      for (let j = i + 1; j < points.length; j++) {
        const a = points[i];
        const b = points[j];
        if (!a || !b) continue;
        expect(Math.hypot(a.x - b.x, a.z - b.z)).toBeGreaterThanOrEqual(base.minDistance);
      }
    }
  });

  it('respects spacing across a seam, not just within one chunk', () => {
    // The failure mode that motivated the design: per-chunk sampling only
    // spaces points against others in the same chunk, so pairs straddling a
    // seam end up on top of each other.
    const left = scatterInRect(base, -64, -64, 0, 64);
    const right = scatterInRect(base, 0, -64, 64, 64);
    for (const a of left) {
      for (const b of right) {
        expect(Math.hypot(a.x - b.x, a.z - b.z)).toBeGreaterThanOrEqual(base.minDistance);
      }
    }
  });

  it('scales point count with minDistance', () => {
    const sparse = scatterInRect({ ...base, minDistance: 20 }, 0, 0, 400, 400).length;
    const dense = scatterInRect({ ...base, minDistance: 5 }, 0, 0, 400, 400).length;
    expect(dense).toBeGreaterThan(sparse * 4);
  });
});

describe('scatterInRect mask', () => {
  it('places nothing where the mask excludes everything', () => {
    expect(scatterInRect({ ...base, mask: () => false }, 0, 0, 256, 256)).toEqual([]);
  });

  it('honours a spatial mask', () => {
    const points = scatterInRect({ ...base, mask: (x) => x < 100 }, 0, 0, 200, 200);
    expect(points.length).toBeGreaterThan(20);
    for (const p of points) expect(p.x).toBeLessThan(100);
  });

  it('does not thin the population it allows', () => {
    // A mask is exclusion, not thinning. Inside the allowed region the scatter
    // must be as dense as an unmasked one, or shorelines and clearings would
    // come with a bald margin.
    //
    // Not exact equality: the unmasked run still lets candidates just past
    // x=150 suppress points inside the rectangle, while the masked run
    // excludes them, so the masked count comes out a couple higher along that
    // edge. That is the mask working correctly. What matters is that it does
    // not THIN, which a percentage bound captures and an equality does not.
    const masked = scatterInRect({ ...base, mask: (x) => x < 150 }, 0, 0, 150, 300).length;
    const plain = scatterInRect(base, 0, 0, 150, 300).length;
    expect(masked).toBeGreaterThanOrEqual(plain);
    expect(masked).toBeLessThan(plain * 1.05);
  });

  it('leaves no bald ring along a mask edge', () => {
    // The failure mode: an excluded candidate suppresses a valid neighbour, so
    // every shoreline gets a prop-free margin one minDistance wide.
    const points = scatterInRect({ ...base, mask: (x) => x < 100 }, 0, 0, 200, 200);
    const nearEdge = points.filter((p) => p.x > 100 - base.minDistance * 2).length;
    const nearMiddle = points.filter((p) => p.x > 50 && p.x < 50 + base.minDistance * 2).length;
    expect(nearEdge).toBeGreaterThan(nearMiddle * 0.6);
  });

  it('keeps a mask chunk-independent', () => {
    const opts: ScatterOptions = { ...base, mask: (x, z) => (x + z) % 97 > 20 };
    const whole = keysIn(opts, 0, 0, 128, 128);
    const halves = new Set([...keysIn(opts, 0, 0, 64, 128), ...keysIn(opts, 64, 0, 128, 128)]);
    expect(halves).toEqual(whole);
  });
});

describe('scatterInRect density', () => {
  it('actually controls the count', () => {
    // Regression. Thinning candidates BEFORE the spacing pass barely moved the
    // count, because minimum spacing is the binding constraint and the
    // survivors simply closed ranks: measured, density 0.5 took 837 points to
    // 830. Thinning after spacing is what makes the knob mean something.
    const full = scatterInRect(base, 0, 0, 300, 300).length;
    const half = scatterInRect({ ...base, density: () => 0.5 }, 0, 0, 300, 300).length;
    expect(half).toBeGreaterThan(full * 0.35);
    expect(half).toBeLessThan(full * 0.65);
  });

  it('is monotonic', () => {
    const counts = [0.25, 0.5, 0.75, 1].map(
      (d) => scatterInRect({ ...base, density: () => d }, 0, 0, 300, 300).length
    );
    for (let i = 1; i < counts.length; i++) {
      expect(counts[i] ?? 0).toBeGreaterThanOrEqual(counts[i - 1] ?? 0);
    }
  });

  it('places nothing at zero density', () => {
    expect(scatterInRect({ ...base, density: () => 0 }, 0, 0, 256, 256)).toEqual([]);
  });

  it('keeps partial density chunk-independent too', () => {
    const opts: ScatterOptions = { ...base, density: (x, z) => (Math.abs(x + z) % 40) / 40 };
    const whole = keysIn(opts, 0, 0, 128, 128);
    const halves = new Set([...keysIn(opts, 0, 0, 64, 128), ...keysIn(opts, 64, 0, 128, 128)]);
    expect(halves).toEqual(whole);
  });

  it('thins an existing population rather than reshuffling it', () => {
    // Density-thinned points must be a strict subset of the undthinned ones,
    // so raising density adds trees instead of moving the ones already there.
    const full = keysIn(base, 0, 0, 200, 200);
    const thin = keysIn({ ...base, density: () => 0.5 }, 0, 0, 200, 200);
    for (const key of thin) expect(full.has(key)).toBe(true);
  });
});

describe('scatterInRect passes', () => {
  it('keeps different labels on different points', () => {
    // Trees and rocks must not stack on the same coordinates.
    const trees = scatterInRect({ ...base, label: 'trees' }, 0, 0, 128, 128);
    const rocks = scatterInRect({ ...base, label: 'rocks' }, 0, 0, 128, 128);
    const treeSpots = new Set(trees.map((p) => `${p.x.toFixed(3)},${p.z.toFixed(3)}`));
    const overlap = rocks.filter((p) => treeSpots.has(`${p.x.toFixed(3)},${p.z.toFixed(3)}`));
    expect(overlap).toEqual([]);
  });

  it('gives each point a rotation and a roll in range', () => {
    for (const p of scatterInRect(base, 0, 0, 128, 128)) {
      expect(p.roll).toBeGreaterThanOrEqual(0);
      expect(p.roll).toBeLessThan(1);
      expect(p.rotation).toBeGreaterThanOrEqual(0);
      expect(p.rotation).toBeLessThan(Math.PI * 2);
    }
  });
});
