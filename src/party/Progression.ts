import config from '../data/progression.json';
import type { PalState } from './PalState';

/**
 * XP, levels, affinity.
 *
 * Pure functions plus two that mutate the pal they are handed, which is the
 * boundary docs/03_TECHNICAL_ARCHITECTURE.md draws: the curve is maths and gets tested, applying
 * it is a system. Every number lives in progression.json.
 */

export const MAX_LEVEL = config.maxLevel;

/** xpToNext(level) = 12 * level^1.6, per docs/01_GAME_DESIGN.md section 5. */
export function xpToNext(level: number): number {
  if (level >= MAX_LEVEL) return Number.POSITIVE_INFINITY;
  return Math.max(1, Math.floor(config.xpBase * Math.pow(level, config.xpExponent)));
}

/** Total XP to climb from level 1 to `level`. Used to prove 50 is reachable. */
export function totalXpToReach(level: number): number {
  let total = 0;
  for (let l = 1; l < level; l++) total += xpToNext(l);
  return total;
}

/** 18 * defeatedLevel, with a bonus for having had type advantage. */
export function xpForWin(defeatedLevel: number, typeAdvantage: boolean): number {
  const base = config.xpPerDefeatedLevel * defeatedLevel;
  return Math.max(1, Math.floor(base * (typeAdvantage ? config.typeAdvantageBonus : 1)));
}

/** What a pal that did not fight gets. Benched pals fall behind, never stall. */
export function benchShare(activeAward: number): number {
  return Math.max(1, Math.floor(activeAward * config.partyShare));
}

export interface XpResult {
  levelsGained: number;
}

/**
 * Bank XP and level up as many times as it covers.
 *
 * At the cap, XP is discarded rather than accumulated. Banking it would let a
 * level 50 pal hold a number that can never be spent, which is state that has
 * to be saved, migrated and explained for no gameplay reason.
 */
export function awardXp(pal: PalState, amount: number): XpResult {
  if (pal.level >= MAX_LEVEL) {
    pal.xp = 0;
    return { levelsGained: 0 };
  }

  pal.xp += Math.max(0, Math.floor(amount));
  let gained = 0;
  while (pal.level < MAX_LEVEL) {
    const need = xpToNext(pal.level);
    if (pal.xp < need) break;
    pal.xp -= need;
    pal.level++;
    gained++;
  }
  if (pal.level >= MAX_LEVEL) pal.xp = 0;
  return { levelsGained: gained };
}

/** Move affinity, clamped. Rises with wins and meals, falls hard on a faint. */
export function adjustAffinity(pal: PalState, delta: number): number {
  pal.affinity = Math.min(
    config.affinityMax,
    Math.max(config.affinityMin, pal.affinity + delta)
  );
  return pal.affinity;
}

/**
 * Whether a neglected pal balks at a power attack.
 *
 * docs/01_GAME_DESIGN.md section 5: below 25 affinity a pal "will occasionally hesitate
 * on a power attack". It is a refusal to act, not reduced damage; see the note
 * in Damage.affinityMultiplier for why those are kept separate.
 */
export function hesitates(affinity: number, rand: () => number = Math.random): boolean {
  if (affinity >= config.affinityLowThreshold) return false;
  return rand() < config.affinityLowHesitateChance;
}

export const PROGRESSION_CONFIG = config;
