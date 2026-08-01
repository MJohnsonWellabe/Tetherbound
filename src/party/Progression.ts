import combat from '../data/combat.json';
import { recomputeStats, type PalState } from './Pal';

/**
 * XP, levels and affinity. Pure functions over plain pal data.
 *
 * GAME_DESIGN.md section 5 for the curves. Affinity is the piece worth stating
 * plainly: it rises slowly on wins and drops hard on a faint, so the pals you
 * have carried are measurably better than the ones you have not, and the
 * release screen is choosing between numbers you earned rather than a list of
 * interchangeable creatures.
 */

export { damageAffinityMultiplier } from '../combat/Damage';

/** XP required to go from `level` to the next one. */
export function xpToNext(level: number): number {
  return Math.floor(combat.xp.curveA * Math.pow(level, combat.xp.curveB));
}

/** XP a win awards, before the benched party's share is taken from it. */
export function xpForWin(defeatedLevel: number, typeAdvantage: boolean): number {
  const bonus = typeAdvantage ? combat.xp.typeAdvantageBonus : 1;
  return Math.floor(combat.xp.winBase * defeatedLevel * bonus);
}

/** What each non-active party member receives from the active pal's award. */
export function benchShare(award: number): number {
  return Math.floor(award * combat.xp.partyShare);
}

/**
 * Grant XP, levelling as many times as it covers. Returns the levels gained.
 *
 * Current HP rises by the same amount max HP does rather than being refilled.
 * A level-up mid-fight should feel like a reward, not a free heal that removes
 * the reason to carry food.
 */
export function awardXp(pal: PalState, amount: number): number {
  if (amount <= 0 || pal.level >= combat.xp.maxLevel) {
    // At the cap, banked XP has nowhere to go. Dropping it keeps the save
    // honest instead of storing a number that will never be spent.
    if (pal.level >= combat.xp.maxLevel) pal.xp = 0;
    return 0;
  }

  pal.xp += Math.floor(amount);
  let gained = 0;

  while (pal.level < combat.xp.maxLevel && pal.xp >= xpToNext(pal.level)) {
    pal.xp -= xpToNext(pal.level);
    pal.level += 1;
    gained += 1;

    const beforeMax = pal.maxHp;
    recomputeStats(pal);
    pal.hp = Math.min(pal.maxHp, pal.hp + (pal.maxHp - beforeMax));
  }

  if (pal.level >= combat.xp.maxLevel) pal.xp = 0;
  return gained;
}

function clampAffinity(value: number): number {
  return Math.max(0, Math.min(combat.affinity.max, value));
}

export function affinityAfterWin(affinity: number): number {
  return clampAffinity(affinity + combat.affinity.onWin);
}

export function affinityAfterFaint(affinity: number): number {
  return clampAffinity(affinity + combat.affinity.onFaint);
}

export function affinityAfterEat(affinity: number): number {
  return clampAffinity(affinity + combat.affinity.onEat);
}

/**
 * Whether a low-affinity pal balks at a power attack this time.
 *
 * `random` is injected so the hesitation is reproducible in a test and can be
 * driven off the combat RNG rather than a global.
 */
export function hesitatesOnPower(affinity: number, random: () => number): boolean {
  if (affinity >= combat.affinity.lowThreshold) return false;
  return random() < combat.affinity.hesitateChance;
}

/**
 * Tick a fainted pal back toward consciousness. `atCampfire` shortens the wait
 * to thirty seconds, which is what makes a campfire worth building.
 */
export function tickRevive(pal: PalState, dtMs: number, atCampfire: boolean): boolean {
  if (pal.hp > 0) return false;
  if (pal.reviveMs <= 0) {
    pal.reviveMs = atCampfire ? combat.revive.campfireMs : combat.revive.naturalMs;
  }
  // Sitting down at a fire should shorten a wait already in progress, not
  // require the player to have planned ahead before the pal went down.
  if (atCampfire) pal.reviveMs = Math.min(pal.reviveMs, combat.revive.campfireMs);

  pal.reviveMs -= dtMs;
  if (pal.reviveMs > 0) return false;

  pal.reviveMs = 0;
  pal.hp = Math.max(1, Math.round(pal.maxHp * combat.revive.healthOnRevive));
  return true;
}

export const PROGRESSION_CONFIG = combat;
