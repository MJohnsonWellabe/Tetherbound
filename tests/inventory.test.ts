import { describe, expect, it } from 'vitest';
import {
  add,
  count,
  createInventory,
  drain,
  hasRoomFor,
  isFull,
  moveSlot,
  remove,
  SLOT_COUNT,
  stackSize,
  wearTool
} from '../src/survival/Inventory';
import { canCraft, craft, type CraftContext } from '../src/survival/Crafting';

const ANYWHERE: CraftContext = { station: null, hasRoof: false, flags: [] };
const AT_CAMPFIRE: CraftContext = { station: 'campfire', hasRoof: false, flags: [] };
const AT_BENCH: CraftContext = { station: 'workbench', hasRoof: false, flags: [] };

describe('inventory basics', () => {
  it('starts with 24 empty slots', () => {
    const inv = createInventory();
    expect(inv.length).toBe(SLOT_COUNT);
    expect(inv.every((s) => s === null)).toBe(true);
  });

  it('adds and counts', () => {
    const inv = createInventory();
    expect(add(inv, 'wood', 10)).toBe(0);
    expect(count(inv, 'wood')).toBe(10);
  });

  it('fills partial stacks before opening new slots', () => {
    // Otherwise a satchel ends up with three half-stacks of wood while
    // claiming to be full.
    const inv = createInventory();
    add(inv, 'wood', 30);
    add(inv, 'wood', 10);
    expect(inv.filter((s) => s?.id === 'wood').length).toBe(1);
    expect(count(inv, 'wood')).toBe(40);
  });

  it('spills into a second slot past the stack size', () => {
    const inv = createInventory();
    const max = stackSize('wood');
    add(inv, 'wood', max + 5);
    expect(inv.filter((s) => s?.id === 'wood').length).toBe(2);
    expect(count(inv, 'wood')).toBe(max + 5);
  });

  it('reports what did not fit rather than deleting it', () => {
    // Silently dropping the excess is the bug players only notice after
    // losing something rare.
    const inv = createInventory();
    const max = stackSize('wood');
    const capacity = SLOT_COUNT * max;
    const leftover = add(inv, 'wood', capacity + 17);
    expect(leftover).toBe(17);
    expect(count(inv, 'wood')).toBe(capacity);
    expect(isFull(inv)).toBe(true);
  });

  it('gives each tool its own slot', () => {
    const inv = createInventory();
    add(inv, 'stone_axe', 3);
    expect(inv.filter((s) => s?.id === 'stone_axe').length).toBe(3);
  });

  it('gives a new tool full durability', () => {
    // Without this a crafted axe arrives already broken, because undefined
    // durability reads as zero on the first swing.
    const inv = createInventory();
    add(inv, 'stone_axe', 1);
    const axe = inv.find((s) => s?.id === 'stone_axe');
    expect(axe?.dur).toBeGreaterThan(0);
  });
});

describe('removal', () => {
  it('removes across multiple stacks', () => {
    const inv = createInventory();
    add(inv, 'wood', stackSize('wood') + 20);
    expect(remove(inv, 'wood', 60)).toBe(true);
    expect(count(inv, 'wood')).toBe(stackSize('wood') + 20 - 60);
  });

  it('is all-or-nothing when there is not enough', () => {
    // A craft must never half-consume its cost.
    const inv = createInventory();
    add(inv, 'wood', 5);
    expect(remove(inv, 'wood', 9)).toBe(false);
    expect(count(inv, 'wood')).toBe(5);
  });

  it('frees the slot when a stack empties', () => {
    const inv = createInventory();
    add(inv, 'wood', 4);
    remove(inv, 'wood', 4);
    expect(inv.every((s) => s === null)).toBe(true);
  });

  it('consolidates by draining the smallest stacks first', () => {
    const inv = createInventory();
    const max = stackSize('wood');
    add(inv, 'wood', max + 3);
    remove(inv, 'wood', 3);
    expect(inv.filter((s) => s?.id === 'wood').length).toBe(1);
  });
});

