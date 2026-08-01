import { describe, expect, it } from 'vitest';
import combat from '../src/data/combat.json';
import { makePal } from '../src/party/Pal';
import { Party } from '../src/party/Party';

/**
 * The five-slot rule is the whole game. ARCHITECTURE.md: "Party.add() throws or
 * returns a needsRelease signal at 5, never appends a sixth."
 *
 * These tests exist to make a sixth pal impossible to introduce by accident. If
 * a future refactor adds a second write path into the roster, the length
 * assertions here are what catch it.
 */

const CAP = combat.party.cap;

function fill(party: Party, n = CAP): void {
  for (let i = 0; i < n; i++) {
    expect(party.add(makePal('tuftmoth', 3, () => 0.5))).toEqual({ status: 'added', index: i });
  }
}

describe('the party cap', () => {
  it('is five', () => {
    expect(CAP).toBe(5);
  });

  it('accepts pals up to the cap', () => {
    const party = new Party();
    fill(party);
    expect(party.size).toBe(CAP);
    expect(party.isFull).toBe(true);
  });

  it('refuses the sixth and asks for a release instead of appending', () => {
    const party = new Party();
    fill(party);
    const sixth = makePal('cragpup', 8, () => 0.5);
    const result = party.add(sixth);
    expect(result.status).toBe('needsRelease');
    expect(party.size).toBe(CAP);
  });

  it('never holds six, however many times add is called', () => {
    const party = new Party();
    for (let i = 0; i < 50; i++) party.add(makePal('tuftmoth', 2, () => 0.5));
    expect(party.size).toBe(CAP);
    expect(party.members).toHaveLength(CAP);
  });

  it('holds the pending pal so the release screen has something to offer', () => {
    const party = new Party();
    fill(party);
    const sixth = makePal('ashmane', 12, () => 0.5);
    party.add(sixth);
    expect(party.pending?.uid).toBe(sixth.uid);
  });
});

describe('resolving a sixth capture', () => {
  it('swaps the released pal for the pending one, keeping the party at five', () => {
    const party = new Party();
    fill(party);
    const doomed = party.members[2];
    expect(doomed).toBeDefined();
    const sixth = makePal('ashmane', 12, () => 0.5);
    party.add(sixth);

    party.resolvePending(doomed!.uid);

    expect(party.size).toBe(CAP);
    expect(party.members.some((p) => p.uid === doomed!.uid)).toBe(false);
    expect(party.members.some((p) => p.uid === sixth.uid)).toBe(true);
    expect(party.pending).toBeNull();
  });

  it('records the released pal in the ledger, permanently', () => {
    const party = new Party();
    fill(party);
    const doomed = party.members[0]!;
    party.add(makePal('ashmane', 12, () => 0.5));
    party.resolvePending(doomed.uid, 4);

    expect(party.ledger).toHaveLength(1);
    expect(party.ledger[0]).toMatchObject({ species: doomed.species, level: doomed.level, day: 4 });
  });

  it('can release the newcomer itself, leaving the five untouched', () => {
    const party = new Party();
    fill(party);
    const before = party.members.map((p) => p.uid);
    const sixth = makePal('ashmane', 12, () => 0.5);
    party.add(sixth);

    party.resolvePending(sixth.uid);

    expect(party.members.map((p) => p.uid)).toEqual(before);
    expect(party.size).toBe(CAP);
    expect(party.ledger[0]?.species).toBe('ashmane');
  });

  it('refuses a uid that is neither in the party nor pending', () => {
    const party = new Party();
    fill(party);
    party.add(makePal('ashmane', 12, () => 0.5));
    expect(() => party.resolvePending('not-a-real-uid')).toThrow();
    expect(party.size).toBe(CAP);
  });
});

describe('roster housekeeping', () => {
  it('reports the highest level, which the catch formula needs', () => {
    const party = new Party();
    party.add(makePal('tuftmoth', 3, () => 0.5));
    party.add(makePal('cragpup', 11, () => 0.5));
    party.add(makePal('rillnewt', 7, () => 0.5));
    expect(party.highestLevel).toBe(11);
  });

  it('reports zero highest level when empty, so an empty party is not a divide by zero', () => {
    expect(new Party().highestLevel).toBe(0);
  });

  it('knows when every pal has fainted, which blocks a Hall fight', () => {
    const party = new Party();
    fill(party, 2);
    expect(party.allFainted).toBe(false);
    for (const p of party.members) p.hp = 0;
    expect(party.allFainted).toBe(true);
  });

  it('picks the first conscious pal as the lead', () => {
    const party = new Party();
    fill(party, 3);
    party.members[0]!.hp = 0;
    expect(party.firstConscious()?.uid).toBe(party.members[1]?.uid);
  });

  it('clamps an over-long roster on load rather than trusting the save', () => {
    const party = Party.fromSaved(
      Array.from({ length: 9 }, () => makePal('tuftmoth', 2, () => 0.5)),
      []
    );
    expect(party.size).toBe(CAP);
  });
});
