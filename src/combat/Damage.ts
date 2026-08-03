import progression from '../data/progression.json';
import types from '../data/types.json';

/**
 * The type ring, the damage formula, and stat scaling.
 *
 * Pure. Takes numbers, returns numbers, touches no globals, imports no engine.
 * docs/03_TECHNICAL_ARCHITECTURE.md requires exactly this of combat math so it can be unit
 * tested, and CLAUDE.md requires the tests to be written first.
 *
 * Randomness is injected rather than called, so a test can pin the roll and a
 * replay can reproduce a fight.
 */

export type PalType = 'verdant' | 'tide' | 'ember' | 'stone' | 'spark';

export const ALL_TYPES = types.order as PalType[];

const BEATS = types.beats as Record<PalType, PalType>;

export interface Attacker {
  atk: number;
  level: number;
  type: PalType;
  affinity: number;
}

export interface Defender {
  def: number;
  level: number;
  type: PalType;
}

/**
 * Effectiveness of `attacker` against `defender`.
 *
 * Derived from a single "beats" edge per type rather than a 25-entry table.
 * A table can drift out of sync with itself; a ring cannot, and every pairing
 * in it is still covered by the tests.
 */
export function typeMultiplier(attacker: PalType, defender: PalType): number {
  if (BEATS[attacker] === defender) return types.strong;
  if (BEATS[defender] === attacker) return types.weak;
  return types.neutral;
}

/**
 * Damage bonus from affinity.
 *
 * Above the high threshold a bonded pal hits harder. Below the low threshold it
 * does NOT hit softer: docs/01_GAME_DESIGN.md section 5 says a neglected pal hesitates
 * on power attacks, which MoveResolver handles. Applying both would be a hidden
 * double penalty on the pal the player already feels worst about.
 */
export function affinityMultiplier(affinity: number): number {
  return affinity >= progression.affinityHighThreshold
    ? 1 + progression.affinityHighDamageBonus
    : 1;
}

/**
 * docs/01_GAME_DESIGN.md section 7:
 *   dmg = (ATK / DEF) * movePower * typeMult * affinityMult
 *         * rand(0.9, 1.1) * (1 + 0.02 * levelDiff)
 *
 * Floored to a whole number, and never below 1. A hit that reads as zero looks
 * like an input that did not register, which is worse than a hit that barely
 * matters.
 */
export function damage(
  attacker: Attacker,
  defender: Defender,
  movePower: number,
  rand: () => number = Math.random
): number {
  const ratio = attacker.atk / Math.max(defender.def, 1);
  const type = typeMultiplier(attacker.type, defender.type);
  const affinity = affinityMultiplier(attacker.affinity);
  const roll = DAMAGE_ROLL_MIN + rand() * (DAMAGE_ROLL_MAX - DAMAGE_ROLL_MIN);
  const levels = 1 + LEVEL_DIFF_WEIGHT * (attacker.level - defender.level);

  const raw = ratio * movePower * type * affinity * roll * Math.max(levels, MIN_LEVEL_SCALE);
  return Math.max(1, Math.floor(raw));
}

/** stat = floor(base * (1 + level * levelStatGain) * variance), minimum 1. */
export function statAt(base: number, level: number, variance: number): number {
  return Math.max(1, Math.floor(base * (1 + level * progression.levelStatGain) * variance));
}

/**
 * Tuning that belongs to the formula rather than to a pal.
 *
 * These are the only numbers in this file and they come straight from the
 * formula as written in docs/01_GAME_DESIGN.md section 7. MIN_LEVEL_SCALE stops a
 * 50-level gap from inverting the sign of the whole expression, which would
 * make an overlevelled attacker heal its target.
 */
const DAMAGE_ROLL_MIN = 0.9;
const DAMAGE_ROLL_MAX = 1.1;
const LEVEL_DIFF_WEIGHT = 0.02;
const MIN_LEVEL_SCALE = 0.1;
