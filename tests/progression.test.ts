import { describe, expect, it } from 'vitest';
import {
  MAX_LEVEL,
  adjustAffinity,
  awardXp,
  benchShare,
  hesitates,
  totalXpToReach,
  xpForWin,
  xpToNext
} from '../src/party/Progression';
import type { PalState } from '../src/party/PalState';

function pal(level = 1, xp = 0): PalState {
  return {
    uid: 'p',
    species: 'tuftmoth',
    nickname: null,
    level,
    xp,
    variance: 1,
    affinity: 50,
    currentHp: 20,
    fainted: false,
    caughtOnDay: 1,
    caughtAtMs: 0
  };
}

describe('the xp curve', () => {
  it('is strictly increasing', () => {
    let last = -Infinity;
    for (let level = 1; level < MAX_LEVEL; level++) {
      const need = xpToNext(level);
      expect(need).toBeGreaterThan(last);
      last = need;
    }
  });

  it('always demands at least one point', () => {
    for (let level = 1; level < MAX_LEVEL; level++) {
      expect(xpToNext(level)).toBeGreaterThanOrEqual(1);
    }
  });

  it('returns whole numbers', () => {
    for (let level = 1; level < MAX_LEVEL; level++) {
      expect(Number.isInteger(xpToNext(level))).toBe(true);
    }
  });

  it('makes level 50 reachable in a finite total', () => {
    const total = totalXpToReach(MAX_LEVEL);
    expect(Number.isFinite(total)).toBe(true);
    expect(total).toBeGreaterThan(0);
  });

  it('reaches level 50 by grinding, and stops there', () => {
    const p = pal(1);
    // Beating level-30 pals repeatedly must cap out rather than overflow.
    for (let i = 0; i < 4000; i++) awardXp(p, xpForWin(30, false));
    expect(p.level).toBe(MAX_LEVEL);
  });

  it('never exceeds the maximum level', () => {
    const p = pal(49);
    awardXp(p, 99_999_999);
    expect(p.level).toBe(MAX_LEVEL);
  });

  it('stops accumulating xp at the cap rather than banking it forever', () => {
    const p = pal(MAX_LEVEL);
    awardXp(p, 100_000);
    expect(p.level).toBe(MAX_LEVEL);
    expect(p.xp).toBe(0);
  });
});

describe('awarding xp', () => {
  it('levels up when the threshold is crossed', () => {
    const p = pal(1);
    const gained = awardXp(p, xpToNext(1));
    expect(p.level).toBe(2);
    expect(gained.levelsGained).toBe(1);
  });

  it('can gain several levels from one big win', () => {
    const p = pal(1);
    const gained = awardXp(p, xpToNext(1) + xpToNext(2) + xpToNext(3));
    expect(gained.levelsGained).toBeGreaterThanOrEqual(3);
  });

  it('keeps the remainder after a level up', () => {
    const p = pal(1);
    awardXp(p, xpToNext(1) + 5);
    expect(p.xp).toBe(5);
  });

  it('does not level up on exactly one point short', () => {
    const p = pal(1);
    awardXp(p, xpToNext(1) - 1);
    expect(p.level).toBe(1);
  });
});

describe('win rewards', () => {
  it('scales with the level of what you beat', () => {
    expect(xpForWin(20, false)).toBeGreaterThan(xpForWin(5, false));
  });

  it('pays a bonus for type advantage', () => {
    expect(xpForWin(10, true)).toBeGreaterThan(xpForWin(10, false));
  });

  it('gives benched pals a share, but less than the fighter', () => {
    const full = xpForWin(10, false);
    const share = benchShare(full);
    expect(share).toBeGreaterThan(0);
    expect(share).toBeLessThan(full);
  });
});

describe('affinity', () => {
  it('stays inside 0 and 100', () => {
    const p = pal();
    for (let i = 0; i < 200; i++) adjustAffinity(p, 25);
    expect(p.affinity).toBeLessThanOrEqual(100);
    for (let i = 0; i < 200; i++) adjustAffinity(p, -25);
    expect(p.affinity).toBeGreaterThanOrEqual(0);
  });

  it('falls when a pal faints', () => {
    const p = pal();
    const before = p.affinity;
    adjustAffinity(p, -12);
    expect(p.affinity).toBeLessThan(before);
  });
});

describe('hesitation', () => {
  it('never hesitates when the pal is bonded', () => {
    expect(hesitates(90, () => 0)).toBe(false);
  });

  it('can hesitate when affinity is low', () => {
    expect(hesitates(10, () => 0)).toBe(true);
  });

  it('does not hesitate on a high roll even at low affinity', () => {
    expect(hesitates(10, () => 0.99)).toBe(false);
  });
});
