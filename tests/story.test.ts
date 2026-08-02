import { describe, expect, it } from 'vitest';
import { isStarterChoice } from '../src/game/Story';
import type { DialogueChoice } from '../src/ui/DialogueRunner';

/**
 * The one bit of Story that is worth testing in isolation: which dialogue
 * line gets the starter picker instead of the plain choice buttons. The rest
 * of Story needs a world, a party, a combat mode and four other collaborators
 * to construct, which is smoke-test territory, not unit-test territory.
 */

function choice(effect?: string): DialogueChoice {
  return effect === undefined ? { label: 'x', goto: 'y' } : { label: 'x', goto: 'y', effect };
}

describe('isStarterChoice', () => {
  it('is true for the three starter effects', () => {
    expect(
      isStarterChoice([choice('starter:bramblit'), choice('starter:cindercub'), choice('starter:dewdrake')])
    ).toBe(true);
  });

  it('is false with no choices', () => {
    expect(isStarterChoice([])).toBe(false);
  });

  it('is false when any choice is not a starter effect', () => {
    expect(isStarterChoice([choice('recruit:loamking'), choice(undefined)])).toBe(false);
  });

  it('is false for a mixed line, so a future choice node cannot be picked up by accident', () => {
    expect(isStarterChoice([choice('starter:bramblit'), choice('flag:something')])).toBe(false);
  });
});
