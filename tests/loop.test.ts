import { describe, expect, it } from 'vitest';
import { FIXED_DT, FixedStepAccumulator, MAX_FRAME_MS } from '../src/core/Loop';

/**
 * The accumulator is the reason a phone and a 144Hz desktop run the same
 * simulation. Every tuned constant in the game depends on it, so it gets
 * tested by hand rather than trusted.
 */
describe('FixedStepAccumulator', () => {
  it('runs exactly one step for one frame at 60fps', () => {
    const acc = new FixedStepAccumulator();
    expect(acc.advance(1000 / 60)).toBe(1);
  });

  it('runs no step when a frame is shorter than the fixed step', () => {
    const acc = new FixedStepAccumulator();
    // 144Hz: ~6.94ms, well under the 16.67ms step.
    expect(acc.advance(1000 / 144)).toBe(0);
  });

  it('banks short frames until they add up to a step', () => {
    const acc = new FixedStepAccumulator();
    let steps = 0;
    // Three 144Hz frames is ~20.8ms, which crosses one 16.67ms step.
    for (let i = 0; i < 3; i++) steps += acc.advance(1000 / 144);
    expect(steps).toBe(1);
  });

  it('catches up with multiple steps after a slow frame', () => {
    const acc = new FixedStepAccumulator();
    // A 100ms hitch owes six whole 16.67ms steps.
    expect(acc.advance(100)).toBe(6);
  });

  it('clamps a huge delta instead of spiralling', () => {
    const acc = new FixedStepAccumulator();
    // A tab restored after five minutes. Unclamped this is 18,000 steps in one
    // frame, which locks the page and makes the next delta worse still.
    const steps = acc.advance(5 * 60 * 1000);
    expect(steps).toBe(Math.floor(MAX_FRAME_MS / 1000 / FIXED_DT));
    expect(steps).toBeLessThanOrEqual(15);
  });

  it('ignores a negative delta from a clock adjustment', () => {
    const acc = new FixedStepAccumulator();
    expect(acc.advance(-5000)).toBe(0);
    expect(acc.simulatedMs).toBe(0);
  });

  it('advances simulated time only in whole steps', () => {
    const acc = new FixedStepAccumulator();
    acc.advance(25); // one step, ~8.3ms left banked
    expect(acc.simulatedMs).toBeCloseTo(FIXED_DT * 1000, 6);
  });

  it('reports alpha between 0 and 1', () => {
    const acc = new FixedStepAccumulator();
    acc.advance(25);
    expect(acc.alpha).toBeGreaterThan(0);
    expect(acc.alpha).toBeLessThan(1);
  });

  it('keeps simulated time in step with real time over a long run', () => {
    const acc = new FixedStepAccumulator();
    // 600 frames of jittery 60fps. Simulated time must not drift from wall
    // clock by more than the one step that is legitimately still banked.
    let realMs = 0;
    for (let i = 0; i < 600; i++) {
      const frame = 16.67 + (i % 7) - 3;
      realMs += frame;
      acc.advance(frame);
    }
    expect(realMs - acc.simulatedMs).toBeLessThan(FIXED_DT * 1000);
    expect(realMs - acc.simulatedMs).toBeGreaterThanOrEqual(0);
  });
});
