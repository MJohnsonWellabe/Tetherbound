import { clear, el, setFill, show, tapButton } from './dom';
import type { PalState } from '../party/PalState';
import { derive, speciesDef } from '../entities/Species';
import type { Party } from '../party/Party';
import type { VitalsState } from '../survival/Vitals';
import { maxHealth, maxStamina, VITALS_CONFIG } from '../survival/Vitals';
import {
  layOutCardinals,
  layOutCompass,
  type CardinalMark,
  type CompassCandidate
} from './compass';

/**
 * The exploration HUD: vitals, party pips, compass, and the interact prompt.
 *
 * DOM overlay. Built for a handheld first (D28): every touch target is at least
 * the --tap token (44px), nothing depends on hover, and the chrome is inset to
 * the --pad-lg safe margin so a rounded or overscanned panel cannot clip it.
 *
 * The HUD is a VIEW. It reads state handed to it and never reaches back into a
 * system to ask a question, which is what keeps a repaint from being able to
 * change the game.
 */

export interface CompassMarker {
  label: string;
  x: number;
  z: number;
  kind: 'hall' | 'stones' | 'village' | 'satchel';
}

/** Fallback strip width, used only before the first layout read. */
const COMPASS_FALLBACK_PX = 460;

export class HUD {
  readonly root: HTMLElement;

  private readonly healthFill: HTMLElement;
  private readonly staminaFill: HTMLElement;
  private readonly hungerFill: HTMLElement;
  private readonly healthNum: HTMLElement;
  private readonly staminaNum: HTMLElement;
  private readonly hungerNum: HTMLElement;
  private readonly buffRow: HTMLElement;
  private readonly pips: HTMLElement;
  private readonly compass: HTMLElement;
  private readonly prompt: HTMLElement;
  private readonly toastRow: HTMLElement;
  private readonly dayLabel: HTMLElement;

  /** Cached so the compass does not force a layout read every single frame. */
  private compassWidth = 0;
  private readonly onResize = (): void => {
    this.compassWidth = 0;
  };

  /** Callbacks the game wires up. Null until then, so the HUD is inert alone. */
  onPartyTap: (() => void) | null = null;
  onInteract: (() => void) | null = null;

  constructor(parent: HTMLElement = document.body) {
    this.healthFill = el('i', 'meter__fill meter__fill--health');
    this.staminaFill = el('i', 'meter__fill meter__fill--stamina');
    this.hungerFill = el('i', 'meter__fill meter__fill--hunger');
    this.healthNum = el('span', 'vital__num', '100');
    this.staminaNum = el('span', 'vital__num', '100');
    this.hungerNum = el('span', 'vital__num', '100');
    this.buffRow = el('div', 'hud__buffs');
    this.dayLabel = el('div', 'hud__day', 'Day 1');

    const vitals = el(
      'div',
      'hud__vitals',
      vitalRow('health', this.healthFill, this.healthNum),
      vitalRow('stamina', this.staminaFill, this.staminaNum),
      vitalRow('hunger', this.hungerFill, this.hungerNum),
      this.buffRow
    );

    this.compass = el('div', 'hud__compass');
    this.pips = el('div', 'hud__pips');
    this.pips.addEventListener('pointerdown', (event) => {
      event.preventDefault();
      this.onPartyTap?.();
    });

    this.prompt = el('div', 'hud__prompt');
    this.prompt.hidden = true;

    this.toastRow = el('div', 'hud__toasts');

    const interact = tapButton('', 'hud__interact', () => this.onInteract?.());
    interact.hidden = true;
    this.interactButton = interact;

    this.root = el(
      'div',
      'hud',
      el('div', 'hud__top', this.compass, this.dayLabel),
      vitals,
      this.toastRow,
      this.prompt,
      interact,
      this.pips
    );
    parent.append(this.root);
    window.addEventListener('resize', this.onResize);
  }

  private readonly interactButton: HTMLButtonElement;

  setVisible(on: boolean): void {
    show(this.root, on);
  }

  /** Vitals bars. Fractions of the CURRENT maxima, so a buff widens the bar. */
  updateVitals(state: VitalsState): void {
    setFill(this.healthFill, state.health / maxHealth(state));
    setFill(this.staminaFill, state.stamina / maxStamina(state));
    setFill(this.hungerFill, state.hunger / VITALS_CONFIG.maxHunger);

    this.healthNum.textContent = String(Math.round(state.health));
    this.staminaNum.textContent = String(Math.round(state.stamina));
    this.hungerNum.textContent = String(Math.round(state.hunger));

    clear(this.buffRow);
    for (const buff of state.buffs) {
      this.buffRow.append(el('span', 'hud__buff', buff.label));
    }
  }

