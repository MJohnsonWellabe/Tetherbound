import { describe, expect, it } from 'vitest';
import { resolveBoomDistance, smoothBoomDistance, type BoomConfig } from '../src/entities/CameraBoom';
import cameraRig from '../src/data/cameraRig.json';

const CONFIG: BoomConfig = {
  steps: 6,
  floor: 1.4,
  groundClearance: 0.5,
  colliderMargin: 0.3
};

const FLAT_GROUND = () => -100; // far below the boom, never blocks
const FOCUS = { x: 0, y: 2, z: 0 };
const BACK_DIR = { x: 0, y: 0, z: -1 }; // camera sits behind the player, -Z
const MAX_DISTANCE = 5.2;

describe('resolveBoomDistance', () => {
  it('returns the full boom distance with no colliders and flat ground', () => {
    const d = resolveBoomDistance(FOCUS, BACK_DIR, MAX_DISTANCE, FLAT_GROUND, [], CONFIG);
    expect(d).toBeCloseTo(MAX_DISTANCE);
  });

  it('shortens when a collider sits squarely on the boom path', () => {
    // House wall centred a couple metres behind the focus, on the boom line.
    const colliders = [{ x: 0, z: -3, radius: 1 }];
    const d = resolveBoomDistance(FOCUS, BACK_DIR, MAX_DISTANCE, FLAT_GROUND, colliders, CONFIG);
    expect(d).toBeLessThan(MAX_DISTANCE);
    expect(d).toBeGreaterThanOrEqual(CONFIG.floor);
  });

  it('does not shorten for a collider far off the boom path', () => {
    // Well off to the side in X, never within radius + margin of any sample.
    const colliders = [{ x: 20, z: -3, radius: 1 }];
    const d = resolveBoomDistance(FOCUS, BACK_DIR, MAX_DISTANCE, FLAT_GROUND, colliders, CONFIG);
    expect(d).toBeCloseTo(MAX_DISTANCE);
  });

  it('still pulls in for rising terrain (existing ground behaviour)', () => {
    // Ground rises to meet the focus height well before the max distance.
    const risingGround = (_x: number, z: number) => 2 + Math.abs(z) * 0.5;
    const d = resolveBoomDistance(FOCUS, BACK_DIR, MAX_DISTANCE, risingGround, [], CONFIG);
    expect(d).toBeLessThan(MAX_DISTANCE);
  });

  it('never resolves below the floor', () => {
    // Collider wraps the focus point itself; every sample is inside it.
    const colliders = [{ x: 0, z: 0, radius: 10 }];
    const d = resolveBoomDistance(FOCUS, BACK_DIR, MAX_DISTANCE, FLAT_GROUND, colliders, CONFIG);
    expect(d).toBe(CONFIG.floor);
  });

  it('accounts for the collider margin, not just the raw radius', () => {
    // Single sample at the full boom distance (z = -5.2). Placing the
    // collider 1.15m from it is outside the bare radius (1) but inside
    // radius + the configured 0.3m margin (1.3).
    const oneSample: BoomConfig = { ...CONFIG, steps: 1 };
    const colliders = [{ x: 0, z: -5.2 + 1.15, radius: 1 }];

    const d = resolveBoomDistance(FOCUS, BACK_DIR, MAX_DISTANCE, FLAT_GROUND, colliders, oneSample);
    expect(d).toBeLessThan(MAX_DISTANCE);

    const noMargin = resolveBoomDistance(FOCUS, BACK_DIR, MAX_DISTANCE, FLAT_GROUND, colliders, {
      ...oneSample,
      colliderMargin: 0
    });
    expect(noMargin).toBeCloseTo(MAX_DISTANCE);
  });
});

describe('smoothBoomDistance', () => {
  it('reaches the target faster pulling in than easing back out', () => {
    const dt = 1 / 60;
    const lerpInRate = 40;
    const lerpOutRate = 6;

    // Pulling in: current 5.2 -> target 2.0.
    let inDist = 5.2;
    for (let i = 0; i < 5; i++) inDist = smoothBoomDistance(inDist, 2.0, dt, lerpInRate, lerpOutRate);
    const inProgress = (5.2 - inDist) / (5.2 - 2.0);

    // Easing out: current 2.0 -> target 5.2, same number of frames.
    let outDist = 2.0;
    for (let i = 0; i < 5; i++) outDist = smoothBoomDistance(outDist, 5.2, dt, lerpInRate, lerpOutRate);
    const outProgress = (outDist - 2.0) / (5.2 - 2.0);

    expect(inProgress).toBeGreaterThan(outProgress);
  });

  it('converges on the target over enough frames either direction', () => {
    const dt = 1 / 60;
    let d = 5.2;
    for (let i = 0; i < 240; i++) d = smoothBoomDistance(d, 2.0, dt, 40, 6);
    expect(d).toBeCloseTo(2.0, 3);

    for (let i = 0; i < 240; i++) d = smoothBoomDistance(d, 5.2, dt, 40, 6);
    expect(d).toBeCloseTo(5.2, 3);
  });

  it('does not move when already at the target', () => {
    expect(smoothBoomDistance(3.0, 3.0, 1 / 60, 40, 6)).toBeCloseTo(3.0);
  });
});

describe('cameraRig.json', () => {
  it('carries sane boom tuning', () => {
    const b = cameraRig.boom;
    expect(Number.isInteger(b.steps)).toBe(true);
    expect(b.steps).toBeGreaterThan(0);
    expect(b.floor).toBeGreaterThan(0);
    expect(b.groundClearance).toBeGreaterThan(0);
    expect(b.colliderMargin).toBeGreaterThan(0);
    expect(b.lerpInRate).toBeGreaterThan(b.lerpOutRate);
  });
});
