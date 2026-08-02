import { Color3, Color4, DirectionalLight, HemisphericLight, Scene, Vector3 } from '../core/babylon';
import lighting from '../data/lighting.json';

/**
 * Day and night. GAME_DESIGN.md section 9: 20 real minutes per full cycle,
 * 14 day and 6 night, night drops visibility hard and campfire light matters.
 *
 * Time is stored as a 0..1 fraction of the cycle so it serialises cleanly into
 * the save and survives a reload at the same hour.
 */

export const CYCLE_SECONDS = lighting.cycleSeconds;
/** Fraction of the cycle that is daylight. The rest is night. */
const DAY_FRACTION = lighting.dayFraction;

/** 0 is dawn, DAY_FRACTION is dusk. */
const DAWN = 0;
const DUSK = DAY_FRACTION;

export interface Palette {
  sun: Color3;
  ambient: Color3;
  ground: Color3;
  fog: Color3;
  sunIntensity: number;
  ambientIntensity: number;
  fogDensity: number;
}

interface RawPalette {
  sun: number[];
  ambient: number[];
  ground: number[];
  fog: number[];
  sunIntensity: number;
  ambientIntensity: number;
  fogDensity: number;
}

const PALETTES = lighting.palettes as unknown as Record<string, RawPalette>;
const STOPS = lighting.stops as { at: number; palette: string }[];

function rawAt(name: string): RawPalette {
  const raw = PALETTES[name];
  if (!raw) throw new Error(`lighting.json names a missing palette "${name}"`);
  return raw;
}

function smoothstep(edge0: number, edge1: number, x: number): number {
  if (edge1 <= edge0) return 0;
  const t = Math.min(1, Math.max(0, (x - edge0) / (edge1 - edge0)));
  return t * t * (3 - 2 * t);
}

function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

function mixColor(a: number[], b: number[], t: number): Color3 {
  return new Color3(
    lerp(a[0] as number, b[0] as number, t),
    lerp(a[1] as number, b[1] as number, t),
    lerp(a[2] as number, b[2] as number, t)
  );
}

/**
 * Blend the keyframes for a point in the cycle. Pure, so it is testable.
 *
 * This was a hand-written if/else ladder over three hardcoded palettes. Making
 * it a generic walk over sorted stops is what lets `lighting.json` add a dawn
 * that is cooler than dusk without touching this file, and it is why adding a
 * fifth palette is a data edit rather than another branch.
 */
export function paletteAt(cycle: number): Palette {
  const t = ((cycle % 1) + 1) % 1;

  let lo = STOPS[0] as { at: number; palette: string };
  let hi = STOPS[STOPS.length - 1] as { at: number; palette: string };
  for (let i = 0; i < STOPS.length - 1; i++) {
    const a = STOPS[i] as { at: number; palette: string };
    const b = STOPS[i + 1] as { at: number; palette: string };
    if (t >= a.at && t <= b.at) {
      lo = a;
      hi = b;
      break;
    }
  }

  const from = rawAt(lo.palette);
  const to = rawAt(hi.palette);
  const k = smoothstep(lo.at, hi.at, t);

  return {
    sun: mixColor(from.sun, to.sun, k),
    ambient: mixColor(from.ambient, to.ambient, k),
    ground: mixColor(from.ground, to.ground, k),
    fog: mixColor(from.fog, to.fog, k),
    sunIntensity: lerp(from.sunIntensity, to.sunIntensity, k),
    ambientIntensity: lerp(from.ambientIntensity, to.ambientIntensity, k),
    fogDensity: lerp(from.fogDensity, to.fogDensity, k)
  };
}

/** True when the cycle position counts as night, for spawn tables. */
export function isNight(cycle: number): boolean {
  const t = ((cycle % 1) + 1) % 1;
  return t < DAWN || t >= DUSK;
}

export class TimeOfDay {
  /** 0..1 through the cycle. 0 is dawn. */
  cycle: number;
  day: number;

  constructor(
    private readonly scene: Scene,
    private readonly sun: DirectionalLight,
    private readonly sky: HemisphericLight,
    startCycle = 0.2,
    startDay = 1
  ) {
    this.cycle = startCycle;
    this.day = startDay;
    this.scene.fogMode = Scene.FOGMODE_EXP2;
    this.apply();
  }

  /** Advance by a fixed simulation step. Returns true when the day rolled. */
  tick(dt: number): boolean {
    this.cycle += dt / CYCLE_SECONDS;
    let rolled = false;
    while (this.cycle >= 1) {
      this.cycle -= 1;
      this.day++;
      rolled = true;
    }
    this.apply();
    return rolled;
  }

  get isNight(): boolean {
    return isNight(this.cycle);
  }

  private apply(): void {
    const p = paletteAt(this.cycle);

    // The sun tracks a low arc: a light directly overhead at noon flattens
    // low-poly terrain into a single shade.
    const angle = (this.cycle / DAY_FRACTION) * Math.PI;
    const elevation = Math.sin(Math.min(Math.max(angle, 0), Math.PI));
    this.sun.direction = new Vector3(
      -Math.cos(angle) * lighting.sun.swing,
      -Math.max(lighting.sun.minElevation, elevation),
      lighting.sun.tilt
    ).normalize();
    this.sun.diffuse = p.sun;
    this.sun.intensity = p.sunIntensity;

    this.sky.diffuse = p.ambient;
    this.sky.groundColor = p.ground;
    this.sky.intensity = p.ambientIntensity;

    this.scene.fogColor = p.fog;
    this.scene.fogDensity = p.fogDensity;
    // Clear colour matches the fog so the horizon has no visible seam where
    // terrain ends and sky begins.
    this.scene.clearColor = new Color4(p.fog.r, p.fog.g, p.fog.b, 1);
  }
}
