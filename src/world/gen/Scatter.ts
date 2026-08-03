import { hashSeed, mulberry32 } from './Rng';

/**
 * Blue-noise prop placement that is independent of chunk traversal order.
 *
 * The obvious implementation runs Bridson's Poisson-disk algorithm inside each
 * chunk, and it is wrong in a way that is easy to miss until you walk the
 * world: samples are only spaced against others in the same chunk, so props
 * clump along every chunk seam. Worse, the result depends on which chunks
 * happen to be resident, so walking away and back regenerates a different
 * layout, and a save that stores "harvested node #7" points at a different
 * bush.
 *
 * So this works on a GLOBAL jittered grid instead:
 *
 *   - The world is divided into cells of `minDistance / sqrt(2)`, globally,
 *     with no reference to chunks.
 *   - Each cell derives one candidate point and one priority value from
 *     hash(seed, cellX, cellZ). Both are pure functions of global coordinates.
 *   - A candidate survives if no higher-priority candidate within `minDistance`
 *     exists in the surrounding neighbourhood.
 *
 * Because acceptance compares against a fixed neighbourhood using a
 * deterministic priority, it is order-independent: a cell resolves the same
 * whether it is evaluated first, last, or in a chunk loaded on its own. Chunk
 * seams stop existing as a concept. The cost is one hash per neighbour cell,
 * which is cheap and, unlike Bridson, needs no shared mutable grid.
 *
 * Pure and engine-free. The renderer half lives in world/PropBatcher.ts.
 */

/** Cells within this radius are checked for a higher-priority neighbour. */
const NEIGHBOURHOOD = 2;

export interface ScatterPoint {
  x: number;
  z: number;
  /** Stable identifier, derived from the cell. Survives across sessions, so
   *  worldDeltas can record "this bush was harvested" and mean it. */
  key: string;
  /** 0..1, uniform. Use for variant, scale and rotation choices. */
  roll: number;
  /** Rotation in radians. */
  rotation: number;
  /** 0..1, uniform, INDEPENDENT of `roll`. Drives per-instance colour.
   *
   *  Its own draw rather than a reuse of `roll` for the reason stated below on
   *  thinning: `roll` already picks scale and doubles as the density coin flip,
   *  so tinting from it would make every big oak the pale one. */
  tint: number;
}

function cellPoint(
  seed: string,
  label: string,
  cellX: number,
  cellZ: number,
  cellSize: number
): { x: number; z: number; priority: number; roll: number; rotation: number; tint: number } {
  const rng = mulberry32(hashSeed(`${seed}:${label}`, cellX, cellZ));
  const jitterX = rng();
  const jitterZ = rng();
  const priority = rng();
  const roll = rng();
  const rotation = rng() * Math.PI * 2;
  // APPENDED, never inserted. Every draw above keeps its position in the
  // sequence, so every existing seed still generates the identical world and
  // every saved harvest key still points at the same bush. Inserting a draw
  // here would silently regenerate the whole world and orphan every delta.
  const tint = rng();
  return {
    x: (cellX + jitterX) * cellSize,
    z: (cellZ + jitterZ) * cellSize,
    priority,
    roll,
    rotation,
    tint
  };
}

export interface ScatterOptions {
  seed: string;
  /** Names the pass, so trees and rocks do not land on identical points. */
  label: string;
  /** Minimum spacing in meters. */
  minDistance: number;
  /**
   * Hard exclusion. False means no prop may ever exist here: water, cliffs,
   * the village footprint, the road.
   *
   * Applied BEFORE spacing, so an excluded candidate never suppresses a valid
   * neighbour. Filtering these out afterwards instead would let a candidate
   * standing in a river suppress the tree on the bank and punch a bald ring
   * around every shoreline.
   */
  mask?: (x: number, z: number) => boolean;
  /**
   * Thinning, 0..1. How much of the allowed population actually appears.
   *
   * Applied AFTER spacing, which is the only way it can control the count.
   * Thinning candidates beforehand does almost nothing, because minimum
   * spacing is the binding constraint: removing half the candidates simply
   * lets the survivors close ranks. Measured, a pre-filter at 0.5 took 837
   * points down to 830.
   *
   * Post-filtering leaves the survivors at irregular spacing rather than a
   * uniform lattice, which is what a thinner stand of trees should look like.
   */
  density?: (x: number, z: number) => number;
}

/**
 * Scatter points inside an axis-aligned rectangle.
 *
 * Callers pass chunk bounds, but nothing about the result depends on those
 * bounds beyond which points fall inside them.
 */
export function scatterInRect(
  opts: ScatterOptions,
  minX: number,
  minZ: number,
  maxX: number,
  maxZ: number
): ScatterPoint[] {
  const { seed, label, minDistance, mask, density } = opts;
  const cellSize = minDistance / Math.SQRT2;
  const allowed = (x: number, z: number): boolean => (mask ? mask(x, z) : true);

  const c0x = Math.floor(minX / cellSize);
  const c0z = Math.floor(minZ / cellSize);
  const c1x = Math.floor(maxX / cellSize);
  const c1z = Math.floor(maxZ / cellSize);

  const out: ScatterPoint[] = [];
  const minDistSq = minDistance * minDistance;

  for (let cz = c0z; cz <= c1z; cz++) {
    for (let cx = c0x; cx <= c1x; cx++) {
      const candidate = cellPoint(seed, label, cx, cz, cellSize);
      if (candidate.x < minX || candidate.x >= maxX) continue;
      if (candidate.z < minZ || candidate.z >= maxZ) continue;

      // The hard mask gates before the neighbour scan, so excluded ground
      // neither hosts a prop nor suppresses one nearby.
      if (!allowed(candidate.x, candidate.z)) continue;

      let beaten = false;
      for (let nz = cz - NEIGHBOURHOOD; nz <= cz + NEIGHBOURHOOD && !beaten; nz++) {
        for (let nx = cx - NEIGHBOURHOOD; nx <= cx + NEIGHBOURHOOD; nx++) {
          if (nx === cx && nz === cz) continue;
          const other = cellPoint(seed, label, nx, nz, cellSize);
          // Only candidates on legal ground compete. Note this deliberately
          // ignores `density`: suppression must not depend on the thinning
          // roll, or two chunks could disagree about who won.
          if (!allowed(other.x, other.z)) continue;

          const dx = other.x - candidate.x;
          const dz = other.z - candidate.z;
          if (dx * dx + dz * dz >= minDistSq) continue;

          // Strictly greater, with the cell coordinates breaking an exact tie,
          // so two candidates can never suppress each other and leave a gap.
          if (
            other.priority > candidate.priority ||
            (other.priority === candidate.priority && (nz > cz || (nz === cz && nx > cx)))
          ) {
            beaten = true;
            break;
          }
        }
      }
      if (beaten) continue;

      // Thinning last. `roll` doubles as the coin flip rather than drawing a
      // fresh number, so a pass cannot end up with density correlated to
      // variant choice ("every rare tree is on a hilltop").
      if (density) {
        const keep = density(candidate.x, candidate.z);
        if (keep <= 0) continue;
        if (keep < 1 && candidate.roll >= keep) continue;
      }

      out.push({
        x: candidate.x,
        z: candidate.z,
        key: `${label}:${cx},${cz}`,
        roll: candidate.roll,
        rotation: candidate.rotation,
        tint: candidate.tint
      });
    }
  }

  return out;
}
