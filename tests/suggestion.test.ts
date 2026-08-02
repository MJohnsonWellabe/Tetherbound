import { describe, expect, it } from 'vitest';
import { suggestActions, type FightRead } from '../src/combat/Suggestion';
import moves from '../src/data/moves.json';
import orbs from '../src/data/orbs.json';

/**
 * Suggestion.ts is the button-glow read (owner's ROG Ally playtest: "the
 * buttons should light up as you more increasingly should choose them").
 * These assert against the real thresholds in moves.json and orbs.json, and
 * the one invariant CombatButtons.ts depends on: nothing here ever says a
 * button is unavailable, only that it is recommended.
 */

const RUN_HP = moves.suggestRunHpFraction;
const ORB_HP = orbs.suggestCatchHpFraction;

function read(overrides: Partial<FightRead> = {}): FightRead {
  return {
    allyHpFraction: 1,
    enemyHpFraction: 1,
    chargeAvailable: false,
    orbsHeld: 0,
    canFlee: true,
    ...overrides
  };
}

describe('quick vs power', () => {
  it('suggests quick until the charge bar covers a power attack', () => {
    const s = suggestActions(read({ chargeAvailable: false }));
    expect(s.quick).toBe(true);
    expect(s.power).toBe(false);
  });

  it('suggests power, not quick, once the charge is available', () => {
    const s = suggestActions(read({ chargeAvailable: true }));
    expect(s.power).toBe(true);
    expect(s.quick).toBe(false);
  });
});

describe('the orb suggestion', () => {
  it('never lights up with no orbs in hand, however low the enemy is', () => {
    const s = suggestActions(read({ orbsHeld: 0, enemyHpFraction: 0 }));
    expect(s.orb).toBe(false);
  });

  it('never lights up while the enemy is above the catch threshold', () => {
    const s = suggestActions(read({ orbsHeld: 3, enemyHpFraction: ORB_HP + 0.01 }));
    expect(s.orb).toBe(false);
  });

  it('lights up exactly at the threshold when orbs are held', () => {
    const s = suggestActions(read({ orbsHeld: 3, enemyHpFraction: ORB_HP }));
    expect(s.orb).toBe(true);
  });

  it('lights up below the threshold when orbs are held', () => {
    const s = suggestActions(read({ orbsHeld: 1, enemyHpFraction: 0 }));
    expect(s.orb).toBe(true);
  });
});

describe('the run suggestion', () => {
  it('never lights up when fleeing is refused, however low the ally is', () => {
    const s = suggestActions(read({ canFlee: false, allyHpFraction: 0 }));
    expect(s.run).toBe(false);
  });

  it('never lights up while the ally is above the retreat threshold', () => {
    const s = suggestActions(read({ canFlee: true, allyHpFraction: RUN_HP + 0.01 }));
    expect(s.run).toBe(false);
  });

  it('lights up exactly at the threshold when fleeing is allowed', () => {
    const s = suggestActions(read({ canFlee: true, allyHpFraction: RUN_HP }));
    expect(s.run).toBe(true);
  });

  it('lights up below the threshold when fleeing is allowed', () => {
    const s = suggestActions(read({ canFlee: true, allyHpFraction: 0 }));
    expect(s.run).toBe(true);
  });
});

describe('the shape carries no availability field', () => {
  it('returns exactly quick, power, orb and run, and nothing that reads as "disabled" or "available"', () => {
    const s = suggestActions(read());
    expect(Object.keys(s).sort()).toEqual(['orb', 'power', 'quick', 'run']);
    expect(s).not.toHaveProperty('available');
    expect(s).not.toHaveProperty('disabled');
  });
});
