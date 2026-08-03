import { describe, expect, it } from 'vitest';
import lighting from '../src/data/lighting.json';
import render from '../src/data/render.json';
import { isNight, paletteAt } from '../src/world/TimeOfDay';

/** Rec.709 luminance, the same weighting the visual survey samples with. */
function luma(c: { r: number; g: number; b: number }): number {
  return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
}

/**
 * How much light lands on flat ground facing up, at a point in the cycle.
 *
 * The hemispheric ambient reaches an up-facing surface at full strength and
 * the directional at cos(elevation), and StandardMaterial CLAMPS their sum to
 * 1 before it ever touches the albedo. That clamp is the reason this helper
 * exists rather than a comparison of raw intensities: the palettes once summed
 * to 2.2 on open ground, every lit pixel and every shadowed pixel saturated to
 * the same value, and the whole world rendered as flat albedo with no shading
 * and no visible shadows at all.
 */
function groundLight(cycle: number): { lit: number; shadowed: number; clipped: boolean } {
  const p = paletteAt(cycle);
  const angle = (cycle / lighting.dayFraction) * Math.PI;
  const elevation = Math.sin(Math.min(Math.max(angle, 0), Math.PI));
  const y = Math.max(lighting.sun.minElevation, elevation);
  const x = -Math.cos(angle) * lighting.sun.swing;
  const z = lighting.sun.tilt;
  const nDotL = y / Math.hypot(x, y, z);

  const channel = (a: number, s: number, k: number): number => a * p.ambientIntensity + s * p.sunIntensity * nDotL * k;
  const at = (k: number): { r: number; g: number; b: number } => ({
    r: Math.min(1, channel(p.ambient.r, p.sun.r, k)),
    g: Math.min(1, channel(p.ambient.g, p.sun.g, k)),
    b: Math.min(1, channel(p.ambient.b, p.sun.b, k))
  });
  const raw = Math.max(
    channel(p.ambient.r, p.sun.r, 1),
    channel(p.ambient.g, p.sun.g, 1),
    channel(p.ambient.b, p.sun.b, 1)
  );
  return { lit: luma(at(1)), shadowed: luma(at(render.shadow.darkness)), clipped: raw > 1 };
}

/**
 * Day-night lighting.
 *
 * The palettes and the keyframes moved out of TimeOfDay.ts and into
 * lighting.json. These tests exist because the interpolator is now generic:
 * it will happily walk a stop list that is unsorted, does not span the cycle,
 * or does not join up at midnight, and every one of those failures looks like
 * "the lighting glitches sometimes" rather than like a broken data file.
 */

const STOPS = lighting.stops;
const PALETTES = lighting.palettes as unknown as Record<string, unknown>;

describe('lighting data', () => {
  it('every stop names a palette that exists', () => {
    for (const stop of STOPS) {
      expect(PALETTES, `stop at ${stop.at}`).toHaveProperty(stop.palette);
    }
  });

  it('stops are sorted', () => {
    for (let i = 1; i < STOPS.length; i++) {
      expect((STOPS[i] as { at: number }).at).toBeGreaterThan(
        (STOPS[i - 1] as { at: number }).at
      );
    }
  });

  it('stops span the whole cycle', () => {
    expect((STOPS[0] as { at: number }).at).toBe(0);
    expect((STOPS[STOPS.length - 1] as { at: number }).at).toBe(1);
  });

  it('joins up at midnight, so the cycle does not jump', () => {
    // The last stop and the first are the same instant. Different palettes
    // there means the sky snaps between two colours as the day rolls over.
    expect((STOPS[STOPS.length - 1] as { palette: string }).palette).toBe(
      (STOPS[0] as { palette: string }).palette
    );
  });

  it('every palette carries a full set of values', () => {
    for (const [name, raw] of Object.entries(lighting.palettes)) {
      const p = raw as Record<string, unknown>;
      for (const key of ['sun', 'ambient', 'ground', 'fog', 'zenith', 'horizon']) {
        expect(p[key], `${name}.${key}`).toHaveLength(3);
      }
      expect(typeof p['sunIntensity'], `${name}.sunIntensity`).toBe('number');
      expect(typeof p['ambientIntensity'], `${name}.ambientIntensity`).toBe('number');
      expect(typeof p['fogDensity'], `${name}.fogDensity`).toBe('number');
    }
  });

  it('gives every palette a sky that is not one flat fill', () => {
    // The survey sampled zenith and horizon on the village frames and got the
    // same three bytes twice: no gradient anywhere in the sky. Part of that was
    // the ramp shape, but a palette whose zenith and horizon nearly match
    // cannot produce a gradient however it is painted.
    for (const [name, raw] of Object.entries(lighting.palettes)) {
      const p = raw as { zenith: number[]; horizon: number[] };
      const delta = Math.max(
        ...[0, 1, 2].map((i) => Math.abs((p.zenith[i] as number) - (p.horizon[i] as number)))
      );
      expect(delta, `${name}: zenith and horizon are too close to read apart`).toBeGreaterThan(0.1);
    }
  });

  it('keeps fog brighter than the ground it hides, so distance recedes', () => {
    // Aerial perspective only works in one direction. When the fog colour is
    // darker than the terrain, distance gets DARKER and the horizon becomes a
    // hard band instead of a soft recession. The survey measured exactly that:
    // near grass at luminance 74 against a far hill at 56.
    for (const [name, raw] of Object.entries(lighting.palettes)) {
      const p = raw as { fog: number[]; ground: number[] };
      const fog = luma({ r: p.fog[0] as number, g: p.fog[1] as number, b: p.fog[2] as number });
      const ground = luma({
        r: p.ground[0] as number,
        g: p.ground[1] as number,
        b: p.ground[2] as number
      });
      expect(fog, `${name}: fog must be lighter than the ground tone`).toBeGreaterThan(ground);
    }
  });

  it('the sky horizon equals the fog colour, per palette', () => {
    // The dome is not fogged (it sits at infinite distance), so the ONLY
    // thing hiding the terrain/sky seam is this equality. A palette whose
    // horizon drifts from its fog paints a visible line across every frame,
    // which is exactly the class of defect the visual judge hunts.
    for (const [name, raw] of Object.entries(lighting.palettes)) {
      const p = raw as { fog: number[]; horizon: number[] };
      expect(p.horizon, `${name}: horizon must equal fog`).toEqual(p.fog);
    }
  });
});

