import { Matrix, Mesh, Quaternion, Vector3 } from '../core/babylon';
import { scatterInRect } from './gen/Scatter';
import { allowedInClearings, clearingsFor } from './Clearings';
import type { BiomeKind, Terrain } from './gen/Terrain';
import type { PropFamilyId, PrototypeSet } from './Prototypes';

/**
 * Builds one (family x spatial cell) batch: its geometry, its colliders and
 * its harvest nodes.
 *
 * Separated from PropBatcher so that file can stay about residency and queries
 * rather than about matrix composition. See PropBatcher.ts for why props are
 * grouped by family cell rather than by terrain chunk.
 */

export interface PropCollider {
  x: number;
  z: number;
  radius: number;
}

/** A harvestable prop instance. Keyed so worldDeltas can record it. */
export interface PropNode {
  key: string;
  family: PropFamilyId;
  resource: string;
  x: number;
  y: number;
  z: number;
  /** The family's cell size, so a harvest can find the cell to rebuild. */
  cellSize: number;
}

/** One family's entry in scatter.json. */
export interface FamilyConfig {
  id: string;
  minDistance: number;
  drawDistance: number;
  cellSize: number;
  castsShadow: boolean;
  shadowDistance: number;
  collisionRadius: number;
  harvest: string | null;
  biomes: string[];
  maxSlope: number;
  density: Record<string, number>;
  scaleRange: number[];
  /** Per-instance colour, multiplied onto the model's baked vertex colours.
   *  `base` re-tints the whole family (the kit models ship a cold cyan-green
   *  that fights the ground); `value` and `warm` are the half-widths of the
   *  per-instance spread either side of it. Absent means untinted. */
  tint?: { base: number[]; value: number; warm: number };
}

export interface PropCell {
  readonly family: FamilyConfig;
  mesh: Mesh | null;
  colliders: PropCollider[];
  nodes: PropNode[];
  /** Cell centre, for distance culls. */
  readonly cx: number;
  readonly cz: number;
  /** Whether this cell is currently registered as a shadow caster. */
  casting: boolean;
}

/** Padding on the batch bounding box, in meters. */
const BOUNDS_PAD = 8;
/** Extra headroom above the tallest sampled ground, for tall props. */
const BOUNDS_HEADROOM = 12;

