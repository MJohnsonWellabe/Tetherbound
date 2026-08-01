import combat from '../data/combat.json';
import { statAt, type PalType } from '../combat/Damage';
import { requireSpecies } from './Species';

/**
 * A single pal instance. Plain data, no engine handles: the mesh that draws it
 * lives in entities/ and looks this up by uid, so a pal can be saved, loaded,
 * benched and revived without anything graphical existing.
 */

export interface PalState {
  uid: string;
  species: string;
  name: string;
  type: PalType;
  level: number;
  xp: number;
  /** Rolled once at spawn, locked for life. This is what makes it yours. */
  variance: number;
  maxHp: number;
  hp: number;
  atk: number;
  def: number;
  spd: number;
  affinity: number;
  /** Power-attack meter, 0..100. Resets between fights. */
  charge: number;
  /** Tether's collar. Hits harder, never dodges, cannot be caught. */
  collared: boolean;
  /** In-game day this pal joined, for the release screen's "time with you". */
  caughtDay: number;
  /** Remaining revive time in ms. Zero when conscious. */
  reviveMs: number;
}

/**
 * Monotonic uid counter.
 *
 * Not Math.random: CLAUDE.md forbids it in world generation and a pal caught
 * from a seeded spawn is world generation's output. A counter also makes save
 * diffs readable, which matters more than uid unpredictability ever will here.
 */
let nextUid = 1;

export function resetUidCounter(to = 1): void {
  nextUid = to;
}

export function rollVariance(random: () => number): number {
  return (
    combat.stats.varianceMin + random() * (combat.stats.varianceMax - combat.stats.varianceMin)
  );
}

/** Recompute every derived stat from species, level and variance. */
export function recomputeStats(pal: PalState): void {
  const def = requireSpecies(pal.species);
  pal.maxHp = Math.max(1, statAt(def.base.hp, pal.level, pal.variance));
  pal.atk = Math.max(1, statAt(def.base.atk, pal.level, pal.variance));
  pal.def = Math.max(1, statAt(def.base.def, pal.level, pal.variance));
  pal.spd = Math.max(1, statAt(def.base.spd, pal.level, pal.variance));
}

export interface MakePalOptions {
  collared?: boolean;
  caughtDay?: number;
  affinity?: number;
}

/**
 * Build a pal. `random` is injected so spawns stay seeded and tests stay exact.
 */
export function makePal(
  speciesId: string,
  level: number,
  random: () => number,
  options: MakePalOptions = {}
): PalState {
  const def = requireSpecies(speciesId);
  const clampedLevel = Math.max(1, Math.min(combat.xp.maxLevel, Math.round(level)));

  const pal: PalState = {
    uid: `${speciesId}-${nextUid++}`,
    species: speciesId,
    name: def.name,
    type: def.type,
    level: clampedLevel,
    xp: 0,
    variance: rollVariance(random),
    maxHp: 1,
    hp: 1,
    atk: 1,
    def: 1,
    spd: 1,
    // A collared pal starts lower: the collar is why Tether's pals fight at
    // reduced affinity, and that penalty is the mechanical shape of the story.
    affinity: Math.max(
      0,
      (options.affinity ?? combat.affinity.start) -
        (options.collared ? combat.affinity.collaredPenalty : 0)
    ),
    charge: 0,
    collared: options.collared ?? false,
    caughtDay: options.caughtDay ?? 0,
    reviveMs: 0
  };

  recomputeStats(pal);
  pal.hp = pal.maxHp;
  return pal;
}

export function isFainted(pal: PalState): boolean {
  return pal.hp <= 0;
}

/** A pal cannot be caught if Tether has it on a collar. Section 10's rule. */
export function isCatchable(pal: PalState): boolean {
  return !pal.collared;
}
