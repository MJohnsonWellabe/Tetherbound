import { describe, expect, it } from 'vitest';
import { hingeSettled, stepHinge, targetAngle } from '../src/building/Door';
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
