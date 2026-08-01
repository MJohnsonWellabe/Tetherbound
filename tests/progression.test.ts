import { describe, expect, it } from 'vitest';
import combat from '../src/data/combat.json';
import { makePal } from '../src/party/Pal';
import {
  affinityAfterFaint,
  affinityAfterWin,
  awardXp,
  damageAffinityMultiplier,
  xpForWin,
  xpToNext
} from '../src/party/Progression';

/**
 * ARCHITECTURE.md: the XP curve must be strictly increasing and level 50 must
 * be reachable. "Reachable" is the load-bearing half. A curve that grows too
 * fast is not a balance problem, it is a cap the player can never touch.
 */

describe('the xp curve', () => {
  it('is strictly increasing', () => {
    for (let level = 1; level < combat.xp.maxLevel; level++) {
      expect(xpToNext(level + 1)).toBeGreaterThan(xpToNext(level));
    }
  });

  it('matches the published formula', () => {
    expect(xpToNext(10)).toBe(Math.floor(combat.xp.curveA * Math.pow(10, combat.xp.curveB)));
  });

  it('reaches level 50 in a plausible number of fights', () => {
    let total = 0;
    for (let level = 1; level < combat.xp.maxLevel; level++) total += xpToNext(level);
    // Fighting things at your own level the whole way up.
    const perFight = xpForWin(25, false);
    expect(total / perFight).toBeLessThan(2000);
    expect(total).toBeGreaterThan(0);
  });
});

describe('xp awards', () => {
  it('scales with the level of what you beat', () => {
    expect(xpForWin(10, false)).toBeGreaterThan(xpForWin(5, false));
  });

  it('pays the type advantage bonus', () => {
    expect(xpForWin(10, true) / xpForWin(10, false)).toBeCloseTo(combat.xp.typeAdvantageBonus, 5);
  });

  it('levels a pal up when the award crosses the threshold', () => {
    const pal = makePal('tuftmoth', 2, () => 0.5);
    const before = pal.level;
    awardXp(pal, xpToNext(pal.level) + 1);
    expect(pal.level).toBe(before + 1);
  });

  it('can level more than once from a single large award', () => {
    const pal = makePal('tuftmoth', 2, () => 0.5);
    awardXp(pal, xpToNext(2) + xpToNext(3) + xpToNext(4) + 1);
    expect(pal.level).toBeGreaterThanOrEqual(5);
  });

  it('raises max hp on level up and does not leave current hp above it', () => {
    const pal = makePal('cragpup', 6, () => 1);
    const beforeMax = pal.maxHp;
    awardXp(pal, xpToNext(pal.level) + 1);
    expect(pal.maxHp).toBeGreaterThan(beforeMax);
    expect(pal.hp).toBeLessThanOrEqual(pal.maxHp);
  });

  it('stops at the level cap and does not bank xp past it', () => {
    const pal = makePal('tuftmoth', combat.xp.maxLevel, () => 0.5);
    awardXp(pal, 9_999_999);
    expect(pal.level).toBe(combat.xp.maxLevel);
  });

  it('gives benched pals their share', () => {
    expect(combat.xp.partyShare).toBeGreaterThan(0);
    expect(combat.xp.partyShare).toBeLessThan(1);
  });
});

describe('affinity', () => {
  it('rises on a win and falls harder on a faint', () => {
    expect(affinityAfterWin(50)).toBeGreaterThan(50);
    expect(affinityAfterFaint(50)).toBeLessThan(50);
    expect(50 - affinityAfterFaint(50)).toBeGreaterThan(affinityAfterWin(50) - 50);
  });

  it('stays inside 0 and the maximum', () => {
    expect(affinityAfterWin(combat.affinity.max)).toBe(combat.affinity.max);
    expect(affinityAfterFaint(0)).toBe(0);
  });

  it('pays a damage bonus only at or above the high threshold', () => {
    expect(damageAffinityMultiplier(combat.affinity.highThreshold - 1)).toBe(1);
    expect(damageAffinityMultiplier(combat.affinity.highThreshold)).toBeCloseTo(
      1 + combat.affinity.highDamageBonus,
      5
    );
  });
});

describe('individual variance', () => {
  it('is locked at spawn and applied to every stat', () => {
    const weak = makePal('grazehorn', 10, () => 0);
    const strong = makePal('grazehorn', 10, () => 1);
    expect(strong.maxHp).toBeGreaterThan(weak.maxHp);
    expect(strong.atk).toBeGreaterThan(weak.atk);
    expect(weak.variance).toBeCloseTo(combat.stats.varianceMin, 5);
    expect(strong.variance).toBeCloseTo(combat.stats.varianceMax, 5);
  });

  it('survives a level up unchanged', () => {
    const pal = makePal('grazehorn', 10, () => 0.25);
    const v = pal.variance;
    awardXp(pal, xpToNext(pal.level) + 1);
    expect(pal.variance).toBe(v);
  });

  it('starts a pal at full health', () => {
    const pal = makePal('tuftmoth', 4, () => 0.5);
    expect(pal.hp).toBe(pal.maxHp);
  });
});
