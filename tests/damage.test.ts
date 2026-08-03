import { describe, expect, it } from 'vitest';
import {
  ALL_TYPES,
  affinityMultiplier,
  damage,
  statAt,
  typeMultiplier,
  type PalType
} from '../src/combat/Damage';

/** A neutral attacker/defender pair, so each test varies one thing. */
const A = { atk: 40, level: 10, type: 'verdant' as PalType, affinity: 50 };
const D = { def: 40, level: 10, type: 'verdant' as PalType };

describe('the type ring', () => {
  it('covers all 25 pairs with a defined multiplier', () => {
    for (const a of ALL_TYPES) {
      for (const d of ALL_TYPES) {
        const m = typeMultiplier(a, d);
        expect(Number.isFinite(m)).toBe(true);
        expect(m).toBeGreaterThan(0);
      }
    }
  });

  it('gives every type exactly one type it is strong against', () => {
    for (const a of ALL_TYPES) {
      const strong = ALL_TYPES.filter((d) => typeMultiplier(a, d) > 1);
      expect(strong).toHaveLength(1);
    }
  });

  it('gives every type exactly one type it is weak against', () => {
    for (const a of ALL_TYPES) {
      const weak = ALL_TYPES.filter((d) => typeMultiplier(a, d) < 1);
      expect(weak).toHaveLength(1);
    }
  });

  it('is neutral against itself', () => {
    for (const t of ALL_TYPES) expect(typeMultiplier(t, t)).toBe(1);
  });

  it('follows the ring in docs/01_GAME_DESIGN.md section 5', () => {
    expect(typeMultiplier('verdant', 'tide')).toBeGreaterThan(1);
    expect(typeMultiplier('tide', 'ember')).toBeGreaterThan(1);
    expect(typeMultiplier('ember', 'stone')).toBeGreaterThan(1);
    expect(typeMultiplier('stone', 'spark')).toBeGreaterThan(1);
    expect(typeMultiplier('spark', 'verdant')).toBeGreaterThan(1);
  });

  it('makes the reverse of every strong pairing weak', () => {
    for (const a of ALL_TYPES) {
      for (const d of ALL_TYPES) {
        if (typeMultiplier(a, d) > 1) expect(typeMultiplier(d, a)).toBeLessThan(1);
      }
    }
  });
});

describe('the damage formula', () => {
  // rand is injected so the formula stays pure and the tests stay deterministic.
  const mid = (): number => 0.5;

  it('is monotonic in attack', () => {
    let last = -Infinity;
    for (let atk = 10; atk <= 200; atk += 10) {
      const d = damage({ ...A, atk }, D, 20, mid);
      expect(d).toBeGreaterThan(last);
      last = d;
    }
  });

  it('is inverse-monotonic in defence', () => {
    // Non-increasing across the whole sweep rather than strictly decreasing.
    // Damage is floored to a whole number and has a floor of 1, so at high
    // defence consecutive steps legitimately land on the same integer. Asking
    // for strict monotonicity there would be asking the formula to be wrong.
    let last = Infinity;
    for (let def = 10; def <= 400; def += 10) {
      const d = damage(A, { ...D, def }, 20, mid);
      expect(d).toBeLessThanOrEqual(last);
      last = d;
    }
  });

  it('strictly reduces damage when defence doubles', () => {
    // The part that actually matters: more armour is always better while the
    // result is still above the floor.
    for (const def of [10, 20, 40, 80]) {
      const weak = damage(A, { ...D, def }, 40, mid);
      const tough = damage(A, { ...D, def: def * 2 }, 40, mid);
      expect(tough).toBeLessThan(weak);
    }
  });

  it('is monotonic in move power', () => {
    let last = -Infinity;
    for (let power = 8; power <= 70; power += 2) {
      const d = damage(A, D, power, mid);
      expect(d).toBeGreaterThan(last);
      last = d;
    }
  });

  it('hits harder with type advantage than without', () => {
    const neutral = damage({ ...A, type: 'verdant' }, { ...D, type: 'verdant' }, 20, mid);
    const strong = damage({ ...A, type: 'verdant' }, { ...D, type: 'tide' }, 20, mid);
    const weak = damage({ ...A, type: 'verdant' }, { ...D, type: 'spark' }, 20, mid);
    expect(strong).toBeGreaterThan(neutral);
    expect(weak).toBeLessThan(neutral);
  });

  it('never returns less than one, so a hit always registers', () => {
    // A level 1 twig against a level 50 wall must still do something, or the
    // player concludes the button is broken.
    const d = damage(
      { atk: 1, level: 1, type: 'verdant', affinity: 0 },
      { def: 999, level: 50, type: 'spark' },
      8,
      () => 0
    );
    expect(d).toBeGreaterThanOrEqual(1);
  });

  it('always returns a whole number', () => {
    for (let i = 0; i < 200; i++) {
      const d = damage({ ...A, atk: 10 + i }, D, 20, () => i / 200);
      expect(Number.isInteger(d)).toBe(true);
    }
  });

  it('scales with the level difference', () => {
    const lower = damage({ ...A, level: 5 }, { ...D, level: 20 }, 20, mid);
    const higher = damage({ ...A, level: 20 }, { ...D, level: 5 }, 20, mid);
    expect(higher).toBeGreaterThan(lower);
  });

  it('stays inside the random band it was given', () => {
    const low = damage(A, D, 20, () => 0);
    const high = damage(A, D, 20, () => 1);
    const mids = damage(A, D, 20, mid);
    expect(low).toBeLessThanOrEqual(mids);
    expect(mids).toBeLessThanOrEqual(high);
  });
});

describe('affinity', () => {
  it('rewards a bonded pal', () => {
    expect(affinityMultiplier(90)).toBeGreaterThan(1);
  });

  it('is neutral in the middle of the range', () => {
    expect(affinityMultiplier(50)).toBe(1);
  });

  it('does not punish a low-affinity pal with less damage', () => {
    // Section 5 says low affinity makes a pal HESITATE on a power attack. It
    // does not reduce damage, and stacking both would be a hidden double
    // penalty on the pal the player already feels worst about.
    expect(affinityMultiplier(10)).toBe(1);
  });
});

describe('stat scaling', () => {
  it('grows with level', () => {
    let last = -Infinity;
    for (let level = 1; level <= 50; level++) {
      const s = statAt(40, level, 1);
      expect(s).toBeGreaterThanOrEqual(last);
      last = s;
    }
  });

  it('applies the variance roll', () => {
    expect(statAt(40, 10, 1.1)).toBeGreaterThan(statAt(40, 10, 0.9));
  });

  it('returns whole numbers', () => {
    for (let level = 1; level <= 50; level++) {
      expect(Number.isInteger(statAt(37, level, 1.07))).toBe(true);
    }
  });

  it('never returns less than one', () => {
    expect(statAt(1, 1, 0.9)).toBeGreaterThanOrEqual(1);
  });
});