describe('slot moves', () => {
  it('moves into an empty slot', () => {
    const inv = createInventory();
    add(inv, 'wood', 5);
    moveSlot(inv, 0, 9);
    expect(inv[0]).toBeNull();
    expect(inv[9]?.id).toBe('wood');
  });

  it('merges two stacks of the same item', () => {
    const inv = createInventory();
    inv[0] = { id: 'wood', n: 10 };
    inv[1] = { id: 'wood', n: 5 };
    moveSlot(inv, 0, 1);
    expect(inv[1]?.n).toBe(15);
    expect(inv[0]).toBeNull();
  });

  it('respects the stack ceiling when merging', () => {
    const inv = createInventory();
    const max = stackSize('wood');
    inv[0] = { id: 'wood', n: max };
    inv[1] = { id: 'wood', n: max - 2 };
    moveSlot(inv, 0, 1);
    expect(inv[1]?.n).toBe(max);
    expect(inv[0]?.n).toBe(max - 2);
  });

  it('swaps different items rather than refusing', () => {
    // A drag that silently does nothing feels broken.
    const inv = createInventory();
    inv[0] = { id: 'wood', n: 5 };
    inv[1] = { id: 'stone', n: 3 };
    moveSlot(inv, 0, 1);
    expect(inv[0]?.id).toBe('stone');
    expect(inv[1]?.id).toBe('wood');
  });

  it('ignores out-of-range and no-op moves', () => {
    const inv = createInventory();
    add(inv, 'wood', 5);
    moveSlot(inv, 0, 0);
    moveSlot(inv, 0, 99);
    moveSlot(inv, -1, 3);
    expect(count(inv, 'wood')).toBe(5);
  });
});

describe('tool durability', () => {
  it('wears down and eventually breaks', () => {
    const inv = createInventory();
    add(inv, 'flint_knife', 1);
    const total = inv[0]?.dur ?? 0;
    expect(total).toBeGreaterThan(0);
    for (let i = 0; i < total - 1; i++) expect(wearTool(inv, 0)).toBe('ok');
    expect(wearTool(inv, 0)).toBe('broke');
    expect(inv[0]).toBeNull();
  });

  it('reports none for a slot with no tool', () => {
    const inv = createInventory();
    add(inv, 'wood', 3);
    expect(wearTool(inv, 0)).toBe('none');
    expect(wearTool(inv, 5)).toBe('none');
  });
});

describe('hasRoomFor and drain', () => {
  it('knows when there is no room', () => {
    const inv = createInventory();
    add(inv, 'wood', SLOT_COUNT * stackSize('wood'));
    expect(hasRoomFor(inv, 'stone', 1)).toBe(false);
    expect(hasRoomFor(inv, 'wood', 1)).toBe(false);
  });

  it('empties the satchel and hands back the contents', () => {
    const inv = createInventory();
    add(inv, 'wood', 12);
    add(inv, 'stone', 4);
    const dropped = drain(inv);
    expect(inv.every((s) => s === null)).toBe(true);
    expect(dropped.reduce((n, s) => n + s.n, 0)).toBe(16);
  });
});

