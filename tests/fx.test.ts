import { describe, expect, it } from 'vitest';
import fx from '../src/data/fx.json';
import harvest from '../src/data/harvest.json';
import {
  addTrauma,
  createShake,
  isShaking,
  shakeOffset,
  stepShake,
  type ShakeConfig,
  type ShakeOffset
} from '../src/fx/shake';
import {
  clearPause,
  consumePause,
  createHitPause,
  isPaused,
  requestPause,
  type HitPauseConfig
} from '../src/fx/hitPause';

const SHAKE: ShakeConfig = fx.shake;
const PAUSE: HitPauseConfig = fx.hitPause;
const STEP = 1 / 60;

function offsetOf(state: ReturnType<typeof createShake>): ShakeOffset {
  return shakeOffset(state, SHAKE, { x: 0, y: 0 });
}

describe('screen shake', () => {
  it('starts at rest', () => {
    const s = createShake();
    expect(isShaking(s)).toBe(false);
    expect(offsetOf(s)).toEqual({ x: 0, y: 0 });
  });

  it('decays to exactly zero and stays there', () => {
    const s = createShake();
    addTrauma(s, 1, SHAKE);
    // 1 / 1.6 is 0.625s; two seconds is comfortably past it.
    for (let i = 0; i < 120; i++) stepShake(s, STEP, SHAKE);
    expect(s.trauma).toBe(0);
    expect(isShaking(s)).toBe(false);
    expect(offsetOf(s)).toEqual({ x: 0, y: 0 });
  });

  it('never exceeds maxTrauma however much is added', () => {
    const s = createShake();
    for (let i = 0; i < 50; i++) addTrauma(s, 5, SHAKE);
    expect(s.trauma).toBe(SHAKE.maxTrauma);
  });

  it('takes the maximum rather than summing, so small hits cannot stack', () => {
    const s = createShake();
    addTrauma(s, 0.2, SHAKE);
    addTrauma(s, 0.2, SHAKE);
    addTrauma(s, 0.2, SHAKE);
    expect(s.trauma).toBeCloseTo(0.2, 10);
  });

  it('lets a bigger hit override a smaller one already in flight', () => {
    const s = createShake();
    addTrauma(s, 0.2, SHAKE);
    addTrauma(s, 0.7, SHAKE);
    expect(s.trauma).toBeCloseTo(0.7, 10);
  });

  it('ignores zero and negative trauma', () => {
    const s = createShake();
    addTrauma(s, 0, SHAKE);
    addTrauma(s, -3, SHAKE);
    expect(s.trauma).toBe(0);
  });

  it('keeps displacement inside maxOffset on both axes', () => {
    const s = createShake();
    addTrauma(s, 1, SHAKE);
    for (let i = 0; i < 200; i++) {
      const o = offsetOf(s);
      expect(Math.abs(o.x)).toBeLessThanOrEqual(SHAKE.maxOffset);
      expect(Math.abs(o.y)).toBeLessThanOrEqual(SHAKE.maxOffset);
      stepShake(s, STEP, SHAKE);
      addTrauma(s, 1, SHAKE);
    }
  });

  it('scales with trauma squared, so half the trauma is a quarter of the shake', () => {
    const full = createShake();
    const half = createShake();
    addTrauma(full, 1, SHAKE);
    addTrauma(half, 0.5, SHAKE);
    // Same time axis, so the noise term is identical and the ratio is pure gain.
    const a = offsetOf(full);
    const b = offsetOf(half);
    expect(Math.abs(b.x)).toBeCloseTo(Math.abs(a.x) * 0.25, 10);
    expect(Math.abs(b.y)).toBeCloseTo(Math.abs(a.y) * 0.25, 10);
  });

  it('moves the two axes independently rather than in lockstep', () => {
    const s = createShake();
    addTrauma(s, 1, SHAKE);
    let identical = 0;
    for (let i = 0; i < 60; i++) {
      const o = offsetOf(s);
      if (Math.abs(o.x - o.y) < 1e-9) identical++;
      stepShake(s, STEP, SHAKE);
      addTrauma(s, 1, SHAKE);
    }
    expect(identical).toBe(0);
  });

  it('is continuous, not white noise: consecutive samples stay close', () => {
    const s = createShake();
    addTrauma(s, 1, SHAKE);
    let previous = offsetOf(s).x;
    for (let i = 0; i < 60; i++) {
      stepShake(s, STEP, SHAKE);
      addTrauma(s, 1, SHAKE);
      const current = offsetOf(s).x;
      // One step advances the noise axis by frequency/60 of a sample, so a
      // jump anywhere near the full range would mean the smoothing is gone.
      expect(Math.abs(current - previous)).toBeLessThan(SHAKE.maxOffset);
      previous = current;
    }
  });

  it('is deterministic: the same inputs give the same offsets', () => {
    const run = (): number[] => {
      const s = createShake();
      addTrauma(s, 1, SHAKE);
      const out: number[] = [];
      for (let i = 0; i < 30; i++) {
        out.push(offsetOf(s).x, offsetOf(s).y);
        stepShake(s, STEP, SHAKE);
      }
      return out;
    };
    expect(run()).toEqual(run());
  });

  it('writes into the caller-owned object rather than allocating', () => {
    const s = createShake();
    addTrauma(s, 1, SHAKE);
    const out: ShakeOffset = { x: 0, y: 0 };
    expect(shakeOffset(s, SHAKE, out)).toBe(out);
  });
});

