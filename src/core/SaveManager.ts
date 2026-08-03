import type { ItemStack } from '../survival/Inventory';
import { MAX_PARTY } from '../party/Party';
import type { PalState, ReleaseRecord } from '../party/PalState';
import type { PlacedPiece } from '../building/SnapGrid';
import type { PlacedStation } from '../survival/Stations';
import type { SatchelContents } from '../survival/Satchel';

/**
 * Save, load, export, import.
 *
 * The schema is `SaveV1` from docs/03_TECHNICAL_ARCHITECTURE.md. Two rules from that document
 * shape the whole file:
 *
 *   "SaveManager.load() validates, clamps party.length to 5, and refuses to
 *    import a save whose schemaVersion it does not have a migration for."
 *
 * and the world-delta rule: a save stores the SEED plus deltas, never the
 * terrain. A save that stored terrain would be enormous, would break on any
 * generation change, and would make the seed meaningless.
 */

export const SCHEMA_VERSION = 1;
export const SAVE_KEY = 'tetherbound.save.v1';
/** One rollback slot, so a bad import is recoverable. */
export const ROLLBACK_KEY = 'tetherbound.save.v1.rollback';

export interface Vec3 {
  x: number;
  y: number;
  z: number;
}

export interface SaveV1 {
  schemaVersion: number;
  seed: string;
  createdAt: number;
  savedAt: number;
  player: {
    pos: Vec3;
    rot: number;
    health: number;
    stamina: number;
    hunger: number;
  };
  inventory: (ItemStack | null)[];
  party: PalState[];
  releasedLedger: ReleaseRecord[];
  structures: PlacedPiece[];
  stations: PlacedStation[];
  /** Where the player wakes. Null until a bed exists. */
  respawn: { x: number; y: number; z: number } | null;
  /** The single faint drop. Null when there is nothing on the ground. */
  satchel: SatchelContents | null;
  worldDeltas: {
    harvested: string[];
    bossesDown: Record<string, number>;
  };
  progress: {
    badges: string[];
    flags: string[];
    day: number;
    timeOfDay: number;
  };
}

export type LoadResult =
  | { ok: true; save: SaveV1 }
  | { ok: false; reason: 'empty' | 'corrupt' | 'unsupported-version' };

/**
 * Migrations keyed by the version they upgrade FROM.
 *
 * Empty at v1, which is correct and not an oversight: there is nothing older
 * to migrate. A save whose version has no entry and is not current is refused
 * rather than guessed at, because silently reinterpreting an unknown schema is
 * how a player loses a party.
 */
const MIGRATIONS: Record<number, ((raw: unknown) => unknown) | undefined> = {};

export class SaveManager {
  constructor(private readonly storage: Storage = localStorage) {}

  save(state: SaveV1): { ok: boolean; reason?: string } {
    try {
      const payload = JSON.stringify({ ...state, savedAt: Date.now() });
      const existing = this.storage.getItem(SAVE_KEY);
      // Keep the previous save before overwriting, so a bad write or a bad
      // import is one step from recoverable.
      if (existing) this.storage.setItem(ROLLBACK_KEY, existing);
      this.storage.setItem(SAVE_KEY, payload);
      return { ok: true };
    } catch (err) {
      // Quota, private mode, disabled storage. Report it honestly rather than
      // letting the player believe their game is saved.
      return { ok: false, reason: err instanceof Error ? err.message : String(err) };
    }
  }

  load(): LoadResult {
    const raw = this.storage.getItem(SAVE_KEY);
    if (!raw) return { ok: false, reason: 'empty' };
    return this.parse(raw);
  }

  /** Export as base64, for moving a game between devices. */
  export(state: SaveV1): string {
    return toBase64(JSON.stringify(state));
  }

  /**
   * Import a pasted string.
   *
   * Validates BEFORE overwriting anything, and keeps the current save in the
   * rollback slot, per docs/03_TECHNICAL_ARCHITECTURE.md.
   */
  import(encoded: string): LoadResult {
    let json: string;
    try {
      json = fromBase64(encoded.trim());
    } catch {
      return { ok: false, reason: 'corrupt' };
    }
    const parsed = this.parse(json);
    if (!parsed.ok) return parsed;

    const existing = this.storage.getItem(SAVE_KEY);
    if (existing) this.storage.setItem(ROLLBACK_KEY, existing);
    this.storage.setItem(SAVE_KEY, JSON.stringify(parsed.save));
    return parsed;
  }

