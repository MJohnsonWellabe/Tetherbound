import type { HarvestController, HarvestResult } from '../survival/HarvestController';
import { harvestableBy, isHarvestable } from '../survival/Harvest';
import { itemDef } from '../survival/Inventory';
import { maxHealth, maxStamina, type VitalsState } from '../survival/Vitals';

/**
 * The gathering readout: what is equipped, what is in reach, what you just got.
 *
 * Minimal on purpose. M1's real inventory screen replaces this; until then it
 * is the only way to tell that harvesting works at all, and a system you cannot
 * see is a system you cannot test.
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

  constructor(
    private readonly el: HTMLElement,
    private readonly harvest: HarvestController
  ) {}

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
  update(x: number, z: number, vitals: VitalsState): void {
    if (this.messageSteps > 0) this.messageSteps--;

    const vit = [
      `HP ${Math.round(vitals.health)}/${Math.round(maxHealth(vitals))}`,
      `ST ${Math.round(vitals.stamina)}/${Math.round(maxStamina(vitals))}`,
      `FD ${Math.round(vitals.hunger)}`
    ].join('  ');

    const tool = this.harvest.equippedId;
    const held = tool ? (itemDef(tool)?.name ?? tool) : 'Empty hands';

    const node = this.harvest.nearestNode(x, z);
    let prompt = '';
    if (node && isHarvestable(node.family)) {
      prompt = harvestableBy(node.family, tool)
        ? `E  ${verbFor(node.family)} ${node.family}`
        : `${node.family} needs ${actionName(node.family)}`;
    }

    const text = [vit, held, prompt, this.messageSteps > 0 ? this.message : '']
      .filter(Boolean)
      .join('     ');
    if (text === this.lastPaint) return;
    this.lastPaint = text;
    this.el.textContent = text;
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
