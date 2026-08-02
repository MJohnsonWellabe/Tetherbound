import { describe, expect, it } from 'vitest';
import { hingeSettled, stepHinge, targetAngle } from '../src/building/Door';
import { DoorRegistry, type DoorHandle } from '../src/building/DoorRegistry';
import pieces from '../src/data/pieces.json';

describe('targetAngle', () => {
  it('is zero when closed', () => {
    expect(targetAngle(false)).toBe(0);
  });

  it('matches the configured open angle in radians', () => {
    expect(targetAngle(true)).toBeCloseTo((pieces.doorOpenAngleDeg * Math.PI) / 180);
  });
});

describe('stepHinge', () => {
  it('reaches fully open in exactly the configured swing time', () => {
    let angle = 0;
    const stepMs = 16;
    let elapsed = 0;
    while (!hingeSettled(angle, true)) {
      angle = stepHinge(angle, true, stepMs);
      elapsed += stepMs;
      expect(elapsed).toBeLessThan(pieces.doorSwingMs + 100);
    }
    expect(angle).toBeCloseTo(targetAngle(true));
  });

  it('closes back down over the same duration', () => {
    let angle = targetAngle(true);
    for (let t = 0; t < pieces.doorSwingMs + 20; t += 16) angle = stepHinge(angle, false, 16);
    expect(angle).toBeCloseTo(0);
  });

  it('never overshoots the target', () => {
    // One giant dt should clamp to the target, not fly past it.
    const angle = stepHinge(0, true, 10_000);
    expect(angle).toBeCloseTo(targetAngle(true));
  });

  it('reverses smoothly from a partial swing without a snap', () => {
    let angle = stepHinge(0, true, pieces.doorSwingMs / 2);
    const midway = angle;
    expect(midway).toBeGreaterThan(0);
    expect(midway).toBeLessThan(targetAngle(true));
    // Reversing should move it back toward zero, not jump.
    const afterOneStep = stepHinge(angle, false, 16);
    expect(afterOneStep).toBeLessThan(midway);
    expect(afterOneStep).toBeGreaterThan(0);
  });
});

describe('hingeSettled', () => {
  it('is false mid-swing and true at the target', () => {
    expect(hingeSettled(0.3, true)).toBe(false);
    expect(hingeSettled(targetAngle(true), true)).toBe(true);
    expect(hingeSettled(0, false)).toBe(true);
  });
});

function fakeDoor(x: number, z: number): DoorHandle {
  let open = false;
  let steps = 0;
  return {
    position: { x, z },
    isOpen: () => open,
    toggle: () => {
      open = !open;
    },
    step: () => {
      steps += 1;
    },
    // Exposed for the step-count assertion below; not part of DoorHandle.
    get _steps() {
      return steps;
    }
  } as DoorHandle & { _steps: number };
}

describe('DoorRegistry', () => {
  it('starts empty', () => {
    expect(new DoorRegistry().size).toBe(0);
  });

  it('finds the nearest door within range, from any source', () => {
    const registry = new DoorRegistry();
    const far = fakeDoor(20, 0);
    const near = fakeDoor(2, 0);
    registry.register(far);
    registry.register(near);
    expect(registry.nearest(0, 0, 30)).toBe(near);
  });

  it('returns null when nothing is within maxDist', () => {
    const registry = new DoorRegistry();
    registry.register(fakeDoor(50, 50));
    expect(registry.nearest(0, 0, 5)).toBeNull();
  });

  it('forgets a door once its unregister function is called', () => {
    const registry = new DoorRegistry();
    const unregister = registry.register(fakeDoor(1, 1));
    expect(registry.size).toBe(1);
    unregister();
    expect(registry.size).toBe(0);
    expect(registry.nearest(0, 0, 10)).toBeNull();
  });

  it('steps every registered door, from BuildMode or Structures alike', () => {
    const registry = new DoorRegistry();
    const a = fakeDoor(0, 0) as DoorHandle & { _steps: number };
    const b = fakeDoor(1, 1) as DoorHandle & { _steps: number };
    registry.register(a);
    registry.register(b);
    registry.stepAll(16);
    expect(a._steps).toBe(1);
    expect(b._steps).toBe(1);
  });

  it('toggle flips the handle state the same way for every door', () => {
    const door = fakeDoor(0, 0);
    expect(door.isOpen()).toBe(false);
    door.toggle();
    expect(door.isOpen()).toBe(true);
  });
});
