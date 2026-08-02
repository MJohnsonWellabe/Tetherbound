import moves from '../data/moves.json';
import orbs from '../data/orbs.json';

/**
 * Which combat buttons glow.
 *
 * Owner's ROG Ally playtest: the buttons should light up as the fight makes
 * one choice increasingly correct, so a first-time player has a read even
 * before they know the rules. This is that read: a pure function of the
 * fight state, with no side effects and no notion of what is legal.
 *
 * Legality is CombatMode's job, not this file's. The throw is always legal
 * from the first frame of a fight (CLAUDE.md hard constraint 3) whatever
 * this returns, and every action stays pressable whatever this returns: the
 * return type below has no "disabled" or "available" field for exactly that
 * reason, so nothing downstream can be tempted to gate on it.
 */

export interface FightRead {
  /** The active pal's current HP over max, 0..1. */
  allyHpFraction: number;
  /** The enemy's current HP over max, 0..1. */
  enemyHpFraction: number;
  /** True once the charge bar actually covers a power attack's cost. */
  chargeAvailable: boolean;
  /** Orbs of any kind currently held. */
  orbsHeld: number;
  /** False only for a collared, scripted duel (CombatMode.leave()). */
  canFlee: boolean;
}

export interface Suggested {
  quick: boolean;
  power: boolean;
  orb: boolean;
  run: boolean;
}

/** Enemy HP fraction at or below which a throw is a realistic catch attempt. */
const ORB_HP_FRACTION = orbs.suggestCatchHpFraction;
/** Ally HP fraction at or below which retreat is the suggested read. */
const RUN_HP_FRACTION = moves.suggestRunHpFraction;

export function suggestActions(read: FightRead): Suggested {
  const power = read.chargeAvailable;
  return {
    // Quick is the default early read: whatever the charge bar has not yet
    // earned a power attack, quick is the button to reach for.
    quick: !power,
    power,
    orb: read.orbsHeld > 0 && read.enemyHpFraction <= ORB_HP_FRACTION,
    run: read.canFlee && read.allyHpFraction <= RUN_HP_FRACTION
  };
}
