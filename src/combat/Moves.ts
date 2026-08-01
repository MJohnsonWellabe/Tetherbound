import moves from '../data/moves.json';
import { isPalType, type PalType } from './Damage';

/** Typed access to moves.json. Same rule as Species.ts: a lens, never a source. */

export interface MoveDef {
  id: string;
  name: string;
  type: PalType;
  kind: 'quick' | 'power';
  power: number;
  castMs: number;
  /** Quick attacks only: charge added to the power meter. */
  charge: number;
  /** Power attacks only: the visible tell before the hit, and the dodge window. */
  windupMs: number;
}

interface RawMove {
  name: string;
  type: string;
  kind: string;
  power: number;
  castMs: number;
  charge?: number;
  windupMs?: number;
}

const RAW = moves as unknown as Record<string, RawMove>;
const CACHE = new Map<string, MoveDef>();

export function moveDef(id: string): MoveDef | undefined {
  const cached = CACHE.get(id);
  if (cached) return cached;
  if (id.startsWith('$')) return undefined;
  const raw = RAW[id];
  if (!raw) return undefined;

  const def: MoveDef = {
    id,
    name: raw.name,
    type: isPalType(raw.type) ? raw.type : 'verdant',
    kind: raw.kind === 'power' ? 'power' : 'quick',
    power: raw.power,
    castMs: raw.castMs,
    charge: raw.charge ?? 0,
    windupMs: raw.windupMs ?? 0
  };
  CACHE.set(id, def);
  return def;
}

export function requireMove(id: string): MoveDef {
  const def = moveDef(id);
  if (!def) throw new Error(`Unknown move "${id}"`);
  return def;
}
