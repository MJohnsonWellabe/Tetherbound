import type { Suggested } from '../combat/Suggestion';
import type { Intent } from '../core/input/Intent';
import { tapButton } from './dom';

/**
 * The four combat buttons, arranged in a diamond around the centre-framed
 * target: quick at the bottom (A), power at the right (B), orb at the left
 * (X), run at the top (Y). Owner's ROG Ally playtest asked for exactly this
 * reading, so the on-screen layout matches the pad in the player's hands.
 *
 * Every button fires the same edge-triggered Intent field the face button
 * does (src/core/input/GamepadLayer.ts), so a tap and a press are the same
 * event downstream. None of them may ever be disabled: the throw especially
 * must stay pressable from the first frame of a fight (CLAUDE.md hard
 * constraint 3), which is also why Suggestion.ts's return type has no
 * "available" field for this file to be tempted to gate on.
 */

interface ButtonSpec {
  key: keyof Suggested;
  letter: string;
  label: string;
  position: 'top' | 'bottom' | 'left' | 'right';
  fire: (intent: Intent) => void;
}

const BUTTONS: readonly ButtonSpec[] = [
  { key: 'run', letter: 'Y', label: 'Run', position: 'top', fire: (i) => (i.flee = true) },
  { key: 'orb', letter: 'X', label: 'Orb', position: 'left', fire: (i) => (i.throwOrb = true) },
  { key: 'power', letter: 'B', label: 'Power', position: 'right', fire: (i) => (i.powerAttack = true) },
  { key: 'quick', letter: 'A', label: 'Quick', position: 'bottom', fire: (i) => (i.quickAttack = true) }
];

export class CombatButtons {
  private readonly buttons = new Map<keyof Suggested, HTMLButtonElement>();
  private readonly orbCount: HTMLElement;

  constructor(container: HTMLElement, intent: Intent) {
    let orbCount: HTMLElement | null = null;
    for (const spec of BUTTONS) {
      const btn = tapButton(
        `${spec.label} (${spec.letter})`,
        `cb__dbtn cb__dbtn--${spec.position}`,
        () => spec.fire(intent)
      );
      // tapButton sets textContent for the pointer/keyboard handlers it wires;
      // this replaces that with the same information laid out as a letter
      // badge over a label, so a controller player and a touch player read
      // the same button two different ways.
      btn.innerHTML = `<span class="cb__dbtn-letter">${spec.letter}</span><span class="cb__dbtn-label">${spec.label}</span>`;
      if (spec.key === 'orb') {
        const badge = document.createElement('span');
        badge.className = 'cb__dbtn-count';
        btn.appendChild(badge);
        orbCount = badge;
      }
      container.appendChild(btn);
      this.buttons.set(spec.key, btn);
    }
    // BUTTONS always includes an 'orb' entry, so this is never null.
    this.orbCount = orbCount as HTMLElement;
  }

  /**
   * Called once per fixed step. `suggested` lights the recommended button(s);
   * `orbsHeld` is shown on the orb button so the glow (or its absence) is
   * explicable rather than mysterious.
   */
  update(suggested: Suggested, orbsHeld: number): void {
    for (const [key, btn] of this.buttons) {
      btn.classList.toggle('is-suggested', suggested[key]);
    }
    this.orbCount.textContent = orbsHeld > 0 ? `×${orbsHeld}` : '';
  }
}
