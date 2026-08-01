import items from '../data/items.json';

/**
 * The satchel: 24 slots, stacking, with the first 6 doubling as the hotbar.
 *
 * Pure and engine-free. Slots are a fixed-length array with `null` holes
 * rather than a dense list, because slot POSITION is player-visible state:
 * dragging wood from slot 3 to slot 11 has to survive a save, and a dense
 * list would silently reshuffle everyone's satchel on load.
 */

export const SLOT_COUNT = 24;
export const HOTBAR_SLOTS = 6;

export interface ItemStack {
  id: string;
  n: number;
  /** Remaining durability. Only present on tools. */
  dur?: number;
}

export type Slots = (ItemStack | null)[];

interface ItemDef {
  name: string;
  kind: string;
  stack: number;
  tool?: { action: string; durability: number; power: number; staminaCost: number };
  food?: unknown;
  orb?: { ballMod: number };
  station?: { id: string };
}

const DEFS = items as unknown as Record<string, ItemDef>;

export function itemDef(id: string): ItemDef | undefined {
  return DEFS[id];
}

export function stackSize(id: string): number {
  return DEFS[id]?.stack ?? 1;
}

export function isTool(id: string): boolean {
  return DEFS[id]?.kind === 'tool';
}

export function createInventory(): Slots {
  return new Array<ItemStack | null>(SLOT_COUNT).fill(null);
}

export function count(slots: Slots, id: string): number {
  let n = 0;
  for (const s of slots) if (s && s.id === id) n += s.n;
  return n;
}

export function isFull(slots: Slots): boolean {
  return slots.every((s) => s !== null);
}

/**
 * Add items. Returns how many did NOT fit.
 *
 * Callers must handle the remainder rather than assume success: picking up
 * more than the satchel can hold is normal, and silently deleting the excess
 * is the kind of bug players notice only after losing something rare.
 *
 * Fills partial stacks before opening new slots, so a satchel does not end up
 * with three half-stacks of wood while claiming to be full.
 */
export function add(slots: Slots, id: string, n: number): number {
  if (n <= 0) return 0;
  const max = stackSize(id);
  let left = n;

  if (max > 1) {
    for (let i = 0; i < slots.length && left > 0; i++) {
      const s = slots[i];
      if (!s || s.id !== id || s.n >= max) continue;
      const room = max - s.n;
      const put = Math.min(room, left);
      s.n += put;
      left -= put;
    }
  }

  for (let i = 0; i < slots.length && left > 0; i++) {
    if (slots[i] !== null) continue;
    const put = Math.min(max, left);
    // A fresh tool enters at full durability. Without this a crafted axe would
    // arrive already broken, since `dur` would be undefined and read as 0.
    slots[i] = isTool(id)
      ? { id, n: put, dur: DEFS[id]?.tool?.durability ?? 1 }
      : { id, n: put };
    left -= put;
  }

  return left;
}

/**
 * Remove items. All-or-nothing: returns false and changes nothing when there
 * is not enough, so a craft can never half-consume its cost.
 */
export function remove(slots: Slots, id: string, n: number): boolean {
  if (n <= 0) return true;
  if (count(slots, id) < n) return false;

  let left = n;
  // Drain the smallest stacks first so the satchel consolidates rather than
  // accumulating a scatter of single items.
  const order = slots
    .map((s, i) => ({ s, i }))
    .filter((e) => e.s !== null && e.s.id === id)
    .sort((a, b) => (a.s?.n ?? 0) - (b.s?.n ?? 0));

  for (const { i } of order) {
    if (left <= 0) break;
    const s = slots[i];
    if (!s) continue;
    const take = Math.min(s.n, left);
    s.n -= take;
    left -= take;
    if (s.n <= 0) slots[i] = null;
  }
  return true;
}

/** True when `n` of `id` could be added without any remainder. */
export function hasRoomFor(slots: Slots, id: string, n: number): boolean {
  const max = stackSize(id);
  let room = 0;
  for (const s of slots) {
    if (s === null) room += max;
    else if (s.id === id && max > 1) room += max - s.n;
    if (room >= n) return true;
  }
  return room >= n;
}

/**
 * Move or merge one slot into another, for drag and drop.
 *
 * Merges when the two hold the same stackable item, swaps otherwise. Swapping
 * rather than refusing is deliberate: a player dragging onto an occupied slot
 * means "put it here", and a drag that silently does nothing feels broken.
 */
export function moveSlot(slots: Slots, from: number, to: number): void {
  if (from === to) return;
  if (from < 0 || to < 0 || from >= slots.length || to >= slots.length) return;

  const a = slots[from];
  if (!a) return;
  const b = slots[to];

  if (b && a.id === b.id && stackSize(a.id) > 1) {
    const room = stackSize(a.id) - b.n;
    const move = Math.min(room, a.n);
    b.n += move;
    a.n -= move;
    if (a.n <= 0) slots[from] = null;
    return;
  }

  slots[to] = a;
  slots[from] = b ?? null;
}

/**
 * Spend one point of durability on the tool in a slot. Returns 'broke' when
 * that was its last point, so the caller can play the sound and tell the
 * player rather than leaving them swinging at nothing.
 */
export function wearTool(slots: Slots, slot: number): 'ok' | 'broke' | 'none' {
  const s = slots[slot];
  if (!s || !isTool(s.id) || s.dur === undefined) return 'none';
  s.dur -= 1;
  if (s.dur <= 0) {
    slots[slot] = null;
    return 'broke';
  }
  return 'ok';
}

/** Everything in the satchel, flattened. Used by the satchel drop on faint. */
export function drain(slots: Slots): ItemStack[] {
  const out: ItemStack[] = [];
  for (let i = 0; i < slots.length; i++) {
    const s = slots[i];
    if (s) out.push({ ...s });
    slots[i] = null;
  }
  return out;
}
