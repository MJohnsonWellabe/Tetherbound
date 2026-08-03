import landmarks from '../data/landmarks.json';
import { hallPlacement, stonesPlacement, villageHousePlacements } from './Landmarks';
import type { Terrain } from './gen/Terrain';

/**
 * Ground the scatter is not allowed to plant on.
 *
 * Hollowbrook, the standing stones and the Hall are placed on top of a world
 * that has already decided where its trees go, and nothing told the scatter to
 * get out of the way. The result was oaks growing through the roofs of the
 * village and, worse, one directly on the spawn point: a new player's first
 * frame was the inside of a tree canopy.
 *
 * This is a mask rather than a post-placement cull because `Scatter.ts` applies
 * its mask BEFORE the spacing scan. Culling afterwards would leave the removed
 * candidates still suppressing their neighbours, which punches a bald ring
 * around every landmark instead of a clean edge (the same reasoning as the
 * river mask, see the comment in scatterInRect).
 *
 * Clearings are derived from the same seeded placements the buildings use, so
 * this needs no state of its own and cannot drift out of sync with them.
 *
 * The village clearing below is centred on the settlement as a whole, so it
 * only reaches ground cover (grass, flowers, reeds) within a fraction of the
 * village radius: a village-sized bald patch of dirt looks worse than a few
 * blades of grass near a fence. But the houses themselves sit on a ring at
 * `radius * 0.55`, outside that ground-cover reach, so that alone still let
 * scatter plant grass and flowers straight through house floors. Each house
 * gets its own tight clearing below, sized to its own footprint, which
 * suppresses every family including ground cover: there is no version of a
 * lawn growing up through the floorboards that reads as intentional.
 */

interface Clearing {
  x: number;
  z: number;
  /** Metres. Props inside this are suppressed entirely. */
  radius: number;
  /** Ground cover survives closer in than trees; a lawn is not a bald patch. */
  groundRadius: number;
}

/** Families small enough to keep growing right up to a wall. */
const GROUND_COVER = new Set(['grass', 'flower', 'reed']);

let cache: { seed: string; clearings: Clearing[] } | null = null;

export function clearingsFor(terrain: Terrain, seed: string): Clearing[] {
  if (cache && cache.seed === seed) return cache.clearings;

  const hall = hallPlacement(terrain, seed);
  const stones = stonesPlacement(terrain, seed);
  const houses = villageHousePlacements(terrain, seed);
  const margin = landmarks.village.houseClearingMargin as number;
  const villagePad = landmarks.village.treeClearingFraction as number;
  const villageGroundFraction = landmarks.village.groundClearingFraction as number;

  const clearings: Clearing[] = [
    {
      x: landmarks.village.at[0] as number,
      z: landmarks.village.at[1] as number,
      // A little wider than the village itself, so the tree line reads as the
      // edge of the settlement rather than as a wall of trunks against it.
      //
      // The village-wide GROUND radius is now 0. It was 0.45 of the village
      // radius, 18.9m, and it is the single reason the player's first frame was
      // a bald plane: the spawn sits inside it and terrain is flattened to a
      // literal plane out to 55m, so the opening shot had no ground cover AND
      // no form. The per-house clearings below already keep grass out of the
      // floorboards, sized to each house's own footprint, so this one was doing
      // nothing except emptying the view.
      radius: (landmarks.village.radius as number) * villagePad,
      groundRadius: (landmarks.village.radius as number) * villageGroundFraction
    },
    {
      x: hall.x,
      z: hall.z,
      radius: 46,
      groundRadius: 20
    },
    {
      x: stones.x,
      z: stones.z,
      // The stones are a ring in open meadow. Trees crowding them hides the
      // one landmark the player is told to walk to.
      radius: 30,
      groundRadius: 14
    },
    // One clearing per house, sized to that house's own footprint rather than
    // the village as a whole. `radius === groundRadius`: unlike the wider
    // clearings above, ground cover has to go too, or grass and flowers still
    // plant themselves inside the walls this ring's own houses stand on.
    ...houses.map((h): Clearing => {
      const halfDiagonal = Math.hypot(h.width, h.depth) / 2;
      const radius = halfDiagonal + margin;
      return { x: h.x, z: h.z, radius, groundRadius: radius };
    })
  ];

  cache = { seed, clearings };
  return clearings;
}

/** True when this family may be planted here. */
export function allowedInClearings(
  clearings: readonly Clearing[],
  family: string,
  x: number,
  z: number
): boolean {
  const cover = GROUND_COVER.has(family);
  for (const c of clearings) {
    const r = cover ? c.groundRadius : c.radius;
    const dx = x - c.x;
    const dz = z - c.z;
    if (dx * dx + dz * dz < r * r) return false;
  }
  return true;
}

/** Drop the memoised placements. Only a seed change needs this. */
export function resetClearings(): void {
  cache = null;
}
