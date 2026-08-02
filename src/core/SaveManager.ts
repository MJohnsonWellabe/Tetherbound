import combat from '../data/combat.json';
import type { ItemStack } from '../survival/Inventory';
import type { PalState } from '../party/Pal';
import type { ReleaseRecord } from '../party/Party';
import type { ActiveBuff } from '../survival/Vitals';

/**
 * localStorage save, plus the base64 export string.
 *
 * The schema is ARCHITECTURE.md's SaveV1. Two rules govern everything here.
 *
 * A save file is user-editable, so `load` validates rather than trusts. The
 * party is clamped to five on the way in: hand-editing a sixth pal into a JSON
 * blob must not be a way around the rule the whole game rests on.
 *
 * A load that cannot be understood returns null rather than throwing. Losing a
 * save is bad; a save that stops the game booting at all is worse, because it
 * leaves no way to start a new one.
 */

const KEY = 'tetherbound.save.v1';
const ROLLBACK_KEY = 'tetherbound.save.rollback';
const SCHEMA_VERSION = 1;

export interface SaveV1 {
  schemaVersion: number;
  seed: string;
  createdAt: number;
  savedAt: number;
  player: {
    pos: { x: number; y: number; z: number };
    rot: number;
    health: number;
    stamina: number;
    hunger: number;
    buffs: ActiveBuff[];
    playMs: number;
  };
  inventory: (ItemStack | null)[];
  party: PalState[];
  releasedLedger: ReleaseRecord[];
  structures: { pieceId: string; pos: { x: number; y: number; z: number }; rot: number; tier: number }[];
  worldDeltas: { harvested: Record<string, number>; bossesDown: Record<string, number> };
  progress: {
    badges: string[];
    flags: string[];
    day: number;
    timeOfDay: number;
    /** Where the player wakes after a faint, if a bed is set. */
    respawn: { x: number; y: number; z: number } | null;
    satchel: { pos: { x: number; y: number; z: number }; items: ItemStack[] } | null;
  };
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}

function num(value: unknown, fallback: number): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : fallback;
}

function strArray(value: unknown): string[] {
  return Array.isArray(value) ? value.filter((v): v is string => typeof v === 'string') : [];
}

/**
 * Coerce an unknown blob into a save, or return null.
 *
 * Deliberately forgiving about missing fields and strict about dangerous ones.
 * A save from an older build missing `satchel` should still load; a save
 * claiming nine party members should not load nine.
 */
export function validate(raw: unknown): SaveV1 | null {
  if (!isObject(raw)) return null;
  if (num(raw.schemaVersion, 0) !== SCHEMA_VERSION) {
    console.warn(`[save] no migration for schemaVersion ${String(raw.schemaVersion)}`);
    return null;
  }
  if (typeof raw.seed !== 'string' || raw.seed.length === 0) return null;

  const player = isObject(raw.player) ? raw.player : {};
  const pos = isObject(player.pos) ? player.pos : {};
  const progress = isObject(raw.progress) ? raw.progress : {};
  const deltas = isObject(raw.worldDeltas) ? raw.worldDeltas : {};

  const party = Array.isArray(raw.party)
    ? (raw.party.filter(isObject) as unknown as PalState[]).slice(0, combat.party.cap)
    : [];

  const respawn = isObject(progress.respawn)
    ? {
        x: num(progress.respawn.x, 0),
        y: num(progress.respawn.y, 0),
        z: num(progress.respawn.z, 0)
      }
    : null;

  const satchelRaw = isObject(progress.satchel) ? progress.satchel : null;
  const satchelPos = satchelRaw && isObject(satchelRaw.pos) ? satchelRaw.pos : null;

  return {
    schemaVersion: SCHEMA_VERSION,
    seed: raw.seed,
    createdAt: num(raw.createdAt, Date.now()),
    savedAt: num(raw.savedAt, Date.now()),
    player: {
      pos: { x: num(pos.x, 0), y: num(pos.y, 0), z: num(pos.z, 0) },
      rot: num(player.rot, 0),
      health: num(player.health, 100),
      stamina: num(player.stamina, 100),
      hunger: num(player.hunger, 100),
      buffs: Array.isArray(player.buffs) ? (player.buffs as ActiveBuff[]) : [],
      playMs: num(player.playMs, 0)
    },
    inventory: Array.isArray(raw.inventory) ? (raw.inventory as (ItemStack | null)[]) : [],
    party,
    releasedLedger: Array.isArray(raw.releasedLedger)
      ? (raw.releasedLedger as ReleaseRecord[])
      : [],
    structures: Array.isArray(raw.structures) ? (raw.structures as SaveV1['structures']) : [],
    worldDeltas: {
      harvested: isObject(deltas.harvested) ? (deltas.harvested as Record<string, number>) : {},
      bossesDown: isObject(deltas.bossesDown) ? (deltas.bossesDown as Record<string, number>) : {}
    },
    progress: {
      badges: strArray(progress.badges),
      flags: strArray(progress.flags),
      day: Math.max(1, Math.floor(num(progress.day, 1))),
      timeOfDay: num(progress.timeOfDay, 0.2),
      respawn,
      satchel:
        satchelRaw && satchelPos
          ? {
              pos: {
                x: num(satchelPos.x, 0),
                y: num(satchelPos.y, 0),
                z: num(satchelPos.z, 0)
              },
              items: Array.isArray(satchelRaw.items) ? (satchelRaw.items as ItemStack[]) : []
            }
          : null
    }
  };
}

export class SaveManager {
  /** Write. Returns false rather than throwing when storage is unavailable. */
  save(state: SaveV1): boolean {
    try {
      const previous = window.localStorage.getItem(KEY);
      // One rollback slot, per the design. Kept before the write so a corrupt
      // write does not take the previous save down with it.
      if (previous) window.localStorage.setItem(ROLLBACK_KEY, previous);
      window.localStorage.setItem(KEY, JSON.stringify({ ...state, savedAt: Date.now() }));
      return true;
    } catch (err) {
      // Private browsing and a full quota both land here. The game keeps
      // running; it just cannot persist.
      console.error('[save] write failed', err);
      return false;
    }
  }

  load(): SaveV1 | null {
    return this.read(KEY);
  }

  loadRollback(): SaveV1 | null {
    return this.read(ROLLBACK_KEY);
  }

  private read(key: string): SaveV1 | null {
    try {
      const text = window.localStorage.getItem(key);
      if (!text) return null;
      return validate(JSON.parse(text));
    } catch (err) {
      console.error(`[save] "${key}" could not be read`, err);
      return null;
    }
  }

  exists(): boolean {
    try {
      return window.localStorage.getItem(KEY) !== null;
    } catch {
      return false;
    }
  }

  clear(): void {
    try {
      window.localStorage.removeItem(KEY);
    } catch {
      // Nothing useful to do; the caller is starting a new game either way.
    }
  }
}

/**
 * Export to a paste-able string.
 *
 * `encodeURIComponent` before btoa, because btoa throws on any character above
 * U+00FF and a pal nickname is free text.
 */
export function exportSave(state: SaveV1): string {
  return btoa(encodeURIComponent(JSON.stringify(state)));
}

export function importSave(text: string): SaveV1 | null {
  try {
    return validate(JSON.parse(decodeURIComponent(atob(text.trim()))));
  } catch (err) {
    console.error('[save] import failed', err);
    return null;
  }
}

export const SAVE_KEY = KEY;