describe('hit pause', () => {
  it('starts unpaused', () => {
    const p = createHitPause();
    expect(isPaused(p)).toBe(false);
    expect(consumePause(p, STEP)).toBe(false);
  });

  it('clamps a single request to the configured ceiling', () => {
    const p = createHitPause();
    requestPause(p, 10_000, PAUSE);
    expect(p.remainingMs).toBe(PAUSE.maxMs);
  });

  it('cannot be extended past the ceiling by repeated requests', () => {
    const p = createHitPause();
    for (let i = 0; i < 100; i++) requestPause(p, PAUSE.maxMs, PAUSE);
    expect(p.remainingMs).toBe(PAUSE.maxMs);
  });

  it('takes the maximum rather than summing', () => {
    const p = createHitPause();
    requestPause(p, 40, PAUSE);
    requestPause(p, 40, PAUSE);
    requestPause(p, 40, PAUSE);
    expect(p.remainingMs).toBe(40);
  });

  it('ignores zero and negative requests', () => {
    const p = createHitPause();
    requestPause(p, 0, PAUSE);
    requestPause(p, -50, PAUSE);
    expect(isPaused(p)).toBe(false);
  });

  it('withholds a bounded number of steps and then always resumes', () => {
    const p = createHitPause();
    requestPause(p, PAUSE.maxMs, PAUSE);
    let withheld = 0;
    // Far more steps than the ceiling could ever justify.
    for (let i = 0; i < 600; i++) {
      if (consumePause(p, STEP)) withheld++;
    }
    expect(withheld).toBe(Math.ceil(PAUSE.maxMs / (STEP * 1000)));
    expect(isPaused(p)).toBe(false);
    expect(consumePause(p, STEP)).toBe(false);
  });

  it('never withholds more simulation time than was requested, plus one step', () => {
    for (const ms of [1, 16, 45, 70, 85, 120, 140]) {
      const p = createHitPause();
      requestPause(p, ms, PAUSE);
      let withheldMs = 0;
      while (consumePause(p, STEP)) withheldMs += STEP * 1000;
      expect(withheldMs).toBeGreaterThanOrEqual(Math.min(ms, PAUSE.maxMs) - 1e-9);
      expect(withheldMs).toBeLessThan(Math.min(ms, PAUSE.maxMs) + STEP * 1000);
    }
  });

  it('never leaves a negative remainder to leak into the next pause', () => {
    const p = createHitPause();
    requestPause(p, 20, PAUSE);
    while (consumePause(p, STEP));
    expect(p.remainingMs).toBe(0);
  });

  it('clears on demand', () => {
    const p = createHitPause();
    requestPause(p, PAUSE.maxMs, PAUSE);
    clearPause(p);
    expect(isPaused(p)).toBe(false);
  });
});

describe('fx data', () => {
  it('every impact names a particle preset that exists', () => {
    const presets = new Set(Object.keys(fx.particles.presets));
    for (const [name, impact] of Object.entries(fx.impacts)) {
      expect(presets, `impact "${name}" names a missing preset`).toContain(impact.particles);
    }
  });

  it('no impact asks for a pause the ceiling would silently truncate', () => {
    for (const [name, impact] of Object.entries(fx.impacts)) {
      expect(impact.pauseMs, `impact "${name}" exceeds hitPause.maxMs`).toBeLessThanOrEqual(
        fx.hitPause.maxMs
      );
    }
  });

  it('no impact asks for more trauma than the shake can hold', () => {
    for (const [name, impact] of Object.entries(fx.impacts)) {
      expect(impact.trauma, `impact "${name}" exceeds shake.maxTrauma`).toBeLessThanOrEqual(
        fx.shake.maxTrauma
      );
      expect(impact.trauma).toBeGreaterThan(0);
    }
  });

  it('every harvestable family has a feel, so a new node is never silent', () => {
    for (const family of Object.keys(harvest.nodes)) {
      expect(
        fx.harvest,
        `family "${family}" is harvestable but has no fx.harvest entry, so chopping it would shake nothing`
      ).toHaveProperty(family);
    }
  });

  it('every harvest feel names impacts that exist', () => {
    const impacts = new Set(Object.keys(fx.impacts));
    for (const [family, entry] of Object.entries(fx.harvest)) {
      expect(impacts, `${family}.swing`).toContain(entry.swing);
      expect(impacts, `${family}.fell`).toContain(entry.fell);
    }
  });

  it('felling always hits harder than swinging', () => {
    const impacts = fx.impacts as Record<string, { trauma: number }>;
    for (const [family, entry] of Object.entries(fx.harvest)) {
      const swing = impacts[entry.swing] as { trauma: number };
      const fell = impacts[entry.fell] as { trauma: number };
      expect(fell.trauma, `${family}: felling should out-shake a swing`).toBeGreaterThan(
        swing.trauma
      );
    }
  });

  it('the preset map holds only presets, never comment keys', () => {
    // Particles.ts builds one pooled ParticleSystem per entry in this map, so a
    // "$comment_" key inside it becomes a system built from a string. This has
    // been written by mistake twice; the map is iterated, the sibling objects
    // in this file are not, and the difference is invisible while editing.
    for (const key of Object.keys(fx.particles.presets)) {
      expect(key.startsWith('$'), `"${key}" belongs beside \`presets\`, not inside it`).toBe(false);
    }
  });

  it('every preset has a sane lifetime, size and speed range', () => {
    for (const [name, p] of Object.entries(fx.particles.presets)) {
      expect(p.count, name).toBeGreaterThan(0);
      expect(p.lifeMs[0], name).toBeLessThanOrEqual(p.lifeMs[1] as number);
      expect(p.size[0], name).toBeLessThanOrEqual(p.size[1] as number);
      expect(p.speed[0], name).toBeLessThanOrEqual(p.speed[1] as number);
    }
  });
});