describe('paletteAt', () => {
  it('lands exactly on the palette at each keyframe', () => {
    for (const stop of STOPS) {
      const raw = (lighting.palettes as unknown as Record<string, { sun: number[] }>)[
        stop.palette
      ];
      const p = paletteAt(stop.at);
      expect(p.sun.r, `stop ${stop.at}`).toBeCloseTo(raw?.sun[0] as number, 6);
      expect(p.sun.g, `stop ${stop.at}`).toBeCloseTo(raw?.sun[1] as number, 6);
      expect(p.sun.b, `stop ${stop.at}`).toBeCloseTo(raw?.sun[2] as number, 6);
    }
  });

  it('wraps, so cycle 0 and cycle 1 are the same sky', () => {
    const a = paletteAt(0);
    const b = paletteAt(1);
    expect(b.sun.r).toBeCloseTo(a.sun.r, 6);
    expect(b.fogDensity).toBeCloseTo(a.fogDensity, 6);
  });

  it('handles cycles outside 0..1 the same as their wrapped value', () => {
    for (const t of [-2.75, -0.4, 1.3, 5.65]) {
      const wrapped = ((t % 1) + 1) % 1;
      expect(paletteAt(t).fogDensity).toBeCloseTo(paletteAt(wrapped).fogDensity, 9);
    }
  });

  it('never produces a colour channel outside 0..1', () => {
    for (let i = 0; i <= 400; i++) {
      const p = paletteAt(i / 400);
      for (const c of [p.sun, p.ambient, p.ground, p.fog]) {
        for (const ch of [c.r, c.g, c.b]) {
          expect(ch).toBeGreaterThanOrEqual(0);
          expect(ch).toBeLessThanOrEqual(1);
        }
      }
    }
  });

  it('is continuous: no visible snap between adjacent samples', () => {
    let previous = paletteAt(0);
    for (let i = 1; i <= 2000; i++) {
      const current = paletteAt(i / 2000);
      // A jump bigger than this across 1/2000 of a 20 minute cycle (0.6s)
      // would read as a flicker rather than as dusk falling.
      expect(Math.abs(current.sun.r - previous.sun.r), `at ${i / 2000}`).toBeLessThan(0.05);
      expect(Math.abs(current.fogDensity - previous.fogDensity)).toBeLessThan(0.0005);
      previous = current;
    }
  });

  it('is darkest at night and brightest around noon', () => {
    const night = paletteAt(0.85);
    const noon = paletteAt(0.4);
    expect(night.sunIntensity).toBeLessThan(noon.sunIntensity);
    // The comparison is on the light that lands on the ground, not on the
    // ambient scalar. Night carries its floor with a strong blue hemispheric
    // and a weak moon, so its ambientIntensity is deliberately the higher of
    // the two; what must stay true is that the night frame is darker overall.
    expect(groundLight(0.85).lit).toBeLessThan(groundLight(0.4).lit);
    // Thicker fog at night is what drops visibility, per docs/01_GAME_DESIGN.md 9.
    expect(night.fogDensity).toBeGreaterThan(noon.fogDensity);
  });

  it('makes dawn read cooler than dusk', () => {
    // Both are warm, but a sunrise that looks identical to a sunset means a
    // screenshot cannot tell you which end of the day you are at. This was the
    // case while the ladder ran night -> golden -> noon with no dawn stop.
    const dawn = paletteAt(0.07);
    const dusk = paletteAt(0.71);
    const warmth = (c: { r: number; b: number }): number => c.r - c.b;
    expect(warmth(dawn.fog)).toBeLessThan(warmth(dusk.fog));
  });

  it('falls into night faster than it rises out of it', () => {
    // Losing the light quickly is what makes night feel like it arrived.
    // Measured off the data rather than off two written-down constants, which
    // is what this was and which meant it kept passing after the stops moved.
    const day = STOPS.filter((s) => s.palette === 'day').map((s) => s.at);
    const night = STOPS.filter((s) => s.palette === 'night').map((s) => s.at);
    const firstDay = Math.min(...day);
    const lastDay = Math.max(...day);
    const rise = firstDay - Math.min(...night);
    const fall = Math.min(...night.filter((t) => t > lastDay)) - lastDay;
    expect(rise).toBeGreaterThan(0);
    expect(fall).toBeGreaterThan(0);
    expect(fall).toBeLessThan(rise);
  });
});

describe('isNight', () => {
  it('agrees with the day fraction', () => {
    expect(isNight(0.0)).toBe(false);
    expect(isNight(0.35)).toBe(false);
    expect(isNight(lighting.dayFraction)).toBe(true);
    expect(isNight(0.9)).toBe(true);
  });

  it('wraps like paletteAt does', () => {
    expect(isNight(1.9)).toBe(isNight(0.9));
    expect(isNight(-0.1)).toBe(isNight(0.9));
  });
});
