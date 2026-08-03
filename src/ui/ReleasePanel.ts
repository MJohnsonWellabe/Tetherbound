import type { ReleaseFlow } from '../party/Release';
import { speciesDef } from '../entities/Species';

/**
 * The sixth-capture screen, as cards instead of ASCII rows.
 *
 * Deliberately heavy per docs/01_GAME_DESIGN.md section 11: level, affinity, days
 * held, and a two-step confirm. Clicking a card selects; the sticky confirm
 * strip does the rest. The keyboard/gamepad slot path in main.ts keeps
 * working; this panel adds pointers, it does not replace anything.
 */

export class ReleasePanel {
  private readonly grid: HTMLElement;
  private readonly confirm: HTMLElement;
  private readonly confirmText: HTMLElement;
  private lastKey = '';

  constructor(
    private readonly root: HTMLElement,
    private readonly release: ReleaseFlow
  ) {
    root.innerHTML = `
      <div class="rel__panel">
        <h2 class="rel__title">The party is full</h2>
        <p class="rel__note">Choose who walks away. Releasing is permanent; there is no storage.</p>
        <div class="rel__grid" data-r="grid"></div>
        <div class="rel__confirm" data-r="confirm" hidden>
          <div class="rel__confirmText" data-r="text"></div>
          <div class="rel__confirmRow">
            <button type="button" class="cb__btn cb__btn--flee" data-r="yes">Release. This cannot be undone.</button>
            <button type="button" class="cb__btn" data-r="no">Keep everyone a moment longer</button>
          </div>
        </div>
      </div>`;

    this.grid = root.querySelector('[data-r="grid"]') as HTMLElement;
    this.confirm = root.querySelector('[data-r="confirm"]') as HTMLElement;
    this.confirmText = root.querySelector('[data-r="text"]') as HTMLElement;

    (root.querySelector('[data-r="no"]') as HTMLElement).addEventListener('click', () => {
      this.release.cancel();
    });
    (root.querySelector('[data-r="yes"]') as HTMLElement).addEventListener('click', () => {
      // confirm(day) needs the day; update() stores it each paint.
      this.release.confirm(this.day);
    });
  }

  private day = 0;

  /** Called once per fixed step. */
  update(day: number): void {
    this.day = day;
    if (this.release.stage === 'closed') {
      if (!this.root.hidden) this.root.hidden = true;
      return;
    }
    this.root.hidden = false;

    const candidates = this.release.candidates(day);
    // Repaint only when the roster or the selection changed; the panel is
    // modal and static between clicks.
    const key = candidates.map((c) => c.pal.uid).join(',') + ':' + (this.release.selectedUid ?? '');
    if (key === this.lastKey) return;
    this.lastKey = key;

    this.grid.textContent = '';
    for (const c of candidates) {
      const card = document.createElement('button');
      card.type = 'button';
      card.className = `card${c.isNewcomer ? ' card--incoming' : ''}${c.pal.fainted ? ' card--fainted' : ''}`;
      const type = speciesDef(c.pal.species)?.type ?? '';
      card.innerHTML = `
        ${c.isNewcomer ? '<span class="card__flag">just caught</span>' : ''}
        <div class="card__head">
          <span class="card__name"></span>
          <span class="card__lvl">Lv${c.level}</span>
          <span class="card__type"></span>
        </div>
        <div class="card__meta">
          <span class="card__affinity">affinity ${c.affinity}</span>
          <span>${c.daysHeld}d together</span>
        </div>
        ${c.pal.fainted ? '<span class="card__fainted">fainted</span>' : ''}
        <span class="card__release">${c.pal.uid === this.release.selectedUid ? 'selected' : 'release'}</span>`;
      (card.querySelector('.card__name') as HTMLElement).textContent = c.speciesName;
      (card.querySelector('.card__type') as HTMLElement).textContent = type;
      card.addEventListener('click', () => {
        // Re-picking while confirming backs out first; select() only acts in
        // the choosing stage.
        if (this.release.stage === 'confirming' && this.release.selectedUid !== c.pal.uid) {
          this.release.cancel();
        }
        this.release.select(c.pal.uid);
      });
      this.grid.appendChild(card);
    }

    const selected = candidates.find((c) => c.pal.uid === this.release.selectedUid);
    this.confirm.hidden = this.release.stage !== 'confirming' || !selected;
    if (selected) {
      this.confirmText.textContent = `${selected.speciesName}, Lv${selected.level}, ${selected.daysHeld} day${selected.daysHeld === 1 ? '' : 's'} together. Release?`;
    }
  }

  dispose(): void {
    this.root.innerHTML = '';
    this.root.hidden = true;
  }
}
