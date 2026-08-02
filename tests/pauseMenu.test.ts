import { describe, expect, it } from 'vitest';
import { activateStartOver } from '../src/ui/PauseMenu';

/**
 * The two-step confirm on Start Over, isolated from the DOM class so it runs
 * headless like the rest of this suite (PauseMenu.ts is a DOM overlay, in
 * keeping with ReleasePanel.ts and HUD.ts, which this codebase verifies with
 * the Playwright smoke tests rather than vitest).
 *
 * "Never wipe on a single press" is the one rule that matters here, so it is
 * asserted directly: one activation must not carry `wipe: true`.
 */
describe('activateStartOver', () => {
  it('does not wipe on the first activation, only arms', () => {
    const first = activateStartOver('idle');
    expect(first.wipe).toBe(false);
    expect(first.stage).toBe('confirming');
  });

  it('wipes on the second activation while still armed', () => {
    const first = activateStartOver('idle');
    const second = activateStartOver(first.stage);
    expect(second.wipe).toBe(true);
    expect(second.stage).toBe('confirming');
  });

  it('does not wipe from idle no matter how many times it is called, unless armed first', () => {
    const a = activateStartOver('idle');
    expect(a.wipe).toBe(false);
    // Calling from 'idle' again (as if a cancel happened in between) still
    // only arms, never wipes.
    const b = activateStartOver('idle');
    expect(b.wipe).toBe(false);
  });
});
