import models from '../data/models.json';
import type { PropFamilyId } from './Prototypes';

/**
 * Decide, per prop family, whether the batcher gets a real model or the
 * primitive fallback. Pure: takes the set of URLs that actually loaded,
 * returns the plan. The renderer half (PropModels.ts) executes it.
 *
 * The fallback is per FAMILY, not all-or-nothing: one corrupt tree file
 * costs cone trees, not a primitive world.
 */

export interface PropVariant {
  url: string;
  scale: number;
}

export interface FamilyPlan {
  family: PropFamilyId;
  source: 'model' | 'primitive';
  /** Set when source is 'model'. */
  variant?: PropVariant;
}

interface PropsData {
  [family: string]: { variants: PropVariant[] };
}

export const PROP_FAMILIES: PropFamilyId[] = [
  'oak',
  'pine',
  'rock',
  'bush',
  'grass',
  'reed',
  'flower'
];

/** Every URL the prop system wants loaded. */
export function propUrls(): string[] {
  const props = models.props as PropsData;
  const urls: string[] = [];
  for (const family of PROP_FAMILIES) {
    const first = props[family]?.variants[0];
    if (first) urls.push(first.url);
  }
  return urls;
}

/**
 * `loaded` maps url -> whether a usable container arrived. Anything absent
 * or false falls back to the primitive for that family only.
 */
export function planProps(loaded: ReadonlyMap<string, boolean>): FamilyPlan[] {
  const props = models.props as PropsData;
  return PROP_FAMILIES.map((family) => {
    const variant = props[family]?.variants[0];
    if (variant && loaded.get(variant.url) === true) {
      return { family, source: 'model' as const, variant };
    }
    return { family, source: 'primitive' as const };
  });
}
