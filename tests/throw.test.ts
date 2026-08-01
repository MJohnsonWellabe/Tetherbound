import { describe, expect, it } from 'vitest';
import combat from '../src/data/combat.json';
import { catchChance, ringQuality, ringRadiusAt, type CatchInput } from '../src/combat/Throw';

/**
 * ARCHITECTURE.md requires catch chance to stay inside 0.01 and 0.95 across the
 * full input range. That clamp is the promise that no throw is ever certain and
 * none is ever hopeless, so it is tested by sweeping rather than by spot check.
 */

const base: CatchInput = {
  speciesCatchRate: 0.3,
  currentHp: 50,
  maxHp: 50,
  palLevel: 5,
  highestPartyLevel: 5,
  ringBonus: combat.throw.ringBonus.none,
  ballMod: 1,
  staggered: false
};

describe('catch chance', () => {
  it('stays inside the clamp across the whole input space', () => {
    for (const rate of [0.01, 0.05, 0.3, 0.6, 1]) {
      for (const hp of [0, 1, 25, 50]) {
        for (const palLevel of [1, 5, 18, 50]) {
          for (const partyLevel of [1, 5, 18, 50]) {
            for (const ball of [1, 1.6, 2.4]) {
              for (const staggered of [false, true]) {
                for (const ring of Object.values(combat.throw.ringBonus)) {
                  const c = catchChance({
                    speciesCatchRate: rate,
                    currentHp: hp,
                    maxHp: 50,
                    palLevel,
                    highestPartyLevel: partyLevel,
                    ringBonus: ring,
                    ballMod: ball,
                    staggered
                  });
                  expect(c).toBeGreaterThanOrEqual(combat.throw.chanceMin);
                  expect(c).toBeLessThanOrEqual(combat.throw.chanceMax);
                  expect(Number.isFinite(c)).toBe(true);
                }
              }
            }
          }
        }
      }
    }
  });

  it('rises as the target is worn down', () => {
    const healthy = catchChance(base);
    const hurt = catchChance({ ...base, currentHp: 5 });
    expect(hurt).toBeGreaterThan(healthy);
  });

  it('falls as the target out-levels your party', () => {
    const even = catchChance(base);
    const above = catchChance({ ...base, palLevel: 20 });
    expect(above).toBeLessThan(even);
  });

  it('does not punish you for catching something below your level', () => {
    // levelTerm caps at 1.0, so a low-level target is not made artificially easy
    const even = catchChance(base);
    const below = catchChance({ ...base, palLevel: 1 });
    expect(below).toBeCloseTo(even, 10);
  });

  it('rewards a better orb', () => {
    const worn = catchChance({ ...base, ballMod: 1 });
    const keen = catchChance({ ...base, ballMod: 1.6 });
    const truestone = catchChance({ ...base, ballMod: 2.4 });
    expect(keen).toBeGreaterThan(worn);
    expect(truestone).toBeGreaterThan(keen);
  });

  it('rewards ring timing and stagger', () => {
    expect(catchChance({ ...base, ringBonus: combat.throw.ringBonus.good })).toBeGreaterThan(
      catchChance(base)
    );
    expect(catchChance({ ...base, ringBonus: combat.throw.ringBonus.great })).toBeGreaterThan(
      catchChance({ ...base, ringBonus: combat.throw.ringBonus.good })
    );
    expect(catchChance({ ...base, staggered: true })).toBeGreaterThan(catchChance(base));
  });

  it('makes even the easiest catch a bad bet at full health', () => {
    // hpTerm is 0.25 at full health for every species, which is the pressure
    // that makes softening the target first the correct play. A Tuftmoth is
    // "very high catch rate" relative to the roster, not a free catch.
    const tuftmoth = catchChance({ ...base, speciesCatchRate: 0.6, palLevel: 3 });
    expect(tuftmoth).toBeLessThan(0.25);
  });

  it('turns the tutorial catch into a near-certainty once it is worn down', () => {
    // The other half of that promise: a player who fights a Tuftmoth down and
    // times the ring should not then lose it to a dice roll.
    const tuftmoth = catchChance({
      ...base,
      speciesCatchRate: 0.6,
      palLevel: 3,
      currentHp: 4,
      ringBonus: combat.throw.ringBonus.great
    });
    expect(tuftmoth).toBeGreaterThan(0.8);
  });

  it('keeps a field boss hard even at one hit point with the best orb', () => {
    const loamking = catchChance({
      speciesCatchRate: 0.05,
      currentHp: 1,
      maxHp: 300,
      palLevel: 18,
      highestPartyLevel: 12,
      ringBonus: combat.throw.ringBonus.great,
      ballMod: 2.4,
      staggered: true
    });
    expect(loamking).toBeLessThan(0.35);
  });
});

describe('the catch ring', () => {
  it('shrinks over the ring period', () => {
    expect(ringRadiusAt(0)).toBeGreaterThan(ringRadiusAt(combat.throw.ringPeriodMs / 2));
  });

  it('grades none, good and great as the ring closes', () => {
    expect(ringQuality(1)).toBe('none');
    expect(ringQuality(combat.throw.ringGoodBelow - 0.01)).toBe('good');
    expect(ringQuality(combat.throw.ringGreatBelow - 0.01)).toBe('great');
  });

  it('treats the boundaries as the weaker grade, so a grade is never given away', () => {
    expect(ringQuality(combat.throw.ringGoodBelow)).toBe('none');
    expect(ringQuality(combat.throw.ringGreatBelow)).toBe('good');
  });
});
