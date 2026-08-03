import { describe, expect, it } from 'vitest';
import {
  CATCH_MAX,
  CATCH_MIN,
  ballMod,
  catchChance,
  ringBonus,
  rollCatch,
  shakeCount,
  type ThrowInput
} from '../src/combat/Throw';

const BASE: ThrowInput = {
  speciesCatchRate: 0.3,
  currentHp: 100,
  maxHp: 100,
  palLevel: 10,
  highestPartyLevel: 10,
  ring: 'none',
  orb: 'worn_orb',
  staggered: false,
  collared: false
};

describe('catch chance clamping', () => {
  it('never leaves the 0.01 to 0.95 band across the whole input range', () => {
    // docs/03_TECHNICAL_ARCHITECTURE.md names this explicitly as required coverage.
    for (const rate of [0.05, 0.2, 0.35, 0.6]) {
      for (const hpFrac of [0, 0.01, 0.25, 0.5, 0.99, 1]) {
        for (const palLevel of [1, 5, 18, 30, 50]) {
          for (const partyLevel of [1, 5, 18, 30, 50]) {
            for (const ring of ['none', 'good', 'great'] as const) {
              for (const orb of ['worn_orb', 'keen_orb', 'truestone_orb']) {
                for (const staggered of [false, true]) {
                  const c = catchChance({
                    speciesCatchRate: rate,
                    currentHp: Math.max(1, Math.round(100 * hpFrac)),
                    maxHp: 100,
                    palLevel,
                    highestPartyLevel: partyLevel,
                    ring,
                    orb,
                    staggered,
                    collared: false
                  });
                  expect(c).toBeGreaterThanOrEqual(CATCH_MIN);
                  expect(c).toBeLessThanOrEqual(CATCH_MAX);
                }
              }
            }
          }
        }
      }
    }
  });

  it('caps even a maximally favourable throw below certainty', () => {
    const c = catchChance({
      ...BASE,
      speciesCatchRate: 0.6,
      currentHp: 1,
      palLevel: 1,
      highestPartyLevel: 50,
      ring: 'great',
      orb: 'truestone_orb',
      staggered: true
    });
    expect(c).toBeLessThanOrEqual(CATCH_MAX);
    // A guaranteed catch would remove the decision the whole game is built on.
    expect(c).toBeLessThan(1);
  });
});

describe('what makes a catch likelier', () => {
  it('rewards a wounded target', () => {
    const healthy = catchChance({ ...BASE, currentHp: 100 });
    const hurt = catchChance({ ...BASE, currentHp: 15 });
    expect(hurt).toBeGreaterThan(healthy);
  });

  it('rewards a tighter ring', () => {
    const none = catchChance({ ...BASE, ring: 'none' });
    const good = catchChance({ ...BASE, ring: 'good' });
    const great = catchChance({ ...BASE, ring: 'great' });
    expect(good).toBeGreaterThan(none);
    expect(great).toBeGreaterThan(good);
  });

  it('rewards a better orb', () => {
    const worn = catchChance({ ...BASE, orb: 'worn_orb' });
    const keen = catchChance({ ...BASE, orb: 'keen_orb' });
    const true_ = catchChance({ ...BASE, orb: 'truestone_orb' });
    expect(keen).toBeGreaterThan(worn);
    expect(true_).toBeGreaterThan(keen);
  });

  it('rewards a staggered target', () => {
    expect(catchChance({ ...BASE, staggered: true })).toBeGreaterThan(
      catchChance({ ...BASE, staggered: false })
    );
  });

  it('punishes throwing at something far above your party', () => {
    const even = catchChance({ ...BASE, palLevel: 10, highestPartyLevel: 10 });
    const over = catchChance({ ...BASE, palLevel: 40, highestPartyLevel: 10 });
    expect(over).toBeLessThan(even);
  });

  it('does not keep rewarding levels below your party forever', () => {
    // The level term is clamped at 1.0, so a level 1 target is not a free
    // catch just because the party is level 50.
    const a = catchChance({ ...BASE, palLevel: 1, highestPartyLevel: 20 });
    const b = catchChance({ ...BASE, palLevel: 1, highestPartyLevel: 50 });
    expect(a).toBe(b);
  });
});

