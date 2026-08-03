import { describe, expect, it } from 'vitest';
import { MAX_PARTY, Party } from '../src/party/Party';
import type { PalState } from '../src/party/PalState';

function pal(id: string, level = 5): PalState {
  return {
    uid: id,
    species: 'tuftmoth',
    nickname: null,
    level,
    xp: 0,
    variance: 1,
    affinity: 50,
    currentHp: 30,
    fainted: false,
    caughtOnDay: 1,
    caughtAtMs: 0
  };
}

describe('the five-slot cap', () => {
  it('accepts five', () => {
    const party = new Party();
    for (let i = 0; i < MAX_PARTY; i++) {
      expect(party.add(pal(`p${i}`)).ok).toBe(true);
    }
    expect(party.size).toBe(MAX_PARTY);
  });

  it('is five, not some other number', () => {
    expect(MAX_PARTY).toBe(5);
  });

  it('refuses the sixth and asks for a release instead', () => {
    const party = new Party();
    for (let i = 0; i < MAX_PARTY; i++) party.add(pal(`p${i}`));
    const result = party.add(pal('sixth'));
    expect(result.ok).toBe(false);
    if (!result.ok && result.needsRelease) {
      // All six are offered, because the player may release the newcomer.
      expect(result.roster).toHaveLength(MAX_PARTY + 1);
      expect(result.roster.map((p: PalState) => p.uid)).toContain('sixth');
    } else {
      throw new Error('a sixth capture must ask for a release');
    }
  });

  it('never holds six, no matter how many times you push', () => {
    const party = new Party();
    for (let i = 0; i < 200; i++) party.add(pal(`p${i}`));
    expect(party.size).toBe(MAX_PARTY);
    expect(party.members).toHaveLength(MAX_PARTY);
  });

  it('does not add the sixth as a side effect of being refused', () => {
    const party = new Party();
    for (let i = 0; i < MAX_PARTY; i++) party.add(pal(`p${i}`));
    party.add(pal('ghost'));
    expect(party.members.map((p) => p.uid)).not.toContain('ghost');
  });

  it('accepts a new pal again once one is released', () => {
    const party = new Party();
    for (let i = 0; i < MAX_PARTY; i++) party.add(pal(`p${i}`));
    party.release('p2', 4);
    expect(party.size).toBe(MAX_PARTY - 1);
    expect(party.add(pal('fresh')).ok).toBe(true);
    expect(party.size).toBe(MAX_PARTY);
  });

  it('rejects a duplicate uid rather than holding the same pal twice', () => {
    const party = new Party();
    party.add(pal('same'));
    const again = party.add(pal('same'));
    expect(again.ok).toBe(false);
    expect(party.size).toBe(1);
  });
});

describe('release', () => {
  it('is permanent and recorded in the ledger', () => {
    const party = new Party();
    party.add(pal('doomed', 9));
    const released = party.release('doomed', 12);
    expect(released).toBe(true);
    expect(party.size).toBe(0);
    expect(party.ledger).toHaveLength(1);
    expect(party.ledger[0]).toMatchObject({ species: 'tuftmoth', level: 9, day: 12 });
  });

  it('reports failure for a pal that is not held', () => {
    const party = new Party();
    expect(party.release('nobody', 1)).toBe(false);
    expect(party.ledger).toHaveLength(0);
  });

  it('lets a released species be caught again, but as a new individual', () => {
    // docs/01_GAME_DESIGN.md section 5: released pals never return. A later catch of
    // the same species is a different pal, and the ledger still remembers.
    const party = new Party();
    party.add(pal('first', 7));
    party.release('first', 3);
    expect(party.add(pal('second', 7)).ok).toBe(true);
    expect(party.ledger).toHaveLength(1);
  });
});

describe('loading a save', () => {
  it('clamps an over-long party rather than trusting the file', () => {
    // docs/03_TECHNICAL_ARCHITECTURE.md: SaveManager.load() clamps party.length to 5. A hand
    // edited or corrupted save must not be able to smuggle in a sixth.
    const party = Party.fromSave(
      Array.from({ length: 9 }, (_, i) => pal(`p${i}`)),
      []
    );
    expect(party.size).toBe(MAX_PARTY);
  });

  it('round-trips a legal party unchanged', () => {
    const members = [pal('a'), pal('b'), pal('c')];
    const party = Party.fromSave(members, [{ species: 'pebblit', level: 4, day: 2 }]);
    expect(party.size).toBe(3);
    expect(party.ledger).toHaveLength(1);
  });
});

describe('active pal', () => {
  it('starts as the first member', () => {
    const party = new Party();
    party.add(pal('a'));
    party.add(pal('b'));
    expect(party.active?.uid).toBe('a');
  });

  it('can be swapped to another slot', () => {
    const party = new Party();
    party.add(pal('a'));
    party.add(pal('b'));
    expect(party.setActive(1)).toBe(true);
    expect(party.active?.uid).toBe('b');
  });

  it('refuses to make a fainted pal active', () => {
    const party = new Party();
    party.add(pal('a'));
    const downed = pal('b');
    downed.fainted = true;
    party.add(downed);
    expect(party.setActive(1)).toBe(false);
    expect(party.active?.uid).toBe('a');
  });

  it('refuses an out-of-range slot', () => {
    const party = new Party();
    party.add(pal('a'));
    expect(party.setActive(4)).toBe(false);
    expect(party.setActive(-1)).toBe(false);
  });

  it('knows when the whole party is down', () => {
    const party = new Party();
    for (let i = 0; i < 3; i++) party.add(pal(`p${i}`));
    expect(party.allFainted).toBe(false);
    for (const p of party.members) p.fainted = true;
    expect(party.allFainted).toBe(true);
  });

  it('reports the highest level held, for the catch formula', () => {
    const party = new Party();
    party.add(pal('a', 6));
    party.add(pal('b', 14));
    party.add(pal('c', 9));
    expect(party.highestLevel).toBe(14);
  });

  it('reports zero highest level when empty, not undefined', () => {
    expect(new Party().highestLevel).toBe(0);
  });
});
