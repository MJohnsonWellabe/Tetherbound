import config from '../data/orbs.json';

/**
 * The catch roll.
 *
 * Pure, per docs/03_TECHNICAL_ARCHITECTURE.md, and unit tested against the clamp because a catch
 * chance that escapes its band is either a guaranteed catch or an impossible
 * one, and both break the five-slot decision the game is built on.
 *
 * The throw itself is always available, from the first frame of a fight
 * (docs/01_GAME_DESIGN.md section 7, and CLAUDE.md hard constraint 3). Nothing in this
 * file gates on combat state, and nothing should ever be added that does.
 */

export type RingQuality = 'none' | 'good' | 'great';

export interface ThrowInput {
  speciesCatchRate: number;
  currentHp: number;
  maxHp: number;
  palLevel: number;
  highestPartyLevel: number;
  ring: RingQuality;
  orb: string;
  staggered: boolean;
  /**
   * Team Tether collars their pals. The orb bounces off with a distinct sound
   * (section 10), which teaches that Tether's pals are not catchable and
   * reserves the throw for the wild.
   */
  collared: boolean;
  /**
   * The scripted, docile tuftmoth of the opening scene (Objectives.ts). While
   * true this bypasses the whole formula below, the same way `collared`
   * bypasses it at the other end: a rule, not a favourable roll. Decided once,
   * at spawn time, by whoever places that one pal; nothing else may set it.
   */
  guaranteed?: boolean;
}

export interface CatchResult {
  caught: boolean;
  chance: number;
  shakes: number;
}

export const CATCH_MIN = config.clampMin;
export const CATCH_MAX = config.clampMax;

const BALL_MOD = config.ballMod as Record<string, number | undefined>;
const RING_BONUS = config.ringBonus as Record<RingQuality, number>;

/** Unknown orbs count as the weakest rather than throwing at runtime. */
export function ballMod(orb: string): number {
  return BALL_MOD[orb] ?? 1.0;
}

export function ringBonus(ring: RingQuality): number {
  return RING_BONUS[ring] ?? 1.0;
}

/**
 * docs/01_GAME_DESIGN.md section 7, verbatim:
 *
 *   base      = species.catchRate
 *   hpTerm    = 1 - (currentHP / maxHP) * 0.75
 *   levelTerm = clamp(1 - (palLevel - highestPartyLevel) * 0.03, 0.35, 1.0)
 *   chance    = clamp(base * hpTerm * levelTerm * ringBonus * ballMod * statusMod, 0.01, 0.95)
 *
 * A collared pal returns 0, which is outside the clamp on purpose: it is a
 * rule rather than a bad roll, and the HUD needs to be able to tell the
 * difference so it can bounce the orb instead of shaking it.
 */
export function catchChance(input: ThrowInput): number {
  if (input.collared) return 0;
  // Outside the clamp on purpose, like the collared rule above it: a promise,
  // not a very good roll. Only the opening scene's scripted tuftmoth ever sets
  // this, and only until it is caught (docs/01_GAME_DESIGN.md section 3).
  if (input.guaranteed) return config.guaranteedChance;

  const hpFraction = input.maxHp > 0 ? input.currentHp / input.maxHp : 1;
  const hpTerm = 1 - hpFraction * config.hpWeight;

  const levelTerm = clamp(
    1 - (input.palLevel - input.highestPartyLevel) * config.levelPenaltyPerLevel,
    config.levelTermMin,
    config.levelTermMax
  );

  const status = input.staggered ? config.staggeredMod : 1;

  const raw =
    input.speciesCatchRate *
    hpTerm *
    levelTerm *
    ringBonus(input.ring) *
    ballMod(input.orb) *
    status;

  return clamp(raw, config.clampMin, config.clampMax);
}

/**
 * Roll it. `rand` is injected so tests are deterministic and a replay can
 * reproduce the moment a player lost a Tuftmoth.
 */
export function rollCatch(input: ThrowInput, rand: () => number = Math.random): CatchResult {
  const chance = catchChance(input);
  const caught = chance > 0 && rand() < chance;
  return { caught, chance, shakes: shakeCount(caught, rand()) };
}

/**
 * How many times the orb shakes before it opens.
 *
 * Three shakes and it holds. A failure breaks out partway, and which shake it
 * breaks on is cosmetic; the roll already happened. Deciding the outcome first
 * and then animating it is what keeps the animation honest.
 */
export function shakeCount(caught: boolean, roll: number): number {
  if (caught) return config.shakeCount;
  return Math.min(config.shakeCount - 1, Math.floor(roll * config.shakeCount));
}

/**
 * Ring quality from how far the ring has closed, 0 (wide) to 1 (closed).
 *
 * Pure so the HUD and the roll cannot disagree about what the player just did.
 */
export function ringQualityAt(progress: number): RingQuality {
  const remaining = 1 - clamp(progress, 0, 1);
  if (remaining <= config.ringGreatWindow) return 'great';
  if (remaining <= config.ringGoodWindow) return 'good';
  return 'none';
}

/** Whether a wild pal bolts this second. Section 7: 20% HP, 25% per second. */
export function shouldFlee(
  currentHp: number,
  maxHp: number,
  dtSeconds: number,
  rand: () => number = Math.random
): boolean {
  if (maxHp <= 0) return false;
  if (currentHp / maxHp > config.fleeHpFraction) return false;
  return rand() < config.fleeChancePerSecond * dtSeconds;
}

function clamp(v: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, v));
}

export const THROW_CONFIG = config;
