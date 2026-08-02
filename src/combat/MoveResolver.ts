import moves from '../data/moves.json';
import { damage, typeMultiplier, type PalType } from './Damage';
import { hesitates } from '../party/Progression';
import { derive, movesFor } from '../entities/Species';
import type { PalState } from '../party/PalState';

/**
 * Resolves one attack between two pals.
 *
 * Sits between the pure formula in Damage.ts and the stateful CombatMode: it
 * knows about charge, telegraphs and hesitation, but still returns a result
 * rather than mutating a scene.
 */

export const TIMING = {
  quickCastMs: moves.quickCastMs,
  powerWindupMs: moves.powerWindupMs,
  telegraphMs: moves.telegraphMs,
  dodgeWindowMs: moves.dodgeWindowMs,
  swapVulnerabilityMs: moves.swapVulnerabilityMs,
  openingGraceMs: moves.openingGraceMs,
  minAttackIntervalMs: moves.minAttackIntervalMs,
  quickChargeGain: moves.quickChargeGain,
  powerChargeCost: moves.powerChargeCost,
  collarDamageMultiplier: moves.collarDamageMultiplier
} as const;

export interface AttackResult {
  damage: number;
  typeAdvantage: boolean;
  /** The pal refused to commit. Low affinity, power attacks only. */
  hesitated: boolean;
  /** The defender dodged in the telegraph window and took nothing. */
  dodged: boolean;
  moveName: string;
}

export interface AttackOptions {
  kind: 'quick' | 'power';
  /** True when the defender committed a correctly timed dodge. */
  defenderDodged: boolean;
  rand?: () => number;
}

/**
 * Resolve an attack.
 *
 * A correctly timed dodge negates a power attack ENTIRELY (GAME_DESIGN.md
 * section 7), not partially. Partial mitigation would make the dodge feel like
 * a stat rather than a skill, and the telegraph exists precisely so the player
 * can earn the whole thing.
 */
export function resolveAttack(
  attacker: PalState,
  defender: PalState,
  options: AttackOptions
): AttackResult {
  const rand = options.rand ?? Math.random;
  const set = movesFor(attacker);
  const move = options.kind === 'power' ? set.power : set.quick;
  if (!move) {
    return { damage: 0, typeAdvantage: false, hesitated: false, dodged: false, moveName: '' };
  }

  // A collared pal never hesitates. Hesitation is what a neglected pal does
  // when it could refuse; a collar removes the choice, which is the whole
  // point of the mechanic and why Tether uses them.
  if (options.kind === 'power' && !attacker.collared && hesitates(attacker.affinity, rand)) {
    return { damage: 0, typeAdvantage: false, hesitated: true, dodged: false, moveName: move.name };
  }

  const a = derive(attacker);
  const d = derive(defender);
  const advantage = typeMultiplier(move.type as PalType, d.type) > 1;

  if (options.defenderDodged) {
    return { damage: 0, typeAdvantage: advantage, hesitated: false, dodged: true, moveName: move.name };
  }

  const dealt = damage(
    { atk: a.atk, level: attacker.level, type: move.type as PalType, affinity: attacker.affinity },
    { def: d.def, level: defender.level, type: d.type },
    move.power,
    rand
  );

  // The collar's half of the trade: harder hits, bought with the pal's will.
  const collared = attacker.collared ? dealt * TIMING.collarDamageMultiplier : dealt;

  return {
    damage: collared,
    typeAdvantage: advantage,
    hesitated: false,
    dodged: false,
    moveName: move.name
  };
}

/** Apply damage and report whether it dropped the pal. */
export function applyDamage(pal: PalState, amount: number): boolean {
  pal.currentHp = Math.max(0, pal.currentHp - amount);
  if (pal.currentHp === 0) {
    pal.fainted = true;
    return true;
  }
  return false;
}

/** Charge earned by landing a quick attack, capped at the power cost. */
export function chargeAfterQuick(charge: number): number {
  return Math.min(TIMING.powerChargeCost, charge + TIMING.quickChargeGain);
}