  updateDay(day: number, isNight: boolean): void {
    this.dayLabel.textContent = `Day ${day}${isNight ? ' · night' : ''}`;
  }

  /**
   * Party pips. Fainted pals read as fainted rather than simply being dimmer,
   * because "why is my pal not fighting" is the question this row exists to
   * answer at a glance.
   */
  updateParty(party: Party): void {
    clear(this.pips);
    const members = party.members;
    for (let i = 0; i < 5; i++) {
      const pal = members[i];
      this.pips.append(pal ? this.pip(pal, i) : el('div', 'pip pip--empty'));
    }
  }

  /**
   * Nothing derived is stored on a pal: max HP, type and the display name all
   * come from `species.json` plus level plus variance, so a balance change is a
   * data edit rather than a save migration. See the header of PalState.ts.
   */
  private pip(pal: PalState, index: number): HTMLElement {
    const stats = derive(pal);
    const fill = el('i', 'pip__fill');
    setFill(fill, pal.currentHp / Math.max(1, stats.maxHp));

    const node = el(
      'div',
      `pip pip--${stats.type}${pal.fainted ? ' pip--fainted' : ''}`,
      el('span', 'pip__slot', String(index + 1)),
      el('span', 'pip__name', pal.nickname ?? speciesDef(pal.species)?.name ?? pal.species),
      el('span', 'pip__lvl', `L${pal.level}`),
      el('div', 'pip__bar', fill)
    );
    return node;
  }

  /**
   * Compass strip. Markers are placed by bearing relative to where the player
   * is looking. Every marker used to be drawn, which meant three landmarks in
   * roughly the same direction printed on top of each other and none of them
   * could be read. `layOutCompass` drops the lower-priority label instead.
   */
  updateCompass(
    playerX: number,
    playerZ: number,
    yaw: number,
    markers: readonly CompassMarker[]
  ): void {
    clear(this.compass);
    const width = this.stripWidth();

    for (const mark of layOutCardinals(yaw, width)) {
      this.compass.append(cardinalNode(mark));
    }
    for (const pin of layOutCompass(markers, playerX, playerZ, yaw, width)) {
      this.compass.append(pinNode(pin));
    }
  }

  private stripWidth(): number {
    if (this.compassWidth === 0) this.compassWidth = this.compass.clientWidth;
    return this.compassWidth || COMPASS_FALLBACK_PX;
  }

  /** The "press to talk" affordance. Text null hides both prompt and button. */
  setPrompt(text: string | null): void {
    if (!text) {
      this.prompt.hidden = true;
      this.interactButton.hidden = true;
      return;
    }
    this.prompt.textContent = text;
    this.prompt.hidden = false;
    this.interactButton.textContent = text;
    this.interactButton.hidden = false;
  }

  /**
   * Transient message. Capped and auto-expiring: a stack of toasts that never
   * leaves covers the world the player is trying to walk through.
   */
  toast(message: string, tone: 'plain' | 'good' | 'bad' | 'sigil' = 'plain'): void {
    const node = el('div', `toast toast--${tone}`, message);
    this.toastRow.append(node);
    while (this.toastRow.childElementCount > 4) this.toastRow.firstElementChild?.remove();
    window.setTimeout(() => node.remove(), 3600);
  }

  dispose(): void {
    window.removeEventListener('resize', this.onResize);
    this.root.remove();
  }
}

/** Icon, track, numeral. The colour alone never has to carry the meaning. */
function vitalRow(kind: string, fill: HTMLElement, num: HTMLElement): HTMLElement {
  return el(
    'div',
    `vital vital--${kind}`,
    el('i', 'vital__icon'),
    el('div', 'meter meter--hud', fill),
    num
  );
}

function pinNode(pin: CompassCandidate): HTMLElement {
  const node = el(
    'div',
    `compass__pin compass__pin--${pin.kind}${pin.behind ? ' compass__pin--behind' : ''}`,
    el('div', 'compass__head', el('i', 'compass__dot'), el('span', 'compass__label', pin.label)),
    el('span', 'compass__distance', `${pin.distance} m`)
  );
  node.style.left = `${pin.centrePx}px`;
  return node;
}

function cardinalNode(mark: CardinalMark): HTMLElement {
  const node = el(
    'div',
    `compass__tick${mark.major ? ' compass__tick--major' : ''}`,
    mark.label
  );
  node.style.left = `${mark.centrePx}px`;
  return node;
}
