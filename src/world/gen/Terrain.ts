import { createNoise2D, type NoiseFunction2D } from 'simplex-noise';
import { mulberry32, hashSeed } from './Rng';

/**
 * The Meadows heightfield. Pure and engine-free: physics, the ground mesh, the
 * camera, prop placement and spawn logic all sample this same function, so the
 * player always stands on the terrain they can see.
 *
 * Units are meters. docs/01_GAME_DESIGN.md talks in meters throughout ("within 4
 * meters of a pal", "a 10m build radius"), so the heightfield does too.
 *
 * Composition, coarse to fine:
 *   continent  broad elevation, sets where the land rises away from the river
 *   hills      the rolling meadow shape you actually walk over
 *   outcrop    ridged noise, masked so rock only appears in a few places
 *   detail     small bumps that keep flat ground from reading as a plane
 *   river      a carve subtracted last, so it cuts through whatever is above it
 *
 * Hollowbrook sits at the origin and needs buildable flat ground, so a radial
 * flatten is applied around it. That is a gameplay requirement expressed in the
 * terrain rather than a special case bolted on later.
 */

export type BiomeKind = 'meadow' | 'grove' | 'rock' | 'riverbank' | 'water';

/** Everything below this is river or pond. */
export const WATER_LEVEL = 0;

/** Radius around Hollowbrook that is flattened for building. */
const VILLAGE_RADIUS = 55;
const VILLAGE_FALLOFF = 90;
const VILLAGE_HEIGHT = 6;

export class Terrain {
  private readonly continent: NoiseFunction2D;
  private readonly hills: NoiseFunction2D;
  private readonly detail: NoiseFunction2D;
  private readonly outcrop: NoiseFunction2D;
  private readonly outcropMask: NoiseFunction2D;
  private readonly riverPath: NoiseFunction2D;
  private readonly riverWarp: NoiseFunction2D;
  private readonly groveMask: NoiseFunction2D;

  constructor(readonly seed: string) {
    // Each noise field gets its own labelled stream. Sharing one generator
    // would mean adding a field shifts every field created after it, and every
    // existing seed would generate a different world.
    const stream = (label: string): NoiseFunction2D =>
      createNoise2D(mulberry32(hashSeed(`${seed}:${label}`)));

    this.continent = stream('continent');
    this.hills = stream('hills');
    this.detail = stream('detail');
    this.outcrop = stream('outcrop');
    this.outcropMask = stream('outcropMask');
    this.riverPath = stream('riverPath');
    this.riverWarp = stream('riverWarp');
    this.groveMask = stream('groveMask');
  }

  /** Fractal Brownian motion. Octaves of a noise field at halving amplitude. */
  private fbm(noise: NoiseFunction2D, x: number, z: number, octaves: number, scale: number): number {
    let sum = 0;
    let amp = 1;
    let freq = 1 / scale;
    let norm = 0;
    for (let i = 0; i < octaves; i++) {
      sum += noise(x * freq, z * freq) * amp;
      norm += amp;
      amp *= 0.5;
      freq *= 2.03; // not exactly 2, or the octaves align into visible grids
    }
    return sum / norm;
  }

  /**
   * Distance from the river's course, as an abstract noise value rather than
   * meters. 0 is the centre line.
   *
   * The trick is treating a low-frequency noise field's zero crossing as the
   * river's course: |noise| near 0 traces a continuous meandering line across
   * the whole world for free, with no path-finding and no stored geometry. A
   * warp field displaces the sample point first so the meander does not read
   * as an obvious noise contour.
   */
  private riverDistance(x: number, z: number): number {
    const wx = x + this.riverWarp(x / 420, z / 420) * 70;
    const wz = z + this.riverWarp(z / 420 + 51.7, x / 420 - 12.3) * 70;
    return Math.abs(this.riverPath(wx / 900, wz / 900));
  }

  /** Smoothstep falloff from a river distance, 1 at the centre line. */
  private riverFalloff(distance: number, band: number): number {
    if (distance > band) return 0;
    const t = 1 - distance / band;
    return t * t * (3 - 2 * t);
  }

  /** How much this point is pulled toward the flat village plateau. 0..1. */
  private villageBlend(x: number, z: number): number {
    const d = Math.hypot(x, z);
    if (d <= VILLAGE_RADIUS) return 1;
    if (d >= VILLAGE_FALLOFF) return 0;
    const t = 1 - (d - VILLAGE_RADIUS) / (VILLAGE_FALLOFF - VILLAGE_RADIUS);
    return t * t * (3 - 2 * t);
  }

