import { describe, expect, it } from 'vitest';
import { selectPad, type PadCandidate } from '../src/core/input/GamepadLayer';
import { NEUTRAL_DODGE } from '../src/core/input/Intent';

/**
 * The ROG Ally bug: `navigator.getGamepads()` enumerates the XInput
 * standard-mapping pad AND ASUS's own vendor HID interface for the same
 * physical device, and picking "whichever connected first" or "whichever is
 * first non-null in the array" picks the vendor interface about half the
 * time. Axes 0/1 land on the left stick on either (that mapping is
 * near-universal on raw HID pads), so the symptom is never "nothing works",
 * it is "only the left stick works". `selectPad` is the fix, pulled out as a
 * pure function so this is checkable without a browser or a real Gamepad.
 */

function pad(index: number, mapping: string, connected = true): PadCandidate {
  return { index, mapping, connected };
}

describe('selectPad', () => {
  it('chooses the standard-mapping pad even when a non-standard one is first', () => {
    const pads = [pad(0, ''), pad(1, 'standard')];
    expect(selectPad(pads)?.index).toBe(1);
  });

  it('chooses the standard-mapping pad when it is first too', () => {
    const pads = [pad(0, 'standard'), pad(1, '')];
    expect(selectPad(pads)?.index).toBe(0);
  });

  it('falls back to a non-standard pad when no standard pad is connected', () => {
    const pads = [pad(0, '')];
    expect(selectPad(pads)?.index).toBe(0);
  });

  it('falls back to the first non-standard pad when several are non-standard', () => {
    const pads = [pad(0, 'vendor'), pad(1, '')];
    expect(selectPad(pads)?.index).toBe(0);
  });

  it('ignores a disconnected pad entirely, standard or not', () => {
    const pads = [pad(0, 'standard', false), pad(1, '')];
    expect(selectPad(pads)?.index).toBe(1);
  });

  it('ignores holes in the array, which is what getGamepads() actually returns', () => {
    const pads = [null, pad(1, 'standard'), undefined];
    expect(selectPad(pads)?.index).toBe(1);
  });

  it('returns null when nothing is connected', () => {
    expect(selectPad([null, undefined])).toBeNull();
    expect(selectPad([])).toBeNull();
  });

  it('prefers standard regardless of array position among several candidates', () => {
    const pads = [pad(0, ''), pad(1, ''), pad(2, 'standard'), pad(3, '')];
    expect(selectPad(pads)?.index).toBe(2);
  });
});

describe('NEUTRAL_DODGE', () => {
  it('is a value CombatMode reads as a committed dodge', () => {
    // CombatMode.update() opens the dodge window on `dodge !== 0`
    // (src/combat/CombatMode.ts). The bug this constant fixes was that both
    // GamepadLayer and DesktopLayer wrote literal 0 for a directionless
    // dodge, which IS the neutral/no-dodge value, so A and Space never
    // dodged at all.
    expect(NEUTRAL_DODGE).not.toBe(0);
  });

  it('is a legal DodgeDir', () => {
    expect([-1, 1]).toContain(NEUTRAL_DODGE);
  });
});