  rollback(): LoadResult {
    const raw = this.storage.getItem(ROLLBACK_KEY);
    if (!raw) return { ok: false, reason: 'empty' };
    const parsed = this.parse(raw);
    if (parsed.ok) this.storage.setItem(SAVE_KEY, raw);
    return parsed;
  }

  clear(): void {
    this.storage.removeItem(SAVE_KEY);
    this.storage.removeItem(ROLLBACK_KEY);
  }

  private parse(raw: string): LoadResult {
    let data: unknown;
    try {
      data = JSON.parse(raw);
    } catch {
      return { ok: false, reason: 'corrupt' };
    }
    return validate(data);
  }
}

/**
 * Validate and normalise an unknown blob into a SaveV1.
 *
 * Exported so tests can hit it without touching storage.
 */
export function validate(data: unknown): LoadResult {
  if (typeof data !== 'object' || data === null) return { ok: false, reason: 'corrupt' };
  const record = data as Record<string, unknown>;

  const version = record['schemaVersion'];
  if (typeof version !== 'number') return { ok: false, reason: 'corrupt' };

  let working: Record<string, unknown> = record;
  if (version !== SCHEMA_VERSION) {
    const migrate = MIGRATIONS[version];
    if (!migrate) return { ok: false, reason: 'unsupported-version' };
    working = migrate(record) as Record<string, unknown>;
  }

  if (typeof working['seed'] !== 'string') return { ok: false, reason: 'corrupt' };

  const party = Array.isArray(working['party']) ? (working['party'] as PalState[]) : [];
  const progress = (working['progress'] ?? {}) as Record<string, unknown>;
  const deltas = (working['worldDeltas'] ?? {}) as Record<string, unknown>;
  const player = (working['player'] ?? {}) as Record<string, unknown>;

  const save: SaveV1 = {
    schemaVersion: SCHEMA_VERSION,
    seed: working['seed'] as string,
    createdAt: numberOr(working['createdAt'], Date.now()),
    savedAt: numberOr(working['savedAt'], Date.now()),
    player: {
      pos: vec3Or(player['pos']),
      rot: numberOr(player['rot'], 0),
      health: numberOr(player['health'], 100),
      stamina: numberOr(player['stamina'], 100),
      hunger: numberOr(player['hunger'], 100)
    },
    inventory: Array.isArray(working['inventory'])
      ? (working['inventory'] as (ItemStack | null)[])
      : [],
    // THE clamp. A save is user-editable and must not be able to smuggle in a
    // sixth pal; Party.fromSave clamps again, and both are deliberate.
    party: party.slice(0, MAX_PARTY),
    releasedLedger: Array.isArray(working['releasedLedger'])
      ? (working['releasedLedger'] as ReleaseRecord[])
      : [],
    structures: Array.isArray(working['structures'])
      ? (working['structures'] as PlacedPiece[])
      : [],
    stations: Array.isArray(working['stations'])
      ? (working['stations'] as PlacedStation[])
      : [],
    respawn:
      typeof working['respawn'] === 'object' && working['respawn'] !== null
        ? vec3Or(working['respawn'])
        : null,
    satchel:
      typeof working['satchel'] === 'object' && working['satchel'] !== null
        ? (working['satchel'] as SatchelContents)
        : null,
    worldDeltas: {
      harvested: Array.isArray(deltas['harvested']) ? (deltas['harvested'] as string[]) : [],
      bossesDown:
        typeof deltas['bossesDown'] === 'object' && deltas['bossesDown'] !== null
          ? (deltas['bossesDown'] as Record<string, number>)
          : {}
    },
    progress: {
      badges: Array.isArray(progress['badges']) ? (progress['badges'] as string[]) : [],
      flags: Array.isArray(progress['flags']) ? (progress['flags'] as string[]) : [],
      day: numberOr(progress['day'], 1),
      timeOfDay: numberOr(progress['timeOfDay'], 0)
    }
  };

  return { ok: true, save };
}

function numberOr(value: unknown, fallback: number): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : fallback;
}

function vec3Or(value: unknown): Vec3 {
  const v = (value ?? {}) as Record<string, unknown>;
  return { x: numberOr(v['x'], 0), y: numberOr(v['y'], 0), z: numberOr(v['z'], 0) };
}

/** Base64 that survives non-ASCII, which btoa alone does not. */
function toBase64(text: string): string {
  const bytes = new TextEncoder().encode(text);
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary);
}

function fromBase64(encoded: string): string {
  const binary = atob(encoded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return new TextDecoder().decode(bytes);
}
