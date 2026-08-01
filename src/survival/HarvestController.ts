import { bus } from '../core/EventBus';
import type { Intent } from '../core/input/Intent';
import type { PropBatcher, PropNode } from '../world/PropBatcher';
import {
  harvestableBy,
  isHarvestable,
  REACH_METERS,
  rollDrops,
  swingsFor
} from './Harvest';
import { add, itemDef, wearTool, type Slots } from './Inventory';

/**
 * Turns the interact intent into wood.
 *
 * Owns the equipped-tool selection and the per-node swing progress; the rules
 * themselves are pure functions in Harvest.ts. This file decides WHEN, that
 * file decides WHAT, and neither knows about the renderer.
 *
 * Swing progress is deliberately not persisted. A half-chopped tree resets when
 * the player walks away, which costs nothing and avoids putting per-node
 * mutable state into the save for a interaction that takes four seconds.
 */

export interface HarvestResult {
  node: PropNode;
  felled: boolean;
  drops: { id: string; n: number }[];
  /** Set when the swing could not happen, for the HUD to explain. */
  refusal?: 'no-tool' | 'wrong-tool' | 'no-stamina' | 'inventory-full' | 'broke';
}

export class HarvestController {
  /** Hotbar index of the equipped item. */
  equipped = 0;
  private progressKey: string | null = null;
  private progress = 0;

  constructor(
    private readonly slots: Slots,
    private readonly props: PropBatcher
  ) {}

  get equippedId(): string | null {
    return this.slots[this.equipped]?.id ?? null;
  }

  /**
   * One simulation step.
   *
   * `intent.slot` doubles as hotbar selection while exploring; in combat the
   * same input picks a party member, which is why CombatMode owns the mode flag
   * and this only ever runs outside a fight.
   */
  update(intent: Intent, x: number, z: number, day: number, stamina: number): HarvestResult | null {
    if (intent.slot !== null) this.equipped = intent.slot - 1;
    if (!intent.interact) return null;

    const node = this.nearestNode(x, z);
    if (!node) return null;

    const tool = this.equippedId;
    if (!tool) return this.refuse(node, 'no-tool');
    if (!harvestableBy(node.family, tool)) return this.refuse(node, 'wrong-tool');

    const cost = itemDef(tool)?.tool?.staminaCost ?? 0;
    if (stamina < cost) return this.refuse(node, 'no-stamina');

    // Starting a different node abandons the last one's progress.
    if (this.progressKey !== node.key) {
      this.progressKey = node.key;
      this.progress = 0;
    }
    this.progress++;

    const worn = wearTool(this.slots, this.equipped);
    if (worn === 'broke') {
      this.progressKey = null;
      this.progress = 0;
      return this.refuse(node, 'broke');
    }

    if (this.progress < swingsFor(node.family)) {
      bus.emit('harvestSwing', { key: node.key, progress: this.progress });
      return { node, felled: false, drops: [] };
    }

    const drops = rollDrops(node.family, node.key, day);
    const taken: { id: string; n: number }[] = [];
    let overflowed = false;
    for (const drop of drops) {
      const leftover = add(this.slots, drop.id, drop.n);
      if (leftover > 0) overflowed = true;
      if (drop.n - leftover > 0) taken.push({ id: drop.id, n: drop.n - leftover });
    }

    this.props.markHarvested(node);
    this.progressKey = null;
    this.progress = 0;

    const result: HarvestResult = { node, felled: true, drops: taken };
    // The node is gone either way. Losing the overflow is the cost of walking
    // around with a full satchel, and silently dropping it with no explanation
    // is how players conclude the game is broken.
    if (overflowed) result.refusal = 'inventory-full';
    bus.emit('harvested', { key: node.key, drops: taken });
    return result;
  }

  /** Nearest harvestable node inside reach, or null. */
  nearestNode(x: number, z: number): PropNode | null {
    for (const node of this.props.nodesNear(x, z, REACH_METERS)) {
      if (isHarvestable(node.family)) return node;
    }
    return null;
  }

  private refuse(node: PropNode, refusal: NonNullable<HarvestResult['refusal']>): HarvestResult {
    return { node, felled: false, drops: [], refusal };
  }
}
