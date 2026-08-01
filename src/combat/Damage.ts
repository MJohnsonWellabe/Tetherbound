import combat from '../data/combat.json';

/**
 * The type ring and the damage formula. Pure functions, no globals, no engine.
 *
 * GAME_DESIGN.md section 5 chose a five-element ring over a type chart on
 * purpose: each type beats exactly one and loses to exactly one, so a player
 * can hold the whole system in their head after one fight and still get a real
 * counter-pick decision at a Hall.
 *
 * The random roll is a PARAMETER, not something this file generates. That is
 * what lets the tests assert exact numbers instead of sampling, and it keeps
 * combat replayable from a seed later without touching the formula.
 */

const RING = combat.typeRing.order;

export type PalType = 'verdant' | 'tide' | 'ember' | 'stone' | 'spark';

export const ALL_TYPES = RING as readonly PalType[];

export function isPalType(value: string): value is PalType {
  return (RING as readonly string[]).includes(value);
}

/**
 * Attacker versus defender, as a damage multiplier.
 *
 * A type is strong against the one that follows it in the ring and weak
 * against the one before it. Everything else is neutral, including a type
 * against itself.
 */
export function typeMultiplier(attacker: PalType, defender: PalType): number {
  const a = RING.indexOf(attacker);
  const d = RING.indexOf(defender);
  // An unknown type is neutral rather than an exception: bad data should make a
  // pal boring, not crash a fight the player is in the middle of.
  if (a < 0 || d < 0) return combat.typeRing.neutral;

  const n = RING.length;
  if (d === (a + 1) % n) return combat.typeRing.strong;
  if (d === (a + n - 1) % n) return combat.typeRing.weak;
  return combat.typeRing.neutral;
}

/** True when this matchup is the favourable one, for the XP bonus. */
export function hasTypeAdvantage(attacker: PalType, defender: PalType): boolean {
  return typeMultiplier(attacker, defender) === combat.typeRing.strong;
}

/**
 * A stat at a given level. GAME_DESIGN.md section 5:
 *   stat = floor(base * (1 + level * 0.035) * variance)
 *
 * Variance is rolled once when the pal spawns and never again, which is what
 * makes an individual pal yours rather than interchangeable with the next one
 * of its species.
 */
export function statAt(base: number, level: number, variance: number): number {
  return Math.floor(base * (1 + level * combat.stats.levelGain) * variance);
}

/** Multiplier a pal's affinity contributes to its damage. */
export function damageAffinityMultiplier(affinity: number): number {
  return affinity >= combat.affinity.highThreshold ? 1 + combat.affinity.highDamageBonus : 1;
}

export interface DamageInput {
  atk: number;
  def: number;
  movePower: number;
  attackerType: PalType;
  defenderType: PalType;
  /** Attacker's affinity, 0..100. */
  affinity: number;
  /** Attacker level minus defender level. */
  levelDiff: number;
  /** Tether's pals hit harder. Their collar is why they never dodge. */
  collared: boolean;
}

/**
 * The formula from GAME_DESIGN.md section 7:
 *
 *   dmg = (ATK / DEF) * movePower * typeMult * affinityMult
 *         * rand(0.9, 1.1) * (1 + 0.02 * levelDiff)
 *
 * `roll` is the rand term, supplied by the caller.
 *
 * The level difference is clamped. Uncapped, a level 50 pal against a level 2
 * one gets a +96% bonus on top of a stat gap that already decided the fight,
 * and the Loamking at 18 against a fresh party stops being a boss and becomes
 * a wall. Clamping keeps the term as flavour rather than the whole calculation.
 */
export function computeDamage(input: DamageInput, roll: number): number {
  const clampedDiff = Math.max(
    -combat.damage.levelDiffClamp,
    Math.min(combat.damage.levelDiffClamp, input.levelDiff)
  );

  // Defence of zero would divide by zero; a pal with no defence should take a
  // lot of damage, not infinite damage.
  const def = Math.max(1, input.def);

  const raw =
    (input.atk / def) *
    input.movePower *
    typeMultiplier(input.attackerType, input.defenderType) *
    damageAffinityMultiplier(input.affinity) *
    roll *
    (1 + combat.damage.levelDiffPerLevel * clampedDiff) *
    (input.collared ? combat.damage.collaredAttackMultiplier : 1);

  // Nothing is ever fully immune. A hit that reads as zero looks like a bug to
  // the player even when the maths is right.
  return Math.max(combat.damage.minimum, raw);
}

/** Roll the random term. Kept here so callers do not each invent their own band. */
export function rollDamageVariance(random: () => number): number {
  return combat.damage.rollMin + random() * (combat.damage.rollMax - combat.damage.rollMin);
}

export const DAMAGE_CONFIG = combat;
