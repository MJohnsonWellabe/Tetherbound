import { describe, expect, it } from 'vitest';
import { applyDeadZone, clampStick, clearEdges, neutralIntent } from '../src/core/input/Intent';

/**
 * BUILD_PROMPT.md's note to the operator says the touch stick dead zone is one
 * of the two things most likely to be wrong, and much cheaper to fix before
 * combat is layered on top. So the maths gets tested rather than eyeballed.
 */

describe('clampStick', () => {
  it('leaves an in-range vector alone', () => {
    expect(clampStick(0.5, 0.5)).toEqual({ x: 0.5, y: 0.5 });
  });

  it('clamps a diagonal to the unit circle so it is not faster than an axis', () => {
    const c = clampStick(1, 1);
    expect(Math.hypot(c.x, c.y)).toBeCloseTo(1, 6);
  });

  it('preserves direction while clamping', () => {
    const c = clampStick(3, 0);
    expect(c).toEqual({ x: 1, y: 0 });
  });
});

describe('applyDeadZone', () => {
  const DZ = 0.18;

  it('reports no movement for a resting thumb', () => {
    expect(applyDeadZone(0.05, 0.05, DZ)).toEqual({ x: 0, y: 0 });
  });

  it('starts from zero speed at the dead zone edge, not a jump to 18%', () => {
    // Just past the boundary must be a slow walk. If this returned the raw
    // magnitude the player would snap straight to a fifth of full speed.
    const out = applyDeadZone(DZ + 0.001, 0, DZ);
    expect(Math.hypot(out.x, out.y)).toBeLessThan(0.01);
  });

  it('reaches full magnitude at full deflection', () => {
    const out = applyDeadZone(1, 0, DZ);
    expect(Math.hypot(out.x, out.y)).toBeCloseTo(1, 6);
  });

  it('never exceeds 1 even past full deflection', () => {
    const out = applyDeadZone(2, 2, DZ);
    expect(Math.hypot(out.x, out.y)).toBeLessThanOrEqual(1 + 1e-9);
  });

  it('preserves direction', () => {
    const out = applyDeadZone(0, -0.8, DZ);
    expect(out.x).toBeCloseTo(0, 6);
    expect(out.y).toBeLessThan(0);
  });

  it('is monotonic in deflection', () => {
    let last = -1;
    for (let d = DZ; d <= 1; d += 0.05) {
      const out = applyDeadZone(d, 0, DZ);
      const mag = Math.hypot(out.x, out.y);
      expect(mag).toBeGreaterThanOrEqual(last);
      last = mag;
    }
  });
});

describe('clearEdges', () => {
  it('clears events but leaves held state alone', () => {
    const intent = neutralIntent();
    intent.jump = true;
    intent.interact = true;
    intent.dodge = -1;
    intent.slot = 3;
    intent.look = { x: 0.4, y: 0.2 };
    intent.sprint = true;
    intent.primary = { down: true, heldMs: 420 };
    intent.move = { x: 1, y: 0 };
    intent.pause = true;

    clearEdges(intent);

    expect(intent.jump).toBe(false);
    expect(intent.interact).toBe(false);
    expect(intent.dodge).toBe(0);
    expect(intent.slot).toBeNull();
    expect(intent.look).toEqual({ x: 0, y: 0 });
    expect(intent.pause).toBe(false);

    // Held state survives. A charge that reset every frame could never reach
    // the 100 charge a power attack needs.
    expect(intent.sprint).toBe(true);
    expect(intent.primary).toEqual({ down: true, heldMs: 420 });
    expect(intent.move).toEqual({ x: 1, y: 0 });
  });
});

describe('pause', () => {
  it('starts neutral', () => {
    expect(neutralIntent().pause).toBe(false);
  });

  it('is a one-frame edge like the other events', () => {
    const intent = neutralIntent();
    intent.pause = true;
    clearEdges(intent);
    expect(intent.pause).toBe(false);
  });
});

describe('layer combination', () => {
  /**
   * Regression for the bug that made the game unplayable on a phone.
   *
   * Both input layers mount whenever the hardware reports touch points. The
   * keyboard poll ran every frame and assigned `intent.move` unconditionally,
   * so with no keyboard attached it assigned zero and erased whatever the touch
   * stick had just written. `look` survived because it accumulates with `+=`
   * and nothing overwrites it, which is why the symptom was exactly "I can look
   * around but I cannot move".
   *
   * The layers now own separate vectors and Input sums them. This models that
   * contract without needing a DOM.
   */
  function combine(
    desktop: { x: number; y: number },
    touch: { x: number; y: number } | null
  ): { x: number; y: number } {
    let x = desktop.x + (touch?.x ?? 0);
    let y = desktop.y + (touch?.y ?? 0);
    const mag = Math.hypot(x, y);
    if (mag > 1) {
      x /= mag;
      y /= mag;
    }
    return { x, y };
  }

  it('does not let an idle keyboard erase the touch stick', () => {
    const out = combine({ x: 0, y: 0 }, { x: 0.7, y: 0.7 });
    expect(Math.hypot(out.x, out.y)).toBeGreaterThan(0.5);
  });

  it('does not let an idle stick erase the keyboard', () => {
    const out = combine({ x: 0, y: 1 }, { x: 0, y: 0 });
    expect(out.y).toBeCloseTo(1, 6);
  });

  it('clamps when both layers are driven at once', () => {
    const out = combine({ x: 0, y: 1 }, { x: 0, y: 1 });
    expect(Math.hypot(out.x, out.y)).toBeCloseTo(1, 6);
  });

  it('reports no movement when neither layer is driven', () => {
    expect(combine({ x: 0, y: 0 }, { x: 0, y: 0 })).toEqual({ x: 0, y: 0 });
  });

  it('works with no touch layer mounted at all', () => {
    expect(combine({ x: 1, y: 0 }, null).x).toBeCloseTo(1, 6);
  });
});