export function buildPropCell(
  terrain: Terrain,
  prototypes: PrototypeSet,
  family: FamilyConfig,
  ix: number,
  iz: number,
  harvested: ReadonlySet<string> = new Set()
): PropCell {
  const size = family.cellSize;
  const minX = ix * size;
  const minZ = iz * size;
  const allowedBiomes = new Set(family.biomes as BiomeKind[]);

  const cell: PropCell = {
    family,
    mesh: null,
    colliders: [],
    nodes: [],
    cx: minX + size / 2,
    cz: minZ + size / 2,
    casting: false
  };

  const clearings = clearingsFor(terrain, terrain.seed);

  const points = scatterInRect(
    {
      seed: terrain.seed,
      label: family.id,
      mask: (x, z) =>
        allowedBiomes.has(terrain.biomeAt(x, z)) &&
        terrain.slopeAt(x, z) < family.maxSlope &&
        // Landmarks were placed on ground the scatter had already claimed, so
        // oaks grew through the village roofs and one sat on the spawn point.
        allowedInClearings(clearings, family.id, x, z),
      density: (x, z) => {
        const biome = terrain.biomeAt(x, z);
        return family.density[biome] ?? family.density['default'] ?? 1;
      },
      minDistance: family.minDistance
    },
    minX,
    minZ,
    minX + size,
    minZ + size
  );
  if (points.length === 0) return cell;

  const proto = prototypes.meshes.get(family.id as PropFamilyId);
  if (!proto) return cell;

  // A clone shares the prototype's material, so a batch is still one draw call.
  //
  // The GEOMETRY must not be shared, though a clone shares it by default.
  // `thinInstanceSetBuffer` below routes through `Mesh.setVerticesBuffer`,
  // which delegates to `Geometry.setVerticesBuffer`, which keeps ONE buffer per
  // kind and disposes whatever was there before. Every resident cell of a
  // family would write its world0..world3 matrices into the same geometry and
  // only the last writer would survive. The build queue is sorted nearest
  // first, so the last cell built is the FARTHEST one, and every batch of the
  // family drew the distant cell's matrices: trees on the horizon, bare ground
  // underfoot, while the harvest nodes and colliders (plain per-cell arrays)
  // stayed correct at your feet and told you to swing a knife at nothing.
  //
  // This has to happen before the buffer upload and before buildBoundingInfo,
  // because makeGeometryUnique reapplies the geometry and rebuilds the bounds.
  const mesh = proto.clone(`${family.id}_${ix}_${iz}`, null, true);
  if (!mesh) return cell;
  mesh.makeGeometryUnique();
  mesh.setEnabled(true);
  mesh.isPickable = false;
  // Only the solid families take shadows. Ground cover is thousands of tiny
  // instances whose own geometry is smaller than a shadow texel at 80m/1024,
  // so shading it resolves to acne rather than to shape and costs the most
  // where it shows the least. `castsShadow` is the right proxy: it already
  // marks the families big enough for the shadow map to say anything about.
  mesh.receiveShadows = family.castsShadow;

  const matrices = new Float32Array(points.length * 16);
  // Per-instance colour. Babylon routes a thin-instance 'color' buffer to the
  // `instanceColor` attribute (NOT ColorKind), sets the INSTANCESCOLOR define
  // itself, and `vertexColorMixing` then does `vColor *= instanceColor`. So
  // this MULTIPLIES the GLB's baked COLOR_0 rather than replacing it, which is
  // what lets one shared material carry both a family base tint and per-prop
  // variation. Alpha must stay exactly 1: it multiplies into the alpha path.
  const tints = new Float32Array(points.length * 4);
  const base = family.tint?.base ?? [1, 1, 1];
  const valueSpread = family.tint?.value ?? 0;
  const warmSpread = family.tint?.warm ?? 0;
  const minScale = family.scaleRange[0] ?? 1;
  const maxScale = family.scaleRange[1] ?? 1;

  const scale = Vector3.Zero();
  const position = Vector3.Zero();
  const rotation = Quaternion.Identity();
  const matrix = Matrix.Identity();

  let minY = Number.POSITIVE_INFINITY;
  let maxY = Number.NEGATIVE_INFINITY;

  let written = 0;
  for (let i = 0; i < points.length; i++) {
    const p = points[i];
    if (!p) continue;
    // A harvested node leaves no stump: it is simply absent until it regrows.
    if (harvested.has(p.key)) continue;
    const s = minScale + p.roll * (maxScale - minScale);
    const y = terrain.heightAt(p.x, p.z);

    // Prototype origins are seated at ground level with any vertical offset
    // baked into their vertices, so placement is the ground sample and nothing
    // else, and scaling grows the prop upward rather than sinking it.
    scale.set(s, s, s);
    position.set(p.x, y, p.z);
    Quaternion.RotationYawPitchRollToRef(p.rotation, 0, 0, rotation);
    Matrix.ComposeToRef(scale, rotation, position, matrix);
    matrix.copyToArray(matrices, written * 16);

    // `tint` is centred on 0, so a family reads as its base colour on average
    // and individuals sit either side of it. `warm` pushes red up and blue down
    // together, which is the axis foliage actually varies along (sun-bleached
    // to shaded) rather than a hue rotation, which goes muddy fast.
    const t = p.tint * 2 - 1;
    const v = 1 + t * valueSpread;
    const w = t * warmSpread;
    tints[written * 4] = Math.max(0, (base[0] ?? 1) * v + w);
    tints[written * 4 + 1] = Math.max(0, (base[1] ?? 1) * v);
    tints[written * 4 + 2] = Math.max(0, (base[2] ?? 1) * v - w);
    tints[written * 4 + 3] = 1;

    written++;

    if (y < minY) minY = y;
    if (y > maxY) maxY = y;

    if (family.collisionRadius > 0) {
      cell.colliders.push({ x: p.x, z: p.z, radius: family.collisionRadius * s });
    }
    if (family.harvest) {
      cell.nodes.push({
        key: p.key,
        family: family.id as PropFamilyId,
        resource: family.harvest,
        x: p.x,
        y,
        z: p.z,
        cellSize: size
      });
    }
  }

  // `true` marks the buffer static: it never changes after upload, so Babylon
  // keeps it GPU-side instead of re-uploading it every frame.
  if (written === 0) {
    // Every candidate in this cell has been harvested.
    mesh.dispose(false, false);
    return cell;
  }
  // Upload only the slots actually written. Harvested nodes are skipped above,
  // so the tail of the buffer would otherwise be zero matrices, which collapse
  // their geometry to a point at the world origin.
  mesh.thinInstanceSetBuffer(
    'matrix',
    written === points.length ? matrices : matrices.subarray(0, written * 16),
    16,
    true
  );
  // Same aliasing hazard as the matrix buffer above, so it goes through the
  // same unique geometry and must come after makeGeometryUnique().
  mesh.thinInstanceSetBuffer(
    'color',
    written === points.length ? tints : tints.subarray(0, written * 4),
    4,
    true
  );

  // Bounds MUST be set explicitly. A clone inherits the prototype's bounding
  // box, which describes one small prop at the origin, so every batch would be
  // frustum-culled the moment the camera looked away from world zero.
  //
  // Built from the cell footprint and the sampled height range rather than by
  // calling thinInstanceRefreshBoundingInfo, which walks every instance matrix
  // on every batch.
  mesh.buildBoundingInfo(
    new Vector3(minX - BOUNDS_PAD, minY - BOUNDS_PAD, minZ - BOUNDS_PAD),
    new Vector3(
      minX + size + BOUNDS_PAD,
      maxY + BOUNDS_PAD + BOUNDS_HEADROOM,
      minZ + size + BOUNDS_PAD
    )
  );
  mesh.alwaysSelectAsActiveMesh = false;

  cell.mesh = mesh;
  return cell;
}
