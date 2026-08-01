import combat from '../data/combat.json';

/**
 * The throw. Pure catch maths plus the ring timing it depends on.
 *
 * GAME_DESIGN.md is emphatic that the throw is available from the first frame
 * of any fight, so nothing here gates on the target being weakened. A full
 * health throw is a bad bet, not an illegal one, and the formula expresses
 * that as a probability rather than a refusal.
 */

export type RingQuality = 'none' | 'good' | 'great';

export interface CatchInput {
  /** species.catchRate, 0.05 to 0.60. */
  speciesCatchRate: number;
  currentHp: number;
  maxHp: number;
  palLevel: number;
  /** Highest level in the player's party. Zero for an empty party. */
  highestPartyLevel: number;
  /** From ringQuality, via combat.throw.ringBonus. */
  ringBonus: number;
  /** Orb tier multiplier from items.json. */
  ballMod: number;
  staggered: boolean;
}

/**
 * Catch chance, GAME_DESIGN.md section 7, verbatim:
 *
 *   hpTerm    = 1 - (currentHP / maxHP) * 0.75
 *   levelTerm = clamp(1 - (palLevel - highestPartyLevel) * 0.03, 0.35, 1.0)
 *   chance    = clamp(base * hpTerm * levelTerm * ringBonus * ballMod * statusMod, 0.01, 0.95)
 *
 * The outer clamp is the design promise, not a safety net: no throw is ever
 * certain and none is ever hopeless. A 95% ceiling is what keeps the moment a
 * Tuftmoth breaks free from feeling like the game cheated, and a 1% floor is
 * what makes a desperate throw at a field boss a story instead of a refusal.
 */
export function catchChance(input: CatchInput): number {
  const maxHp = Math.max(1, input.maxHp);
  const hpFraction = Math.max(0, Math.min(1, input.currentHp / maxHp));
  const hpTerm = 1 - hpFraction * combat.throw.hpTermWeight;

  const levelTerm = Math.max(
    combat.throw.levelTermMin,
    Math.min(
      combat.throw.levelTermMax,
      1 - (input.palLevel - input.highestPartyLevel) * combat.throw.levelTermPerLevel
    )
  );

  const statusMod = input.staggered ? combat.throw.staggeredMod : 1;

  const chance =
    input.speciesCatchRate * hpTerm * levelTerm * input.ringBonus * input.ballMod * statusMod;

  return Math.max(combat.throw.chanceMin, Math.min(combat.throw.chanceMax, chance));
}

/**
 * Ring radius as a 0..1 fraction of its starting size, at `elapsedMs` into the
 * pulse. The ring closes, holds at its tightest, then resets.
 *
 * Modelled as a saw rather than a bounce so the tight window arrives at a
 * predictable rhythm. A player learning the timing should be rewarded for
 * counting, not for reacting to an animation curve they cannot see coming.
 */
export function ringRadiusAt(elapsedMs: number): number {
  const t = (elapsedMs % combat.throw.ringPeriodMs) / combat.throw.ringPeriodMs;
  return 1 - t;
}

/**
 * Grade the ring at release.
 *
 * Boundaries fall to the WEAKER grade. Being strict at the edge means a player
 * who genuinely earned "great" always sees it, and one who was a frame late
 * never gets it for free, which is the direction an honest timing window
 * should err.
 */
export function ringQuality(radius: number): RingQuality {
  if (radius < combat.throw.ringGreatBelow) return 'great';
  if (radius < combat.throw.ringGoodBelow) return 'good';
  return 'none';
}

export function ringBonusFor(quality: RingQuality): number {
  return combat.throw.ringBonus[quality];
}

/**
 * Resolve a throw into the shake sequence the player watches.
 *
 * Every throw plays the full three shakes before breaking, rather than
 * stopping at the shake that failed. The roll has already happened; the
 * animation is there to make the player sweat, and cutting it short at shake
 * one would leak the result early.
 */
export function rollCatch(chance: number, random: () => number): boolean {
  return random() < chance;
}

export const THROW_CONFIG = combat.throw;