  /** Ground height in meters at a world position. The single source of truth. */
  heightAt(x: number, z: number): number {
    const dist = this.riverDistance(x, z);
    // Two tiers, and the reason is measured. A single narrow carve dropped the
    // terrain from whatever height it happened to be (often 30m) to the river
    // bed across ~25m of ground: river banks came out at a median 54 degrees,
    // steeper than the 45 degree limit the character controller allows, so the
    // player could see water they could never reach. The wide valley does most
    // of the descent gently; the narrow bed only cuts the last few meters.
    const valley = this.riverFalloff(dist, 0.34);
    const bed = this.riverFalloff(dist, 0.07);

    const continent = this.fbm(this.continent, x, z, 3, 900) * 24;
    const hills = this.fbm(this.hills, x, z, 4, 190) * 9.5;
    const detail = this.fbm(this.detail, x, z, 3, 42) * 1.4;

    // Ridged noise reads as rock; plain fbm reads as more hills. Outcrops fade
    // out inside the valley, since a cliff rising out of a riverbed is exactly
    // the shape the two-tier carve exists to avoid.
    const mask = Math.max(0, this.outcropMask(x / 640, z / 640) - 0.35) / 0.65;
    const ridge = 1 - Math.abs(this.fbm(this.outcrop, x, z, 3, 85));
    const outcrop = ridge * ridge * mask * 15 * (1 - valley);

    // Hills flatten toward the valley floor rather than being carved through.
    let h = 12 + continent + hills * (1 - valley * 0.85) + detail + outcrop;

    // Wide, gentle descent to just above the waterline.
    if (valley > 0) h = h * (1 - valley) + (WATER_LEVEL + 1.4) * valley;
    // Narrow channel, cut last so it still reads as a river bed.
    if (bed > 0) h = h * (1 - bed) + (WATER_LEVEL - 2.4) * bed;

    const village = this.villageBlend(x, z);
    if (village > 0) h = h * (1 - village) + VILLAGE_HEIGHT * village;

    return h;
  }

  /**
   * Surface normal by central differences.
   *
   * Sampled at 1m rather than something tiny: the character controller uses
   * this for slope limiting, and a 0.01m sample picks up the detail octave and
   * reports a cliff where the player sees a pebble.
   */
  normalAt(x: number, z: number, epsilon = 1): { x: number; y: number; z: number } {
    const hL = this.heightAt(x - epsilon, z);
    const hR = this.heightAt(x + epsilon, z);
    const hD = this.heightAt(x, z - epsilon);
    const hU = this.heightAt(x, z + epsilon);
    const nx = hL - hR;
    const nz = hD - hU;
    const ny = 2 * epsilon;
    const len = Math.hypot(nx, ny, nz) || 1;
    return { x: nx / len, y: ny / len, z: nz / len };
  }

  /** Slope in degrees from vertical. 0 is flat ground. */
  slopeAt(x: number, z: number): number {
    const n = this.normalAt(x, z);
    return Math.acos(Math.min(1, Math.max(-1, n.y))) * (180 / Math.PI);
  }

  /**
   * Which surface this is. Drives scatter tables, spawn tables, and footstep
   * audio, so it is derived from the same fields the height came from rather
   * than being painted separately and drifting out of sync.
   */
  biomeAt(x: number, z: number): BiomeKind {
    const h = this.heightAt(x, z);
    if (h < WATER_LEVEL) return 'water';

    // Riverbank is the strip you can stand on and touch the water from, not
    // the whole valley. docs/01_GAME_DESIGN.md gates Rillnewt to "river banks only",
    // so a loose threshold here would scatter a river species across a sixth
    // of the world. The valley shoulder stays meadow.
    if (this.riverFalloff(this.riverDistance(x, z), 0.34) > 0.82) return 'riverbank';

    if (this.slopeAt(x, z) > 34) return 'rock';

    const mask = this.outcropMask(x / 640, z / 640);
    if (mask > 0.62 && this.slopeAt(x, z) > 20) return 'rock';

    // Groves are sparse by design: the Meadows is grassland with oak stands in
    // it, not a forest. The high threshold is what keeps it that way.
    if (this.groveMask(x / 260, z / 260) > 0.42) return 'grove';

    return 'meadow';
  }

  /** True where the player is standing in water rather than on it. */
  isSubmerged(x: number, z: number): boolean {
    return this.heightAt(x, z) < WATER_LEVEL;
  }
}
