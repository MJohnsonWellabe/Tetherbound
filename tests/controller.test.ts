import { describe, expect, it } from 'vitest';
import {
  createState,
  DEFAULT_CONFIG,
  intentToWorld,
  step,
  type ControllerWorld
} from '../src/entities/CharacterController';

/**
 * BUILD_PROMPT.md's operator note: "The character controller feel and the touch
 * stick deadzone are the two things most likely to be wrong, and they are much
 * cheaper to fix before combat is layered on top."
 *
 * Feel cannot be unit tested, but the rules underneath it can: gravity settles,
 * slopes block, ledges step, props push back, and a blocked diagonal slides
 * instead of sticking.
 */

const FLAT: ControllerWorld = {
  heightAt: () => 0,
  slopeAt: () => 0,
  collidersNear: () => []
};

const DT = 1 / 60;
const IDLE = { forward: 0, right: 0, sprint: false, jump: false };

function run(
  world: ControllerWorld,
  input: Parameters<typeof step>[1],
  steps: number,
  start = { x: 0, y: 0, z: 0 }
): ReturnType<typeof createState> {
  const state = createState(start);
  for (let i = 0; i < steps; i++) step(state, input, world, DT);
  return state;
}

describe('grounding and gravity', () => {
  it('settles onto the ground and stays there', () => {
    const state = run(FLAT, IDLE, 120, { x: 0, y: 20, z: 0 });
    expect(state.position.y).toBeCloseTo(0, 5);
    expect(state.grounded).toBe(true);
  });

  it('does not accumulate downward velocity while standing', () => {
    // Left unclamped, the next jump fights a large negative velocity and the
    // player barely leaves the ground.
    const state = run(FLAT, IDLE, 300);
    expect(state.velocity.y).toBe(0);
  });

  it('follows the terrain downhill', () => {
    const ramp: ControllerWorld = { ...FLAT, heightAt: (x) => -x * 0.2 };
    const state = run(ramp, { ...IDLE, right: 1 }, 120);
    expect(state.position.x).toBeGreaterThan(3);
    // Tolerance rather than exact equality: descending, the player is briefly
    // airborne over ground that has fallen away beneath them, so y trails the
    // surface by a fraction of a step. Gluing them to it would be worse.
    expect(state.position.y).toBeCloseTo(-state.position.x * 0.2, 1);
  });
});

describe('jumping', () => {
  it('leaves the ground and lands again', () => {
    const state = createState({ x: 0, y: 0, z: 0 });
    step(state, IDLE, FLAT, DT); // settle
    step(state, { ...IDLE, jump: true }, FLAT, DT);
    expect(state.grounded).toBe(false);
    expect(state.position.y).toBeGreaterThan(0);

    for (let i = 0; i < 200; i++) step(state, IDLE, FLAT, DT);
    expect(state.grounded).toBe(true);
    expect(state.position.y).toBeCloseTo(0, 5);
  });

  it('cannot jump in mid-air', () => {
    const state = createState({ x: 0, y: 0, z: 0 });
    step(state, IDLE, FLAT, DT);
    step(state, { ...IDLE, jump: true }, FLAT, DT);
    const apexAttempt = state.velocity.y;
    step(state, { ...IDLE, jump: true }, FLAT, DT);
    // Velocity should only have decreased under gravity, never been reset.
    expect(state.velocity.y).toBeLessThan(apexAttempt);
  });
});

describe('slope limiting', () => {
  it('walks up a gentle slope', () => {
    const gentle: ControllerWorld = { ...FLAT, heightAt: (x) => x * 0.3, slopeAt: () => 20 };
    const state = run(gentle, { ...IDLE, right: 1 }, 120);
    expect(state.position.x).toBeGreaterThan(3);
  });

  it('refuses a slope past the limit', () => {
    const cliff: ControllerWorld = {
      ...FLAT,
      heightAt: (x) => (x > 1 ? 40 : 0),
      slopeAt: (x) => (x > 1 ? 70 : 0)
    };
    const state = run(cliff, { ...IDLE, right: 1 }, 200);
    expect(state.position.x).toBeLessThanOrEqual(1);
  });

  it('uses the configured limit rather than a hardcoded one', () => {
    expect(DEFAULT_CONFIG.maxSlopeDegrees).toBe(45);
    const justUnder: ControllerWorld = { ...FLAT, heightAt: (x) => x * 2, slopeAt: () => 44 };
    const justOver: ControllerWorld = { ...FLAT, heightAt: (x) => x * 2, slopeAt: () => 46 };
    expect(run(justUnder, { ...IDLE, right: 1 }, 120).position.x).toBeGreaterThan(1);
    expect(run(justOver, { ...IDLE, right: 1 }, 120).position.x).toBeLessThan(0.5);
  });
});

