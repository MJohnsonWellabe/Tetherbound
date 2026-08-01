import species from '../data/species.json';
import { isPalType, type PalType } from '../combat/Damage';

/**
 * Typed access to species.json.
 *
 * The JSON is the source of truth and this file is only a lens onto it. No
 * stat, rate or level band may be restated here (CLAUDE.md rule 5), which is
 * why every field below is read rather than defaulted to a number.
 */

export interface SpeciesLook {
  body: string;
  tint: string;
  scale: number;
  accessory: string;
}

export interface SpeciesDef {
  id: string;
  name: string;
  type: PalType;
  role: 'starter' | 'wild' | 'boss';
  rarity?: string;
  /** Inclusive level band for wild spawns. Starters have none. */
  levels?: readonly [number, number];
  base: { hp: number; atk: number; def: number; spd: number };
  catchRate: number;
  moves: { quick: string; power: string };
  look: SpeciesLook;
  blurb: string;
  /** Flees sooner than the usual threshold. */
  skittish?: boolean;
  /** Spawns as a group of this size. */
  herd?: number;
  /** Chance to counterattack when hit by a quick attack. */
  riposte?: number;
  burrows?: boolean;
  /** Starts a fight itself from the longer aggro range. */
  aggressive?: boolean;
}

interface RawSpecies {
  name: string;
  type: string;
  role: string;
  rarity?: string;
  levels?: number[];
  base: { hp: number; atk: number; def: number; spd: number };
  catchRate: number;
  moves: { quick: string; power: string };
  look: SpeciesLook;
  blurb: string;
  skittish?: boolean;
  herd?: number;
  riposte?: number;
  burrows?: boolean;
  aggressive?: boolean;
}

const RAW = species as unknown as Record<string, RawSpecies>;

const CACHE = new Map<string, SpeciesDef>();

function build(id: string, raw: RawSpecies): SpeciesDef {
  const band = raw.levels;
  return {
    id,
    name: raw.name,
    // Bad type data makes a pal neutral rather than crashing a fight.
    type: isPalType(raw.type) ? raw.type : 'verdant',
    role: raw.role === 'starter' || raw.role === 'boss' ? raw.role : 'wild',
    base: raw.base,
    catchRate: raw.catchRate,
    moves: raw.moves,
    look: raw.look,
    blurb: raw.blurb,
    ...(raw.rarity === undefined ? {} : { rarity: raw.rarity }),
    ...(band && band.length >= 2 && band[0] !== undefined && band[1] !== undefined
      ? { levels: [band[0], band[1]] as readonly [number, number] }
      : {}),
    ...(raw.skittish === undefined ? {} : { skittish: raw.skittish }),
    ...(raw.herd === undefined ? {} : { herd: raw.herd }),
    ...(raw.riposte === undefined ? {} : { riposte: raw.riposte }),
    ...(raw.burrows === undefined ? {} : { burrows: raw.burrows }),
    ...(raw.aggressive === undefined ? {} : { aggressive: raw.aggressive })
  };
}

export function speciesIds(): string[] {
  return Object.keys(RAW).filter((k) => !k.startsWith('$'));
}

export function speciesDef(id: string): SpeciesDef | undefined {
  const cached = CACHE.get(id);
  if (cached) return cached;
  if (id.startsWith('$')) return undefined;
  const raw = RAW[id];
  if (!raw) return undefined;
  const def = build(id, raw);
  CACHE.set(id, def);
  return def;
}

/** Throwing accessor for code paths where a missing species is a data bug. */
export function requireSpecies(id: string): SpeciesDef {
  const def = speciesDef(id);
  if (!def) throw new Error(`Unknown species "${id}"`);
  return def;
}

export function starters(): SpeciesDef[] {
  return speciesIds()
    .map((id) => requireSpecies(id))
    .filter((s) => s.role === 'starter');
}
