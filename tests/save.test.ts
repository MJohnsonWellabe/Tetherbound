import { beforeEach, describe, expect, it } from 'vitest';
import {
  SAVE_KEY,
  SCHEMA_VERSION,
  SaveManager,
  validate,
  type SaveV1
} from '../src/core/SaveManager';
import { MAX_PARTY, Party } from '../src/party/Party';
import type { PalState } from '../src/party/PalState';

/** Minimal in-memory Storage, so these tests need no DOM. */
class MemoryStorage implements Storage {
  private readonly map = new Map<string, string>();
  get length(): number {
    return this.map.size;
  }
  clear(): void {
    this.map.clear();
  }
  getItem(key: string): string | null {
    return this.map.get(key) ?? null;
  }
  key(index: number): string | null {
    return [...this.map.keys()][index] ?? null;
  }
  removeItem(key: string): void {
    this.map.delete(key);
  }
  setItem(key: string, value: string): void {
    this.map.set(key, value);
  }
}

function pal(uid: string, level = 5): PalState {
  return {
    uid,
    species: 'tuftmoth',
    nickname: null,
    level,
    xp: 12,
    variance: 1.04,
    affinity: 61,
    currentHp: 22,
    fainted: false,
    caughtOnDay: 3,
    caughtAtMs: 1000
  };
}

function makeSave(overrides: Partial<SaveV1> = {}): SaveV1 {
  return {
    schemaVersion: SCHEMA_VERSION,
    seed: 'hollowbrook',
    createdAt: 1,
    savedAt: 2,
    player: { pos: { x: 12.5, y: 6, z: -4 }, rot: 1.2, health: 80, stamina: 55, hunger: 71 },
    inventory: [{ id: 'wood', n: 17 }, null, { id: 'stone_axe', n: 1, dur: 96 }],
    party: [pal('a'), pal('b', 9)],
    releasedLedger: [{ species: 'pebblit', level: 4, day: 2 }],
    structures: [{ pieceId: 'wood_floor', x: 2, y: 6, z: 4, rot: 0, placedAtMs: 500 }],
    worldDeltas: { harvested: ['oak:3,-1', 'rock:0,0'], bossesDown: { loamking: 4 } },
    progress: { badges: ['meadow_sigil'], flags: ['met_orin'], day: 6, timeOfDay: 0.42 },
    ...overrides
  };
}

describe('save round trip', () => {
  let storage: MemoryStorage;
  let manager: SaveManager;

  beforeEach(() => {
    storage = new MemoryStorage();
    manager = new SaveManager(storage);
  });

  it('survives a write and a read without losing anything', () => {
    const original = makeSave();
    expect(manager.save(original).ok).toBe(true);
    const loaded = manager.load();
    expect(loaded.ok).toBe(true);
    if (!loaded.ok) return;

    expect(loaded.save.seed).toBe(original.seed);
    expect(loaded.save.player).toEqual(original.player);
    expect(loaded.save.inventory).toEqual(original.inventory);
    expect(loaded.save.party).toEqual(original.party);
    expect(loaded.save.releasedLedger).toEqual(original.releasedLedger);
    expect(loaded.save.structures).toEqual(original.structures);
    expect(loaded.save.worldDeltas).toEqual(original.worldDeltas);
    expect(loaded.save.progress).toEqual(original.progress);
  });

  it('survives an export and an import', () => {
    const original = makeSave();
    const encoded = manager.export(original);
    const imported = manager.import(encoded);
    expect(imported.ok).toBe(true);
    if (!imported.ok) return;
    expect(imported.save.party).toEqual(original.party);
    expect(imported.save.worldDeltas.harvested).toEqual(original.worldDeltas.harvested);
  });

  it('reports empty rather than pretending on a fresh install', () => {
    const result = manager.load();
    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.reason).toBe('empty');
  });

  it('reports corrupt rather than throwing on garbage', () => {
    storage.setItem(SAVE_KEY, '{not json at all');
    const result = manager.load();
    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.reason).toBe('corrupt');
  });

  it('refuses an import that is not base64', () => {
    const result = manager.import('!!!! not base64 !!!!');
    expect(result.ok).toBe(false);
  });

  it('does not overwrite a good save with a bad import', () => {
    manager.save(makeSave({ seed: 'keepme' }));
    manager.import('garbage');
    const after = manager.load();
    expect(after.ok).toBe(true);
    if (after.ok) expect(after.save.seed).toBe('keepme');
  });

  it('keeps one rollback slot', () => {
    manager.save(makeSave({ seed: 'first' }));
    manager.save(makeSave({ seed: 'second' }));
    const rolled = manager.rollback();
    expect(rolled.ok).toBe(true);
    if (rolled.ok) expect(rolled.save.seed).toBe('first');
  });
});

describe('validation', () => {
  it('refuses a schema version it has no migration for', () => {
    const result = validate({ ...makeSave(), schemaVersion: 99 });
    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.reason).toBe('unsupported-version');
  });

  it('refuses a save with no seed', () => {
    const broken = makeSave() as unknown as Record<string, unknown>;
    delete broken['seed'];
    expect(validate(broken).ok).toBe(false);
  });

  it('clamps an over-long party to five', () => {
    const many = Array.from({ length: 11 }, (_, i) => pal(`p${i}`));
    const result = validate(makeSave({ party: many }));
    expect(result.ok).toBe(true);
    if (result.ok) expect(result.save.party).toHaveLength(MAX_PARTY);
  });

  it('cannot smuggle a sixth pal past Party.fromSave either', () => {
    // Belt and braces, deliberately. The clamp exists in both places because
    // a save is user-editable and this is the constraint the whole game rests on.
    const many = Array.from({ length: 11 }, (_, i) => pal(`p${i}`));
    const result = validate(makeSave({ party: many }));
    if (!result.ok) throw new Error('expected a valid save');
    const party = Party.fromSave(result.save.party, result.save.releasedLedger);
    expect(party.size).toBe(MAX_PARTY);
  });

  it('fills in sensible defaults for missing optional sections', () => {
    const bare = { schemaVersion: SCHEMA_VERSION, seed: 'x' };
    const result = validate(bare);
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.save.party).toEqual([]);
    expect(result.save.worldDeltas.harvested).toEqual([]);
    expect(result.save.progress.day).toBe(1);
    expect(result.save.player.health).toBe(100);
  });

  it('does not treat NaN as a valid number', () => {
    const result = validate(makeSave({ progress: { badges: [], flags: [], day: NaN, timeOfDay: 0 } }));
    expect(result.ok).toBe(true);
    if (result.ok) expect(result.save.progress.day).toBe(1);
  });
});
