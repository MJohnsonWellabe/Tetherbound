import { clear, tapButton } from './dom';
import type { DialogueChoice } from './DialogueRunner';
import { facingYaw } from '../combat/stagePlacement';
import type { PalBody, PalVisuals } from '../entities/PalVisual';
import type { CameraFraming, Player } from '../entities/Player';
import { speciesDef } from '../entities/Species';
import { centreOf, placeStarters, type StarterAnchor } from './starterPlacement';
import dialogueData from '../data/dialogue.json';
import tuning from '../data/starterPicker.json';

/**
 * Grandpa Orin's starter choice, staged instead of spoken.
 *
 * The three candidates are real, animated bodies standing in front of Orin
 * (PalVisuals.acquire, the same display-only body combat borrows for the
 * ally), each with a card carrying its name, type and a one-line read. The
 * player picks the single most important pal in the game from something they
 * can actually look at, not three words in a list.
 *
 * DialoguePanel stays hidden for this one node; Story swaps between the two.
 */

const FRAMING = tuning.camera as CameraFraming;
const READS = (dialogueData as unknown as { $starterReads?: Record<string, string> }).$starterReads ?? {};

export class StarterPicker {
  private readonly textEl: HTMLElement;
  private readonly cardsEl: HTMLElement;
  private bodies: PalBody[] = [];
  private centre = { x: 0, z: 0 };
  private open = false;

  onChoose: ((index: number) => void) | null = null;

  constructor(
    private readonly root: HTMLElement,
    private readonly visuals: PalVisuals,
    private readonly player: Player
  ) {
    root.innerHTML = `
      <div class="starter__panel">
        <p class="starter__speaker">Grandpa Orin</p>
        <p class="starter__text" data-s="text"></p>
        <div class="starter__row" data-s="cards"></div>
      </div>`;
    this.textEl = root.querySelector('[data-s="text"]') as HTMLElement;
    this.cardsEl = root.querySelector('[data-s="cards"]') as HTMLElement;
  }

  get isOpen(): boolean {
    return this.open;
  }

  /**
   * Story calls this on every repaint while the starter node is active.
   * Idempotent past the first call: the bodies and cards are built once, and
   * a repeated call only refreshes the line (it never actually changes, but
   * a future rewrite of orin_intro should not have to remember why this
   * matters).
   */
  show(text: string, choices: readonly DialogueChoice[], anchor: { x: number; y: number; z: number; yaw: number }): void {
    this.textEl.textContent = text;
    if (this.open) return;
    this.open = true;
    this.root.hidden = false;

    const speciesIds = choices.map((choice) => speciesFromEffect(choice.effect));
    const flatAnchor: StarterAnchor = { x: anchor.x, z: anchor.z, yaw: anchor.yaw };
    const spots = placeStarters(flatAnchor, speciesIds.length, tuning.placement);
    this.centre = centreOf(spots);

    clear(this.cardsEl);
    speciesIds.forEach((speciesId, index) => {
      const spot = spots[index];
      if (speciesId && spot) this.spawn(speciesId, spot.x, anchor.y, spot.z, spot.yaw);
      this.cardsEl.append(this.buildCard(speciesId, choices[index]?.label ?? '', index));
    });

    this.player.setCameraFraming(FRAMING);
  }

  /** One fixed step while open, so the trio stays framed if the player moves. */
  update(playerX: number, playerZ: number): void {
    if (!this.open) return;
    this.player.setYaw(facingYaw(playerX, playerZ, this.centre.x, this.centre.z));
  }

  /** Closes the picker: disposes the three bodies and hands the camera back. */
  hide(): void {
    if (!this.open) return;
    this.open = false;
    this.root.hidden = true;
    clear(this.cardsEl);
    for (const body of this.bodies) body.dispose();
    this.bodies = [];
    this.player.setCameraFraming(null);
  }

  private spawn(speciesId: string, x: number, y: number, z: number, yaw: number): void {
    const body = this.visuals.acquire(speciesId);
    if (!body) return;
    body.root.position.set(x, y, z);
    body.root.rotation.y = yaw;
    body.driver.play('idle', performance.now());
    this.bodies.push(body);
  }

  private buildCard(speciesId: string | null, label: string, index: number): HTMLElement {
    const def = speciesId ? speciesDef(speciesId) : undefined;
    const card = tapButton('', 'card starter__card', () => this.onChoose?.(index));
    card.innerHTML = `
      <div class="card__head">
        <span class="starter__num"></span>
        <span class="card__name"></span>
        <span class="card__type"></span>
      </div>
      <p class="card__blurb"></p>`;
    (card.querySelector('.starter__num') as HTMLElement).textContent = String(index + 1);
    (card.querySelector('.card__name') as HTMLElement).textContent = def?.name ?? label;
    (card.querySelector('.card__type') as HTMLElement).textContent = def?.type ?? '';
    (card.querySelector('.card__blurb') as HTMLElement).textContent = (speciesId && READS[speciesId]) || '';
    return card;
  }

  /** Disposal soak: called once, at teardown, same as every other UI class. */
  dispose(): void {
    this.hide();
    this.root.innerHTML = '';
  }
}

/** `starter:bramblit` -> `bramblit`. Null for anything else, so a choice with
 *  no starter effect renders a card with no body and no read rather than
 *  throwing; nothing in dialogue.json produces that today, but the picker
 *  should not depend on that staying true to avoid crashing mid-scene. */
function speciesFromEffect(effect: string | undefined): string | null {
  if (!effect?.startsWith('starter:')) return null;
  return effect.slice('starter:'.length);
}
