import { describe, expect, it } from 'vitest';
import { evaluatePredicate, type ObjectiveContext, type ObjectivePredicate } from '../src/game/Objectives';
import objectivesData from '../src/data/objectives.json';

/**
 * The opening objective chain (docs/01_GAME_DESIGN.md section 3). `evaluatePredicate`
 * is pure, so the predicate kinds are tested here on their own, ahead of
 * anything wiring them to Story, Party or the inventory, same as any other
 * formula CLAUDE.md asks to be tested before it exists.
 */

function ctx(overrides: Partial<ObjectiveContext> = {}): ObjectiveContext {
  return {
    hasFlag: () => false,
    partySize: 0,
    itemCount: () => 0,
    ...overrides
  };
}

describe('evaluatePredicate', () => {
  it('a flag predicate reads Story flags and nothing else', () => {
    const flagged: ObjectivePredicate = { kind: 'flag', flag: 'met_orin' };
    expect(evaluatePredicate(flagged, ctx({ hasFlag: (f) => f === 'met_orin' }))).toBe(true);
    expect(evaluatePredicate(flagged, ctx({ hasFlag: (f) => f === 'took_starter' }))).toBe(false);
  });

  it('a partySize predicate is satisfied at or above the target, never below', () => {
    const needsTwo: ObjectivePredicate = { kind: 'partySize', n: 2 };
    expect(evaluatePredicate(needsTwo, ctx({ partySize: 1 }))).toBe(false);
    expect(evaluatePredicate(needsTwo, ctx({ partySize: 2 }))).toBe(true);
    expect(evaluatePredicate(needsTwo, ctx({ partySize: 5 }))).toBe(true);
  });

  it('an itemCount predicate reads the named item only', () => {
    const needsOrbs: ObjectivePredicate = { kind: 'itemCount', item: 'worn_orb', n: 3 };
    const inventory = ctx({ itemCount: (id) => (id === 'worn_orb' ? 2 : 0) });
    expect(evaluatePredicate(needsOrbs, inventory)).toBe(false);
    const full = ctx({ itemCount: (id) => (id === 'worn_orb' ? 3 : 0) });
    expect(evaluatePredicate(needsOrbs, full)).toBe(true);
  });
});

describe('the opening chain data', () => {
  const steps = objectivesData.steps as { id: string; prompt: string; predicate: ObjectivePredicate }[];

  it('is short: this is the first fifteen minutes, not a tutorial campaign', () => {
    expect(steps.length).toBeGreaterThan(0);
    expect(steps.length).toBeLessThanOrEqual(5);
  });

  it('gives every step a unique id', () => {
    const ids = steps.map((s) => s.id);
    expect(new Set(ids).size).toBe(ids.length);
  });

  it('names a real predicate kind for every step', () => {
    const KNOWN = new Set(['flag', 'partySize', 'itemCount']);
    for (const step of steps) expect(KNOWN.has(step.predicate.kind)).toBe(true);
  });

  it('leads with talking to Grandpa Orin and ends past the catch', () => {
    expect(steps[0]!.id).toBe('meet_orin');
    expect(steps.some((s) => s.id === 'catch_tuftmoth')).toBe(true);
  });
});

describe('a chain advances in order and never skips', () => {
  /** A minimal in-memory chain-walker, mirroring Objectives' own advance rule
   *  (check the current step only, advance one at a time) without needing the
   *  whole game's Story/Party/HUD wiring. */
  function walk(
    steps: { predicate: ObjectivePredicate }[],
    states: ObjectiveContext[]
  ): number[] {
    let index = 0;
    const seenAt: number[] = [];
    for (const state of states) {
      if (index < steps.length && evaluatePredicate(steps[index]!.predicate, state)) {
        seenAt.push(index);
        index++;
      }
    }
    return seenAt;
  }

  it('does not advance past step 1 just because step 2 is already true', () => {
    const steps: { predicate: ObjectivePredicate }[] = [
      { predicate: { kind: 'flag', flag: 'met_orin' } },
      { predicate: { kind: 'partySize', n: 2 } }
    ];
    // Party is already size 2 (step 2's condition) but met_orin is never set,
    // so step 1 must never report satisfied and the chain must never move.
    const advanced = walk(steps, [ctx({ hasFlag: () => false, partySize: 2 })]);
    expect(advanced).toEqual([]);
  });

  it('advances one step at a time, in the order the steps are listed', () => {
    const steps: { predicate: ObjectivePredicate }[] = [
      { predicate: { kind: 'flag', flag: 'met_orin' } },
      { predicate: { kind: 'partySize', n: 2 } },
      { predicate: { kind: 'flag', flag: 'grunt_a_down' } }
    ];
    const sequence: ObjectiveContext[] = [
      ctx({ hasFlag: () => false, partySize: 1 }),
      ctx({ hasFlag: (f) => f === 'met_orin', partySize: 1 }),
      ctx({ hasFlag: (f) => f === 'met_orin', partySize: 2 }),
      ctx({ hasFlag: (f) => f === 'met_orin' || f === 'grunt_a_down', partySize: 2 })
    ];
    expect(walk(steps, sequence)).toEqual([0, 1, 2]);
  });
});