describe('collared pals', () => {
  it('cannot be caught at all', () => {
    // docs/01_GAME_DESIGN.md section 10: the orb bounces off Team Tether's pals. This
    // is a rule, not a low roll, so it has to be zero and not merely small.
    expect(catchChance({ ...BASE, collared: true })).toBe(0);
  });

  it('stays uncatchable even under perfect conditions', () => {
    expect(
      catchChance({
        ...BASE,
        collared: true,
        currentHp: 1,
        ring: 'great',
        orb: 'truestone_orb',
        staggered: true
      })
    ).toBe(0);
  });

  it('never rolls a success', () => {
    for (let i = 0; i < 100; i++) {
      expect(rollCatch({ ...BASE, collared: true }, () => i / 100).caught).toBe(false);
    }
  });
});

describe('the roll', () => {
  it('catches when the roll lands under the chance', () => {
    const result = rollCatch({ ...BASE, currentHp: 5, ring: 'great' }, () => 0);
    expect(result.caught).toBe(true);
  });

  it('fails when the roll lands above the chance', () => {
    expect(rollCatch(BASE, () => 0.999).caught).toBe(false);
  });

  it('reports the chance it used, so the HUD is never guessing', () => {
    const result = rollCatch(BASE, () => 0.5);
    expect(result.chance).toBe(catchChance(BASE));
  });
});

describe('shakes', () => {
  it('always plays three shakes on a success', () => {
    expect(shakeCount(true, 0.9)).toBe(3);
  });

  it('breaks out somewhere in the first three on a failure', () => {
    for (let i = 0; i <= 100; i++) {
      const n = shakeCount(false, i / 100);
      expect(n).toBeGreaterThanOrEqual(0);
      expect(n).toBeLessThanOrEqual(2);
    }
  });
});

describe('orb tiers', () => {
  it('matches the table in docs/01_GAME_DESIGN.md section 7', () => {
    expect(ballMod('worn_orb')).toBe(1.0);
    expect(ballMod('keen_orb')).toBe(1.6);
    expect(ballMod('truestone_orb')).toBe(2.4);
  });

  it('treats an unknown orb as the weakest rather than throwing', () => {
    expect(ballMod('mystery_orb')).toBe(1.0);
  });
});

describe('ring bonuses', () => {
  it('matches the table in docs/01_GAME_DESIGN.md section 7', () => {
    expect(ringBonus('none')).toBe(1.0);
    expect(ringBonus('good')).toBe(1.3);
    expect(ringBonus('great')).toBe(1.7);
  });
});

describe('the guaranteed opening catch', () => {
  // docs/01_GAME_DESIGN.md section 3 / Objectives.ts: the scripted tuftmoth must land
  // on the first orb, whatever the roll. This is applied per-pal by whoever
  // spawns it (SpawnManager.spawnScripted), not by anything in this file, so
  // these only check the formula itself is an honest override.

  it('bypasses every other term, even the worst possible throw', () => {
    const c = catchChance({
      ...BASE,
      guaranteed: true,
      speciesCatchRate: 0.01,
      currentHp: 100,
      palLevel: 50,
      highestPartyLevel: 1,
      ring: 'none',
      orb: 'worn_orb',
      staggered: false
    });
    expect(c).toBe(1);
  });

  it('never fails to catch, across the whole roll range a real rng produces', () => {
    // `rand()` is documented (and every seeded generator in this codebase
    // guarantees) to return [0, 1), never touching 1 itself, so i < 100
    // covers everything a real roll can produce.
    for (let i = 0; i < 100; i++) {
      expect(rollCatch({ ...BASE, guaranteed: true }, () => i / 100).caught).toBe(true);
    }
  });

  it('does not apply when the flag is unset, i.e. when nothing marks the pal guaranteed', () => {
    // A normal pal (guaranteed omitted, same as false) is not certain to be
    // caught even under a bad roll, unlike the guaranteed pal above.
    expect(rollCatch({ ...BASE, currentHp: 100, ring: 'none' }, () => 0.999).caught).toBe(false);
  });

  it('a collared pal stays uncatchable even if it were somehow also flagged guaranteed', () => {
    // Collared is Tether's rule; guaranteed is the opening scene's. Collared
    // wins, because nothing should ever be able to make a Tether pal catchable.
    expect(catchChance({ ...BASE, collared: true, guaranteed: true })).toBe(0);
  });
});
