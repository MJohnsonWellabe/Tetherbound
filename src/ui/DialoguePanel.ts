import { clear, el, tapButton } from './dom';
import type { DialogueLine } from './DialogueRunner';

/**
 * The dialogue box, and the victory sequence that reuses it.
 *
 * Tapping anywhere on the panel advances a plain line. A line with choices does
 * not advance on tap: the player has to pick one, which is what stops a fast
 * tapper from blowing through the starter choice without seeing it.
 */

export class DialoguePanel {
  readonly root: HTMLElement;
  private readonly speaker: HTMLElement;
  private readonly text: HTMLElement;
  private readonly choices: HTMLElement;
  private readonly hint: HTMLElement;

  onAdvance: (() => void) | null = null;
  onChoose: ((index: number) => void) | null = null;

  constructor(parent: HTMLElement = document.body) {
    this.speaker = el('div', 'dlg__speaker');
    this.text = el('div', 'dlg__text');
    this.choices = el('div', 'dlg__choices');
    this.hint = el('div', 'dlg__hint', 'Tap to continue');

    const panel = el('div', 'dlg__panel', this.speaker, this.text, this.choices, this.hint);
    this.root = el('div', 'dlg', panel);
    this.root.hidden = true;

    this.root.addEventListener('pointerdown', (event) => {
      // A tap on a choice button is that button's business, not an advance.
      if ((event.target as HTMLElement).closest('.dlg__choice')) return;
      event.preventDefault();
      if (this.choices.childElementCount > 0) return;
      this.onAdvance?.();
    });

    parent.append(this.root);
  }

  get isOpen(): boolean {
    return !this.root.hidden;
  }

  show(line: DialogueLine): void {
    this.root.hidden = false;
    this.speaker.textContent = line.speaker;
    this.text.textContent = line.text;

    clear(this.choices);
    for (const [index, choice] of line.choices.entries()) {
      this.choices.append(
        tapButton(choice.label, 'dlg__choice', () => this.onChoose?.(index))
      );
    }
    this.hint.hidden = line.choices.length > 0;
    this.hint.textContent = line.isLast ? 'Tap to close' : 'Tap to continue';
  }

  hide(): void {
    this.root.hidden = true;
    clear(this.choices);
  }

  dispose(): void {
    this.root.remove();
  }
}

export interface VictoryDetails {
  title: string;
  lines: string[];
  badge?: { name: string };
  unlocks: string[];
}

/**
 * The cut-tether sequence. Deliberately a full-screen moment rather than a
 * toast: this is the win state the whole milestone exists to reach, and the
 * four freed pals scattering is the payoff for the Hall.
 */
export class VictoryScreen {
  readonly root: HTMLElement;
  private readonly body: HTMLElement;
  onDismiss: (() => void) | null = null;

  constructor(parent: HTMLElement = document.body) {
    this.body = el('div', 'victory__body');
    this.root = el('div', 'victory', el('div', 'victory__panel', this.body));
    this.root.hidden = true;
    parent.append(this.root);
  }

  show(details: VictoryDetails): void {
    clear(this.body);
    this.root.hidden = false;

    this.body.append(el('h2', 'victory__title', details.title));
    for (const line of details.lines) {
      this.body.append(el('p', 'victory__line', line));
    }
    if (details.badge) {
      this.body.append(
        el(
          'div',
          'victory__badge',
          el('div', 'victory__sigil'),
          el('div', 'victory__badgeName', details.badge.name)
        )
      );
    }
    if (details.unlocks.length > 0) {
      const list = el('ul', 'victory__unlocks');
      for (const unlock of details.unlocks) list.append(el('li', 'victory__unlock', unlock));
      this.body.append(list);
    }
    this.body.append(
      tapButton('Continue', 'btn btn--primary victory__go', () => {
        this.hide();
        this.onDismiss?.();
      })
    );
  }

  hide(): void {
    this.root.hidden = true;
  }

  get isOpen(): boolean {
    return !this.root.hidden;
  }

  dispose(): void {
    this.root.remove();
  }
}
