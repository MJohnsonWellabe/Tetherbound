import { describe, expect, it } from 'vitest';
import { createAi, stepAi } from '../src/entities/PalAI';
import { speciesDef } from '../src/entities/Species';
import { mulberry32 } from '../src/world/gen/Rng';

/**
 * The docile pin (Objectives.ts / SpawnManager.spawnScripted). The opening
 * scene's tuftmoth is pinned to wander/graze so a new player cannot lose it,
 * but tested here against species that WOULD otherwise aggro or flee, so the
 * pin is proven to override behaviour rather than merely agree with a docile
 * species that never had any to begin with.
 */

const rand = mulberry32(1);

describe('the docile pin', () => {
  it('an aggressive species aggros normally when not docile', () => {
    const ashmane = speciesDef('ashmane')!;
    const ai = createAi(0, 0, rand);
    const out = stepAi(
      ai,
      ashmane,
      {
        distanceToPlayer: 3,
        bearingToPlayer: 0,
        distanceFromHome: 0,
        headingHome: 0
      },
      1 / 60,
      rand,
      false
    );
    expect(out.mood).toBe('aggro');
  });

  it('the same aggressive species never aggros while pinned docile', () => {
    const ashmane = speciesDef('ashmane')!;
    const ai = createAi(0, 0, rand);
    const out = stepAi(
      ai,
      ashmane,
      {
        distanceToPlayer: 3,
        bearingToPlayer: 0,
        distanceFromHome: 0,
        headingHome: 0
      },
      1 / 60,
      rand,
      true
    );
    expect(out.mood).not.toBe('aggro');
  });

  it('a skittish species flees normally when not docile', () => {
    const sparrowick = speciesDef('sparrowick')!;
    const ai = createAi(0, 0, rand);
    const out = stepAi(
      ai,
      sparrowick,
      {
        distanceToPlayer: 3,
        bearingToPlayer: 0,
        distanceFromHome: 0,
        headingHome: 0
      },
      1 / 60,
      rand,
      false
    );
    expect(out.mood).toBe('flee');
  });

  it('the same skittish species never flees while pinned docile', () => {
    const sparrowick = speciesDef('sparrowick')!;
    const ai = createAi(0, 0, rand);
    for (let i = 0; i < 20; i++) {
      const out = stepAi(
        ai,
        sparrowick,
        {
          distanceToPlayer: 3,
          bearingToPlayer: 0,
          distanceFromHome: 0,
          headingHome: 0
        },
        1 / 60,
        rand,
        true
      );
      expect(out.mood).not.toBe('flee');
      expect(out.mood).not.toBe('aggro');
    }
  });

  it('a docile pal still leashes home, since that rule protects the world, not the player', () => {
    const tuftmoth = speciesDef('tuftmoth')!;
    const ai = createAi(0, 0, rand);
    const out = stepAi(
      ai,
      tuftmoth,
      {
        distanceToPlayer: 3,
        bearingToPlayer: 0,
        distanceFromHome: 999,
        headingHome: Math.PI
      },
      1 / 60,
      rand,
      true
    );
    expect(out.mood).toBe('wander');
    expect(out.heading).toBe(Math.PI);
  });
});
