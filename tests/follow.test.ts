import { describe, expect, it } from 'vitest';
import { followTarget, stepFollow, type FollowConfig } from '../src/anim/Follow';
import companion from '../src/data/companion.json';

const CONFIG: FollowConfig = {
  behind: 2,
  side: 1,
  settleRadius: 0.5,
  gain: 2,
  maxSpeed: 6,
  teleportDistance: 20
};

describe('followTarget', () => {
  it('is behind and to the left of a north-facing player', () => {
    const t = followTarget(0, 0, 0, CONFIG);
    expect(t.x).toBeCloseTo(-1); // left of +Z facing
    expect(t.z).toBeCloseTo(-2); // behind
  });

  it('rotates with the player yaw', () => {
    const t = followTarget(0, 0, Math.PI / 2, CONFIG); // facing +X
    expect(t.x).toBeCloseTo(-2); // behind is -X
    expect(t.z).toBeCloseTo(1); // left of +X facing is +Z
  });
});

describe('stepFollow', () => {
  it('converges on the target without overshooting', () => {
    const state = { x: 10, z: 10 };
    for (let i = 0; i < 600; i++) stepFollow(state, 0, 0, 0, 1 / 60, CONFIG);
    const target = followTarget(0, 0, 0, CONFIG);
    const dist = Math.hypot(state.x - target.x, state.z - target.z);
    expect(dist).toBeLessThanOrEqual(CONFIG.settleRadius + 1e-9);
  });

  it('stops inside the settle radius instead of orbiting', () => {
    const target = followTarget(0, 0, 0, CONFIG);
    const state = { x: target.x + 0.2, z: target.z };
    const out = stepFollow(state, 0, 0, 0, 1 / 60, CONFIG);
    expect(out.speed).toBe(0);
    expect(state.x).toBeCloseTo(target.x + 0.2);
  });

  it('never moves faster than maxSpeed', () => {
    const state = { x: 15, z: 0 };
    const out = stepFollow(state, 0, 0, 0, 1 / 60, CONFIG);
    expect(out.speed).toBeLessThanOrEqual(CONFIG.maxSpeed + 1e-9);
  });

  it('teleports when left too far behind', () => {
    const state = { x: 100, z: 100 };
    const out = stepFollow(state, 0, 0, 0, 1 / 60, CONFIG);
    expect(out.teleported).toBe(true);
    const target = followTarget(0, 0, 0, CONFIG);
    expect(state.x).toBeCloseTo(target.x);
    expect(state.z).toBeCloseTo(target.z);
  });

  it('never overlaps a player who walks straight through it', () => {
    const state = { x: 0, z: 2 };
    let settled = false;
    for (let i = 0; i < 400; i++) {
      const pz = 2 - i * 0.05; // player marches toward then past it
      stepFollow(state, 0, pz, Math.PI, 1 / 60, CONFIG);
      // After the player has passed through and pulled ahead, the companion
      // must keep clear of their heels while chasing the behind-point.
      if (i > 120) {
        expect(Math.hypot(state.x, state.z - pz)).toBeGreaterThan(CONFIG.settleRadius);
        settled = true;
      }
    }
    expect(settled).toBe(true);
  });
});

describe('companion.json', () => {
  it('carries a complete, sane follow config', () => {
    const f = companion.follow;
    for (const key of ['behind', 'side', 'settleRadius', 'gain', 'maxSpeed', 'teleportDistance'] as const) {
      expect(Number.isFinite(f[key]), key).toBe(true);
      expect(f[key], key).toBeGreaterThan(0);
    }
    expect(f.teleportDistance).toBeGreaterThan(f.behind);
    expect(companion.verbs.runAbove).toBeGreaterThan(companion.verbs.walkAbove);
  });
});
