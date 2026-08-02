import combat from '../data/combat.json';
import { clear, el, setFill, tapButton } from './dom';
import type { PalState } from '../party/Pal';
import { requireSpecies } from '../party/Species';
import { xpToNext } from '../party/Progression';

/**
 * The release screen, and the party screen it shares a layout with.
 *
 * GAME_DESIGN.md section 11: "Release confirmation is deliberately heavy. It
 * shows the pal's level, affinity, time with you, and a two-step confirm. This
 * screen should feel bad."
 *
 * So it does. There is no cancel, because at six pals there is no version of
 * this where nobody goes. The two-step confirm names the pal in the second step
 * rather than saying "are you sure", so the last thing the player reads before
 * committing is who they are giving up.
 */

function affinityWord(affinity: number): string {
  if (affinity >= combat.affinity.highThreshold) return 'Bonded';
  if (affinity <= combat.affinity.lowThreshold) return 'Wary';
  return 'Settled';
}

function timeWith(pal: PalState, day: number): string {
  const days = Math.max(0, day - pal.caughtDay);
  if (pal.caughtDay === 0 && days === 0) return 'Since the start';
  if (days === 0) return 'Caught today';
  return days === 1 ? '1 day with you' : `${days} days with you`;
}

/** One pal, rendered as a card. Shared by both screens. */
function palCard(pal: PalState, day: number, onPick: (() => void) | null): HTMLElement {
  const def = requireSpecies(pal.species);
  const hpFill = el('i', 'bar__fill bar__fill--health');
  setFill(hpFill, pal.hp / Math.max(1, pal.maxHp));
  const xpFill = el('i', 'bar__fill bar__fill--xp');
  setFill(xpFill, pal.xp / Math.max(1, xpToNext(pal.level)));

  const card = el(
    'div',
    `card card--${pal.type}${pal.hp <= 0 ? ' card--fainted' : ''}`,
    el(
      'div',
      'card__head',
      el('span', 'card__name', pal.name),
      el('span', 'card__lvl', `L${pal.level}`),
      el('span', `card__type card__type--${pal.type}`, pal.type)
    ),
    el('div', 'bar', hpFill),
    el('div', 'card__stat', `${Math.max(0, Math.round(pal.hp))} / ${pal.maxHp} HP`),
    el('div', 'bar bar--xp', xpFill),
    el(
      'div',
      'card__meta',
      el('span', 'card__affinity', affinityWord(pal.affinity)),
      el('span', 'card__time', timeWith(pal, day))
    ),
    el('div', 'card__blurb', def.blurb),
    pal.hp <= 0 ? el('div', 'card__fainted', 'Fainted') : null
  );

  if (onPick) {
    card.classList.add('card--pickable');
    card.append(tapButton('Release', 'card__release', onPick));
  }
  return card;
}

export class ReleaseScreen {
  readonly root: HTMLElement;
  private readonly grid: HTMLElement;
  private readonly title: HTMLElement;
  private readonly note: HTMLElement;
  private readonly confirm: HTMLElement;

  /** Resolved with the uid of the pal the player gave up. */
  onRelease: ((uid: string) => void) | null = null;

  constructor(parent: HTMLElement = document.body) {
    this.title = el('h2', 'rel__title', 'You are holding six');
    this.note = el(
      'div',
      'rel__note',
      'Five is the limit. Choose who goes. They will not come back.'
    );
    this.grid = el('div', 'rel__grid');
    this.confirm = el('div', 'rel__confirm');
    this.confirm.hidden = true;

    this.root = el(
      'div',
      'rel',
      el('div', 'rel__panel', this.title, this.note, this.grid, this.confirm)
    );
    this.root.hidden = true;
    parent.append(this.root);
  }

  get isOpen(): boolean {
    return !this.root.hidden;
  }

  /** Open with all six: the five held plus the newcomer. */
  open(members: readonly PalState[], incoming: PalState, day: number): void {
    this.root.hidden = false;
    this.confirm.hidden = true;
    clear(this.grid);

    for (const pal of members) {
      this.grid.append(palCard(pal, day, () => this.askConfirm(pal, day)));
    }
    const card = palCard(incoming, day, () => this.askConfirm(incoming, day));
    card.classList.add('card--incoming');
    card.prepend(el('div', 'card__flag', 'Just caught'));
    this.grid.append(card);
  }

  /**
   * Step two. Names the pal rather than asking a generic question, so the
   * confirming tap is attached to a specific animal.
   */
  private askConfirm(pal: PalState, day: number): void {
    clear(this.confirm);
    this.confirm.hidden = false;
    this.confirm.append(
      el('div', 'rel__confirmText', `Release ${pal.name}, level ${pal.level}, ${timeWith(pal, day).toLowerCase()}?`),
      el(
        'div',
        'rel__confirmRow',
        tapButton('Go back', 'btn', () => {
          this.confirm.hidden = true;
        }),
        tapButton(`Release ${pal.name}`, 'btn btn--danger', () => {
          this.close();
          this.onRelease?.(pal.uid);
        })
      )
    );
  }

  close(): void {
    this.root.hidden = true;
  }

  dispose(): void {
    this.root.remove();
  }
}

/** The read-only roster. Same cards, no release affordance. */
export class PartyScreen {
  readonly root: HTMLElement;
  private readonly grid: HTMLElement;
  private readonly ledger: HTMLElement;

  constructor(parent: HTMLElement = document.body) {
    this.grid = el('div', 'rel__grid');
    this.ledger = el('div', 'party__ledger');

    const close = tapButton('Close', 'btn party__close', () => this.close());
    this.root = el(
      'div',
      'rel party',
      el(
        'div',
        'rel__panel',
        el('h2', 'rel__title', 'Your five'),
        this.grid,
        this.ledger,
        close
      )
    );
    this.root.hidden = true;
    parent.append(this.root);
  }

  get isOpen(): boolean {
    return !this.root.hidden;
  }

  open(
    members: readonly PalState[],
    released: readonly { name: string; level: number; day: number }[],
    day: number
  ): void {
    this.root.hidden = false;
    clear(this.grid);
    clear(this.ledger);

    if (members.length === 0) {
      this.grid.append(el('div', 'party__empty', 'No pals yet. Orin has three.'));
    }
    for (const pal of members) this.grid.append(palCard(pal, day, null));

    // The ledger is permanent and always visible. Releasing has to leave a
    // mark somewhere or the five-slot rule costs nothing after the fact.
    if (released.length > 0) {
      this.ledger.append(el('h3', 'party__ledgerTitle', 'Released'));
      for (const record of released) {
        this.ledger.append(
          el('div', 'party__ledgerRow', `${record.name}, level ${record.level}, day ${record.day}`)
        );
      }
    }
  }

  close(): void {
    this.root.hidden = true;
  }

  dispose(): void {
    this.root.remove();
  }
}
