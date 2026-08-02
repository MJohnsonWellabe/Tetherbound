import type { HarvestController, HarvestResult } from '../survival/HarvestController';
import { harvestableBy, isHarvestable } from '../survival/Harvest';
import { itemDef } from '../survival/Inventory';
import type { VitalsState } from '../survival/Vitals';

/**
 * The gathering readout: what is equipped, what you just got, and what the
 * thing in front of you wants.
 *
 * Two elements, deliberately. The equipped tool and the last pickup are
 * PERSISTENT state and sit in the corner chip. The "press E to chop" line is
 * TRANSIENT and gets its own prompt above the hotbar in lime, because when the
 * two shared one centred line the result read as
 * `HP 100/100 ST 100/100 FD 100 Stone Axe bush needs a knife` and nothing in it
 * could be told apart. The numeric vitals are gone entirely: the HUD bars carry
 * them now.
 */

const REFUSALS: Record<NonNullable<HarvestResult['refusal']>, string> = {
  'no-tool': 'Nothing equipped',
  'wrong-tool': 'Wrong tool for that',
  'no-stamina': 'Too tired',
  'inventory-full': 'Satchel full, some was lost',
  broke: 'Your tool broke'
};

/** How long a pickup or refusal line stays up, in fixed steps (60 = 1s). */
const MESSAGE_STEPS = 150;

export class HarvestHud {
  private message = '';
  private messageSteps = 0;
  private lastPaint = '';
  private lastPrompt = '';

  private readonly promptEl: HTMLElement;

  constructor(
    private readonly el: HTMLElement,
    private readonly harvest: HarvestController
  ) {
    this.promptEl = document.createElement('div');
    this.promptEl.className = 'prompt';
    this.promptEl.hidden = true;
    (el.parentElement ?? document.body).append(this.promptEl);
  }

  report(result: HarvestResult | null): void {
    if (!result) return;
    if (result.refusal) {
      this.message = REFUSALS[result.refusal];
      this.messageSteps = MESSAGE_STEPS;
      return;
    }
    if (result.felled && result.drops.length > 0) {
      this.message = result.drops
        .map((d) => `+${d.n} ${itemDef(d.id)?.name ?? d.id}`)
        .join('   ');
      this.messageSteps = MESSAGE_STEPS;
    }
  }

  /** Called once per fixed step. */
  update(x: number, z: number, _vitals: VitalsState): void {
    if (this.messageSteps > 0) this.messageSteps--;

    const tool = this.harvest.equippedId;
    const held = tool ? (itemDef(tool)?.name ?? tool) : 'Empty hands';

    const text = [held, this.messageSteps > 0 ? this.message : ''].filter(Boolean).join('   ');
    if (text !== this.lastPaint) {
      this.lastPaint = text;
      this.el.textContent = text;
    }

    this.paintPrompt(this.harvest.nearestNode(x, z));
  }

  /**
   * Lime means "you can act on this" per tokens.css, so a node you cannot work
   * yet must not borrow it. The blocked variant stays neutral.
   */
  private paintPrompt(node: { family: string } | null): void {
    let text = '';
    let blocked = false;
    if (node && isHarvestable(node.family)) {
      const tool = this.harvest.equippedId;
      if (harvestableBy(node.family, tool)) {
        text = `E   ${verbFor(node.family)} ${node.family}`;
      } else {
        text = `${node.family} needs ${actionName(node.family)}`;
        blocked = true;
      }
    }

    const key = `${blocked ? 'x' : 'o'}${text}`;
    if (key === this.lastPrompt) return;
    this.lastPrompt = key;
    this.promptEl.textContent = text;
    this.promptEl.hidden = text === '';
    this.promptEl.classList.toggle('prompt--blocked', blocked);
  }

  dispose(): void {
    this.promptEl.remove();
  }
}

function verbFor(family: string): string {
  if (family === 'rock') return 'Mine';
  if (family === 'bush') return 'Cut';
  return 'Chop';
}

function actionName(family: string): string {
  if (family === 'rock') return 'a pick';
  if (family === 'bush') return 'a knife';
  return 'an axe';
}