describe('step offset', () => {
  it('steps onto a low ledge without jumping', () => {
    // A kerb or a boulder edge. Requiring a jump for these makes a world full
    // of small rocks feel like an obstacle course.
    const ledge: ControllerWorld = {
      ...FLAT,
      heightAt: (x) => (x > 1 ? 0.3 : 0),
      slopeAt: (x) => (x > 1 ? 89 : 0)
    };
    const state = run(ledge, { ...IDLE, right: 1 }, 120);
    expect(state.position.x).toBeGreaterThan(2);
    expect(state.position.y).toBeCloseTo(0.3, 3);
  });

  it('is blocked by a ledge above the step offset', () => {
    const wall: ControllerWorld = {
      ...FLAT,
      heightAt: (x) => (x > 1 ? 0.9 : 0),
      slopeAt: (x) => (x > 1 ? 89 : 0)
    };
    expect(run(wall, { ...IDLE, right: 1 }, 200).position.x).toBeLessThanOrEqual(1);
  });

  it('uses the configured step offset', () => {
    expect(DEFAULT_CONFIG.stepOffset).toBe(0.4);
  });
});

describe('prop collision', () => {
  const tree = { x: 3, z: 0, radius: 0.5 };
  const world: ControllerWorld = { ...FLAT, collidersNear: () => [tree] };

  it('stops the player entering a prop', () => {
    const state = run(world, { ...IDLE, right: 1 }, 200);
    const gap = Math.hypot(state.position.x - tree.x, state.position.z - tree.z);
    expect(gap).toBeGreaterThanOrEqual(tree.radius + DEFAULT_CONFIG.radius - 1e-6);
  });

  it('slides along a prop instead of sticking to it', () => {
    // Pressing diagonally into an obstacle must not zero out both axes.
    // Sticking here is the most noticeable controller flaw there is.
    const state = run(world, { ...IDLE, right: 1, forward: 1 }, 200);
    expect(Math.abs(state.position.z)).toBeGreaterThan(2);
  });

  it('lets the player walk through zero-radius cover', () => {
    // Grass and flowers register no collider at all.
    const grass: ControllerWorld = { ...FLAT, collidersNear: () => [] };
    expect(run(grass, { ...IDLE, right: 1 }, 120).position.x).toBeGreaterThan(3);
  });
});

describe('speed', () => {
  it('sprints faster than it walks', () => {
    const walked = run(FLAT, { ...IDLE, forward: 1 }, 180).position.z;
    const sprinted = run(FLAT, { ...IDLE, forward: 1, sprint: true }, 180).position.z;
    expect(sprinted).toBeGreaterThan(walked * 1.3);
  });

  it('does not exceed the configured speed', () => {
    const state = run(FLAT, { ...IDLE, forward: 1, sprint: true }, 600);
    const speed = Math.hypot(state.velocity.x, state.velocity.z);
    expect(speed).toBeLessThanOrEqual(DEFAULT_CONFIG.sprintSpeed + 1e-6);
  });

  it('moves diagonally no faster than straight, given a clamped stick', () => {
    const straight = run(FLAT, { ...IDLE, forward: 1 }, 180);
    const diag = run(FLAT, { ...IDLE, forward: Math.SQRT1_2, right: Math.SQRT1_2 }, 180);
    const straightDist = Math.hypot(straight.position.x, straight.position.z);
    const diagDist = Math.hypot(diag.position.x, diag.position.z);
    expect(diagDist).toBeCloseTo(straightDist, 3);
  });
});

describe('intentToWorld', () => {
  it('sends forward input away from a camera looking down +Z', () => {
    const { forward, right } = intentToWorld(0, 1, 0);
    expect(forward).toBeCloseTo(1, 6);
    expect(right).toBeCloseTo(0, 6);
  });

  it('rotates with the camera', () => {
    const { forward, right } = intentToWorld(0, 1, Math.PI / 2);
    expect(forward).toBeCloseTo(0, 6);
    expect(right).toBeCloseTo(1, 6);
  });

  it('preserves magnitude at any yaw', () => {
    for (let yaw = 0; yaw < Math.PI * 2; yaw += 0.3) {
      const { forward, right } = intentToWorld(0.6, 0.8, yaw);
      expect(Math.hypot(forward, right)).toBeCloseTo(1, 6);
    }
  });
});
