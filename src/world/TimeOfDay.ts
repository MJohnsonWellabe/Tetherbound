import { Color3, Color4, DirectionalLight, HemisphericLight, Scene, Vector3 } from '../core/babylon';

/**
 * Day and night. GAME_DESIGN.md section 9: 20 real minutes per full cycle,
 * 14 day and 6 night, night drops visibility hard and campfire light matters.
 *
 * Time is stored as a 0..1 fraction of the cycle so it serialises cleanly into
 * the save and survives a reload at the same hour.
 */

export const CYCLE_SECONDS = 20 * 60;
/** Fraction of the cycle that is daylight. The rest is night. */
const DAY_FRACTION = 14 / 20;

/** 0 is dawn, 0.35 is noon, DAY_FRACTION is dusk. */
const DAWN = 0;
const DUSK = DAY_FRACTION;

interface Palette {
  sun: Color3;
  ambient: Color3;
  ground: Color3;
  fog: Color3;
  sunIntensity: number;
  ambientIntensity: number;
  fogDensity: number;
}

const NOON: Palette = {
  sun: new Color3(1, 0.96, 0.86),
  ambient: new Color3(0.72, 0.8, 0.92),
  ground: new Color3(0.28, 0.3, 0.2),
  fog: new Color3(0.64, 0.73, 0.82),
  sunIntensity: 1.75,
  ambientIntensity: 0.55,
  fogDensity: 0.0018
};

const GOLDEN: Palette = {
  sun: new Color3(1, 0.72, 0.44),
  ambient: new Color3(0.6, 0.55, 0.55),
  ground: new Color3(0.26, 0.22, 0.17),
  fog: new Color3(0.78, 0.6, 0.45),
  sunIntensity: 1.25,
  ambientIntensity: 0.42,
  fogDensity: 0.0032
};

const NIGHT: Palette = {
  // Moonlight, not black. A night the player cannot navigate at all is not
  // atmospheric, it is a bug report.
  sun: new Color3(0.42, 0.5, 0.72),
  ambient: new Color3(0.2, 0.26, 0.4),
  ground: new Color3(0.08, 0.1, 0.14),
  fog: new Color3(0.06, 0.08, 0.13),
  sunIntensity: 0.32,
  ambientIntensity: 0.22,
  fogDensity: 0.0072
};

function lerpColor(a: Color3, b: Color3, t: number, out: Color3): Color3 {
  out.r = a.r + (b.r - a.r) * t;
  out.g = a.g + (b.g - a.g) * t;
  out.b = a.b + (b.b - a.b) * t;
  return out;
}

function smoothstep(edge0: number, edge1: number, x: number): number {
  const t = Math.min(1, Math.max(0, (x - edge0) / (edge1 - edge0)));
  return t * t * (3 - 2 * t);
}

/** Blend the three palettes for a point in the cycle. Pure, so it is testable. */
export function paletteAt(cycle: number): Palette {
  const t = ((cycle % 1) + 1) % 1;
  const sun = new Color3();
  const ambient = new Color3();
  const ground = new Color3();
  const fog = new Color3();

  let from: Palette;
  let to: Palette;
  let k: number;

  if (t < 0.12) {
    // Dawn: night giving way to full day.
    from = NIGHT;
    to = GOLDEN;
    k = smoothstep(0, 0.12, t);
  } else if (t < 0.25) {
    from = GOLDEN;
    to = NOON;
    k = smoothstep(0.12, 0.25, t);
  } else if (t < DUSK - 0.13) {
    from = NOON;
    to = NOON;
    k = 0;
  } else if (t < DUSK) {
    from = NOON;
    to = GOLDEN;
    k = smoothstep(DUSK - 0.13, DUSK, t);
  } else if (t < DUSK + 0.06) {
    from = GOLDEN;
    to = NIGHT;
    k = smoothstep(DUSK, DUSK + 0.06, t);
  } else {
    from = NIGHT;
    to = NIGHT;
    k = 0;
  }

  return {
    sun: lerpColor(from.sun, to.sun, k, sun),
    ambient: lerpColor(from.ambient, to.ambient, k, ambient),
    ground: lerpColor(from.ground, to.ground, k, ground),
    fog: lerpColor(from.fog, to.fog, k, fog),
    sunIntensity: from.sunIntensity + (to.sunIntensity - from.sunIntensity) * k,
    ambientIntensity: from.ambientIntensity + (to.ambientIntensity - from.ambientIntensity) * k,
    fogDensity: from.fogDensity + (to.fogDensity - from.fogDensity) * k
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
      -Math.cos(angle) * 0.8,
      -Math.max(0.25, elevation),
      0.36
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
