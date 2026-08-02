import { beforeEach, describe, expect, it } from 'vitest';
import { bus } from '../src/core/EventBus';
import { SAVE_KEY, SCHEMA_VERSION, SaveManager, type SaveV1 } from '../src/core/SaveManager';
import { SaveWiring } from '../src/game/SaveWiring';

/** Minimal in-memory Storage, so this needs no DOM. Mirrors tests/save.test.ts. */
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

function makeSave(): SaveV1 {
  return {
    schemaVersion: SCHEMA_VERSION,
    seed: 'hollowbrook',
    createdAt: 1,
    savedAt: 2,
    player: { pos: { x: 0, y: 0, z: 0 }, rot: 0, health: 100, stamina: 100, hunger: 100 },
    inventory: [],
    party: [],
    releasedLedger: [],
    structures: [],
    stations: [],
    respawn: null,
    satchel: null,
    worldDeltas: { harvested: [], bossesDown: {} },
    progress: { badges: [], flags: [], day: 1, timeOfDay: 0 }
  };
}

describe('SaveWiring', () => {
  let storage: MemoryStorage;
  let manager: SaveManager;
  let wiring: SaveWiring;

  beforeEach(() => {
    storage = new MemoryStorage();
    manager = new SaveManager(storage);
    wiring = new SaveWiring(manager, makeSave);
  });

  it('saves normally before a wipe', () => {
    const result = wiring.flush();
    expect(result?.ok).toBe(true);
    expect(storage.getItem(SAVE_KEY)).not.toBeNull();
    expect(wiring.isWiped).toBe(false);
  });

  it('startOver clears storage and latches wiped on', () => {
    wiring.flush();
    wiring.startOver();
    expect(storage.getItem(SAVE_KEY)).toBeNull();
    expect(wiring.isWiped).toBe(true);
  });

  /**
   * The whole reason this class exists: Start Over reloads the page, and
   * `visibilitychange` fires during that reload. Without the guard, a flush
   * landing in that gap would write the in-memory state straight back over
   * the wipe and Start Over would silently do nothing.
   */
  it('flush is permanently inert once the run is wiped', () => {
    wiring.flush();
    wiring.startOver();

    const result = wiring.flush();

    expect(result).toBeNull();
    expect(storage.getItem(SAVE_KEY)).toBeNull();
  });

  it('covers both the autosave timer and the visibilitychange call site, since both only ever call flush()', () => {
    wiring.startOver();

    // Simulate the 60s timer and a tab-hide firing back to back after a wipe.
    wiring.flush();
    wiring.flush();

    expect(storage.getItem(SAVE_KEY)).toBeNull();
  });

  it('does not emit saveStatus once wiped', () => {
    wiring.startOver();
    const seen: string[] = [];
    const off = bus.on('saveStatus', (e) => seen.push(e.status));
    wiring.flush();
    off();
    expect(seen).toEqual([]);
  });
});
