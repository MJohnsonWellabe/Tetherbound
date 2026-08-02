/**
 * Trauma-based screen shake. Pure: no engine import, no globals, no clock.
 *
 * The model is Squirrel Eiserloh's ("Juicing Your Cameras With Math", GDC 2016).
 * Callers add *trauma*, a 0..1 stress value that decays on its own, and the
 * displacement is derived from `trauma^2` rather than from trauma directly.
 *
 * Why the square matters, since it looks like a detail and is not: with linear
 * trauma every impact reads as the same shake at a different volume, because
 * the ratio between a light hit and a heavy one stays constant as both decay.
 * Squaring makes small trauma almost invisible and large trauma violent, so a
 * bush and a felled oak feel like different events rather than one event twice.
 *
 * Displacement comes from smooth value noise rather than `Math.random()` per
 * frame. Random per frame is white noise, which at 60Hz reads as a buzz or a
 * rendering fault; sampling continuous noise along a time axis gives the
 * camera actual momentum. It is also deterministic, which is what lets
 * tests/fx.test.ts assert on exact offsets rather than on statistics.
 *
 * Three axes are sampled at different offsets into the noise field so x and y
 * never move in lockstep, which would read as a diagonal slide.
 */

export interface ShakeConfig {
  /** Trauma units shed per second. */
  readonly decayPerSecond: number;
  /** Noise samples per second. */
  readonly frequency: number;
  /** Metres of displacement at trauma 1. */
  readonly maxOffset: number;
  readonly maxTrauma: number;
}

export interface ShakeState {
  /** Current stress, 0..maxTrauma. */
  trauma: number;
  /** Seconds elapsed. Advances only through `stepShake`, never wall clock. */
  time: number;
}

export interface ShakeOffset {
  /** Metres along the camera's right vector. */
  x: number;
  /** Metres along the camera's up vector. */
  y: number;
}

export function createShake(): ShakeState {
  return { trauma: 0, time: 0 };
}

/**
 * Add stress. Takes the maximum rather than summing, so a burst of small hits
 * cannot add up to a bigger shake than the biggest single hit in it. Summing
 * is how a rapid-fire action ends up shaking harder than a boss death.
 */
export function addTrauma(state: ShakeState, amount: number, config: ShakeConfig): void {
  if (!(amount > 0)) return;
  state.trauma = Math.min(config.maxTrauma, Math.max(state.trauma, amount));
}

/** Advance by one fixed simulation step. */
export function stepShake(state: ShakeState, dt: number, config: ShakeConfig): void {
  state.time += dt;
  state.trauma = Math.max(0, state.trauma - config.decayPerSecond * dt);
}

/** Current displacement. Zero-allocation into `out` so this is safe per frame. */
export function shakeOffset(
  state: ShakeState,
  config: ShakeConfig,
  out: ShakeOffset
): ShakeOffset {
  const magnitude = state.trauma * state.trauma * config.maxOffset;
  if (magnitude === 0) {
    out.x = 0;
    out.y = 0;
    return out;
  }
  const t = state.time * config.frequency;
  out.x = magnitude * noise1d(t, 0);
  out.y = magnitude * noise1d(t, 137.31);
  return out;
}

/** True while the camera is still displaced, so callers can skip the write. */
export function isShaking(state: ShakeState): boolean {
  return state.trauma > 0;
}

/**
 * Smooth value noise on one axis, in -1..1.
 *
 * Hash-based rather than table-based: no allocation, no setup, and identical
 * results on every platform, which is what makes the tests meaningful. The
 * smoothstep between integer samples is what separates this from white noise.
 */
function noise1d(t: number, seed: number): number {
  const x = t + seed;
  const i = Math.floor(x);
  const f = x - i;
  const a = hash(i + seed);
  const b = hash(i + 1 + seed);
  const u = f * f * (3 - 2 * f);
  return (a + (b - a) * u) * 2 - 1;
}

/** Deterministic 0..1 hash of an integer. */
function hash(n: number): number {
  const s = Math.sin(n * 12.9898) * 43758.5453123;
  return s - Math.floor(s);
}
