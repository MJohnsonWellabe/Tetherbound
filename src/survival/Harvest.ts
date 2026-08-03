import config from '../data/harvest.json';
import { itemDef } from './Inventory';
import { hashSeed, mulberry32, rangeInt } from '../world/gen/Rng';

/**
 * Harvest rules: what a node drops, what tool opens it, and what a tool is
 * allowed to be pointed at.
 *
 * Pure. No renderer, no inventory mutation, no globals, so the rules are
 * testable headless and the systems that apply them stay boring.
 *
 * Every number lives in harvest.json. Nodes are keyed by prop family and
 * matched by tool ACTION rather than tool id, so a bronze axe later is a data
 * change.
 */

export interface DropSpec {
  id: string;
  min: number;
  max: number;
}

export interface NodeDef {
  action: string;
  swings: number;
  drops: DropSpec[];
}

export interface Drop {
  id: string;
  n: number;
}

const NODES = config.nodes as Record<string, NodeDef | undefined>;

export const REACH_METERS = config.reachMeters;
export const RESPAWN_DAYS = config.respawnDays;

/**
 * What a tool may be pointed at.
 *
 * `node` is scenery. Everything else is alive, and the answer for everything
 * alive is no.
 */
export type TargetKind = 'node' | 'pal' | 'npc' | 'player';

export function nodeDef(family: string): NodeDef | undefined {
  return NODES[family];
}

export function isHarvestable(family: string): boolean {
  return nodeDef(family) !== undefined;
}

/**
 * CLAUDE.md hard constraint 2, docs/01_GAME_DESIGN.md pillar 2: the player never wields
 * a weapon, and tools "cannot target pals or people".
 *
 * Written as an explicit allowlist rather than left implicit in the absence of
 * combat code. A rule enforced only by nobody having written the opposite yet
 * is not enforced, and this is the constraint most likely to be broken by
 * accident once pals are in the world and a swing has something to collide
 * with. Unknown tools and unknown target kinds are both refused, so adding a
 * new entity type cannot quietly make it hittable.
 */
export function canTarget(toolId: string | null, kind: TargetKind): boolean {
  if (kind !== 'node') return false;
  if (!toolId) return false;
  return itemDef(toolId)?.tool !== undefined;
}

/** True when this tool's action opens this node. */
export function harvestableBy(family: string, toolId: string | null): boolean {
  const def = nodeDef(family);
  if (!def || !toolId) return false;
  if (!canTarget(toolId, 'node')) return false;
  return itemDef(toolId)?.tool?.action === def.action;
}

/** Swings needed to fell the node. 0 when it is not harvestable at all. */
export function swingsFor(family: string): number {
  return nodeDef(family)?.swings ?? 0;
}

/**
 * What this specific node gives up, this specific day.
 *
 * Seeded by node key and day rather than rolled from `Math.random()`, so a
 * reload does not reroll the tree the player just chopped, and so the same
 * bush gives something different after it regrows. Same rule as world
 * generation: determinism is what makes a bug report reproducible.
 */
export function rollDrops(family: string, nodeKey: string, day: number): Drop[] {
  const def = nodeDef(family);
  if (!def) return [];

  const rng = mulberry32(hashSeed(`harvest:${nodeKey}`, day));
  const out: Drop[] = [];
  for (const spec of def.drops) {
    const n = rangeInt(rng, spec.min, spec.max);
    // A drop that rolled zero is absent, not an empty stack.
    if (n > 0) out.push({ id: spec.id, n });
  }
  return out;
}

/**
 * Whether a harvested node has regrown.
 *
 * Kept here rather than in the batcher so the respawn rule is one line in one
 * place when M1's save code starts writing `worldDeltas.harvested`.
 */
export function hasRespawned(harvestedOnDay: number, currentDay: number): boolean {
  return currentDay - harvestedOnDay >= RESPAWN_DAYS;
}
