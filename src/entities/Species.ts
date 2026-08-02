import { statAt, type PalType } from '../combat/Damage';
import moves from '../data/moves.json';
import species from '../data/species.json';
import progression from '../data/progression.json';
import type { PalState } from '../party/PalState';

/**
 * Species lookup and derived stats.
 *
 * The one place that turns "a tuftmoth at level 6 with variance 1.04" into
 * numbers. Nothing else may read species.json directly, so a change to the
 * roster's shape lands here and nowhere else.
 */

export interface MoveDef {
  name: string;
  type: PalType;
  kind: 'quick' | 'power';
  power: number;
}

export interface SpeciesDef {
  name: string;
  type: PalType;
  role: 'starter' | 'wild' | 'boss';
  rarity?: string;
  levelBand?: [number, number];
  base: { hp: number; atk: number; def: number; spd: number };
  catchRate: number;
  /** Milliseconds between this species' attacks. Floored by moves.json. */
  attackCadenceMs?: number;
  moves: [string, string];
  model: { body: string; tint: string; scale: number; accessory: string };
  timeWindows?: string[];
  biomes?: string[];
  herd?: number;
  flees?: boolean;
  counters?: boolean;
  burrows?: boolean;
  aggroRange?: number;
}

const SPECIES = species.species as unknown as Record<string, SpeciesDef | undefined>;
const MOVES = moves.moves as unknown as Record<string, MoveDef | undefined>;

export function speciesDef(id: string): SpeciesDef | undefined {
  return SPECIES[id];
}

export function allSpeciesIds(): string[] {
  return Object.keys(SPECIES);
}

export function moveDef(id: string): MoveDef | undefined {
  return MOVES[id];
}

/**
 * The two moves a species knows, both available from level 1.
 *
 * GAME_DESIGN.md section 5 gated the power move behind level 8. That made the
 * power button a dead press for most of a first fight: `MoveResolver` saw no
 * move and returned zero damage with no number, no FX and no log line,
 * indistinguishable from broken input. The charge bar is the gate now
 * (`TIMING.powerChargeCost` in MoveResolver.ts): a species always KNOWS its
 * power move, whether the player has earned the charge to use it is a
 * separate, honest question CombatMode answers on every press.
 */
export function movesFor(pal: PalState): { quick: MoveDef | undefined; power: MoveDef | undefined } {
  const def = speciesDef(pal.species);
  if (!def) return { quick: undefined, power: undefined };
  return { quick: moveDef(def.moves[0]), power: moveDef(def.moves[1]) };
}

export interface DerivedStats {
  maxHp: number;
  atk: number;
  def: number;
  spd: number;
  type: PalType;
}

/** Species base block plus level plus the locked variance roll. */
export function derive(pal: PalState): DerivedStats {
  const def = speciesDef(pal.species);
  if (!def) return { maxHp: 1, atk: 1, def: 1, spd: 1, type: 'verdant' };
  return {
    maxHp: statAt(def.base.hp, pal.level, pal.variance),
    atk: statAt(def.base.atk, pal.level, pal.variance),
    def: statAt(def.base.def, pal.level, pal.variance),
    spd: statAt(def.base.spd, pal.level, pal.variance),
    type: def.type
  };
}

/**
 * Build a fresh individual.
 *
 * `variance` is rolled once here and never again; GAME_DESIGN.md section 5 is
 * explicit that it is locked for life, which is also why it is stored in the
 * save rather than recomputed.
 */
export function createPal(
  speciesId: string,
  level: number,
  day: number,
  nowMs: number,
  rand: () => number,
  uid: string
): PalState {
  const variance =
    progression.varianceMin + rand() * (progression.varianceMax - progression.varianceMin);
  const pal: PalState = {
    uid,
    species: speciesId,
    nickname: null,
    level,
    xp: 0,
    variance,
    affinity: progression.affinityStart,
    currentHp: 1,
    fainted: false,
    caughtOnDay: day,
    caughtAtMs: nowMs
  };
  pal.currentHp = derive(pal).maxHp;
  return pal;
}
