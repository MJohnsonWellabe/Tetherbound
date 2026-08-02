import { describe, expect, it } from 'vitest';
import { SpawnManager, type ScriptedSpawnOptions, type WildPal } from '../src/entities/SpawnManager';
import type { PalBody, PalVisuals } from '../src/entities/PalVisual';
import { Terrain } from '../src/world/gen/Terrain';

/**
 * `spawnScripted`, the opening scene's guaranteed tuftmoth (Objectives.ts).
 * CLAUDE.md hard constraint 6: no Math.random in anything world-facing, and
 * these prove it by construction rather than by reading the source: two
 * managers built from the same seed place the same pal the same way.
 *
 * PalVisuals owns real meshes, which need a Babylon scene this file has no
 * reason to spin up. A fake stands in; SpawnManager only ever calls
 * `acquire()` and touches the returned body's `root` and `driver`.
 */

function fakeVisuals(): PalVisuals {
  const acquire = (): PalBody => ({
    root: { position: { set: () => undefined }, rotation: { y: 0 } } as unknown as PalBody['root'],
    driver: { play: () => undefined } as unknown as PalBody['driver'],
    speciesId: 'tuftmoth',
    dispose: () => undefined
  });
  return { acquire, dispose: () => undefined } as unknown as PalVisuals;
}

const OPTS: ScriptedSpawnOptions = {
  level: 3,
  day: 1,
  uid: 'story_tuftmoth',
  docile: true,
  guaranteedCatch: true
};

function place(seed: string, opts: ScriptedSpawnOptions): WildPal {
  const spawner = new SpawnManager(new Terrain(seed), fakeVisuals());
  const pal = spawner.spawnScripted('tuftmoth', 65, 0, opts);
  expect(pal, 'the fake visuals always returns a body, so this must never be null').not.toBeNull();
  return pal!;
}

describe('spawnScripted', () => {
  it('places the pal at the requested spot, at the terrain height there', () => {
    const terrain = new Terrain('hollowbrook');
    const pal = place('hollowbrook', OPTS);
    expect(pal.x).toBe(65);
    expect(pal.z).toBe(0);
    expect(pal.y).toBe(terrain.heightAt(65, 0));
  });

  it('is deterministic: the same seed and uid place an identical pal twice', () => {
    const a = place('hollowbrook', OPTS);
    const b = place('hollowbrook', OPTS);
    expect(a.state.variance).toBe(b.state.variance);
    expect(a.yaw).toBe(b.yaw);
    expect(a.state.uid).toBe(b.state.uid);
  });

  it('a different world seed places a different-facing, differently-varied pal', () => {
    const a = place('hollowbrook', OPTS);
    const b = place('a-different-seed', OPTS);
    // Not a hard guarantee for any single field in isolation, but the pair
    // matching on every seed-derived field would be a coincidence worth
    // investigating rather than trusting.
    expect(a.yaw === b.yaw && a.state.variance === b.state.variance).toBe(false);
  });

  it('sets guaranteedCatch on the pal only when asked', () => {
    const guaranteed = place('hollowbrook', { ...OPTS, guaranteedCatch: true });
    expect(guaranteed.state.guaranteedCatch).toBe(true);

    const notGuaranteed = place('hollowbrook', { ...OPTS, uid: 'other', guaranteedCatch: false });
    expect(notGuaranteed.state.guaranteedCatch).toBeUndefined();
  });

  it('sets docile on the WildPal only when asked', () => {
    const docile = place('hollowbrook', { ...OPTS, docile: true });
    expect(docile.docile).toBe(true);

    const notDocile = place('hollowbrook', { ...OPTS, uid: 'other', docile: false });
    expect(notDocile.docile).toBe(false);
  });
});
