import { bus } from '../core/EventBus';
import { add, isTool, type ItemStack, type Slots } from './Inventory';

/**
 * The faint drop.
 *
 * GAME_DESIGN.md section 4: at 0 health the player collapses and wakes at their
 * last bed. All inventory items drop into a Satchel marker at the faint
 * location. Pals are never dropped. Equipped tools are never dropped.
 *
 * Only ONE satchel exists at a time. A new faint moves the old contents to the
 * new marker rather than leaving a trail of them, which the design doc is
 * explicit about and which also stops a death loop from scattering a player's
 * whole run across the map.
 *
 * PURE. The marker mesh lives in world/StationViews.ts, because src/survival
 * must run headless and tests/bundle.test.ts enforces it.
 */

export interface SatchelContents {
  x: number;
  y: number;
  z: number;
  items: ItemStack[];
}

export class Satchel {
  private contents: SatchelContents | null = null;

  get marker(): SatchelContents | null {
    return this.contents;
  }

  /**
   * Drop the player's satchel here.
   *
   * Tools are kept, so a player who dies far from home can still chop their way
   * back rather than being stranded with nothing.
   */
  drop(slots: Slots, x: number, y: number, z: number): void {
    // Walk the slots directly rather than draining and filtering. drain()
    // empties everything, so filtering its result would silently destroy the
    // tools instead of keeping them.
    const dropped: ItemStack[] = [];
    for (let i = 0; i < slots.length; i++) {
      const stack = slots[i];
      if (!stack || isTool(stack.id)) continue;
      dropped.push(stack);
      slots[i] = null;
    }

    // A second faint moves the old contents to the new marker rather than
    // leaving two, per section 4.
    const carried = this.contents?.items ?? [];

    this.contents = { x, y, z, items: [...carried, ...dropped] };
    bus.emit('satchelDropped', { x, y, z, count: this.contents.items.length });
  }

  /** Collect it. Anything that does not fit stays in the satchel. */
  collect(slots: Slots): number {
    if (!this.contents) return 0;
    let taken = 0;
    const leftovers: ItemStack[] = [];
    for (const stack of this.contents.items) {
      const remaining = add(slots, stack.id, stack.n);
      taken += stack.n - remaining;
      if (remaining > 0) leftovers.push({ id: stack.id, n: remaining });
    }
    if (leftovers.length === 0) {
      this.clear();
    } else {
      this.contents = { ...this.contents, items: leftovers };
    }
    return taken;
  }

  private clear(): void {
    this.contents = null;
  }

  restore(contents: SatchelContents | null): void {
    this.contents = contents;
  }

}