describe('crafting', () => {
  it('crafts a stone axe by hand from real costs', () => {
    const inv = createInventory();
    add(inv, 'wood', 4);
    add(inv, 'stone', 2);
    expect(craft(inv, 'stone_axe', ANYWHERE).ok).toBe(true);
    expect(count(inv, 'stone_axe')).toBe(1);
    expect(count(inv, 'wood')).toBe(0);
    expect(count(inv, 'stone')).toBe(0);
  });

  it('reports exactly what is missing', () => {
    const inv = createInventory();
    add(inv, 'wood', 2);
    const check = canCraft(inv, 'stone_axe', ANYWHERE);
    expect(check.ok).toBe(false);
    if (!check.ok && check.block.reason === 'missing-ingredients') {
      expect(check.block.missing).toEqual([
        { id: 'wood', n: 2 },
        { id: 'stone', n: 2 }
      ]);
    } else {
      throw new Error('expected missing-ingredients');
    }
  });

  it('consumes nothing on a failed craft', () => {
    const inv = createInventory();
    add(inv, 'wood', 2);
    craft(inv, 'stone_axe', ANYWHERE);
    expect(count(inv, 'wood')).toBe(2);
  });

  it('requires the right station', () => {
    const inv = createInventory();
    add(inv, 'raw_meat', 1);
    const away = canCraft(inv, 'grilled_meat', ANYWHERE);
    expect(away.ok).toBe(false);
    if (!away.ok && away.block.reason === 'wrong-station') {
      expect(away.block.needs).toBe('campfire');
    } else {
      throw new Error('expected wrong-station');
    }
    expect(craft(inv, 'grilled_meat', AT_CAMPFIRE).ok).toBe(true);
  });

  it('names the station before the ingredients', () => {
    // Standing in a field holding meat, "you need a campfire" is the useful
    // message and "you need 2 raw meat" is not.
    const inv = createInventory();
    const check = canCraft(inv, 'grilled_meat', ANYWHERE);
    expect(check.ok).toBe(false);
    if (!check.ok) expect(check.block.reason).toBe('wrong-station');
  });

  it('enforces the roof gate for tier two', () => {
    const inv = createInventory();
    add(inv, 'raw_meat', 2);
    add(inv, 'mushroom', 2);
    add(inv, 'berries', 3);
    const open = canCraft(inv, 'meadow_stew', AT_CAMPFIRE);
    expect(open.ok).toBe(false);
    if (!open.ok) expect(open.block.reason).toBe('needs-roof');
    expect(craft(inv, 'meadow_stew', { ...AT_CAMPFIRE, hasRoof: true }).ok).toBe(true);
  });

  it('locks recipes behind progress flags', () => {
    const inv = createInventory();
    add(inv, 'leather', 2);
    add(inv, 'amber', 1);
    add(inv, 'stone', 3);
    const locked = canCraft(inv, 'truestone_orb', { station: 'orb_bench', hasRoof: true, flags: [] });
    expect(locked.ok).toBe(false);
    if (!locked.ok && locked.block.reason === 'locked') {
      expect(locked.block.flag).toBe('badge_meadow');
    } else {
      throw new Error('expected locked');
    }
    expect(
      craft(inv, 'truestone_orb', {
        station: 'orb_bench',
        hasRoof: true,
        flags: ['badge_meadow']
      }).ok
    ).toBe(true);
  });

  it('refuses to consume ingredients when the output has nowhere to go', () => {
    // The bug this prevents: eat the cost, fail to place the result, and the
    // player has paid for nothing.
    const inv = createInventory();
    for (let i = 0; i < SLOT_COUNT; i++) inv[i] = { id: 'stone', n: 1 };
    inv[0] = { id: 'wood', n: 4 };
    inv[1] = { id: 'stone', n: 2 };
    const check = canCraft(inv, 'stone_axe', ANYWHERE);
    expect(check.ok).toBe(false);
    if (!check.ok) expect(check.block.reason).toBe('no-room');
    expect(count(inv, 'wood')).toBe(4);
  });

  it('rejects an unknown recipe', () => {
    const check = canCraft(createInventory(), 'dragon', ANYWHERE);
    expect(check.ok).toBe(false);
    if (!check.ok) expect(check.block.reason).toBe('unknown-recipe');
  });

  it('never treats a $comment key as a recipe', () => {
    // The data files carry $comment keys for the next reader. Leaking one into
    // the crafting panel as a broken entry would be an embarrassing way to
    // discover that.
    const check = canCraft(createInventory(), '$comment', ANYWHERE);
    expect(check.ok).toBe(false);
    if (!check.ok) expect(check.block.reason).toBe('unknown-recipe');
  });

  it('crafts a bed at the workbench', () => {
    const inv = createInventory();
    add(inv, 'wood', 8);
    add(inv, 'fiber', 12);
    expect(craft(inv, 'bed', AT_BENCH).ok).toBe(true);
    expect(count(inv, 'bed')).toBe(1);
  });
});
