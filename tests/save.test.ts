import { describe, expect, it } from 'vitest';
import combat from '../src/data/combat.json';
import { exportSave, importSave, validate, type SaveV1 } from '../src/core/SaveManager';
import { makePal } from '../src/party/Pal';

/**
 * ARCHITECTURE.md: "SaveManager.load() validates, clamps party.length to 5, and
 * refuses to import a save whose schemaVersion it does not have a migration
 * for." A save file is user-editable, so the clamp is a rule, not a tidy-up.
 */

function baseSave(): SaveV1 {
  return {
    schemaVersion: 1,
    seed: 'hollowbrook',
    createdAt: 1,
    savedAt: 2,
    player: {
      pos: { x: 1, y: 2, z: 3 },
      rot: 0.5,
      health: 80,
      stamina: 60,
      hunger: 40,
      buffs: [],
      playMs: 1234
    },
    inventory: [{ id: 'wood', n: 12 }, null],
    party: [makePal('tuftmoth', 4, () => 0.5)],
    releasedLedger: [],
    structures: [],
    worldDeltas: { harvested: {}, bossesDown: {} },
    progress: {
      badges: [],
      flags: ['met_orin'],
      day: 3,
      timeOfDay: 0.4,
      respawn: null,
      satchel: null
    }
  };
}

describe('validation', () => {
  it('round-trips a save through export and import without loss', () => {
    const original = baseSave();
    const restored = importSave(exportSave(original));
    expect(restored).toEqual(original);
  });

  it('survives a nickname outside Latin-1, which raw btoa cannot', () => {
    const save = baseSave();
    save.party[0]!.name = 'Tuftmoth ✦ 苔';
    const restored = importSave(exportSave(save));
    expect(restored?.party[0]?.name).toBe('Tuftmoth ✦ 苔');
  });

  it('clamps a hand-edited party of nine down to five', () => {
    const save = baseSave();
    save.party = Array.from({ length: 9 }, () => makePal('tuftmoth', 2, () => 0.5));
    const restored = validate(save);
    expect(restored?.party).toHaveLength(combat.party.cap);
  });

  it('refuses a schema version it has no migration for', () => {
    const save = { ...baseSave(), schemaVersion: 99 };
    expect(validate(save)).toBeNull();
  });

  it('refuses a blob that is not a save at all', () => {
    expect(validate(null)).toBeNull();
    expect(validate('nope')).toBeNull();
    expect(validate({})).toBeNull();
    expect(validate({ schemaVersion: 1 })).toBeNull();
  });

  it('refuses garbage passed to import instead of throwing', () => {
    expect(importSave('not base64 at all !!')).toBeNull();
    expect(importSave('')).toBeNull();
  });

  it('fills in fields an older build did not write', () => {
    const save = baseSave() as unknown as Record<string, unknown>;
    delete save.structures;
    delete save.worldDeltas;
    const restored = validate(save);
    expect(restored?.structures).toEqual([]);
    expect(restored?.worldDeltas).toEqual({ harvested: {}, bossesDown: {} });
  });

  it('keeps progress flags, which is what gates the Truestone Orb', () => {
    const save = baseSave();
    save.progress.flags = ['met_orin', 'badge_meadow'];
    expect(validate(save)?.progress.flags).toContain('badge_meadow');
  });

  it('never lets a corrupt day roll the clock backwards past day one', () => {
    const save = baseSave();
    save.progress.day = -40;
    expect(validate(save)?.progress.day).toBe(1);
  });
});
