import { describe, expect, it } from 'vitest';
import combat from '../src/data/combat.json';
import {
  ALL_TYPES,
  computeDamage,
  statAt,
  typeMultiplier,
  type DamageInput,
  type PalType
} from '../src/combat/Damage';

/**
 * ARCHITECTURE.md requires the type matrix to be correct for all 25 pairs and
 * the damage formula to be monotonic in ATK and inverse-monotonic in DEF.
 *
 * `computeDamage` takes its random roll as an argument rather than calling a
 * generator, which is what makes every assertion here exact instead of
 * statistical.
 */

const base: DamageInput = {
  atk: 40,
  def: 30,
  movePower: 20,
  attackerType: 'verdant',
  defenderType: 'verdant',
  affinity: combat.affinity.start,
  levelDiff: 0,
  collared: false
};

describe('the type ring', () => {
  it('covers all 25 pairs with exactly one of three multipliers', () => {
    for (const a of ALL_TYPES) {
      for (const d of ALL_TYPES) {
        const m = typeMultiplier(a, d);
        expect([combat.typeRing.strong, combat.typeRing.weak, combat.typeRing.neutral]).toContain(m);
      }
    }
  });

  it('gives every type exactly one it beats and exactly one it loses to', () => {
    for (const a of ALL_TYPES) {
      const beats = ALL_TYPES.filter((d) => typeMultiplier(a, d) === combat.typeRing.strong);
      const losesTo = ALL_TYPES.filter((d) => typeMultiplier(a, d) === combat.typeRing.weak);
      expect(beats).toHaveLength(1);
      expect(losesTo).toHaveLength(1);
    }
  });

  it('follows the ring in GAME_DESIGN.md: verdant to tide to ember to stone to spark to verdant', () => {
    const ring: PalType[] = ['verdant', 'tide', 'ember', 'stone', 'spark'];
    for (let i = 0; i < ring.length; i++) {
      const attacker = ring[i] as PalType;
      const prey = ring[(i + 1) % ring.length] as PalType;
      expect(typeMultiplier(attacker, prey)).toBe(combat.typeRing.strong);
      // and the reverse direction is the weak one
      expect(typeMultiplier(prey, attacker)).toBe(combat.typeRing.weak);
    }
  });

  it('is neutral against itself', () => {
    for (const t of ALL_TYPES) {
      expect(typeMultiplier(t, t)).toBe(combat.typeRing.neutral);
    }
  });
});

describe('the damage formula', () => {
  it('rises with attack', () => {
    let previous = 0;
    for (let atk = 10; atk <= 200; atk += 10) {
      const d = computeDamage({ ...base, atk }, 1);
      expect(d).toBeGreaterThan(previous);
      previous = d;
    }
  });

  it('falls as defence rises', () => {
    let previous = Infinity;
    for (let def = 10; def <= 200; def += 10) {
      const d = computeDamage({ ...base, def }, 1);
      expect(d).toBeLessThan(previous);
      previous = d;
    }
  });

  it('scales with the type ring', () => {
    const neutral = computeDamage({ ...base, defenderType: 'verdant' }, 1);
    const strong = computeDamage({ ...base, defenderType: 'tide' }, 1);
    const weak = computeDamage({ ...base, defenderType: 'spark' }, 1);
    expect(strong).toBeGreaterThan(neutral);
    expect(weak).toBeLessThan(neutral);
    expect(strong / neutral).toBeCloseTo(combat.typeRing.strong, 5);
    expect(weak / neutral).toBeCloseTo(combat.typeRing.weak, 5);
  });

  it('pays the high-affinity bonus only above the threshold', () => {
    const below = computeDamage({ ...base, affinity: combat.affinity.highThreshold - 1 }, 1);
    const at = computeDamage({ ...base, affinity: combat.affinity.highThreshold }, 1);
    expect(at / below).toBeCloseTo(1 + combat.affinity.highDamageBonus, 5);
  });

  it('gives collared enemies their flat multiplier', () => {
    const plain = computeDamage({ ...base, collared: false }, 1);
    const collared = computeDamage({ ...base, collared: true }, 1);
    expect(collared / plain).toBeCloseTo(combat.damage.collaredAttackMultiplier, 5);
  });

  it('never returns less than the configured minimum, however lopsided', () => {
    const d = computeDamage(
      {
        ...base,
        atk: 1,
        def: 999,
        movePower: 1,
        attackerType: 'verdant',
        defenderType: 'spark',
        levelDiff: -combat.damage.levelDiffClamp
      },
      combat.damage.rollMin
    );
    expect(d).toBeGreaterThanOrEqual(combat.damage.minimum);
  });

  it('clamps the level difference so a 40 level gap is not a 180% bonus', () => {
    const capped = computeDamage({ ...base, levelDiff: combat.damage.levelDiffClamp }, 1);
    const beyond = computeDamage({ ...base, levelDiff: combat.damage.levelDiffClamp + 25 }, 1);
    expect(beyond).toBe(capped);
  });

  it('varies with the roll across exactly the configured band', () => {
    const low = computeDamage(base, combat.damage.rollMin);
    const high = computeDamage(base, combat.damage.rollMax);
    expect(high / low).toBeCloseTo(combat.damage.rollMax / combat.damage.rollMin, 5);
  });
});

describe('stat scaling', () => {
  it('matches the published curve: floor(base * (1 + level * gain) * variance)', () => {
    expect(statAt(50, 10, 1)).toBe(Math.floor(50 * (1 + 10 * combat.stats.levelGain)));
  });

  it('rises with level for every base value', () => {
    for (const b of [20, 45, 90]) {
      let previous = 0;
      for (let level = 1; level <= combat.xp.maxLevel; level++) {
        const s = statAt(b, level, 1);
        expect(s).toBeGreaterThanOrEqual(previous);
        previous = s;
      }
      // and it has actually grown, not just failed to shrink
      expect(statAt(b, combat.xp.maxLevel, 1)).toBeGreaterThan(statAt(b, 1, 1));
    }
  });

  it('applies the variance band', () => {
    expect(statAt(100, 1, combat.stats.varianceMax)).toBeGreaterThan(
      statAt(100, 1, combat.stats.varianceMin)
    );
  });
});
