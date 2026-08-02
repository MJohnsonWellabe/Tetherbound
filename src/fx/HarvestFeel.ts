import { bus } from '../core/EventBus';
import fxData from '../data/fx.json';
import { itemDef } from '../survival/Inventory';
import type { Fx } from './Fx';

/**
 * Turns harvest events into feel.
 *
 * This exists as its own file so `main.ts` stays a wiring diagram and the feel
 * layer stays ignorant of harvesting. `Fx` knows how to shake and spray; this
 * knows that a felled oak is a `fell_wood`. Neither knows about the other's
 * internals, and M2 adds `CombatFeel.ts` beside this rather than editing it.
 *
 * A harvest swing is the same shape of moment as a combat hit: contact, a jolt,
 * debris, a sound, a number. Wiring the feel layer to harvesting now means M2
 * inherits something already tuned against a real interaction instead of
 * against an imagined one.
 */

interface HarvestFeelEntry {
  readonly swing: string;
  readonly fell: string;
}

const HARVEST = fxData.harvest as Record<string, HarvestFeelEntry | undefined>;

export function mountHarvestFeel(fx: Fx): () => void {
  const offSwing = bus.on('harvestSwing', ({ family, at }) => {
    const entry = HARVEST[family];
    if (entry) fx.impact(entry.swing, at.x, at.y, at.z);
  });

  const offFelled = bus.on('harvested', ({ family, drops, at }) => {
    const entry = HARVEST[family];
    if (entry) fx.impact(entry.fell, at.x, at.y, at.z);

    // One number per resource, stacked upward by spawn order. Summing them into
    // a single line would hide that a rock gave flint as well as stone, which
    // is the only feedback that flint exists at all.
    for (const drop of drops) {
      if (drop.n <= 0) continue;
      const name = itemDef(drop.id)?.name ?? drop.id;
      fx.number(`+${drop.n} ${name}`, at.x, at.y, at.z, 'gain');
    }
  });

  const offFainted = bus.on('playerFainted', ({ pos }) => {
    fx.impact('faint', pos.x, pos.y, pos.z);
  });

  return () => {
    offSwing();
    offFelled();
    offFainted();
  };
}
