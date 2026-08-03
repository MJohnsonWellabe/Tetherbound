import { describe, expect, it } from 'vitest';
import {
  canTarget,
  harvestableBy,
  isHarvestable,
  nodeDef,
  rollDrops,
  swingsFor,
  type TargetKind
} from '../src/survival/Harvest';

describe('the no-weapon rule', () => {
  /**
   * docs/01_GAME_DESIGN.md pillar 2 and CLAUDE.md hard constraint 2: the player never
   * wields a weapon, and tools cannot target pals or people. This is the test
   * that has to keep passing forever, so it goes first.
   */
  const everyTool = ['stone_axe', 'stone_pick', 'flint_knife', 'hammer'];

  it('lets tools target world nodes', () => {
    for (const tool of everyTool) {
      expect(canTarget(tool, 'node')).toBe(true);
    }
  });

  it('refuses every tool against a pal', () => {
    for (const tool of everyTool) {
      expect(canTarget(tool, 'pal')).toBe(false);
    }
  });

  it('refuses every tool against an NPC', () => {
    for (const tool of everyTool) {
      expect(canTarget(tool, 'npc')).toBe(false);
    }
  });

  it('refuses every tool against the player', () => {
    for (const tool of everyTool) {
      expect(canTarget(tool, 'player')).toBe(false);
    }
  });

  it('refuses an unknown target kind rather than defaulting to allowed', () => {
    // A new entity type added later must be rejected until someone decides
    // otherwise, not silently become a valid target.
    expect(canTarget('stone_axe', 'wyrm' as TargetKind)).toBe(false);
  });

  it('refuses an unknown tool as well', () => {
    expect(canTarget('sword', 'node')).toBe(false);
    expect(canTarget('sword', 'pal')).toBe(false);
  });
});

describe('tool matching', () => {
  it('matches each node to the tool action that works on it', () => {
    expect(harvestableBy('oak', 'stone_axe')).toBe(true);
    expect(harvestableBy('rock', 'stone_pick')).toBe(true);
    expect(harvestableBy('bush', 'flint_knife')).toBe(true);
  });

  it('rejects the wrong tool for the node', () => {
    expect(harvestableBy('oak', 'stone_pick')).toBe(false);
    expect(harvestableBy('rock', 'flint_knife')).toBe(false);
    expect(harvestableBy('bush', 'stone_axe')).toBe(false);
  });

  it('rejects the hammer everywhere, since building is not harvesting', () => {
    for (const family of ['oak', 'pine', 'rock', 'bush']) {
      expect(harvestableBy(family, 'hammer')).toBe(false);
    }
  });

  it('rejects bare hands', () => {
    expect(harvestableBy('oak', null)).toBe(false);
    expect(harvestableBy('rock', null)).toBe(false);
  });

  it('reports non-harvestable families as such', () => {
    for (const family of ['grass', 'reed', 'flower']) {
      expect(isHarvestable(family)).toBe(false);
      expect(harvestableBy(family, 'stone_axe')).toBe(false);
      expect(nodeDef(family)).toBeUndefined();
    }
  });
});

describe('swing counts', () => {
  it('needs at least one swing for every harvestable node', () => {
    for (const family of ['oak', 'pine', 'rock', 'bush']) {
      expect(swingsFor(family)).toBeGreaterThanOrEqual(1);
    }
  });

  it('reports zero for something that cannot be harvested', () => {
    expect(swingsFor('grass')).toBe(0);
  });
});

describe('drops', () => {
  const KEY = 'oak:12,-4';

  it('is deterministic for a given node key and day', () => {
    const a = rollDrops('oak', KEY, 3);
    const b = rollDrops('oak', KEY, 3);
    expect(a).toEqual(b);
  });

  it('changes after the node respawns on a later day', () => {
    // Otherwise the same bush hands out identical berries forever, and a
    // player who learns one node learns them all.
    const day3 = rollDrops('bush', 'bush:1,1', 3);
    const day9 = rollDrops('bush', 'bush:1,1', 9);
    expect(day3).not.toEqual(day9);
  });

  it('differs between two nodes of the same family on the same day', () => {
    const a = rollDrops('oak', 'oak:0,0', 1);
    const b = rollDrops('oak', 'oak:5,5', 1);
    expect(a).not.toEqual(b);
  });

  it('stays inside the declared min and max for every drop', () => {
    // Sweep a lot of nodes rather than trusting one sample.
    for (let i = 0; i < 400; i++) {
      for (const family of ['oak', 'pine', 'rock', 'bush']) {
        const def = nodeDef(family);
        expect(def).toBeDefined();
        const drops = rollDrops(family, `${family}:${i},${i}`, i % 30);
        for (const drop of drops) {
          const spec = def?.drops.find((d) => d.id === drop.id);
          expect(spec).toBeDefined();
          expect(drop.n).toBeGreaterThanOrEqual(spec?.min ?? 0);
          expect(drop.n).toBeLessThanOrEqual(spec?.max ?? 0);
        }
      }
    }
  });

  it('never returns a zero-quantity stack', () => {
    // A drop that rolled 0 is absent, not present-with-nothing-in-it, or the
    // inventory fills with empty flint entries.
    for (let i = 0; i < 400; i++) {
      for (const drop of rollDrops('rock', `rock:${i},0`, 1)) {
        expect(drop.n).toBeGreaterThan(0);
      }
    }
  });

  it('always yields the guaranteed drop of a node', () => {
    // Rock's stone has min 2, so a rock that gives nothing is a bug.
    for (let i = 0; i < 200; i++) {
      const drops = rollDrops('rock', `rock:${i},7`, 2);
      expect(drops.some((d) => d.id === 'stone')).toBe(true);
    }
  });

  it('returns nothing for a family with no node definition', () => {
    expect(rollDrops('grass', 'grass:0,0', 1)).toEqual([]);
  });
});
